class_name Tab
extends Control

signal tab_pressed
signal tab_closed

@onready var gradient_texture: TextureRect = %GradientTexture
@onready var button: Button = %Button
@onready var close_button: Button = %CloseButton
@onready var icon: TextureRect = %Icon
@onready var animation: AnimationPlayer = $AnimationPlayer

const TAB_GRADIENT: GradientTexture2D = preload("res://Scenes/Styles/TabGradient.tres")
const TAB_GRADIENT_DEFAULT: GradientTexture2D = preload("res://Scenes/Styles/TabGradientDefault.tres")
const TAB_GRADIENT_INACTIVE: GradientTexture2D = preload("res://Scenes/Styles/TabGradientInactive.tres")

const TAB_HOVER: StyleBoxFlat = preload("res://Scenes/Styles/TabHover.tres")
const TAB_DEFAULT: StyleBoxFlat = preload("res://Scenes/Styles/TabDefault.tres")
const CLOSE_BUTTON_HOVER: StyleBoxFlat = preload("res://Scenes/Styles/CloseButtonHover.tres")
const CLOSE_BUTTON_NORMAL: StyleBoxFlat = preload("res://Scenes/Styles/CloseButtonNormal.tres")

var is_active := false
var mouse_over_tab := false
var loading_tween: Tween

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

func set_title(title: String) -> void:
	button.text = title

func set_icon(new_icon: Texture) -> void:
	icon.texture = new_icon
	icon.rotation = 0

func update_icon_from_url(icon_url: String) -> void:
	const LOADER_CIRCLE = preload("res://Assets/Icons/loader-circle.svg")
	
	loading_tween = create_tween()
	
	set_icon(LOADER_CIRCLE)
	
	loading_tween.set_loops()
	
	icon.pivot_offset = Vector2(11.5, 11.5)
	loading_tween.tween_method(func(angle):
		if !is_instance_valid(icon): 
			if loading_tween: loading_tween.kill()
			return
		icon.rotation = angle
	, 0.0, TAU, 1.0)
	
	var icon_resource = await Network.fetch_image(icon_url)

	# Only update if tab still exists
	if is_instance_valid(self):
		set_icon(icon_resource)
		if loading_tween:
			loading_tween.kill()
			loading_tween = null

func _on_button_mouse_entered() -> void:
	mouse_over_tab = true
	if is_active: return
	gradient_texture.texture = TAB_GRADIENT_INACTIVE

func _on_button_mouse_exited() -> void:
	mouse_over_tab = false
	if is_active: return
	gradient_texture.texture = TAB_GRADIENT_DEFAULT

func _exit_tree():
	if loading_tween:
		loading_tween.kill()
		loading_tween = null
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
	animation.play("appear", -1, -1.0, true)
	await animation.animation_finished
	queue_free()
