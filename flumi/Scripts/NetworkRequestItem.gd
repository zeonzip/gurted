class_name NetworkRequestItem
extends PanelContainer

@onready var icon: TextureRect = $HBoxContainer/IconContainer/Icon
@onready var name_label: Label = $HBoxContainer/NameLabel
@onready var status_label: Label = $HBoxContainer/StatusLabel
@onready var type_label: Label = $HBoxContainer/TypeLabel
@onready var size_label: Label = $HBoxContainer/SizeLabel
@onready var time_label: Label = $HBoxContainer/TimeLabel

var request: NetworkRequest
var network_tab: NetworkTab

signal item_clicked(request: NetworkRequest)

func _ready():
	# Set up styles for different states
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color.TRANSPARENT
	style_normal.content_margin_left = 5
	style_normal.content_margin_bottom = 5
	style_normal.content_margin_right = 5
	style_normal.content_margin_top = 5
	style_normal.corner_radius_bottom_left = 8
	style_normal.corner_radius_bottom_right = 8
	style_normal.corner_radius_top_left = 8
	style_normal.corner_radius_top_right = 8
	
	add_theme_stylebox_override("panel", style_normal)
	
	# Set up mouse handling
	mouse_filter = Control.MOUSE_FILTER_PASS
	gui_input.connect(_on_gui_input)

func init(network_request: NetworkRequest, parent_tab: NetworkTab):
	request = network_request
	network_tab = parent_tab
	update_display()

func update_display():
	if not request:
		return
	
	# Update icon
	icon.texture = request.get_icon_texture()
	
	# Update labels
	name_label.text = request.name
	status_label.text = request.get_status_display()
	type_label.text = request.get_type_display()
	size_label.text = request.get_size_display()
	time_label.text = request.get_time_display()
	
	# Color code status
	match request.status:
		NetworkRequest.RequestStatus.SUCCESS:
			status_label.add_theme_color_override("font_color", Color.GREEN)
		NetworkRequest.RequestStatus.ERROR:
			status_label.add_theme_color_override("font_color", Color.RED)
		NetworkRequest.RequestStatus.PENDING:
			status_label.add_theme_color_override("font_color", Color.YELLOW)

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			item_clicked.emit(request)

func set_selected(selected: bool):
	if selected:
		var style_selected = StyleBoxFlat.new()
		style_selected.bg_color = Color(0.2, 0.4, 0.8, 0.3)
		style_selected.content_margin_left = 5
		style_selected.content_margin_bottom = 5
		style_selected.content_margin_right = 5
		style_selected.content_margin_top = 5
		style_selected.corner_radius_bottom_left = 8
		style_selected.corner_radius_bottom_right = 8
		style_selected.corner_radius_top_left = 8
		style_selected.corner_radius_top_right = 8
		add_theme_stylebox_override("panel", style_selected)
	else:
		var style_normal = StyleBoxFlat.new()
		style_normal.bg_color = Color.TRANSPARENT
		style_normal.content_margin_left = 5
		style_normal.content_margin_bottom = 5
		style_normal.content_margin_right = 5
		style_normal.content_margin_top = 5
		style_normal.corner_radius_bottom_left = 8
		style_normal.corner_radius_bottom_right = 8
		style_normal.corner_radius_top_left = 8
		style_normal.corner_radius_top_right = 8
		add_theme_stylebox_override("panel", style_normal)

func hide_columns(should_hide: bool):
	status_label.visible = !should_hide
	type_label.visible = !should_hide
	size_label.visible = !should_hide
	time_label.visible = !should_hide