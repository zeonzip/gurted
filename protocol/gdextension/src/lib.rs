use godot::prelude::*;
use gurt::prelude::*;
use gurt::{GurtMethod, GurtClientConfig};
use tokio::runtime::Runtime;
use std::sync::Arc;
use std::cell::RefCell;

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
        
        let mut config = GurtClientConfig::default();
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
        
        let client_binding = self.client.borrow();
        let client = match client_binding.as_ref() {
            Some(c) => c,
            None => {
                godot_print!("No client available");
                return None;
            }
        };
        
        let url = format!("gurt://{}:{}{}", host, port, path);
        let response = match runtime.block_on(async {
            match method {
                GurtMethod::GET => client.get(&url).await,
                GurtMethod::POST => client.post(&url, "").await,
                GurtMethod::PUT => client.put(&url, "").await,
                GurtMethod::DELETE => client.delete(&url).await,
                GurtMethod::HEAD => client.head(&url).await,
                GurtMethod::OPTIONS => client.options(&url).await,
                GurtMethod::PATCH => client.patch(&url, "").await,
                _ => {
                    godot_print!("Unsupported method: {:?}", method);
                    return Err(GurtError::invalid_message("Unsupported method"));
                }
            }
        }) {
            Ok(resp) => resp,
            Err(e) => {
                godot_print!("GURT request failed: {}", e);
                return None;
            }
        };
        
        Some(self.convert_response(response))
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