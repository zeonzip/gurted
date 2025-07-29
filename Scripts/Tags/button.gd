extends Control

func init(element: HTMLParser.HTMLElement, parser: HTMLParser = null) -> void:
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
	
	if styles.has("background-color"):
		set_meta("custom_css_background_color", styles["background-color"])

	var width = null
	var height = null

	if styles.has("width"):
		width = StyleManager.parse_size(styles["width"])
	if styles.has("height"):
		height = StyleManager.parse_size(styles["height"])

	var button_node = $ButtonNode

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
