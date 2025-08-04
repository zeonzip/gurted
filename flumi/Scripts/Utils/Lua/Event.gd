class_name LuaEventUtils
extends RefCounted

static func connect_element_event(signal_node: Node, event_name: String, subscription) -> bool:
	if not signal_node:
		return false
	
	match event_name:
		"click":
			if signal_node.has_signal("pressed"):
				signal_node.pressed.connect(subscription.lua_api._on_event_triggered.bind(subscription))
				subscription.connected_signal = "pressed"
				subscription.connected_node = signal_node if signal_node != subscription.lua_api.get_dom_node(signal_node.get_parent(), "signal") else null
				return true
			elif signal_node is Control:
				signal_node.gui_input.connect(subscription.lua_api._on_gui_input_click.bind(subscription))
				subscription.connected_signal = "gui_input"
				subscription.connected_node = signal_node
				return true
		"mousedown", "mouseup":
			if signal_node is Control:
				# Check if we already have a mouse handler connected to this node
				var already_connected = false
				for existing_id in subscription.lua_api.event_subscriptions:
					var existing_sub = subscription.lua_api.event_subscriptions[existing_id]
					if existing_sub.connected_node == signal_node and existing_sub.connected_signal == "gui_input_mouse":
						already_connected = true
						break
				
				if not already_connected:
					signal_node.gui_input.connect(subscription.lua_api._on_gui_input_mouse_universal.bind(signal_node))
				
				subscription.connected_signal = "gui_input_mouse"
				subscription.connected_node = signal_node
				return true
		"mousemove":
			if signal_node is Control:
				signal_node.gui_input.connect(subscription.lua_api._on_gui_input_mousemove.bind(subscription))
				subscription.connected_signal = "gui_input_mousemove"
				subscription.connected_node = signal_node
				return true
		"mouseenter":
			if signal_node is Control and signal_node.has_signal("mouse_entered"):
				signal_node.mouse_entered.connect(subscription.lua_api._on_event_triggered.bind(subscription))
				subscription.connected_signal = "mouse_entered"
				subscription.connected_node = signal_node
				return true
		"mouseexit":
			if signal_node is Control and signal_node.has_signal("mouse_exited"):
				signal_node.mouse_exited.connect(subscription.lua_api._on_event_triggered.bind(subscription))
				subscription.connected_signal = "mouse_exited"
				subscription.connected_node = signal_node
				return true
		"focusin":
			if signal_node is Control:
				signal_node.focus_mode = Control.FOCUS_ALL
				if signal_node.has_signal("focus_entered"):
					signal_node.focus_entered.connect(subscription.lua_api._on_event_triggered.bind(subscription))
					subscription.connected_signal = "focus_entered"
					subscription.connected_node = signal_node
					return true
				else:
					signal_node.gui_input.connect(subscription.lua_api._on_focus_gui_input.bind(subscription))
					subscription.connected_signal = "gui_input_focus"
					subscription.connected_node = signal_node
					return true
		"focusout":
			if signal_node is Control and signal_node.has_signal("focus_exited"):
				signal_node.focus_exited.connect(subscription.lua_api._on_event_triggered.bind(subscription))
				subscription.connected_signal = "focus_exited"
				subscription.connected_node = signal_node
				return true
	
	return false

static func connect_body_event(event_name: String, subscription, lua_api) -> bool:
	match event_name:
		"keydown", "keypress", "keyup":
			lua_api.set_process_input(true)
			subscription.connected_signal = "input"
			subscription.connected_node = lua_api
			return true
		"mousemove":
			lua_api.set_process_input(true)
			subscription.connected_signal = "input_mousemove"
			subscription.connected_node = lua_api
			return true
		"mouseenter", "mouseexit":
			var main_container = lua_api.dom_parser.parse_result.dom_nodes.get("body", null)
			if main_container:
				if event_name == "mouseenter":
					main_container.mouse_entered.connect(lua_api._on_body_mouse_enter.bind(subscription))
					subscription.connected_signal = "mouse_entered"
				elif event_name == "mouseexit":
					main_container.mouse_exited.connect(lua_api._on_body_mouse_exit.bind(subscription))
					subscription.connected_signal = "mouse_exited"
				subscription.connected_node = main_container
				return true
		"focusin", "focusout":
			subscription.connected_signal = "focus_events"
			subscription.connected_node = lua_api
			return true
	
	return false

static func _count_active_input_subscriptions(lua_api) -> int:
	var count = 0
	for sub_id in lua_api.event_subscriptions:
		var sub = lua_api.event_subscriptions[sub_id]
		if sub.connected_signal in ["input", "input_mousemove"]:
			count += 1
	return count

static func disconnect_subscription(subscription, lua_api) -> void:
	var target_node = subscription.connected_node if subscription.connected_node else lua_api.dom_parser.parse_result.dom_nodes.get(subscription.element_id, null)
	
	if target_node and subscription.connected_signal:
		match subscription.connected_signal:
			"pressed":
				if target_node.has_signal("pressed"):
					target_node.pressed.disconnect(lua_api._on_event_triggered.bind(subscription))
			"gui_input":
				if target_node.has_signal("gui_input"):
					target_node.gui_input.disconnect(lua_api._on_gui_input_click.bind(subscription))
			"gui_input_mouse":
				if target_node.has_signal("gui_input"):
					target_node.gui_input.disconnect(lua_api._on_gui_input_mouse_universal.bind(target_node))
			"gui_input_mousemove":
				if target_node.has_signal("gui_input"):
					target_node.gui_input.disconnect(lua_api._on_gui_input_mousemove.bind(subscription))
			"gui_input_focus":
				if target_node.has_signal("gui_input"):
					target_node.gui_input.disconnect(lua_api._on_focus_gui_input.bind(subscription))
			"mouse_entered":
				if target_node.has_signal("mouse_entered"):
					# Check if this is a body event or element event
					if subscription.element_id == "body":
						target_node.mouse_entered.disconnect(lua_api._on_body_mouse_enter.bind(subscription))
					else:
						target_node.mouse_entered.disconnect(lua_api._on_event_triggered.bind(subscription))
			"mouse_exited":
				if target_node.has_signal("mouse_exited"):
					# Check if this is a body event or element event
					if subscription.element_id == "body":
						target_node.mouse_exited.disconnect(lua_api._on_body_mouse_exit.bind(subscription))
					else:
						target_node.mouse_exited.disconnect(lua_api._on_event_triggered.bind(subscription))
			"focus_entered":
				if target_node.has_signal("focus_entered"):
					target_node.focus_entered.disconnect(lua_api._on_event_triggered.bind(subscription))
			"focus_exited":
				if target_node.has_signal("focus_exited"):
					target_node.focus_exited.disconnect(lua_api._on_event_triggered.bind(subscription))
			"input":
				# Only disable input processing if no other input subscriptions remain
				if _count_active_input_subscriptions(lua_api) <= 1:
					lua_api.set_process_input(false)
			"input_mousemove":
				# Only disable input processing if no other input subscriptions remain
				if _count_active_input_subscriptions(lua_api) <= 1:
					lua_api.set_process_input(false)
