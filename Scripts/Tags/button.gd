extends Control

func init(element: HTMLParser.HTMLElement) -> void:
	var button_node: Button = $ButtonNode
	
	var button_text = element.text_content.strip_edges()
	if button_text.length() == 0:
		button_text = element.get_bbcode_formatted_text()
	
	if button_text.length() > 0:
		button_node.text = button_text
	
	button_node.custom_minimum_size = button_node.get_theme_default_font().get_string_size(
		button_node.text, 
		HORIZONTAL_ALIGNMENT_LEFT, 
		-1, 
		button_node.get_theme_default_font_size()
	) + Vector2(20, 10)  # Add padding
