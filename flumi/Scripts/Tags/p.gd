class_name HTMLP
extends RichTextLabel

func init(element: HTMLParser.HTMLElement, parser: HTMLParser = null) -> void:
	text = "[font_size=24]%s[/font_size]" % element.get_bbcode_formatted_text(parser)
	
	# Allow mouse events to pass through to parent containers for hover effects while keeping text selection
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	# NOTE: estimate width/height because FlexContainer removes our anchor preset (sets 0 width)  
	var plain_text = element.get_collapsed_text()
	var estimated_height = 30
	var estimated_width = min(200, max(100, plain_text.length() * 12))
	
	custom_minimum_size = Vector2(estimated_width, estimated_height)
