class_name StyleManager
extends RefCounted

static var body_text_color: Color = Color.BLACK

static func parse_size(val):
	if val == null: return null
	if typeof(val) == TYPE_INT or typeof(val) == TYPE_FLOAT:
		return float(val)
	if val.ends_with("px"):
		return float(val.replace("px", ""))
	if val.ends_with("rem"):
		return float(val.replace("rem", "")) * 16.0
	if val.ends_with("%") or (val.ends_with("]") and "%" in val):
		var clean_val = val.replace("[", "").replace("]", "")
		return clean_val
	if val == "full":
		return null
	return float(val)

static func apply_element_styles(node: Control, element: HTMLParser.HTMLElement, parser: HTMLParser) -> Control:
	var styles = parser.get_element_styles_with_inheritance(element, "", [])
	var label = null
	
	if not (node is FlexContainer):
		label = node if node is RichTextLabel else node.get_node_or_null("RichTextLabel")
	
	var width = null
	var height = null

	if styles.has("width"):
		width = parse_size(styles["width"])
	if styles.has("height"):
		height = parse_size(styles["height"])

	# Skip width/height inheritance for buttons when inheriting from auto-sized containers
	var skip_sizing = SizingUtils.should_skip_sizing(node, element, parser)
	
	if (width != null or height != null) and not skip_sizing:
		# FlexContainers handle percentage sizing differently than regular controls
		if node is FlexContainer:
			if width != null and typeof(width) != TYPE_STRING:
				node.custom_minimum_size.x = width
			if height != null and typeof(height) != TYPE_STRING:
				node.custom_minimum_size.y = height
		elif node is VBoxContainer or node is HBoxContainer or node is Container:
			# Hcontainer nodes (like ul, ol)
			SizingUtils.apply_container_dimension_sizing(node, width, height)
		else:
			# regular controls
			SizingUtils.apply_regular_control_sizing(node, width, height)

		if label and label != node:
			label.anchors_preset = Control.PRESET_FULL_RECT

	# Apply background color
	if styles.has("background-color"):
		var target_node_for_bg = node if node is FlexContainer else label
		if target_node_for_bg:
			target_node_for_bg.set_meta("custom_css_background_color", styles["background-color"])
			if target_node_for_bg.has_method("add_background_rect"):
				target_node_for_bg.call_deferred("add_background_rect")

	if label:
		apply_styles_to_label(label, styles, element, parser)

	return node

static func apply_styles_to_label(label: RichTextLabel, styles: Dictionary, element: HTMLParser.HTMLElement, parser, text_override: String = "") -> void:
		var text = text_override if text_override != "" else (element.get_preserved_text() if element.tag_name == "pre" else element.get_bbcode_formatted_text(parser))

		var font_size = 24  # default
		# Apply font size
		if styles.has("font-size"):
			font_size = int(styles["font-size"])
		# Apply color
		var color_tag = ""
		if styles.has("color"):
			var color = styles["color"] as Color

			if color == Color.BLACK and StyleManager.body_text_color != Color.BLACK:
				color = StyleManager.body_text_color
			color_tag = "[color=#%s]" % color.to_html(false)
		else:
			if StyleManager.body_text_color != Color.BLACK:
				color_tag = "[color=#%s]" % StyleManager.body_text_color.to_html(false)
		# Apply bold
		var bold_open = ""
		var bold_close = ""
		if styles.has("font-bold") and styles["font-bold"]:
			bold_open = "[b]"
			bold_close = "[/b]"
		# Apply italic
		var italic_open = ""
		var italic_close = ""
		if styles.has("font-italic") and styles["font-italic"]:
			italic_open = "[i]"
			italic_close = "[/i]"
		# Apply underline
		var underline_open = ""
		var underline_close = ""
		if styles.has("underline") and styles["underline"]:
			underline_open = "[u]"
			underline_close = "[/u]"
		# Apply monospace font
		var mono_open = ""
		var mono_close = ""
		if styles.has("font-mono") and styles["font-mono"]:
			mono_open = "[code]"
			mono_close = "[/code]"
		if styles.has("text-align"):
			match styles["text-align"]:
				"left":
					label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
				"center":
					label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				"right":
					label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				"justify":
					label.horizontal_alignment = HORIZONTAL_ALIGNMENT_FILL
		# Construct final text
		var styled_text = "[font_size=%d]%s%s%s%s%s%s%s%s%s%s%s[/font_size]" % [
				font_size,
				color_tag,
				bold_open,
				italic_open,
				underline_open,
				mono_open,
				text,
				mono_close,
				underline_close,
				italic_close,
				bold_close,
				"[/color]" if color_tag.length() > 0 else "",
		]
		
		label.text = styled_text

static func apply_flex_container_properties(node: FlexContainer, styles: Dictionary) -> void:
	FlexUtils.apply_flex_container_properties(node, styles)

static func apply_flex_item_properties(node: Control, styles: Dictionary) -> void:
	FlexUtils.apply_flex_item_properties(node, styles)

static func parse_flex_value(val):
	return FlexUtils.parse_flex_value(val)

static func apply_body_styles(body: HTMLParser.HTMLElement, parser: HTMLParser, website_container: Control, website_background: Control) -> void:
	var styles = parser.get_element_styles_with_inheritance(body, "", [])
	
	# Apply background color
	if styles.has("background-color"):
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = styles["background-color"] as Color
		website_background.add_theme_stylebox_override("panel", style_box)
	
	if styles.has("color"):
		StyleManager.body_text_color = styles["color"]
	# Apply padding
	var has_padding = styles.has("padding") or styles.has("padding-top") or styles.has("padding-right") or styles.has("padding-bottom") or styles.has("padding-left")
	
	if has_padding:
		var margin_container = MarginContainer.new()
		margin_container.name = "BodyMarginContainer"
		margin_container.size_flags_horizontal = website_container.size_flags_horizontal
		margin_container.size_flags_vertical = website_container.size_flags_vertical

		# ScrollContainer
		# |__ BodyMarginContainer
		#     |__ WebsiteContainer
		var original_parent = website_container.get_parent()
		var container_index = website_container.get_index()

		original_parent.remove_child(website_container)
		original_parent.add_child(margin_container)
		original_parent.move_child(margin_container, container_index)
		margin_container.add_child(website_container)
		
		var margin_val = parse_size(styles["padding"])

		margin_container.add_theme_constant_override("margin_left", margin_val)
		margin_container.add_theme_constant_override("margin_right", margin_val)
		margin_container.add_theme_constant_override("margin_top", margin_val)
		margin_container.add_theme_constant_override("margin_bottom", margin_val)
		
		# Apply individual padding values
		var padding_sides = [
			["padding-top", "margin_top"],
			["padding-right", "margin_right"], 
			["padding-bottom", "margin_bottom"],
			["padding-left", "margin_left"]
		]
		
		for side_pair in padding_sides:
			var style_key = side_pair[0]
			var margin_key = side_pair[1]
			if styles.has(style_key):
				var margin_val2 = parse_size(styles[style_key])
				margin_container.add_theme_constant_override(margin_key, margin_val2)

static func parse_radius(radius_str: String) -> int:
	return SizeUtils.parse_radius(radius_str)
