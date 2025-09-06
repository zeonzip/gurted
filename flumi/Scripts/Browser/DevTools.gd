extends Control

func _on_close_button_pressed():
	Engine.get_main_loop().current_scene._toggle_dev_tools()
