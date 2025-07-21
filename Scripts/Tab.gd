class_name Tab
extends Control

signal tab_pressed
signal tab_closed

@onready var gradient_texture: TextureRect = $GradientTexture
@onready var button: Button = $Button
@onready var close_button: Button = $CloseButton

const TAB_GRADIENT: GradientTexture2D = preload("res://Scenes/Styles/TabGradient.tres")
const TAB_GRADIENT_DEFAULT: GradientTexture2D = preload("res://Scenes/Styles/TabGradientDefault.tres")
const TAB_GRADIENT_INACTIVE: GradientTexture2D = preload("res://Scenes/Styles/TabGradientInactive.tres")

const TAB_HOVER: StyleBoxFlat = preload("res://Scenes/Styles/TabHover.tres")
const TAB_DEFAULT: StyleBoxFlat = preload("res://Scenes/Styles/TabDefault.tres")
const CLOSE_BUTTON_HOVER: StyleBoxFlat = preload("res://Scenes/Styles/CloseButtonHover.tres")
const CLOSE_BUTTON_NORMAL: StyleBoxFlat = preload("res://Scenes/Styles/CloseButtonNormal.tres")

var is_active := false
var mouse_over_tab := false

func _ready():
	add_to_group("tabs")
	gradient_texture.texture = gradient_texture.texture.duplicate()
	gradient_texture.texture.gradient = gradient_texture.texture.gradient.duplicate()

func _process(_delta):
	# NOTE: probably very inefficient
	if mouse_over_tab:
		var mouse_pos = get_global_mouse_position()
		var close_button_rect = Rect2(close_button.global_position, close_button.size * close_button.scale)
		
		if close_button_rect.has_point(mouse_pos):
			close_button.add_theme_stylebox_override("normal", CLOSE_BUTTON_HOVER)
		else:
			close_button.add_theme_stylebox_override("normal", CLOSE_BUTTON_NORMAL)

func _on_button_mouse_entered() -> void:
	mouse_over_tab = true
	if is_active: return
	gradient_texture.texture = TAB_GRADIENT_INACTIVE

func _on_button_mouse_exited() -> void:
	mouse_over_tab = false
	if is_active: return
	gradient_texture.texture = TAB_GRADIENT_DEFAULT

func _exit_tree():
	remove_from_group("tabs")

func _on_button_pressed() -> void:
	# Check if click was on close button area
	var mouse_pos = get_global_mouse_position()
	var close_button_rect = Rect2(close_button.global_position, close_button.size * close_button.scale)
	
	if close_button_rect.has_point(mouse_pos):
		_on_close_button_pressed()
	else:
		# Handle tab button click
		tab_pressed.emit()

func _on_close_button_pressed() -> void:
	tab_closed.emit()
	queue_free()
