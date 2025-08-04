class_name LuaFunctionUtils
extends RefCounted

# Core Lua handler functions that extend Lua functionality

static func table_tostring_handler(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	var table_string = LuaPrintUtils.table_to_string(vm, 1)
	vm.lua_pushstring(table_string)
	return 1

static func setup_gurt_api(vm: LuauVM, lua_api, dom_parser: HTMLParser) -> void:
	# override global print
	# This makes print() behave like gurt.log()
	vm.lua_pushcallable(LuaPrintUtils.lua_print, "print")
	vm.lua_setglobal("print")
	
	# Add table.tostring utility
	vm.lua_getglobal("table")
	if vm.lua_isnil(-1):
		vm.lua_pop(1)
		vm.lua_newtable()
		vm.lua_setglobal("table")
		vm.lua_getglobal("table")
	
	vm.lua_pushcallable(LuaFunctionUtils.table_tostring_handler, "table.tostring")
	vm.lua_setfield(-2, "tostring")
	vm.lua_pop(1)  # Pop table from stack
	
	vm.lua_newtable()
	
	vm.lua_pushcallable(LuaPrintUtils.lua_print, "gurt.log")
	vm.lua_setfield(-2, "log")

	vm.lua_pushcallable(lua_api._gurt_select_handler, "gurt.select")
	vm.lua_setfield(-2, "select")
	
	# Add body element access
	var body_element = dom_parser.find_first("body")
	if body_element:
		vm.lua_newtable()
		vm.lua_pushstring("body")
		vm.lua_setfield(-2, "_element_id")
		
		# NOTE: same code as add_element_methods, but lazy to handle body.xxxx prop
		vm.lua_pushcallable(lua_api._element_set_text_handler, "body.set_text")
		vm.lua_setfield(-2, "set_text")
		
		vm.lua_pushcallable(lua_api._element_get_text_handler, "body.get_text")
		vm.lua_setfield(-2, "get_text")
		
		vm.lua_pushcallable(lua_api._body_on_event_handler, "body.on")
		vm.lua_setfield(-2, "on")
		
		vm.lua_setfield(-2, "body")

	vm.lua_setglobal("gurt")
