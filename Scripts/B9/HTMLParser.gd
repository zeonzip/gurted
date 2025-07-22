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
	
	func get_attribute(name_: String) -> String:
		return attributes.get(name_, "")
	
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
	
	func get_bbcode_formatted_text() -> String:
		var result = ""
		var has_previous_content = false
		
		if text_content.length() > 0:
			result += get_collapsed_text()
			has_previous_content = true
		
		for child in children:
			var child_content = ""
			match child.tag_name:
				"b":
					child_content = "[b]" + child.get_bbcode_formatted_text() + "[/b]"
				"i":
					child_content = "[i]" + child.get_bbcode_formatted_text() + "[/i]"
				"u":
					child_content = "[u]" + child.get_bbcode_formatted_text() + "[/u]"
				"small":
					child_content = "[font_size=20]" + child.get_bbcode_formatted_text() + "[/font_size]"
				"mark":
					child_content = "[bgcolor=#FFFF00]" + child.get_bbcode_formatted_text() + "[/bgcolor]"
				"code":
					child_content = "[font_size=20][code]" + child.get_bbcode_formatted_text() + "[/code][/font_size]"
				"span":
					child_content = child.get_bbcode_formatted_text()
				_:
					child_content = child.get_bbcode_formatted_text()

			if has_previous_content and child_content.length() > 0:
				result += " "
			
			result += child_content
			
			if child_content.length() > 0:
				has_previous_content = true
		
		return result
	
	func is_inline_element() -> bool:
		return tag_name in ["b", "i", "u", "small", "mark", "code", "span"]

class ParseResult:
	var root: HTMLElement
	var all_elements: Array[HTMLElement] = []
	var errors: Array[String] = []
	
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
		if element.tag_name == tag and element.get_class() == the_class_name:
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
