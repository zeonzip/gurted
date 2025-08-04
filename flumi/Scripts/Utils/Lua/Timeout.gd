class_name LuaTimeoutManager
extends RefCounted

var active_timeouts: Dictionary = {}
var next_timeout_id: int = 1

class TimeoutInfo:
	var id: int
	var callback_ref: int
	var vm: LuauVM  
	var timer: Timer
	var timeout_manager: LuaTimeoutManager
	
	func _init(timeout_id: int, cb_ref: int, lua_vm: LuauVM, manager: LuaTimeoutManager):
		id = timeout_id
		callback_ref = cb_ref
		vm = lua_vm
		timeout_manager = manager

func set_timeout_handler(vm: LuauVM, parent_node: Node) -> int:
	vm.luaL_checktype(1, vm.LUA_TFUNCTION)
	var delay_ms: int = vm.luaL_checkint(2)
	
	var timeout_id = next_timeout_id
	next_timeout_id += 1
	
	# Store callback in isolated registry table
	vm.lua_pushstring("GURT_TIMEOUTS")
	vm.lua_rawget(vm.LUA_REGISTRYINDEX)
	if vm.lua_isnil(-1):
		vm.lua_pop(1)
		vm.lua_newtable()
		vm.lua_pushstring("GURT_TIMEOUTS")
		vm.lua_pushvalue(-2)
		vm.lua_rawset(vm.LUA_REGISTRYINDEX)
	
	vm.lua_pushinteger(timeout_id)
	vm.lua_pushvalue(1)
	vm.lua_rawset(-3)
	vm.lua_pop(1)
	
	# Create timeout info
	var timeout_info = TimeoutInfo.new(timeout_id, timeout_id, vm, self)
	
	# Create and configure timer
	var timer = Timer.new()
	timer.wait_time = delay_ms / 1000.0
	timer.one_shot = true
	timer.timeout.connect(_on_timeout_triggered.bind(timeout_info))
	
	timeout_info.timer = timer
	active_timeouts[timeout_id] = timeout_info
	
	# Add timer to scene tree
	parent_node.add_child(timer)
	timer.start()
	
	vm.lua_pushinteger(timeout_id)
	return 1

func clear_timeout_handler(vm: LuauVM) -> int:
	var timeout_id: int = vm.luaL_checkint(1)
	
	var timeout_info = active_timeouts.get(timeout_id, null)
	if timeout_info:
		# Stop and remove timer
		if timeout_info.timer:
			timeout_info.timer.stop()
			timeout_info.timer.queue_free()
		
		# Clean up callback reference
		vm.lua_pushstring("GURT_TIMEOUTS")
		vm.lua_rawget(vm.LUA_REGISTRYINDEX)
		if not vm.lua_isnil(-1):
			vm.lua_pushinteger(timeout_info.callback_ref)
			vm.lua_pushnil()
			vm.lua_rawset(-3)
		vm.lua_pop(1)
		
		# Remove from active timeouts
		active_timeouts.erase(timeout_id)
	
	return 0

func _on_timeout_triggered(timeout_info: TimeoutInfo) -> void:
	if not active_timeouts.has(timeout_info.id):
		return
	
	# Execute the callback
	timeout_info.vm.lua_pushstring("GURT_TIMEOUTS")
	timeout_info.vm.lua_rawget(timeout_info.vm.LUA_REGISTRYINDEX)
	timeout_info.vm.lua_pushinteger(timeout_info.callback_ref)
	timeout_info.vm.lua_rawget(-2)
	timeout_info.vm.lua_remove(-2)
	
	if timeout_info.vm.lua_isfunction(-1):
		if timeout_info.vm.lua_pcall(0, 0, 0) != timeout_info.vm.LUA_OK:
			print("GURT ERROR in timeout callback: ", timeout_info.vm.lua_tostring(-1))
			timeout_info.vm.lua_pop(1)
	else:
		timeout_info.vm.lua_pop(1)
	
	# Clean up timeout
	timeout_info.timer.queue_free()
	timeout_info.vm.lua_pushstring("GURT_TIMEOUTS")
	timeout_info.vm.lua_rawget(timeout_info.vm.LUA_REGISTRYINDEX)
	if not timeout_info.vm.lua_isnil(-1):
		timeout_info.vm.lua_pushinteger(timeout_info.callback_ref)
		timeout_info.vm.lua_pushnil()
		timeout_info.vm.lua_rawset(-3)
	timeout_info.vm.lua_pop(1)
	active_timeouts.erase(timeout_info.id)

func cleanup_all_timeouts():
	# Clean up all active timeouts
	for timeout_id in active_timeouts:
		var timeout_info = active_timeouts[timeout_id]
		if timeout_info.timer:
			timeout_info.timer.stop()
			timeout_info.timer.queue_free()

		# Release Lua callback reference
		if timeout_info.vm and timeout_info.callback_ref:
			timeout_info.vm.lua_pushstring("GURT_TIMEOUTS")
			timeout_info.vm.lua_rawget(timeout_info.vm.LUA_REGISTRYINDEX)
			if not timeout_info.vm.lua_isnil(-1):
				timeout_info.vm.lua_pushinteger(timeout_info.callback_ref)
				timeout_info.vm.lua_pushnil()
				timeout_info.vm.lua_rawset(-3)
			timeout_info.vm.lua_pop(1)
	active_timeouts.clear()
