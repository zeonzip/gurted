class_name HTMLP
extends RichTextLabel

var element_styles: Dictionary = {}

func init(element: HTMLParser.HTMLElement, parser: HTMLParser) -> void:
	element_styles = parser.get_element_styles_with_inheritance(element, "", [])
	
	text = "[font_size=24]%s[/font_size]" % element.get_bbcode_formatted_text(parser)
	
	# Allow mouse events to pass through to parent containers for hover effects while keeping text selection
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	call_deferred("_auto_resize_to_content")
	
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)

func _auto_resize_to_content():
	if not is_inside_tree():
		await tree_entered
	
	var min_width = 20
	var max_width = 800
	var min_height = 30
	
	fit_content = true
	
	var original_autowrap = autowrap_mode
	autowrap_mode = TextServer.AUTOWRAP_OFF
	
	await get_tree().process_frame
	
	var natural_width = size.x
	
	var font_weight_multiplier = _get_font_weight_multiplier()
	natural_width *= font_weight_multiplier
	
	var desired_width = clampf(natural_width, min_width, max_width)
	
	autowrap_mode = original_autowrap
	
	await get_tree().process_frame
	
	var content_height = get_content_height()
	var explicit_height = custom_minimum_size.y if custom_minimum_size.y > 0 else null
	var final_height = explicit_height if explicit_height != null else max(content_height, min_height)
	custom_minimum_size = Vector2(desired_width, final_height)
	
	queue_redraw()

func _get_font_weight_multiplier() -> float:
	if element_styles.has("font-black"):
		return 1.12
	elif element_styles.has("font-extrabold"):
		return 1.10
	elif element_styles.has("font-bold"):
		return 1.08
	elif element_styles.has("font-semibold"):
		return 1.06
	elif element_styles.has("font-medium"):
		return 1.03
	elif element_styles.has("font-light"):
		return 0.98
	elif element_styles.has("font-extralight") or element_styles.has("font-thin"):
		return 0.95
	
	var text_content = get_parsed_text()
	
	if text_content.contains("[b]"):
		return 1.08
	
	return 1.0
