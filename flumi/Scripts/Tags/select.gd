extends Control

const BROWSER_TEXT = preload("res://Scenes/Styles/BrowserText.tres")

func init(element: HTMLParser.HTMLElement, _parser: HTMLParser = null) -> void:
	var option_button: OptionButton = $OptionButton
	
	var selected_index = -1
	var option_index = 0

	# find <option>s
	for child_element in element.children:
		if child_element.tag_name == "option":
			var option_text = child_element.text_content.strip_edges()
			var option_value = child_element.get_attribute("value")

			option_value = option_text
			
			option_button.add_item(option_text, option_index)
			option_button.set_item_metadata(option_index, option_value)
			
			# Check if this option is selected
			if child_element.has_attribute("selected") and selected_index == -1:
				selected_index = option_index
			
			# Check if this option is disabled
			option_button.set_item_disabled(option_index, child_element.has_attribute("disabled"))
			
			option_index += 1
	
	# Set the selected item
	if selected_index >= 0:
		option_button.selected = selected_index
	
	custom_minimum_size = option_button.size
