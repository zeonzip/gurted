use super::{models::*, AppState, helpers::validate_ip};
use crate::auth::Claims;
use gurt::prelude::*;
use std::{env, collections::HashMap};

fn parse_query_string(query: &str) -> HashMap<String, String> {
    let mut params = HashMap::new();
    for pair in query.split('&') {
        if let Some((key, value)) = pair.split_once('=') {
            params.insert(key.to_string(), value.to_string());
        }
    }
    params
}

pub(crate) async fn index(_app_state: AppState) -> Result<GurtResponse> {
    let body = format!(
        "GurtDNS v{}!\n\nThe available endpoints are:\n\n - [GET] /domains\n - [GET] /domain/{{name}}/{{tld}}\n - [POST] /domain\n - [PUT] /domain/{{key}}\n - [DELETE] /domain/{{key}}\n - [GET] /tlds\n\nRatelimits are as follows: 5 requests per 10 minutes on `[POST] /domain`.\n\nCode link: https://github.com/outpoot/gurted",
        env!("CARGO_PKG_VERSION")
    );
    
    Ok(GurtResponse::ok().with_string_body(body))
}

pub(crate) async fn create_logic(domain: Domain, user_id: i32, app: &AppState) -> Result<Domain> {
    validate_ip(&domain)?;

    if !app.config.tld_list().contains(&domain.tld.as_str()) 
        || !domain.name.chars().all(|c| c.is_alphabetic() || c == '-') 
        || domain.name.len() > 24
        || domain.name.is_empty()
        || domain.name.starts_with('-')
        || domain.name.ends_with('-') {
        return Err(GurtError::invalid_message("Invalid name, non-existent TLD, or name too long (24 chars)."));
    }

    if app.config.offen_words().iter().any(|word| domain.name.contains(word)) {
        return Err(GurtError::invalid_message("The given domain name is offensive."));
    }

    let existing_count: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM domains WHERE name = $1 AND tld = $2"
    )
    .bind(&domain.name)
    .bind(&domain.tld)
    .fetch_one(&app.db)
    .await
    .map_err(|_| GurtError::invalid_message("Database error"))?;

    if existing_count > 0 {
        return Err(GurtError::invalid_message("Domain already exists"));
    }

    sqlx::query(
        "INSERT INTO domains (name, tld, ip, user_id, status) VALUES ($1, $2, $3, $4, 'pending')"
    )
    .bind(&domain.name)
    .bind(&domain.tld)
    .bind(&domain.ip)
    .bind(user_id)
    .execute(&app.db)
    .await
    .map_err(|_| GurtError::invalid_message("Failed to create domain"))?;

    // Decrease user's registrations remaining
    sqlx::query("UPDATE users SET registrations_remaining = registrations_remaining - 1 WHERE id = $1")
        .bind(user_id)
        .execute(&app.db)
        .await
        .map_err(|_| GurtError::invalid_message("Failed to update user registrations"))?;

    Ok(domain)
}

pub(crate) async fn create_domain(ctx: &ServerContext, app_state: AppState, claims: Claims) -> Result<GurtResponse> {
    // Check if user has registrations remaining
    let user: (i32,) = sqlx::query_as("SELECT registrations_remaining FROM users WHERE id = $1")
        .bind(claims.user_id)
        .fetch_one(&app_state.db)
        .await
        .map_err(|_| GurtError::invalid_message("User not found"))?;

    if user.0 <= 0 {
        return Ok(GurtResponse::bad_request().with_json_body(&Error {
            msg: "Failed to create domain",
            error: "No registrations remaining".into(),
        })?);
    }

    let domain: Domain = serde_json::from_slice(ctx.body())
        .map_err(|_| GurtError::invalid_message("Invalid JSON"))?;

    match create_logic(domain.clone(), claims.user_id, &app_state).await {
        Ok(created_domain) => {
            Ok(GurtResponse::ok().with_json_body(&created_domain)?)
        }
        Err(e) => {
            Ok(GurtResponse::bad_request().with_json_body(&Error {
                msg: "Failed to create domain",
                error: e.to_string(),
            })?)
        }
    }
}

pub(crate) async fn get_domain(ctx: &ServerContext, app_state: AppState) -> Result<GurtResponse> {
    let path_parts: Vec<&str> = ctx.path().split('/').collect();
    if path_parts.len() < 4 {
        return Ok(GurtResponse::bad_request().with_string_body("Invalid path format. Expected /domain/{name}/{tld}"));
    }

    let name = path_parts[2];
    let tld = path_parts[3];

    let domain: Option<Domain> = sqlx::query_as::<_, Domain>(
        "SELECT id, name, tld, ip, user_id, status, denial_reason, created_at FROM domains WHERE name = $1 AND tld = $2 AND status = 'approved'"
    )
    .bind(name)
    .bind(tld)
    .fetch_optional(&app_state.db)
    .await
    .map_err(|_| GurtError::invalid_message("Database error"))?;

    match domain {
        Some(domain) => {
            let response_domain = ResponseDomain {
                name: domain.name,
                tld: domain.tld,
                ip: domain.ip,
                records: None, // TODO: Implement DNS records
            };
            Ok(GurtResponse::ok().with_json_body(&response_domain)?)
        }
        None => Ok(GurtResponse::not_found().with_string_body("Domain not found"))
    }
}

pub(crate) async fn get_domains(ctx: &ServerContext, app_state: AppState) -> Result<GurtResponse> {
    // Parse pagination from query parameters
    let path = ctx.path();
    let query_params = if let Some(query_start) = path.find('?') {
        let query_string = &path[query_start + 1..];
        parse_query_string(query_string)
    } else {
        HashMap::new()
    };

    let page = query_params.get("page")
        .and_then(|p| p.parse::<u32>().ok())
        .unwrap_or(1)
        .max(1); // Ensure page is at least 1

    let page_size = query_params.get("limit")
        .and_then(|l| l.parse::<u32>().ok())
        .unwrap_or(100)
        .clamp(1, 1000); // Limit between 1 and 1000

    let offset = (page - 1) * page_size;

    let domains: Vec<Domain> = sqlx::query_as::<_, Domain>(
        "SELECT id, name, tld, ip, user_id, status, denial_reason, created_at FROM domains WHERE status = 'approved' ORDER BY created_at DESC LIMIT $1 OFFSET $2"
    )
    .bind(page_size as i64)
    .bind(offset as i64)
    .fetch_all(&app_state.db)
    .await
    .map_err(|_| GurtError::invalid_message("Database error"))?;

    let response_domains: Vec<ResponseDomain> = domains.into_iter().map(|domain| {
        ResponseDomain {
            name: domain.name,
            tld: domain.tld,
            ip: domain.ip,
            records: None,
        }
    }).collect();

    let response = PaginationResponse {
        domains: response_domains,
        page,
        limit: page_size,
    };

    Ok(GurtResponse::ok().with_json_body(&response)?)
}

pub(crate) async fn get_tlds(app_state: AppState) -> Result<GurtResponse> {
    Ok(GurtResponse::ok().with_json_body(&app_state.config.tld_list())?)
}

pub(crate) async fn check_domain(ctx: &ServerContext, app_state: AppState) -> Result<GurtResponse> {
    let path = ctx.path();
    let query_params = if let Some(query_start) = path.find('?') {
        let query_string = &path[query_start + 1..];
        parse_query_string(query_string)
    } else {
        return Ok(GurtResponse::bad_request().with_string_body("Missing query parameters. Expected ?name=<name>&tld=<tld>"));
    };

    let name = query_params.get("name")
        .ok_or_else(|| GurtError::invalid_message("Missing 'name' parameter"))?;
    let tld = query_params.get("tld")
        .ok_or_else(|| GurtError::invalid_message("Missing 'tld' parameter"))?;

    let domain: Option<Domain> = sqlx::query_as::<_, Domain>(
        "SELECT id, name, tld, ip, user_id, status, denial_reason, created_at FROM domains WHERE name = $1 AND tld = $2"
    )
    .bind(name)
    .bind(tld)
    .fetch_optional(&app_state.db)
    .await
    .map_err(|_| GurtError::invalid_message("Database error"))?;

    let domain_list = DomainList {
        domain: format!("{}.{}", name, tld),
        taken: domain.is_some(),
    };

    Ok(GurtResponse::ok().with_json_body(&domain_list)?)
}

pub(crate) async fn update_domain(ctx: &ServerContext, app_state: AppState, claims: Claims) -> Result<GurtResponse> {
    let path_parts: Vec<&str> = ctx.path().split('/').collect();
    if path_parts.len() < 4 {
        return Ok(GurtResponse::bad_request().with_string_body("Invalid path format. Expected /domain/{name}/{tld}"));
    }

    let name = path_parts[2];
    let tld = path_parts[3];

    let update_data: UpdateDomain = serde_json::from_slice(ctx.body())
        .map_err(|_| GurtError::invalid_message("Invalid JSON"))?;

    // Verify user owns this domain
    let domain: Option<Domain> = sqlx::query_as::<_, Domain>(
        "SELECT id, name, tld, ip, user_id, status, denial_reason, created_at FROM domains WHERE name = $1 AND tld = $2 AND user_id = $3"
    )
    .bind(name)
    .bind(tld)
    .bind(claims.user_id)
    .fetch_optional(&app_state.db)
    .await
    .map_err(|_| GurtError::invalid_message("Database error"))?;

    let domain = match domain {
        Some(d) => d,
        None => return Ok(GurtResponse::not_found().with_string_body("Domain not found or access denied"))
    };

    // Validate IP
    validate_ip(&Domain {
        id: domain.id,
        name: domain.name.clone(),
        tld: domain.tld.clone(),
        ip: update_data.ip.clone(),
        user_id: domain.user_id,
        status: domain.status,
        denial_reason: domain.denial_reason,
        created_at: domain.created_at,
    })?;

    sqlx::query("UPDATE domains SET ip = $1 WHERE name = $2 AND tld = $3 AND user_id = $4")
        .bind(&update_data.ip)
        .bind(name)
        .bind(tld)
        .bind(claims.user_id)
        .execute(&app_state.db)
        .await
        .map_err(|_| GurtError::invalid_message("Failed to update domain"))?;

    Ok(GurtResponse::ok().with_string_body("Domain updated successfully"))
}

pub(crate) async fn delete_domain(ctx: &ServerContext, app_state: AppState, claims: Claims) -> Result<GurtResponse> {
    let path_parts: Vec<&str> = ctx.path().split('/').collect();
    if path_parts.len() < 4 {
        return Ok(GurtResponse::bad_request().with_string_body("Invalid path format. Expected /domain/{name}/{tld}"));
    }

    let name = path_parts[2];
    let tld = path_parts[3];

    // Verify user owns this domain
    let domain: Option<Domain> = sqlx::query_as::<_, Domain>(
        "SELECT id, name, tld, ip, user_id, status, denial_reason, created_at FROM domains WHERE name = $1 AND tld = $2 AND user_id = $3"
    )
    .bind(name)
    .bind(tld)
    .bind(claims.user_id)
    .fetch_optional(&app_state.db)
    .await
    .map_err(|_| GurtError::invalid_message("Database error"))?;

    if domain.is_none() {
        return Ok(GurtResponse::not_found().with_string_body("Domain not found or access denied"));
    }

    sqlx::query("DELETE FROM domains WHERE name = $1 AND tld = $2 AND user_id = $3")
        .bind(name)
        .bind(tld)
        .bind(claims.user_id)
        .execute(&app_state.db)
        .await
        .map_err(|_| GurtError::invalid_message("Failed to delete domain"))?;

    Ok(GurtResponse::ok().with_string_body("Domain deleted successfully"))
}

pub(crate) async fn get_user_domains(ctx: &ServerContext, app_state: AppState, claims: Claims) -> Result<GurtResponse> {
    // Parse pagination from query parameters
    let path = ctx.path();
    let query_params = if let Some(query_start) = path.find('?') {
        let query_string = &path[query_start + 1..];
        parse_query_string(query_string)
    } else {
        HashMap::new()
    };

    let page = query_params.get("page")
        .and_then(|p| p.parse::<u32>().ok())
        .unwrap_or(1)
        .max(1);

    let page_size = query_params.get("limit")
        .and_then(|l| l.parse::<u32>().ok())
        .unwrap_or(100)
        .clamp(1, 1000);

    let offset = (page - 1) * page_size;

    let domains: Vec<Domain> = sqlx::query_as::<_, Domain>(
        "SELECT id, name, tld, ip, user_id, status, denial_reason, created_at FROM domains WHERE user_id = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3"
    )
    .bind(claims.user_id)
    .bind(page_size as i64)
    .bind(offset as i64)
    .fetch_all(&app_state.db)
    .await
    .map_err(|_| GurtError::invalid_message("Database error"))?;

    let response_domains: Vec<UserDomain> = domains.into_iter().map(|domain| {
        UserDomain {
            name: domain.name,
            tld: domain.tld,
            ip: domain.ip,
            status: domain.status.unwrap_or_else(|| "pending".to_string()),
            denial_reason: domain.denial_reason,
        }
    }).collect();

    let response = UserDomainResponse {
        domains: response_domains,
        page,
        limit: page_size,
    };

    Ok(GurtResponse::ok().with_json_body(&response)?)
}

#[derive(serde::Serialize)]
struct Error {
    msg: &'static str,
    error: String,
}