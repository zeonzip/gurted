class_name Main
extends Control

@onready var website_container: Control = %WebsiteContainer
@onready var tab_container: TabManager = $VBoxContainer/TabContainer
const LOADER_CIRCLE = preload("res://Assets/Icons/loader-circle.svg")

var loading_tween: Tween

const P = preload("res://Scenes/Tags/p.tscn")
const IMG = preload("res://Scenes/Tags/img.tscn")
const SEPARATOR = preload("res://Scenes/Tags/separator.tscn")
const BOLD = preload("res://Scenes/Tags/bold.tscn")
const ITALIC = preload("res://Scenes/Tags/italic.tscn")
const UNDERLINE = preload("res://Scenes/Tags/underline.tscn")
const SMALL = preload("res://Scenes/Tags/small.tscn")
const MARK = preload("res://Scenes/Tags/mark.tscn")
const CODE = preload("res://Scenes/Tags/code.tscn")
const PRE = preload("res://Scenes/Tags/pre.tscn")
const BR = preload("res://Scenes/Tags/br.tscn")

func render():
	# Clear existing content
	for child in website_container.get_children():
		child.queue_free()
	
	var html_bytes = "<head>
	<title>My cool web</title>
	<icon src=\"https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/768px-Google_%22G%22_logo.svg.png\"> <!--This image will be the page's icon-->

	<meta name=\"theme-color\" content=\"#000000\">
	<meta name=\"description\" content=\"My cool web\">

	<style href=\"styles.css\">
	<script src=\"script.lua\" />
</head>

<body>
	<p>Hey there!       this is a        test</p>
	<b>This is bold</b>
	<i>This is italic</i>
	<u>This is underline</u>
	<small>this is small</small>
	<mark>this is marked</mark>
	<code>this is code</code>
	
	<pre>
Text in a pre element
is displayed in a fixed-width
font, and it preserves
both      spaces and
line breaks
</pre>

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
	tab.set_icon(await Network.fetch_image(icon))
	stop_loading_icon()
	
	var body = parser.find_first("body")
	for element: HTMLParser.HTMLElement in body.children:
		match element.tag_name:
			"p":
				var p = P.instantiate()
				p.init(element)
				website_container.add_child(p)
			"pre":
				var pre = PRE.instantiate()
				pre.init(element)
				website_container.add_child(pre)
			"br":
				var br = BR.instantiate()
				br.init(element)
				website_container.add_child(br)
			"b":
				var bold = BOLD.instantiate()
				bold.init(element)
				website_container.add_child(bold)
			"img":
				var img = IMG.instantiate()
				img.init(element)
				website_container.add_child(img)
			"separator":
				var separator = SEPARATOR.instantiate()
				separator.init(element)
				website_container.add_child(separator)
			"i":
				var italic = ITALIC.instantiate()
				italic.init(element)
				website_container.add_child(italic)
			"u":
				var underline = UNDERLINE.instantiate()
				underline.init(element)
				website_container.add_child(underline)
			"small":
				var small = SMALL.instantiate()
				small.init(element)
				website_container.add_child(small)
			"mark":
				var mark = MARK.instantiate()
				mark.init(element)
				website_container.add_child(mark)
			"code":
				var code = CODE.instantiate()
				code.init(element)
				website_container.add_child(code)
			_:
				print("Couldn't parse unsupported HTML tag \"%s\"" % element.tag_name)

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
