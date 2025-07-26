extends Control

@onready var rich_text_label: RichTextLabel = $RichTextLabel

func init(element: HTMLParser.HTMLElement, parser: HTMLParser = null) -> void:
	var label: RichTextLabel = $RichTextLabel
	label.text = "[font_size=20][b]%s[/b][/font_size]" % element.get_bbcode_formatted_text(parser)
