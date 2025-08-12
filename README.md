gurted (verb)
> “to do something smart, but also dangerous”

wayfinder (noun)
> “a person helping others navigate”

In traditional web, you might be familiar with the term "browser." A **wayfinder** is that, but for the **GURT** protocol.

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
12. **< canvas >** component should be theoretically impossible by exposing Godot `_draw()` APIs to Lua.
13. `grid` display property for CSS, using `GridContainer` in Godot.

Issues:
1. **< br />** counts as 1 element in **WebsiteContainer**, therefore despite being (0,0) in size, it counts as double in spacing
2. **Tween** API doesn't modify CSS, it operates independently at Godot level.
3. Certain properties like `scale` and `rotate` don't apply to the `active` pseudo-class because they rely on mouse_enter and mouse_exit events
4. `<div style="bg-[#3b82f6] w-[100px] h-[100px] flex hover:scale-110 transition hover:rotate-45">Box</div>` something like this has the "Box" text (presumably the PanelContainer) as the target of the hover, not the div itself (which has the w/h size)
5. font in button doesn't comply with CSS, its the projects default

Notes:
- **< input />** is sort-of inline in normal web. We render it as a block element (new-line).
- A single `RichTextLabel` for inline text tags should stop, we should use invididual ones so it's easier to style and achieve separation through a `vboxcontainer`.
- Fonts use **Flash of Unstyled Text (FOUT)** as opposed to **Flash of Invisible Text (FOIT)**, meaning the text with custom fonts will render with a generic font (sans-serif) while the custom ones downloads.
