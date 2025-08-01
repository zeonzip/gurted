extends Control

func init(element: HTMLParser.HTMLElement, parser: HTMLParser = null) -> void:
	# This is mainly for cases where <li> appears outside of <ul>/<ol>
	var label: RichTextLabel = $RichTextLabel
	var styles = parser.get_element_styles_with_inheritance(element, "", [])

	StyleManager.apply_styles_to_label(label, styles, element, parser)