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
	var skip_sizing = should_skip_sizing(node, element, parser)
	
	if (width != null or height != null) and not skip_sizing:
		# FlexContainers handle percentage sizing differently than regular controls
		if node is FlexContainer:
			if width != null and typeof(width) != TYPE_STRING:
				node.custom_minimum_size.x = width
			if height != null and typeof(height) != TYPE_STRING:
				node.custom_minimum_size.y = height
		elif node is VBoxContainer or node is HBoxContainer or node is Container:
			# Hcontainer nodes (like ul, ol)
			apply_container_dimension_sizing(node, width, height)
		else:
			# regular controls
			apply_regular_control_sizing(node, width, height)

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

static func apply_styles_to_label(label: RichTextLabel, styles: Dictionary, element: HTMLParser.HTMLElement, parser) -> void:
		var text =  element.get_preserved_text() if element.tag_name == "pre" else element.get_bbcode_formatted_text(parser)

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

static func apply_flex_container_properties(node: FlexContainer, styles: Dictionary, element: HTMLParser.HTMLElement, parser: HTMLParser) -> void:
	# Flex direction - default to row if not specified
	if styles.has("flex-direction"):
		match styles["flex-direction"]:
			"row": node.flex_direction = FlexContainer.FlexDirection.Row
			"row-reverse": node.flex_direction = FlexContainer.FlexDirection.RowReverse
			"column": node.flex_direction = FlexContainer.FlexDirection.Column
			"column-reverse": node.flex_direction = FlexContainer.FlexDirection.ColumnReverse
	else:
		node.flex_direction = FlexContainer.FlexDirection.Row
	# Flex wrap
	if styles.has("flex-wrap"):
		match styles["flex-wrap"]:
			"nowrap": node.flex_wrap = FlexContainer.FlexWrap.NoWrap
			"wrap": node.flex_wrap = FlexContainer.FlexWrap.Wrap
			"wrap-reverse": node.flex_wrap = FlexContainer.FlexWrap.WrapReverse
	# Justify content
	if styles.has("justify-content"):
		match styles["justify-content"]:
			"flex-start": node.justify_content = FlexContainer.JustifyContent.FlexStart
			"flex-end": node.justify_content = FlexContainer.JustifyContent.FlexEnd
			"center": node.justify_content = FlexContainer.JustifyContent.Center
			"space-between": node.justify_content = FlexContainer.JustifyContent.SpaceBetween
			"space-around": node.justify_content = FlexContainer.JustifyContent.SpaceAround
			"space-evenly": node.justify_content = FlexContainer.JustifyContent.SpaceEvenly
	# Align items
	if styles.has("align-items"):
		match styles["align-items"]:
			"flex-start": node.align_items = FlexContainer.AlignItems.FlexStart
			"flex-end": node.align_items = FlexContainer.AlignItems.FlexEnd
			"center": node.align_items = FlexContainer.AlignItems.Center
			"stretch": node.align_items = FlexContainer.AlignItems.Stretch
			"baseline": node.align_items = FlexContainer.AlignItems.Baseline
	# Align content
	if styles.has("align-content"):
		match styles["align-content"]:
			"flex-start": node.align_content = FlexContainer.AlignContent.FlexStart
			"flex-end": node.align_content = FlexContainer.AlignContent.FlexEnd
			"center": node.align_content = FlexContainer.AlignContent.Center
			"stretch": node.align_content = FlexContainer.AlignContent.Stretch
			"space-between": node.align_content = FlexContainer.AlignContent.SpaceBetween
			"space-around": node.align_content = FlexContainer.AlignContent.SpaceAround
	# Gap
	if styles.has("gap"):
		# YGGutterAll = 2
		node._root.set_gap(2, parse_flex_value(styles["gap"]))
	if styles.has("row-gap"):
		# YGGutterRow = 1
		node._root.set_gap(1, parse_flex_value(styles["row-gap"]))
	if styles.has("column-gap"):
		# YGGutterColumn = 0
		node._root.set_gap(0, parse_flex_value(styles["column-gap"]))
	
	if styles.has("width"):
		var width_val = styles["width"]
		if width_val == "full":
			# For flex containers, w-full should expand to fill parent
			node.set_meta("should_fill_horizontal", true)
		elif typeof(width_val) == TYPE_STRING and width_val.ends_with("%"):
			node.set_meta("custom_css_width_percentage", width_val)
		else:
			node.set_meta("custom_css_width", parse_size(width_val))
	if styles.has("height"):
		var height_val = styles["height"]
		if height_val == "full":
			# For flex containers, h-full should expand to fill parent
			node.set_meta("should_fill_vertical", true)
		elif typeof(height_val) == TYPE_STRING and height_val.ends_with("%"):
			node.set_meta("custom_css_height_percentage", height_val)
		else:
			node.set_meta("custom_css_height", parse_size(height_val))
	if styles.has("background-color"):
		node.set_meta("custom_css_background_color", styles["background-color"])
	node.update_layout()

static func apply_flex_item_properties(node: Control, styles: Dictionary) -> void:
	var properties: Dictionary = node.get_meta("flex_metas", {}).duplicate(true)
	var changed = false

	if styles.has("flex-grow"):
		properties["grow"] = float(styles["flex-grow"])
		changed = true
	if styles.has("flex-shrink"):
		properties["shrink"] = float(styles["flex-shrink"])
		changed = true
	if styles.has("flex-basis"):
		properties["basis"] = parse_flex_value(styles["flex-basis"])
		changed = true
	if styles.has("align-self"):
		var align_self_value = -1
		match styles["align-self"]:
			"auto": align_self_value = FlexContainer.AlignItems.Auto
			"flex-start": align_self_value = FlexContainer.AlignItems.FlexStart
			"flex-end": align_self_value = FlexContainer.AlignItems.FlexEnd
			"center": align_self_value = FlexContainer.AlignItems.Center
			"stretch": align_self_value = FlexContainer.AlignItems.Stretch
			"baseline": align_self_value = FlexContainer.AlignItems.Baseline
		
		if align_self_value != -1:
			properties["align_self"] = align_self_value
			changed = true

	if changed:
		node.set_meta("flex_metas", properties)
		# The parent FlexContainer must be notified to update its layout.
		var parent = node.get_parent()
		if parent is FlexContainer:
			parent.update_layout()

static func parse_flex_value(val):
	if val is float or val is int:
		return float(val)

	if val is String:
		var s_val = val.strip_edges()
		if s_val.is_valid_float():
			return s_val.to_float()
		if s_val.ends_with("%"):
			# NOTE: Flex-basis percentages not supported by flexbox
			return s_val.trim_suffix("%").to_float() / 100.0
		if s_val.ends_with("px"):
			return s_val.trim_suffix("px").to_float()
		if s_val == "auto":
			return "auto"

	return null

static func should_skip_sizing(node: Control, element: HTMLParser.HTMLElement, parser: HTMLParser) -> bool:
	# Cache style lookups to avoid repeated calls
	var element_styles = parser.get_element_styles_internal(element, "")
	
	# Button sizing rules: Skip sizing only when button has no explicit size 
	# AND parent doesn't have explicit width (auto-inherited sizing)
	if node.get_script() and node.get_script().get_path().ends_with("button.gd"):
		# If button has explicit size, don't skip sizing
		if element_styles.has("width") or element_styles.has("height"):
			return false
		
		# Check if width is being inherited from parent with explicit size
		var parent_element = element.parent
		if parent_element:
			var parent_styles = parser.get_element_styles_internal(parent_element, "")
			var parent_has_explicit_width = parent_styles.has("width")
			# Skip only if parent doesn't have explicit width (auto-inherited)
			return not parent_has_explicit_width
		
		return true
	
	# Span sizing rules: Always skip sizing for spans since they're inline elements
	# (flex containers use AutoSizingFlexContainer, not span.gd)
	elif node.get_script() and node.get_script().get_path().ends_with("span.gd"):
		return true
	
	return false

static func apply_container_dimension_sizing(node: Control, width, height) -> void:
	if width != null:
		if is_percentage(width):
			node.set_meta("container_percentage_width", width)
			node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			apply_container_percentage_sizing(node)
		else:
			node.custom_minimum_size.x = width
			node.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	
	if height != null:
		if is_percentage(height):
			node.set_meta("container_percentage_height", height)
			node.size_flags_vertical = Control.SIZE_EXPAND_FILL
			apply_container_percentage_sizing(node)
		else:
			node.custom_minimum_size.y = height
			node.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

static func apply_regular_control_sizing(node: Control, width, height) -> void:
	if width != null:
		if is_percentage(width):
			var estimated_width = calculate_percentage_size(width, 800.0)
			node.custom_minimum_size.x = estimated_width
			node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		else:
			node.custom_minimum_size.x = width
			node.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	
	if height != null:
		if is_percentage(height):
			var estimated_height = calculate_percentage_size(height, 600.0)
			node.custom_minimum_size.y = estimated_height
			node.size_flags_vertical = Control.SIZE_EXPAND_FILL
		else:
			node.custom_minimum_size.y = height
			node.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

static func is_percentage(value) -> bool:
	return typeof(value) == TYPE_STRING and value.ends_with("%")

static func calculate_percentage_size(percentage_str: String, fallback_size: float) -> float:
	var clean_percentage = percentage_str.replace("%", "")
	var percentage = float(clean_percentage) / 100.0
	return fallback_size * percentage

static func apply_container_percentage_sizing(node: Control) -> void:
	var parent = node.get_parent()
	if not parent:
		return

	var new_min_size = node.custom_minimum_size
	
	if node.has_meta("container_percentage_width"):
		var percentage_str = node.get_meta("container_percentage_width")
		var parent_width = get_parent_dimension(parent, true, 800.0)
		new_min_size.x = calculate_percentage_size(percentage_str, parent_width)
	
	if node.has_meta("container_percentage_height"):
		var percentage_str = node.get_meta("container_percentage_height")
		var parent_height = get_parent_dimension(parent, false, 600.0)
		new_min_size.y = calculate_percentage_size(percentage_str, parent_height)
	
	node.custom_minimum_size = new_min_size

static func get_parent_dimension(parent: Control, is_width: bool, fallback: float) -> float:
	var size_value = parent.size.x if is_width else parent.size.y
	if size_value > 0:
		return size_value
	
	var rect_size = parent.get_rect().size.x if is_width else parent.get_rect().size.y
	if rect_size > 0:
		return rect_size
	
	var min_size = parent.custom_minimum_size.x if is_width else parent.custom_minimum_size.y
	if min_size > 0:
		return min_size
	
	return fallback

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
	if radius_str.ends_with("px"):
		return int(radius_str.replace("px", ""))
	elif radius_str.ends_with("rem"):
		return int(radius_str.replace("rem", "")) * 16
	elif radius_str.is_valid_float():
		return int(radius_str)
	else:
		return 0
