extends Button

@onready var tab_container: TabManager = $"../../TabContainer"

func _on_pressed() -> void:
	%OptionsMenu.show()

func _on_options_menu_id_pressed(id: int) -> void:
	if id == 0: # new tab
		tab_container.create_tab()
	if id == 1: # new window
		OS.create_process(OS.get_executable_path(), [])
	if id == 2: # new ingonito window
		# TODO: handle incognito
		OS.create_process(OS.get_executable_path(), ["--incognito"])
	if id == 4: # history
		modulate = Constants.SECONDARY_COLOR
