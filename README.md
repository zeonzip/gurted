gurted (verb)
> “to do something smart, but also dangerous”

Sir facedev you should use the appropriate feature for this (issues) instead of using the readme, it's not professional.

TODO:
1. Write a new **selection system**. Godot's built-in `RichTextLabel` selection is limited by the node's boundaries. In normal web, holding click and dragging your mouse across the screen will select text across multiple nodes. Godot doesn't have a "set_selected_text" property, despite having one for "get_selected_text".
2. **Right-click Dropdown** for basic text operations (Copy, Paste, Cut). Download options for images
3. **Select-all CTRL+A shortcut**
4. **Scrolling** in the website container
5. **Store** tab containers so switching tabs won't erase previous tab.
6. **GIF** support
7. **Video** support via [GDE GoZen](https://github.com/VoylinsGamedevJourney/gde_gozen)
8. **Required** attribute for inputs
9. Installer should register **gurt://** as a valid protocol thru the registry.
10. < input type=**datetime** />, essentially a type "date" but with a vertical separator, then `mm | ss | FORMAT` layout for time.
11. **< table >** component. [🔗 Related Godot proposal](https://github.com/godotengine/godot-proposals/issues/97)

Issues:
1. **< br />** counts as 1 element in **WebsiteContainer**, therefore despite being (0,0) in size, it counts as double in spacing

Notes:
- **< input />** is sort-of inline in normal web. We render it as a block element (new-line).
- A single `RichTextLabel` for inline text tags should stop, we should use invididual ones so it's easier to style and achieve separation through a `vboxcontainer`.


Supported styles:

- **Font style:**  
  - `font-bold` 
  - `font-italic`
  - `underline`
- **Font size:**  
  - `text-xs` → 12  
  - `text-sm` → 14  
  - `text-base` → 16  
  - `text-lg` → 18  
  - `text-xl` → 20  
  - `text-2xl` → 24  
  - `text-3xl` → 30  
  - `text-4xl` → 36  
  - `text-5xl` → 48  
  - `text-6xl` → 60
- **Font family:**  
  - `font-mono`
- **Text color:**  
  - `text-[color]`
- **Background color:**  
  - `bg-[color]`
- **Flexbox**
- `flex` / `inline-flex` (display: flex/inline-flex)
- `flex-row`, `flex-row-reverse`, `flex-col`, `flex-col-reverse` (flex-direction)
- `flex-nowrap`, `flex-wrap`, `flex-wrap-reverse` (flex-wrap)
- `justify-start`, `justify-end`, `justify-center`, `justify-between`, `justify-around`, `justify-evenly` (justify-content)
- `items-start`, `items-end`, `items-center`, `items-baseline`, `items-stretch` (align-items)
- `content-start`, `content-end`, `content-center`, `content-between`, `content-around`, `content-evenly`, `content-stretch` (align-content)
- `gap-{size}`, `row-gap-{size}`, `col-gap-{size}` (gap, row-gap, column-gap)
- `flex-grow-{n}` (flex-grow)
- `flex-shrink-{n}` (flex-shrink)
- `basis-{size}` (flex-basis)
- `self-auto`, `self-start`, `self-end`, `self-center`, `self-stretch`, `self-baseline` (align-self)
- `order-{n}` (order)