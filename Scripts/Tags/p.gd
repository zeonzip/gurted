extends Control

func init(element: HTMLParser.HTMLElement) -> void:
	var label: RichTextLabel = $RichTextLabel
	label.text = "[font_size=24]%s[/font_size]" % element.get_collapsed_text()
