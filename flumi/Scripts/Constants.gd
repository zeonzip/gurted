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

button { text-[16px] bg-[#1b1b1b] rounded-md text-white hover:bg-[#2a2a2a] active:bg-[#101010] }
button[disabled] { bg-[#666666] text-[#999999] cursor-not-allowed }
"""

var HTML_CONTENT2 = """<head>
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
var HTML_CONTENTvv = """<head>
	<title>My cool web</title>
	<icon src=\"https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/768px-Google_%22G%22_logo.svg.png\">

	<meta name=\"theme-color\" content=\"#000000\">
	<meta name=\"description\" content=\"My cool web\">

	<font name="roboto" src="https://fonts.gstatic.com/s/roboto/v48/KFO7CnqEu92Fr1ME7kSn66aGLdTylUAMa3KUBGEe.woff2" />

	<style>
		h1 { text-[#ff0000] font-italic hover:text-[#00ff00] }
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
	<a href="https://youtube.com">Hello gang</a>
	</p>

	<pre>
Text in a pre element
is displayed in a fixed-width
font, and it preserves
both      spaces and
line breaks
	</pre>
	
	<p style="text-center w-32 h-32">
	So
	</p>

	<div>
		<button style="rounded-lg px-4 py-2 cursor-pointer">Create Report</button>
		<button style="rounded-lg px-4 py-2 bg-[#3b82f6] hover:bg-[#2563eb] active:bg-[#1e40af] cursor-pointer">Invite User</button>
		<button style="rounded-lg px-4 py-2 bg-[#facc15] text-[#000] hover:bg-[#eab308] active:bg-[#ca8a04] cursor-pointer">Upgrade Plan</button>
	</div>
	<button disabled="true">Disabled Button</button>
	<button>Normal Button</button>

	<separator direction="horizontal" />

	<!-- Test CSS Properties -->
	<h2 style="text-center mt-6">🧪 CSS Properties Test</h2>
	<div style="flex flex-col gap-2 justify-center items-center mt-2">
		<div style="bg-[#ef4444] text-white p-4 rounded-lg opacity-75 z-10 cursor-pointer">
			<p>Opacity 75% with cursor pointer and z-index 10 - Text should show pointer cursor, not I-beam</p>
		</div>
		<div style="bg-[#10b981] text-white p-4 rounded-lg opacity-50 z-20 cursor-text">
			<p>Opacity 50% with cursor text and z-index 20 - Text should show I-beam cursor</p>
		</div>
		<div style="bg-[#8b5cf6] text-white p-4 rounded-lg opacity-[0.25] z-[999] cursor-default">
			<p>Custom opacity 0.25 with cursor default and z-index 999 - Text should show arrow cursor</p>
		</div>
		<div style="bg-[#f59e0b] text-white p-2 rounded cursor-move">
			<p>Cursor move - Text should show move cursor</p>
		</div>
		<div style="bg-[#06b6d4] text-white p-2 rounded cursor-crosshair">
			<p>Cursor crosshair - Text should show crosshair cursor</p>
		</div>
		<div style="bg-[#84cc16] text-white p-2 rounded cursor-help">
			<p>Cursor help - Text should show help cursor</p>
		</div>
		<div style="bg-[#ec4899] text-white p-2 rounded cursor-not-allowed">
			<p>Cursor not-allowed - Text should show forbidden cursor</p>
		</div>
	</div>
	
	<separator direction="horizontal" />
	
	<!-- Test cursor inheritance -->
	<h2 style="text-center mt-6">🖱️ Cursor Inheritance Test</h2>
	<div style="cursor-pointer bg-[#1e293b] p-4 rounded-lg">
		<p>This paragraph is inside a div with cursor-pointer.</p>
		<p>Both paragraphs should show pointer cursor instead of default I-beam.</p>
		<div style="bg-[#334155] p-2 rounded mt-2">
			<p>This nested paragraph should also inherit the pointer cursor.</p>
		</div>
	</div>

	<!-- Border examples -->
	<div style="border p-2 mb-2">border</div>
	<div style="border-2 p-2 mb-2">border-2</div>
	<div style="border-4 p-2 mb-2">border-4</div>
	<div style="border-2 border-red-500 p-2 mb-2">border-2 border-red-500</div>
	<div style="border p-2 mb-2">border-solid</div>
	<div style="border border-dashed p-2 mb-2">border-dashed</div>
	<div style="border border-dotted p-2 mb-2">border-dotted</div>
	<div style="border-none p-2 mb-2">border-none</div>
	<div style="border-t p-2 mb-2">border-t</div>
	<div style="border-r p-2 mb-2">border-r</div>
	<div style="border-b p-2 mb-2">border-b</div>
	<div style="border-l p-2 mb-2">border-l</div>
	<div style="border-t-4 p-2 mb-2">border-t-4</div>
	<div style="border-b-2 p-2 mb-2">border-b-2</div>
	<div style="border-l-6 p-2 mb-2">border-l-6</div>
	<div style="border-t-3 border-green-500 p-2 mb-2">border-t-3 border-green-500</div>
	<div style="border border-white p-2 mb-2">border-white</div>
	<div style="border border-black p-2 mb-2">border-black</div>
	<div style="border border-transparent p-2 mb-2">border-transparent</div>
	<div style="border border-gray-400 p-2 mb-2">border-gray-400</div>
	<div style="border border-slate-700 p-2 mb-2">border-slate-700</div>
	<div style="border border-red-500 p-2 mb-2">border-red-500</div>
	<div style="border border-green-600 p-2 mb-2">border-green-600</div>
	<div style="border border-blue-400 p-2 mb-2">border-blue-400</div>
	<div style="border border-yellow-300 p-2 mb-2">border-yellow-300</div>

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

var HTML_CONTENT_S = """<head>
	<title>CSS Selector Tests</title>
	<style>
		/* Descendant selectors */
		div p { text-[#663399] }
		.container span { bg-[#ffeeaa] }
		
		/* Direct child selectors */
		.outer-div > p { font-bold }
		.parent > button { bg-[#44cc88] }
		
		/* Adjacent sibling selectors */
		h1 + p { text-[#ff0000] font-bold }
		h2 + div { bg-[#eeffee] }
		
		/* General sibling selectors */
		h1 ~ p { text-[#0000ff] }
		h1 ~ .second-p { text-[#0000ff] }
		h3 ~ span { bg-[#ffdddd] }
		
		/* Attribute selectors */
		input[type="text"] { border border-[#cccccc] bg-[#f9f9f9] }
		a[href^="https"] { text-[#008000] font-bold }
		button[disabled] { bg-[#888888] text-[#cccccc] }
		input[placeholder*="email"] { border-2 border-[#0066cc] bg-[#ffffff] }
		div[style$="special"] { bg-[#ffffaa] }
	</style>
</head>

<body>
	<h1>CSS Selector Test Page</h1>
	<p>This paragraph should be red and bold (h1 + p)</p>
	<p style="second-p">This paragraph should be blue (h1 ~ p)</p>
	
	<h2>Descendant vs Child Selectors</h2>
	<div style="outer-div">
		<p>This paragraph should be purple and bold (div p and .outer-div > p)</p>
		<div>
			<p>This paragraph should be purple but not bold (div p only)</p>
		</div>
	</div>
	
	<h3>Attribute Selectors</h3>
	<input type="text" placeholder="Enter your name" />
	<input type="text" placeholder="Enter your email address" />
	<input type="password" placeholder="Enter password" />
	
	<br />
	<a href="http://example.com">HTTP Link (normal)</a>
	<br />
	<a href="https://secure.com">HTTPS Link (green and bold)</a>
	
	<br />
	<button>Normal Button</button>
	<button disabled="true">Disabled Button (gray)</button>
	
	<h3>Sibling Selectors</h3>
	<div style="bg-[#eeffee]">This div should have light green bg (h2 + div)</div>
	<span>This span should have light red bg (h3 ~ span)</span>
	<span>This span should also have light red bg (h3 ~ span)</span>
	
	<div style="container">
		<span>This span should have yellow bg (.container span)</span>
		<p>Regular paragraph in container</p>
	</div>
	
	<div style="parent">
		<button>This button should be green (.parent > button)</button>
		<div>
			<button>This button should be normal (not direct child)</button>
		</div>
	</div>
	
	<div style="item-special">This div should have yellow bg (class ends with 'special')</div>
	<div style="special-item">This div should be normal</div>
</body>
""".to_utf8_buffer()

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

var HTML_CONTENTvvv = """
<head>
	<title>Lua API Demo</title>
	<icon src="https://upload.wikimedia.org/wikipedia/commons/thumb/c/cf/Lua-Logo.svg/256px-Lua-Logo.svg.png">
	<meta name="theme-color" content="#000080">
	<meta name="description" content="Demonstrating the GURT Lua API">
	
	<style>
		body { bg-[#f8f9fa] p-6 }
		h1 { text-[#2563eb] text-2xl font-bold }
		.container { bg-[#ffffff] p-4 rounded-lg shadow-lg }
		.demo-button { bg-[#3b82f6] text-white px-4 py-2 rounded hover:bg-[#2563eb] }
		.fancy { bg-green-500 text-red-500 p-2 rounded-full mt-2 mb-2 text-2xl hover:bg-red-300 hover:text-[#2563eb] }
	</style>
	
	<script>
		local typing = gurt.select('#type')
		local mouse = gurt.select('#mouse')
		local btnmouse = gurt.select('#btnmouse')
		
		gurt.log('Starting Lua script execution...')
		
		gurt.body:on('keypress', function(el)
			typing.text = table.tostring(el)
		end)
		
		gurt.body:on('mousemove', function(el)
			mouse.text = table.tostring(el)
		end)

		-- Test element selection and manipulation
		local heading = gurt.select('#main-heading')
		heading.text = 'Welcome to the New Web!'
		
		local button = gurt.select('#demo-button')
		local event_log = gurt.select('#event-log')
		
		button:on('mousedown', function()
			print('Mouse down')
		end)
		
		button:on('mouseup', function()
			print('Mouse up')
		end)
		
		button:on('mouseenter', function()
			print('Mouse enter')
		end)
		
		button:on('mouseexit', function()
			print('Mouse exit')
		end)
		
		button:on('mousemove', function(el)
			btnmouse.text = table.tostring(el)
		end)
		
		if button and event_log then
			local click_count = 0
			
			local subscription = button:on('click', function()
				click_count = click_count + 1
				local new_text = 'Button clicked ' .. click_count .. ' time(s)!'
				event_log.text = new_text
			end)
			
			heading:on('focusin', function()
				print('oh u flck')
				subscription:unsubscribe()
			end)
			
			gurt.log('Event listener attached to button with subscription ID')
		else
			gurt.log('Could not find button or event log element')
		end
		
		-- DOM Manipulation Demo
		gurt.log('Testing DOM manipulation...')
		
		-- Create a new div with styling
		local new_div = gurt.create('div', { style = 'bg-red-500 p-4 rounded-lg mb-4' })
		
		-- Create a paragraph with text
		local new_p = gurt.create('p', { 
			style = 'text-white font-bold text-lg', 
			text = 'This element was created dynamically with Lua!' 
		})
		
		-- Append paragraph to div
		new_div:append(new_p)
		
		-- Append div to body
		gurt.body:append(new_div)
		
		-- Create another element to test removal
		local temp_element = gurt.create('div', {
			style = 'bg-yellow-400 p-2 rounded text-black',
			text = 'This will be removed in 3 seconds...'
		})
		gurt.body:append(temp_element)
		
		local test = gurt.setTimeout(function()
			print('removed')
			temp_element:remove()
		end, 3000)
		
		-- gurt.clearTimeout(test)
		
		local addBtn = gurt.select('#add-class')
		local removeBtn = gurt.select('#remove-class')
		local btnTarget = gurt.select('#btnTarget')

		addBtn:on('click', function()
			btnTarget.classList:add('fancy')
			-- btnTarget.classList:toggle('fancy')
			print('Class added')
		end)

		removeBtn:on('click', function()
			btnTarget.classList:remove('fancy')
			print('Class removed')
		end)
	</script>
</head>

<body>
	<h1 id="main-heading">Welcome to GURT Lua API Demo</h1>
	
	<div style="container">
		<p>This page demonstrates the GURT Lua API in action.</p>
		<div id="demo-button" style="w-40 h-40 bg-red-500 p-4 rounded-lg">Click me to see Lua in action!</div>
	</div>
	
	<p id="event-log" style="mt-4 p-4 bg-[#f3f4f6] rounded min-h-24">Click the button</p>
	
	<p id="mouse" style="mt-4 p-4 bg-[#f3f4f6] rounded min-h-24">Move your mouse</p>
	
	<p id="btnmouse" style="mt-4 p-4 bg-[#f3f4f6] rounded min-h-24">Move mouse over Button</p>
	
	<p id="type" style="mt-4 p-4 bg-[#f3f4f6] rounded min-h-24">Type something</p>
	
	<div style="mt-6 flex gap-4 items-center">
	<div style="text-lg font-semibold">Style Controls:</div>
	<button id="add-class" style="bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700">Add Class</button>
	<button id="remove-class" style="bg-red-600 text-white px-4 py-2 rounded hover:bg-red-700">Remove Class</button>
</div>
	<button id="btnTarget" style="bg-gray-600">Button</button>

</body>""".to_utf8_buffer()

var HTML_CONTENT_ADD_REMOVE = """<head>
	<title>Lua List Manipulation Demo</title>
	<icon src="https://upload.wikimedia.org/wikipedia/commons/thumb/c/cf/Lua-Logo.svg/256px-Lua-Logo.svg.png">
	<meta name="theme-color" content="#000080">
	<meta name="description" content="Adding and popping list items with GURT Lua API">

	<style>
		body { bg-[#f8f9fa] p-6 }
		h1 { text-[#2563eb] text-4xl font-bold }
		.container { flex flex-row bg-[#ffffff] p-4 rounded-lg shadow-lg }
		.demo-button { bg-[#3b82f6] text-white px-4 py-2 rounded hover:bg-[#2563eb] cursor-pointer }
		ul { list-disc pl-6 }
		li { text-[#111827] py-1 }
	</style>

	<script>
		local add_button = gurt.select('#add-button')
		local pop_button = gurt.select('#pop-button')
		local list = gurt.select('#item-list')
		local counter = 1

		gurt.log('List manipulation script started.')

		add_button:on('click', function()
			local new_item = gurt.create('li', {
				text = 'Item #' .. counter
			})
			list:append(new_item)
			counter = counter + 1
		end)

		pop_button:on('click', function()
			local items = list.children
			local last = items[#items]
			if last then
				last:remove()
				counter = math.max(1, counter - 1)
			end
		end)
	</script>
</head>

<body>
	<h1 id="main-heading">List Manipulation with Lua</h1>

	<div style="container">
		<p>Use the buttons below to add or remove items from the list:</p>
		<button id="add-button" style="demo-button inline-block mr-2">Add Item</button>
		<button id="pop-button" style="demo-button inline-block">Pop Item</button>
	</div>

	<ul id="item-list" style="mt-4 bg-[#f3f4f6] p-4 rounded min-h-24">
		<!-- List items will appear here -->
	</ul>
</body>
""".to_utf8_buffer()

var HTML_CONTENT_DOM_MANIPULATION = """
<head>
	<title>DOM Utilities Test</title>
	<style>
		.test-item { bg-[#e0e7ef] text-[#22223b] rounded p-2 mb-2 }
		.highlight { bg-[#ffd700] }
	</style>
	<script>
		local log = gurt.select("#log")
		local function log_msg(msg)
			log.text = log.text .. msg .. "\\n"
		end

		local parent = gurt.select("#parent")
		local child1 = gurt.select("#child1")
		local child2 = gurt.select("#child2")
		local child3 = gurt.select("#child3")
		print(log)
		-- Show DOM property usage
		log.text = ""
		log_msg("parent of child2: " .. table.tostring(child2.parent))
		log_msg("nextSibling of child2: " .. table.tostring(child2.nextSibling))
		log_msg("previousSibling of child2: " .. table.tostring(child2.previousSibling))
		log_msg("firstChild of parent: " .. table.tostring(parent.firstChild))
		log_msg("lastChild of parent: " .. table.tostring(parent.lastChild))

		-- Insert Before
		gurt.select("#btn-insert-before"):on("click", function()
			local newDiv = gurt.create("div", { class = "test-item highlight", text = "Inserted Before Child 2" })
			parent:insertBefore(newDiv, child2)
			log_msg("Inserted before child2: " .. newDiv._element_id)
		end)

		-- Insert After
		gurt.select("#btn-insert-after"):on("click", function()
			local newDiv = gurt.create("div", { class = "test-item highlight", text = "Inserted After Child 2" })
			parent:insertAfter(newDiv, child2)
			log_msg("Inserted after child2: " .. newDiv._element_id)
		end)

		-- Replace
		gurt.select("#btn-replace"):on("click", function()
			local newDiv = gurt.create("div", { class = "test-item highlight", text = "Replacement for Child 2" })
			parent:replace(newDiv, child2)
			log_msg("Replaced child2 with: " .. newDiv._element_id)
		end)

		-- Clone
		gurt.select("#btn-clone"):on("click", function()
			local clone = child3:clone(true)
			parent:append(clone)
			log_msg("Cloned child3: " .. clone._element_id)
		end)
</script>
</head>
<body>
	<h1>DOM Utilities Demo</h1>
	<div id="parent" style="bg-[#f8fafc] p-4 rounded flex flex-col gap-2">
		<div class="test-item">Non-interactible</div>
		<div id="child1" class="test-item">Child 1</div>
		<div id="child2" class="test-item">Child 2</div>
		<div id="child3" class="test-item">Child 3</div>
	</div>
	<div style="flex gap-2 mt-4">
		<button id="btn-insert-before">Insert Before Child 2</button>
		<button id="btn-insert-after">Insert After Child 2</button>
		<button id="btn-replace">Replace Child 2</button>
		<button id="btn-clone">Clone Child 3</button>
	</div>
	<p id="log" style="mt-4 text-[#444] text-sm">Test</p>
</body>
""".to_utf8_buffer()

var HTML_CONTENT = """<head>
	<title>Signal API Demo</title>
	<icon src="https://upload.wikimedia.org/wikipedia/commons/thumb/c/cf/Lua-Logo.svg/256px-Lua-Logo.svg.png">
	<meta name="theme-color" content="#8b5cf6">
	<meta name="description" content="Demonstrating the new Signal API with custom events">

	<style>
		body { bg-[#f8fafc] p-6 }
		h1 { text-[#8b5cf6] text-3xl font-bold text-center }
		h2 { text-[#6d28d9] text-xl font-semibold }
		.container { bg-[#ffffff] p-6 rounded-lg shadow-lg max-w-4xl mx-auto }
		.button-group { flex gap-3 justify-center items-center flex-wrap }
		.signal-button { px-4 py-2 rounded-lg font-medium cursor-pointer transition-colors }
		.fire-btn { bg-[#10b981] text-white hover:bg-[#059669] }
		.connect-btn { bg-[#3b82f6] text-white hover:bg-[#2563eb] }
		.disconnect-btn { bg-[#ef4444] text-white hover:bg-[#dc2626] }
		.log-area { bg-[#f1f5f9] p-4 rounded-lg min-h-32 font-mono text-sm }
		.status-display { bg-[#ddd6fe] p-3 rounded-md text-[#5b21b6] font-mono }
		.info-box { bg-[#fef3c7] border border-[#f59e0b] p-4 rounded-lg }
	</style>

	<script>
		-- Create custom signals
		local mySignal = Signal.new()
		local dataSignal = Signal.new()
		local userActionSignal = Signal.new()
		print(".container > div: ", gurt.selectAll('.container > div'))
		print(".container div: ", gurt.selectAll('.container div'))
		print("button[disabled]: ", gurt.selectAll('button[disabled]'))
		print(".container: ", gurt.selectAll('.container'))
		print("#log-area: ", gurt.selectAll('#log-area'))
		-- Get UI elements
		local logArea = gurt.select('#log-area')
		local statusDisplay = gurt.select('#status-display')
		local connectBtn = gurt.select('#connect-btn')
		local disconnectBtn = gurt.select('#disconnect-btn')
		local fireBtn = gurt.select('#fire-btn')
		local fireDataBtn = gurt.select('#fire-data-btn')
		local clearLogBtn = gurt.select('#clear-log-btn')

		gurt.log('Signal API demo script started.')

		local logMessages = {}
		local connectionCount = 0
		local activeConnections = {}

		-- Function to add message to log
		local function addLog(message)
			table.insert(logMessages, Time.format(Time.now(), '%H:%M:%S') .. ' - ' .. message)
			if #logMessages > 20 then
				table.remove(logMessages, 1)
			end
			logArea.text = table.concat(logMessages, '\\n')
		end

		-- Function to update status
		local function updateStatus()
			statusDisplay.text = 'Active Connections: ' .. #activeConnections .. '\\nTotal Events Fired: ' .. connectionCount
		end

		-- Signal handlers
		local function onMySignal(arg1, arg2)
			addLog('mySignal fired with args: ' .. (arg1 or 'nil') .. ', ' .. (arg2 or 'nil'))
		end

		local function onDataSignal(data)
			addLog('dataSignal received: ' .. table.tostring(data))
		end

		local function onUserAction(action, timestamp)
			addLog('userActionSignal: ' .. action .. ' at ' .. timestamp)
		end

		-- Connect button
		connectBtn:on('click', function()
			-- Connect multiple handlers to demonstrate multiple connections
			local conn1 = mySignal:connect(onMySignal)
			local conn2 = dataSignal:connect(onDataSignal)
			local conn3 = userActionSignal:connect(onUserAction)
			
			table.insert(activeConnections, conn1)
			table.insert(activeConnections, conn2)
			table.insert(activeConnections, conn3)
			
			addLog('Connected 3 signal handlers')
			updateStatus()
		end)

		-- Disconnect button
		disconnectBtn:on('click', function()
			for i = 1, #activeConnections do
				activeConnections[i]:disconnect()
			end
			activeConnections = {}
			addLog('Disconnected all signal handlers')
			updateStatus()
		end)

		-- Fire simple signal
		fireBtn:on('click', function()
			mySignal:fire('Hello', 123)
			connectionCount = connectionCount + 1
			addLog('Fired mySignal with two arguments')
			updateStatus()
		end)

		-- Fire data signal
		fireDataBtn:on('click', function()
			local sampleData = {
				user = 'Alice',
				score = math.random(100, 999),
				items = {'sword', 'shield', 'potion'}
			}
			dataSignal:fire(sampleData)
			connectionCount = connectionCount + 1
			addLog('Fired dataSignal with complex data')
			updateStatus()
		end)

		-- Fire user action signal
		gurt.body:on('keypress', function(keyInfo)
			if #activeConnections > 0 then
				userActionSignal:fire('keypress: ' .. keyInfo.key, Time.format(Time.now(), '%H:%M:%S'))
				connectionCount = connectionCount + 1
				updateStatus()
			end
		end)

		-- Clear log button  
		clearLogBtn:on('click', function()
			logMessages = {}
			logArea.text = 'Log cleared.'
			addLog('Log area cleared')
		end)

		-- Initialize with some sample connections
		local initialConn = mySignal:connect(function(a, b)
			addLog('Initial handler triggered with: ' .. (a or 'nil') .. ', ' .. (b or 'nil'))
		end)
		table.insert(activeConnections, initialConn)
		
		addLog('Signal API demo initialized')
		addLog('Try connecting handlers and firing signals!')
		addLog('Press any key to trigger userActionSignal (when connected)')
		updateStatus()
	</script>
</head>

<body>
	<h1>🔔 Signal API Demo</h1>
	
	<div style="container mt-6">
		<div style="info-box mb-6">
			<p><strong>Signal API Usage Example:</strong></p>
			<p><code>local mySignal = Signal.new()</code></p>
			<p><code>mySignal:connect(function(arg1, arg2) print("Event fired with: ", arg1, arg2) end)</code></p>
			<p><code>mySignal:fire("Hello", 123)</code></p>
			<p><code>connection:disconnect()</code></p>
		</div>

		<h2>Controls</h2>
		<div style="button-group mb-6">
			<button id="connect-btn" style="signal-button connect-btn">🔗 Connect Handlers</button>
			<button id="disconnect-btn" style="signal-button disconnect-btn">❌ Disconnect All</button>
			<button id="fire-btn" style="signal-button fire-btn">🔔 Fire Simple Signal</button>
			<button id="fire-data-btn" style="signal-button fire-btn">📊 Fire Data Signal</button>
			<button id="clear-log-btn" style="signal-button">🧹 Clear Log</button>
		</div>

		<h2>Status</h2>
		<div style="status-display mb-6">
			<pre id="status-display">Loading status...</pre>
		</div>

		<h2>Event Log</h2>
		<div style="log-area mb-6">
			<pre id="log-area">Initializing...</pre>
		</div>

		<div style="bg-[#e0f2fe] p-4 rounded-lg">
			<h3 style="text-[#0277bd] font-semibold mb-2">Signal API Features:</h3>
			<ul style="text-[#01579b] space-y-1">
				<li><strong>Signal.new():</strong> Creates a new signal object</li>
				<li><strong>signal:connect(callback):</strong> Connects a callback function and returns a connection object</li>
				<li><strong>signal:fire(...):</strong> Fires the signal with optional arguments</li>
				<li><strong>connection:disconnect():</strong> Disconnects a specific connection</li>
				<li><strong>signal:disconnect():</strong> Disconnects all connections from the signal</li>
				<li><strong>Multiple Connections:</strong> One signal can have multiple connected callbacks</li>
				<li><strong>Argument Passing:</strong> Signals can pass multiple arguments to connected callbacks</li>
			</ul>
		</div>
	<button disabled="true">Test</button>
	<button disabled="true">Test2</button>
	</div>
</body>
""".to_utf8_buffer()

var HTML_CONTENTa = """<head>
	<title>Button getAttribute/setAttribute Demo</title>
	<icon src="https://upload.wikimedia.org/wikipedia/commons/thumb/c/cf/Lua-Logo.svg/256px-Lua-Logo.svg.png">
	<meta name="theme-color" content="#3b82f6">
	<meta name="description" content="Demonstrating getAttribute and setAttribute with button controls">

	<style>
		body { bg-[#f8fafc] p-6 }
		h1 { text-[#3b82f6] text-3xl font-bold text-center }
		h2 { text-[#1e40af] text-xl font-semibold }
		.container { bg-[#ffffff] p-6 rounded-lg shadow-lg max-w-4xl mx-auto }
		.button-group { flex gap-3 justify-center items-center flex-wrap }
		.control-button { px-4 py-2 rounded-lg font-medium cursor-pointer transition-colors }
		.enable-btn { bg-[#10b981] text-white hover:bg-[#059669] }
		.disable-btn { bg-[#ef4444] text-white hover:bg-[#dc2626] }
		.toggle-btn { bg-[#8b5cf6] text-white hover:bg-[#7c3aed] }
		.status-btn { bg-[#6b7280] text-white hover:bg-[#4b5563] }
		.demo-buttons { bg-[#f1f5f9] p-4 rounded-lg }
		.status-display { bg-[#e0e7ff] p-3 rounded-md text-[#3730a3] font-mono }
		.info-box { bg-[#fef3c7] border border-[#f59e0b] p-4 rounded-lg }
		.target-button { bg-[#3b82f6] text-white px-6 py-3 rounded-lg font-semibold hover:bg-[#2563eb] }
		.target-button[disabled] { bg-[#9ca3af] text-[#6b7280] cursor-not-allowed }
	</style>

	<script>
		local targetButton = gurt.select('#target-button')
		local enableBtn = gurt.select('#enable-btn')
		local disableBtn = gurt.select('#disable-btn')
		local toggleBtn = gurt.select('#toggle-btn')
		local statusBtn = gurt.select('#status-btn')
		local statusDisplay = gurt.select('#status-display')
		local infoBox = gurt.select('#info-box')
		local clickCounter = gurt.select('#click-counter')

		gurt.log('Button attribute demo script started.')

		local clickCount = 0

		-- Function to update the status display
		local function updateStatus()
			local disabled = targetButton:getAttribute('disabled')
			local type = targetButton:getAttribute('type')
			local style = targetButton:getAttribute('style')
			local id = targetButton:getAttribute('id')
			local dataValue = targetButton:getAttribute('data-value')
			
			local status = 'Status: ' .. (disabled and 'DISABLED' or 'ENABLED') .. '\\n'
			status = status .. 'Type: ' .. (type or 'button') .. '\\n'
			status = status .. 'ID: ' .. (id or 'none') .. '\\n'
			status = status .. 'Data Value: ' .. (dataValue or 'none') .. '\\n'
			status = status .. 'Click Count: ' .. clickCount
			
			statusDisplay.text = status
			
			-- Update info box with current state
			if disabled then
				infoBox.text = '🔒 Target button is currently DISABLED. It cannot be clicked and appears grayed out.'
			else
				infoBox.text = '✅ Target button is currently ENABLED. Click it to see the counter increase!'
			end
		end

		-- Target button click handler
		targetButton:on('click', function()
			clickCount = clickCount + 1
			clickCounter.text = 'Button clicked ' .. clickCount .. ' times!'
			gurt.log('Target button clicked! Count:', clickCount)
			updateStatus()
		end)

		-- Enable button functionality
		enableBtn:on('click', function()
			targetButton:setAttribute('disabled', '') -- Remove disabled attribute
			targetButton:setAttribute('data-value', 'enabled')
			gurt.log('Target button enabled via setAttribute')
			updateStatus()
		end)

		-- Disable button functionality
		disableBtn:on('click', function()
			targetButton:setAttribute('disabled', 'true')
			targetButton:setAttribute('data-value', 'disabled')
			gurt.log('Target button disabled via setAttribute')
			updateStatus()
		end)

		-- Toggle button functionality
		toggleBtn:on('click', function()
			local currentlyDisabled = targetButton:getAttribute('disabled')
			
			if currentlyDisabled then
				-- Currently disabled, so enable it
				targetButton:setAttribute('disabled', '')
				targetButton:setAttribute('data-value', 'toggled-enabled')
				gurt.log('Target button toggled to enabled state')
			else
				-- Currently enabled, so disable it
				targetButton:setAttribute('disabled', 'true')
				targetButton:setAttribute('data-value', 'toggled-disabled')
				gurt.log('Target button toggled to disabled state')
			end
			
			updateStatus()
		end)

		-- Status check button
		statusBtn:on('click', function()
			local disabled = targetButton:getAttribute('disabled')
			local type = targetButton:getAttribute('type')
			local dataValue = targetButton:getAttribute('data-value')
			
			gurt.log('=== BUTTON STATUS CHECK ===')
			gurt.log('Disabled attribute:', disabled or 'not set')
			gurt.log('Type attribute:', type or 'not set')
			gurt.log('Data-value attribute:', dataValue or 'not set')
			gurt.log('Click count:', clickCount)
			gurt.log('===========================')
			
			-- Demonstrate style setAttribute
			local randomColors = {'bg-red-500', 'bg-green-500', 'bg-purple-500', 'bg-orange-500', 'bg-pink-500'}
			local randomColor = randomColors[math.random(1, #randomColors)]
			
			if not disabled then
				targetButton:setAttribute('style', 'target-button ' .. randomColor .. ' text-white px-6 py-3 rounded-lg font-semibold hover:opacity-75')
				
				gurt.setTimeout(function()
					targetButton:setAttribute('style', 'target-button bg-[#3b82f6] text-white px-6 py-3 rounded-lg font-semibold hover:bg-[#2563eb]')
				end, 1000)
			end
		end)

		-- Initialize status display
		updateStatus()

		-- Set initial attributes to demonstrate the methods
		targetButton:setAttribute('type', 'button')
		targetButton:setAttribute('data-value', 'initial')
		
		-- Update status after setting initial attributes
		gurt.setTimeout(function()
			updateStatus()
		end, 100)
	</script>
</head>

<body>
	<h1>🔘 Button getAttribute & setAttribute Demo</h1>
	
	<div style="container mt-6">
		<div style="info-box mb-6">
			<p id="info-box">✅ Target button is currently ENABLED. Click it to see the counter increase!</p>
		</div>

		<h2>Target Button</h2>
		<div style="demo-buttons mb-6 text-center">
			<button id="target-button" style="target-button">🎯 Click Me!</button>
			<p id="click-counter" style="mt-3 text-lg font-semibold text-[#374151]">Button clicked 0 times!</p>
		</div>

		<h2>Control Buttons</h2>
		<div style="button-group mb-6">
			<button id="enable-btn" style="control-button enable-btn">🟢 Enable Button</button>
			<button id="disable-btn" style="control-button disable-btn">🔴 Disable Button</button>
			<button id="toggle-btn" style="control-button toggle-btn">🔄 Toggle State</button>
			<button id="status-btn" style="control-button status-btn">📊 Check Status</button>
		</div>

		<h2>Current Attributes</h2>
		<div style="status-display mb-6">
			<pre id="status-display">Loading status...</pre>
		</div>

		<div style="bg-[#e0f2fe] p-4 rounded-lg">
			<h3 style="text-[#0277bd] font-semibold mb-2">How It Works:</h3>
			<ul style="text-[#01579b] space-y-1">
				<li><strong>Enable:</strong> Uses <code>setAttribute('disabled', '')</code> to remove the disabled attribute</li>
				<li><strong>Disable:</strong> Uses <code>setAttribute('disabled', 'true')</code> to add the disabled attribute</li>
				<li><strong>Toggle:</strong> Uses <code>getAttribute('disabled')</code> to check current state, then toggles it</li>
				<li><strong>Status:</strong> Uses <code>getAttribute()</code> to read multiple attributes and displays them</li>
				<li><strong>Bonus:</strong> Also demonstrates setting custom data attributes and style changes</li>
			</ul>
		</div>
	</div>
</body>
""".to_utf8_buffer()
