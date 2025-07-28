extends Control

func init(element: HTMLParser.HTMLElement, parser: HTMLParser = null) -> void:
	var button_node: Button = $ButtonNode
	
	var button_text = element.text_content.strip_edges()
	if button_text.length() == 0:
		button_text = element.get_bbcode_formatted_text(parser)
	
	if button_text.length() > 0:
		button_node.text = button_text
	
	button_node.custom_minimum_size = button_node.get_theme_default_font().get_string_size(
		button_node.text, 
		HORIZONTAL_ALIGNMENT_LEFT, 
		-1, 
		button_node.get_theme_default_font_size()
	) + Vector2(20, 10)  # Add padding

	apply_button_styles(element, parser)

func apply_button_styles(element: HTMLParser.HTMLElement, parser: HTMLParser) -> void:
	if not element or not parser:
		return

	StyleManager.apply_element_styles(self, element, parser)

	var styles = parser.get_element_styles_with_inheritance(element, "", [])

	var width = null
	var height = null

	if styles.has("width"):
		width = StyleManager.parse_size(styles["width"])
	if styles.has("height"):
		height = StyleManager.parse_size(styles["height"])

	var button_node = $ButtonNode

	apply_size_and_flags(self, width, height)
	apply_size_and_flags(button_node, width, height, false)

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
