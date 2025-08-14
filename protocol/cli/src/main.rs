use clap::{Parser, Subcommand};
use colored::Colorize;
use gurt::prelude::*;
use std::path::PathBuf;
use tracing::error;
use tracing_subscriber;

#[derive(Parser)]
#[command(name = "server")]
#[command(about = "GURT Protocol Server")]
#[command(version = "1.0.0")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    Serve {
        #[arg(short, long, default_value_t = 4878)]
        port: u16,
        
        #[arg(long, default_value = "127.0.0.1")]
        host: String,
        
        #[arg(short, long, default_value = ".")]
        dir: PathBuf,
        
        #[arg(short, long)]
        verbose: bool,
        
        #[arg(long, help = "Path to TLS certificate file")]
        cert: Option<PathBuf>,
        
        #[arg(long, help = "Path to TLS private key file")]
        key: Option<PathBuf>,
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();
    
    match cli.command {
        Commands::Serve { port, host, dir, verbose, cert, key } => {
            if verbose {
                tracing_subscriber::fmt()
                    .with_max_level(tracing::Level::DEBUG)
                    .init();
            } else {
                tracing_subscriber::fmt()
                    .with_max_level(tracing::Level::INFO)
                    .init();
            }
            
            println!("{}", "GURT Protocol Server".bright_cyan().bold());
            println!("{} {}:{}", "Listening on".bright_blue(), host, port);
            println!("{} {}", "Serving from".bright_blue(), dir.display());
            
            let server = create_file_server(dir, cert, key)?;
            let addr = format!("{}:{}", host, port);
            
            if let Err(e) = server.listen(&addr).await {
                error!("Server error: {}", e);
                std::process::exit(1);
            }
        }
    }
    
    Ok(())
}

fn create_file_server(base_dir: PathBuf, cert_path: Option<PathBuf>, key_path: Option<PathBuf>) -> Result<GurtServer> {
    let base_dir = std::sync::Arc::new(base_dir);
    
    let server = match (cert_path, key_path) {
        (Some(cert), Some(key)) => {
            println!("TLS using certificate: {}", cert.display());
            GurtServer::with_tls_certificates(
                cert.to_str().ok_or_else(|| GurtError::invalid_message("Invalid certificate path"))?,
                key.to_str().ok_or_else(|| GurtError::invalid_message("Invalid key path"))?
            )?
        }
        (Some(_), None) => {
            return Err(GurtError::invalid_message("Certificate provided but no key file specified (use --key)"));
        }
        (None, Some(_)) => {
            return Err(GurtError::invalid_message("Key provided but no certificate file specified (use --cert)"));
        }
        (None, None) => {
            return Err(GurtError::invalid_message("GURT protocol requires TLS encryption. Please provide --cert and --key parameters."));
        }
    };
    
    let server = server
        .get("/", {
            let base_dir = base_dir.clone();
            move |ctx| {
                let client_ip = ctx.client_ip();
                let base_dir = base_dir.clone();
                async move {
                    // Try to serve index.html if it exists, otherwise show server info
                    let index_path = base_dir.join("index.html");

                    if index_path.exists() && index_path.is_file() {
                        match std::fs::read_to_string(&index_path) {
                            Ok(content) => {
                                return Ok(GurtResponse::ok()
                                    .with_header("Content-Type", "text/html")
                                    .with_string_body(content));
                            }
                            Err(_) => {
                                // Fall through to default page
                            }
                        }
                    }
                    
                    // Default server info page
                    Ok(GurtResponse::ok()
                        .with_header("Content-Type", "text/html")
                        .with_string_body(format!(r#"
<!DOCTYPE html>
<html>
<head>
    <title>GURT Protocol Server</title>
    <style>
        body {{ font-sans m-[30px] bg-[#f5f5f5] }}
        .header {{ text-[#0066cc] }}
        .status {{ text-[#28a745] font-bold }}
    </style>
</head>
<body>
    <h1 class="header">Welcome to the GURT Protocol!</h1>
    <p class="status">This server is successfully running. We couldn't find index.html though :(</p>
    <p>Protocol: <strong>GURT/{}</strong></p>
    <p>Client IP: <strong>{}</strong></p>
</body>
</html>
                        "#,
                        gurt::GURT_VERSION,
                        client_ip,
                    )))
                }
            }
        })
        .get("/*", {
            let base_dir = base_dir.clone();
            move |ctx| {
                let base_dir = base_dir.clone();
                let path = ctx.path().to_string();
                async move {
                    let mut relative_path = path.strip_prefix('/').unwrap_or(&path).to_string();
                    // Remove any leading slashes to ensure relative path
                    while relative_path.starts_with('/') || relative_path.starts_with('\\') {
                        relative_path = relative_path[1..].to_string();
                    }
                    // If the path is now empty, use "."
                    let relative_path = if relative_path.is_empty() { ".".to_string() } else { relative_path };
                    let file_path = base_dir.join(&relative_path);

                    match file_path.canonicalize() {
                        Ok(canonical_path) => {
                            let canonical_base = match base_dir.canonicalize() {
                                Ok(base) => base,
                                Err(_) => {
                                    return Ok(GurtResponse::internal_server_error()
                                        .with_header("Content-Type", "text/plain")
                                        .with_string_body("Server configuration error"));
                                }
                            };

                            if !canonical_path.starts_with(&canonical_base) {
                                return Ok(GurtResponse::bad_request()
                                    .with_header("Content-Type", "text/plain")
                                    .with_string_body("Access denied: Path outside served directory"));
                            }
                            
                            if canonical_path.is_file() {
                                match std::fs::read(&canonical_path) {
                                    Ok(content) => {
                                        let content_type = get_content_type(&canonical_path);
                                        Ok(GurtResponse::ok()
                                            .with_header("Content-Type", &content_type)
                                            .with_body(content))
                                    }
                                    Err(_) => {
                                        Ok(GurtResponse::internal_server_error()
                                            .with_header("Content-Type", "text/plain")
                                            .with_string_body("Failed to read file"))
                                    }
                                }
                            } else if canonical_path.is_dir() {
                                let index_path = canonical_path.join("index.html");
                                if index_path.is_file() {
                                    match std::fs::read_to_string(&index_path) {
                                        Ok(content) => {
                                            Ok(GurtResponse::ok()
                                                .with_header("Content-Type", "text/html")
                                                .with_string_body(content))
                                        }
                                        Err(_) => {
                                            Ok(GurtResponse::internal_server_error()
                                                .with_header("Content-Type", "text/plain")
                                                .with_string_body("Failed to read index file"))
                                        }
                                    }
                                } else {
                                    match std::fs::read_dir(&canonical_path) {
                                        Ok(entries) => {
                                            let mut listing = String::from(r#"
<!DOCTYPE html>
<html>
<head>
    <title>Directory Listing</title>
    <style>
        body { font-sans m-[40px] }
        .file { my-1 }
        .dir { font-bold text-[#0066cc] }
    </style>
</head>
<body>
    <h1>Directory Listing</h1>
    <p><a href="../">← Parent Directory</a></p>
    <div style="flex flex-col gap-2">
"#);
                                            for entry in entries.flatten() {
                                                let file_name = entry.file_name();
                                                let name = file_name.to_string_lossy();
                                                let is_dir = entry.path().is_dir();
                                                let display_name = if is_dir { format!("{}/", name) } else { name.to_string() };
                                                let class = if is_dir { "file dir" } else { "file" };
                                                
                                                listing.push_str(&format!(
                                                    r#"    <a style={} href="/{}">{}</a>"#,
                                                    class, name, display_name
                                                ));
                                                listing.push('\n');
                                            }
                                            
                                            listing.push_str("</div></body>\n</html>");

                                            Ok(GurtResponse::ok()
                                                .with_header("Content-Type", "text/html")
                                                .with_string_body(listing))
                                        }
                                        Err(_) => {
                                            Ok(GurtResponse::internal_server_error()
                                                .with_header("Content-Type", "text/plain")
                                                .with_string_body("Failed to read directory"))
                                        }
                                    }
                                }
                            } else {
                                // File not found
                                Ok(GurtResponse::not_found()
                                    .with_header("Content-Type", "text/html")
                                    .with_string_body(get_404_html()))
                            }
                        }
                        Err(_e) => {
                            Ok(GurtResponse::not_found()
                                .with_header("Content-Type", "text/html")
                                .with_string_body(get_404_html()))
                        }
                    }
                }
            }
        });
    
    Ok(server)
}

fn get_404_html() -> &'static str {
    r#"<!DOCTYPE html>
<html>
<head>
    <title>404 Not Found</title>
    <style>
        body { font-sans m-[40px] text-center }
    </style>
</head>
<body>
    <h1>404 Page Not Found</h1>
    <p>The requested path was not found on this GURT server.</p>
    <p><a href="/">Back to home</a></p>
</body>
</html>
"#
}

fn get_content_type(path: &std::path::Path) -> String {
    match path.extension().and_then(|ext| ext.to_str()) {
        Some("html") | Some("htm") => "text/html".to_string(),
        Some("css") => "text/css".to_string(),
        Some("js") => "application/javascript".to_string(),
        Some("json") => "application/json".to_string(),
        Some("png") => "image/png".to_string(),
        Some("jpg") | Some("jpeg") => "image/jpeg".to_string(),
        Some("gif") => "image/gif".to_string(),
        Some("svg") => "image/svg+xml".to_string(),
        Some("ico") => "image/x-icon".to_string(),
        Some("txt") => "text/plain".to_string(),
        Some("xml") => "application/xml".to_string(),
        Some("pdf") => "application/pdf".to_string(),
        _ => "application/octet-stream".to_string(),
    }
}