extends Control

func init(element: HTMLParser.HTMLElement) -> void:
	var line_edit: LineEdit = $LineEdit
	var check_box: CheckBox = $CheckBox
	
	var input_type = element.get_attribute("type").to_lower()
	var placeholder = element.get_attribute("placeholder")
	var value = element.get_attribute("value")
	
	match input_type:
		"checkbox":
			line_edit.visible = false
			check_box.visible = true
			if value and value == "true": check_box.button_pressed = true
			custom_minimum_size = check_box.size
		_: # Default to text input
			line_edit.visible = true
			check_box.visible = false
			custom_minimum_size = line_edit.size
			
			if placeholder: line_edit.placeholder_text = placeholder
			if value: line_edit.text = value
