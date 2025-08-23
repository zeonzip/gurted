class_name HTMLP
extends HBoxContainer

var _element: HTMLParser.HTMLElement
var _parser: HTMLParser

func init(element: HTMLParser.HTMLElement, parser: HTMLParser) -> void:
	_element = element
	_parser = parser
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	if get_child_count() > 0:
		return
	
	var content_parts = []
	var current_text = ""
	
	var element_text = element.text_content
	var child_texts = []
	
	for child in element.children:
		child_texts.append(child.text_content)
	
	var parent_only_text = element_text
	for child_text in child_texts:
		parent_only_text = parent_only_text.replace(child_text, "")
	
	if not parent_only_text.strip_edges().is_empty():
		var parent_label = create_styled_label(parent_only_text.strip_edges(), element, parser)
	
	for child in element.children:
		var child_label = create_styled_label(child.get_bbcode_formatted_text(parser), element, parser)
		
		if contains_hyperlink(child):
			child_label.meta_clicked.connect(_on_meta_clicked)

func create_styled_label(text: String, element: HTMLParser.HTMLElement, parser: HTMLParser) -> RichTextLabel:
	var label = RichTextLabel.new()
	label.fit_content = true
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.bbcode_enabled = true
	add_child(label)
	
	var styles = parser.get_element_styles_with_inheritance(element, "", [])
	StyleManager.apply_styles_to_label(label, styles, element, parser, text)
	
	call_deferred("_apply_auto_resize_to_label", label)
	return label

func _apply_auto_resize_to_label(label: RichTextLabel):
	if not label.is_inside_tree():
		await label.tree_entered
	
	var min_width = 20
	var max_width = 800
	var min_height = 30
	
	label.fit_content = true
	
	var original_autowrap = label.autowrap_mode
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	
	await get_tree().process_frame
	
	var natural_width = label.size.x
	natural_width *= 1.0  # font weight multiplier simplified
	
	var desired_width = clampf(natural_width, min_width, max_width)
	
	label.autowrap_mode = original_autowrap
	
	await get_tree().process_frame
	
	label.custom_minimum_size = Vector2(desired_width, 0)
	
	label.queue_redraw()

func contains_hyperlink(element: HTMLParser.HTMLElement) -> bool:
	if element.tag_name == "a":
		return true
	
	for child in element.children:
		if contains_hyperlink(child):
			return true
	
	return false

func _on_meta_clicked(meta: Variant) -> void:
	var current = get_parent()
	while current:
		if current.has_method("handle_link_click"):
			current.handle_link_click(meta)
			break
		current = current.get_parent()

func get_text() -> String:
	var text_parts = []
	for child in get_children():
		if child is RichTextLabel:
			text_parts.append(child.get_parsed_text())
	return " ".join(text_parts)

func set_text(new_text: String) -> void:
	# Clear existing children immediately
	for child in get_children():
		remove_child(child)
		child.queue_free()
	
	if _element and _parser:
		var label = create_styled_label(new_text, _element, _parser)
	else:
		var label = create_label(new_text)

func create_label(text: String) -> RichTextLabel:
	var label = RichTextLabel.new()
	label.text = text
	label.fit_content = true
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.bbcode_enabled = true
	add_child(label)
	call_deferred("_apply_auto_resize_to_label", label)
	return label
