extends VBoxContainer

const BROWSER_TEXT = preload("res://Scenes/Styles/BrowserText.tres")

func init(element: HTMLParser.HTMLElement, parser: HTMLParser = null) -> void:
	var list_type = element.get_attribute("type").to_lower()
	if list_type == "": list_type = "disc"  # Default
	
	var marker_min_width = await calculate_marker_width(list_type)
	
	for child_element in element.children:
		if child_element.tag_name == "li":
			var li_node = create_li_node(child_element, list_type, marker_min_width, parser)
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
	StyleManager.apply_styles_to_label(temp_label, {}, null, null, bullet_text)
	
	await get_tree().process_frame
	
	var width = temp_label.get_content_width() + 5  # padding
	
	remove_child(temp_label)
	temp_label.queue_free()
	
	return max(width, 20)  # Minimum pixels

func create_li_node(element: HTMLParser.HTMLElement, list_type: String, marker_width: float = 20, parser: HTMLParser = null) -> Control:
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

	var bullet_styles = parser.get_element_styles_with_inheritance(element, "", []) if parser else {}
	StyleManager.apply_styles_to_label(bullet_label, bullet_styles, element, parser, bullet_text)
	
	# Create content
	var content_label = RichTextLabel.new()
	content_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_label.bbcode_enabled = true
	content_label.fit_content = true
	content_label.theme = BROWSER_TEXT
	content_label.scroll_active = false
	var content_text = element.get_bbcode_formatted_text(parser)

	var content_styles = parser.get_element_styles_with_inheritance(element, "", []) if parser else {}
	StyleManager.apply_styles_to_label(content_label, content_styles, element, parser, content_text)
	
	li_container.add_theme_constant_override("separation", 0)
	li_container.add_child(bullet_label)
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
