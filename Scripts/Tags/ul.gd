extends VBoxContainer

const BROWSER_TEXT = preload("res://Scenes/Styles/BrowserText.tres")

func init(element: HTMLParser.HTMLElement) -> void:
	var list_type = element.get_attribute("type").to_lower()
	if list_type == "": list_type = "disc"  # Default
	
	var marker_min_width = await calculate_marker_width(list_type)
	
	for child_element in element.children:
		if child_element.tag_name == "li":
			var li_node = create_li_node(child_element, list_type, marker_min_width)
			if li_node:
				add_child(li_node)

func calculate_marker_width(list_type: String) -> float:
	var temp_label = RichTextLabel.new()
	temp_label.bbcode_enabled = true
	temp_label.fit_content = true
	temp_label.scroll_active = false
	temp_label.theme = BROWSER_TEXT
	add_child(temp_label)
	
	var bullet_text = get_bullet_for_type(list_type)
	temp_label.text = "[font_size=24]%s[/font_size]" % bullet_text
	
	await get_tree().process_frame
	
	var width = temp_label.get_content_width() + 5  # padding
	
	remove_child(temp_label)
	temp_label.queue_free()
	
	return max(width, 20)  # Minimum pixels

func create_li_node(element: HTMLParser.HTMLElement, list_type: String, marker_width: float = 20) -> Control:
	var li_container = HBoxContainer.new()
	
	# Create bullet point
	var bullet_label = RichTextLabel.new()
	bullet_label.custom_minimum_size = Vector2(marker_width, 0)
	bullet_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bullet_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bullet_label.bbcode_enabled = true
	bullet_label.fit_content = true
	bullet_label.scroll_active = false
	bullet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bullet_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bullet_label.theme = BROWSER_TEXT
	
	var bullet_text = get_bullet_for_type(list_type)
	bullet_label.text = "[font_size=24]%s[/font_size]" % bullet_text
	
	# Create content
	var content_label = RichTextLabel.new()
	content_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_label.bbcode_enabled = true
	content_label.fit_content = true
	content_label.theme = BROWSER_TEXT
	content_label.scroll_active = false
	content_label.text = "[font_size=24]%s[/font_size]" % element.get_bbcode_formatted_text()
	
	li_container.add_theme_constant_override("separation", 0)
	li_container.add_child(bullet_label)
	li_container.add_child(content_label)
	
	return li_container

func get_bullet_for_type(list_type: String) -> String:
	match list_type:
		"circle":
			return "◦"
		"disc":
			return "•"
		"square":
			return "■"
		"none":
			return " "
		_:
			return "•"  # Default to disc
