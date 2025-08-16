class_name URLUtils
extends RefCounted

static func resolve_url(base_url: String, relative_url: String) -> String:
	# If relative_url is already absolute, return it as-is
	if relative_url.begins_with("http://") or relative_url.begins_with("https://") or relative_url.begins_with("gurt://"):
		return relative_url
	
	# If empty, treat as relative to current domain
	if base_url.is_empty():
		return relative_url
	
	var clean_base = base_url.rstrip("/")
	
	# Parse scheme and host
	var scheme_end = clean_base.find("://")
	if scheme_end == -1:
		return relative_url
	
	var scheme = clean_base.substr(0, scheme_end + 3)
	var remainder = clean_base.substr(scheme_end + 3)
	
	# Split remainder into host and path
	var first_slash = remainder.find("/")
	var host = ""
	var current_path_parts = []
	
	if first_slash == -1:
		# No path in base URL, just host
		host = remainder
	else:
		host = remainder.substr(0, first_slash)
		var path = remainder.substr(first_slash + 1)
		if not path.is_empty():
			current_path_parts = path.split("/")
	
	var final_path_parts = []
	
	if relative_url.begins_with("/"):
		# Absolute path from root
		var href_path = relative_url.substr(1) if relative_url.length() > 1 else ""
		if not href_path.is_empty():
			final_path_parts = href_path.split("/")
	else:
		# Relative path
		final_path_parts = current_path_parts.duplicate()
		
		if final_path_parts.size() > 0:
			var last_part = final_path_parts[-1]
			if "." in last_part and not last_part.ends_with("/"):
				final_path_parts.resize(final_path_parts.size() - 1)
		
		var href_parts = relative_url.split("/")
		for part in href_parts:
			if part == "..":
				if final_path_parts.size() > 0:
					final_path_parts.resize(final_path_parts.size() - 1)
			elif part == "." or part == "":
				continue
			else:
				final_path_parts.append(part)
	
	var result = scheme + host
	if final_path_parts.size() > 0:
		result += "/" + "/".join(final_path_parts)
	
	return result
