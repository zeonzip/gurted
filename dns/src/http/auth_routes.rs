use super::{models::*, AppState};
use crate::auth::*;
use actix_web::{web, HttpResponse, Responder, HttpRequest, HttpMessage};
use sqlx::Row;
use rand::Rng;
use chrono::Utc;

#[actix_web::post("/auth/register")]
pub(crate) async fn register(
    user: web::Json<RegisterRequest>, 
    app: web::Data<AppState>
) -> impl Responder {
    let registrations = 3; // New users get 3 registrations by default

    // Hash password
    let password_hash = match hash_password(&user.password) {
        Ok(hash) => hash,
        Err(_) => {
            return HttpResponse::InternalServerError().json(Error {
                msg: "Failed to hash password",
                error: "HASH_ERROR".into(),
            });
        }
    };

    // Create user
    let user_result = sqlx::query(
        "INSERT INTO users (username, password_hash, registrations_remaining, domain_invite_codes) VALUES ($1, $2, $3, $4) RETURNING id"
    )
    .bind(&user.username)
    .bind(&password_hash)
    .bind(registrations)
    .bind(3) // Default 3 domain invite codes
    .fetch_one(&app.db)
    .await;

    match user_result {
        Ok(row) => {
            let user_id: i32 = row.get("id");
            

            // Generate JWT
            match generate_jwt(user_id, &user.username, &app.config.auth.jwt_secret) {
                Ok(token) => {
                    HttpResponse::Ok().json(LoginResponse {
                        token,
                        user: UserInfo {
                            id: user_id,
                            username: user.username.clone(),
                            registrations_remaining: registrations,
                            domain_invite_codes: 3,
                            created_at: Utc::now(),
                        },
                    })
                }
                Err(_) => HttpResponse::InternalServerError().json(Error {
                    msg: "Failed to generate token",
                    error: "TOKEN_ERROR".into(),
                }),
            }
        }
        Err(sqlx::Error::Database(db_err)) => {
            if db_err.is_unique_violation() {
                HttpResponse::Conflict().json(Error {
                    msg: "Username already exists",
                    error: "USER_EXISTS".into(),
                })
            } else {
                HttpResponse::InternalServerError().json(Error {
                    msg: "Database error",
                    error: "DB_ERROR".into(),
                })
            }
        }
        Err(_) => HttpResponse::InternalServerError().json(Error {
            msg: "Database error",
            error: "DB_ERROR".into(),
        }),
    }
}

#[actix_web::post("/auth/login")]
pub(crate) async fn login(
    credentials: web::Json<LoginRequest>, 
    app: web::Data<AppState>
) -> impl Responder {
    match sqlx::query_as::<_, User>(
        "SELECT id, username, password_hash, registrations_remaining, domain_invite_codes, created_at FROM users WHERE username = $1"
    )
    .bind(&credentials.username)
    .fetch_optional(&app.db)
    .await
    {
        Ok(Some(user)) => {
            match verify_password(&credentials.password, &user.password_hash) {
                Ok(true) => {
                    match generate_jwt(user.id, &user.username, &app.config.auth.jwt_secret) {
                        Ok(token) => {
                            HttpResponse::Ok().json(LoginResponse {
                                token,
                                user: UserInfo {
                                    id: user.id,
                                    username: user.username,
                                    registrations_remaining: user.registrations_remaining,
                                    domain_invite_codes: user.domain_invite_codes,
                                    created_at: user.created_at,
                                },
                            })
                        }
                        Err(e) => {
                            eprintln!("JWT generation error: {:?}", e);
                            HttpResponse::InternalServerError().json(Error {
                                msg: "Failed to generate token",
                                error: "TOKEN_ERROR".into(),
                            })
                        },
                    }
                }
                Ok(false) | Err(_) => {
                    HttpResponse::Unauthorized().json(Error {
                        msg: "Invalid credentials",
                        error: "INVALID_CREDENTIALS".into(),
                    })
                }
            }
        }
        Ok(None) => {
            HttpResponse::Unauthorized().json(Error {
                msg: "Invalid credentials",
                error: "INVALID_CREDENTIALS".into(),
            })
        }
        Err(e) => {
            eprintln!("Database error: {:?}", e);
            HttpResponse::InternalServerError().json(Error {
                msg: "Database error",
                error: "DB_ERROR".into(),
            })
        },
    }
}

#[actix_web::get("/auth/me")]
pub(crate) async fn get_user_info(
    req: HttpRequest,
    app: web::Data<AppState>
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

    match sqlx::query_as::<_, User>(
        "SELECT id, username, password_hash, registrations_remaining, domain_invite_codes, created_at FROM users WHERE id = $1"
    )
    .bind(claims.user_id)
    .fetch_optional(&app.db)
    .await
    {
        Ok(Some(user)) => {
            HttpResponse::Ok().json(UserInfo {
                id: user.id,
                username: user.username,
                registrations_remaining: user.registrations_remaining,
                domain_invite_codes: user.domain_invite_codes,
                created_at: user.created_at,
            })
        }
        Ok(None) => HttpResponse::NotFound().json(Error {
            msg: "User not found",
            error: "USER_NOT_FOUND".into(),
        }),
        Err(_) => HttpResponse::InternalServerError().json(Error {
            msg: "Database error",
            error: "DB_ERROR".into(),
        }),
    }
}

#[actix_web::post("/auth/invite")]
pub(crate) async fn create_invite(
    req: HttpRequest,
    app: web::Data<AppState>
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

    // Generate random invite code  
    let invite_code: String = rand::thread_rng()
        .sample_iter(&rand::distributions::Alphanumeric)
        .take(16)
        .map(char::from)
        .collect();

    // Create invite code (no registration cost)
    match sqlx::query(
        "INSERT INTO invite_codes (code, created_by) VALUES ($1, $2)"
    )
    .bind(&invite_code)
    .bind(claims.user_id)
    .execute(&app.db)
    .await
    {
        Ok(_) => {},
        Err(_) => {
            return HttpResponse::InternalServerError().json(Error {
                msg: "Failed to create invite code",
                error: "DB_ERROR".into(),
            });
        }
    }

    HttpResponse::Ok().json(serde_json::json!({
        "invite_code": invite_code
    }))
}

#[actix_web::post("/auth/redeem-invite")]
pub(crate) async fn redeem_invite(
    invite_request: web::Json<serde_json::Value>,
    req: HttpRequest,
    app: web::Data<AppState>
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

    let invite_code = match invite_request.get("invite_code").and_then(|v| v.as_str()) {
        Some(code) => code,
        None => {
            return HttpResponse::BadRequest().json(Error {
                msg: "Invite code is required",
                error: "INVITE_CODE_REQUIRED".into(),
            });
        }
    };

    // Find and validate invite code
    let invite = match sqlx::query_as::<_, InviteCode>(
        "SELECT id, code, created_by, used_by, created_at, used_at FROM invite_codes WHERE code = $1 AND used_by IS NULL"
    )
    .bind(invite_code)
    .fetch_optional(&app.db)
    .await
    {
        Ok(Some(invite)) => invite,
        Ok(None) => {
            return HttpResponse::BadRequest().json(Error {
                msg: "Invalid or already used invite code",
                error: "INVALID_INVITE".into(),
            });
        }
        Err(_) => {
            return HttpResponse::InternalServerError().json(Error {
                msg: "Database error",
                error: "DB_ERROR".into(),
            });
        }
    };

    // Start transaction to redeem invite
    let mut tx = match app.db.begin().await {
        Ok(tx) => tx,
        Err(_) => {
            return HttpResponse::InternalServerError().json(Error {
                msg: "Database error",
                error: "DB_ERROR".into(),
            });
        }
    };

    // Mark invite as used
    if let Err(_) = sqlx::query(
        "UPDATE invite_codes SET used_by = $1, used_at = CURRENT_TIMESTAMP WHERE id = $2"
    )
    .bind(claims.user_id)
    .bind(invite.id)
    .execute(&mut *tx)
    .await
    {
        let _ = tx.rollback().await;
        return HttpResponse::InternalServerError().json(Error {
            msg: "Failed to redeem invite code",
            error: "DB_ERROR".into(),
        });
    }

    // Add registrations to user (3 registrations per invite)
    if let Err(_) = sqlx::query(
        "UPDATE users SET registrations_remaining = registrations_remaining + 3 WHERE id = $1"
    )
    .bind(claims.user_id)
    .execute(&mut *tx)
    .await
    {
        let _ = tx.rollback().await;
        return HttpResponse::InternalServerError().json(Error {
            msg: "Failed to add registrations",
            error: "DB_ERROR".into(),
        });
    }

    if let Err(_) = tx.commit().await {
        return HttpResponse::InternalServerError().json(Error {
            msg: "Transaction failed",
            error: "DB_ERROR".into(),
        });
    }

    HttpResponse::Ok().json(serde_json::json!({
        "message": "Invite code redeemed successfully",
        "registrations_added": 3
    }))
}

#[actix_web::post("/auth/domain-invite")]
pub(crate) async fn create_domain_invite(
    req: HttpRequest,
    app: web::Data<AppState>
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

    // Check if user has domain invite codes remaining
    let user = match sqlx::query_as::<_, User>(
        "SELECT id, username, password_hash, registrations_remaining, domain_invite_codes, created_at FROM users WHERE id = $1"
    )
    .bind(claims.user_id)
    .fetch_optional(&app.db)
    .await
    {
        Ok(Some(user)) => user,
        Ok(None) => {
            return HttpResponse::NotFound().json(Error {
                msg: "User not found",
                error: "USER_NOT_FOUND".into(),
            });
        }
        Err(_) => {
            return HttpResponse::InternalServerError().json(Error {
                msg: "Database error",
                error: "DB_ERROR".into(),
            });
        }
    };

    if user.domain_invite_codes <= 0 {
        return HttpResponse::BadRequest().json(Error {
            msg: "No domain invite codes remaining",
            error: "NO_DOMAIN_INVITES".into(),
        });
    }

    // Generate random domain invite code  
    let invite_code: String = rand::thread_rng()
        .sample_iter(&rand::distributions::Alphanumeric)
        .take(16)
        .map(char::from)
        .collect();

    // Start transaction
    let mut tx = match app.db.begin().await {
        Ok(tx) => tx,
        Err(_) => {
            return HttpResponse::InternalServerError().json(Error {
                msg: "Database error",
                error: "DB_ERROR".into(),
            });
        }
    };

    // Create domain invite code
    if let Err(_) = sqlx::query(
        "INSERT INTO domain_invite_codes (code, created_by) VALUES ($1, $2)"
    )
    .bind(&invite_code)
    .bind(claims.user_id)
    .execute(&mut *tx)
    .await
    {
        let _ = tx.rollback().await;
        return HttpResponse::InternalServerError().json(Error {
            msg: "Failed to create domain invite code",
            error: "DB_ERROR".into(),
        });
    }

    // Decrease user's domain invite codes
    if let Err(_) = sqlx::query(
        "UPDATE users SET domain_invite_codes = domain_invite_codes - 1 WHERE id = $1"
    )
    .bind(claims.user_id)
    .execute(&mut *tx)
    .await
    {
        let _ = tx.rollback().await;
        return HttpResponse::InternalServerError().json(Error {
            msg: "Failed to update domain invite codes",
            error: "DB_ERROR".into(),
        });
    }

    if let Err(_) = tx.commit().await {
        return HttpResponse::InternalServerError().json(Error {
            msg: "Transaction failed",
            error: "DB_ERROR".into(),
        });
    }

    HttpResponse::Ok().json(serde_json::json!({
        "domain_invite_code": invite_code
    }))
}

#[actix_web::post("/auth/redeem-domain-invite")]
pub(crate) async fn redeem_domain_invite(
    invite_request: web::Json<serde_json::Value>,
    req: HttpRequest,
    app: web::Data<AppState>
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

    let invite_code = match invite_request.get("domain_invite_code").and_then(|v| v.as_str()) {
        Some(code) => code,
        None => {
            return HttpResponse::BadRequest().json(Error {
                msg: "Domain invite code is required",
                error: "DOMAIN_INVITE_CODE_REQUIRED".into(),
            });
        }
    };

    // Find and validate domain invite code
    let invite = match sqlx::query_as::<_, DomainInviteCode>(
        "SELECT id, code, created_by, used_by, created_at, used_at FROM domain_invite_codes WHERE code = $1 AND used_by IS NULL"
    )
    .bind(invite_code)
    .fetch_optional(&app.db)
    .await
    {
        Ok(Some(invite)) => invite,
        Ok(None) => {
            return HttpResponse::BadRequest().json(Error {
                msg: "Invalid or already used domain invite code",
                error: "INVALID_DOMAIN_INVITE".into(),
            });
        }
        Err(_) => {
            return HttpResponse::InternalServerError().json(Error {
                msg: "Database error",
                error: "DB_ERROR".into(),
            });
        }
    };

    // Start transaction to redeem invite
    let mut tx = match app.db.begin().await {
        Ok(tx) => tx,
        Err(_) => {
            return HttpResponse::InternalServerError().json(Error {
                msg: "Database error",
                error: "DB_ERROR".into(),
            });
        }
    };

    // Mark domain invite as used
    if let Err(_) = sqlx::query(
        "UPDATE domain_invite_codes SET used_by = $1, used_at = CURRENT_TIMESTAMP WHERE id = $2"
    )
    .bind(claims.user_id)
    .bind(invite.id)
    .execute(&mut *tx)
    .await
    {
        let _ = tx.rollback().await;
        return HttpResponse::InternalServerError().json(Error {
            msg: "Failed to redeem domain invite code",
            error: "DB_ERROR".into(),
        });
    }

    // Add domain invite codes to user (1 per domain invite)
    if let Err(_) = sqlx::query(
        "UPDATE users SET domain_invite_codes = domain_invite_codes + 1 WHERE id = $1"
    )
    .bind(claims.user_id)
    .execute(&mut *tx)
    .await
    {
        let _ = tx.rollback().await;
        return HttpResponse::InternalServerError().json(Error {
            msg: "Failed to add domain invite codes",
            error: "DB_ERROR".into(),
        });
    }

    if let Err(_) = tx.commit().await {
        return HttpResponse::InternalServerError().json(Error {
            msg: "Transaction failed",
            error: "DB_ERROR".into(),
        });
    }

    HttpResponse::Ok().json(serde_json::json!({
        "message": "Domain invite code redeemed successfully",
        "domain_invite_codes_added": 1
    }))
}