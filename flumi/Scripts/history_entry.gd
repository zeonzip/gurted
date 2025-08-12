extends HBoxContainer
signal checkbox_toggle

@onready var check_box: CheckBox = $CheckBox

func reset() -> void:
	check_box.set_pressed_no_signal(false)

func _on_check_box_toggled(toggled_on: bool) -> void:
	checkbox_toggle.emit(toggled_on)
