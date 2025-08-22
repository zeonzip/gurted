extends RefCounted
class_name CertificateManager

static var trusted_ca_certificates: Array[String] = []
static var ca_cache: Dictionary = {}

static func fetch_cert_via_http(url: String) -> String:
	var http_request = HTTPRequest.new()
	
	var main_scene = Engine.get_main_loop().current_scene
	if not main_scene:
		return ""
	
	main_scene.add_child(http_request)
	
	var error = http_request.request(url)
	if error != OK:
		http_request.queue_free()
		return ""
	
	var response = await http_request.request_completed
	http_request.queue_free()
	
	var result = response[0]
	var response_code = response[1]
	var body = response[3]
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		return ""
	
	return body.get_string_from_utf8()

static func initialize():
	load_builtin_ca()
	print("📋 Certificate Manager initialized with ", trusted_ca_certificates.size(), " trusted CAs")

static func load_builtin_ca():
	var ca_file = FileAccess.open("res://Assets/gurted-ca.crt", FileAccess.READ)
	if ca_file:
		var ca_cert_pem = ca_file.get_as_text()
		ca_file.close()
		
		if not ca_cert_pem.is_empty():
			trusted_ca_certificates.append(ca_cert_pem)
			print("✅ Loaded built-in GURT CA certificate")
		else:
			print("⚠️ Built-in CA certificate not yet configured")
	else:
		print("❌ Could not load built-in CA certificate")
