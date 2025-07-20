func _test_find_methods(parser: HTMLParser):
	_log_result("\n--- Testing Find Methods ---")
	
	# Test find_all
	var all_scripts = parser.find_all("script")
	_log_result("All script tags: " + str(all_scripts.size()))
	
	var scripts_with_src = parser.find_all("script", "src")
	_log_result("Script tags with src: " + str(scripts_with_src.size()))
	
	# Test find_first
	var first_meta = parser.find_first("meta")
	if first_meta:
		_log_result("First meta tag found with attributes: " + str(first_meta.attributes))
	else:
		_log_result("No meta tags found")
	
	# Test find_by_id (won't find anything in our example)
	var by_id = parser.find_by_id("main")
	_log_result("Element with id 'main': " + str(by_id != null))

func _test_attribute_extraction(parser: HTMLParser):
	_log_result("\n--- Testing Attribute Extraction ---")

	var script_sources = parser.get_attribute_values("script", "src")
	_log_result("Script sources: " + str(script_sources))
	
	var meta_names = parser.get_attribute_values("meta", "name")
	_log_result("Meta names: " + str(meta_names))
	
	var hrefs = parser.get_attribute_values("icon", "href")
	_log_result("Icon hrefs: " + str(hrefs))

func _test_convenience_methods(parser: HTMLParser):
	_log_result("\n--- Testing Convenience Methods ---")
	
	# Test convenience methods
	var title = parser.get_title()
	_log_result("Page title: '" + title + "'")
	
	var theme_color = parser.get_meta_content("theme-color")
	_log_result("Theme color: '" + theme_color + "'")
	
	var description = parser.get_meta_content("description")
	_log_result("Description: '" + description + "'")
	
	var all_scripts = parser.get_all_scripts()
	_log_result("All script sources: " + str(all_scripts))
	
	var all_images = parser.get_all_images()
	_log_result("All image sources: " + str(all_images))
	
	var all_stylesheets = parser.get_all_stylesheets()
	_log_result("All stylesheets: " + str(all_stylesheets))

func _log_element_tree(element: HTMLParser.HTMLElement, depth: int):
	if depth == 0:
		_log_result("\n--- Element Tree ---")
	
	var indent = "  ".repeat(depth)
	var element_info = indent + element.tag_name
	
	if element.attributes.size() > 0:
		element_info += " " + str(element.attributes)
	
	if element.text_content.length() > 0:
		element_info += " [text: '" + element.text_content.substr(0, 30) + "']"
	
	_log_result(element_info)
	
	for child in element.children:
		_log_element_tree(child, depth + 1)