extends Node

const MAIN_COLOR = Color(27/255.0, 27/255.0, 27/255.0, 1)
const SECONDARY_COLOR = Color(43/255.0, 43/255.0, 43/255.0, 1)

const HOVER_COLOR = Color(0, 0, 0, 1)

const DEFAULT_CSS = """
body { text-base text-[#000000] text-left }
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

button { bg-[#1b1b1b] rounded-md text-white hover:bg-[#2a2a2a] active:bg-[#101010] }
"""

var HTML_CONTENT = """<head>
	<title>My Custom Dashboard</title>
	<icon src="https://cdn-icons-png.flaticon.com/512/1828/1828774.png">
	<meta name="theme-color" content="#1a202c">
	<meta name="description" content="A stylish no-script dashboard">

	<font name="roboto" src="https://fonts.gstatic.com/s/roboto/v48/KFO7CnqEu92Fr1ME7kSn66aGLdTylUAMa3KUBGEe.woff2" />

	<style>
		h1 { text-[#ffffff] text-3xl font-bold }
		h2 { text-[#cbd5e1] text-xl }
		p { text-[#94a3b8] text-base }
		button { bg-[#4ade80] text-[#ffffff] hover:bg-[#22c55e] active:bg-[#15803d] }
		.card { bg-[#1e293b] text-[#f8fafc] rounded-xl p-4 shadow-lg }
	</style>
</head>

<body style="bg-[#0f172a] p-8 text-white font-roboto">
	<h1 style="text-center mb-4">📊 My Dashboard</h1>

	<!-- Top Summary Cards -->
	<div style="flex flex-row gap-4 justify-center flex-wrap">
		<div style="card w-48 h-24 flex flex-col justify-center items-center">
			<h2 style="text-red-500">Users</h2>
			<p>1,240</p>
		</div>
		<div style="card w-48 h-24 flex flex-col justify-center items-center">
			<h2>Sales</h2>
			<p>$9,842</p>
		</div>
		<div style="card w-48 h-24 flex flex-col justify-center items-center">
			<h2>Visitors</h2>
			<p>3,590</p>
		</div>
	</div>

	<separator direction="horizontal" />

	<!-- User Info Panel -->
	<h2 style="text-center mt-6">👤 User Panel</h2>
	<div style="flex flex-row gap-4 justify-center mt-2">
		<div style="card w-64">
			<p>Name: Jane Doe</p>
			<p>Email: jane@example.com</p>
			<p>Status: <span style="text-[#22c55e]">Active</span></p>
		</div>
		<div style="card w-64">
			<p>Plan: Pro</p>
			<p>Projects: 8</p>
			<p>Tasks: 42</p>
		</div>
	</div>

	<separator direction="horizontal" />

	<!-- Recent Activity Log -->
	<h2 style="text-center mt-6">📝 Recent Activity</h2>
	<ul style="w-[80%] mt-2 flex justify-center flex-column gap-2">
		<li style="bg-[#334155] px-4 py-2 rounded-xl mb-1">✅ Task "Update UI" marked as complete</li>
		<li style="bg-[#334155] px-4 py-2 rounded-xl mb-1">🔔 New comment on "Bug Fix #224"</li>
		<li style="bg-[#334155] px-4 py-2 rounded-xl mb-1">📤 Exported report "Q2 Metrics"</li>
	</ul>

	<separator direction="horizontal" />

	<!-- Action Buttons -->
	<h2 style="text-center mt-6">🔧 Actions</h2>
	<div style="flex flex-row gap-2 justify-center mt-2">
		<button style="rounded-lg px-4 py-2">Create Report</button>
		<button style="rounded-lg px-4 py-2 bg-[#3b82f6] hover:bg-[#2563eb] active:bg-[#1e40af]">Invite User</button>
		<button style="rounded-lg px-4 py-2 bg-[#facc15] text-[#000] hover:bg-[#eab308] active:bg-[#ca8a04]">Upgrade Plan</button>
	</div>

</body>
""".to_utf8_buffer()
var HTML_CONTENT2 = """<head>
	<title>My cool web</title>
	<icon src=\"https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/768px-Google_%22G%22_logo.svg.png\">

	<meta name=\"theme-color\" content=\"#000000\">
	<meta name=\"description\" content=\"My cool web\">

	<font name="roboto" src="https://fonts.gstatic.com/s/roboto/v48/KFO7CnqEu92Fr1ME7kSn66aGLdTylUAMa3KUBGEe.woff2" />

	<style>
		h1 { text-[#ff0000] font-italic hover:text-[#00ff00] }
		p { text-[#333333] text-2xl }
		button { hover:bg-[#FF6B35] hover:text-[#FFFFFF] active:bg-[#CC5429] active:text-[#F0F0F0] }
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
	
	<separator />
	
	<p>Normal font</p>
	<p style="font-mono">Mono font</p>
	<p style="font-sans">Sans font</p>
	<p style="font-roboto">Custom font - Roboto</p>
	
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
</body>""".to_utf8_buffer()

var HTML_CONTENT3 = """<head>
	<title>Task Manager</title>
	<icon src="https://cdn-icons-png.flaticon.com/512/126/126472.png">

	<meta name="theme-color" content="#1e1e2f">
	<meta name="description" content="Manage your tasks easily.">

	<style>
		h1 { text-[#4ade80] text-3xl font-bold }
		p { text-[#94a3b8] text-lg }
		input { border border-[#cbd5e1] px-2 py-1 rounded }
	</style>

	<script src="logic.lua" />
</head>

<body>
	<h1 style="text-center">📝 My Task Manager</h1>
	<p style="text-center mb-4">Keep track of your to-do list</p>

	<!-- Task List -->
	<div style="flex flex-col gap-2 w-80 mx-auto bg-[#f8fafc] p-4 rounded">
		<span style="flex justify-between items-center bg-[#e2e8f0] px-2 py-1 rounded">
			<span>✅ Finish homework</span>
			<button style="bg-[#4ade80] text-[#ffffff] hover:bg-[#22c55e]">Delete</button>
		</span>
		<span style="flex justify-between items-center bg-[#e2e8f0] px-2 py-1 rounded">
			<span>✍️ Write blog post</span>
			<button style="bg-[#4ade80] text-[#ffffff] hover:bg-[#22c55e]">Delete</button>
		</span>
		<span style="flex justify-between items-center bg-[#e2e8f0] px-2 py-1 rounded">
			<span>💪 Gym workout</span>
			<button style="bg-[#4ade80] text-[#ffffff] hover:bg-[#22c55e]">Delete</button>
		</span>
	</div>

	<separator direction="horizontal" />

	<!-- Add New Task -->
	<h2 style="text-center mt-4">Add a New Task</h2>
	<form action="/add-task" method="POST" style="flex flex-col gap-2 w-80 mx-auto">
		<input type="text" placeholder="Enter task..." minlength="3" required="true" />
		<input type="date" />
		<button type="submit" style="bg-[#4ade80] text-[#ffffff] hover:bg-[#22c55e]">Add Task</button>
	</form>

	<separator direction="horizontal" />

	<h2 style="text-center">Task Categories</h2>
	<div style="flex flex-row gap-2 justify-center items-center w-full">
		<span style="bg-[#fef3c7] px-4 py-2 rounded">📚 Study</span>
		<span style="bg-[#d1fae5] px-4 py-2 rounded">💼 Work</span>
		<span style="bg-[#e0e7ff] px-4 py-2 rounded">🏋️ Health</span>
	</div>

<form>
  <input type=\"password\" placeholder=\"your password...\" />
  <button type=\"submit\" style=\"bg-[#4CAF50] rounded-lg text-[#FFFFFF]\">Submit</button>
  <button style=\"bg-[#2196F3] rounded-xl text-[#FFFFFF]\">Blue Button</button>
  <button style=\"bg-[#FF5722] rounded-full text-[#FFFFFF]\">Orange Pill</button>
  <button style=\"bg-[#9C27B0] rounded-[20px] text-[#FFFFFF]\">Purple Custom</button>
  <button style=\"bg-[#FFD700] rounded text-[#000000] hover:bg-[#FFA500] hover:text-[#FFFFFF]\">Hover Test</button>
</form>

<h2>Button Style Tests</h2>

<button>Normal, no-styling button.</button>

<h3>Corner Radius Variants</h3>
<button style=\"bg-[#E74C3C] text-[#FFFFFF] rounded-none\">No Radius</button>
<button style=\"bg-[#E74C3C] text-[#FFFFFF] rounded-sm\">Small (2px)</button>
<button style=\"bg-[#E74C3C] text-[#FFFFFF] rounded\">Default (4px)</button>
<button style=\"bg-[#E74C3C] text-[#FFFFFF] rounded-md\">Medium (6px)</button>
<button style=\"bg-[#E74C3C] text-[#FFFFFF] rounded-lg\">Large (8px)</button>
<button style=\"bg-[#E74C3C] text-[#FFFFFF] rounded-xl\">Extra Large (12px)</button>
<button style=\"bg-[#E74C3C] text-[#FFFFFF] rounded-2xl\">2XL (16px)</button>
<button style=\"bg-[#E74C3C] text-[#FFFFFF] rounded-3xl\">3XL (24px)</button>
<button style=\"bg-[#E74C3C] text-[#FFFFFF] rounded-full\">Full (Pill)</button>
<button style=\"bg-[#E74C3C] text-[#FFFFFF] rounded-[30px]\">Custom 30px</button>

<h3>Color Combinations</h3>
<button style=\"bg-[#FF6B6B] text-[#FFFFFF] rounded-lg\">Red Background</button>
<button style=\"bg-[#4ECDC4] text-[#2C3E50] rounded-lg\">Teal & Dark Text</button>
<button style=\"bg-[#45B7D1] text-[#FFFFFF] rounded-lg\">Sky Blue</button>
<button style=\"bg-[#96CEB4] text-[#2C3E50] rounded-lg\">Mint Green</button>
<button style=\"bg-[#FFEAA7] text-[#2D3436] rounded-lg\">Yellow Cream</button>
<button style=\"bg-[#DDA0DD] text-[#FFFFFF] rounded-lg\">Plum Purple</button>
<button style=\"bg-[#98D8C8] text-[#2C3E50] rounded-lg\">Seafoam</button>

<h3>Hover Effects</h3>
<button style=\"bg-[#3498DB] text-[#FFFFFF] rounded-lg hover:bg-[#2980B9] hover:text-[#F8F9FA]\">Blue Hover</button>
<button style=\"bg-[#E67E22] text-[#FFFFFF] rounded-xl hover:bg-[#D35400] hover:text-[#ECF0F1]\">Orange Hover</button>
<button style=\"bg-[#9B59B6] text-[#FFFFFF] rounded-full hover:bg-[#8E44AD] hover:text-[#F4F4F4]\">Purple Pill Hover</button>
<button style=\"bg-[#1ABC9C] text-[#FFFFFF] rounded-2xl hover:bg-[#16A085]\">Turquoise Hover</button>

<h3>Advanced Hover Combinations</h3>
<button style=\"bg-[#34495E] text-[#ECF0F1] rounded hover:bg-[#E74C3C] hover:text-[#FFFFFF]\">Dark to Red</button>
<button style=\"bg-[#F39C12] text-[#2C3E50] rounded-lg hover:bg-[#27AE60] hover:text-[#FFFFFF]\">Gold to Green</button>
<button style=\"bg-[#FFFFFF] text-[#2C3E50] rounded-xl hover:bg-[#2C3E50] hover:text-[#FFFFFF]\">Light to Dark</button>

<h3>Text Color Focus</h3>
<button style=\"text-[#E74C3C] rounded-lg\">Red Text Only</button>
<button style=\"text-[#27AE60] rounded-lg\">Green Text Only</button>
<button style=\"text-[#3498DB] rounded-lg\">Blue Text Only</button>
<button style=\"text-[#9B59B6] rounded-full\">Purple Text Pill</button>

<h3>Mixed Styles</h3>
<button style=\"bg-[#FF7675] text-[#FFFFFF] rounded-[15px] hover:bg-[#FD79A8] hover:text-[#2D3436]\">Custom Mix 1</button>
<button style=\"bg-[#6C5CE7] text-[#DDD] rounded-3xl hover:bg-[#A29BFE] hover:text-[#2D3436]\">Custom Mix 2</button>
<button style=\"bg-[#00B894] text-[#FFFFFF] rounded-[25px] hover:bg-[#00CEC9] hover:text-[#2D3436]\">Custom Mix 3</button>
<button style=\"bg-[#0000ff] text-[#FFFFFF] rounded-[25px] hover:bg-[#ff0000] hover:text-[#2D3436]\">Blue normal, red hover</button>

<h3>Active State Tests</h3>
<button style=\"bg-[#3498DB] text-[#FFFFFF] rounded-lg hover:bg-[#2980B9] active:bg-[#1F618D] active:text-[#F8F9FA]\">Blue with Active</button>
<button style=\"bg-[#E74C3C] text-[#FFFFFF] rounded-xl hover:bg-[#C0392B] active:bg-[#A93226] active:text-[#ECF0F1]\">Red with Active</button>
<button style=\"bg-[#27AE60] text-[#FFFFFF] rounded-full hover:bg-[#229954] active:bg-[#1E8449] active:text-[#D5DBDB]\">Green Pill Active</button>
<button style=\"bg-[#F39C12] text-[#2C3E50] rounded hover:bg-[#E67E22] hover:text-[#FFFFFF] active:bg-[#D35400] active:text-[#F7F9FC]\">Gold Multi-State</button>
<button style=\"bg-[#9B59B6] text-[#FFFFFF] rounded-2xl active:bg-[#7D3C98] active:text-[#E8DAEF]\">Purple Active Only</button>

</body>
""".to_utf8_buffer()
