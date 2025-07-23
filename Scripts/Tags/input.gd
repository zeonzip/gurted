extends Control
static var button_groups: Dictionary = {}

func init(element: HTMLParser.HTMLElement) -> void:
	var line_edit: LineEdit = $LineEdit
	var check_box: CheckBox = $CheckBox
	var radio_button: CheckBox = $RadioButton
	
	var input_type = element.get_attribute("type").to_lower()
	var placeholder = element.get_attribute("placeholder")
	var value = element.get_attribute("value")
	var group = element.get_attribute("group")
	var minlength = element.get_attribute("minlength")
	var maxlength = element.get_attribute("maxlength")
	var pattern = element.get_attribute("pattern")
	
	# Hide all inputs initially
	line_edit.visible = false
	check_box.visible = false
	radio_button.visible = false
	
	match input_type:
		"checkbox":
			check_box.visible = true
			if value and value == "true": check_box.button_pressed = true
			custom_minimum_size = check_box.size
		"radio":
			radio_button.visible = true
			radio_button.toggle_mode = true
			if value and value == "true": radio_button.button_pressed = true
			custom_minimum_size = radio_button.size
			
			if group.length() > 0:
				if not button_groups.has(group):
					button_groups[group] = ButtonGroup.new()
				radio_button.button_group = button_groups[group]
		"password":
			line_edit.visible = true
			line_edit.secret = true
			custom_minimum_size = line_edit.size
			setup_text_input(line_edit, placeholder, value, minlength, maxlength, pattern)
		_: # Default to text input
			line_edit.visible = true
			line_edit.secret = false
			custom_minimum_size = line_edit.size
			setup_text_input(line_edit, placeholder, value, minlength, maxlength, pattern)

func setup_text_input(line_edit: LineEdit, placeholder: String, value: String, minlength: String, maxlength: String, pattern: String) -> void:
	if placeholder: line_edit.placeholder_text = placeholder
	if value: line_edit.text = value
	
	line_edit.max_length = maxlength.to_int()
	
	if minlength.length() > 0 or pattern.length() > 0:
		line_edit.text_changed.connect(_on_text_changed.bind(minlength, pattern))

func _on_text_changed(new_text: String, minlength: String, pattern: String) -> void:
	var line_edit = get_node("LineEdit") as LineEdit
	var is_valid = true
	
	# Check minimum length
	if minlength.length() > 0 and minlength.is_valid_int():
		var min_len = minlength.to_int()
		if new_text.length() < min_len and new_text.length() > 0:
			is_valid = false
	
	# Check pattern (regex)
	if pattern.length() > 0 and new_text.length() > 0:
		var regex = RegEx.new()
		if regex.compile(pattern) == OK:
			if not regex.search(new_text):
				is_valid = false
	
	if is_valid:
		# Reset to default styles
		line_edit.remove_theme_stylebox_override("normal")
		line_edit.remove_theme_stylebox_override("focus")
		line_edit.modulate = Color.WHITE
	else:
		var normal_style = create_red_border_style_from_theme(line_edit, "normal")
		var focus_style = create_red_border_style_from_theme(line_edit, "focus")
		
		line_edit.add_theme_stylebox_override("normal", normal_style)
		line_edit.add_theme_stylebox_override("focus", focus_style)
		line_edit.modulate = Color.WHITE

func create_red_border_style_from_theme(line_edit: LineEdit, style_name: String) -> StyleBoxFlat:
	var original_style: StyleBoxFlat = line_edit.get_theme_stylebox(style_name)
	var style: StyleBoxFlat = original_style.duplicate()
	
	style.border_color = Color.RED
	
	return style
