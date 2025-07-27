class_name Main
extends Control

@onready var website_container: Control = %WebsiteContainer
@onready var tab_container: TabManager = $VBoxContainer/TabContainer
const LOADER_CIRCLE = preload("res://Assets/Icons/loader-circle.svg")

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

	<style>
		h1 { text-[#ff0000] font-italic hover:text-[#00ff00] }
		p { text-[#333333] text-2xl }
	</style>
	<style src=\"styles.css\">
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

<p style=\"text-center w-32 h-32\">
So
</p>

<select style=\"text-center max-w-5 max-h-32\">
<option value=\"test1\">Test 1</option>
<option value=\"test2\" selected=\"true\">Test 2</option>
<option value=\"test3\">Test 3</option>
<option value=\"test4\" disabled=\"true\">Test 4</option>
<option value=\"test5\">Test 5</option>
</select>

<textarea />
<textarea cols=\"30\" />
<textarea rows=\"2\" />
<textarea maxlength=\"20\" />
<textarea readonly=\"true\">le skibidi le toilet</textarea>
<textarea disabled=\"true\" value=\"DISABLED\" />
<textarea placeholder=\"this is a placeholder...\" />

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

  <h2>Color</h2>
  <input type=\"color\" value=\"#ff0000\" />
  <h2>Date</h2>
  <input type=\"date\" value=\"2018-07-22\" />

  <h2>Range Slider</h2>
  <input style=\"max-w-2 max-h-2\" type=\"range\" min=\"0\" max=\"100\" step=\"5\" value=\"50\" />
  
  <h2>Number Input</h2>
  <input type=\"number\" min=\"1\" max=\"10\" step=\"0.5\" value=\"5\" placeholder=\"Enter number\" />
  
  <h2>File Upload</h2>
  <input type=\"file\" accept=\".txt,.pdf,image/*\" />

  <input type=\"password\" placeholder=\"your password...\" />
  <button type=\"submit\">Submit</button>
</form>

	<separator direction=\"horizontal\" />
# Ordered list
<ol>
<li>hello gang</li>
<li>this</li>
<li>is</li>
</ol>

<ol type=\"zero-lead\">
<li>hello gang</li>
<li>this</li>
<li>is</li>
<li>a test</li>
</ol>

<ol type=\"lower-alpha\">
<li>hello gang</li>
<li>this</li>
<li>is</li>
<li>a test</li>
</ol>

<ol type=\"upper-alpha\">
<li>hello gang</li>
<li>this</li>
<li>is</li>
<li>a test</li>
</ol>


<ol type=\"lower-roman\">
<li>hello gang</li>
<li>this</li>
<li>is</li>
<li>a test</li>
</ol>

<ol type=\"upper-roman\">
<li>hello gang</li>
<li>this</li>
<li>is</li>
<li>a test</li>
</ol>

<ul>
<li>hello gang</li>
<li>this</li>
<li>is</li>
<li>a test</li>
</ul>

<ul type=\"circle\">
<li>hello gang</li>
<li>this</li>
<li>is</li>
<li>a test</li>
</ul>
<ul type=\"none\">
<li>hello gang</li>
<li>this</li>
<li>is</li>
<li>a test</li>
</ul>
<ul type=\"square\">
<li>hello gang</li>
<li>this</li>
<li>is</li>
<li>a test</li>
</ul>
	<img style=\"text-center max-w-24 max-h-24\" src=\"https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQMNUPIKabszX0Js_c0kfa4cz_JQYKfGTuBUA&s\" />
	<separator direction=\"vertical\" />
</body>".to_utf8_buffer()
	
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

func safe_add_child(parent: Node, child: Node) -> void:
	if child.get_parent():
		child.get_parent().remove_child(child)
	parent.add_child(child)

func parse_size(val):
	if typeof(val) == TYPE_INT or typeof(val) == TYPE_FLOAT:
		return float(val)
	if val.ends_with("px"):
		return float(val.replace("px", ""))
	if val.ends_with("rem"):
		return float(val.replace("rem", "")) * 16.0
	if val.ends_with("%"):
		# Not supported directly, skip
		return null
	return float(val)

func apply_element_styles(node: Control, element: HTMLParser.HTMLElement, parser: HTMLParser) -> Control:
	var styles = parser.get_element_styles(element)
	var label = node if node is RichTextLabel else node.get_node_or_null("RichTextLabel")
	
	var max_width = null
	var max_height = null
	var min_width = null
	var min_height = null
	var width = null
	var height = null

	# Handle width/height/min/max
	if styles.has("width"):
		width = parse_size(styles["width"])
	if styles.has("height"):
		height = parse_size(styles["height"])
	if styles.has("min-width"):
		min_width = parse_size(styles["min-width"])
	if styles.has("min-height"):
		min_height = parse_size(styles["min-height"])
	if styles.has("max-width"):
		max_width = parse_size(styles["max-width"])
	if styles.has("max-height"):
		max_height = parse_size(styles["max-height"])

	# Apply min size
	if min_width != null or min_height != null:
		node.custom_minimum_size = Vector2(
			min_width if min_width != null else node.custom_minimum_size.x,
			min_height if min_height != null else node.custom_minimum_size.y
		)
	# Apply w/h size
	if width != null or height != null:
		node.custom_minimum_size = Vector2(
			width if width != null else node.custom_minimum_size.x,
			height if height != null else node.custom_minimum_size.y
		)
		
		# Set size flags to shrink (without center) so it doesn't expand beyond minimum
		if width != null:
			node.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		if height != null:
			node.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

		if label and label != node:  # If label is a child of node
			label.anchors_preset = Control.PRESET_FULL_RECT
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			label.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Apply max constraints via MaxSizeContainer
	var result_node = node
	if max_width != null or max_height != null:
		var max_container = MaxSizeControl.new()
		max_container.max_size = Vector2(
			max_width if max_width != null else -1,
			max_height if max_height != null else -1
		)

		safe_add_child(website_container, max_container)
		result_node = max_container

	if label:
		apply_styles_to_label(label, styles, element, parser)
	return result_node

func apply_styles_to_label(label: RichTextLabel, styles: Dictionary, element: HTMLParser.HTMLElement, parser) -> void:
	var text = element.get_bbcode_formatted_text(parser) # pass parser
	var font_size = 24  # default
	print("applying styles to: ", text)
	print("applying styles to label: ", label.text, " | styles: ")
	for child in styles:
		print(child)
	
	# Apply font size
	if styles.has("font-size"):
		font_size = int(styles["font-size"])
	
	# Apply color
	var color_tag = ""
	if styles.has("color"):
		var color = styles["color"] as Color
		color_tag = "[color=#%s]" % color.to_html(false)
	
	# Apply background color
	var bg_color_tag = ""
	var bg_color_close = ""
	if styles.has("background-color"):
		var bg_color = styles["background-color"] as Color
		bg_color_tag = "[bgcolor=#%s]" % bg_color.to_html(false)
		bg_color_close = "[/bgcolor]"
	
	# Apply bold
	var bold_open = ""
	var bold_close = ""
	if styles.has("font-bold") and styles["font-bold"]:
		bold_open = "[b]"
		bold_close = "[/b]"
	
	# Apply italic
	var italic_open = ""
	var italic_close = ""
	if styles.has("font-italic") and styles["font-italic"]:
		italic_open = "[i]"
		italic_close = "[/i]"
	# Apply underline
	var underline_open = ""
	var underline_close = ""
	if styles.has("underline") and styles["underline"]:
		underline_open = "[u]"
		underline_close = "[/u]"

	# Apply monospace font
	var mono_open = ""
	var mono_close = ""
	if styles.has("font-mono") and styles["font-mono"]:
		mono_open = "[code]"
		mono_close = "[/code]"

	if styles.has("text-align"):
		match styles["text-align"]:
			"left":
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			"center":
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			"right":
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			"justify":
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_FILL
	# Construct final text
	var styled_text = "[font_size=%d]%s%s%s%s%s%s%s%s%s%s%s%s%s[/font_size]" % [
		font_size,
		bg_color_tag,
		color_tag,
		bold_open,
		italic_open,
		underline_open,
		mono_open,
		text,
		mono_close,
		underline_close,
		italic_close,
		bold_close,
		"[/color]" if color_tag.length() > 0 else "",
		bg_color_close
	]
	
	label.text = styled_text

func contains_hyperlink(element: HTMLParser.HTMLElement) -> bool:
	if element.tag_name == "a":
		return true
	
	for child in element.children:
		if contains_hyperlink(child):
			return true
	
	return false

func create_element_node(element: HTMLParser.HTMLElement, parser: HTMLParser = null) -> Control:
	var node: Control = null
	
	match element.tag_name:
		"p":
			node = P.instantiate()
			node.init(element)
			if parser:
				node = apply_element_styles(node, element, parser)
		"h1":
			node = H1.instantiate()
			node.init(element)
			if parser:
				node = apply_element_styles(node, element, parser)
		"h2":
			node = H2.instantiate()
			node.init(element)
			if parser:
				node = apply_element_styles(node, element, parser)
		"h3":
			node = H3.instantiate()
			node.init(element)
			if parser:
				node = apply_element_styles(node, element, parser)
		"h4":
			node = H4.instantiate()
			node.init(element)
			if parser:
				node = apply_element_styles(node, element, parser)
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
			if parser:
				node = apply_element_styles(node, element, parser)
		"separator":
			node = SEPARATOR.instantiate()
			node.init(element)
		"form":
			node = FORM.instantiate()
			node.init(element)

			for child_element in element.children:
				var child_node = await create_element_node(child_element)
				if child_node:
					node.add_child(child_node)
		"input":
			node = INPUT.instantiate()
			node.init(element)
			if parser:
				node = apply_element_styles(node, element, parser)
		"button":
			node = BUTTON.instantiate()
			node.init(element)
			if parser:
				node = apply_element_styles(node, element, parser)
		"span":
			node = SPAN.instantiate()
			node.init(element)
			if parser:
				node = apply_element_styles(node, element, parser)
		"b":
			node = SPAN.instantiate()
			node.init(element)
			if parser:
				node = apply_element_styles(node, element, parser)
		"i":
			node = SPAN.instantiate()
			node.init(element)
			if parser:
				node = apply_element_styles(node, element, parser)
		"u":
			node = SPAN.instantiate()
			node.init(element)
			if parser:
				node = apply_element_styles(node, element, parser)
		"small":
			node = SPAN.instantiate()
			node.init(element)
			if parser:
				node = apply_element_styles(node, element, parser)
		"mark":
			node = SPAN.instantiate()
			node.init(element)
			if parser:
				node = apply_element_styles(node, element, parser)
		"code":
			node = SPAN.instantiate()
			node.init(element)
			if parser:
				node = apply_element_styles(node, element, parser)
		"a":
			node = SPAN.instantiate()
			node.init(element)
			if parser:
				node = apply_element_styles(node, element, parser)
		"ul":
			node = UL.instantiate()
			website_container.add_child(node)  # Add to scene tree first
			await node.init(element)
			return node  # Return early since we already added it
		"ol":
			node = OL.instantiate()
			website_container.add_child(node)  # Add to scene tree first
			await node.init(element)
			return node  # Return early since we already added it
		"li":
			node = LI.instantiate()
			node.init(element)
			if parser:
				node = apply_element_styles(node, element, parser)
		"select":
			node = SELECT.instantiate()
			node.init(element)
			if parser:
				node = apply_element_styles(node, element, parser)
		"option":
			node = OPTION.instantiate()
			node.init(element)
			if parser:
				node = apply_element_styles(node, element, parser)
		"textarea":
			node = TEXTAREA.instantiate()
			node.init(element)
			if parser:
				node = apply_element_styles(node, element, parser)
		_:
			return null
	
	return node
