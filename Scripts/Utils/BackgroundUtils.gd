class_name BackgroundUtils
extends RefCounted

static func create_stylebox_from_styles(styles: Dictionary = {}, container: Control = null) -> StyleBoxFlat:
	var style_box = StyleBoxFlat.new()
	
	# Background color
	var bg_color = null
	if styles.has("background-color"):
		bg_color = styles["background-color"]
	elif container and container.has_meta("custom_css_background_color"):
		bg_color = container.get_meta("custom_css_background_color")
	
	if bg_color:
		style_box.bg_color = bg_color
	else:
		style_box.bg_color = Color.TRANSPARENT
	
	# Border radius
	var border_radius = null
	if styles.has("border-radius"):
		border_radius = styles["border-radius"]
	elif container and container.has_meta("custom_css_border_radius"):
		border_radius = container.get_meta("custom_css_border_radius")
	
	if border_radius:
		var radius = StyleManager.parse_radius(border_radius)
		style_box.corner_radius_top_left = radius
		style_box.corner_radius_top_right = radius
		style_box.corner_radius_bottom_left = radius
		style_box.corner_radius_bottom_right = radius
	
	# Padding as content margins
	var has_padding = false
	if styles.size() > 0:
		has_padding = styles.has("padding") or styles.has("padding-top") or styles.has("padding-right") or styles.has("padding-bottom") or styles.has("padding-left")
	elif container:
		has_padding = container.has_meta("padding") or container.has_meta("padding-top") or container.has_meta("padding-right") or container.has_meta("padding-bottom") or container.has_meta("padding-left")
	
	if has_padding:
		# General padding
		var padding_val = null
		if styles.has("padding"):
			padding_val = StyleManager.parse_size(styles["padding"])
		elif container and container.has_meta("padding"):
			padding_val = StyleManager.parse_size(container.get_meta("padding"))
		
		if padding_val:
			style_box.content_margin_left = padding_val
			style_box.content_margin_right = padding_val
			style_box.content_margin_top = padding_val
			style_box.content_margin_bottom = padding_val
		
		# Individual padding values override general padding
		var padding_keys = [["padding-left", "content_margin_left"], ["padding-right", "content_margin_right"], ["padding-top", "content_margin_top"], ["padding-bottom", "content_margin_bottom"]]
		
		for pair in padding_keys:
			var key = pair[0]
			var property = pair[1]
			var val = null
			
			if styles.has(key):
				val = StyleManager.parse_size(styles[key])
			elif container and container.has_meta(key):
				val = StyleManager.parse_size(container.get_meta(key))
			
			if val:
				style_box.set(property, val)
	
	return style_box

# for AutoSizingFlexContainer
static func update_background_panel(container: Control) -> void:
	var needs_background = container.has_meta("custom_css_background_color") or container.has_meta("custom_css_border_radius")
	var needs_padding = container.has_meta("padding") or container.has_meta("padding-top") or container.has_meta("padding-right") or container.has_meta("padding-bottom") or container.has_meta("padding-left")
	var background_panel = get_background_panel(container)
	
	if needs_background or needs_padding:
		if not background_panel:
			background_panel = Panel.new()
			background_panel.name = "BackgroundPanel"
			background_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
			background_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			container.add_child(background_panel)
			container.move_child(background_panel, 0) # first child
		
		var style_box = create_stylebox_from_styles({}, container)
		background_panel.add_theme_stylebox_override("panel", style_box)
	
	elif background_panel:
		background_panel.queue_free()

# Helper methods for AutoSizingFlexContainer
static func get_background_panel(container: Control) -> Panel:
	for child in container.get_children():
		if child.name == "BackgroundPanel" and child is Panel:
			return child
	return null

static func is_background_panel(node: Node) -> bool:
	return node.name == "BackgroundPanel" and node is Panel

# for any other tag
static func create_panel_container_with_background(styles: Dictionary) -> PanelContainer:
	var panel_container = PanelContainer.new()
	panel_container.name = "Div"
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	panel_container.add_child(vbox)
	
	var style_box = create_stylebox_from_styles(styles)
	panel_container.add_theme_stylebox_override("panel", style_box)
	return panel_container

static func needs_background_wrapper(styles: Dictionary) -> bool:
	return styles.has("background-color") or styles.has("border-radius") or styles.has("padding") or styles.has("padding-top") or styles.has("padding-right") or styles.has("padding-bottom") or styles.has("padding-left")
