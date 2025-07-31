class_name HTMLParser
extends Node

class HTMLElement:
	var tag_name: String
	var attributes: Dictionary = {}
	var text_content: String = ""
	var children: Array[HTMLElement] = []
	var parent: HTMLElement = null
	var is_self_closing: bool = false
	
	func _init(tag: String = ""):
		tag_name = tag
	
	func get_attribute(name_: String, default: String = "") -> String:
		return attributes.get(name_, default)
	
	func has_attribute(name_: String) -> bool:
		return attributes.has(name_)
	
	func get_class_name() -> String:
		return get_attribute("class")
	
	func get_id() -> String:
		return get_attribute("id")
	
	func get_collapsed_text() -> String:
		var collapsed = text_content.strip_edges()
		# Replace multiple whitespace characters with single space
		var regex = RegEx.new()
		regex.compile("\\s+")
		return regex.sub(collapsed, " ", true)
	
	func get_preserved_text() -> String:
		return text_content
	
	func get_bbcode_formatted_text(parser: HTMLParser = null) -> String:
		return HTMLParser.get_bbcode_with_styles(self, {}, parser)  # Pass empty dict for default
	
	func is_inline_element() -> bool:
		return tag_name in ["b", "i", "u", "small", "mark", "code", "span", "a", "input"]

class ParseResult:
	var root: HTMLElement
	var all_elements: Array[HTMLElement] = []
	var errors: Array[String] = []
	var css_parser: CSSParser = null
	var inline_styles: Dictionary = {}
	
	func _init():
		root = HTMLElement.new("document")

# Properties
var xml_parser: XMLParser
var bitcode: PackedByteArray
var parse_result: ParseResult

func _init(data: PackedByteArray):
	bitcode = data
	xml_parser = XMLParser.new()
	parse_result = ParseResult.new()

# Main parsing function
func parse() -> ParseResult:
	xml_parser.open_buffer(bitcode)
	var element_stack: Array[HTMLElement] = [parse_result.root]

	while xml_parser.read() != ERR_FILE_EOF:
		match xml_parser.get_node_type():
			XMLParser.NODE_ELEMENT:
				var element = create_element()
				var current_parent = element_stack.back()
				element.parent = current_parent
				current_parent.children.append(element)
				parse_result.all_elements.append(element)
				
				if element.tag_name == "style":
					handle_style_element(element)
				
				if not element.is_self_closing:
					element_stack.append(element)
			
			XMLParser.NODE_ELEMENT_END:
				if element_stack.size() > 1:
					element_stack.pop_back()
			
			XMLParser.NODE_TEXT:
				var text = xml_parser.get_node_data().strip_edges()
				if text.length() > 0 and element_stack.size() > 0:
					element_stack.back().text_content += text
	
	return parse_result

func handle_style_element(style_element: HTMLElement) -> void:
	# Check if it's an external stylesheet
	var src = style_element.get_attribute("src")
	if src.length() > 0:
		# TODO: Handle external CSS loading when Network module is available
		print("External CSS not yet supported: " + src)
		return
	
	# Handle inline CSS - we'll get the text content when parsing is complete
	# For now, create a parser that will be populated later
	if not parse_result.css_parser:
		parse_result.css_parser = CSSParser.new()
		parse_result.css_parser.init()

func process_styles() -> void:
	if not parse_result.css_parser:
		return
	
	# Collect all style element content
	var css_content = Constants.DEFAULT_CSS
	var style_elements = find_all("style")
	for style_element in style_elements:
		if style_element.get_attribute("src").is_empty():
			css_content += style_element.text_content + "\n"
	print("Processing CSS: ", css_content)
	# Parse CSS if we have any
	if css_content.length() > 0:
		parse_result.css_parser.css_text = css_content
		parse_result.css_parser.parse()
		for child: CSSParser.CSSRule in parse_result.css_parser.stylesheet.rules:
			print("INFO: for selector \"%s\" we have props: %s" % [child.selector, child.properties])

func get_element_styles_with_inheritance(element: HTMLElement, event: String = "", visited_elements: Array = []) -> Dictionary:
	# Prevent infinite recursion
	if element in visited_elements:
		return {}

	visited_elements.append(element)
	
	var styles = {}
	
	var class_names = extract_class_names_from_style(element)
	styles.merge(parse_result.css_parser.stylesheet.get_styles_for_element(element.tag_name, event, class_names))
	# Apply inline styles (higher priority) - force override CSS rules
	var inline_style = element.get_attribute("style")
	if inline_style.length() > 0:
		var inline_parsed = CSSParser.parse_inline_style(inline_style)
		for property in inline_parsed:
			styles[property] = inline_parsed[property]
	
	# Inherit certain properties from parent elements
	var inheritable_properties = ["width", "height", "font-size", "color", "font-family"]
	var parent_element = element.parent
	while parent_element and parent_element.tag_name != "body":
		var parent_styles = get_element_styles_internal(parent_element, event)
		for property in inheritable_properties:
			# Only inherit if child doesn't already have this property
			if not styles.has(property) and parent_styles.has(property):
				styles[property] = parent_styles[property]
		parent_element = parent_element.parent
	
	return styles

func get_element_styles_internal(element: HTMLElement, event: String = "") -> Dictionary:
	var styles = {}
	
	# Apply CSS rules
	if parse_result.css_parser:
		var class_names = extract_class_names_from_style(element)
		styles.merge(parse_result.css_parser.stylesheet.get_styles_for_element(element.tag_name, event, class_names))
	
	# Apply inline styles (higher priority) - force override CSS rules
	var inline_style = element.get_attribute("style")
	if inline_style.length() > 0:
		var inline_parsed = parse_inline_style_with_event(inline_style, event)
		for property in inline_parsed:
			styles[property] = inline_parsed[property]  # Force override
	
	return styles

func parse_inline_style_with_event(style_string: String, event: String = "") -> Dictionary:
	var properties = {}
	
	# Split style string into individual utility classes
	var utility_classes = style_string.split(" ") # e.g. ["bg-red-500, "text-lg", "hover:bg-blue-500"]

	for utility_name in utility_classes:
		utility_name = utility_name.strip_edges() # e.g. "bg-red-500"
		if utility_name.is_empty():
			continue
		
		# Check if this utility is for the requested event
		if event.length() > 0:
			if utility_name.begins_with(event + ":"): # e.g. "hover:bg-blue-500"
				var actual_utility = utility_name.substr(event.length() + 1)  # bg-blue-500
				var rule = CSSParser.CSSRule.new()
				CSSParser.parse_utility_class_internal(rule, actual_utility)
				for property in rule.properties:
					properties[property] = rule.properties[property]
		else:
			if not utility_name.contains(":"):
				var rule = CSSParser.CSSRule.new()
				CSSParser.parse_utility_class_internal(rule, utility_name)
				for property in rule.properties:
					properties[property] = rule.properties[property]
	
	return properties

func extract_class_names_from_style(element: HTMLElement) -> Array[String]:
	var class_names: Array[String] = []
	var style_attr = element.get_attribute("style")
	if style_attr.length() > 0:
		var style_tokens = style_attr.split(" ")
		for token in style_tokens:
			token = token.strip_edges()
			if token.length() > 0 and not UtilityClassValidator.is_utility_class(token):
				class_names.append(token)
	return class_names

# Creates element from CURRENT xml parser node
func create_element() -> HTMLElement:
	var element = HTMLElement.new(xml_parser.get_node_name())
	element.is_self_closing = xml_parser.is_empty()
	
	# Parse attributes
	for i in range(xml_parser.get_attribute_count()):
		var attr_name = xml_parser.get_attribute_name(i)
		var attr_value = xml_parser.get_attribute_value(i)
		element.attributes[attr_name] = attr_value
	
	return element

# Utility functions
func find_all(tag: String, attribute: String = "") -> Array[HTMLElement]:
	if parse_result.all_elements.is_empty():
		parse()
	
	var results: Array[HTMLElement] = []
	for element in parse_result.all_elements:
		if element.tag_name == tag:
			if attribute.is_empty() or element.has_attribute(attribute):
				results.append(element)
	
	return results

func find_all_by_class(tag: String, the_class_name: String) -> Array[HTMLElement]:
	if parse_result.all_elements.is_empty():
		parse()
	
	var results: Array[HTMLElement] = []
	for element in parse_result.all_elements:
		if element.tag_name == tag and element.get_class_name() == the_class_name:
			results.append(element)
	
	return results

func find_by_id(element_id: String) -> HTMLElement:
	if parse_result.all_elements.is_empty():
		parse()
	
	for element in parse_result.all_elements:
		if element.get_id() == element_id:
			return element
	
	return null

func find_first(tag: String, attribute: String = "") -> HTMLElement:
	var results = find_all(tag, attribute)
	return results[0] if results.size() > 0 else null

# Extract attribute values
func get_attribute_values(tag: String, attribute: String) -> Array[String]:
	var elements = find_all(tag, attribute)
	var values: Array[String] = []
	
	for element in elements:
		var value = element.get_attribute(attribute)
		if value.length() > 0:
			values.append(value)
	
	return values

func get_attribute_values_by_class(tag: String, the_class_name: String, attribute: String) -> Array[String]:
	var elements = find_all_by_class(tag, the_class_name)
	var values: Array[String] = []
	
	for element in elements:
		var value = element.get_attribute(attribute)
		if value.length() > 0:
			values.append(value)
	
	return values

# Misc
func get_title() -> String:
	var title_element = find_first("title")
	return title_element.text_content if title_element != null else ""

func get_icon() -> String:
	var icon_element = find_first("icon")
	return icon_element.get_attribute("src")

func process_fonts() -> void:
	var font_elements = find_all("font")
	
	for font_element in font_elements:
		var name = font_element.get_attribute("name")
		var src = font_element.get_attribute("src")
		var weight = font_element.get_attribute("weight", "400")
		
		if name and src:
			FontManager.register_font(name, src, weight)

func get_meta_content(name_: String) -> String:
	var meta_elements = find_all("meta", "name")
	for element in meta_elements:
		if element.get_attribute("name") == name_:
			return element.get_attribute("content")
	return ""

func get_all_links() -> Array[String]:
	return get_attribute_values("a", "href")

func get_all_images() -> Array[String]:
	return get_attribute_values("img", "src")

func get_all_scripts() -> Array[String]:
	return get_attribute_values("script", "src")

func get_all_stylesheets() -> Array[String]:
	return get_attribute_values("style", "src")

func apply_element_styles(node: Control, element: HTMLElement, parser: HTMLParser) -> void:
	var styles = parser.get_element_styles_with_inheritance(element, "", [])
	if node.get("rich_text_label"):
		var label = node.rich_text_label
		var text = HTMLParser.get_bbcode_with_styles(element, styles, parser)
		label.text = text

static func get_bbcode_with_styles(element: HTMLElement, styles: Dictionary, parser: HTMLParser) -> String:
	var text = ""
	if element.text_content.length() > 0:
		text += element.get_collapsed_text()

	for child in element.children:
		var child_styles = styles
		if parser != null:
			child_styles = parser.get_element_styles_with_inheritance(child, "", [])
		var child_content = HTMLParser.get_bbcode_with_styles(child, child_styles, parser)
		match child.tag_name:
			"b":
				if child_styles.has("font-bold") and child_styles["font-bold"]:
					child_content = "[b]" + child_content + "[/b]"
			"i":
				if child_styles.has("font-italic") and child_styles["font-italic"]:
					child_content = "[i]" + child_content + "[/i]"
			"u":
				if child_styles.has("underline") and child_styles["underline"]:
					child_content = "[u]" + child_content + "[/u]"
			"small":
				if child_styles.has("font-size"):
					child_content = "[font_size=%d]%s[/font_size]" % [child_styles["font-size"], child_content]
				else:
					child_content = "[font_size=20]%s[/font_size]" % child_content
			"mark":
				if child_styles.has("bg"):
					var color = child_styles["bg"]
					if typeof(color) == TYPE_COLOR:
						color = color.to_html(false)
					child_content = "[bgcolor=#%s]%s[/bgcolor]" % [color, child_content]
				else:
					child_content = "[bgcolor=#FFFF00]%s[/bgcolor]" % child_content
			"code":
				if child_styles.has("font-size"):
					child_content = "[font_size=%d][code]%s[/code][/font_size]" % [child_styles["font-size"], child_content]
				else:
					child_content = "[font_size=20][code]%s[/code][/font_size]" % child_content
			"a":
				var href = child.get_attribute("href")
				var color = "#1a0dab"
				if child_styles.has("color"):
					var c = child_styles["color"]
					if typeof(c) == TYPE_COLOR:
						color = "#" + c.to_html(false)
					else:
						color = str(c)
				if href.length() > 0:
					child_content = "[color=%s][url=%s]%s[/url][/color]" % [color, href, child_content]
			_:
				pass
		text += child_content
	return text
