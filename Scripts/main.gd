class_name Main
extends Control

@onready var website_container: Control = %WebsiteContainer
@onready var tab_container: TabManager = $VBoxContainer/TabContainer
const LOADER_CIRCLE = preload("res://Assets/Icons/loader-circle.svg")

var loading_tween: Tween

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

const MIN_SIZE = Vector2i(750, 200)

func _ready():
	ProjectSettings.set_setting("display/window/size/min_width", MIN_SIZE.x)
	ProjectSettings.set_setting("display/window/size/min_height", MIN_SIZE.y)
	DisplayServer.window_set_min_size(MIN_SIZE)

func render():
	# Clear existing content
	for child in website_container.get_children():
		child.queue_free()
	
	var html_bytes = "<head>
	<title>My cool web</title>
	<icon src=\"https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/768px-Google_%22G%22_logo.svg.png\">

	<meta name=\"theme-color\" content=\"#000000\">
	<meta name=\"description\" content=\"My cool web\">

	<style href=\"styles.css\">
	<script src=\"script.lua\" />
</head>

<body>
	<h1>Header 1</h1>
	<h2>Header 2</h2>
	<h3>Header 3</h3>
	<h4>Header 4</h4>
	<h5>Header 5</h5>
	<h6>Header 6</h6>
	
	<p>Hey there!       this is a        test</p>
	<b>This is bold</b>
	<i>This is italic <mark>actually, and it's pretty <u>cool</u></mark></i>
	<u>This is underline</u>
	<small>this is small</small>
	<mark>this is marked</mark>
	<code>this is code<span> THIS IS A SPAN AND SHOULDNT BE ANY DIFFERENT</span></code>
	
	<p>
	<a href=\"https://youtube.com\">Hello gang</a>
	</p>

	<pre>
Text in a pre element
is displayed in a fixed-width
font, and it preserves
both      spaces and
line breaks
</pre>

<!-- action, method, and type=submit are for when we implement Lua -->
<form action=\"/submit\" method=\"POST\">
  <span>Name:</span>
  <input type=\"text\" placeholder=\"First name\" value=\"John\" maxlength=\"20\" minlength=\"3\" />
  <span>Email regex:</span>
  <input type=\"text\" placeholder=\"Last name\" value=\"Doe\" pattern=\"^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$\" />
  <span>Smart:</span>
  <input type=\"checkbox\" />
  <input type=\"checkbox\" value=\"true\" />

  <p>favorite food</p>
  <input type=\"radio\" group=\"food\" />
  <span>Pizza</span>
  <input type=\"radio\" group=\"food\" />
  <span>Berry</span>
  <input type=\"radio\" group=\"food\" />
  <span>Gary</span>
  
  <input type=\"password\" placeholder=\"your password...\" />
  <button type=\"submit\">Submit</button>


</form>

	<separator direction=\"horizontal\" />
	<img src=\"https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQMNUPIKabszX0Js_c0kfa4cz_JQYKfGTuBUA&s\" />
	<separator direction=\"vertical\" />
</body>".to_utf8_buffer()
	
	# Create parser and parse
	var parser: HTMLParser = HTMLParser.new(html_bytes)
	var parse_result = parser.parse()
	
	print("Total elements found: " + str(parse_result.all_elements.size()))
	
	if parse_result.errors.size() > 0:
		print("Parse errors: " + str(parse_result.errors))
	
	# TODO: render the shit on the screen
	var tab = tab_container.tabs[tab_container.active_tab]
	
	var title = parser.get_title()
	tab.set_title(title)
	
	var icon = parser.get_icon()
	set_loading_icon(tab)
	call_deferred("update_tab_icon", tab, icon)
	
	var body = parser.find_first("body")
	var i = 0
	while i < body.children.size():
		var element: HTMLParser.HTMLElement = body.children[i]
		
		if element.is_inline_element():
			# Collect consecutive inline elements and flatten nested ones
			var inline_elements: Array[HTMLParser.HTMLElement] = []
			var has_hyperlink = false
			while i < body.children.size() and body.children[i].is_inline_element():
				inline_elements.append(body.children[i])
				if contains_hyperlink(body.children[i]):
					has_hyperlink = true
				i += 1
			
			var inline_container = P.instantiate()

			var temp_parent = HTMLParser.HTMLElement.new()
			temp_parent.tag_name = "p"
			temp_parent.children = inline_elements
			inline_container.init(temp_parent)
			
			website_container.add_child(inline_container)
			
			if has_hyperlink:
				inline_container.rich_text_label.meta_clicked.connect(func(meta): OS.shell_open(str(meta)))
			
			continue
		
		var element_node = create_element_node(element)
		if element_node:
			website_container.add_child(element_node)
			# Handle hyperlinks for all elements
			if contains_hyperlink(element) and element_node.has_method("get") and element_node.get("rich_text_label"):
				element_node.rich_text_label.meta_clicked.connect(func(meta): OS.shell_open(str(meta)))
		else:
			print("Couldn't parse unsupported HTML tag \"%s\"" % element.tag_name)
		
		i += 1

func set_loading_icon(tab: Tab) -> void:
	tab.set_icon(LOADER_CIRCLE)
	
	loading_tween = create_tween()
	loading_tween.set_loops()
	
	var icon = tab.icon
	icon.pivot_offset = Vector2(11.5, 11.5)
	loading_tween.tween_method(func(angle): icon.rotation = angle, 0.0, TAU, 1.0)

func stop_loading_icon() -> void:
	if loading_tween:
		loading_tween.kill()
		loading_tween = null

func update_tab_icon(tab: Tab, icon: String) -> void:
	tab.set_icon(await Network.fetch_image(icon))
	stop_loading_icon()

func contains_hyperlink(element: HTMLParser.HTMLElement) -> bool:
	if element.tag_name == "a":
		return true
	
	for child in element.children:
		if contains_hyperlink(child):
			return true
	
	return false

func create_element_node(element: HTMLParser.HTMLElement) -> Control:
	var node: Control = null
	
	match element.tag_name:
		"p":
			node = P.instantiate()
			node.init(element)
		"h1":
			node = H1.instantiate()
			node.init(element)
		"h2":
			node = H2.instantiate()
			node.init(element)
		"h3":
			node = H3.instantiate()
			node.init(element)
		"h4":
			node = H4.instantiate()
			node.init(element)
		"h5":
			node = H5.instantiate()
			node.init(element)
		"h6":
			node = H6.instantiate()
			node.init(element)
		"pre":
			node = PRE.instantiate()
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
			node = FORM.instantiate()
			node.init(element)

			for child_element in element.children:
				var child_node = create_element_node(child_element)
				if child_node:
					node.add_child(child_node)
		"input":
			node = INPUT.instantiate()
			node.init(element)
		"button":
			node = BUTTON.instantiate()
			node.init(element)
		"span":
			node = SPAN.instantiate()
			node.init(element)
		_:
			return null
	
	return node
