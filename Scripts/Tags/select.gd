extends Control

const BROWSER_TEXT = preload("res://Scenes/Styles/BrowserText.tres")

func init(element: HTMLParser.HTMLElement) -> void:
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
			var is_selected = child_element.get_attribute("selected")
			if is_selected.length() > 0 and selected_index == -1:
				selected_index = option_index
			
			# Check if this option is disabled
			var is_disabled = child_element.get_attribute("disabled")
			if is_disabled.length() > 0:
				option_button.set_item_disabled(option_index, true)
			
			option_index += 1
	
	# Set the selected item
	if selected_index >= 0:
		option_button.selected = selected_index
	
	add_child(option_button)
	custom_minimum_size = option_button.size
