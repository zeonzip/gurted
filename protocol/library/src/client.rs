use crate::{
    GurtError, Result, GurtRequest, GurtResponse,
    protocol::{DEFAULT_PORT, DEFAULT_CONNECTION_TIMEOUT, DEFAULT_REQUEST_TIMEOUT, DEFAULT_HANDSHAKE_TIMEOUT, BODY_SEPARATOR},
    message::GurtMethod,
};
use tokio::net::TcpStream;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::time::{timeout, Duration};
use url::Url;
use tracing::debug;

#[derive(Debug, Clone)]
pub struct ClientConfig {
    pub connect_timeout: Duration,
    pub request_timeout: Duration,
    pub handshake_timeout: Duration,
    pub user_agent: String,
    pub max_redirects: usize,
}

impl Default for ClientConfig {
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
struct PooledConnection {
    stream: TcpStream,
}

impl PooledConnection {
    fn new(stream: TcpStream) -> Self {
        Self { stream }
    }
}

pub struct GurtClient {
    config: ClientConfig,
}

impl GurtClient {
    pub fn new() -> Self {
        Self {
            config: ClientConfig::default(),
        }
    }
    
    pub fn with_config(config: ClientConfig) -> Self {
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
    
    async fn read_response_data(&self, stream: &mut TcpStream) -> Result<Vec<u8>> {
        let mut buffer = Vec::new();
        let mut temp_buffer = [0u8; 8192];
        
        let start_time = std::time::Instant::now();
        
        loop {
            if start_time.elapsed() > self.config.request_timeout {
                return Err(GurtError::timeout("Response timeout"));
            }
            
            let bytes_read = stream.read(&mut temp_buffer).await?;
            if bytes_read == 0 {
                break; // Connection closed
            }
            
            buffer.extend_from_slice(&temp_buffer[..bytes_read]);
            
            // Check for complete message without converting to string
            let body_separator = BODY_SEPARATOR.as_bytes();
            let has_complete_response = buffer.windows(body_separator.len()).any(|w| w == body_separator) ||
                (buffer.starts_with(b"{") && buffer.ends_with(b"}"));
            
            if has_complete_response {
                return Ok(buffer);
            }
        }
        
        if buffer.is_empty() {
            Err(GurtError::connection("Connection closed unexpectedly"))
        } else {
            Ok(buffer)
        }
    }
    
    async fn send_request_internal(&self, host: &str, port: u16, request: GurtRequest) -> Result<GurtResponse> {
        debug!("Sending {} {} to {}:{}", request.method, request.path, host, port);
        
        let mut conn = self.create_connection(host, port).await?;
        
        let request_data = request.to_string();
        conn.stream.write_all(request_data.as_bytes()).await?;
        
        let response_bytes = timeout(
            self.config.request_timeout,
            self.read_response_data(&mut conn.stream)
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