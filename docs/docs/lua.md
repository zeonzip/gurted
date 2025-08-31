---
sidebar_position: 3
---

# Lua API

Gurted provides a Lua API that enables dynamic web development with client-side scripting. The Lua runtime is integrated into the browser engine and provides access to DOM manipulation, network requests, animations, and more.

## Global: gurt

The main global object for DOM manipulation and core functionality.

### gurt.select(selector)

Selects the first element matching the CSS selector.

```lua
local element = gurt.select('#my-id')
local firstButton = gurt.select('button')
local classElement = gurt.select('.my-class')
```

### gurt.selectAll(selector)

Selects all elements matching the CSS selector, returns an array.

```lua
local allButtons = gurt.selectAll('button')
local listItems = gurt.selectAll('li')

-- Iterate through results
for i = 1, #allButtons do
    local button = allButtons[i]
    button.text = 'Button ' .. i
end
```

### gurt.create(tagName, options)

Creates a new HTML element.

```lua
-- Basic element
local div = gurt.create('div')

-- Element with attributes and content
local button = gurt.create('button', {
    text = 'Click me!',
    style = 'bg-blue-500 text-white px-4 py-2 rounded',
    id = 'my-button'
})
```

### gurt.body

Reference to the document body element.

```lua
-- Add event listeners to body
gurt.body:on('keydown', function(event)
    trace.log('Key pressed: ' .. event.key)
end)

-- Append elements to body
local newDiv = gurt.create('div', { text = 'Hello World!' })
gurt.body:append(newDiv)
```

### gurt.location

Browser location and navigation control.

### gurt.location.href

Gets the current URL.

```lua
local currentUrl = gurt.location.href
trace.log('Current URL: ' .. currentUrl)
```

### gurt.location.reload()

Reloads the current page.

```lua
gurt.location.reload()
```

### gurt.location.goto(url)

Navigates to a new URL.

```lua
gurt.location.goto('gurt://example.com/page')
gurt.location.goto('https://external-site.com')
```

### gurt.location.query

Query parameter access.

```lua
-- Get a specific parameter
local userId = gurt.location.query.get('user_id')

-- Check if parameter exists
if gurt.location.query.has('debug') then
    trace.log('Debug mode enabled')
end

-- Get all values for a parameter (for repeated params)
local tags = gurt.location.query.getAll('tag')
```
## Global: trace

The global trace table for logging messages to the console.

### trace.log(message)
Identical to `print()`, logs a message to the console.

```lua
trace.log('Hello from Lua!')
```

### trace.warn(message)
Logs a warning message to the console.

```lua
trace.warn('This is a warning!')
```

### trace.error(message)
Logs an error message to the console.

```lua
trace.error('This is an error!')
```

## Element

Elements returned by `gurt.select()`, `gurt.create()`, etc. have the following properties and methods:

### Properties

#### element.text

Gets or sets the text content of an element.

```lua
local p = gurt.select('p')
p.text = 'New paragraph content'
local currentText = p.text
```

#### element.value

Gets or sets the value of form elements.

```lua
local input = gurt.select('#username')
input.value = 'john_doe'
local username = input.value

local checkbox = gurt.select('#agree')
checkbox.value = true  -- Check the checkbox
```

#### element.visible

Gets or sets element visibility.

```lua
local modal = gurt.select('#modal')
modal.visible = false  -- Hide element
modal.visible = true   -- Show element

if modal.visible then
    trace.log('Element is visible')
end
```

#### element.children

Gets an array of child elements.

```lua
local container = gurt.select('.container')
local children = container.children

for i = 1, #children do
    local child = children[i]
    trace.log('Child ' .. i .. ': ' .. child.text)
end
```

### DOM Traversal

#### element.parent

Gets the parent element.

```lua
local button = gurt.select('#my-button')
local container = button.parent
```

#### element.nextSibling / element.previousSibling

Gets adjacent sibling elements.

```lua
local current = gurt.select('#current-item')
local next = current.nextSibling
local prev = current.previousSibling
```

#### element.firstChild / element.lastChild

Gets first or last child element.

```lua
local list = gurt.select('ul')
local firstItem = list.firstChild
local lastItem = list.lastChild
```

### Methods

#### element:on(eventName, callback)

Adds an event listener. Returns a subscription object.

```lua
local button = gurt.select('#my-button')

-- Click event
local subscription = button:on('click', function()
    trace.log('Button clicked!')
end)

-- Mouse events
button:on('mouseenter', function()
    button.classList:add('hover-effect')
end)

button:on('mouseexit', function()
    button.classList:remove('hover-effect')
end)

-- Input events (for form elements)
local input = gurt.select('#username')
input:on('change', function(event)
    trace.log('Input changed to: ' .. event.value)
end)

-- Focus events
input:on('focusin', function()
    trace.log('Input focused')
end)

input:on('focusout', function()
    trace.log('Input lost focus')
end)

-- Unsubscribe from event
subscription:unsubscribe()
```

#### element:append(childElement)

Adds a child element.

```lua
local container = gurt.select('.container')
local newDiv = gurt.create('div', { text = 'New content' })
container:append(newDiv)
```

#### element:remove()

Removes the element from the DOM.

```lua
local elementToRemove = gurt.select('#temporary')
elementToRemove:remove()
```

#### element:insertBefore(newElement, referenceElement)

Inserts an element before another element.

```lua
local container = gurt.select('.container')
local newElement = gurt.create('div', { text = 'Inserted' })
local reference = gurt.select('#reference')
container:insertBefore(newElement, reference)
```

#### element:insertAfter(newElement, referenceElement)

Inserts an element after another element.

```lua
local container = gurt.select('.container')
local newElement = gurt.create('div', { text = 'Inserted' })
local reference = gurt.select('#reference')
container:insertAfter(newElement, reference)
```

#### element:replace(oldElement, newElement)

Replaces a child element with a new element.

```lua
local container = gurt.select('.container')
local oldElement = gurt.select('#old')
local newElement = gurt.create('div', { text = 'Replacement' })
container:replace(oldElement, newElement)
```

#### element:clone(deep)

Creates a copy of the element.

```lua
-- Shallow clone (element only)
local copy = element:clone(false)

-- Deep clone (element and all children)
local deepCopy = element:clone(true)
```

#### element:getAttribute(name) / element:setAttribute(name, value)

Gets or sets element attributes.

```lua
local img = gurt.select('img')
local src = img:getAttribute('src')
img:setAttribute('alt', 'Description text')

-- Remove attribute by setting empty value
img:setAttribute('title', '')
```

#### element:show() / element:hide()

Shows or hides an element.

```lua
local modal = gurt.select('#modal')
modal:show()   -- Makes element visible
modal:hide()   -- Hides element
```

#### element:focus() / element:unfocus()

Sets or removes focus from an element.

```lua
local input = gurt.select('#search')
input:focus()    -- Focus the input
input:unfocus()  -- Remove focus
```

### Class List Management

#### element.classList

Provides methods for managing CSS classes.

```lua
local button = gurt.select('#my-button')

-- Add classes
button.classList:add('active')
button.classList:add('btn-primary')

-- Remove classes
button.classList:remove('disabled')

-- Toggle classes
button.classList:toggle('selected')

-- Check if class exists
if button.classList:contains('active') then
    trace.log('Button is active')
end

-- Get specific class by index (1-based)
local firstClass = button.classList:item(1)

-- Get number of classes
local classCount = button.classList.length
```

### Animations

#### element:createTween()

Creates a tween animation for the element.

```lua
local box = gurt.select('#animated-box')

-- Fade out
box:createTween()
   :to('opacity', 0)
   :duration(1.0)
   :easing('out')
   :transition('linear')
   :play()

-- Move and scale
box:createTween()
   :to('x', 200)
   :to('y', 100)
   :to('scale', 1.5)
   :duration(2.0)
   :easing('inout')
   :transition('cubic')
   :play()

-- Color animation
box:createTween()
   :to('backgroundColor', '#ff0000')
   :duration(1.5)
   :easing('out')
   :transition('quad')
   :play()

-- Rotation
box:createTween()
   :to('rotation', 360)
   :duration(3.0)
   :easing('inout')
   :transition('sine')
   :play()
```

**Available Tween Properties:**
- `opacity` - Element transparency (0-1)
- `backgroundColor` - Background color (hex format)
- `scale` - Element scale (1.0 = normal size)
- `rotation` - Rotation in degrees
- `x`, `y` - Position offset

**Easing Types:** `'in'`, `'out'`, `'inout'`, `'outin'`

**Transition Types:** `'linear'`, `'quad'`, `'cubic'`, `'quart'`, `'quint'`, `'sine'`, `'expo'`, `'circ'`, `'elastic'`, `'back'`, `'bounce'`

![CRT effect](../static/img/docs/tween.png)
Resource: [Reddit](https://www.reddit.com/r/godot/comments/frqzup/godot_tweening_cheat_sheet/)

## Audio API

Work with audio elements for sound playback.

```lua
local audio = gurt.select('#my-audio')

audio:play()    -- Start playback
audio:pause()   -- Pause playback
audio:stop()    -- Stop and reset

audio.currentTime = 30.0            -- Seek to 30 seconds
audio.volume = 0.8                  -- Set volume (0.0 - 1.0)
audio.loop = true                   -- Enable looping
audio.src = 'gurt://new-audio.mp3'  -- Change source

local duration = audio.duration
local currentPos = audio.currentTime
local isPlaying = audio.playing
local isPaused = audio.paused
```

## Canvas API

Gurted features a 2D canvas API similar to HTML5 Canvas, plus shader support.

### Context

```lua
local canvas = gurt.select('#my-canvas')

local ctx = canvas:withContext('2d')
local shaderCtx = canvas:withContext('shader')
```

### 2D Drawing Context

#### Rectangle

```lua
-- Fill a solid rectangle
ctx:fillRect(x, y, width, height, color)
ctx:fillRect(50, 50, 100, 75, '#ff0000') -- Red filled rectangle

-- Draw rectangle outline
ctx:strokeRect(x, y, width, height, color, strokeWidth)
ctx:strokeRect(200, 50, 100, 75, '#00ff00', 3) -- Green outline, 3px thick

-- Clear a rectangular area 
ctx:clearRect(x, y, width, height)
ctx:clearRect(80, 80, 40, 40) -- Clear 40x40 area
```

#### Circle

```lua
-- Draw filled or outlined circles
ctx:drawCircle(x, y, radius, color, filled)
ctx:drawCircle(150, 100, 30, '#0000ff', true) -- Filled blue circle
ctx:drawCircle(200, 100, 30, '#ff00ff', false) -- Outlined magenta circle
```

#### Text

```lua
ctx:drawText(x, y, text, color)
ctx:drawText(20, 250, 'Hello Canvas!', '#ffffff')
ctx:drawText(20, 280, 'Default Font Only', '#ffff00')

-- Font size can be set with setFont (size only, not family)
ctx:setFont('20px sans-serif')  -- Only size matters
ctx:drawText(20, 300, 'Larger text', '#00ff00')

local metrics = ctx:measureText('Sample Text')
local textWidth = metrics.width
```

### Path-Based Drawing

For complex shapes, use path-based drawing methods:

```lua
ctx:beginPath()

-- Move to starting point without drawing
ctx:moveTo(100, 100)

-- Draw line to point
ctx:lineTo(200, 150)
ctx:lineTo(150, 200)
ctx:lineTo(50, 200)

-- Close the path (connects back to start)
ctx:closePath()

-- Draw the path
ctx:stroke() -- Draw outline
-- or
ctx:fill() -- Fill the shape
```

#### Advanced Path Methods

##### Arc and Circle Paths

```lua
-- Draw arc (part of circle)
ctx:arc(x, y, radius, startAngle, endAngle, counterclockwise)

-- Example: Draw a quarter circle
ctx:beginPath()
ctx:arc(200, 200, 50, 0, math.pi/2, false) -- 0 to 90 degrees
ctx:stroke()

-- Full circle path
ctx:beginPath()
ctx:arc(300, 200, 40, 0, 2 * math.pi, false) -- 0 to 360 degrees
ctx:fill()
```

##### Curve Methods

```lua
-- Quadratic curve (one control point)
ctx:quadraticCurveTo(controlX, controlY, endX, endY)

-- Example: Smooth curve
ctx:beginPath()
ctx:moveTo(50, 300)
ctx:quadraticCurveTo(150, 250, 250, 300) -- Control point at (150,250)
ctx:stroke()

-- Bezier curve (two control points)
ctx:bezierCurveTo(cp1x, cp1y, cp2x, cp2y, endX, endY)

-- Example: S-curve
ctx:beginPath()
ctx:moveTo(50, 350)
ctx:bezierCurveTo(100, 300, 200, 400, 250, 350)
ctx:stroke()
```

#### Styling and Properties

##### Setting Draw Styles

```lua
-- Set stroke (outline) color
ctx:setStrokeStyle('#ff0000') -- Red outline
ctx:setStrokeStyle('rgba(255, 0, 0, 0.5)') -- Semi-transparent red
ctx:setStrokeStyle('red-500') -- Tailwind color names
ctx:setStrokeStyle('blue') -- Named colors

-- Set fill color
ctx:setFillStyle('#00ff00') -- Green fill
ctx:setFillStyle('#33aa88') -- Teal fill
ctx:setFillStyle('slate-800') -- Tailwind colors
ctx:setFillStyle('transparent') -- Named transparent

-- Set line width for strokes
ctx:setLineWidth(5) -- 5 pixel wide lines
ctx:setLineWidth(0.5) -- Thin lines

-- Set font for text (size only, not family)
ctx:setFont('20px sans-serif')  -- Only size matters
ctx:setFont('16px Arial')       -- Font family ignored
ctx:setFont('14px monospace')   -- Uses default font at 14px
```

**Color Support**: Canvas color parsing is identical to CSS styling - supports hex colors (`#ff0000`), RGB/RGBA (`rgba(255,0,0,0.5)`), Tailwind color names (`red-500`, `slate-800`), and basic named colors (`red`, `blue`, `transparent`).

##### Using Styles in Drawing

```lua
-- Set up styles first
ctx:setFillStyle('#ff6b6b')
ctx:setStrokeStyle('#4ecdc4')
ctx:setLineWidth(3)

-- Then draw with those styles
ctx:fillRect(50, 50, 100, 100)    -- Uses fill style
ctx:strokeRect(200, 50, 100, 100) -- Uses stroke style and line width

-- Styles persist until changed
ctx:setFillStyle('#45b7d1')
ctx:fillRect(50, 200, 100, 100)   -- Now uses blue fill
```

#### Transformations

Canvas transformations allow you to modify the coordinate system for drawing operations.

##### Basic Transformations

```lua
ctx:save()
ctx:translate(100, 50)
ctx:rotate(math.pi / 4)
ctx:scale(2.0, 1.5)
ctx:fillRect(0, 0, 50, 50)
ctx:restore()
ctx:fillRect(0, 0, 50, 50)
```

##### Transformation Examples

```lua
ctx:save()
ctx:translate(200, 200)
ctx:rotate(math.pi / 6)
ctx:drawText(-25, 0, 'Rotated', 'Arial', '#000000')
ctx:restore()

for i = 1, 5 do
    ctx:save()
    ctx:scale(i * 0.3, i * 0.3)
    ctx:strokeRect(100, 100, 50, 50)
    ctx:restore()
end

for angle = 0, 360, 30 do
    ctx:save()
    ctx:translate(200, 200)
    ctx:rotate(math.rad(angle))
    ctx:fillRect(50, -5, 40, 10)
    ctx:restore()
end
```

### Shader Context

For advanced visual effects, use the shader context:

```lua
local canvas = gurt.select('#shader-canvas')
local shaderCtx = canvas:withContext('shader')

shaderCtx:source([[
    shader_type canvas_item;
    
    uniform float time : hint_range(0.0, 10.0) = 1.0;
    uniform vec2 resolution;
    
    void fragment() {
        vec2 uv = UV;
        
        // Create animated rainbow effect
        vec3 color = vec3(
            0.5 + 0.5 * cos(time + uv.x * 6.0),
            0.5 + 0.5 * cos(time + uv.y * 6.0 + 2.0),
            0.5 + 0.5 * cos(time + (uv.x + uv.y) * 6.0 + 4.0)
        );
        
        COLOR = vec4(color, 1.0);
    }
]])
```

## Network API

### fetch(url, options)

Makes HTTP requests with full control over method, headers, and body.

```lua
-- Simple GET request
local response = fetch('https://api.example.com/data')

-- POST request with data
local response = fetch('https://api.example.com/users', {
    method = 'POST',
    headers = {
        ['Content-Type'] = 'application/json',
        ['Authorization'] = 'Bearer token123'
    },
    body = JSON.stringify({
        name = 'John Doe',
        email = 'john@example.com'
    })
})

-- Check response
if response:ok() then
    local data = response:json()  -- Parse JSON response
    local text = response:text()  -- Get as text
    
    trace.log('Status: ' .. response.status)
    trace.log('Status Text: ' .. response.statusText)
    
    -- Access headers
    local contentType = response.headers['content-type']
else
    trace.log('Request failed with status: ' .. response.status)
end
```

**Supported Methods:** `GET`, `POST`, `PUT`, `DELETE`, `HEAD`, `OPTIONS`, `PATCH`

**Relative URLs** are automatically resolved to the current domain with `gurt://` protocol.

## JSON API

### JSON.stringify(data)

Converts Lua data to JSON string.

```lua
local data = {
    name = 'Alice',
    age = 30,
    hobbies = {'reading', 'coding'},
    active = true
}

local jsonString = JSON.stringify(data)
trace.log(jsonString)  -- {"name":"Alice","age":30,"hobbies":["reading","coding"],"active":true}
```

### JSON.parse(jsonString)

Parses JSON string to Lua data.

```lua
local jsonString = '{"name":"Bob","score":95.5}'
local data, error = JSON.parse(jsonString)

if data then
    trace.log('Name: ' .. data.name)
    trace.log('Score: ' .. data.score)
else
    trace.log('Parse error: ' .. error)
end
```

## Time API

### Time.now()

Gets current Unix timestamp.

```lua
local timestamp = Time.now()
trace.log('Current time: ' .. timestamp)
```

### Time.format(timestamp, format)

Formats a timestamp using format strings.

```lua
local now = Time.now()
local formatted = Time.format(now, '%Y-%m-%d %H:%M:%S')
trace.log('Formatted: ' .. formatted)

-- Format strings
-- %Y - Full year (2024)
-- %y - Two-digit year (24)
-- %m - Month (01-12)
-- %d - Day (01-31)
-- %H - Hour 24-format (00-23)
-- %I - Hour 12-format (01-12)
-- %M - Minute (00-59)
-- %S - Second (00-59)
-- %p - AM/PM
-- %A - Full weekday name
-- %a - Abbreviated weekday name
-- %B - Full month name
-- %b - Abbreviated month name
```

### Time.date(timestamp)

Gets date components as a table.

```lua
local now = Time.now()
local date = Time.date(now)

trace.log('Year: ' .. date.year)
trace.log('Month: ' .. date.month)
trace.log('Day: ' .. date.day)
trace.log('Hour: ' .. date.hour)
trace.log('Minute: ' .. date.minute)
trace.log('Second: ' .. date.second)
trace.log('Weekday: ' .. date.weekday)  -- 0=Sunday, 6=Saturday
```

### Time.sleep(seconds)

Pauses execution for a specified duration.

```lua
trace.log('Starting...')
Time.sleep(2.0)  -- Wait 2 seconds
trace.log('Done waiting!')
```

:::note
This blocks the entire Lua thread. Use with caution, we recommend using `setTimeout()` for non-blocking delays.
:::

### Time.benchmark(function)

Measures function execution time.

```lua
local elapsed, result = Time.benchmark(function()
    -- Some complex calculation
    local sum = 0
    for i = 1, 1000000 do
        sum = sum + i
    end
    return sum
end)

trace.log('Function took ' .. elapsed .. ' seconds')
trace.log('Result: ' .. result)
```

### Time.timer()

Creates a timer object for measuring intervals.

```lua
local timer = Time.timer()

-- Do some work...
Time.sleep(1.5)

local elapsed = timer:elapsed()
trace.log('Elapsed: ' .. elapsed .. ' seconds')

timer:reset()  -- Reset timer
```

### Time.delay(seconds)

Creates a delay object for non-blocking waits.

```lua
local delay = Time.delay(3.0)

-- Check if delay is complete
if delay:complete() then
    trace.log('Delay finished!')
end

-- Get remaining time
local remaining = delay:remaining()
trace.log('Time left: ' .. remaining .. ' seconds')
```

## Timeout and Interval Functions

### setTimeout(callback, milliseconds)

Executes a function after a delay.

```lua
local timeoutId = setTimeout(function()
    trace.log('This runs after 2 seconds')
end, 2000)

-- Cancel the timeout
-- clearTimeout(timeoutId)
```

### setInterval(callback, milliseconds)

Executes a function repeatedly at intervals.

```lua
local intervalId = setInterval(function()
    trace.log('This runs every second')
end, 1000)

setTimeout(function()
    clearInterval(intervalId)
    trace.log('Interval stopped')
end, 5000)
```

### clearTimeout(timeoutId) / clearInterval(intervalId)

Cancels scheduled timeouts or intervals.

```lua
local id = setTimeout(function()
    trace.log('This will not run')
end, 1000)

clearTimeout(id)
```

## WebSocket API

Real-time communication with WebSocket servers.

```lua
local ws = WebSocket.new('ws://localhost:8080/chat')

ws:on('open', function()
    trace.log('WebSocket connected')
    ws:send('Hello server!')
end)

ws:on('message', function(data)
    trace.log('Received: ' .. data)
end)

ws:on('close', function(code, reason)
    trace.log('WebSocket closed: ' .. code .. ' - ' .. reason)
end)

ws:on('error', function(error)
    trace.log('WebSocket error: ' .. error)
end)

ws:send('Hello from client!')
ws:send(JSON.stringify({ type = 'chat', message = 'Hello!' }))

ws:close()

if ws.readyState == WebSocket.OPEN then
    ws:send('Connected message')
end
```

**WebSocket States:**
- `WebSocket.CONNECTING` (0) - Connection in progress
- `WebSocket.OPEN` (1) - Connection established
- `WebSocket.CLOSING` (2) - Connection closing
- `WebSocket.CLOSED` (3) - Connection closed

## URL API

URL encoding and decoding utilities for handling special characters in URLs.

### urlEncode(string)

Encodes a string for safe use in URLs by converting special characters to percent-encoded format.

```lua
local encoded = urlEncode('hello world!')
trace.log(encoded) -- hello%20world%21

local params = urlEncode('name=John Doe&age=30')
trace.log(params) -- name%3DJohn%20Doe%26age%3D30

-- Building query strings
local searchTerm = 'cats & dogs'
local url = 'gurt://search.com/api?q=' .. urlEncode(searchTerm)
trace.log(url) -- gurt://search.com/api?q=cats%20%26%20dogs
```

### urlDecode(string)

Decodes a percent-encoded URL string back to its original form.

```lua
local decoded = urlDecode('hello%20world%21')
trace.log(decoded) -- hello world!

local params = urlDecode('name%3DJohn%20Doe%26age%3D30')
trace.log(params) -- name=John Doe&age=30

local queryParam = 'cats%20%26%20dogs'
local searchTerm = urlDecode(queryParam)
trace.log(searchTerm) -- cats & dogs
```

## Clipboard API

Write to the system clipboard.

```lua
Clipboard.write('Hello clipboard!')
```

## Regex API

Pattern matching and text processing with regular expressions.

### Regex.new(pattern)

Creates a new regex object from a pattern string.

```lua
local emailPattern = Regex.new('[a-zA-Z]+@[a-zA-Z]+\\.[a-zA-Z]+')
local phonePattern = Regex.new('\\(\\d{3}\\)\\s*\\d{3}-\\d{4}')
```

### regex:test(text)

Tests if the pattern matches anywhere in the text. Returns `true` or `false`.

```lua
local pattern = Regex.new('[a-zA-Z]+@[a-zA-Z]+\\.[a-zA-Z]+')

if pattern:test('user@example.com') then
    trace.log('Valid email format')
end

if pattern:test('Contact us at admin@site.com') then
    trace.log('Found email in text')
end
```

### regex:match(text)

Finds the first match and returns capture groups as an array, or `nil` if no match found.

```lua
local pattern = Regex.new('(\\w+)@(\\w+)\\.(\\w+)')
local result = pattern:match('Contact: admin@site.com for help')

if result then
    trace.log('Full match: ' .. result[1])  -- admin@site.com
    trace.log('Username: ' .. result[2])    -- admin
    trace.log('Domain: ' .. result[3])      -- site
    trace.log('TLD: ' .. result[4])         -- com
else
    trace.log('No match found')
end
```

## Event Handling

### Body Events

Global events that can be captured on the document body:

```lua
-- Keyboard events
gurt.body:on('keydown', function(event)
    trace.log('Key down: ' .. event.key)
    if event.ctrl and event.key == 's' then
        trace.log('Ctrl+S pressed - Save shortcut!')
    end
end)

gurt.body:on('keyup', function(event)
    trace.log('Key up: ' .. event.key)
end)

gurt.body:on('keypress', function(event)
    trace.log('Key pressed: ' .. event.key)
    -- Event properties: key, keycode, ctrl, shift, alt
end)

-- Mouse events
gurt.body:on('mousemove', function(event)
    trace.log('Mouse at: ' .. event.x .. ', ' .. event.y)
    -- Event properties: x, y, deltaX, deltaY
end)

gurt.body:on('mouseenter', function()
    trace.log('Mouse entered page')
end)

gurt.body:on('mouseexit', function()
    trace.log('Mouse left page')
end)
```

### Element Events

Events specific to DOM elements:

```lua
local button = gurt.select('#my-button')

-- Mouse events
button:on('click', function()
    trace.log('Button clicked!')
end)

button:on('mousedown', function()
    trace.log('Mouse button pressed')
end)

button:on('mouseup', function()
    trace.log('Mouse button released')
end)

button:on('mouseenter', function()
    trace.log('Mouse entered button')
end)

button:on('mouseexit', function()
    trace.log('Mouse left button')
end)

button:on('mousemove', function(event)
    trace.log('Mouse moved over button: ' .. event.x .. ', ' .. event.y)
end)

-- Focus events
local input = gurt.select('#text-input')
input:on('focusin', function()
    trace.log('Input gained focus')
end)

input:on('focusout', function()
    trace.log('Input lost focus')
end)

-- Form events
input:on('change', function(event)
    trace.log('Input value changed to: ' .. event.value)
end)

input:on('input', function(event)
    trace.log('Input text: ' .. event.value)
end)

-- For file inputs
local fileInput = gurt.select('#file-input')
fileInput:on('change', function(event)
    trace.log('File selected: ' .. event.fileName)
end)

-- For form submission
local form = gurt.select('#my-form')
form:on('submit', function(event)
    trace.log('Form submitted with data:')
    for key, value in pairs(event.data) do
        trace.log(key .. ': ' .. tostring(value))
    end
end)
```

## Error Handling

### pcall for Protected Calls

Use Lua's `pcall` for error handling:

```lua
local success, result = pcall(function()
    local data = JSON.parse('invalid json')
    return data
end)

if success then
    trace.log('Parse successful: ' .. tostring(result))
else
    trace.log('Parse failed: ' .. result)  -- result contains error message
end
```

## Additional utilities

Gurted includes several helpful utilities:

### print(...)
We modify the global `print()` function to log to the browser console, and also convert any type (e.g. tables) to a readable string.

```lua
print('Hello, world!')
print({ name = 'Alice', age = 30, hobbies = {'reading', 'coding'} }) -- {age=30,hobbies={1="reading",2="coding"},name="Alice"}
```

### table.tostring(table)

Converts a table to a readable string representation.

```lua
local data = { name = 'John', age = 30, hobbies = {'reading', 'coding'} }
local str = table.tostring(data) -- {age=30,hobbies={1="reading",2="coding"},name="John"}
```

### string.replace(text, search, replacement)

Replaces the first occurrence of a string or regex pattern.

```lua
local text = 'Hello world, hello universe'
local result = string.replace(text, 'hello', 'hi')
trace.log(result)  -- Hello world, hi universe

local pattern = Regex.new('\\b\\w+@\\w+\\.\\w+\\b')
local masked = string.replace('Email: john@test.com', pattern, '[EMAIL]')
trace.log(masked)  -- Email: [EMAIL]
```

### string.replaceAll(text, search, replacement)

Replaces all occurrences of a string or regex pattern.

```lua
local text = 'Hello world, hello universe'
local result = string.replaceAll(text, 'hello', 'hi')
trace.log(result) -- Hello world, hi universe

local pattern = Regex.new('\\b\\w+@\\w+\\.\\w+\\b')
local text = 'Emails: john@test.com, jane@demo.org'
local masked = string.replaceAll(text, pattern, '[EMAIL]')
trace.log(masked) -- Emails: [EMAIL], [EMAIL]
```

### string.trim(text)

Removes whitespace from the beginning and end of a string.

```lua
local messy = '   Hello World   '
local clean = string.trim(messy)
trace.log('"' .. clean .. '"')  -- "Hello World"
```

This is particularly useful for debugging and logging complex data structures.
