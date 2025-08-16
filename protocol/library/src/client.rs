use crate::{
    GurtError, Result, GurtRequest, GurtResponse,
    protocol::{DEFAULT_PORT, DEFAULT_CONNECTION_TIMEOUT, DEFAULT_REQUEST_TIMEOUT, DEFAULT_HANDSHAKE_TIMEOUT, BODY_SEPARATOR},
    message::GurtMethod,
    crypto::GURT_ALPN,
};
use tokio::net::TcpStream;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::time::{timeout, Duration};
use tokio_rustls::{TlsConnector, rustls::{ClientConfig as TlsClientConfig, RootCertStore, pki_types::ServerName}};
use std::sync::Arc;
use url::Url;
use tracing::debug;

#[derive(Debug, Clone)]
pub struct GurtClientConfig {
    pub connect_timeout: Duration,
    pub request_timeout: Duration,
    pub handshake_timeout: Duration,
    pub user_agent: String,
    pub max_redirects: usize,
}

impl Default for GurtClientConfig {
    fn default() -> Self {
        Self {
            connect_timeout: Duration::from_secs(DEFAULT_CONNECTION_TIMEOUT),
            request_timeout: Duration::from_secs(DEFAULT_REQUEST_TIMEOUT),
            handshake_timeout: Duration::from_secs(DEFAULT_HANDSHAKE_TIMEOUT),
            user_agent: format!("GURT-Client/{}", crate::GURT_VERSION),
            max_redirects: 5,
        }
    }
}

#[derive(Debug)]
enum Connection {
    Plain(TcpStream),
    Tls(tokio_rustls::client::TlsStream<TcpStream>),
}

impl Connection {
    async fn read(&mut self, buf: &mut [u8]) -> Result<usize> {
        match self {
            Connection::Plain(stream) => stream.read(buf).await.map_err(|e| GurtError::connection(e.to_string())),
            Connection::Tls(stream) => stream.read(buf).await.map_err(|e| GurtError::connection(e.to_string())),
        }
    }
    
    async fn write_all(&mut self, buf: &[u8]) -> Result<()> {
        match self {
            Connection::Plain(stream) => stream.write_all(buf).await.map_err(|e| GurtError::connection(e.to_string())),
            Connection::Tls(stream) => stream.write_all(buf).await.map_err(|e| GurtError::connection(e.to_string())),
        }
    }
}

#[derive(Debug)]
struct PooledConnection {
    connection: Connection,
}

impl PooledConnection {
    fn new(stream: TcpStream) -> Self {
        Self { connection: Connection::Plain(stream) }
    }
    
    fn with_tls(stream: tokio_rustls::client::TlsStream<TcpStream>) -> Self {
        Self { connection: Connection::Tls(stream) }
    }
}

pub struct GurtClient {
    config: GurtClientConfig,
}

impl GurtClient {
    pub fn new() -> Self {
        Self {
            config: GurtClientConfig::default(),
        }
    }
    
    pub fn with_config(config: GurtClientConfig) -> Self {
        Self {
            config,
        }
    }
    
    async fn create_connection(&self, host: &str, port: u16) -> Result<PooledConnection> {
        let addr = format!("{}:{}", host, port);
        let stream = timeout(
            self.config.connect_timeout,
            TcpStream::connect(&addr)
        ).await
            .map_err(|_| GurtError::timeout("Connection timeout"))?
            .map_err(|e| GurtError::connection(format!("Failed to connect: {}", e)))?;
        
        let conn = PooledConnection::new(stream);
        Ok(conn)
    }
    
    async fn read_response_data(&self, conn: &mut PooledConnection) -> Result<Vec<u8>> {
        let mut buffer = Vec::new();
        let mut temp_buffer = [0u8; 8192];
        
        let start_time = std::time::Instant::now();
        let mut headers_parsed = false;
        let mut expected_body_length: Option<usize> = None;
        let mut headers_end_pos: Option<usize> = None;
        
        loop {
            if start_time.elapsed() > self.config.request_timeout {
                return Err(GurtError::timeout("Response timeout"));
            }
            
            let bytes_read = conn.connection.read(&mut temp_buffer).await?;
            if bytes_read == 0 {
                break; // Connection closed
            }
            
            buffer.extend_from_slice(&temp_buffer[..bytes_read]);
            
            // Check for complete message
            let body_separator = BODY_SEPARATOR.as_bytes();
            
            if !headers_parsed {
                if let Some(pos) = buffer.windows(body_separator.len()).position(|w| w == body_separator) {
                    headers_end_pos = Some(pos + body_separator.len());
                    headers_parsed = true;
                    
                    // Parse headers to get Content-Length
                    let headers_section = &buffer[..pos];
                    if let Ok(headers_str) = std::str::from_utf8(headers_section) {
                        for line in headers_str.lines() {
                            if line.to_lowercase().starts_with("content-length:") {
                                if let Some(length_str) = line.split(':').nth(1) {
                                    if let Ok(length) = length_str.trim().parse::<usize>() {
                                        expected_body_length = Some(length);
                                    }
                                }
                                break;
                            }
                        }
                    }
                }
            }
            
            if let (Some(headers_end), Some(expected_length)) = (headers_end_pos, expected_body_length) {
                let current_body_length = buffer.len() - headers_end;
                if current_body_length >= expected_length {
                    return Ok(buffer);
                }
            } else if headers_parsed && expected_body_length.is_none() {
                // No Content-Length header, return what we have after headers
                return Ok(buffer);
            }
        }
        
        if buffer.is_empty() {
            Err(GurtError::connection("Connection closed unexpectedly"))
        } else {
            Ok(buffer)
        }
    }
    
    async fn perform_handshake(&self, host: &str, port: u16) -> Result<tokio_rustls::client::TlsStream<TcpStream>> {
        debug!("Starting GURT handshake with {}:{}", host, port);
        
        let mut plain_conn = self.create_connection(host, port).await?;
        
        let handshake_request = GurtRequest::new(GurtMethod::HANDSHAKE, "/".to_string())
            .with_header("Host", host)
            .with_header("User-Agent", &self.config.user_agent);
        
        let handshake_data = handshake_request.to_string();
        plain_conn.connection.write_all(handshake_data.as_bytes()).await?;
        
        let handshake_response_bytes = timeout(
            self.config.handshake_timeout,
            self.read_response_data(&mut plain_conn)
        ).await
            .map_err(|_| GurtError::timeout("Handshake timeout"))??;
        
        let handshake_response = GurtResponse::parse_bytes(&handshake_response_bytes)?;
        
        if handshake_response.status_code != 101 {
            return Err(GurtError::protocol(format!("Handshake failed: {} {}", 
                handshake_response.status_code, 
                handshake_response.status_message)));
        }
        
        let tcp_stream = match plain_conn.connection {
            Connection::Plain(stream) => stream,
            _ => return Err(GurtError::protocol("Expected plain connection for handshake")),
        };
        
        self.upgrade_to_tls(tcp_stream, host).await
    }
    
    async fn upgrade_to_tls(&self, stream: TcpStream, host: &str) -> Result<tokio_rustls::client::TlsStream<TcpStream>> {
        debug!("Upgrading connection to TLS for {}", host);
        
        let mut root_store = RootCertStore::empty();
        
        let cert_result = rustls_native_certs::load_native_certs();
        let mut added = 0;
        for cert in cert_result.certs {
            if root_store.add(cert).is_ok() {
                added += 1;
            }
        }
        if added == 0 {
            return Err(GurtError::crypto("No valid system certificates found".to_string()));
        }
        
        let mut client_config = TlsClientConfig::builder()
            .with_root_certificates(root_store)
            .with_no_client_auth();
        
        client_config.alpn_protocols = vec![GURT_ALPN.to_vec()];
        
        let connector = TlsConnector::from(Arc::new(client_config));
        
        let server_name = match host {
            "127.0.0.1" => "localhost",
            "localhost" => "localhost", 
            _ => host
        };
        
        let domain = ServerName::try_from(server_name.to_string())
            .map_err(|e| GurtError::crypto(format!("Invalid server name '{}': {}", server_name, e)))?;
        
        let tls_stream = connector.connect(domain, stream).await
            .map_err(|e| GurtError::crypto(format!("TLS handshake failed: {}", e)))?;
        
        debug!("TLS connection established with {}", host);
        Ok(tls_stream)
    }
    
    async fn send_request_internal(&self, host: &str, port: u16, request: GurtRequest) -> Result<GurtResponse> {
        debug!("Sending {} {} to {}:{}", request.method, request.path, host, port);
        
        let tls_stream = self.perform_handshake(host, port).await?;
        let mut conn = PooledConnection::with_tls(tls_stream);
        
        let request_data = request.to_string();
        conn.connection.write_all(request_data.as_bytes()).await?;
        
        let response_bytes = timeout(
            self.config.request_timeout,
            self.read_response_data(&mut conn)
        ).await
            .map_err(|_| GurtError::timeout("Request timeout"))??;
        
        let response = GurtResponse::parse_bytes(&response_bytes)?;
        
        Ok(response)
    }
    
    pub async fn get(&self, url: &str) -> Result<GurtResponse> {
        let (host, port, path) = self.parse_url(url)?;
        let request = GurtRequest::new(GurtMethod::GET, path)
            .with_header("Host", &host)
            .with_header("User-Agent", &self.config.user_agent)
            .with_header("Accept", "*/*");
        
        self.send_request_internal(&host, port, request).await
    }
    
    pub async fn post(&self, url: &str, body: &str) -> Result<GurtResponse> {
        let (host, port, path) = self.parse_url(url)?;
        let request = GurtRequest::new(GurtMethod::POST, path)
            .with_header("Host", &host)
            .with_header("User-Agent", &self.config.user_agent)
            .with_header("Content-Type", "text/plain")
            .with_string_body(body);
        
        self.send_request_internal(&host, port, request).await
    }
    
    /// POST request with JSON body
    pub async fn post_json<T: serde::Serialize>(&self, url: &str, data: &T) -> Result<GurtResponse> {
        let (host, port, path) = self.parse_url(url)?;
        let json_body = serde_json::to_string(data)?;
        
        let request = GurtRequest::new(GurtMethod::POST, path)
            .with_header("Host", &host)
            .with_header("User-Agent", &self.config.user_agent)
            .with_header("Content-Type", "application/json")
            .with_string_body(json_body);
        
        self.send_request_internal(&host, port, request).await
    }

    /// PUT request with body
    pub async fn put(&self, url: &str, body: &str) -> Result<GurtResponse> {
        let (host, port, path) = self.parse_url(url)?;
        let request = GurtRequest::new(GurtMethod::PUT, path)
            .with_header("Host", &host)
            .with_header("User-Agent", &self.config.user_agent)
            .with_header("Content-Type", "text/plain")
            .with_string_body(body);
        
        self.send_request_internal(&host, port, request).await
    }

    /// PUT request with JSON body
    pub async fn put_json<T: serde::Serialize>(&self, url: &str, data: &T) -> Result<GurtResponse> {
        let (host, port, path) = self.parse_url(url)?;
        let json_body = serde_json::to_string(data)?;
        
        let request = GurtRequest::new(GurtMethod::PUT, path)
            .with_header("Host", &host)
            .with_header("User-Agent", &self.config.user_agent)
            .with_header("Content-Type", "application/json")
            .with_string_body(json_body);
        
        self.send_request_internal(&host, port, request).await
    }

    pub async fn delete(&self, url: &str) -> Result<GurtResponse> {
        let (host, port, path) = self.parse_url(url)?;
        let request = GurtRequest::new(GurtMethod::DELETE, path)
            .with_header("Host", &host)
            .with_header("User-Agent", &self.config.user_agent);
        
        self.send_request_internal(&host, port, request).await
    }

    pub async fn head(&self, url: &str) -> Result<GurtResponse> {
        let (host, port, path) = self.parse_url(url)?;
        let request = GurtRequest::new(GurtMethod::HEAD, path)
            .with_header("Host", &host)
            .with_header("User-Agent", &self.config.user_agent);
        
        self.send_request_internal(&host, port, request).await
    }

    pub async fn options(&self, url: &str) -> Result<GurtResponse> {
        let (host, port, path) = self.parse_url(url)?;
        let request = GurtRequest::new(GurtMethod::OPTIONS, path)
            .with_header("Host", &host)
            .with_header("User-Agent", &self.config.user_agent);
        
        self.send_request_internal(&host, port, request).await
    }

    /// PATCH request with body
    pub async fn patch(&self, url: &str, body: &str) -> Result<GurtResponse> {
        let (host, port, path) = self.parse_url(url)?;
        let request = GurtRequest::new(GurtMethod::PATCH, path)
            .with_header("Host", &host)
            .with_header("User-Agent", &self.config.user_agent)
            .with_header("Content-Type", "text/plain")
            .with_string_body(body);
        
        self.send_request_internal(&host, port, request).await
    }

    /// PATCH request with JSON body
    pub async fn patch_json<T: serde::Serialize>(&self, url: &str, data: &T) -> Result<GurtResponse> {
        let (host, port, path) = self.parse_url(url)?;
        let json_body = serde_json::to_string(data)?;
        
        let request = GurtRequest::new(GurtMethod::PATCH, path)
            .with_header("Host", &host)
            .with_header("User-Agent", &self.config.user_agent)
            .with_header("Content-Type", "application/json")
            .with_string_body(json_body);
        
        self.send_request_internal(&host, port, request).await
    }
    
    pub async fn send_request(&self, host: &str, port: u16, request: GurtRequest) -> Result<GurtResponse> {
        self.send_request_internal(host, port, request).await
    }
    
    fn parse_url(&self, url: &str) -> Result<(String, u16, String)> {
        let parsed_url = Url::parse(url).map_err(|e| GurtError::invalid_message(format!("Invalid URL: {}", e)))?;
        
        if parsed_url.scheme() != "gurt" {
            return Err(GurtError::invalid_message("URL must use gurt:// scheme"));
        }
        
        let host = parsed_url.host_str()
            .ok_or_else(|| GurtError::invalid_message("URL must have a host"))?
            .to_string();
        
        let port = parsed_url.port().unwrap_or(DEFAULT_PORT);
        
        let path = if parsed_url.path().is_empty() {
            "/".to_string()
        } else {
            parsed_url.path().to_string()
        };
        
        Ok((host, port, path))
    }
    
}

impl Default for GurtClient {
    fn default() -> Self {
        Self::new()
    }
}

impl Clone for GurtClient {
    fn clone(&self) -> Self {
        Self {
            config: self.config.clone(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[tokio::test]
    async fn test_url_parsing() {
        let client = GurtClient::new();
        
        let (host, port, path) = client.parse_url("gurt://example.com/test").unwrap();
        assert_eq!(host, "example.com");
        assert_eq!(port, DEFAULT_PORT);
        assert_eq!(path, "/test");
        
        let (host, port, path) = client.parse_url("gurt://example.com:8080/api/v1").unwrap();
        assert_eq!(host, "example.com");
        assert_eq!(port, 8080);
        assert_eq!(path, "/api/v1");
    }
}