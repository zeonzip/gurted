use godot::prelude::*;
use gurt::prelude::*;
use gurt::{GurtMethod, GurtRequest};
use tokio::runtime::Runtime;
use std::sync::Arc;
use std::cell::RefCell;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::TcpStream;

struct GurtGodotExtension;

#[gdextension]
unsafe impl ExtensionLibrary for GurtGodotExtension {}

#[derive(GodotClass)]
#[class(init)]
struct GurtProtocolClient {
    base: Base<RefCounted>,
    
    client: Arc<RefCell<Option<GurtClient>>>,
    runtime: Arc<RefCell<Option<Runtime>>>,
}

#[derive(GodotClass)]
#[class(init)]
struct GurtGDResponse {
    base: Base<RefCounted>,
    
    #[var]
    status_code: i32,
    
    #[var]
    status_message: GString,
    
    #[var]
    headers: Dictionary,
    
    #[var]
    is_success: bool,
    
    #[var]
    body: PackedByteArray, // Raw bytes
    
    #[var]
    text: GString,  // Decoded text
}

#[godot_api]
impl GurtGDResponse {
    #[func]
    fn get_header(&self, key: GString) -> GString {
        self.headers.get(key).map_or(GString::new(), |v| v.to::<GString>())
    }
    
    #[func]
    fn is_binary(&self) -> bool {
        let content_type = self.get_header("content-type".into()).to_string();
        content_type.starts_with("image/") ||
        content_type.starts_with("application/octet-stream") ||
        content_type.starts_with("video/") ||
        content_type.starts_with("audio/")
    }
    
    #[func]
    fn is_text(&self) -> bool {
        let content_type = self.get_header("content-type".into()).to_string();
        content_type.starts_with("text/") ||
        content_type.starts_with("application/json") ||
        content_type.starts_with("application/xml") ||
        content_type.is_empty()
    }
    
    #[func]
    fn debug_info(&self) -> GString {
        let content_length = self.get_header("content-length".into()).to_string();
        let actual_size = self.body.len();
        let content_type = self.get_header("content-type".into()).to_string();
        let size_match = content_length.parse::<usize>().unwrap_or(0) == actual_size;
        
        format!(
            "Status: {} | Type: {} | Length: {} | Actual: {} | Match: {}",
            self.status_code,
            content_type,
            content_length,
            actual_size,
            size_match
        ).into()
    }
}

#[derive(GodotClass)]
#[class(init)]
struct GurtProtocolServer {
    base: Base<RefCounted>,
}

#[godot_api]
impl GurtProtocolClient {
    #[signal]
    fn request_completed(response: Gd<GurtGDResponse>);
    
    #[func] 
    fn create_client(&mut self, timeout_seconds: i32) -> bool {
        let runtime = match Runtime::new() {
            Ok(rt) => rt,
            Err(e) => {
                godot_print!("Failed to create runtime: {}", e);
                return false;
            }
        };
        
        let mut config = ClientConfig::default();
        config.request_timeout = tokio::time::Duration::from_secs(timeout_seconds as u64);
        
        let client = GurtClient::with_config(config);
        
        *self.runtime.borrow_mut() = Some(runtime);
        *self.client.borrow_mut() = Some(client);

        true
    }
    
    #[func]
    fn request(&self, url: GString, options: Dictionary) -> Option<Gd<GurtGDResponse>> {
        let runtime_binding = self.runtime.borrow();
        let runtime = match runtime_binding.as_ref() {
            Some(rt) => rt,
            None => {
                godot_print!("No runtime available");
                return None;
            }
        };
        
        let url_str = url.to_string();
        
        // Parse URL to get host and port
        let parsed_url = match url::Url::parse(&url_str) {
            Ok(u) => u,
            Err(e) => {
                godot_print!("Invalid URL: {}", e);
                return None;
            }
        };

        let host = match parsed_url.host_str() {
            Some(h) => h,
            None => {
                godot_print!("URL must have a host");
                return None;
            }
        };

        let port = parsed_url.port().unwrap_or(4878);
        let path = if parsed_url.path().is_empty() { "/" } else { parsed_url.path() };
        
        let method_str = options.get("method").unwrap_or("GET".to_variant()).to::<String>();
        let method = match method_str.to_uppercase().as_str() {
            "GET" => GurtMethod::GET,
            "POST" => GurtMethod::POST,
            "PUT" => GurtMethod::PUT,
            "DELETE" => GurtMethod::DELETE,
            "PATCH" => GurtMethod::PATCH,
            "HEAD" => GurtMethod::HEAD,
            "OPTIONS" => GurtMethod::OPTIONS,
            _ => {
                godot_print!("Unsupported HTTP method: {}", method_str);
                GurtMethod::GET
            }
        };
        
        let response = match runtime.block_on(self.gurt_request_with_handshake(host, port, method, path)) {
            Ok(resp) => resp,
            Err(e) => {
                godot_print!("GURT request failed: {}", e);
                return None;
            }
        };
        
        Some(self.convert_response(response))
    }
    
    async fn gurt_request_with_handshake(&self, host: &str, port: u16, method: GurtMethod, path: &str) -> gurt::Result<GurtResponse> {
        let addr = format!("{}:{}", host, port);
        let mut stream = TcpStream::connect(&addr).await?;
        
        let handshake_request = GurtRequest::new(GurtMethod::HANDSHAKE, "/".to_string())
            .with_header("Host", host)
            .with_header("User-Agent", &format!("GURT-Client/{}", gurt::GURT_VERSION));
            
        let handshake_data = handshake_request.to_string();
        stream.write_all(handshake_data.as_bytes()).await?;
        
        let mut buffer = Vec::new();
        let mut temp_buffer = [0u8; 8192];
        
        loop {
            let bytes_read = stream.read(&mut temp_buffer).await?;
            if bytes_read == 0 {
                break;
            }
            buffer.extend_from_slice(&temp_buffer[..bytes_read]);
            
            let separator = b"\r\n\r\n";
            if buffer.windows(separator.len()).any(|w| w == separator) {
                break;
            }
        }
        
        let handshake_response = GurtResponse::parse_bytes(&buffer)?;
        
        if handshake_response.status_code != 101 {
            return Err(GurtError::handshake(format!("Handshake failed: {} {}", 
                handshake_response.status_code, 
                handshake_response.status_message)));
        }
        
        let tls_stream = self.create_secure_tls_connection(stream, host).await?;
        let (mut reader, mut writer) = tokio::io::split(tls_stream);
        
        let actual_request = GurtRequest::new(method, path.to_string())
            .with_header("Host", host)
            .with_header("User-Agent", &format!("GURT-Client/{}", gurt::GURT_VERSION))
            .with_header("Accept", "*/*");
        
        let request_data = actual_request.to_string();
        writer.write_all(request_data.as_bytes()).await?;
        
        let mut response_buffer = Vec::new();
        let mut temp_buf = [0u8; 8192];
        
        let mut headers_complete = false;
        while !headers_complete {
            let bytes_read = reader.read(&mut temp_buf).await?;
            if bytes_read == 0 {
                break;
            }
            response_buffer.extend_from_slice(&temp_buf[..bytes_read]);
            
            let separator = b"\r\n\r\n";
            if response_buffer.windows(separator.len()).any(|w| w == separator) {
                headers_complete = true;
            }
        }
        
        let response = GurtResponse::parse_bytes(&response_buffer)?;
        let content_length = response.header("content-length")
            .and_then(|s| s.parse::<usize>().ok())
            .unwrap_or(0);
        
        let separator_pos = response_buffer.windows(4).position(|w| w == b"\r\n\r\n").unwrap_or(0) + 4;
        let current_body_len = response_buffer.len().saturating_sub(separator_pos);
        
        if content_length > current_body_len {
            let remaining = content_length - current_body_len;
            let mut remaining_buffer = vec![0u8; remaining];
            match reader.read_exact(&mut remaining_buffer).await {
                Ok(_) => {
                    response_buffer.extend_from_slice(&remaining_buffer);
                }
                Err(e) => {
                    godot_error!("Failed to read remaining {} bytes: {}", remaining, e);
                    // Don't fail completely, try to parse what we have
                }
            }
        }
        
        drop(reader);
        drop(writer);
        
        let final_response = GurtResponse::parse_bytes(&response_buffer)?;
        
        Ok(final_response)
    }
    
    async fn create_secure_tls_connection(&self, stream: tokio::net::TcpStream, host: &str) -> gurt::Result<tokio_rustls::client::TlsStream<tokio::net::TcpStream>> {
        use tokio_rustls::rustls::{ClientConfig, RootCertStore};
        use std::sync::Arc;
        
        let mut root_store = RootCertStore::empty();
        
        let cert_result = rustls_native_certs::load_native_certs();
        let mut system_cert_count = 0;
        for cert in cert_result.certs {
            if root_store.add(cert).is_ok() {
                system_cert_count += 1;
            }
        }

        if system_cert_count <= 0 {
            godot_error!("No system certificates found. TLS connections will fail.");
        }
        
        let mut client_config = ClientConfig::builder()
            .with_root_certificates(root_store)
            .with_no_client_auth();
        
        client_config.alpn_protocols = vec![gurt::crypto::GURT_ALPN.to_vec()];
        
        let connector = tokio_rustls::TlsConnector::from(Arc::new(client_config));
        
        let server_name = match host {
            "127.0.0.1" => "localhost",
            "localhost" => "localhost",
            _ => host
        };
        
        let domain = tokio_rustls::rustls::pki_types::ServerName::try_from(server_name.to_string())
            .map_err(|e| GurtError::connection(format!("Invalid server name '{}': {}", server_name, e)))?;
                
        match connector.connect(domain, stream).await {
            Ok(tls_stream) => {
                Ok(tls_stream)
            }
            Err(e) => {
                godot_error!("TLS handshake failed: {}", e);
                Err(GurtError::connection(format!("TLS handshake failed: {}", e)))
            }
        }
    }
    
    #[func]
    fn disconnect(&mut self) {
        *self.client.borrow_mut() = None;
        *self.runtime.borrow_mut() = None;
    }
    
    #[func]
    fn is_connected(&self) -> bool {
        self.client.borrow().is_some()
    }
    
    #[func]
    fn get_version(&self) -> GString {
        gurt::GURT_VERSION.to_string().into()
    }
    
    #[func]
    fn get_default_port(&self) -> i32 {
        gurt::DEFAULT_PORT as i32
    }
    
    fn convert_response(&self, response: GurtResponse) -> Gd<GurtGDResponse> {
        let mut gd_response = GurtGDResponse::new_gd();
        
        gd_response.bind_mut().status_code = response.status_code as i32;
        gd_response.bind_mut().status_message = response.status_message.clone().into();
        gd_response.bind_mut().is_success = response.is_success();
        
        let mut headers = Dictionary::new();
        for (key, value) in &response.headers {
            headers.set(key.clone(), value.clone());
        }
        gd_response.bind_mut().headers = headers;
        
        let mut body = PackedByteArray::new();
        body.resize(response.body.len());
        for (i, byte) in response.body.iter().enumerate() {
            body[i] = *byte;
        }
        gd_response.bind_mut().body = body;
        
        match std::str::from_utf8(&response.body) {
            Ok(text_str) => {
                gd_response.bind_mut().text = text_str.into();
            }
            Err(_) => {
                let content_type = response.headers.get("content-type").cloned().unwrap_or_default();
                let size = response.body.len();
                gd_response.bind_mut().text = format!("[Binary data: {} ({} bytes)]", content_type, size).into();
            }
        }
        
        gd_response
    }
}