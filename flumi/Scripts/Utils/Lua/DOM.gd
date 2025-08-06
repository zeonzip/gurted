class_name LuaDOMUtils
extends RefCounted

# DOM traversal properties (read-only)
static func get_element_parent_handler(vm: LuauVM, dom_parser: HTMLParser, lua_api: LuaAPI) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	
	vm.lua_getfield(1, "_element_id")
	var element_id: String = vm.lua_tostring(-1)
	vm.lua_pop(1)
	
	var element = find_element_by_id(element_id, dom_parser)
	if not element or not element.parent:
		vm.lua_pushnil()
		return 1
	
	create_element_wrapper(vm, element.parent, lua_api)
	return 1

static func get_element_next_sibling_handler(vm: LuauVM, dom_parser: HTMLParser, lua_api: LuaAPI) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	
	vm.lua_getfield(1, "_element_id")
	var element_id: String = vm.lua_tostring(-1)
	vm.lua_pop(1)
	
	var element = find_element_by_id(element_id, dom_parser)
	if not element or not element.parent:
		vm.lua_pushnil()
		return 1
	
	var siblings = element.parent.children
	var current_index = siblings.find(element)
	
	if current_index >= 0 and current_index < siblings.size() - 1:
		var next_sibling = siblings[current_index + 1]
		create_element_wrapper(vm, next_sibling, lua_api)
	else:
		vm.lua_pushnil()
	
	return 1

static func get_element_previous_sibling_handler(vm: LuauVM, dom_parser: HTMLParser, lua_api: LuaAPI) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	
	vm.lua_getfield(1, "_element_id")
	var element_id: String = vm.lua_tostring(-1)
	vm.lua_pop(1)
	
	var element = find_element_by_id(element_id, dom_parser)
	if not element or not element.parent:
		vm.lua_pushnil()
		return 1
	
	var siblings = element.parent.children
	var current_index = siblings.find(element)
	
	if current_index > 0:
		var prev_sibling = siblings[current_index - 1]
		create_element_wrapper(vm, prev_sibling, lua_api)
	else:
		vm.lua_pushnil()
	
	return 1

static func get_element_first_child_handler(vm: LuauVM, dom_parser: HTMLParser, lua_api: LuaAPI) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	
	vm.lua_getfield(1, "_element_id")
	var element_id: String = vm.lua_tostring(-1)
	vm.lua_pop(1)
	
	var element = find_element_by_id(element_id, dom_parser)
	if not element or element.children.is_empty():
		vm.lua_pushnil()
		return 1
	
	create_element_wrapper(vm, element.children[0], lua_api)
	return 1

static func get_element_last_child_handler(vm: LuauVM, dom_parser: HTMLParser, lua_api: LuaAPI) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	
	vm.lua_getfield(1, "_element_id")
	var element_id: String = vm.lua_tostring(-1)
	vm.lua_pop(1)
	
	var element = find_element_by_id(element_id, dom_parser)
	if not element or element.children.is_empty():
		vm.lua_pushnil()
		return 1
	
	create_element_wrapper(vm, element.children[-1], lua_api)
	return 1

# DOM Manipulation Methods
static func insert_before_handler(vm: LuauVM, dom_parser: HTMLParser, lua_api) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE) # parent
	vm.luaL_checktype(2, vm.LUA_TTABLE) # new_child
	vm.luaL_checktype(3, vm.LUA_TTABLE) # reference_child
	
	# Get parent element info
	vm.lua_getfield(1, "_element_id")
	var parent_element_id: String = vm.lua_tostring(-1)
	vm.lua_pop(1)
	
	# Get new child element info
	vm.lua_getfield(2, "_element_id")
	var new_child_element_id: String = vm.lua_tostring(-1)
	vm.lua_pop(1)
	
	# Get reference child element info
	vm.lua_getfield(3, "_element_id")
	var reference_child_element_id: String = vm.lua_tostring(-1)
	vm.lua_pop(1)
	
	# Find elements
	var parent_element = find_element_by_id(parent_element_id, dom_parser)
	var new_child_element = find_element_by_id(new_child_element_id, dom_parser)
	var reference_child_element = find_element_by_id(reference_child_element_id, dom_parser)
	
	if not parent_element or not new_child_element or not reference_child_element:
		vm.lua_pushnil()
		return 1
	
	# Find reference child index in parent's children
	var reference_index = parent_element.children.find(reference_child_element)
	if reference_index < 0:
		vm.lua_pushnil()
		return 1
	
	# Remove new child from its current parent if it has one
	if new_child_element.parent:
		var current_parent = new_child_element.parent
		var current_index = current_parent.children.find(new_child_element)
		if current_index >= 0:
			current_parent.children.remove_at(current_index)
	
	# Insert new child before reference child
	new_child_element.parent = parent_element
	parent_element.children.insert(reference_index, new_child_element)
	
	# Handle visual rendering if parent is already rendered
	handle_visual_insertion_by_reference(parent_element_id, new_child_element, reference_child_element_id, true, dom_parser, lua_api)
	
	# Return the new child
	vm.lua_pushvalue(2)
	return 1

static func insert_after_handler(vm: LuauVM, dom_parser: HTMLParser, lua_api) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE) # parent
	vm.luaL_checktype(2, vm.LUA_TTABLE) # new_child
	vm.luaL_checktype(3, vm.LUA_TTABLE) # reference_child
	
	# Get parent element info
	vm.lua_getfield(1, "_element_id")
	var parent_element_id: String = vm.lua_tostring(-1)
	vm.lua_pop(1)
	
	# Get new child element info
	vm.lua_getfield(2, "_element_id")
	var new_child_element_id: String = vm.lua_tostring(-1)
	vm.lua_pop(1)
	
	# Get reference child element info
	vm.lua_getfield(3, "_element_id")
	var reference_child_element_id: String = vm.lua_tostring(-1)
	vm.lua_pop(1)
	
	# Find elements
	var parent_element = find_element_by_id(parent_element_id, dom_parser)
	var new_child_element = find_element_by_id(new_child_element_id, dom_parser)
	var reference_child_element = find_element_by_id(reference_child_element_id, dom_parser)
	
	if not parent_element or not new_child_element or not reference_child_element:
		vm.lua_pushnil()
		return 1
	
	# Find reference child index in parent's children
	var reference_index = parent_element.children.find(reference_child_element)
	if reference_index < 0:
		vm.lua_pushnil()
		return 1
	
	# Remove new child from its current parent if it has one
	if new_child_element.parent:
		var current_parent = new_child_element.parent
		var current_index = current_parent.children.find(new_child_element)
		if current_index >= 0:
			current_parent.children.remove_at(current_index)
	
	# Insert new child after reference child
	new_child_element.parent = parent_element
	parent_element.children.insert(reference_index + 1, new_child_element)
	
	# Handle visual rendering if parent is already rendered
	handle_visual_insertion_by_reference(parent_element_id, new_child_element, reference_child_element_id, false, dom_parser, lua_api)
	
	# Return the new child
	vm.lua_pushvalue(2)
	return 1

static func replace_handler(vm: LuauVM, dom_parser: HTMLParser, lua_api) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE) # parent
	vm.luaL_checktype(2, vm.LUA_TTABLE) # new_child
	vm.luaL_checktype(3, vm.LUA_TTABLE) # old_child
	
	# Get parent element info
	vm.lua_getfield(1, "_element_id")
	var parent_element_id: String = vm.lua_tostring(-1)
	vm.lua_pop(1)
	
	# Get new child element info
	vm.lua_getfield(2, "_element_id")
	var new_child_element_id: String = vm.lua_tostring(-1)
	vm.lua_pop(1)
	
	# Get old child element info
	vm.lua_getfield(3, "_element_id")
	var old_child_element_id: String = vm.lua_tostring(-1)
	vm.lua_pop(1)
	
	# Find elements
	var parent_element = find_element_by_id(parent_element_id, dom_parser)
	var new_child_element = find_element_by_id(new_child_element_id, dom_parser)
	var old_child_element = find_element_by_id(old_child_element_id, dom_parser)
	
	if not parent_element or not new_child_element or not old_child_element:
		vm.lua_pushnil()
		return 1
	
	# Find old child index in parent's children
	var old_index = parent_element.children.find(old_child_element)
	if old_index < 0:
		vm.lua_pushnil()
		return 1
	
	# Remove new child from its current parent if it has one
	if new_child_element.parent:
		var current_parent = new_child_element.parent
		var current_index = current_parent.children.find(new_child_element)
		if current_index >= 0:
			current_parent.children.remove_at(current_index)
	
	# Replace old child with new child
	old_child_element.parent = null
	new_child_element.parent = parent_element
	parent_element.children[old_index] = new_child_element
	
	# Handle visual updates
	handle_visual_replacement(old_child_element_id, new_child_element, parent_element_id, dom_parser, lua_api)
	
	# Return the old child
	vm.lua_pushvalue(3)
	return 1

static func clone_handler(vm: LuauVM, dom_parser: HTMLParser, lua_api) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE) # element to clone
	var deep: bool = false
	
	if vm.lua_gettop() >= 2:
		deep = vm.lua_toboolean(2)
	
	# Get element info
	vm.lua_getfield(1, "_element_id")
	var element_id: String = vm.lua_tostring(-1)
	vm.lua_pop(1)
	
	# Find the element
	var element = find_element_by_id(element_id, dom_parser)
	if not element:
		vm.lua_pushnil()
		return 1
	
	# Clone the element
	var cloned_element = clone_element(element, deep)
	
	# Add cloned element to parser's element collection
	dom_parser.parse_result.all_elements.append(cloned_element)
	
	# Create Lua element wrapper with full functionality
	create_element_wrapper(vm, cloned_element, lua_api)
	
	return 1

# Helper functions
static func find_element_by_id(element_id: String, dom_parser: HTMLParser) -> HTMLParser.HTMLElement:
	if element_id == "body":
		return dom_parser.find_first("body")
	else:
		return dom_parser.find_by_id(element_id)

static func create_element_wrapper(vm: LuauVM, element: HTMLParser.HTMLElement, lua_api: LuaAPI) -> void:
	vm.lua_newtable()
	
	var element_id: String
	if element.tag_name == "body":
		element_id = "body"
	else:
		element_id = element.get_attribute("id")
		if element_id.is_empty():
			element_id = lua_api.get_or_assign_element_id(element)
			element.set_attribute("id", element_id)
	
	vm.lua_pushstring(element_id)
	vm.lua_setfield(-2, "_element_id")
	vm.lua_pushstring(element.tag_name)
	vm.lua_setfield(-2, "_tag_name")
	
	if lua_api:
		lua_api.add_element_methods(vm)

static func clone_element(element: HTMLParser.HTMLElement, deep: bool) -> HTMLParser.HTMLElement:
	var cloned = HTMLParser.HTMLElement.new(element.tag_name)
	
	for attr_name in element.attributes:
		if attr_name != "id":
			cloned.attributes[attr_name] = element.attributes[attr_name]
	
	cloned.text_content = element.text_content
	
	if deep:
		for child in element.children:
			var cloned_child = clone_element(child, true)
			cloned_child.parent = cloned
			cloned.children.append(cloned_child)
	
	return cloned


static func handle_visual_insertion_by_reference(parent_element_id: String, new_child_element: HTMLParser.HTMLElement, reference_element_id: String, insert_before: bool, dom_parser: HTMLParser, lua_api) -> void:
	var parent_dom_node: Node = null
	if parent_element_id == "body":
		var main_scene = lua_api.get_node("/root/Main")
		if main_scene:
			parent_dom_node = main_scene.website_container
	else:
		parent_dom_node = dom_parser.parse_result.dom_nodes.get(parent_element_id, null)
	
	if parent_dom_node:
		render_new_element_by_reference.call_deferred(new_child_element, parent_dom_node, reference_element_id, insert_before, dom_parser)

static func handle_visual_replacement(old_child_element_id: String, new_child_element: HTMLParser.HTMLElement, parent_element_id: String, dom_parser: HTMLParser, lua_api) -> void:
	var old_dom_node = dom_parser.parse_result.dom_nodes.get(old_child_element_id, null)
	if not old_dom_node:
		return
	
	var parent_container = old_dom_node.get_parent()
	if not parent_container:
		return
	
	var old_position = -1
	for i in parent_container.get_child_count():
		if parent_container.get_child(i) == old_dom_node:
			old_position = i
			break
	
	old_dom_node.queue_free()
	dom_parser.parse_result.dom_nodes.erase(old_child_element_id)
	
	if old_position >= 0:
		var parent_dom_node: Node = null
		if parent_element_id == "body":
			var main_scene = lua_api.get_node("/root/Main")
			if main_scene:
				parent_dom_node = main_scene.website_container
		else:
			parent_dom_node = dom_parser.parse_result.dom_nodes.get(parent_element_id, null)
		
		if parent_dom_node:
			render_new_element_at_position.call_deferred(new_child_element, parent_dom_node, old_position, dom_parser)

static func add_enhanced_element_methods(vm: LuauVM, lua_api, index: String = "element") -> void:
	vm.lua_pushcallable(lua_api._element_insert_before_wrapper, index + ".insertBefore")
	vm.lua_setfield(-2, "insertBefore")
	
	vm.lua_pushcallable(lua_api._element_insert_after_wrapper, index + ".insertAfter")
	vm.lua_setfield(-2, "insertAfter")
	
	vm.lua_pushcallable(lua_api._element_replace_wrapper, index + ".replace")
	vm.lua_setfield(-2, "replace")
	
	vm.lua_pushcallable(lua_api._element_clone_wrapper, index + ".clone")
	vm.lua_setfield(-2, "clone")

static func is_same_element_visual_node(node1: Node, node2: Node) -> bool:
	if node1 == node2:
		return true

	var current = node1
	var node1_grandparent = node1.get_parent()
	if node1_grandparent:
		node1_grandparent = node1_grandparent.get_parent()
	while current:
		if current == node2:
			return true
		var parent = current.get_parent()
		if not parent or (node1_grandparent and current == node1_grandparent):
			break
		current = parent

	current = node2
	var node2_grandparent = node2.get_parent()
	if node2_grandparent:
		node2_grandparent = node2_grandparent.get_parent()
	while current:
		if current == node1:
			return true
		var parent = current.get_parent()
		if not parent or (node2_grandparent and current == node2_grandparent):
			break
		current = parent

	return false

static func render_new_element_at_position(element: HTMLParser.HTMLElement, parent_node: Node, position: int, dom_parser: HTMLParser) -> void:
	var main_scene = Engine.get_main_loop().current_scene.get_node("/root/Main")
	if not main_scene:
		return
	
	var element_node = await main_scene.create_element_node(element, dom_parser)
	if not element_node:
		return

	element_node.set_meta("html_element", element)
	dom_parser.register_dom_node(element, element_node)

	var container_node = parent_node
	if parent_node is MarginContainer and parent_node.get_child_count() > 0:
		container_node = parent_node.get_child(0)
	elif parent_node == main_scene.website_container:
		container_node = parent_node

	container_node.add_child(element_node)
	if position >= 0 and position < container_node.get_child_count():
		container_node.move_child(element_node, position)

static func render_new_element_by_reference(element: HTMLParser.HTMLElement, parent_node: Node, reference_element_id: String, insert_before: bool, dom_parser: HTMLParser) -> void:
	var main_scene = Engine.get_main_loop().current_scene.get_node("/root/Main")
	if not main_scene:
		return
	
	var reference_dom_node = dom_parser.parse_result.dom_nodes.get(reference_element_id, null)
	if not reference_dom_node:
		return
	
	var container_node = parent_node
	if parent_node is MarginContainer and parent_node.get_child_count() > 0:
		container_node = parent_node.get_child(0)
	elif parent_node == main_scene.website_container:
		container_node = parent_node
	
	var reference_position = -1
	for i in container_node.get_child_count():
		var child = container_node.get_child(i)
		if child == reference_dom_node or is_same_element_visual_node(child, reference_dom_node):
			reference_position = i
			break
	
	if reference_position < 0:
		reference_position = container_node.get_child_count()
	
	var insert_position = reference_position
	if not insert_before:
		insert_position = reference_position + 1
	
	var element_node = await main_scene.create_element_node(element, dom_parser)
	if not element_node:
		return

	element_node.set_meta("html_element", element)
	dom_parser.register_dom_node(element, element_node)
	
	container_node.add_child(element_node)
	if insert_position >= 0 and insert_position < container_node.get_child_count() - 1:
		container_node.move_child(element_node, insert_position)

static func _index_handler(vm: LuauVM, lua_api: LuaAPI) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	var key: String = vm.luaL_checkstring(2)
	
	match key:
		"parent":
			return lua_api._get_element_parent_wrapper(vm, lua_api)
		"nextSibling":
			return lua_api._get_element_next_sibling_wrapper(vm, lua_api)
		"previousSibling":
			return lua_api._get_element_previous_sibling_wrapper(vm, lua_api)
		"firstChild":
			return lua_api._get_element_first_child_wrapper(vm, lua_api)
		"lastChild":
			return lua_api._get_element_last_child_wrapper(vm, lua_api)
		_:
			return lua_api._element_index_handler(vm)
