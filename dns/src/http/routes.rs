use super::{models::*, AppState};
use crate::{auth::Claims, discord_bot::*, http::helpers};
use std::env;

use actix_web::{
    web::{self, Data},
    HttpRequest, HttpResponse, Responder, HttpMessage,
};

#[actix_web::get("/")]
pub(crate) async fn index() -> impl Responder {
    HttpResponse::Ok().body(format!(
		  "GurtDNS v{}!\n\nThe available endpoints are:\n\n - [GET] /domains\n - [GET] /domain/{{name}}/{{tld}}\n - [POST] /domain\n - [PUT] /domain/{{key}}\n - [DELETE] /domain/{{key}}\n - [GET] /tlds\n\nRatelimits are as follows: 5 requests per 10 minutes on `[POST] /domain`.\n\nCode link: https://github.com/outpoot/gurted",env!("CARGO_PKG_VERSION")),
	 )
}

pub(crate) async fn create_logic(domain: Domain, user_id: i32, app: &AppState) -> Result<Domain, HttpResponse> {
    helpers::validate_ip(&domain)?;

    if !app.config.tld_list().contains(&domain.tld.as_str()) || !domain.name.chars().all(|c| c.is_alphabetic() || c == '-') || domain.name.len() > 24 {
        return Err(HttpResponse::BadRequest().json(Error {
            msg: "Failed to create domain",
            error: "Invalid name, non-existent TLD, or name too long (24 chars).".into(),
        }));
    }

    if app.config.offen_words().iter().any(|word| domain.name.contains(word)) {
        return Err(HttpResponse::BadRequest().json(Error {
            msg: "Failed to create domain",
            error: "The given domain name is offensive.".into(),
        }));
    }

    let existing_count: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM domains WHERE name = ? AND tld = ?"
    )
    .bind(&domain.name)
    .bind(&domain.tld)
    .fetch_one(&app.db)
    .await
    .map_err(|_| HttpResponse::InternalServerError().finish())?;

    if existing_count > 0 {
        return Err(HttpResponse::Conflict().finish());
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
    .map_err(|_| HttpResponse::Conflict().finish())?;

    Ok(domain)
}

pub(crate) async fn create_domain(
    domain: web::Json<Domain>, 
    app: Data<AppState>,
    req: HttpRequest
) -> impl Responder {
    let extensions = req.extensions();
    let claims = match extensions.get::<Claims>() {
        Some(claims) => claims,
        None => {
            return HttpResponse::Unauthorized().json(Error {
                msg: "Authentication required",
                error: "AUTH_REQUIRED".into(),
            });
        }
    };

    // Check if user has registrations or domain invite codes remaining
    let (user_registrations, user_domain_invites): (i32, i32) = match sqlx::query_as::<_, (i32, i32)>(
        "SELECT registrations_remaining, domain_invite_codes FROM users WHERE id = $1"
    )
    .bind(claims.user_id)
    .fetch_one(&app.db)
    .await
    {
        Ok((registrations, domain_invites)) => (registrations, domain_invites),
        Err(_) => {
            return HttpResponse::InternalServerError().json(Error {
                msg: "Database error",
                error: "DB_ERROR".into(),
            });
        }
    };

    if user_registrations <= 0 && user_domain_invites <= 0 {
        return HttpResponse::BadRequest().json(Error {
            msg: "No domain registrations or domain invite codes remaining",
            error: "NO_REGISTRATIONS_OR_INVITES".into(),
        });
    }

    let domain = domain.into_inner();

    match create_logic(domain.clone(), claims.user_id, app.as_ref()).await {
        Ok(_) => {
            // Start transaction for domain registration
            let mut tx = match app.db.begin().await {
                Ok(tx) => tx,
                Err(_) => {
                    return HttpResponse::InternalServerError().json(Error {
                        msg: "Database error",
                        error: "DB_ERROR".into(),
                    });
                }
            };

            // Get the created domain ID
            let domain_id: i32 = match sqlx::query_scalar(
                "SELECT id FROM domains WHERE name = $1 AND tld = $2 AND user_id = $3 ORDER BY created_at DESC LIMIT 1"
            )
            .bind(&domain.name)
            .bind(&domain.tld)
            .bind(claims.user_id)
            .fetch_one(&mut *tx)
            .await
            {
                Ok(id) => id,
                Err(_) => {
                    let _ = tx.rollback().await;
                    return HttpResponse::InternalServerError().json(Error {
                        msg: "Failed to get domain ID",
                        error: "DB_ERROR".into(),
                    });
                }
            };

            // Get user's current domain invite codes
            let user_domain_invites: i32 = match sqlx::query_scalar(
                "SELECT domain_invite_codes FROM users WHERE id = $1"
            )
            .bind(claims.user_id)
            .fetch_one(&mut *tx)
            .await
            {
                Ok(invites) => invites,
                Err(_) => {
                    let _ = tx.rollback().await;
                    return HttpResponse::InternalServerError().json(Error {
                        msg: "Database error getting user domain invites",
                        error: "DB_ERROR".into(),
                    });
                }
            };

            // Auto-consume domain invite code if available, otherwise use registration
            if user_domain_invites > 0 {
                // Use domain invite code
                if let Err(_) = sqlx::query(
                    "UPDATE users SET domain_invite_codes = domain_invite_codes - 1 WHERE id = $1"
                )
                .bind(claims.user_id)
                .execute(&mut *tx)
                .await
                {
                    let _ = tx.rollback().await;
                    return HttpResponse::InternalServerError().json(Error {
                        msg: "Failed to consume domain invite code",
                        error: "DB_ERROR".into(),
                    });
                }
            } else {
                // Use regular registration
                if let Err(_) = sqlx::query(
                    "UPDATE users SET registrations_remaining = registrations_remaining - 1 WHERE id = $1"
                )
                .bind(claims.user_id)
                .execute(&mut *tx)
                .await
                {
                    let _ = tx.rollback().await;
                    return HttpResponse::InternalServerError().json(Error {
                        msg: "Failed to consume registration",
                        error: "DB_ERROR".into(),
                    });
                }
            }

            // Commit the transaction
            if let Err(_) = tx.commit().await {
                return HttpResponse::InternalServerError().json(Error {
                    msg: "Transaction failed",
                    error: "DB_ERROR".into(),
                });
            }

            // Send to Discord for approval
            let registration = DomainRegistration {
                id: domain_id,
                domain_name: domain.name.clone(),
                tld: domain.tld.clone(),
                ip: domain.ip.clone(),
                user_id: claims.user_id,
                username: claims.username.clone(),
            };

            let bot_token = app.config.discord.bot_token.clone();
            let channel_id = app.config.discord.channel_id;
            
            tokio::spawn(async move {
                if let Err(e) = send_domain_approval_request(
                    channel_id,
                    registration,
                    &bot_token,
                ).await {
                    log::error!("Failed to send Discord message: {}", e);
                }
            });

            HttpResponse::Ok().json(serde_json::json!({
                "message": "Domain registration submitted for approval",
                "domain": format!("{}.{}", domain.name, domain.tld),
                "status": "pending"
            }))
        }
        Err(error) => error,
    }
}


#[actix_web::get("/domain/{name}/{tld}")]
pub(crate) async fn get_domain(path: web::Path<(String, String)>, app: Data<AppState>) -> impl Responder {
    let (name, tld) = path.into_inner();

    match sqlx::query_as::<_, Domain>(
        "SELECT id, name, tld, ip, user_id, status, denial_reason, created_at FROM domains WHERE name = $1 AND tld = $2 AND status = 'approved'"
    )
    .bind(&name)
    .bind(&tld)
    .fetch_optional(&app.db)
    .await
    {
        Ok(Some(domain)) => HttpResponse::Ok().json(ResponseDomain {
            tld: domain.tld,
            name: domain.name,
            ip: domain.ip,
            records: None,
        }),
        Ok(None) => HttpResponse::NotFound().finish(),
        Err(_) => HttpResponse::InternalServerError().finish(),
    }
}

#[actix_web::put("/domain/{name}/{tld}")]
pub(crate) async fn update_domain(
    path: web::Path<(String, String)>, 
    domain_update: web::Json<UpdateDomain>, 
    app: Data<AppState>,
    req: HttpRequest
) -> impl Responder {
    let extensions = req.extensions();
    let claims = match extensions.get::<Claims>() {
        Some(claims) => claims,
        None => {
            return HttpResponse::Unauthorized().json(Error {
                msg: "Authentication required",
                error: "AUTH_REQUIRED".into(),
            });
        }
    };

    let (name, tld) = path.into_inner();

    match sqlx::query(
        "UPDATE domains SET ip = $1 WHERE name = $2 AND tld = $3 AND user_id = $4 AND status = 'approved'"
    )
    .bind(&domain_update.ip)
    .bind(&name)
    .bind(&tld)
    .bind(claims.user_id)
    .execute(&app.db)
    .await
    {
        Ok(result) => {
            if result.rows_affected() == 1 {
                HttpResponse::Ok().json(domain_update.into_inner())
            } else {
                HttpResponse::NotFound().json(Error {
                    msg: "Domain not found or not owned by user",
                    error: "DOMAIN_NOT_FOUND".into(),
                })
            }
        }
        Err(_) => HttpResponse::InternalServerError().finish(),
    }
}

#[actix_web::delete("/domain/{name}/{tld}")]
pub(crate) async fn delete_domain(
    path: web::Path<(String, String)>, 
    app: Data<AppState>,
    req: HttpRequest
) -> impl Responder {
    let extensions = req.extensions();
    let claims = match extensions.get::<Claims>() {
        Some(claims) => claims,
        None => {
            return HttpResponse::Unauthorized().json(Error {
                msg: "Authentication required",
                error: "AUTH_REQUIRED".into(),
            });
        }
    };

    let (name, tld) = path.into_inner();

    match sqlx::query(
        "DELETE FROM domains WHERE name = $1 AND tld = $2 AND user_id = $3"
    )
    .bind(&name)
    .bind(&tld)
    .bind(claims.user_id)
    .execute(&app.db)
    .await
    {
        Ok(result) => {
            if result.rows_affected() == 1 {
                HttpResponse::Ok().finish()
            } else {
                HttpResponse::NotFound().json(Error {
                    msg: "Domain not found or not owned by user",
                    error: "DOMAIN_NOT_FOUND".into(),
                })
            }
        }
        Err(_) => HttpResponse::InternalServerError().finish(),
    }
}

#[actix_web::post("/domain/check")]
pub(crate) async fn check_domain(query: web::Json<DomainQuery>, app: Data<AppState>) -> impl Responder {
    let DomainQuery { name, tld } = query.into_inner();

    let result = helpers::is_domain_taken(&name, tld.as_deref(), app).await;
    HttpResponse::Ok().json(result)
}

#[actix_web::get("/domains")]
pub(crate) async fn get_domains(query: web::Query<PaginationParams>, app: Data<AppState>) -> impl Responder {
    let page = query.page.unwrap_or(1);
    let limit = query.page_size.unwrap_or(15);

    if page == 0 || limit == 0 {
        return HttpResponse::BadRequest().json(Error {
            msg: "page_size or page must be greater than 0",
            error: "Invalid pagination parameters".into(),
        });
    }

    if limit > 100 {
        return HttpResponse::BadRequest().json(Error {
            msg: "page_size must be greater than 0 and less than or equal to 100",
            error: "Invalid pagination parameters".into(),
        });
    }

    let offset = (page - 1) * limit;

    match sqlx::query_as::<_, Domain>(
        "SELECT id, name, tld, ip, user_id, status, denial_reason, created_at FROM domains WHERE status = 'approved' ORDER BY created_at DESC LIMIT $1 OFFSET $2"
    )
    .bind(limit as i64)
    .bind(offset as i64)
    .fetch_all(&app.db)
    .await
    {
        Ok(domains) => {
            let response_domains: Vec<ResponseDomain> = domains
                .into_iter()
                .map(|domain| ResponseDomain {
                    tld: domain.tld,
                    name: domain.name,
                    ip: domain.ip,
                    records: None,
                })
                .collect();

            HttpResponse::Ok().json(PaginationResponse {
                domains: response_domains,
                page,
                limit,
            })
        }
        Err(err) => HttpResponse::InternalServerError().json(Error {
            msg: "Failed to fetch domains",
            error: err.to_string(),
        }),
    }
}

#[actix_web::get("/tlds")]
pub(crate) async fn get_tlds(app: Data<AppState>) -> impl Responder { HttpResponse::Ok().json(&*app.config.tld_list()) }
