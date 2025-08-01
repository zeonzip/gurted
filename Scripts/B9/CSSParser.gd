class_name CSSParser
extends RefCounted

class CSSRule:
	var selector: String
	var event_prefix: String = ""
	var properties: Dictionary = {}
	var specificity: int = 0
	
	func init(sel: String = ""):
		selector = sel
		parse_selector()
		calculate_specificity()
	
	func parse_selector():
		if selector.contains(":"):
			var parts = selector.split(":", false, 1)
			if parts.size() == 2:
				selector = parts[0]
				event_prefix = parts[1]
	
	func calculate_specificity():
		specificity = 1
		if selector.begins_with("."):
			specificity += 10  # Class selectors have higher specificity than tag selectors
		if event_prefix.length() > 0:
			specificity += 10

class CSSStylesheet:
	var rules: Array[CSSRule] = []
	
	func add_rule(rule: CSSRule):
		rules.append(rule)
	
	func get_styles_for_element(tag_name: String, event: String = "", class_names: Array[String] = []) -> Dictionary:
		var styles = {}
		
		# Sort rules by specificity
		var applicable_rules: Array[CSSRule] = []
		for rule in rules:
			if selector_matches(rule, tag_name, event, class_names):
				applicable_rules.append(rule)
		
		applicable_rules.sort_custom(func(a, b): return a.specificity < b.specificity)
		
		# Apply styles in order of specificity
		for rule in applicable_rules:
			for property in rule.properties:
				styles[property] = rule.properties[property]
		
		return styles
	
	func selector_matches(rule: CSSRule, tag_name: String, event: String = "", cls_names: Array[String] = []) -> bool:
		# Handle class selectors
		if rule.selector.begins_with("."):
			var cls = rule.selector.substr(1)  # Remove the "." prefix
			if not cls in cls_names:
				return false
		else:
			# Handle tag selectors
			if rule.selector != tag_name:
				return false
		
		if rule.event_prefix.length() > 0:
			return rule.event_prefix == event
		
		return event.length() == 0

var stylesheet: CSSStylesheet
var css_text: String

func init(css_content: String = ""):
	stylesheet = CSSStylesheet.new()
	css_text = css_content

func parse() -> void:
	if css_text.is_empty():
		return
	
	var cleaned_css = preprocess_css(css_text)
	var rules = extract_rules(cleaned_css)
	
	for rule_data in rules:
		var rule = parse_rule(rule_data)
		if rule:
			stylesheet.add_rule(rule)

func preprocess_css(css: String) -> String:
	# Remove comments
	var regex = RegEx.new()
	regex.compile("/\\*.*?\\*/")
	css = regex.sub(css, "", true)
	
	# Normalize whitespace
	regex.compile("\\s+")
	css = regex.sub(css, " ", true)
	
	return css.strip_edges()

func extract_rules(css: String) -> Array:
	var rules = []
	var current_pos = 0
	
	while current_pos < css.length():
		var brace_start = css.find("{", current_pos)
		if brace_start == -1:
			break
		
		var brace_end = find_matching_brace(css, brace_start)
		if brace_end == -1:
			break
		
		var selector_part = css.substr(current_pos, brace_start - current_pos).strip_edges()
		var properties_part = css.substr(brace_start + 1, brace_end - brace_start - 1).strip_edges()
		
		# Handle multiple selectors separated by commas
		var selectors = selector_part.split(",")
		for selector in selectors:
			rules.append({
				"selector": selector.strip_edges(),
				"properties": properties_part
			})
		
		current_pos = brace_end + 1
	
	return rules

func find_matching_brace(css: String, start_pos: int) -> int:
	var brace_count = 0
	var pos = start_pos
	
	while pos < css.length():
		match css[pos]:
			"{":
				brace_count += 1
			"}":
				brace_count -= 1
				if brace_count == 0:
					return pos
		pos += 1
	
	return -1

func parse_rule(rule_data: Dictionary) -> CSSRule:
	var rule = CSSRule.new()
	rule.selector = rule_data.selector
	rule.init(rule.selector)
	var properties_text = rule_data.properties
	
	var utility_classes = properties_text.split(" ")
	for utility_name in utility_classes:
		utility_name = utility_name.strip_edges()
		if utility_name.is_empty():
			continue
		
		parse_utility_class(rule, utility_name)
	
	return rule

func parse_utility_class(rule: CSSRule, utility_name: String) -> void:
	var pseudo_classes = ["hover", "active"]

	for pseudo in pseudo_classes:
		var prefix = pseudo + ":"
		if utility_name.begins_with(prefix):
			var actual_utility = utility_name.substr(prefix.length())
			var pseudo_rule = CSSRule.new()
			pseudo_rule.selector = rule.selector + ":" + pseudo
			pseudo_rule.init(pseudo_rule.selector)
			parse_utility_class_internal(pseudo_rule, actual_utility)
			stylesheet.add_rule(pseudo_rule)
			return

	# Fallback to normal parsing
	parse_utility_class_internal(rule, utility_name)

# Parses a utility class (e.g. "text-red-500") and adds properties to the rule (e.g. "color: red")
# Used as a translation layer for Tailwind-like utility classes, as it becomes easier to manage these programmatically
static func parse_utility_class_internal(rule: CSSRule, utility_name: String) -> void:
	# Handle color classes like text-[#ff0000]
	if utility_name.begins_with("text-[") and utility_name.ends_with("]"):
		var color_value = SizeUtils.extract_bracket_content(utility_name, 5)  # after 'text-'
		rule.properties["color"] = ColorUtils.parse_color(color_value)
		return
	
	# Handle standard text color classes like text-white, text-black, etc.
	# But exclude text alignment classes
	if utility_name.begins_with("text-") and not utility_name in ["text-left", "text-center", "text-right", "text-justify"]:
		var color_name = utility_name.substr(5)  # after 'text-'
		var color = ColorUtils.get_color(color_name)
		if color != null:
			rule.properties["color"] = color
			return

	# Handle background color classes like bg-[#ff0000]
	if utility_name.begins_with("bg-[") and utility_name.ends_with("]"):
		var color_value = SizeUtils.extract_bracket_content(utility_name, 3)  # after 'bg-'
		var color = ColorUtils.parse_color(color_value)
		rule.properties["background-color"] = color
		return
	
	# Handle standard background color classes like bg-white, bg-black, etc.
	if utility_name.begins_with("bg-"):
		var color_name = utility_name.substr(3)  # after 'bg-'
		var color = ColorUtils.get_color(color_name)
		if color != null:
			rule.properties["background-color"] = color
			return

	# e.g. max-w-[123px], w-[50%], h-[2rem]
	if utility_name.match("^max-w-\\[.*\\]$"):
		var val = SizeUtils.extract_bracket_content(utility_name, 6)
		rule.properties["max-width"] = val
		return
	if utility_name.match("^max-h-\\[.*\\]$"):
		var val = SizeUtils.extract_bracket_content(utility_name, 6)
		rule.properties["max-height"] = val
		return
	if utility_name.match("^min-w-\\[.*\\]$"):
		var val = SizeUtils.extract_bracket_content(utility_name, 6)
		rule.properties["min-width"] = val
		return
	if utility_name.match("^min-h-\\[.*\\]$"):
		var val = SizeUtils.extract_bracket_content(utility_name, 6)
		rule.properties["min-height"] = val
		return
	if utility_name.match("^w-\\[.*\\]$"):
		var val = SizeUtils.extract_bracket_content(utility_name, 2)
		rule.properties["width"] = val
		return
	if utility_name.match("^h-\\[.*\\]$"):
		var val = SizeUtils.extract_bracket_content(utility_name, 2)
		rule.properties["height"] = val
		return

	# Handle font weight
	if utility_name == "font-bold":
		rule.properties["font-bold"] = true
		return

	# Handle font family
	if utility_name == "font-sans":
		rule.properties["font-family"] = "sans-serif"
		return
	if utility_name == "font-serif":
		rule.properties["font-family"] = "serif"
		return
	if utility_name == "font-mono":
		rule.properties["font-family"] = "monospace"
		rule.properties["font-mono"] = true
		return
	
	var reserved_font_styles = ["font-sans", "font-serif", "font-mono", "font-bold", "font-italic"]
	# Handle custom font families like font-roboto
	if utility_name.begins_with("font-") and not utility_name in reserved_font_styles:
		var font_name = utility_name.substr(5)  # after 'font-'
		rule.properties["font-family"] = font_name
		return

	# Handle font style italic
	if utility_name == "font-italic":
		rule.properties["font-italic"] = true
		return

	# Handle underline
	if utility_name == "underline":
		rule.properties["underline"] = true
		return

	# Handle text size classes
	match utility_name:
		"text-xs": rule.properties["font-size"] = 12
		"text-sm": rule.properties["font-size"] = 14
		"text-base": rule.properties["font-size"] = 16
		"text-lg": rule.properties["font-size"] = 18
		"text-xl": rule.properties["font-size"] = 20
		"text-2xl": rule.properties["font-size"] = 24
		"text-3xl": rule.properties["font-size"] = 30
		"text-4xl": rule.properties["font-size"] = 36
		"text-5xl": rule.properties["font-size"] = 48
		"text-6xl": rule.properties["font-size"] = 60
		
		# Handle text alignment classes
		"text-left": rule.properties["text-align"] = "left"
		"text-center": rule.properties["text-align"] = "center"
		"text-right": rule.properties["text-align"] = "right"
		"text-justify": rule.properties["text-align"] = "justify"
	
	# Width
	if utility_name.begins_with("w-"):
		var val = utility_name.substr(2)
		if val.begins_with("[") and val.ends_with("]"):
			val = val.substr(1, val.length() - 2)
		rule.properties["width"] = SizeUtils.parse_size(val)
		return
	# Height
	if utility_name.begins_with("h-"):
		var val = utility_name.substr(2)
		if val.begins_with("[") and val.ends_with("]"):
			val = val.substr(1, val.length() - 2)
		rule.properties["height"] = SizeUtils.parse_size(val)
		return
	# Min width
	if utility_name.begins_with("min-w-"):
		var val = utility_name.substr(6)
		rule.properties["min-width"] = SizeUtils.parse_size(val)
		return
	# Min height
	if utility_name.begins_with("min-h-"):
		var val = utility_name.substr(6)
		rule.properties["min-height"] = SizeUtils.parse_size(val)
		return
	# Max width
	if utility_name.begins_with("max-w-"):
		var val = utility_name.substr(6)
		rule.properties["max-width"] = SizeUtils.parse_size(val)
		return
	# Max height
	if utility_name.begins_with("max-h-"):
		var val = utility_name.substr(6)
		rule.properties["max-height"] = SizeUtils.parse_size(val)
		return

	# Flex container
	if utility_name == "flex":
		rule.properties["display"] = "flex"
		return
	if utility_name == "inline-flex":
		rule.properties["display"] = "inline-flex"
		return

	# Flex direction
	match utility_name:
		"flex-row": rule.properties["flex-direction"] = "row"; return
		"flex-row-reverse": rule.properties["flex-direction"] = "row-reverse"; return
		"flex-col": rule.properties["flex-direction"] = "column"; return
		"flex-col-reverse": rule.properties["flex-direction"] = "column-reverse"; return

	# Flex wrap
	match utility_name:
		"flex-nowrap": rule.properties["flex-wrap"] = "nowrap"; return
		"flex-wrap": rule.properties["flex-wrap"] = "wrap"; return
		"flex-wrap-reverse": rule.properties["flex-wrap"] = "wrap-reverse"; return

	# Justify content
	match utility_name:
		"justify-start": rule.properties["justify-content"] = "flex-start"; return
		"justify-end": rule.properties["justify-content"] = "flex-end"; return
		"justify-center": rule.properties["justify-content"] = "center"; return
		"justify-between": rule.properties["justify-content"] = "space-between"; return
		"justify-around": rule.properties["justify-content"] = "space-around"; return
		"justify-evenly": rule.properties["justify-content"] = "space-evenly"; return

	# Align items
	match utility_name:
		"items-start": rule.properties["align-items"] = "flex-start"; return
		"items-end": rule.properties["align-items"] = "flex-end"; return
		"items-center": rule.properties["align-items"] = "center"; return
		"items-baseline": rule.properties["align-items"] = "baseline"; return
		"items-stretch": rule.properties["align-items"] = "stretch"; return

	# Align content
	match utility_name:
		"content-start": rule.properties["align-content"] = "flex-start"; return
		"content-end": rule.properties["align-content"] = "flex-end"; return
		"content-center": rule.properties["align-content"] = "center"; return
		"content-between": rule.properties["align-content"] = "space-between"; return
		"content-around": rule.properties["align-content"] = "space-around"; return
		"content-stretch": rule.properties["align-content"] = "stretch"; return

	# Gap
	if utility_name.begins_with("gap-"):
		var val = utility_name.substr(4)
		rule.properties["gap"] = SizeUtils.parse_size(val)
		return
	if utility_name.begins_with("row-gap-"):
		var val = utility_name.substr(8)
		rule.properties["row-gap"] = SizeUtils.parse_size(val)
		return
	if utility_name.begins_with("col-gap-"):
		var val = utility_name.substr(8)
		rule.properties["column-gap"] = SizeUtils.parse_size(val)
		return

	# FLEX ITEM PROPERTIES
	if utility_name.begins_with("flex-grow-"):
		var val = utility_name.substr(10)
		rule.properties["flex-grow"] = val.to_float()
		return
	if utility_name.begins_with("flex-shrink-"):
		var val = utility_name.substr(12)
		rule.properties["flex-shrink"] = val.to_float()
		return
	if utility_name.begins_with("basis-"):
		var val = utility_name.substr(6)
		rule.properties["flex-basis"] = SizeUtils.parse_size(val)
		return

	# Align self
	match utility_name:
		"self-auto": rule.properties["align-self"] = "auto"; return
		"self-start": rule.properties["align-self"] = "flex-start"; return
		"self-end": rule.properties["align-self"] = "flex-end"; return
		"self-center": rule.properties["align-self"] = "center"; return
		"self-stretch": rule.properties["align-self"] = "stretch"; return
		"self-baseline": rule.properties["align-self"] = "baseline"; return

	# Order
	if utility_name.begins_with("order-"):
		var val = utility_name.substr(6)
		rule.properties["order"] = val.to_int()
		return

	if utility_name == "rounded":
		rule.properties["border-radius"] = "4px"  # Default rounded
		return

	# Handle padding classes like p-8, px-4, py-2, etc.
	if utility_name.begins_with("p-"):
		var val = utility_name.substr(2)
		var padding_value = SizeUtils.parse_size(val)
		rule.properties["padding"] = padding_value
		return
	if utility_name.begins_with("px-"):
		var val = utility_name.substr(3)
		var padding_value = SizeUtils.parse_size(val)
		rule.properties["padding-left"] = padding_value
		rule.properties["padding-right"] = padding_value
		return
	if utility_name.begins_with("py-"):
		var val = utility_name.substr(3)
		var padding_value = SizeUtils.parse_size(val)
		rule.properties["padding-top"] = padding_value
		rule.properties["padding-bottom"] = padding_value
		return
	if utility_name.begins_with("pt-"):
		var val = utility_name.substr(3)
		var padding_value = SizeUtils.parse_size(val)
		rule.properties["padding-top"] = padding_value
		return
	if utility_name.begins_with("pr-"):
		var val = utility_name.substr(3)
		var padding_value = SizeUtils.parse_size(val)
		rule.properties["padding-right"] = padding_value
		return
	if utility_name.begins_with("pb-"):
		var val = utility_name.substr(3)
		var padding_value = SizeUtils.parse_size(val)
		rule.properties["padding-bottom"] = padding_value
		return
	if utility_name.begins_with("pl-"):
		var val = utility_name.substr(3)
		var padding_value = SizeUtils.parse_size(val)
		rule.properties["padding-left"] = padding_value
		return

	# Handle border radius classes like rounded, rounded-lg, rounded-[12px]
	if utility_name == "rounded":
		rule.properties["border-radius"] = "4px"
		return
	if utility_name == "rounded-none":
		rule.properties["border-radius"] = "0px"
		return
	if utility_name == "rounded-sm":
		rule.properties["border-radius"] = "2px"
		return
	if utility_name == "rounded-md":
		rule.properties["border-radius"] = "6px"
		return
	if utility_name == "rounded-lg":
		rule.properties["border-radius"] = "8px"
		return
	if utility_name == "rounded-xl":
		rule.properties["border-radius"] = "12px"
		return
	if utility_name == "rounded-2xl":
		rule.properties["border-radius"] = "16px"
		return
	if utility_name == "rounded-3xl":
		rule.properties["border-radius"] = "24px"
		return
	if utility_name == "rounded-full":
		rule.properties["border-radius"] = "9999px"
		return
	
	# Handle custom border radius like rounded-[12px]
	if utility_name.begins_with("rounded-[") and utility_name.ends_with("]"):
		var radius_value = SizeUtils.extract_bracket_content(utility_name, 8)  # after 'rounded-'
		rule.properties["border-radius"] = radius_value
		return

	# Handle numeric border radius classes like rounded-8, rounded-12, etc.
	if utility_name.begins_with("rounded-"):
		var val = utility_name.substr(8)
		if val.is_valid_int():
			rule.properties["border-radius"] = str(int(val)) + "px"
			return

	# Handle margin auto classes for centering
	if utility_name == "mx-auto":
		rule.properties["mx-auto"] = true
		return
	if utility_name == "my-auto":
		rule.properties["my-auto"] = true
		return
	if utility_name == "m-auto":
		rule.properties["mx-auto"] = true
		rule.properties["my-auto"] = true
		return
	
	# Apply border properties
	var apply_border = func(side: String, width: String = "", color = null, style: String = "solid"):
		var prefix = "border" + ("-" + side if side != "" else "")
		if width != "":
			rule.properties[prefix + "-width"] = width
		if color != null:
			rule.properties[prefix + "-color"] = color
		if style != "":
			rule.properties[prefix + "-style"] = style
	
	# Handle border utilities
	if utility_name == "border":
		apply_border.call("", "1px", Color.BLACK)
		return
	
	if utility_name == "border-none":
		rule.properties["border-style"] = "none"
		return
	
	# Individual border sides - pattern: border-{side}-{value}
	var border_sides = ["t", "r", "b", "l"]
	var side_map = {"t": "top", "r": "right", "b": "bottom", "l": "left"}
	
	for side in border_sides:
		var short_side = side
		var full_side = side_map[side]
		
		# Basic side border (e.g., border-t)
		if utility_name == "border-" + short_side:
			apply_border.call(full_side, "1px")
			return
		
		# Side with value (e.g., border-t-2, border-t-red-500)
		if utility_name.begins_with("border-" + short_side + "-"):
			var val = utility_name.substr(9)  # after "border-X-"
			
			# Check for bracket notation first
			if utility_name.begins_with("border-" + short_side + "-[") and utility_name.ends_with("]"):
				var value = SizeUtils.extract_bracket_content(utility_name, 9)
				if value.begins_with("#") or ColorUtils.parse_color(value) != null:
					apply_border.call(full_side, "", ColorUtils.parse_color(value))
				else:
					apply_border.call(full_side, value)
				return
			
			# Check if it's a numeric width
			if val.is_valid_int():
				apply_border.call(full_side, str(int(val)) + "px")
				return
			
			# Check if it's a color
			var color = ColorUtils.get_color(val)
			if color != null:
				apply_border.call(full_side, "", color)
				return
	
	# General border width (e.g., border-2)
	if utility_name.begins_with("border-"):
		var val = utility_name.substr(7)
		
		# Custom border width like border-[2px]
		if utility_name.begins_with("border-[") and utility_name.ends_with("]"):
			var value = SizeUtils.extract_bracket_content(utility_name, 7)
			if value.begins_with("#"):
				apply_border.call("", "", ColorUtils.parse_color(value))
			else:
				apply_border.call("", value)
			return
		
		# Numeric width
		if val.is_valid_int():
			apply_border.call("", str(int(val)) + "px")
			return
		
		# Color name
		var color = ColorUtils.get_color(val)
		if color != null:
			apply_border.call("", "", color)
			return

	# Handle more utility classes as needed
	# Add more cases here for other utilities

static func parse_inline_style(style_string: String) -> Dictionary:
	var rule = CSSRule.new()
	rule.selector = ""
	rule.init(rule.selector)
	
	var utility_classes = style_string.split(" ")
	for utility_name in utility_classes:
		utility_name = utility_name.strip_edges()
		if utility_name.is_empty():
			continue
		parse_utility_class_internal(rule, utility_name)
	
	return rule.properties
