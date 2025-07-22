extends VBoxContainer

func init(element: HTMLParser.HTMLElement) -> void:
	var label: RichTextLabel = $RichTextLabel
	label.text = "[font_size=24][b]%s[/b][/font_size]" % element.get_collapsed_text()
