mod config;
mod http;
mod secret;
mod auth;
mod discord_bot;

use clap::{Parser, Subcommand};
use clap_verbosity_flag::{LogLevel, Verbosity};
use config::Config;
use macros_rs::fs::file_exists;

#[derive(Copy, Clone, Debug, Default)]
struct Info;
impl LogLevel for Info {
    fn default() -> Option<log::Level> { Some(log::Level::Info) }
}

#[derive(Parser)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
    #[clap(flatten)]
    verbose: Verbosity<Info>,
    #[arg(global = true, short, long, default_value_t = String::from("config.toml"), help = "config path")]
    config: String,
}

#[derive(Subcommand)]
enum Commands {
    /// Start the daemon
    Start,
}


fn main() {
    let cli = Cli::parse();
    let mut env = pretty_env_logger::formatted_builder();
    let level = cli.verbose.log_level_filter();

    env.filter_level(level).init();

    if !file_exists!(&cli.config) {
        Config::new().set_path(&cli.config).write();
        log::warn!("Written initial config, please configure database URL");
        std::process::exit(1);
    }

    match &cli.command {
        Commands::Start => {
            if let Err(err) = http::start(cli) {
                log::error!("Failed to start server: {err}")
            }
        }
    };
}
