TODO:
1. Write a new **selection system**. Godot's built-in `RichTextLabel` selection is limited by the node's boundaries. In normal web, holding click and dragging your mouse across the screen will select text across multiple nodes. Godot doesn't have a "set_selected_text" property, despite having one for "get_selected_text".
2. **Right-click Dropdown** for basic text operations (Copy, Paste, Cut). Download options for images
3. **Select-all CTRL+A shortcut**
4. **Scrolling** in the website container
5. **Store** tab containers so switching tabs won't erase previous tab.
6. **GIF** support
7. **Video** support via [GDE GoZen](https://github.com/VoylinsGamedevJourney/gde_gozen)
8. **More input types** (url, tel, date, time, etc.)
9. **Required** attribute for inputs
10. Installer should register **gurt://** as a valid protocol thru the registry.
11. < input type=**datetime** />, essentially a type "date" but with a vertical separator, then `mm | ss | FORMAT` layout for time.
12. **< table >** component. [🔗 Related Godot proposal](https://github.com/godotengine/godot-proposals/issues/97)

Issues:
1. **< br />** counts as 1 element in **WebsiteContainer**, therefore despite being (0,0) in size, it counts as double in spacing

Notes:
- **< input />** is sort-of inline in normal web. We render it as a block element (new-line).
- A single `RichTextLabel` for inline text tags should stop, we should use invididual ones so it's easier to style and achieve separation through a `vboxcontainer`.
