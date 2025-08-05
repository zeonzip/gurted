extends RefCounted
class_name LuaClassListUtils

static func element_classlist_add_handler(vm: LuauVM, dom_parser: HTMLParser) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	var css_class: String = vm.luaL_checkstring(2)
	
	vm.lua_getfield(1, "_element_id")
	var element_id: String = vm.lua_tostring(-1)
	vm.lua_pop(1)
	
	# Find the element
	var element = dom_parser.find_by_id(element_id)
	if not element:
		print("DEBUG: Element not found!")
		return 0
	
	# Get classes
	var current_style = element.get_attribute("style", "")
	var style_classes = CSSParser.smart_split_utility_classes(current_style) if current_style.length() > 0 else []
	
	# Add new css_class if not already present
	if css_class not in style_classes:
		style_classes.append(css_class)
		var new_style_attr = " ".join(style_classes)
		element.set_attribute("style", new_style_attr)
		trigger_element_restyle(element, dom_parser)
	else:
		print("DEBUG: classList.add - Class already exists")
	
	return 0

static func element_classlist_remove_handler(vm: LuauVM, dom_parser: HTMLParser) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	var css_class: String = vm.luaL_checkstring(2)
	
	vm.lua_getfield(1, "_element_id")
	var element_id: String = vm.lua_tostring(-1)
	vm.lua_pop(1)
	
	# Find the element
	var element = dom_parser.find_by_id(element_id)
	if not element:
		return 0
	
	# Get style attribute
	var current_style = element.get_attribute("style", "")
	if current_style.length() == 0:
		return 0
	
	var style_classes = CSSParser.smart_split_utility_classes(current_style)
	var clean_classes = []
	for style_cls in style_classes:
		if style_cls != css_class:
			clean_classes.append(style_cls)
	
	# Update style attribute
	if clean_classes.size() > 0:
		var new_style_attr = " ".join(clean_classes)
		element.set_attribute("style", new_style_attr)
	else:
		element.attributes.erase("style")
	
	trigger_element_restyle(element, dom_parser)
	return 0

static func element_classlist_toggle_handler(vm: LuauVM, dom_parser: HTMLParser) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	var css_class: String = vm.luaL_checkstring(2)
	
	vm.lua_getfield(1, "_element_id")
	var element_id: String = vm.lua_tostring(-1)
	vm.lua_pop(1)
	
	# Find the element
	var element = dom_parser.find_by_id(element_id)
	if not element:
		vm.lua_pushboolean(false)
		return 1
	
	# Get style attribute
	var current_style = element.get_attribute("style", "")
	var style_classes = CSSParser.smart_split_utility_classes(current_style) if current_style.length() > 0 else []
	
	var has_css_class = css_class in style_classes
	
	if has_css_class:
		# Remove css_class
		var new_classes = []
		for style_cls in style_classes:
			if style_cls != css_class:
				new_classes.append(style_cls)
		
		if new_classes.size() > 0:
			element.set_attribute("style", " ".join(new_classes))
		else:
			element.attributes.erase("style")
		
		vm.lua_pushboolean(false)
	else:
		# Add css_class
		style_classes.append(css_class)
		element.set_attribute("style", " ".join(style_classes))
		vm.lua_pushboolean(true)
	
	trigger_element_restyle(element, dom_parser)
	return 1

static func trigger_element_restyle(element: HTMLParser.HTMLElement, dom_parser: HTMLParser) -> void:
	# Find DOM node for element
	var element_id = element.get_attribute("id")
	var dom_node = dom_parser.parse_result.dom_nodes.get(element_id, null)
	if not dom_node:
		return
		
	# margins, wrappers, etc.
	var updated_dom_node = StyleManager.apply_element_styles(dom_node, element, dom_parser)
	
	# If the node was wrapped/unwrapped by margin handling, update DOM registration
	if updated_dom_node != dom_node:
		dom_parser.parse_result.dom_nodes[element_id] = updated_dom_node
		dom_node = updated_dom_node
	
	# Find node
	var actual_element_node = dom_node
	if dom_node is MarginContainer and dom_node.name.begins_with("MarginWrapper_"):
		if dom_node.get_child_count() > 0:
			actual_element_node = dom_node.get_child(0)
	
	if actual_element_node is HTMLButton:
		actual_element_node.apply_button_styles(element, dom_parser)
	elif element.tag_name == "div":
		update_div_hover_styles(actual_element_node, element, dom_parser)
	else:
		update_element_text_content(actual_element_node, element, dom_parser)
		
		if actual_element_node.has_method("init"):
			actual_element_node.init(element, dom_parser)

static func update_element_text_content(dom_node: Control, element: HTMLParser.HTMLElement, dom_parser: HTMLParser) -> void:
	# Get node
	var content_node = dom_node
	if dom_node is MarginContainer and dom_node.name.begins_with("MarginWrapper_"):
		if dom_node.get_child_count() > 0:
			content_node = dom_node.get_child(0)
	
	# Handle RichTextLabel elements (p, span, etc.)
	if content_node is RichTextLabel:
		var styles = dom_parser.get_element_styles_with_inheritance(element, "", [])
		StyleManager.apply_styles_to_label(content_node, styles, element, dom_parser)
		return
	
	# Handle div elements that might contain RichTextLabel children
	if element.tag_name == "div":
		update_text_labels_recursive(content_node, element, dom_parser)
		return

static func update_text_labels_recursive(node: Node, element: HTMLParser.HTMLElement, dom_parser: HTMLParser) -> void:
	if node is RichTextLabel:
		var styles = dom_parser.get_element_styles_with_inheritance(element, "", [])
		StyleManager.apply_styles_to_label(node, styles, element, dom_parser)
		return
	
	for child in node.get_children():
		update_text_labels_recursive(child, element, dom_parser)

static func update_div_hover_styles(dom_node: Control, element: HTMLParser.HTMLElement, dom_parser: HTMLParser) -> void:
	var styles = dom_parser.get_element_styles_with_inheritance(element, "", [])
	var hover_styles = dom_parser.get_element_styles_with_inheritance(element, "hover", [])
	
	if dom_node is PanelContainer:
		var normal_stylebox = BackgroundUtils.create_stylebox_from_styles(styles)
		dom_node.add_theme_stylebox_override("panel", normal_stylebox)
		
		if hover_styles.size() > 0:
			BackgroundUtils.setup_panel_hover_support(dom_node, styles, hover_styles)
		else:
			if dom_node.has_meta("normal_stylebox"):
				dom_node.remove_meta("normal_stylebox")
			if dom_node.has_meta("hover_stylebox"):
				dom_node.remove_meta("hover_stylebox")

			if dom_node.mouse_entered.is_connected(BackgroundUtils._on_panel_mouse_entered):
				dom_node.mouse_entered.disconnect(BackgroundUtils._on_panel_mouse_entered)
			if dom_node.mouse_exited.is_connected(BackgroundUtils._on_panel_mouse_exited):
				dom_node.mouse_exited.disconnect(BackgroundUtils._on_panel_mouse_exited)
	
	update_element_text_content(dom_node, element, dom_parser)
