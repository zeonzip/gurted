extends VBoxContainer

const BROWSER_TEXT = preload("res://Scenes/Styles/BrowserText.tres")

func init(element: HTMLParser.HTMLElement, parser: HTMLParser = null) -> void:
	var list_type = element.get_attribute("type").to_lower()
	if list_type == "": list_type = "decimal"  # Default
	
	var item_count = 0
	for child_element in element.children:
		if child_element.tag_name == "li":
			item_count += 1
	
	var marker_min_width = await calculate_marker_width(list_type, item_count)
	
	var index = 1
	for child_element in element.children:
		if child_element.tag_name == "li":
			var li_node = create_li_node(child_element, list_type, index, marker_min_width, parser)
			if li_node:
				add_child(li_node)
			index += 1

func calculate_marker_width(list_type: String, max_index: int) -> float:
	var temp_label = RichTextLabel.new()
	temp_label.bbcode_enabled = true
	temp_label.fit_content = true
	temp_label.scroll_active = false
	temp_label.theme = BROWSER_TEXT
	add_child(temp_label)
	
	var marker_text = get_marker_for_type(list_type, max_index)
	StyleManager.apply_styles_to_label(temp_label, {}, null, null, marker_text)
	
	await get_tree().process_frame
	
	var width = temp_label.get_content_width() + 5
	
	remove_child(temp_label)
	temp_label.queue_free()
	
	return max(width, 30)  # Minimum pixels

func create_li_node(element: HTMLParser.HTMLElement, list_type: String, index: int, marker_width: float = 30, parser: HTMLParser = null) -> Control:
	var li_container = HBoxContainer.new()
	
	# Create number/letter marker
	var marker_label = RichTextLabel.new()
	marker_label.custom_minimum_size = Vector2(marker_width, 0)
	marker_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	marker_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	marker_label.bbcode_enabled = true
	marker_label.fit_content = true
	marker_label.scroll_active = false
	marker_label.theme = BROWSER_TEXT
	
	var marker_text = get_marker_for_type(list_type, index)
	StyleManager.apply_styles_to_label(marker_label, {}, null, null, marker_text)
	
	# Create content
	var content_label = RichTextLabel.new()
	content_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_label.bbcode_enabled = true
	content_label.fit_content = true
	content_label.scroll_active = false
	content_label.theme = BROWSER_TEXT
	
	var content_text = element.get_bbcode_formatted_text(parser)
	StyleManager.apply_styles_to_label(content_label, {}, null, null, content_text)
	
	li_container.add_theme_constant_override("separation", 0)
	li_container.add_child(marker_label)
	li_container.add_child(content_label)
	
	var styles = parser.get_element_styles_with_inheritance(element, "", [])
	if BackgroundUtils.needs_background_wrapper(styles):
		var panel_container = BackgroundUtils.create_panel_container_with_background(styles)
		panel_container.name = "Li"
		# Get the VBoxContainer inside PanelContainer and replace it with our HBoxContainer
		var vbox = panel_container.get_child(0)
		panel_container.remove_child(vbox)
		vbox.queue_free()
		panel_container.add_child(li_container)
		return panel_container
	else:
		return li_container

func get_marker_for_type(list_type: String, index: int) -> String:
	match list_type:
		"decimal":
			return str(index) + "."
		"zero-lead":
			return "%02d." % index
		"lower-alpha", "lower-roman":
			return char(96 + index) + "." if list_type == "lower-alpha" else int_to_roman(index).to_lower() + "."
		"upper-alpha", "upper-roman":
			return char(64 + index) + "." if list_type == "upper-alpha" else int_to_roman(index) + "."
		"none":
			return ""
		_:
			return str(index) + "."  # Default to decimal

func int_to_roman(num: int) -> String:
	var values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1]
	var symbols = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"]
	var result = ""
	
	for i in range(values.size()):
		while num >= values[i]:
			result += symbols[i]
			num -= values[i]
	
	return result
