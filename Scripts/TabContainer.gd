class_name TabManager
extends HFlowContainer

var tabs: Array[Tab] = []
var active_tab := 0

@onready var main: Main = $"../.."

const TAB = preload("res://Scenes/Tab.tscn")

const TAB_NORMAL: StyleBoxFlat = preload("res://Scenes/Styles/TabNormal.tres")
const TAB_HOVER: StyleBoxFlat = preload("res://Scenes/Styles/TabHover.tres")

const TAB_DEFAULT: StyleBoxFlat = preload("res://Scenes/Styles/TabDefault.tres")
const TAB_HOVER_DEFAULT: StyleBoxFlat = preload("res://Scenes/Styles/TabHoverDefault.tres")

const TAB_GRADIENT: GradientTexture2D = preload("res://Scenes/Styles/TabGradient.tres")
const TAB_GRADIENT_DEFAULT: GradientTexture2D = preload("res://Scenes/Styles/TabGradientDefault.tres")

@onready var h_box_container: HBoxContainer = $HBoxContainer

func _ready() -> void:
	tabs.assign(get_tree().get_nodes_in_group("tabs"))
	set_active_tab(0)
	
	for i in tabs.size():
		tabs[i].tab_pressed.connect(_tab_pressed.bind(i))
		tabs[i].tab_closed.connect(_tab_closed.bind(i))

func _tab_pressed(index: int) -> void:
	set_active_tab(index)

func _tab_closed(index: int) -> void:
	tabs.remove_at(index)

	if tabs.is_empty():
		get_tree().quit()
		return

	if index <= active_tab:
		if index == active_tab:
			# Closed tab was active, select right neighbor (or last tab if at end)
			if index >= tabs.size():
				active_tab = tabs.size() - 1
			else:
				active_tab = index
		else:
			# Closed tab was before active tab, shift active index down
			active_tab -= 1
	
	# Reconnect signals with updated indices
	for i in tabs.size():
		tabs[i].tab_pressed.disconnect(_tab_pressed)
		tabs[i].tab_closed.disconnect(_tab_closed)
		tabs[i].tab_pressed.connect(_tab_pressed.bind(i))
		tabs[i].tab_closed.connect(_tab_closed.bind(i))

	set_active_tab(active_tab)

func set_active_tab(index: int) -> void:
	# old tab
	tabs[active_tab].is_active = false
	tabs[active_tab].button.add_theme_stylebox_override("normal", TAB_DEFAULT)
	tabs[active_tab].button.add_theme_stylebox_override("pressed", TAB_DEFAULT)
	tabs[active_tab].button.add_theme_stylebox_override("hover", TAB_HOVER_DEFAULT)
	tabs[active_tab].gradient_texture.texture = TAB_GRADIENT_DEFAULT
	# new tab
	tabs[index].is_active = true
	tabs[index].button.add_theme_stylebox_override("normal", TAB_NORMAL)
	tabs[index].button.add_theme_stylebox_override("pressed", TAB_NORMAL)
	tabs[index].button.add_theme_stylebox_override("hover", TAB_NORMAL)
	tabs[index].gradient_texture.texture = TAB_GRADIENT
	
	active_tab = index

func create_tab() -> void:
	var index = tabs.size();
	var tab = TAB.instantiate()
	tabs.append(tab)
	tab.tab_pressed.connect(_tab_pressed.bind(index))
	tab.tab_closed.connect(_tab_closed.bind(index))
	h_box_container.add_child(tab)
	
	set_active_tab(index)
	
	# WARNING: temporary
	main.render()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("NewTab"):
		create_tab()
	if Input.is_action_just_pressed("CloseTab"):
		tabs[active_tab]._on_close_button_pressed()
	if Input.is_action_just_pressed("NextTab"):
		var next_tab = (active_tab + 1) % tabs.size()
		set_active_tab(next_tab)
	if Input.is_action_just_pressed("PreviousTab"):
		var prev_tab = (active_tab - 1 + tabs.size()) % tabs.size()
		set_active_tab(prev_tab - 1)

func _on_new_tab_button_pressed() -> void:
	create_tab()
