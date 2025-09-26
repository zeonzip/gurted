use godot::prelude::*;
use gurtlib::prelude::*;
use gurtlib::{GurtMethod, GurtClientConfig, GurtRequest, GurtResponseHead};
use std::cell::RefCell;
use std::fs::File;
use std::io::Write;
use std::sync::Arc;
use std::sync::Mutex;
use std::collections::HashMap;
use tokio::runtime::Runtime;

struct GurtGodotExtension;

#[gdextension]
unsafe impl ExtensionLibrary for GurtGodotExtension {}

#[derive(GodotClass)]
#[class(init)]
struct GurtProtocolClient {
    base: Base<RefCounted>,

    client: Arc<RefCell<Option<GurtClient>>>,
    runtime: Arc<RefCell<Option<Runtime>>>,
    ca_certificates: Arc<RefCell<Vec<String>>>,
    cancel_flags: Arc<Mutex<HashMap<String, bool>>>,
    event_queue: Arc<Mutex<Vec<DownloadEvent>>>,
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

struct DLState { file: Option<std::fs::File>, total_bytes: i64, downloaded: i64 }


#[derive(Clone)]
enum DownloadEvent {
    Started(String, i64),
    Progress(String, i64, i64),
    Completed(String, String),
    Failed(String, String),
}

#[godot_api]
impl GurtProtocolClient {
    fn init(base: Base<RefCounted>) -> Self {
        Self {
            base,
            client: Arc::new(RefCell::new(None)),
            runtime: Arc::new(RefCell::new(None)),
            ca_certificates: Arc::new(RefCell::new(Vec::new())),
            cancel_flags: Arc::new(Mutex::new(HashMap::new())),
            event_queue: Arc::new(Mutex::new(Vec::new())),
        }
    }

    #[signal]
    fn request_completed(response: Gd<GurtGDResponse>);

    #[signal]
    fn download_started(download_id: GString, total_bytes: i64);

    #[signal]
    fn download_progress(download_id: GString, downloaded_bytes: i64, total_bytes: i64);

    #[signal]
    fn download_completed(download_id: GString, save_path: GString);

    #[signal]
    fn download_failed(download_id: GString, message: GString);

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

        // Add custom CA certificates
        config.custom_ca_certificates = self.ca_certificates.borrow().clone();

        let client = GurtClient::with_config(config);

        *self.runtime.borrow_mut() = Some(runtime);
        *self.client.borrow_mut() = Some(client);

        true
    }

    #[func]
    fn create_client_with_dns(&mut self, timeout_seconds: i32, dns_ip: GString, dns_port: i32) -> bool {
        let runtime = match Runtime::new() {
            Ok(rt) => rt,
            Err(e) => {
                godot_print!("Failed to create runtime: {}", e);
                return false;
            }
        };

        let mut config = GurtClientConfig::default();
        config.request_timeout = tokio::time::Duration::from_secs(timeout_seconds as u64);
        config.dns_server_ip = dns_ip.to_string();
        config.dns_server_port = dns_port as u16;

        config.custom_ca_certificates = self.ca_certificates.borrow().clone();

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
        let path_with_query = if parsed_url.path().is_empty() {
            "/"
        } else {
            parsed_url.path()
        };

        let path = match parsed_url.query() {
            Some(query) => format!("{}?{}", path_with_query, query),
            None => path_with_query.to_string(),
        };

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

        let body = options.get("body").unwrap_or("".to_variant()).to::<String>();
        let headers_dict = options.get("headers").unwrap_or(Dictionary::new().to_variant()).to::<Dictionary>();

        let mut request = GurtRequest::new(method, path.to_string())
            .with_header("User-Agent", "GURT-Client/1.0.0");

        for key_variant in headers_dict.keys_array().iter_shared() {
            let key = key_variant.to::<String>();
            if let Some(value_variant) = headers_dict.get(key_variant) {
                let value = value_variant.to::<String>();
                request = request.with_header(key, value);
            }
        }

        if !body.is_empty() {
            request = request.with_string_body(&body);
        }

        let response = match runtime.block_on(async {
            client.send_request(host, port, request).await
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
    fn start_download(&mut self, download_id: GString, url: GString, save_path: GString) -> bool {
        let runtime_handle = {
            let runtime_binding = self.runtime.borrow();
            match runtime_binding.as_ref() {
                Some(rt) => rt.handle().clone(),
                None => { godot_print!("No runtime available"); return false; }
            }
        };

        let client_instance = {
            let client_binding = self.client.borrow();
            match client_binding.as_ref() {
                Some(c) => c.clone(),
                None => { godot_print!("No client available"); return false; }
            }
        };

        let url_str = url.to_string();
        let save_path_str = save_path.to_string();
        let download_id_string = download_id.to_string();
        let cancel_flags = self.cancel_flags.clone();
        let event_queue = self.event_queue.clone();

        runtime_handle.spawn(async move {
            let event_queue_main = event_queue.clone();
            let parsed_url = match url::Url::parse(&url_str) { Ok(u) => u, Err(e) => {
                if let Ok(mut q) = event_queue.lock() { q.push(DownloadEvent::Failed(download_id_string.clone(), format!("Invalid URL: {}", e))); }
                return;
            }};
            let host = match parsed_url.host_str() { Some(h) => h.to_string(), None => {
                if let Ok(mut q) = event_queue.lock() { q.push(DownloadEvent::Failed(download_id_string.clone(), "URL must have a host".to_string())); }
                return;
            }};
            let port = parsed_url.port().unwrap_or(4878);
            let path_with_query = if parsed_url.path().is_empty() { "/".to_string() } else { parsed_url.path().to_string() };
            let path = match parsed_url.query() { Some(query) => format!("{}?{}", path_with_query, query), None => path_with_query };

        let state = Arc::new(Mutex::new(DLState { file: None, total_bytes: -1, downloaded: 0 }));

            let request = GurtRequest::new(GurtMethod::GET, path).with_header("User-Agent", "GURT-Client/1.0.0");

            let state_head = state.clone();
            let event_queue_head = event_queue.clone();
            let id_for_head = download_id_string.clone();
            let sp_for_head = save_path_str.clone();
            let on_head = move |head: &GurtResponseHead| {
                if head.status_code < 200 || head.status_code >= 300 {
                    if let Ok(mut q) = event_queue_head.lock() { q.push(DownloadEvent::Failed(id_for_head.clone(), format!("{} {}", head.status_code, head.status_message))); }
                    return;
                }
                let mut total: i64 = -1;
                if let Some(cl) = head.headers.get("content-length").or_else(|| head.headers.get("Content-Length")) {
                    if let Ok(v) = cl.parse::<i64>() { total = v; }
                }
                match File::create(&sp_for_head) {
                    Ok(f) => {
                        if let Ok(mut st) = state_head.lock() { st.file = Some(f); st.total_bytes = total; }
                    }
                    Err(e) => { if let Ok(mut q) = event_queue_head.lock() { q.push(DownloadEvent::Failed(id_for_head.clone(), format!("File error: {}", e))); } }
                }
                if let Ok(mut q) = event_queue_head.lock() { q.push(DownloadEvent::Started(id_for_head.clone(), total)); }
            };

            let state_chunk = state.clone();
            let event_queue_chunk = event_queue.clone();
            let id_for_chunk = download_id_string.clone();
            let on_chunk = move |chunk: &[u8]| -> bool {
                if let Ok(map) = cancel_flags.lock() {
                    if map.get(&id_for_chunk).copied().unwrap_or(false) { return false; }
                }
                let mut down = 0i64; let mut total = -1i64; let mut write_result: std::io::Result<()> = Ok(());
                if let Ok(mut st) = state_chunk.lock() {
                    if let Some(f) = st.file.as_mut() { write_result = f.write_all(chunk); }
                    st.downloaded += chunk.len() as i64; down = st.downloaded; total = st.total_bytes;
                }
                if let Err(e) = write_result { if let Ok(mut q) = event_queue_chunk.lock() { q.push(DownloadEvent::Failed(id_for_chunk.clone(), format!("Write error: {}", e))); } return false; }
                if let Ok(mut q) = event_queue_chunk.lock() { q.push(DownloadEvent::Progress(id_for_chunk.clone(), down, total)); }
                true
            };

            let result = client_instance.stream_request(host.as_str(), port, request, on_head, on_chunk).await;
            match result {
                Ok(()) => {
                    if let Ok(mut st) = state.lock() { if let Some(f) = st.file.as_mut() { let _ = f.flush(); } }
                    if let Ok(mut q) = event_queue_main.lock() { q.push(DownloadEvent::Completed(download_id_string.clone(), save_path_str.clone())); }
                }
                Err(e) => {
                    if let Ok(mut q) = event_queue_main.lock() { q.push(DownloadEvent::Failed(download_id_string.clone(), format!("{}", e))); }
                }
            }
        });
        true
    }

    #[func]
    fn cancel_download(&mut self, download_id: GString) {
        if let Ok(mut map) = self.cancel_flags.lock() { map.insert(download_id.to_string(), true); }
    }

    #[func]
    fn poll_events(&mut self) {
        let mut drained: Vec<DownloadEvent> = Vec::new();
        if let Ok(mut q) = self.event_queue.lock() { drained.append(&mut *q); }
        for ev in drained.into_iter() {
            match ev {
                DownloadEvent::Started(id, total) => { let mut owner = self.base.to_gd(); let args = [GString::from(id).to_variant(), (total as i64).to_variant()]; owner.emit_signal("download_started".into(), &args); }
                DownloadEvent::Progress(id, down, total) => { let mut owner = self.base.to_gd(); let args = [GString::from(id).to_variant(), (down as i64).to_variant(), (total as i64).to_variant()]; owner.emit_signal("download_progress".into(), &args); }
                DownloadEvent::Completed(id, path) => { let mut owner = self.base.to_gd(); let args = [GString::from(id).to_variant(), GString::from(path).to_variant()]; owner.emit_signal("download_completed".into(), &args); }
                DownloadEvent::Failed(id, msg) => { let mut owner = self.base.to_gd(); let args = [GString::from(id).to_variant(), GString::from(msg).to_variant()]; owner.emit_signal("download_failed".into(), &args); }
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
        gurtlib::GURT_VERSION.to_string().into()
    }

    #[func]
    fn get_default_port(&self) -> i32 {
        gurtlib::DEFAULT_PORT as i32
    }

    #[func]
    fn add_ca_certificate(&self, cert_pem: GString) {
        self.ca_certificates.borrow_mut().push(cert_pem.to_string());
    }

    #[func]
    fn clear_ca_certificates(&self) {
        self.ca_certificates.borrow_mut().clear();
    }

    #[func]
    fn get_ca_certificate_count(&self) -> i32 {
        self.ca_certificates.borrow().len() as i32
    }

    fn emit_download_failed(&mut self, download_id: &GString, message: String) {
        let mut owner = self.base.to_gd();
        let args = [
            download_id.to_variant(),
            GString::from(message).to_variant(),
        ];
        owner.emit_signal("download_failed".into(), &args);
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