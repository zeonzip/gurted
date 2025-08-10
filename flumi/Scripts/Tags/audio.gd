extends VBoxContainer

@onready var popup_panel: PopupPanel = $PopupPanel
@onready var volume_button: Button = $PanelContainer/HBoxContainer/Volume
@onready var volume_slider: VSlider = $PopupPanel/VSlider

const VOLUME_OFF = preload("res://Assets/Icons/volume-off.svg")
const VOLUME_2 = preload("res://Assets/Icons/volume-2.svg")

var is_muted = false
var initial_volume_value = 0.0

func _ready():
	popup_panel.hide()
	initial_volume_value = volume_slider.value

func _on_volume_pressed():
	is_muted = !is_muted
	
	if is_muted:
		volume_button.icon = VOLUME_OFF
	else:
		volume_button.icon = VOLUME_2
	
	if popup_panel.is_visible():
		popup_panel.hide()

func _on_volume_mouse_entered():
	if popup_panel.is_visible():
		return
	
	var h_offset = (volume_button.size.x - popup_panel.size.x) / 2
	var v_offset = volume_button.size.y + 17 
	
	popup_panel.position = volume_button.get_screen_position() + Vector2(h_offset, v_offset)
	popup_panel.show()

func _on_volume_mouse_exited():
	if volume_slider.value == initial_volume_value:
		await get_tree().create_timer(0.3).timeout
		
		var mouse_position = get_global_mouse_position()
		var popup_position = popup_panel.get_position()
		var popup_size = popup_panel.get_size()
		var popup_rect = Rect2(popup_position, popup_size)
		
		if not popup_rect.has_point(mouse_position):
			popup_panel.hide()

func _on_popup_panel_focus_exited() -> void:
	popup_panel.hide()
	initial_volume_value = volume_slider.value

func _on_volume_slider_value_changed(value: float) -> void:
	initial_volume_value = value
