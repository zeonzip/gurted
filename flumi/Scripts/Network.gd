extends Node

func fetch_image(url: String) -> ImageTexture:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	if url.is_empty():
		return null
	
	var error = http_request.request(url)
	if error != OK:
		print("Error making HTTP request: ", error)
		http_request.queue_free()
		return null
	
	var response = await http_request.request_completed
	
	var result = response[0]  # HTTPClient.Result
	var response_code = response[1]  # int
	var headers = response[2]  # PackedStringArray
	var body = response[3]  # PackedByteArray
	
	http_request.queue_free()
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print("Failed to fetch image. Result: ", result, " Response code: ", response_code)
		return null
	
	# Get content type from headers
	var content_type = ""
	for header in headers:
		if header.to_lower().begins_with("content-type:"):
			content_type = header.split(":")[1].strip_edges().to_lower()
			break
	
	var image: Image = Image.new()
	var load_error
	
	# Load image based on content type
	if content_type.contains("jpeg") or content_type.contains("jpg") or url.to_lower().ends_with(".jpg") or url.to_lower().ends_with(".jpeg"):
		load_error = image.load_jpg_from_buffer(body)
	elif content_type.contains("png") or url.to_lower().ends_with(".png"):
		load_error = image.load_png_from_buffer(body)
	elif content_type.contains("webp") or url.to_lower().ends_with(".webp"):
		load_error = image.load_webp_from_buffer(body)
	elif content_type.contains("bmp"):
		load_error = image.load_bmp_from_buffer(body)
	elif content_type.contains("tga"):
		load_error = image.load_tga_from_buffer(body)
	else:
		print("Unknown or missing content-type. Attempting bruteforce converting across JPEG, PNG and WebP...")
		load_error = image.load_jpg_from_buffer(body)
		if load_error != OK:
			load_error = image.load_png_from_buffer(body)
			if load_error != OK:
				load_error = image.load_webp_from_buffer(body)
	
	if load_error != OK:
		print("Failed to load image from buffer. Content-Type: ", content_type, " Error: ", load_error)
		return null
	
	var texture = ImageTexture.create_from_image(image)
	
	return texture
