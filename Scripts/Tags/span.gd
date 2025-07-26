extends RichTextLabel

@onready var rich_text_label: RichTextLabel = self

func init(element: HTMLParser.HTMLElement, parser: HTMLParser = null) -> void:
	text = "[font_size=24]%s[/font_size]" % element.get_bbcode_formatted_text(parser)
