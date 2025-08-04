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
	var target = null

	if not (node is FlexContainer):
		target = node if node is RichTextLabel else node.get_node_or_null("RichTextLabel")
		label = target
		# Also check for Button nodes
		if not target and node is HTMLButton:
			var button_node = node.get_node_or_null("ButtonNode")
			if button_node:
				target = button_node

	if element.tag_name == "input":
		apply_input_border_styles(node, styles)

	# Unified font applying for label and button
	if target and styles.has("font-family") and styles["font-family"] not in ["sans-serif", "serif", "monospace"]:
		var main_node = Engine.get_main_loop().current_scene
		main_node.register_font_dependent_element(target, styles, element, parser)

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
			if width != null:
				if SizingUtils.is_percentage(width):
					# For FlexContainers with percentage width, use proportion sizing
					var percentage_value = float(width.replace("%", "")) / 100.0
					node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					node.size_flags_stretch_ratio = percentage_value
				else:
					node.custom_minimum_size.x = width
					var should_center_h = styles.has("mx-auto") or styles.has("justify-self-center") or (styles.has("text-align") and styles["text-align"] == "center")
					node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER if should_center_h else Control.SIZE_SHRINK_BEGIN
			
			if height != null:
				if SizingUtils.is_percentage(height):
					node.size_flags_vertical = Control.SIZE_EXPAND_FILL
				else:
					node.custom_minimum_size.y = height
					var should_center_v = styles.has("my-auto") or styles.has("align-self-center")
					node.size_flags_vertical = Control.SIZE_SHRINK_CENTER if should_center_v else Control.SIZE_SHRINK_BEGIN
			
			node.set_meta("size_flags_set_by_style_manager", true)
		elif node is VBoxContainer or node is HBoxContainer or node is Container:
			# Hcontainer nodes (like ul, ol)
			SizingUtils.apply_container_dimension_sizing(node, width, height, styles)
		elif node is HTMLP:
			# Only apply sizing if element has explicit size, otherwise preserve natural sizing
			var element_styles = parser.get_element_styles_internal(element, "")
			if element_styles.has("width") or element_styles.has("height"):
				var orig_h_flag = node.size_flags_horizontal
				var orig_v_flag = node.size_flags_vertical
				SizingUtils.apply_regular_control_sizing(node, width, height, styles)
				if not element_styles.has("width"):
					node.size_flags_horizontal = orig_h_flag
				if not element_styles.has("height"):
					node.size_flags_vertical = orig_v_flag
		else:
			# regular controls
			SizingUtils.apply_regular_control_sizing(node, width, height, styles)

	if label and label != node:
		label.anchors_preset = Control.PRESET_FULL_RECT

	# Apply z-index
	if styles.has("z-index"):
		node.z_index = styles["z-index"]
	
	# Apply opacity
	if styles.has("opacity"):
		node.modulate.a = styles["opacity"]
	
	# Apply cursor
	if styles.has("cursor"):
		var cursor_shape = get_cursor_shape_from_type(styles["cursor"])
		node.mouse_default_cursor_shape = cursor_shape
		
		# For text elements, apply cursor and handle mouse events appropriately
		if label:
			label.mouse_default_cursor_shape = cursor_shape
			
			# For non-pointer cursors on RichTextLabel, disable text interaction and let parent handle cursor
			if label is RichTextLabel and cursor_shape != Control.CURSOR_POINTING_HAND:
				label.selection_enabled = false
				label.context_menu_enabled = false
				label.shortcut_keys_enabled = false
				# Let parent container handle the cursor by ignoring mouse on text element
				label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			else:
				# For pointer cursors or non-RichTextLabel, ensure they can receive mouse events
				if label.mouse_filter == Control.MOUSE_FILTER_PASS:
					label.mouse_filter = Control.MOUSE_FILTER_STOP

	# Check for margins first and wrap in MarginContainer if needed
	var has_margin = styles.has("margin") or styles.has("margin-top") or styles.has("margin-right") or styles.has("margin-bottom") or styles.has("margin-left")
	
	if has_margin:
		node = apply_margin_wrapper(node, styles)
	
	# Apply background color, border radius, borders  
	var needs_styling = styles.has("background-color") or styles.has("border-radius") or styles.has("border-width") or styles.has("border-top-width") or styles.has("border-right-width") or styles.has("border-bottom-width") or styles.has("border-left-width") or styles.has("border-color")
	
	if needs_styling:
		var target_node_for_bg = node if node is FlexContainer else label
		if target_node_for_bg:
			if styles.has("background-color"):
				target_node_for_bg.set_meta("custom_css_background_color", styles["background-color"])
			if styles.has("border-radius"):
				target_node_for_bg.set_meta("custom_css_border_radius", styles["border-radius"])
			
			# Border properties
			if styles.has("border-width"):
				target_node_for_bg.set_meta("custom_css_border_width", styles["border-width"])
			if styles.has("border-color"):
				target_node_for_bg.set_meta("custom_css_border_color", styles["border-color"])
			
			# Individual border sides
			var border_sides = ["top", "right", "bottom", "left"]
			for side in border_sides:
				var width_key = "border-" + side + "-width"
				if styles.has(width_key):
					target_node_for_bg.set_meta("custom_css_" + width_key.replace("-", "_"), styles[width_key])

			if target_node_for_bg.has_method("add_background_rect"):
				target_node_for_bg.call_deferred("add_background_rect")

	if label:
		apply_styles_to_label(label, styles, element, parser)

	return node

static func apply_margin_wrapper(node: Control, styles: Dictionary) -> Control:
	var margin_container = MarginContainer.new()
	margin_container.name = "MarginWrapper_" + node.name
	
	# Copy size flags from the original node
	margin_container.size_flags_horizontal = node.size_flags_horizontal
	margin_container.size_flags_vertical = node.size_flags_vertical
	
	# Set margin values using theme overrides
	var general_margin_str = null
	if styles.has("margin"):
		general_margin_str = styles["margin"]
	
	if general_margin_str != null:
		var general_margin = parse_size(general_margin_str)
		if general_margin != null:
			margin_container.add_theme_constant_override("margin_top", general_margin)
			margin_container.add_theme_constant_override("margin_right", general_margin)
			margin_container.add_theme_constant_override("margin_bottom", general_margin)
			margin_container.add_theme_constant_override("margin_left", general_margin)
	
	# Individual margin overrides
	var margin_sides = [
		["margin-top", "margin_top"],
		["margin-right", "margin_right"],
		["margin-bottom", "margin_bottom"],
		["margin-left", "margin_left"]
	]
	
	for side_pair in margin_sides:
		var style_key = side_pair[0]
		var theme_key = side_pair[1]
		if styles.has(style_key):
			var margin_val_str = styles[style_key]
			var margin_val = parse_size(margin_val_str)
			if margin_val != null:
				margin_container.add_theme_constant_override(theme_key, margin_val)
	
	# Reset the original node's size flags since they're now handled by the wrapper
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Handle reparenting properly
	var original_parent = node.get_parent()
	if original_parent:
		var node_index = node.get_index()
		original_parent.remove_child(node)
		margin_container.add_child(node)
		original_parent.add_child(margin_container)
		original_parent.move_child(margin_container, node_index)
	else:
		margin_container.add_child(node)
	
	return margin_container

static func apply_styles_to_label(label: Control, styles: Dictionary, element: HTMLParser.HTMLElement, parser, text_override: String = "") -> void:
	if label is Button:
		apply_font_to_button(label, styles)
		return
	
	if not label is RichTextLabel:
		return
	
	var text = text_override if text_override != "" else (element.get_preserved_text() if element.tag_name == "pre" else element.get_bbcode_formatted_text(parser))

	var font_size = 24  # default

	if styles.has("font-family"):
		var font_family = styles["font-family"]
		var font_resource = FontManager.get_font(font_family)
			
		# set a sans-serif fallback first
		if font_family not in ["sans-serif", "serif", "monospace"]:
			if not FontManager.loaded_fonts.has(font_family):
				# Font not loaded yet, use sans-serif as fallback
				var fallback_font = FontManager.get_font("sans-serif")
				apply_font_to_label(label, fallback_font)
			
		if font_resource:
			apply_font_to_label(label, font_resource)
		
	# Apply font size
	if styles.has("font-size"):
		font_size = int(styles["font-size"])
	
	label.add_theme_font_size_override("normal_font_size", font_size)
	label.add_theme_font_size_override("bold_font_size", font_size)
	label.add_theme_font_size_override("italics_font_size", font_size)
	label.add_theme_font_size_override("bold_italics_font_size", font_size)
	label.add_theme_font_size_override("mono_font_size", font_size)
		
	var has_existing_bbcode = text.contains("[url=") or text.contains("[color=")
	
	# Apply color
	var color_tag = ""
	if not has_existing_bbcode and styles.has("color"):
		var color = styles["color"] as Color
		if color == Color.BLACK and StyleManager.body_text_color != Color.BLACK:
			color = StyleManager.body_text_color
		color_tag = "[color=#%s]" % color.to_html(false)
	elif not has_existing_bbcode and StyleManager.body_text_color != Color.BLACK:
		color_tag = "[color=#%s]" % StyleManager.body_text_color.to_html(false)

	# Apply text styling (but not for text with existing BBCode)
	var bold_open = ""
	var bold_close = ""
	if not has_existing_bbcode and styles.has("font-bold") and styles["font-bold"]:
		bold_open = "[b]"
		bold_close = "[/b]"
	
	var italic_open = ""
	var italic_close = ""
	if not has_existing_bbcode and styles.has("font-italic") and styles["font-italic"]:
		italic_open = "[i]"
		italic_close = "[/i]"
	
	var underline_open = ""
	var underline_close = ""
	if not has_existing_bbcode and styles.has("underline") and styles["underline"]:
		underline_open = "[u]"
		underline_close = "[/u]"
	# Apply monospace font
	var mono_open = ""
	var mono_close = ""
	if styles.has("font-mono") and styles["font-mono"]:
		# If font-family is already monospace, just use BBCode for styling
		if not (styles.has("font-family") and styles["font-family"] == "monospace"):
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
	
	var styled_text = "%s%s%s%s%s%s%s%s%s%s%s" % [
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

static func apply_font_to_label(label: RichTextLabel, font_resource: Font) -> void:
	label.add_theme_font_override("normal_font", font_resource)
	label.add_theme_font_override("bold_font", font_resource) 
	label.add_theme_font_override("italics_font", font_resource)
	label.add_theme_font_override("bold_italics_font", font_resource)

static func apply_font_to_button(button: Button, styles: Dictionary) -> void:
	if styles.has("font-family"):
		var font_family = styles["font-family"]
		var font_resource = FontManager.get_font(font_family)
		
		# Set fallback first for FOUT prevention
		if font_family not in ["sans-serif", "serif", "monospace"]:
			if not FontManager.loaded_fonts.has(font_family):
				var fallback_font = FontManager.get_font("sans-serif")
				button.add_theme_font_override("font", fallback_font)
		
		if font_resource:
			button.add_theme_font_override("font", font_resource)
	
	# Apply font size
	if styles.has("font-size"):
		var font_size = int(styles["font-size"])
		button.add_theme_font_size_override("font_size", font_size)

static func get_cursor_shape_from_type(cursor_type: String) -> Control.CursorShape:
	match cursor_type:
		"pointer", "hand":
			return Control.CURSOR_POINTING_HAND
		"text":
			return Control.CURSOR_IBEAM
		"crosshair":
			return Control.CURSOR_CROSS
		"move":
			return Control.CURSOR_MOVE
		"not-allowed", "forbidden":
			return Control.CURSOR_FORBIDDEN
		"wait":
			return Control.CURSOR_WAIT
		"help":
			return Control.CURSOR_HELP
		"grab":
			return Control.CURSOR_DRAG
		"grabbing":
			return Control.CURSOR_CAN_DROP
		"e-resize", "ew-resize":
			return Control.CURSOR_HSIZE
		"n-resize", "ns-resize":
			return Control.CURSOR_VSIZE
		"ne-resize":
			return Control.CURSOR_BDIAGSIZE
		"nw-resize":
			return Control.CURSOR_FDIAGSIZE
		"se-resize":
			return Control.CURSOR_FDIAGSIZE
		"sw-resize":
			return Control.CURSOR_BDIAGSIZE
		"default", "auto", _:
			return Control.CURSOR_ARROW

static func apply_input_border_styles(input_node: Control, styles: Dictionary) -> void:
	if not BackgroundUtils.needs_background_wrapper(styles):
		return
	
	# Find the appropriate input control to style
	var styleable_controls = []
	
	# Get all potential input controls that support StyleBox
	var line_edit = input_node.get_node_or_null("LineEdit")
	var spinbox = input_node.get_node_or_null("SpinBox")
	var file_container = input_node.get_node_or_null("FileContainer")
	
	if line_edit: styleable_controls.append(line_edit)
	if spinbox: styleable_controls.append(spinbox)
	if file_container:
		var file_button = file_container.get_node_or_null("FileButton")
		if file_button: styleable_controls.append(file_button)
	
	# Apply styles using BackgroundUtils
	for control in styleable_controls:
		var style_box = BackgroundUtils.create_stylebox_from_styles(styles)
		
		# Set appropriate content margins for inputs if not specified
		if not styles.has("padding") and not styles.has("padding-left"):
			style_box.content_margin_left = 5.0
		if not styles.has("padding") and not styles.has("padding-right"):
			style_box.content_margin_right = 5.0
		if not styles.has("padding") and not styles.has("padding-top"):
			style_box.content_margin_top = 2.0
		if not styles.has("padding") and not styles.has("padding-bottom"):
			style_box.content_margin_bottom = 2.0
		
		# Apply the style to the appropriate states
		if control is LineEdit:
			control.add_theme_stylebox_override("normal", style_box)
			control.add_theme_stylebox_override("focus", style_box)
		elif control is SpinBox:
			control.add_theme_stylebox_override("normal", style_box)
			control.add_theme_stylebox_override("focus", style_box)
		elif control is Button:
			control.add_theme_stylebox_override("normal", style_box)
