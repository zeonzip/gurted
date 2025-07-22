extends VBoxContainer

func init(element: HTMLParser.HTMLElement) -> void:
	var label: RichTextLabel = $RichTextLabel
	label.text = "[font_size=18]%s[/font_size]" % element.get_collapsed_text()
