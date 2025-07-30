extends Control

var current_element: HTMLParser.HTMLElement
var current_parser: HTMLParser

func init(element: HTMLParser.HTMLElement, parser: HTMLParser = null) -> void:
	current_element = element
	current_parser = parser
	var button_node: Button = $ButtonNode
	
	var button_text = element.text_content.strip_edges()
	if button_text.length() == 0:
		button_text = element.get_bbcode_formatted_text(parser)
	
	if button_text.length() > 0:
		button_node.text = button_text
	
	var natural_size = button_node.get_theme_default_font().get_string_size(
		button_node.text, 
		HORIZONTAL_ALIGNMENT_LEFT, 
		-1, 
		button_node.get_theme_default_font_size()
	) + Vector2(20, 10)  # Add padding
	
	# Force our container to use the natural size
	custom_minimum_size = natural_size
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	
	# Make button node fill the container
	button_node.custom_minimum_size = Vector2.ZERO
	button_node.size_flags_horizontal = Control.SIZE_FILL
	button_node.size_flags_vertical = Control.SIZE_FILL
	
	apply_button_styles(element, parser, natural_size)

func apply_button_styles(element: HTMLParser.HTMLElement, parser: HTMLParser, natural_size: Vector2) -> void:
	if not element or not parser:
		return

	var styles = parser.get_element_styles_internal(element, "")
	var hover_styles = parser.get_element_styles_internal(element, "hover")
	var active_styles = parser.get_element_styles_internal(element, "active")
	var button_node = $ButtonNode
	
	# Apply text color with state-dependent colors
	apply_button_text_color(button_node, styles, hover_styles, active_styles)
	
	# Apply background color (hover: + active:)
	if styles.has("background-color"):
		var normal_color: Color = styles["background-color"]
		var hover_color = normal_color  # Default to normal color
		var active_color = normal_color  # Default to normal color
		
		# Check if background color comes from inline styles
		var inline_style = element.get_attribute("style")
		var inline_normal_styles = parser.parse_inline_style_with_event(inline_style, "")
		var has_inline_bg = inline_normal_styles.has("background-color")
		
		if has_inline_bg:
			# If user set inline bg, only use inline hover/active, ignore global ones
			var inline_hover_styles = parser.parse_inline_style_with_event(inline_style, "hover")
			var inline_active_styles = parser.parse_inline_style_with_event(inline_style, "active")
			
			if inline_hover_styles.has("background-color"):
				hover_color = inline_hover_styles["background-color"]
			if inline_active_styles.has("background-color"):
				active_color = inline_active_styles["background-color"]
			elif inline_hover_styles.has("background-color"):
				# Fallback: if hover is defined but active isn't, use hover for active
				active_color = hover_color
		else:
			# No inline bg, use global CSS hover/active if available
			if hover_styles.has("background-color"):
				hover_color = hover_styles["background-color"]
			if active_styles.has("background-color"):
				active_color = active_styles["background-color"]
			elif hover_styles.has("background-color"):
				# Fallback: if hover is defined but active isn't, use hover for active
				active_color = hover_color
			
		apply_button_color_with_states(button_node, normal_color, hover_color, active_color)
	
	# Apply corner radius
	if styles.has("border-radius"):
		var radius = StyleManager.parse_radius(styles["border-radius"])
		apply_button_radius(button_node, radius)

	var width = null
	var height = null

	if styles.has("width"):
		width = SizingUtils.parse_size_value(styles["width"])
	if styles.has("height"):
		height = SizingUtils.parse_size_value(styles["height"])

	# Only apply size flags if there's explicit sizing
	if width != null or height != null:
		apply_size_and_flags(self, width, height)
		apply_size_and_flags(button_node, width, height, false)
	else:
		# Keep the natural sizing we set earlier
		custom_minimum_size = natural_size
		# Also ensure the ButtonNode doesn't override our size
		button_node.custom_minimum_size = Vector2.ZERO
		button_node.anchors_preset = Control.PRESET_FULL_RECT

func apply_button_text_color(button: Button, normal_styles: Dictionary, hover_styles: Dictionary, active_styles: Dictionary) -> void:
	var normal_color = normal_styles.get("color", Color.WHITE)
	var hover_color = hover_styles.get("color", normal_color)
	var active_color = active_styles.get("color", hover_color)
	
	button.add_theme_color_override("font_color", normal_color)
	button.add_theme_color_override("font_hover_color", hover_color)
	button.add_theme_color_override("font_pressed_color", active_color)
	button.add_theme_color_override("font_focus_color", normal_color)

func apply_button_color_with_states(button: Button, normal_color: Color, hover_color: Color, active_color: Color) -> void:
	var style_normal = StyleBoxFlat.new()
	var style_hover = StyleBoxFlat.new()
	var style_pressed = StyleBoxFlat.new()
	
	var radius: int = 0
	
	style_normal.set_corner_radius_all(radius)
	style_hover.set_corner_radius_all(radius)
	style_pressed.set_corner_radius_all(radius)

	# Set normal color
	style_normal.bg_color = normal_color

	# Set hover: color
	# If hover isn't default, use it
	if hover_color != Color():
		style_hover.bg_color = hover_color
	else:
		# If no hover, fallback to normal color
		style_hover.bg_color = normal_color
	
	# Set active: color
	if active_color != Color():
		style_pressed.bg_color = active_color
	elif hover_color != Color():
		style_pressed.bg_color = hover_color # Fallback to hover if defined
	else:
		style_pressed.bg_color = normal_color # Final fallback to normal
	
	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	
func apply_button_radius(button: Button, radius: int) -> void:
	var style_normal = button.get_theme_stylebox("normal")
	var style_hover = button.get_theme_stylebox("hover")
	var style_pressed = button.get_theme_stylebox("pressed")

	style_normal.set_corner_radius_all(radius)
	style_hover.set_corner_radius_all(radius)
	style_pressed.set_corner_radius_all(radius)

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)

func apply_size_and_flags(ctrl: Control, width: Variant, height: Variant, reset_layout := false) -> void:
	if width != null or height != null:
		ctrl.custom_minimum_size = Vector2(
			width if width != null else ctrl.custom_minimum_size.x,
			height if height != null else ctrl.custom_minimum_size.y
		)
		if width != null:
			ctrl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		if height != null:
			ctrl.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if reset_layout:
		ctrl.position = Vector2.ZERO
		ctrl.anchors_preset = Control.PRESET_FULL_RECT
