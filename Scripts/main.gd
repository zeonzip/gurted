extends Control

func _ready():
	render()

func render():
	var html_bytes = "<head>
	<title>My cool web</title>
	<icon href=\"https://buss.log/icon.ico\"> <!--This image will be the page's icon-->

	<meta name=\"theme-color\" content=\"#000000\">
	<meta name=\"description\" content=\"My cool web\">

	<style href=\"styles.css\">
	<script src=\"script.lua\" />
</head>

<body>
  <h1>Hey there!</h1>
  <img href=\"https://buss.log/rick-astley.png\" />

  <script src=\"script2.lua\" />
</body>".to_utf8_buffer()
	
	# Create parser and parse
	var parser = HTMLParser.new(html_bytes)
	var parse_result = parser.parse()
	
	print("Total elements found: " + str(parse_result.all_elements.size()))
	
	if parse_result.errors.size() > 0:
		print("Parse errors: " + str(parse_result.errors))
	
	# TODO: render the shit on the screen
