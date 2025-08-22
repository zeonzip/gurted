extends RefCounted
class_name GurtProtocol

const DNS_API_URL = "gurt://localhost:8877"

# DNS resolution cache: domain.tld -> IP address
static var _dns_cache: Dictionary = {}

static func is_gurt_domain(url: String) -> bool:
	if url.begins_with("gurt://"):
		return true
	
	if not url.contains("://"):
		var parts = url.split(".")
		return parts.size() == 2
	
	return false

static func parse_gurt_domain(url: String) -> Dictionary:
	var domain_part = url
	var path = "/"
	
	if url.begins_with("gurt://"):
		domain_part = url.substr(7)
	
	# Extract path from domain_part (e.g., "test.dawg/script.lua" -> "test.dawg" + "/script.lua")
	var path_start = domain_part.find("/")
	if path_start != -1:
		path = domain_part.substr(path_start)
		domain_part = domain_part.substr(0, path_start)
	
	# Check if domain is cached (resolved before)
	var domain_key = domain_part
	if _dns_cache.has(domain_key):
		return {
			"direct_address": _dns_cache[domain_key],
			"display_url": domain_part + path,
			"is_direct": true,
			"path": path,
			"full_domain": domain_part
		}
	
	if domain_part.contains(":") or domain_part.begins_with("127.0.0.1") or domain_part.begins_with("localhost") or is_ip_address(domain_part):
		return {
			"direct_address": domain_part,
			"display_url": domain_part + path,
			"is_direct": true,
			"path": path,
			"full_domain": domain_part
		}
	
	var parts = domain_part.split(".")
	if parts.size() < 2:
		return {}
	
	# Support subdomains (e.g., api.blog.example.com)
	if parts.size() == 2:
		return {
			"name": parts[0],
			"tld": parts[1],
			"display_url": domain_part + path,
			"is_direct": false,
			"path": path,
			"full_domain": domain_part,
			"is_subdomain": false
		}
	else:
		return {
			"name": parts[parts.size() - 2],  # The domain name part
			"tld": parts[parts.size() - 1],   # The TLD part
			"display_url": domain_part + path,
			"is_direct": false,
			"path": path,
			"full_domain": domain_part,
			"is_subdomain": true,
			"subdomain_parts": parts.slice(0, parts.size() - 2)
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
	var request_data = JSON.stringify({"name": name, "tld": tld})
	var result = await fetch_dns_post_working("localhost:8877", "/resolve", request_data)
	
	if result.has("error"):
		return {"error": result.error}
	
	if not result.has("content"):
		return {"error": "No content in DNS response"}
	
	var content_str = result.content.get_string_from_utf8()
	var json = JSON.new()
	var parse_result = json.parse(content_str)
	
	if parse_result != OK:
		return {"error": "Invalid JSON in DNS response"}
	
	return json.data

static func fetch_full_domain_info(full_domain: String, record_type: String = "") -> Dictionary:
	var request_data = {"domain": full_domain}
	if not record_type.is_empty():
		request_data["record_type"] = record_type
	
	var json_data = JSON.stringify(request_data)
	var result = await fetch_dns_post_working("localhost:8877", "/resolve-full", json_data)
	
	if result.has("error"):
		return {"error": result.error}
	
	if not result.has("content"):
		return {"error": "No content in DNS response"}
	
	var content_str = result.content.get_string_from_utf8()
	var json = JSON.new()
	var parse_result = json.parse(content_str)
	
	if parse_result != OK:
		return {"error": "Invalid JSON in DNS response"}
	
	return json.data

static func fetch_dns_post_working(server: String, path: String, json_data: String) -> Dictionary:
	var shared_result = {"finished": false}
	var thread = Thread.new()
	var mutex = Mutex.new()
	
	var thread_func = func():
		var local_result = {}
		var client = GurtProtocolClient.new()
		
		for ca_cert in CertificateManager.trusted_ca_certificates:
			client.add_ca_certificate(ca_cert)
		
		if not client.create_client(10):
			local_result = {"error": "Failed to create client"}
		else:
			var url = "gurt://" + server + path
			
			# Prepare request options
			var options = {
				"method": "POST",
				"headers": {"Content-Type": "application/json"},
				"body": json_data
			}
			
			var response = client.request(url, options)
			
			client.disconnect()
			
			if not response:
				local_result = {"error": "No response from server"}
			elif not response.is_success:
				local_result = {"error": "Server error: " + str(response.status_code) + " " + str(response.status_message)}
			else:
				local_result = {"content": response.body}
		
		mutex.lock()
		shared_result.clear()
		for key in local_result:
			shared_result[key] = local_result[key]
		shared_result["finished"] = true
		mutex.unlock()
	
	thread.start(thread_func)
	
	# Non-blocking wait
	while not shared_result.get("finished", false):
		await Engine.get_main_loop().process_frame
	
	thread.wait_to_finish()
	
	mutex.lock()
	var final_result = {}
	for key in shared_result:
		if key != "finished":
			final_result[key] = shared_result[key]
	mutex.unlock()
	
	return final_result

static func fetch_content_via_gurt(ip: String, path: String = "/") -> Dictionary:	
	var client = GurtProtocolClient.new()
	
	for ca_cert in CertificateManager.trusted_ca_certificates:
		client.add_ca_certificate(ca_cert)
	
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
		
		for ca_cert in CertificateManager.trusted_ca_certificates:
			client.add_ca_certificate(ca_cert)
		
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
	
	# Non-blocking wait using signals instead of polling
	while not shared_result.get("finished", false):
		await Engine.get_main_loop().process_frame
		# Yield control back to the main thread without blocking delays
	
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
	var path = parsed.get("path", "/")
	
	if parsed.get("is_direct", false):
		target_address = parsed.direct_address
	else:
		var domain_info: Dictionary
		
		# Use the new full domain resolution for subdomains
		if parsed.get("is_subdomain", false):
			domain_info = await fetch_full_domain_info(parsed.full_domain)
		else:
			domain_info = await fetch_domain_info(parsed.name, parsed.tld)
		
		if domain_info.has("error"):
			return {"error": domain_info.error, "html": create_error_page(domain_info.error)}
		
		# Process DNS records to find target address
		var target_result = await resolve_target_address(domain_info, parsed.full_domain)
		if target_result.has("error"):
			return {"error": target_result.error, "html": create_error_page(target_result.error)}
		
		target_address = target_result.address
		
		# Cache the resolved address
		var domain_key = parsed.full_domain
		_dns_cache[domain_key] = target_address
	
	var content_result = await fetch_content_via_gurt_direct(target_address, path)
	if content_result.has("error"):
		var error_msg = "Failed to fetch content from " + target_address + path + " via GURT protocol - " + content_result.error
		if content_result.has("content") and not content_result.content.is_empty():
			return {"html": content_result.content, "display_url": parsed.display_url}
		return {"error": error_msg, "html": create_error_page(error_msg)}
	
	if not content_result.has("content"):
		var error_msg = "No content received from " + target_address + path
		return {"error": error_msg, "html": create_error_page(error_msg)}
	
	var html_content = content_result.content
	if html_content.is_empty():
		var error_msg = "Empty content received from " + target_address + path
		return {"error": error_msg, "html": create_error_page(error_msg)}
	
	return {"html": html_content, "display_url": parsed.display_url}

static func resolve_target_address(domain_info: Dictionary, original_domain: String) -> Dictionary:
	if not domain_info.has("records") or domain_info.records == null:
		return {"error": "No DNS records found for domain"}
	
	var records = domain_info.records
	var max_cname_depth = 5  # Prevent infinite CNAME loops
	var cname_depth = 0
	
	# First pass: Look for direct A/AAAA records
	var a_records = []
	var aaaa_records = []
	var cname_records = []
	var ns_records = []
	
	for record in records:
		if not record.has("type") or not record.has("value"):
			continue
			
		match record.type:
			"A":
				a_records.append(record.value)
			"AAAA":
				aaaa_records.append(record.value)
			"CNAME":
				cname_records.append(record.value)
			"NS":
				ns_records.append(record.value)
	
	# If we have direct A records, use the first one
	if not a_records.is_empty():
		return {"address": a_records[0]}
	
	# If we have IPv6 AAAA records and no A records, we need to handle this
	if not aaaa_records.is_empty() and a_records.is_empty():
		return {"error": "Only IPv6 (AAAA) records found, but IPv4 required for GURT protocol"}
	
	# Follow CNAME chain
	if not cname_records.is_empty():
		var current_cname = cname_records[0]
		
		while cname_depth < max_cname_depth:
			cname_depth += 1
			
			# Try to resolve the CNAME target
			var cname_info = await fetch_full_domain_info(current_cname, "A")
			if cname_info.has("error"):
				return {"error": "Failed to resolve CNAME target: " + current_cname + " - " + cname_info.error}
			
			if not cname_info.has("records") or cname_info.records == null:
				return {"error": "No records found for CNAME target: " + current_cname}
			
			# Look for A records in the CNAME target
			var found_next_cname = false
			for record in cname_info.records:
				if record.has("type") and record.type == "A" and record.has("value"):
					return {"address": record.value}
				elif record.has("type") and record.type == "CNAME" and record.has("value"):
					# Another CNAME, continue the chain
					current_cname = record.value
					found_next_cname = true
					break
			
			if not found_next_cname:
				# No more CNAMEs found, but also no A record
				return {"error": "CNAME chain ended without A record for: " + current_cname}
		
		return {"error": "CNAME chain too deep (max " + str(max_cname_depth) + " levels)"}
	
	# If we have NS records, this indicates delegation
	if not ns_records.is_empty():
		return {"error": "Domain is delegated to nameservers: " + str(ns_records) + ". Cannot resolve directly."}
	
	return {"error": "No A record found for domain"}

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

static func create_error_page(error_message: String) -> PackedByteArray:
	var error_info = get_error_type(error_message)
	
	return ("""<head>
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
</body>""").to_utf8_buffer()
