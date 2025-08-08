class_name Main
extends Control

@onready var website_container: Control = %WebsiteContainer
@onready var website_background: Control = %WebsiteBackground
@onready var tab_container: TabManager = $VBoxContainer/TabContainer
const LOADER_CIRCLE = preload("res://Assets/Icons/loader-circle.svg")
const AUTO_SIZING_FLEX_CONTAINER = preload("res://Scripts/AutoSizingFlexContainer.gd")

const P = preload("res://Scenes/Tags/p.tscn")
const IMG = preload("res://Scenes/Tags/img.tscn")
const SEPARATOR = preload("res://Scenes/Tags/separator.tscn")
const PRE = P
const BR = preload("res://Scenes/Tags/br.tscn")
const SPAN = preload("res://Scenes/Tags/span.tscn")
const H1 = P
const H2 = P
const H3 = P
const H4 = P
const H5 = P
const H6 = P
const FORM = preload("res://Scenes/Tags/form.tscn")
const INPUT = preload("res://Scenes/Tags/input.tscn")
const BUTTON = preload("res://Scenes/Tags/button.tscn")
const UL = preload("res://Scenes/Tags/ul.tscn")
const OL = preload("res://Scenes/Tags/ol.tscn")
const SELECT = preload("res://Scenes/Tags/select.tscn")
const OPTION = preload("res://Scenes/Tags/option.tscn")
const TEXTAREA = preload("res://Scenes/Tags/textarea.tscn")
const DIV = preload("res://Scenes/Tags/div.tscn")

const MIN_SIZE = Vector2i(750, 200)

var font_dependent_elements: Array = []

func should_group_as_inline(element: HTMLParser.HTMLElement) -> bool:
	# Don't group inputs unless they're inside a form
	if element.tag_name == "input":
		# Check if this element has a form ancestor
		var parent = element.parent
		while parent:
			if parent.tag_name == "form":
				return true
			parent = parent.parent
		return false
	
	return element.is_inline_element()

func _ready():
	ProjectSettings.set_setting("display/window/size/min_width", MIN_SIZE.x)
	ProjectSettings.set_setting("display/window/size/min_height", MIN_SIZE.y)
	DisplayServer.window_set_min_size(MIN_SIZE)
	
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func _on_viewport_size_changed():
	recalculate_percentage_elements(website_container)

func recalculate_percentage_elements(node: Node):
	if node is Control and node.has_meta("needs_percentage_recalc"):
		SizingUtils.apply_container_percentage_sizing(node)
	
	for child in node.get_children():
		recalculate_percentage_elements(child)

func render() -> void:
	# Clear existing content
	for child in website_container.get_children():
		child.queue_free()
	
	font_dependent_elements.clear()
	FontManager.clear_fonts()
	FontManager.set_refresh_callback(refresh_fonts)
	
	var html_bytes = Constants.HTML_CONTENT
	
	var parser: HTMLParser = HTMLParser.new(html_bytes)
	var parse_result = parser.parse()
	
	parser.process_styles()
	
	# Process and load all custom fonts defined in <font> tags
	parser.process_fonts()
	FontManager.load_all_fonts()
	
	if parse_result.errors.size() > 0:
		print("Parse errors: " + str(parse_result.errors))
	
	var tab = tab_container.tabs[tab_container.active_tab]
	
	var title = parser.get_title()
	tab.set_title(title)
	
	var icon = parser.get_icon()
	tab.update_icon_from_url(icon)
	
	var body = parser.find_first("body")
	
	if body:
		StyleManager.apply_body_styles(body, parser, website_container, website_background)
		
		parser.register_dom_node(body, website_container)
	
	var scripts = parser.find_all("script")
	var lua_api = null
	if scripts.size() > 0:
		lua_api = LuaAPI.new()
		add_child(lua_api)

	var i = 0
	while i < body.children.size():
		var element: HTMLParser.HTMLElement = body.children[i]
		
		if should_group_as_inline(element):
			# Create an HBoxContainer for consecutive inline elements
			var inline_elements: Array[HTMLParser.HTMLElement] = []

			while i < body.children.size() and should_group_as_inline(body.children[i]):
				inline_elements.append(body.children[i])
				i += 1

			var hbox = HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 4)

			for inline_element in inline_elements:
				var inline_node = await create_element_node(inline_element, parser)
				if inline_node:
					# Input elements register their own DOM nodes in their init() function
					if inline_element.tag_name not in ["input", "textarea", "select", "button"]:
						parser.register_dom_node(inline_element, inline_node)
					
					safe_add_child(hbox, inline_node)
					# Handle hyperlinks for all inline elements
					if contains_hyperlink(inline_element) and inline_node is RichTextLabel:
						inline_node.meta_clicked.connect(func(meta): OS.shell_open(str(meta)))
				else:
					print("Failed to create inline element node: ", inline_element.tag_name)

			safe_add_child(website_container, hbox)
			continue
		
		var element_node = await create_element_node(element, parser)
		if element_node:
			# Input elements register their own DOM nodes in their init() function
			if element.tag_name not in ["input", "textarea", "select", "button"]:
				parser.register_dom_node(element, element_node)
			
			# ul/ol handle their own adding
			if element.tag_name != "ul" and element.tag_name != "ol":
				safe_add_child(website_container, element_node)

			# Handle hyperlinks for all elements
			if contains_hyperlink(element):
				if element_node is RichTextLabel:
					element_node.meta_clicked.connect(func(meta): OS.shell_open(str(meta)))
				elif element_node.has_method("get") and element_node.get("rich_text_label"):
					element_node.rich_text_label.meta_clicked.connect(func(meta): OS.shell_open(str(meta)))
		else:
			print("Couldn't parse unsupported HTML tag \"%s\"" % element.tag_name)
		
		i += 1
	
	if scripts.size() > 0 and lua_api:
		parser.process_scripts(lua_api, null)

static func safe_add_child(parent: Node, child: Node) -> void:
	if child.get_parent():
		child.get_parent().remove_child(child)
	parent.add_child(child)
	
	if child.has_meta("container_percentage_width") or child.has_meta("container_percentage_height"):
		SizingUtils.apply_container_percentage_sizing(child)
		child.set_meta("needs_percentage_recalc", true)

func contains_hyperlink(element: HTMLParser.HTMLElement) -> bool:
	if element.tag_name == "a":
		return true
	
	for child in element.children:
		if contains_hyperlink(child):
			return true
	
	return false

func is_text_only_element(element: HTMLParser.HTMLElement) -> bool:
	if element.children.size() == 0:
		var text = element.get_collapsed_text()
		return not text.is_empty()
	
	return false

func create_element_node(element: HTMLParser.HTMLElement, parser: HTMLParser) -> Control:
	var styles = parser.get_element_styles_with_inheritance(element, "", [])
	var is_flex_container = styles.has("display") and ("flex" in styles["display"])

	var final_node: Control
	var container_for_children: Node

	# If this is an inline element AND not a flex container, do NOT recursively add child nodes for its children.
	# Only create a node for the outermost inline group; nested inline tags are handled by BBCode.
	if element.is_inline_element() and not is_flex_container:
		final_node = await create_element_node_internal(element, parser)
		if not final_node:
			return null
		final_node = StyleManager.apply_element_styles(final_node, element, parser)
		# Flex item properties may still apply
		StyleManager.apply_flex_item_properties(final_node, styles)
		return final_node

	if is_flex_container:
		# The element's primary identity IS a flex container.
		# We create it directly.
		final_node = AUTO_SIZING_FLEX_CONTAINER.new()
		final_node.name = "Flex_" + element.tag_name
		container_for_children = final_node
		
		# For FLEX ul/ol elements, we need to create the li children directly in the flex container
		if element.tag_name == "ul" or element.tag_name == "ol":
			final_node.flex_direction = FlexContainer.FlexDirection.Column

			website_container.add_child(final_node)
			
			var temp_list = UL.instantiate() if element.tag_name == "ul" else OL.instantiate()
			website_container.add_child(temp_list)
			await temp_list.init(element, parser)
			
			for child in temp_list.get_children():
				temp_list.remove_child(child)
				container_for_children.add_child(child)
			
			website_container.remove_child(temp_list)
			temp_list.queue_free()
		# If the element itself has text (like <span style="flex">TEXT</span>)
		elif not element.text_content.is_empty():
			var new_node = await create_element_node_internal(element, parser)
			container_for_children.add_child(new_node)
	else:
		final_node = await create_element_node_internal(element, parser)
		if not final_node:
			return null # Unsupported tag

		# If final_node is a PanelContainer, children should go to the VBoxContainer inside
		if final_node is PanelContainer and final_node.get_child_count() > 0:
			container_for_children = final_node.get_child(0)  # The VBoxContainer inside
		else:
			container_for_children = final_node

	# Applies background, size, etc. to the FlexContainer (top-level node)
	final_node = StyleManager.apply_element_styles(final_node, element, parser)

	# Apply flex CONTAINER properties if it's a flex container
	if is_flex_container:
		var flex_container_node = final_node
		# If the node was wrapped in a MarginContainer, get the inner FlexContainer
		if final_node is MarginContainer and final_node.get_child_count() > 0:
			var first_child = final_node.get_child(0)
			if first_child is FlexContainer:
				flex_container_node = first_child
		
		if flex_container_node is FlexContainer:
			StyleManager.apply_flex_container_properties(flex_container_node, styles)

	# Apply flex ITEM properties
	StyleManager.apply_flex_item_properties(final_node, styles)

	# Skip ul/ol and non-flex forms, they handle their own children
	var skip_general_processing = false

	if element.tag_name == "ul" or element.tag_name == "ol":
		skip_general_processing = true
	elif element.tag_name == "form":
		skip_general_processing = not is_flex_container
	
	if not skip_general_processing:
		for child_element in element.children:
			# Only add child nodes if the child is NOT an inline element
			# UNLESS the parent is a flex container (inline elements become flex items)
			if not child_element.is_inline_element() or is_flex_container:
				var child_node = await create_element_node(child_element, parser)
				if child_node and is_instance_valid(container_for_children):
					# Input elements register their own DOM nodes in their init() function
					if child_element.tag_name not in ["input", "textarea", "select", "button"]:
						parser.register_dom_node(child_element, child_node)
					safe_add_child(container_for_children, child_node)

	return final_node

func create_element_node_internal(element: HTMLParser.HTMLElement, parser: HTMLParser) -> Control:
	var node: Control = null
	
	match element.tag_name:
		"p":
			node = P.instantiate()
			node.init(element, parser)
		"pre":
			node = PRE.instantiate()
			node.init(element, parser)
		"h1", "h2", "h3", "h4", "h5", "h6":
			match element.tag_name:
				"h1": node = H1.instantiate()
				"h2": node = H2.instantiate()
				"h3": node = H3.instantiate()
				"h4": node = H4.instantiate()
				"h5": node = H5.instantiate()
				"h6": node = H6.instantiate()
			node.init(element, parser)
		"br":
			node = BR.instantiate()
			node.init(element, parser)
		"img":
			node = IMG.instantiate()
			node.init(element, parser)
		"separator":
			node = SEPARATOR.instantiate()
			node.init(element, parser)
		"form":
			var form_styles = parser.get_element_styles_with_inheritance(element, "", [])
			var is_flex_form = form_styles.has("display") and ("flex" in form_styles["display"])
			
			if is_flex_form:
				# Don't create a form node here - return null so general processing takes over
				return null
			else:
				node = FORM.instantiate()
				node.init(element, parser)
				
				# Manually process children for non-flex forms
				for child_element in element.children:
					var child_node = await create_element_node(child_element, parser)
					if child_node:
						safe_add_child(node, child_node)
		"input":
			node = INPUT.instantiate()
			node.init(element, parser)
		"button":
			node = BUTTON.instantiate()
			node.init(element, parser)
		"span", "b", "i", "u", "small", "mark", "code", "a":
			node = SPAN.instantiate()
			node.init(element, parser)
		"ul":
			node = UL.instantiate()
			website_container.add_child(node)
			await node.init(element, parser)
			return node
		"ol":
			node = OL.instantiate()
			website_container.add_child(node)
			await node.init(element, parser)
			return node
		"li":
			node = P.instantiate()
			node.init(element, parser)
		"select":
			node = SELECT.instantiate()
			node.init(element, parser)
		"option":
			node = OPTION.instantiate()
			node.init(element, parser)
		"textarea":
			node = TEXTAREA.instantiate()
			node.init(element, parser)
		"div":
			var styles = parser.get_element_styles_with_inheritance(element, "", [])
			var hover_styles = parser.get_element_styles_with_inheritance(element, "hover", [])
			
			# Create div container
			if BackgroundUtils.needs_background_wrapper(styles) or hover_styles.size() > 0:
				node = BackgroundUtils.create_panel_container_with_background(styles, hover_styles)
			else:
				node = DIV.instantiate()
				node.init(element, parser)
			
			var has_only_text = is_text_only_element(element)
			
			if has_only_text:
				var p_node = P.instantiate()
				p_node.init(element, parser)
				
				var container_for_children = node
				if node is PanelContainer and node.get_child_count() > 0:
					container_for_children = node.get_child(0)  # The VBoxContainer inside
				
				safe_add_child(container_for_children, p_node)
		_:
			return null
	
	return node

func register_font_dependent_element(label: Control, styles: Dictionary, element: HTMLParser.HTMLElement, parser: HTMLParser) -> void:
	font_dependent_elements.append({
		"label": label,
		"styles": styles,
		"element": element,
		"parser": parser
	})

func refresh_fonts(font_name: String) -> void:
	# Find all elements that should use this font and refresh them
	for element_info in font_dependent_elements:
		var label = element_info["label"]
		var styles = element_info["styles"]
		var element = element_info["element"]
		var parser = element_info["parser"]
		
		if styles.has("font-family") and styles["font-family"] == font_name:
			if is_instance_valid(label):
				StyleManager.apply_styles_to_label(label, styles, element, parser)
