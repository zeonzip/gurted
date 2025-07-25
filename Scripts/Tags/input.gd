extends Control
static var button_groups: Dictionary = {}

const BROWSER_TEXT: Theme = preload("res://Scenes/Styles/BrowserText.tres")

var custom_hex_input: LineEdit

func init(element: HTMLParser.HTMLElement) -> void:
	var color_picker_button: ColorPickerButton = $ColorPickerButton
	var picker: ColorPicker = color_picker_button.get_picker()

	picker.sliders_visible = false
	picker.presets_visible = false
	picker.color_modes_visible = false
	picker.hex_visible = false

	# Create custom hex input
	custom_hex_input = LineEdit.new()
	custom_hex_input.placeholder_text = "#RRGGBB"
	
	# Apply custom unique theme
	var picker_theme = BROWSER_TEXT.duplicate()
	picker_theme.set_color("font_color", "LineEdit", Color.WHITE)
	picker_theme.set_color("font_placeholder_color", "LineEdit", Color(1, 1, 1, 0.6))
	picker_theme.set_color("caret_color", "LineEdit", Color.WHITE)

	var normal_style = picker_theme.get_stylebox("normal", "LineEdit").duplicate()
	var focus_style = picker_theme.get_stylebox("focus", "LineEdit").duplicate()
	normal_style.border_color = Color.WHITE
	focus_style.border_color = Color.WHITE
	picker_theme.set_stylebox("normal", "LineEdit", normal_style)
	picker_theme.set_stylebox("focus", "LineEdit", focus_style)

	custom_hex_input.theme = picker_theme
	picker.add_child(custom_hex_input)

	# Connect signals for two-way binding of Hex
	picker.color_changed.connect(_on_picker_color_changed)
	custom_hex_input.text_submitted.connect(_on_custom_hex_submitted)
	# Set initial hex value
	_on_picker_color_changed(picker.color)

	picker.theme = picker_theme
	color_picker_button.get_popup().theme = picker_theme

	var input_type = element.get_attribute("type").to_lower()
	var placeholder = element.get_attribute("placeholder")
	var value = element.get_attribute("value")
	var group = element.get_attribute("group")
	var minlength = element.get_attribute("minlength")
	var maxlength = element.get_attribute("maxlength")
	var pattern = element.get_attribute("pattern")

	# Define which child should be active for each input type
	var active_child_map = {
		"checkbox": "CheckBox",
		"radio": "RadioButton", 
		"color": "ColorPickerButton",
		"password": "LineEdit",
		"date": "DateButton"
	}
	
	var active_child_name = active_child_map.get(input_type, "LineEdit")
	remove_unused_children(active_child_name)
	
	var active_child = get_node(active_child_name)
	active_child.visible = true
	custom_minimum_size = active_child.size

	match input_type:
		"checkbox":
			var checkbox = active_child as CheckBox
			if value and value == "true": 
				checkbox.button_pressed = true
				
		"radio":
			var radio = active_child as CheckBox
			radio.toggle_mode = true
			if value and value == "true": 
				radio.button_pressed = true
			
			if group.length() > 0:
				if not button_groups.has(group):
					button_groups[group] = ButtonGroup.new()
				radio.button_group = button_groups[group]
				
		"color":
			var color_button = active_child as ColorPickerButton
			if value and value.length() > 0:
				var color = Color.from_string(value, Color.WHITE)
				color_button.color = color
				
		"password":
			var line_edit = active_child as LineEdit
			line_edit.secret = true
			setup_text_input(line_edit, placeholder, value, minlength, maxlength, pattern)
			
		"date":
			var date_button = active_child as DateButton
			if value and value.length() > 0:
				date_button.init_with_date(value)
			else:
				date_button.init()
			
		_: # Default case (text input)
			var line_edit = active_child as LineEdit
			line_edit.secret = false
			setup_text_input(line_edit, placeholder, value, minlength, maxlength, pattern)

func remove_unused_children(keep_child_name: String) -> void:
	for child in get_children():
		if child.name != keep_child_name:
			child.queue_free()

func setup_text_input(line_edit: LineEdit, placeholder: String, value: String, minlength: String, maxlength: String, pattern: String) -> void:
	if placeholder: line_edit.placeholder_text = placeholder
	if value: line_edit.text = value

	line_edit.max_length = maxlength.to_int()

	if minlength.length() > 0 or pattern.length() > 0:
		line_edit.text_changed.connect(_on_text_changed.bind(minlength, pattern))

func _on_text_changed(new_text: String, minlength: String, pattern: String) -> void:
	var line_edit = get_node("LineEdit") as LineEdit
	var is_valid = true

	if minlength.length() > 0 and minlength.is_valid_int():
		var min_len = minlength.to_int()
		if new_text.length() < min_len and new_text.length() > 0:
			is_valid = false

	if pattern.length() > 0 and new_text.length() > 0:
		var regex = RegEx.new()
		if regex.compile(pattern) == OK:
			if not regex.search(new_text):
				is_valid = false

	if is_valid:
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

func _on_picker_color_changed(new_color: Color) -> void:
	var hex_string = "#" + new_color.to_html(false)
	custom_hex_input.text = hex_string

func _on_custom_hex_submitted(new_text: String) -> void:
	var cleaned_text = new_text.strip_edges()
	if not cleaned_text.begins_with("#"):
		cleaned_text = "#" + cleaned_text
	
	var new_color = Color.from_string(cleaned_text, Color.WHITE)
	
	var picker = ($ColorPickerButton as ColorPickerButton).get_picker()
	picker.set_pick_color(new_color)
	$ColorPickerButton.color = new_color
