class_name LuaAPI
extends Node

class EventSubscription:
	var id: int
	var element_id: String
	var event_name: String
	var callback_ref: int
	var vm: LuauVM
	var lua_api: LuaAPI
	var connected_signal: String = ""
	var connected_node: Node = null

var dom_parser: HTMLParser
var event_subscriptions: Dictionary = {}
var next_subscription_id: int = 1
var next_callback_ref: int = 1

var timeout_manager: LuaTimeoutManager
var element_id_counter: int = 1
var element_id_registry: Dictionary = {}

func _init():
	timeout_manager = LuaTimeoutManager.new()

func get_or_assign_element_id(element: HTMLParser.HTMLElement) -> String:
	var existing_id = element.get_attribute("id")
	if not existing_id.is_empty():
		element_id_registry[element] = existing_id
		return existing_id
	
	if element_id_registry.has(element):
		return element_id_registry[element]
	
	var new_id = "auto_" + str(element_id_counter)
	element_id_counter += 1
	
	element.set_attribute("id", new_id)
	element_id_registry[element] = new_id
	
	return new_id

func _gurt_select_handler(vm: LuauVM) -> int:
	var selector: String = vm.luaL_checkstring(1)
	
	var element_id = ""
	if selector.begins_with("#"):
		element_id = selector.substr(1)
	else:
		vm.lua_pushnil()
		return 1
	
	var dom_node = dom_parser.parse_result.dom_nodes.get(element_id, null)
	if not dom_node:
		vm.lua_pushnil()
		return 1
	
	vm.lua_newtable()
	vm.lua_pushstring(element_id)
	vm.lua_setfield(-2, "_element_id")
	
	add_element_methods(vm)
	return 1

# selectAll() function to find multiple elements
func _gurt_select_all_handler(vm: LuauVM) -> int:
	var selector: String = vm.luaL_checkstring(1)
	
	var elements: Array[HTMLParser.HTMLElement] = []
	 
	# Handle different selector types
	if selector.begins_with("#"):
		# ID selector - find single element
		var element_id = selector.substr(1)
		var element = dom_parser.find_by_id(element_id)
		if element:
			elements.append(element)
			LuaPrintUtils.lua_print_direct("WARNING: Using ID selector in select_all is not recommended, use select instead.")
	elif selector.begins_with("."):
		# Class selector - find all elements with class
		var cls = selector.substr(1)
		for element in dom_parser.parse_result.all_elements:
			var element_classes = CSSParser.smart_split_utility_classes(element.get_attribute("style"))
			if cls in element_classes:
				elements.append(element)
	else:
		# Tag selector - find all elements with tag name
		elements = dom_parser.find_all(selector)
	
	vm.lua_newtable()
	var index = 1
	
	for element in elements:
		var element_id = get_or_assign_element_id(element)
		
		# Create element wrapper
		vm.lua_newtable()
		vm.lua_pushstring(element_id)
		vm.lua_setfield(-2, "_element_id")
		vm.lua_pushstring(element.tag_name)
		vm.lua_setfield(-2, "_tag_name")
		
		add_element_methods(vm)
		
		# Add to array at index
		vm.lua_rawseti(-2, index)
		index += 1
	
	return 1

# create() function to create HTML element
func _gurt_create_handler(vm: LuauVM) -> int:
	var tag_name: String = vm.luaL_checkstring(1)
	var options: Dictionary = {}
	
	if vm.lua_gettop() >= 2 and vm.lua_istable(2):
		options = vm.lua_todictionary(2)
	
	var element = HTMLParser.HTMLElement.new(tag_name)
	
	# Apply options as attributes and content
	for key in options:
		if key == "text":
			element.text_content = str(options[key])
		else:
			element.attributes[str(key)] = str(options[key])
	
	# Add to parser's element collection first
	dom_parser.parse_result.all_elements.append(element)
	
	# Get or assign stable ID
	var unique_id = get_or_assign_element_id(element)
	
	# Create Lua element wrapper with methods
	vm.lua_newtable()
	vm.lua_pushstring(unique_id)
	vm.lua_setfield(-2, "_element_id")
	vm.lua_pushstring(tag_name)
	vm.lua_setfield(-2, "_tag_name")
	vm.lua_pushboolean(true)
	vm.lua_setfield(-2, "_is_dynamic")
	
	add_element_methods(vm)
	return 1

func add_element_methods(vm: LuauVM, index: String = "element") -> void:
	# Add methods directly to element table first
	vm.lua_pushcallable(_element_on_event_handler, index + ".on")
	vm.lua_setfield(-2, "on")
	
	vm.lua_pushcallable(_element_append_handler, index + ".append")
	vm.lua_setfield(-2, "append")
	
	vm.lua_pushcallable(_element_remove_handler, index + ".remove")
	vm.lua_setfield(-2, "remove")
	
	vm.lua_pushcallable(_element_get_attribute_handler, index + ".getAttribute")
	vm.lua_setfield(-2, "getAttribute")
	
	vm.lua_pushcallable(_element_set_attribute_handler, index + ".setAttribute")
	vm.lua_setfield(-2, "setAttribute")
	
	# Create metatable for property access
	vm.lua_newtable() # metatable
	
	# __index method for property getters
	vm.lua_pushcallable(_element_index_handler, index + ".__index")
	vm.lua_setfield(-2, "__index")
	
	# __newindex method for property setters
	vm.lua_pushcallable(_element_newindex_handler, index + ".__newindex")
	vm.lua_setfield(-2, "__newindex")
	
	# Set metatable on element table
	vm.lua_setmetatable(-2)

# Property access handlers
func _element_index_handler(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	var key: String = vm.luaL_checkstring(2)
	
	vm.lua_getfield(1, "_element_id")
	var element_id: String = vm.lua_tostring(-1)
	vm.lua_pop(1)
	
	match key:
		"text":
			var dom_node = dom_parser.parse_result.dom_nodes.get(element_id, null)
			var text = ""
			
			var text_node = get_dom_node(dom_node, "text")
			if text_node:
				if text_node.has_method("get_text"):
					text = text_node.get_text()
				else:
					text = text_node.text
			
			vm.lua_pushstring(text)
			return 1
		"children":
			# Find the element
			var element: HTMLParser.HTMLElement = null
			if element_id == "body":
				element = dom_parser.find_first("body")
			else:
				element = dom_parser.find_by_id(element_id)
			
			vm.lua_newtable()
			var index = 1
			
			if element:
				for child in element.children:
					vm.lua_newtable()
					vm.lua_pushstring(child.tag_name)
					vm.lua_setfield(-2, "tagName")
					vm.lua_pushstring(child.get_text_content())
					vm.lua_setfield(-2, "text")
					
					vm.lua_rawseti(-2, index)
					index += 1
			
			return 1
		"classList":
			# Create classList object with add, remove, toggle methods
			vm.lua_newtable()
			
			# Add methods to classList using the utility class
			vm.lua_pushcallable(_element_classlist_add_wrapper, "classList.add")
			vm.lua_setfield(-2, "add")
			
			vm.lua_pushcallable(_element_classlist_remove_wrapper, "classList.remove")
			vm.lua_setfield(-2, "remove")
			
			vm.lua_pushcallable(_element_classlist_toggle_wrapper, "classList.toggle")
			vm.lua_setfield(-2, "toggle")
			
			# Store element reference for the classList methods
			vm.lua_getfield(1, "_element_id")
			vm.lua_setfield(-2, "_element_id")
			
			return 1
		_:
			# Fall back to checking the original table for methods
			vm.lua_pushvalue(1) # Push the original table
			vm.lua_pushstring(key) # Push the key
			vm.lua_rawget(-2) # Get table[key] without triggering metamethods
			vm.lua_remove(-2) # Remove the table, leaving just the result
			return 1

func _element_newindex_handler(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	var key: String = vm.luaL_checkstring(2)
	var value = vm.lua_tovariant(3)
	
	vm.lua_getfield(1, "_element_id")
	var element_id: String = vm.lua_tostring(-1)
	vm.lua_pop(1)
	
	match key:
		"text":
			var text: String = str(value)
			var dom_node = dom_parser.parse_result.dom_nodes.get(element_id, null)
			var text_node = get_dom_node(dom_node, "text")
			if text_node:
				text_node.text = text
		_:
			# Ignore unknown properties
			pass
	
	return 0

# append() function to add a child element
func _element_append_handler(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	vm.luaL_checktype(2, vm.LUA_TTABLE)
	
	# Get parent element info
	vm.lua_getfield(1, "_element_id")
	var parent_element_id: String = vm.lua_tostring(-1)
	vm.lua_pop(1)
	
	# Get child element info
	vm.lua_getfield(2, "_element_id")
	var child_element_id: String = vm.lua_tostring(-1)
	vm.lua_pop(1)
	
	vm.lua_getfield(2, "_is_dynamic")
	vm.lua_pop(1)
	
	# Find parent element
	var parent_element: HTMLParser.HTMLElement = null
	if parent_element_id == "body":
		parent_element = dom_parser.find_first("body")
	else:
		parent_element = dom_parser.find_by_id(parent_element_id)
	
	if not parent_element:
		return 0
	
	# Find child element
	var child_element = dom_parser.find_by_id(child_element_id)
	if not child_element:
		return 0
	
	# Add child to parent in DOM tree
	child_element.parent = parent_element
	parent_element.children.append(child_element)
	
	# If the parent is already rendered, we need to create and add the visual node
	var parent_dom_node: Node = null
	if parent_element_id == "body":
		var main_scene = get_node("/root/Main")
		if main_scene:
			parent_dom_node = main_scene.website_container
	else:
		parent_dom_node = dom_parser.parse_result.dom_nodes.get(parent_element_id, null)
	
	if parent_dom_node:
		_render_new_element.call_deferred(child_element, parent_dom_node)
	
	return 0

# remove() function to remove an element
func _element_remove_handler(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	
	vm.lua_getfield(1, "_element_id")
	var element_id: String = vm.lua_tostring(-1)
	vm.lua_pop(1)
	
	# Find the element in DOM
	var element = dom_parser.find_by_id(element_id)
	if not element:
		return 0

	# Remove from parent's children array
	if element.parent:
		var parent_children = element.parent.children
		var idx = parent_children.find(element)
		if idx >= 0:
			parent_children.remove_at(idx)

	# Remove the visual node
	var dom_node = dom_parser.parse_result.dom_nodes.get(element_id, null)
	if dom_node:
		dom_node.queue_free()
		dom_parser.parse_result.dom_nodes.erase(element_id)

	# Remove from all_elements array
	var all_elements = dom_parser.parse_result.all_elements
	var index = all_elements.find(element)
	if index >= 0:
		all_elements.remove_at(index)

	# Remove from element_id_registry to avoid memory leaks
	if element_id_registry.has(element):
		element_id_registry.erase(element)

	return 0

# getAttribute() function to get element attribute
func _element_get_attribute_handler(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	var attribute_name: String = vm.luaL_checkstring(2)
	
	vm.lua_getfield(1, "_element_id")
	var element_id: String = vm.lua_tostring(-1)
	vm.lua_pop(1)
	
	# Find the element
	var element: HTMLParser.HTMLElement = null
	if element_id == "body":
		element = dom_parser.find_first("body")
	else:
		element = dom_parser.find_by_id(element_id)
	
	if not element:
		vm.lua_pushnil()
		return 1
	
	# Get the attribute value
	var attribute_value = element.get_attribute(attribute_name)
	if attribute_value.is_empty():
		vm.lua_pushnil()
	else:
		vm.lua_pushstring(attribute_value)
	
	return 1

# setAttribute() function to set element attribute
func _element_set_attribute_handler(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	var attribute_name: String = vm.luaL_checkstring(2)
	var attribute_value: String = vm.luaL_checkstring(3)
	
	vm.lua_getfield(1, "_element_id")
	var element_id: String = vm.lua_tostring(-1)
	vm.lua_pop(1)
	
	# Find the element
	var element: HTMLParser.HTMLElement = null
	if element_id == "body":
		element = dom_parser.find_first("body")
	else:
		element = dom_parser.find_by_id(element_id)
	
	if not element:
		return 0
	
	if attribute_value == "":
		element.attributes.erase(attribute_name)
	else:
		element.set_attribute(attribute_name, attribute_value)
	
	# Trigger visual update by calling init() again
	var dom_node = dom_parser.parse_result.dom_nodes.get(element_id, null)
	if dom_node and dom_node.has_method("init"):
		dom_node.init(element, dom_parser)
	
	return 0

func _element_classlist_add_wrapper(vm: LuauVM) -> int:
	return LuaClassListUtils.element_classlist_add_handler(vm, dom_parser)

func _element_classlist_remove_wrapper(vm: LuauVM) -> int:
	return LuaClassListUtils.element_classlist_remove_handler(vm, dom_parser)

func _element_classlist_toggle_wrapper(vm: LuauVM) -> int:
	return LuaClassListUtils.element_classlist_toggle_handler(vm, dom_parser)

func _render_new_element(element: HTMLParser.HTMLElement, parent_node: Node) -> void:
	# Get reference to main scene for rendering
	var main_scene = get_node("/root/Main")
	if not main_scene:
		return
	
	# Create the visual node for the element
	var element_node = await main_scene.create_element_node(element, dom_parser)
	if not element_node:
		LuaPrintUtils.lua_print_direct("Failed to create visual node for element: " + str(element))
		return

	# Set metadata so ul/ol can detect dynamically added li elements
	element_node.set_meta("html_element", element)

	# Register the DOM node
	dom_parser.register_dom_node(element, element_node)

	# Add to parent - handle body special case
	var container_node = parent_node
	if parent_node is MarginContainer and parent_node.get_child_count() > 0:
		container_node = parent_node.get_child(0)
	elif parent_node == main_scene.website_container:
		container_node = parent_node

	main_scene.safe_add_child(container_node, element_node)

# Timeout management handlers
func _gurt_set_timeout_handler(vm: LuauVM) -> int:
	return timeout_manager.set_timeout_handler(vm, self)

func _gurt_clear_timeout_handler(vm: LuauVM) -> int:
	return timeout_manager.clear_timeout_handler(vm)

# Event system handlers
func _element_on_event_handler(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	var event_name: String = vm.luaL_checkstring(2)
	vm.luaL_checktype(3, vm.LUA_TFUNCTION)
	
	vm.lua_getfield(1, "_element_id")
	var element_id: String = vm.lua_tostring(-1)
	vm.lua_pop(1)
	
	var dom_node = dom_parser.parse_result.dom_nodes.get(element_id, null)
	if not dom_node:
		vm.lua_pushnil()
		return 1
	
	var subscription = _create_subscription(vm, element_id, event_name)
	event_subscriptions[subscription.id] = subscription
	
	var signal_node = get_dom_node(dom_node, "signal")
	var success = LuaEventUtils.connect_element_event(signal_node, event_name, subscription)
	
	return _handle_subscription_result(vm, subscription, success)

func _body_on_event_handler(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	var event_name: String = vm.luaL_checkstring(2)
	vm.luaL_checktype(3, vm.LUA_TFUNCTION)
	
	var subscription = _create_subscription(vm, "body", event_name)
	event_subscriptions[subscription.id] = subscription
	
	var success = LuaEventUtils.connect_body_event(event_name, subscription, self)
	
	return _handle_subscription_result(vm, subscription, success)

func _subscription_unsubscribe_handler(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	
	vm.lua_getfield(1, "_subscription_id")
	var subscription_id: int = vm.lua_tointeger(-1)
	vm.lua_pop(1)
	
	var subscription = event_subscriptions.get(subscription_id, null)
	if subscription:
		LuaEventUtils.disconnect_subscription(subscription, self)
		event_subscriptions.erase(subscription_id)
		vm.lua_pushnil()
		vm.lua_rawseti(vm.LUA_REGISTRYINDEX, subscription.callback_ref)
	
	return 0

# Subscription management
func _create_subscription(vm: LuauVM, element_id: String, event_name: String) -> EventSubscription:
	var subscription_id = next_subscription_id
	next_subscription_id += 1
	var callback_ref = next_callback_ref
	next_callback_ref += 1
	
	vm.lua_pushvalue(3)
	vm.lua_rawseti(vm.LUA_REGISTRYINDEX, callback_ref)
	
	var subscription = EventSubscription.new()
	subscription.id = subscription_id
	subscription.element_id = element_id
	subscription.event_name = event_name
	subscription.callback_ref = callback_ref
	subscription.vm = vm
	subscription.lua_api = self
	
	return subscription

func _handle_subscription_result(vm: LuauVM, subscription: EventSubscription, success: bool) -> int:
	if success:
		vm.lua_newtable()
		vm.lua_pushinteger(subscription.id)
		vm.lua_setfield(-2, "_subscription_id")
		
		vm.lua_pushcallable(_subscription_unsubscribe_handler, "subscription.unsubscribe")
		vm.lua_setfield(-2, "unsubscribe")
		
		return 1
	else:
		vm.lua_pushnil()
		vm.lua_rawseti(vm.LUA_REGISTRYINDEX, subscription.callback_ref)
		event_subscriptions.erase(subscription.id)
		vm.lua_pushnil()
		return 1

# Event callbacks
func _on_event_triggered(subscription: EventSubscription) -> void:
	if not event_subscriptions.has(subscription.id):
		return
	
	subscription.vm.lua_rawgeti(subscription.vm.LUA_REGISTRYINDEX, subscription.callback_ref)
	if subscription.vm.lua_isfunction(-1):
		if subscription.vm.lua_pcall(0, 0, 0) != subscription.vm.LUA_OK:
			print("GURT ERROR in event callback: ", subscription.vm.lua_tostring(-1))
			subscription.vm.lua_pop(1)
	else:
		subscription.vm.lua_pop(1)

func _on_gui_input_click(event: InputEvent, subscription: EventSubscription) -> void:
	if not event_subscriptions.has(subscription.id):
		return
	
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_execute_lua_callback(subscription)

func _on_gui_input_mouse_universal(event: InputEvent, signal_node: Node) -> void:
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			# Find all subscriptions for this node with mouse events
			for subscription_id in event_subscriptions:
				var subscription = event_subscriptions[subscription_id]
				if subscription.connected_node == signal_node and subscription.connected_signal == "gui_input_mouse":
					var should_trigger = false
					if subscription.event_name == "mousedown" and mouse_event.pressed:
						should_trigger = true
					elif subscription.event_name == "mouseup" and not mouse_event.pressed:
						should_trigger = true
					
					if should_trigger:
						_execute_lua_callback(subscription)

# Event callback handlers
func _on_gui_input_mousemove(event: InputEvent, subscription: EventSubscription) -> void:
	if not event_subscriptions.has(subscription.id):
		return
	
	if event is InputEventMouseMotion:
		var mouse_event = event as InputEventMouseMotion
		_handle_mousemove_event(mouse_event, subscription)

func _on_focus_gui_input(event: InputEvent, subscription: EventSubscription) -> void:
	if not event_subscriptions.has(subscription.id):
		return
	
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			if subscription.event_name == "focusin":
				_execute_lua_callback(subscription)

func _on_body_mouse_enter(subscription: EventSubscription) -> void:
	if not event_subscriptions.has(subscription.id):
		return
	
	if subscription.event_name == "mouseenter":
		_execute_lua_callback(subscription)

func _on_body_mouse_exit(subscription: EventSubscription) -> void:
	if not event_subscriptions.has(subscription.id):
		return
	
	if subscription.event_name == "mouseexit":
		_execute_lua_callback(subscription)

func _execute_lua_callback(subscription: EventSubscription, args: Array = []) -> void:
	subscription.vm.lua_rawgeti(subscription.vm.LUA_REGISTRYINDEX, subscription.callback_ref)
	if subscription.vm.lua_isfunction(-1):
		for arg in args:
			subscription.vm.lua_pushvariant(arg)
		
		if subscription.vm.lua_pcall(args.size(), 0, 0) != subscription.vm.LUA_OK:
			print("GURT ERROR in callback: ", subscription.vm.lua_tostring(-1))
			subscription.vm.lua_pop(1)
	else:
		subscription.vm.lua_pop(1)

# Global input processing
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event = event as InputEventKey
		for subscription_id in event_subscriptions:
			var subscription = event_subscriptions[subscription_id]
			if subscription.element_id == "body" and subscription.connected_signal == "input":
				var should_trigger = false
				match subscription.event_name:
					"keydown":
						should_trigger = key_event.pressed
					"keyup": 
						should_trigger = not key_event.pressed
					"keypress":
						should_trigger = key_event.pressed
				
				if should_trigger:
					var key_info = {
						"key": OS.get_keycode_string(key_event.keycode),
						"keycode": key_event.keycode,
						"ctrl": key_event.ctrl_pressed,
						"shift": key_event.shift_pressed,
						"alt": key_event.alt_pressed
					}
					_execute_lua_callback(subscription, [key_info])
	
	elif event is InputEventMouseMotion:
		var mouse_event = event as InputEventMouseMotion
		for subscription_id in event_subscriptions:
			var subscription = event_subscriptions[subscription_id]
			if subscription.element_id == "body" and subscription.connected_signal == "input_mousemove":
				if subscription.event_name == "mousemove":
					_handle_mousemove_event(mouse_event, subscription)

func _handle_mousemove_event(mouse_event: InputEventMouseMotion, subscription: EventSubscription) -> void:
	# TODO: pass reference instead of hardcoded path
	var body_container = get_node("/root/Main").website_container

	if body_container.get_parent() is MarginContainer:
		body_container = body_container.get_parent()
	
	if not body_container:
		return
	
	var container_rect = body_container.get_global_rect()
	var local_x = mouse_event.global_position.x - container_rect.position.x
	var local_y = mouse_event.global_position.y - container_rect.position.y
	
	# Only provide coordinates if mouse is within the container bounds
	if local_x >= 0 and local_y >= 0 and local_x <= container_rect.size.x and local_y <= container_rect.size.y:
		var mouse_info = {
			"x": local_x,
			"y": local_y,
			"deltaX": mouse_event.relative.x,
			"deltaY": mouse_event.relative.y
		}
		_execute_lua_callback(subscription, [mouse_info])

# DOM node utilities
func get_dom_node(node: Node, purpose: String = "general") -> Node:
	if not node:
		return null
	
	if node is MarginContainer: 
		node = node.get_child(0)
	
	match purpose:
		"signal":
			if node is HTMLButton:
				return node.get_node_or_null("ButtonNode")
			elif node is RichTextLabel:
				return node
			elif node.has_method("get") and node.get("rich_text_label"):
				return node.get("rich_text_label")
			elif node.get_node_or_null("RichTextLabel"):
				return node.get_node_or_null("RichTextLabel")
			else:
				return node
		"text":
			if node.has_method("set_text") and node.has_method("get_text"):
				return node
			elif node is RichTextLabel:
				return node
			elif node.has_method("get") and node.get("rich_text_label"):
				return node.get("rich_text_label")
			elif node.get_node_or_null("RichTextLabel"):
				return node.get_node_or_null("RichTextLabel")
			else:
				if "text" in node:
					return node
				return null
		"general":
			if node is HTMLButton:
				return node.get_node_or_null("ButtonNode")
			elif node is RichTextLabel:
				return node
			elif node.get_node_or_null("RichTextLabel"):
				return node.get_node_or_null("RichTextLabel")
			else:
				return node
	
	return node

# Main execution function
func execute_lua_script(code: String, vm: LuauVM):
	vm.open_libraries([vm.LUA_BASE_LIB, vm.LUA_BIT32_LIB,
			vm.LUA_COROUTINE_LIB, vm.LUA_MATH_LIB, vm.LUA_UTF8_LIB,
			vm.LUA_TABLE_LIB, vm.LUA_STRING_LIB, vm.LUA_VECTOR_LIB])
	
	LuaFunctionUtils.setup_gurt_api(vm, self, dom_parser)
	
	if vm.lua_dostring(code) != vm.LUA_OK:
		print("LUA ERROR: ", vm.lua_tostring(-1))
		vm.lua_pop(1)
