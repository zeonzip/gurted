extends Control

func init(element: HTMLParser.HTMLElement) -> void:
	# This is mainly for cases where <li> appears outside of <ul>/<ol>
	var label: RichTextLabel = $RichTextLabel
	label.text = "[font_size=24]%s[/font_size]" % element.get_bbcode_formatted_text()
