extends Control
static var button_groups: Dictionary = {}

const BROWSER_TEXT: Theme = preload("res://Scenes/Styles/BrowserText.tres")

var custom_hex_input: LineEdit

func init(element: HTMLParser.HTMLElement) -> void:
	var line_edit: LineEdit = $LineEdit
	var check_box: CheckBox = $CheckBox
	var radio_button: CheckBox = $RadioButton
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

	if input_type == "checkbox":
		if is_instance_valid(line_edit): line_edit.queue_free()
		if is_instance_valid(radio_button): radio_button.queue_free()
		if is_instance_valid(color_picker_button): color_picker_button.queue_free()
		check_box.visible = true
		if value and value == "true": check_box.button_pressed = true
		custom_minimum_size = check_box.size

	elif input_type == "radio":
		if is_instance_valid(line_edit): line_edit.queue_free()
		if is_instance_valid(check_box): check_box.queue_free()
		if is_instance_valid(color_picker_button): color_picker_button.queue_free()
		radio_button.visible = true
		radio_button.toggle_mode = true
		if value and value == "true": radio_button.button_pressed = true
		custom_minimum_size = radio_button.size

		if group.length() > 0:
			if not button_groups.has(group):
				button_groups[group] = ButtonGroup.new()
			radio_button.button_group = button_groups[group]

	elif input_type == "color":
		if is_instance_valid(line_edit): line_edit.queue_free()
		if is_instance_valid(check_box): check_box.queue_free()
		if is_instance_valid(radio_button): radio_button.queue_free()
		color_picker_button.visible = true
		if value and value.length() > 0:
			var color = Color.from_string(value, Color.WHITE)
			color_picker_button.color = color
		custom_minimum_size = color_picker_button.size

	elif input_type == "password":
		if is_instance_valid(check_box): check_box.queue_free()
		if is_instance_valid(radio_button): radio_button.queue_free()
		if is_instance_valid(color_picker_button): color_picker_button.queue_free()
		line_edit.visible = true
		line_edit.secret = true
		custom_minimum_size = line_edit.size
		setup_text_input(line_edit, placeholder, value, minlength, maxlength, pattern)

	else:
		if is_instance_valid(check_box): check_box.queue_free()
		if is_instance_valid(radio_button): radio_button.queue_free()
		if is_instance_valid(color_picker_button): color_picker_button.queue_free()
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
