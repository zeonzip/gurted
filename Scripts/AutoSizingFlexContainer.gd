@tool
class_name AutoSizingFlexContainer
extends FlexContainer

signal flex_resized

var bgcolor: Color = Color(0,0,0,0)
var content_size: Vector2 = Vector2.ZERO

func set_background_color(color: Color) -> void:
	bgcolor = color
	queue_redraw()

func _notification(what: int) -> void:
	super._notification(what)

	if what == NOTIFICATION_DRAW and bgcolor.a > 0:
		draw_rect(Rect2(Vector2.ZERO, content_size), bgcolor)

# This is the overridden layout logic for the auto-sizing container
func _resort() -> void:
	# Check if we should fill horizontally (for w-full)
	if has_meta("should_fill_horizontal"):
		size_flags_horizontal = Control.SIZE_FILL
	else:
		size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# Check if we should fill vertically (for h-full)  
	if has_meta("should_fill_vertical"):
		size_flags_vertical = Control.SIZE_FILL
	else:
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	if debug_draw:
		_draw_rects.clear()

	var child_count = get_child_count()
	var valid_child_index = 0
	for i in range(child_count):
		var c = get_child(i)
		if not c is Control or c.is_set_as_top_level():
			continue

		var cid = c.get_instance_id()
		var target_index = _find_index_from_flex_list(_flex_list, cid)
		var flexbox: Flexbox

		# If the child is not visible, remove its corresponding flexbox node
		if not c.is_visible_in_tree():
			if target_index != -1:
				_root.remove_child_at(target_index)
				_flex_list.remove_at(target_index)
			continue

		# Find, swap, or create a new flexbox node for the child
		if target_index != -1:
			var old_flex_data = _flex_list[valid_child_index]
			var new_flex_data = _flex_list[target_index]
			flexbox = new_flex_data[FlexDataType.FLEXBOX]

			if old_flex_data[FlexDataType.CID] != cid:
				_root.swap_child(valid_child_index, target_index)
				_flex_list[target_index] = old_flex_data
				_flex_list[valid_child_index] = new_flex_data
		else:
			flexbox = Flexbox.new()
			_root.insert_child(flexbox, valid_child_index)
			_flex_list.insert(valid_child_index, [cid, flexbox, c])

		# Set the minimum size and apply flex properties for the child
		_set_control_min_size(c, flexbox)
		var flex_metas = c.get_meta("flex_metas", {})
		if flex_metas.size():
			apply_flex_meta(flexbox, flex_metas)
			if flex_metas.has("padding"):
				padding_wrapper(c, flex_metas.get("padding"))
		valid_child_index += 1

	# Clean up any flexbox nodes for children that were removed
	child_count = valid_child_index
	if child_count != _flex_list.size():
		for i in range(_flex_list.size() - 1, child_count - 1, -1):
			_root.remove_child_at(i)
		_flex_list.resize(child_count)
		_root.mark_dirty_and_propogate()


	var auto_size_width = not has_meta("custom_css_width") and not has_meta("should_fill_horizontal")
	var auto_size_height = not has_meta("custom_css_height") and not has_meta("should_fill_vertical")

	var available_width = NAN
	var available_height = NAN
	
	if not auto_size_width:
		if has_meta("should_fill_horizontal"):
			# For w-full, use the full parent size if available
			var parent_container = get_parent()
			if parent_container and parent_container.size.x > 0:
				available_width = parent_container.size.x
			elif size.x > 0:
				available_width = size.x
			else:
				# Fallback: try to get from custom_minimum_size
				available_width = custom_minimum_size.x if custom_minimum_size.x > 0 else NAN
		else:
			available_width = size.x
	
	if not auto_size_height:
		if has_meta("should_fill_vertical"):
			# For h-full, use the full parent size if available
			var parent_container = get_parent()
			if parent_container and parent_container.size.y > 0:
				available_height = parent_container.size.y
			elif size.y > 0:
				available_height = size.y
			else:
				available_height = custom_minimum_size.y if custom_minimum_size.y > 0 else NAN
		else:
			available_height = size.y

	_root.calculate_layout(available_width, available_height, 1) # 1 = LTR direction

	# Get the size computed by Yoga
	var computed_size = Vector2(
		_root.get_computed_width(),
		_root.get_computed_height()
	)

	# Respect any explicit width/height set via metadata
	var custom_w = 0.0
	if has_meta("custom_css_width"):
		custom_w = float(get_meta("custom_css_width"))
	elif has_meta("should_fill_horizontal"):
		# Use the same logic as available_width calculation
		var parent_container = get_parent()
		if parent_container and parent_container.size.x > 0:
			custom_w = parent_container.size.x
		elif size.x > 0:
			custom_w = size.x
		else:
			custom_w = custom_minimum_size.x if custom_minimum_size.x > 0 else 0.0

	var custom_h = 0.0
	if has_meta("custom_css_height"):
		custom_h = float(get_meta("custom_css_height"))
	elif has_meta("should_fill_vertical"):
		# Use the same logic as available_height calculation
		var parent_container = get_parent()
		if parent_container and parent_container.size.y > 0:
			custom_h = parent_container.size.y
		elif size.y > 0:
			custom_h = size.y
		else:
			custom_h = custom_minimum_size.y if custom_minimum_size.y > 0 else 0.0

	var needed_size = Vector2(
		max(custom_w, computed_size.x),
		max(custom_h, computed_size.y)
	)
	
	# Store the actual content size for background drawing
	content_size = needed_size

	# Construct the new minimum size for this container
	var new_min_size = custom_minimum_size
	if auto_size_width:
		new_min_size.x = needed_size.x
	else:
		# For w-full, ensure minimum size matches the needed size
		new_min_size.x = needed_size.x
	if auto_size_height:
		new_min_size.y = needed_size.y
	else:
		# For h-full, ensure minimum size matches the needed size  
		new_min_size.y = needed_size.y

	if not custom_minimum_size.is_equal_approx(new_min_size):
		custom_minimum_size = new_min_size
		
		# For w-full/h-full, also force the actual size if SIZE_FILL isn't working
		if has_meta("should_fill_horizontal") and size.x < new_min_size.x:
			size.x = new_min_size.x
		if has_meta("should_fill_vertical") and size.y < new_min_size.y:
			size.y = new_min_size.y

	# Apply the calculated layout to each child control
	for flex_data in _flex_list:
		var flexbox = flex_data[FlexDataType.FLEXBOX]
		var c = flex_data[FlexDataType.CONTROL]
		var offset = Vector2(flexbox.get_computed_left(), flexbox.get_computed_top())
		var rect_size = Vector2(flexbox.get_computed_width(), flexbox.get_computed_height())
		_fit_child_in_rect(c, Rect2(offset, rect_size))

		if debug_draw:
			_draw_debug_rect(Rect2(offset, rect_size), Color(1, 0, 0, 0.8))


	if has_meta("custom_css_background_color"):
		set_background_color(get_meta("custom_css_background_color"))

	queue_redraw()
	emit_signal("flex_resized")
