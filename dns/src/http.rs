mod auth_routes;
mod helpers;
mod models;
mod ratelimit;
mod routes;

use crate::{auth::jwt_middleware, config::Config, discord_bot};
use actix_governor::{Governor, GovernorConfigBuilder};
use actix_web::{http::Method, web, web::Data, App, HttpServer};
use actix_web_httpauth::middleware::HttpAuthentication;
use colored::Colorize;
use macros_rs::fmt::{crashln, string};
use ratelimit::RealIpKeyExtractor;
use std::{net::IpAddr, str::FromStr, time::Duration};

// Domain struct is now defined in models.rs

#[derive(Clone)]
pub(crate) struct AppState {
    trusted: IpAddr,
    config: Config,
    db: sqlx::PgPool,
}


#[actix_web::main]
pub async fn start(cli: crate::Cli) -> std::io::Result<()> {
    let config = Config::new().set_path(&cli.config).read();

    let trusted_ip = match IpAddr::from_str(&config.server.address) {
        Ok(addr) => addr,
        Err(err) => crashln!("Cannot parse address.\n{}", string!(err).white()),
    };

    let governor_builder = GovernorConfigBuilder::default()
        .methods(vec![Method::POST])
        .period(Duration::from_secs(600))
        .burst_size(5)
        .key_extractor(RealIpKeyExtractor)
        .finish()
        .unwrap();

    let db = match config.connect_to_db().await {
        Ok(pool) => pool,
        Err(err) => crashln!("Failed to connect to PostgreSQL database.\n{}", string!(err).white()),
    };

    // Start Discord bot
    if !config.discord.bot_token.is_empty() {
        if let Err(e) = discord_bot::start_discord_bot(config.discord.bot_token.clone(), db.clone()).await {
            log::error!("Failed to start Discord bot: {}", e);
        }
    }

    let auth_middleware = HttpAuthentication::bearer(jwt_middleware);
    let jwt_secret = config.auth.jwt_secret.clone();

    let app = move || {
        let data = AppState {
            db: db.clone(),
            trusted: trusted_ip,
            config: Config::new().set_path(&cli.config).read(),
        };

        App::new()
            .app_data(Data::new(data))
            .app_data(Data::new(jwt_secret.clone()))
            // Public routes
            .service(routes::index)
            .service(routes::get_domain)
            .service(routes::get_domains)
            .service(routes::get_tlds)
            .service(routes::check_domain)
            // Auth routes
            .service(auth_routes::register)
            .service(auth_routes::login)
            // Protected routes
            .service(
                web::scope("")
                    .wrap(auth_middleware.clone())
                    .service(auth_routes::get_user_info)
                    .service(auth_routes::create_invite)
                    .service(auth_routes::redeem_invite)
                    .service(auth_routes::create_domain_invite)
                    .service(auth_routes::redeem_domain_invite)
                    .service(routes::update_domain)
                    .service(routes::delete_domain)
                    .route("/domain", web::post().to(routes::create_domain).wrap(Governor::new(&governor_builder)))
            )
    };

    log::info!("Listening on {}", config.get_address());
    HttpServer::new(app).bind(config.get_address())?.run().await
}
