extends Control

@onready var rich_text_label: RichTextLabel = $RichTextLabel

func init(element: HTMLParser.HTMLElement, parser: HTMLParser = null) -> void:
	var label: RichTextLabel = $RichTextLabel
	label.text = "[font_size=24]%s[/font_size]" % element.get_bbcode_formatted_text(parser)
