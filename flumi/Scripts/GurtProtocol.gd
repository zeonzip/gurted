extends RefCounted
class_name GurtProtocol

const DNS_API_URL = "http://localhost:8080"

static func is_gurt_domain(url: String) -> bool:
	if url.begins_with("gurt://"):
		return true
	
	if not url.contains("://"):
		var parts = url.split(".")
		return parts.size() == 2
	
	return false

static func parse_gurt_domain(url: String) -> Dictionary:
	var domain_part = url
	
	if url.begins_with("gurt://"):
		domain_part = url.substr(7)
	
	if domain_part.contains(":") or domain_part.begins_with("127.0.0.1") or domain_part.begins_with("localhost") or is_ip_address(domain_part):
		return {
			"direct_address": domain_part,
			"display_url": domain_part,
			"is_direct": true
		}
	
	var parts = domain_part.split(".")
	if parts.size() != 2:
		return {}
	
	return {
		"name": parts[0],
		"tld": parts[1],
		"display_url": domain_part,
		"is_direct": false
	}

static func is_ip_address(address: String) -> bool:
	var parts = address.split(".")
	if parts.size() != 4:
		return false
	
	for part in parts:
		if not part.is_valid_int():
			return false
		var num = part.to_int()
		if num < 0 or num > 255:
			return false
	
	return true

static func fetch_domain_info(name: String, tld: String) -> Dictionary:	
	var http_request = HTTPRequest.new()
	var tree = Engine.get_main_loop()
	tree.current_scene.add_child(http_request)
	
	http_request.timeout = 5.0
	
	var url = DNS_API_URL + "/domain/" + name + "/" + tld
	print("DNS API URL: ", url)
	
	var error = http_request.request(url)
	
	if error != OK:
		print("HTTP request failed with error: ", error)
		http_request.queue_free()
		return {"error": "Failed to make DNS request"}
	
	var response = await http_request.request_completed
	http_request.queue_free()
	
	if response[1] == 0 and response[3].size() == 0:
		return {"error": "DNS server is not responding"}
	
	var http_code = response[1]
	var body = response[3]
	
	if http_code != 200:
		return {"error": "Domain not found or not approved"}
	
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	
	if parse_result != OK:
		return {"error": "Invalid JSON response from DNS server"}
	
	return json.data

static func fetch_content_via_gurt(ip: String, path: String = "/") -> Dictionary:	
	var client = GurtProtocolClient.new()
	
	if not client.create_client(30):
		return {"error": "Failed to create GURT client"}
	
	var gurt_url = "gurt://" + ip + ":4878" + path
	
	var response = client.request(gurt_url, {"method": "GET"})
	
	client.disconnect()
	
	if not response:
		return {"error": "No response from GURT server"}
	
	if not response.is_success:
		var error_msg = "Server returned status " + str(response.status_code) + ": " + response.status_message
		return {"error": error_msg}
	
	var content = response.body
	return {"content": content, "headers": response.headers}

static func fetch_content_via_gurt_direct(address: String, path: String = "/") -> Dictionary:
	var shared_result = {"finished": false}
	var thread = Thread.new()
	var mutex = Mutex.new()
	
	var thread_func = func():
		var local_result = {}
		var client = GurtProtocolClient.new()
		
		if not client.create_client(10):
			local_result = {"error": "Failed to create GURT client"}
		else:
			var gurt_url: String
			if address.contains(":"):
				gurt_url = "gurt://" + address + path
			else:
				gurt_url = "gurt://" + address + ":4878" + path
			
			var response = client.request(gurt_url, {"method": "GET"})
			
			client.disconnect()
			
			if not response:
				local_result = {"error": "No response from GURT server"}
			else:
				var content = response.body
				
				if not response.is_success:
					var error_msg = "Server returned status " + str(response.status_code) + ": " + response.status_message
					local_result = {"error": error_msg, "content": content, "headers": response.headers}
				else:
					local_result = {"content": content, "headers": response.headers}
		
		mutex.lock()
		shared_result.clear()
		for key in local_result:
			shared_result[key] = local_result[key]
		shared_result["finished"] = true
		mutex.unlock()
	
	thread.start(thread_func)
	
	var finished = false
	while not finished:
		await Engine.get_main_loop().process_frame
		OS.delay_msec(10)
		
		mutex.lock()
		finished = shared_result.get("finished", false)
		mutex.unlock()
	
	thread.wait_to_finish()
	
	mutex.lock()
	var final_result = {}
	for key in shared_result:
		if key != "finished":
			final_result[key] = shared_result[key]
	mutex.unlock()
	
	return final_result

static func handle_gurt_domain(url: String) -> Dictionary:	
	var parsed = parse_gurt_domain(url)
	if parsed.is_empty():
		return {"error": "Invalid domain format. Use: domain.tld or IP:port", "html": create_error_page("Invalid domain format. Use: domain.tld or IP:port")}
	
	var target_address: String
	var path = "/"
	
	if parsed.get("is_direct", false):
		target_address = parsed.direct_address
	else:
		var domain_info = await fetch_domain_info(parsed.name, parsed.tld)
		if domain_info.has("error"):
			return {"error": domain_info.error, "html": create_error_page(domain_info.error)}
		target_address = domain_info.ip
	
	var content_result = await fetch_content_via_gurt_direct(target_address, path)
	if content_result.has("error"):
		var error_msg = "Failed to fetch content from " + target_address + " via GURT protocol - " + content_result.error
		if content_result.has("content") and not content_result.content.is_empty():
			return {"html": content_result.content, "display_url": parsed.display_url}
		return {"error": error_msg, "html": create_error_page(error_msg)}
	
	if not content_result.has("content"):
		var error_msg = "No content received from " + target_address
		return {"error": error_msg, "html": create_error_page(error_msg)}
	
	var html_content = content_result.content
	if html_content.is_empty():
		var error_msg = "Empty content received from " + target_address
		return {"error": error_msg, "html": create_error_page(error_msg)}
	
	return {"html": html_content, "display_url": parsed.display_url}

static func get_error_type(error_message: String) -> Dictionary:
	if "DNS server is not responding" in error_message or "Domain not found" in error_message:
		return {"code": "ERR_NAME_NOT_RESOLVED", "title": "This site can't be reached", "icon": "🌐"}
	elif "timeout" in error_message.to_lower() or "timed out" in error_message.to_lower():
		return {"code": "ERR_CONNECTION_TIMED_OUT", "title": "This site can't be reached", "icon": "⏰"}
	elif "Failed to fetch" in error_message or "No response" in error_message:
		return {"code": "ERR_CONNECTION_REFUSED", "title": "This site can't be reached", "icon": "🚫"}
	elif "Invalid domain format" in error_message:
		return {"code": "ERR_INVALID_URL", "title": "This page isn't working", "icon": "⚠️"}
	else:
		return {"code": "ERR_UNKNOWN", "title": "Something went wrong", "icon": "❌"}

static func create_error_page(error_message: String) -> String:
	var error_info = get_error_type(error_message)
	
	return """<head>
	<title>""" + error_info.title + """ - GURT</title>
	<meta name="theme-color" content="#f8f9fa">
	<style>
		body { bg-[#ffffff] text-[#202124] font-sans p-0 m-0 }
		.error-container { flex flex-col items-center justify-center max-w-[600px] mx-auto px-6 text-center }
		.error-icon { text-6xl mb-6 opacity-60 w-32 h-32 }
		.error-title { text-[#202124] text-2xl font-normal mb-4 line-height-1.3 }
		.error-subtitle { text-[#5f6368] text-base mb-6 line-height-1.4 }
		.error-code { bg-[#f8f9fa] text-[#5f6368] px-3 py-2 rounded-md font-mono text-sm inline-block mb-6 }
		.suggestions { text-left max-w-[400px] w-[500px] }
		.suggestion-title { text-[#202124] text-lg font-normal mb-3 }
		.suggestion-list { text-[#5f6368] text-sm line-height-1.6 }
		.suggestion-item { mb-2 pl-4 relative }
		.suggestion-item:before { content-"•" absolute left-0 top-0 text-[#5f6368] }
		.retry-button { bg-[#1a73e8] text-[#ffffff] px-6 py-3 rounded-md font-medium text-sm hover:bg-[#1557b0] active:bg-[#1246a0] cursor-pointer border-none mt-4 }
		.details-section { mt-8 pt-6 border-t border-[#e8eaed] }
		.details-toggle { text-[#1a73e8] text-sm cursor-pointer hover:underline }
		.details-content { bg-[#f8f9fa] text-[#5f6368] text-xs font-mono p-4 rounded-md mt-3 text-left display-none }
	</style>
	
	<script>
		gurt.select("#reload"):on("click", function()
			gurt.location.reload()
		end)
	</script>
</head>
<body>
	<div style="error-container">
		<p style="error-icon">""" + error_info.icon + """</p>
		
		<h1 style="error-title">""" + error_info.title + """</h1>
		
		<p style="error-subtitle">""" + error_message + """</p>
		
		<div style="error-code">""" + error_info.code + """</div>
		
		<div style="suggestions">
			<h2 style="suggestion-title">Try:</h2>
			<ul style="suggestion-list">
				<li style="suggestion-item">Checking if the domain is correctly registered</li>
				<li style="suggestion-item">Verifying your DNS server is running</li>
				<li style="suggestion-item">Checking your internet connection</li>
			</ul>
		</div>
		
		<button style="retry-button" id="reload">Reload</button>
	</div>
</body>"""
