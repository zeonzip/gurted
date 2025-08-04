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

func add_element_methods(vm: LuauVM) -> void:
	vm.lua_pushcallable(_element_set_text_handler, "element.set_text")
	vm.lua_setfield(-2, "set_text")
	
	vm.lua_pushcallable(_element_get_text_handler, "element.get_text")
	vm.lua_setfield(-2, "get_text")
	
	vm.lua_pushcallable(_element_on_event_handler, "element.on")
	vm.lua_setfield(-2, "on")

# Element manipulation handlers
func _element_set_text_handler(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	var text: String = vm.luaL_checkstring(2)
	
	vm.lua_getfield(1, "_element_id")
	var element_id: String = vm.lua_tostring(-1)
	vm.lua_pop(1)
	
	var dom_node = dom_parser.parse_result.dom_nodes.get(element_id, null)
	var text_node = get_dom_node(dom_node, "text")
	if text_node:
		text_node.text = text
	return 0

func _element_get_text_handler(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	
	vm.lua_getfield(1, "_element_id")
	var element_id: String = vm.lua_tostring(-1)
	vm.lua_pop(1)
	
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
