extends VBoxContainer

func init(element: HTMLParser.HTMLElement) -> void:
	var label: RichTextLabel = $RichTextLabel
	label.text = "[font_size=24][bgcolor=#FFFF00]%s[/bgcolor][/font_size]" % element.get_collapsed_text()
