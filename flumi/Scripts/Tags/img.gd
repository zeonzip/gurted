extends TextureRect

func init(element: HTMLParser.HTMLElement, parser: HTMLParser) -> void:
	var src = element.get_attribute("src")
	if !src: return print("Ignoring <img/> tag without \"src\" attribute.")
	
	load_image_async(src, element, parser)

func load_image_async(src: String, element: HTMLParser.HTMLElement, parser: HTMLParser) -> void:
	# Wait until this node is in the scene tree
	if not is_inside_tree():
		await tree_entered
	
	texture = await Network.fetch_image(src)
	
	if !is_instance_valid(texture): 
		print("Failed to load image: ", src)
		return
	
	var element_styles = parser.get_element_styles_internal(element, "")
	var has_width = element_styles.has("width")
	var has_height = element_styles.has("height")
	
	if not has_width and not has_height:
		var texture_size = texture.get_size()
		custom_minimum_size = texture_size
		size = texture_size
	else:
		var width_val = element_styles.get("width", "")
		var height_val = element_styles.get("height", "")
		
		if width_val == "100%" and height_val == "100%" or width_val == "full" and height_val == "full":
			size_flags_horizontal = Control.SIZE_EXPAND_FILL
			size_flags_vertical = Control.SIZE_EXPAND_FILL
			custom_minimum_size = Vector2.ZERO
