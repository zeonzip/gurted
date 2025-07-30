class_name ColorUtils
extends RefCounted

static func parse_color(color_string: String) -> Color:
	color_string = color_string.strip_edges()
	
	# Handle hex colors
	if color_string.begins_with("#"):
		return Color.from_string(color_string, Color.WHITE)
	
	# Handle rgb/rgba
	if color_string.begins_with("rgb"):
		var regex = RegEx.new()
		regex.compile("rgba?\\(([^)]+)\\)")
		var result = regex.search(color_string)
		if result:
			var values = result.get_string(1).split(",")
			if values.size() >= 3:
				var r = values[0].strip_edges().to_float() / 255.0
				var g = values[1].strip_edges().to_float() / 255.0
				var b = values[2].strip_edges().to_float() / 255.0
				var a = 1.0
				if values.size() >= 4:
					a = values[3].strip_edges().to_float()
				return Color(r, g, b, a)
	
	# Handle named colors - delegate to get_color function
	return get_color(color_string)

static func get_color(color_name: String) -> Color:
	# Common colors
	match color_name:
		"white": return Color.WHITE
		"black": return Color.BLACK
		"transparent": return Color.TRANSPARENT
		
		# Gray scale
		"slate-50": return Color.from_string("#f8fafc", Color.WHITE)
		"slate-100": return Color.from_string("#f1f5f9", Color.WHITE)
		"slate-200": return Color.from_string("#e2e8f0", Color.WHITE)
		"slate-300": return Color.from_string("#cbd5e1", Color.WHITE)
		"slate-400": return Color.from_string("#94a3b8", Color.WHITE)
		"slate-500": return Color.from_string("#64748b", Color.WHITE)
		"slate-600": return Color.from_string("#475569", Color.WHITE)
		"slate-700": return Color.from_string("#334155", Color.WHITE)
		"slate-800": return Color.from_string("#1e293b", Color.WHITE)
		"slate-900": return Color.from_string("#0f172a", Color.WHITE)
		
		"gray-50": return Color.from_string("#f9fafb", Color.WHITE)
		"gray-100": return Color.from_string("#f3f4f6", Color.WHITE)
		"gray-200": return Color.from_string("#e5e7eb", Color.WHITE)
		"gray-300": return Color.from_string("#d1d5db", Color.WHITE)
		"gray-400": return Color.from_string("#9ca3af", Color.WHITE)
		"gray-500": return Color.from_string("#6b7280", Color.WHITE)
		"gray-600": return Color.from_string("#4b5563", Color.WHITE)
		"gray-700": return Color.from_string("#374151", Color.WHITE)
		"gray-800": return Color.from_string("#1f2937", Color.WHITE)
		"gray-900": return Color.from_string("#111827", Color.WHITE)
		
		# Red
		"red-50": return Color.from_string("#fef2f2", Color.WHITE)
		"red-100": return Color.from_string("#fee2e2", Color.WHITE)
		"red-200": return Color.from_string("#fecaca", Color.WHITE)
		"red-300": return Color.from_string("#fca5a5", Color.WHITE)
		"red-400": return Color.from_string("#f87171", Color.WHITE)
		"red-500": return Color.from_string("#ef4444", Color.WHITE)
		"red-600": return Color.from_string("#dc2626", Color.WHITE)
		"red-700": return Color.from_string("#b91c1c", Color.WHITE)
		"red-800": return Color.from_string("#991b1b", Color.WHITE)
		"red-900": return Color.from_string("#7f1d1d", Color.WHITE)
		
		# Green
		"green-50": return Color.from_string("#f0fdf4", Color.WHITE)
		"green-100": return Color.from_string("#dcfce7", Color.WHITE)
		"green-200": return Color.from_string("#bbf7d0", Color.WHITE)
		"green-300": return Color.from_string("#86efac", Color.WHITE)
		"green-400": return Color.from_string("#4ade80", Color.WHITE)
		"green-500": return Color.from_string("#22c55e", Color.WHITE)
		"green-600": return Color.from_string("#16a34a", Color.WHITE)
		"green-700": return Color.from_string("#15803d", Color.WHITE)
		"green-800": return Color.from_string("#166534", Color.WHITE)
		"green-900": return Color.from_string("#14532d", Color.WHITE)
		
		# Blue
		"blue-50": return Color.from_string("#eff6ff", Color.WHITE)
		"blue-100": return Color.from_string("#dbeafe", Color.WHITE)
		"blue-200": return Color.from_string("#bfdbfe", Color.WHITE)
		"blue-300": return Color.from_string("#93c5fd", Color.WHITE)
		"blue-400": return Color.from_string("#60a5fa", Color.WHITE)
		"blue-500": return Color.from_string("#3b82f6", Color.WHITE)
		"blue-600": return Color.from_string("#2563eb", Color.WHITE)
		"blue-700": return Color.from_string("#1d4ed8", Color.WHITE)
		"blue-800": return Color.from_string("#1e40af", Color.WHITE)
		"blue-900": return Color.from_string("#1e3a8a", Color.WHITE)
		
		# Yellow
		"yellow-50": return Color.from_string("#fefce8", Color.WHITE)
		"yellow-100": return Color.from_string("#fef9c3", Color.WHITE)
		"yellow-200": return Color.from_string("#fef08a", Color.WHITE)
		"yellow-300": return Color.from_string("#fde047", Color.WHITE)
		"yellow-400": return Color.from_string("#facc15", Color.WHITE)
		"yellow-500": return Color.from_string("#eab308", Color.WHITE)
		"yellow-600": return Color.from_string("#ca8a04", Color.WHITE)
		"yellow-700": return Color.from_string("#a16207", Color.WHITE)
		"yellow-800": return Color.from_string("#854d0e", Color.WHITE)
		"yellow-900": return Color.from_string("#713f12", Color.WHITE)
		
		_: return Color.BLACK
