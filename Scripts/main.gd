class_name Main
extends Control

@onready var website_container: Control = %WebsiteContainer
@onready var tab_container: TabManager = $VBoxContainer/TabContainer
const LOADER_CIRCLE = preload("res://Assets/Icons/loader-circle.svg")
const AUTO_SIZING_FLEX_CONTAINER = preload("res://Scripts/AutoSizingFlexContainer.gd")

const P = preload("res://Scenes/Tags/p.tscn")
const IMG = preload("res://Scenes/Tags/img.tscn")
const SEPARATOR = preload("res://Scenes/Tags/separator.tscn")
const PRE = preload("res://Scenes/Tags/pre.tscn")
const BR = preload("res://Scenes/Tags/br.tscn")
const SPAN = preload("res://Scenes/Tags/span.tscn")
const H1 = preload("res://Scenes/Tags/h1.tscn")
const H2 = preload("res://Scenes/Tags/h2.tscn")
const H3 = preload("res://Scenes/Tags/h3.tscn")
const H4 = preload("res://Scenes/Tags/h4.tscn")
const H5 = preload("res://Scenes/Tags/h5.tscn")
const H6 = preload("res://Scenes/Tags/h6.tscn")
const FORM = preload("res://Scenes/Tags/form.tscn")
const INPUT = preload("res://Scenes/Tags/input.tscn")
const BUTTON = preload("res://Scenes/Tags/button.tscn")
const UL = preload("res://Scenes/Tags/ul.tscn")
const OL = preload("res://Scenes/Tags/ol.tscn")
const LI = preload("res://Scenes/Tags/li.tscn")
const SELECT = preload("res://Scenes/Tags/select.tscn")
const OPTION = preload("res://Scenes/Tags/option.tscn")
const TEXTAREA = preload("res://Scenes/Tags/textarea.tscn")
const DIV = preload("res://Scenes/Tags/div.tscn")

const MIN_SIZE = Vector2i(750, 200)

func _ready():
	ProjectSettings.set_setting("display/window/size/min_width", MIN_SIZE.x)
	ProjectSettings.set_setting("display/window/size/min_height", MIN_SIZE.y)
	DisplayServer.window_set_min_size(MIN_SIZE)

func render() -> void:
	# Clear existing content
	for child in website_container.get_children():
		child.queue_free()
	
	var html_bytes = Constants.HTML_CONTENT
	
	var parser: HTMLParser = HTMLParser.new(html_bytes)
	var parse_result = parser.parse()
	
	parser.process_styles()
	
	print("Total elements found: " + str(parse_result.all_elements.size()))
	
	if parse_result.errors.size() > 0:
		print("Parse errors: " + str(parse_result.errors))
	
	var tab = tab_container.tabs[tab_container.active_tab]
	
	var title = parser.get_title()
	tab.set_title(title)
	
	var icon = parser.get_icon()
	tab.update_icon_from_url(icon)
	
	var body = parser.find_first("body")
	var i = 0
	while i < body.children.size():
		var element: HTMLParser.HTMLElement = body.children[i]
		
		if element.is_inline_element():
			# Create an HBoxContainer for consecutive inline elements
			var inline_elements: Array[HTMLParser.HTMLElement] = []

			while i < body.children.size() and body.children[i].is_inline_element():
				inline_elements.append(body.children[i])
				i += 1

			var hbox = HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 4)

			for inline_element in inline_elements:
				var inline_node = await create_element_node(inline_element, parser)
				if inline_node:
					safe_add_child(hbox, inline_node)
					# Handle hyperlinks for all inline elements
					if contains_hyperlink(inline_element) and inline_node.rich_text_label:
						inline_node.rich_text_label.meta_clicked.connect(func(meta): OS.shell_open(str(meta)))
				else:
					print("Failed to create inline element node: ", inline_element.tag_name)

			safe_add_child(website_container, hbox)
			continue
		
		var element_node = await create_element_node(element, parser)
		if element_node:
			# ul/ol handle their own adding
			if element.tag_name != "ul" and element.tag_name != "ol":
				safe_add_child(website_container, element_node)

			# Handle hyperlinks for all elements
			if contains_hyperlink(element) and element_node.has_method("get") and element_node.get("rich_text_label"):
				element_node.rich_text_label.meta_clicked.connect(func(meta): OS.shell_open(str(meta)))
		else:
			print("Couldn't parse unsupported HTML tag \"%s\"" % element.tag_name)
		
		i += 1

static func safe_add_child(parent: Node, child: Node) -> void:
	if child.get_parent():
		child.get_parent().remove_child(child)
	parent.add_child(child)

func contains_hyperlink(element: HTMLParser.HTMLElement) -> bool:
	if element.tag_name == "a":
		return true
	
	for child in element.children:
		if contains_hyperlink(child):
			return true
	
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
		# If the element itself has text (like <span style="flex">TEXT</span>)
		if not element.text_content.is_empty():
			var new_node = await create_element_node_internal(element, parser)
			container_for_children.add_child(new_node)
	else:
		final_node = await create_element_node_internal(element, parser)
		if not final_node:
			return null # Unsupported tag
		# Children will be added to this node.
		container_for_children = final_node

	# Applies background, size, etc. to the FlexContainer (top-level node)
	final_node = StyleManager.apply_element_styles(final_node, element, parser)

	# Apply flex CONTAINER properties if it's a flex container
	if is_flex_container:
		StyleManager.apply_flex_container_properties(final_node, styles, element, parser)

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
					safe_add_child(container_for_children, child_node)

	return final_node

func create_element_node_internal(element: HTMLParser.HTMLElement, parser: HTMLParser = null) -> Control:
	var node: Control = null
	
	match element.tag_name:
		"p":
			node = P.instantiate()
			node.init(element)
		"pre":
			node = PRE.instantiate()
			node.init(element)
		"h1", "h2", "h3", "h4", "h5", "h6":
			match element.tag_name:
				"h1": node = H1.instantiate()
				"h2": node = H2.instantiate()
				"h3": node = H3.instantiate()
				"h4": node = H4.instantiate()
				"h5": node = H5.instantiate()
				"h6": node = H6.instantiate()
			node.init(element)
		"br":
			node = BR.instantiate()
			node.init(element)
		"img":
			node = IMG.instantiate()
			node.init(element)
		"separator":
			node = SEPARATOR.instantiate()
			node.init(element)
		"form":
			var form_styles = parser.get_element_styles_with_inheritance(element, "", [])
			var is_flex_form = form_styles.has("display") and ("flex" in form_styles["display"])
			
			if is_flex_form:
				# Don't create a form node here - return null so general processing takes over
				return null
			else:
				node = FORM.instantiate()
				node.init(element)
				
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
			node.init(element)
		"ul":
			node = UL.instantiate()
			website_container.add_child(node)
			await node.init(element)
			return node
		"ol":
			node = OL.instantiate()
			website_container.add_child(node)
			await node.init(element)
			return node
		"li":
			node = LI.instantiate()
			node.init(element)
		"select":
			node = SELECT.instantiate()
			node.init(element)
		"option":
			node = OPTION.instantiate()
			node.init(element)
		"textarea":
			node = TEXTAREA.instantiate()
			node.init(element)
		"div":
			node = DIV.instantiate()
			node.init(element)
		_:
			return null
	
	return node
