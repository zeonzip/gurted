extends Control
static var button_groups: Dictionary = {}

const BROWSER_TEXT: Theme = preload("res://Scenes/Styles/BrowserText.tres")

var custom_hex_input: LineEdit
var _file_text_content: String = ""
var _file_binary_content: PackedByteArray = PackedByteArray()

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
	var min_attr = element.get_attribute("min")
	var max_attr = element.get_attribute("max")
	var step_attr = element.get_attribute("step")
	var accept = element.get_attribute("accept")

	# Define which child should be active for each input type
	var active_child_map = {
		"checkbox": "CheckBox",
		"radio": "RadioButton", 
		"color": "ColorPickerButton",
		"password": "LineEdit",
		"date": "DateButton",
		"range": "HSlider",
		"number": "SpinBox",
		"file": "FileContainer"
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
		
		"range":
			var slider = active_child as HSlider
			setup_range_input(slider, value, min_attr, max_attr, step_attr)
		
		"number":
			var spin_box = active_child as SpinBox
			setup_number_input(spin_box, value, min_attr, max_attr, step_attr, placeholder)
		
		"file":
			var file_container = active_child as Control
			setup_file_input(file_container, accept)
			
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

func setup_range_input(slider: HSlider, value: String, min_attr: String, max_attr: String, step_attr: String) -> void:
	var min_val = min_attr.to_float() if min_attr.length() > 0 else 0.0
	var max_val = max_attr.to_float() if max_attr.length() > 0 else 100.0
	var step_val = step_attr.to_float() if step_attr.length() > 0 else 1.0
	
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = step_val
	slider.value = value.to_float() if value.length() > 0 else min_val

func setup_number_input(spin_box: SpinBox, value: String, min_attr: String, max_attr: String, step_attr: String, placeholder: String) -> void:
	var min_val = min_attr.to_float() if min_attr.length() > 0 else -99999.0
	var max_val = max_attr.to_float() if max_attr.length() > 0 else 99999.0
	var step_val = step_attr.to_float() if step_attr.length() > 0 else 1.0
	
	spin_box.min_value = min_val
	spin_box.max_value = max_val
	spin_box.step = step_val
	spin_box.value = value.to_float() if value.length() > 0 else min_val
	
	var line_edit = spin_box.get_line_edit()
	line_edit.placeholder_text = placeholder

func setup_file_input(file_container: Control, accept: String = "") -> void:
	var file_button = file_container.get_node("FileButton") as Button
	var file_label = file_container.get_node("FileLabel") as Label
	var file_dialog = file_container.get_node("FileDialog") as FileDialog
	
	if accept.length() > 0:
		setup_file_filters(file_dialog, accept)
	
	file_button.pressed.connect(_on_file_button_pressed)
	file_dialog.file_selected.connect(_on_file_selected)
	
	file_label.text = "No file chosen"

func setup_file_filters(file_dialog: FileDialog, accept: String) -> void:
	file_dialog.clear_filters()
	
	var filters = accept.split(",")
	var image_extensions = ["jpg", "jpeg", "png", "gif", "bmp", "webp", "svg"]
	var audio_extensions = ["mp3", "wav", "ogg", "m4a", "flac"]
	var video_extensions = ["mp4", "avi", "mov", "wmv", "flv", "webm"]
	
	for filter in filters:
		filter = filter.strip_edges()
		
		if filter == "image/*":
			for ext in image_extensions:
				file_dialog.add_filter("*." + ext, "Image Files")
		elif filter == "audio/*":
			for ext in audio_extensions:
				file_dialog.add_filter("*." + ext, "Audio Files")
		elif filter == "video/*":
			for ext in video_extensions:
				file_dialog.add_filter("*." + ext, "Video Files")
		elif filter.begins_with("."):
			# Individual file extension
			var ext = filter.substr(1)
			file_dialog.add_filter("*" + filter, ext.to_upper() + " Files")
		elif filter.contains("/"):
			# MIME type - convert to common extensions
			match filter:
				"text/plain":
					file_dialog.add_filter("*.txt", "Text Files")
				"application/pdf":
					file_dialog.add_filter("*.pdf", "PDF Files")
				"application/json":
					file_dialog.add_filter("*.json", "JSON Files")
				"text/html":
					file_dialog.add_filter("*.html", "HTML Files")
				"text/css":
					file_dialog.add_filter("*.css", "CSS Files")
				"application/javascript":
					file_dialog.add_filter("*.js", "JavaScript Files")

	# If no valid filters were added, allow all files
	if file_dialog.filters.size() == 0:
		file_dialog.add_filter("*", "All Files")

func _on_file_button_pressed() -> void:
	var file_dialog = get_node("FileContainer/FileDialog") as FileDialog
	file_dialog.popup_centered(Vector2i(800, 600))

func _on_file_selected(path: String) -> void:
	var file_label = get_node("FileContainer/FileLabel") as Label
	var file_name = path.get_file()
	file_label.text = file_name
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		_file_text_content = file.get_as_text()
		file.close()
		
		file = FileAccess.open(path, FileAccess.READ)
		_file_binary_content = file.get_buffer(file.get_length())
		file.close()
		
		# TODO: when adding Lua, make these actually usable
