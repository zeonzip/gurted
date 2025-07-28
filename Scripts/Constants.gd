extends Node

const MAIN_COLOR = Color(27/255.0, 27/255.0, 27/255.0, 1)
const SECONDARY_COLOR = Color(43/255.0, 43/255.0, 43/255.0, 1)

const HOVER_COLOR = Color(0, 0, 0, 1)

const DEFAULT_CSS = """
h1 { text-5xl font-bold }
h2 { text-4xl font-bold }
h3 { text-3xl font-bold }
h4 { text-2xl font-bold }
h5 { text-xl font-bold }
b { font-bold }
i { font-italic }
u { underline }
small { text-xl }
mark { bg-[#FFFF00] }
code { text-xl font-mono }
a { text-[#1a0dab] }
pre { text-xl font-mono }
"""

var HTML_CONTENT = "<head>
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

	<!-- FLEXBOX EXAMPLES -->
	<h2>Flex Row (gap, justify-between, items-center)</h2>
	<div style=\"flex flex-row gap-4 justify-between items-center w-64 h-16 bg-[#f0f0f0]\">
		<span style=\"bg-[#ffaaaa] w-16 h-8 flex items-center justify-center\">A</span>
		<span style=\"bg-[#aaffaa] w-16 h-8 flex items-center justify-center\">B</span>
		<span style=\"bg-[#aaaaff] w-16 h-8 flex items-center justify-center\">C</span>
	</div>

	<h2>Flex Column (gap, items-center, content-center)</h2>
	<div style=\"flex flex-col gap-2 items-center content-center h-32 w-32 bg-[#e0e0e0]\">
		<span style=\"bg-[#ffaaaa] w-16 h-6 flex items-center justify-center\">1</span>
		<span style=\"bg-[#aaffaa] w-16 h-6 flex items-center justify-center\">2</span>
		<span style=\"bg-[#aaaaff] w-16 h-6 flex items-center justify-center\">3</span>
	</div>

	<h2>Flex Wrap (row, wrap, gap)</h2>
	<div style=\"flex flex-row flex-wrap gap-2 w-40 bg-[#f8f8f8]\">
		<span style=\"bg-[#ffaaaa] w-16 h-6 flex items-center justify-center\">X</span>
		<span style=\"bg-[#aaffaa] w-16 h-6 flex items-center justify-center\">Y</span>
		<span style=\"bg-[#aaaaff] w-16 h-6 flex items-center justify-center\">Z</span>
		<span style=\"bg-[#ffffaa] w-16 h-6 flex items-center justify-center\">W</span>
	</div>

	<h2>Flex Grow/Shrink/Basis</h2>
	<div style=\"flex flex-row gap-2 w-64 bg-[#f0f0f0]\">
		<span style=\"bg-[#ffaaaa] flex-grow-1 h-8 flex items-center justify-center\">Grow 1</span>
		<span style=\"bg-[#aaffaa] flex-grow-2 h-8 flex items-center justify-center\">Grow 2</span>
		<span style=\"bg-[#aaaaff] flex-shrink-0 w-8 h-8 flex items-center justify-center\">No Shrink</span>
	</div>

	<h2>Align Self</h2>
	<div style=\"flex flex-row h-24 bg-[#f0f0f0] items-stretch gap-2 w-64\">
		<span style=\"bg-[#ffaaaa] w-12 h-8 self-start flex items-center justify-center\">Start</span>
		<span style=\"bg-[#aaffaa] w-12 h-8 self-center flex items-center justify-center\">Center</span>
		<span style=\"bg-[#aaaaff] w-12 h-8 self-end flex items-center justify-center\">End</span>
		<span style=\"bg-[#ffffaa] w-12 h-8 self-stretch flex items-center justify-center\">Stretch</span>
	</div>
</body>".to_utf8_buffer()
