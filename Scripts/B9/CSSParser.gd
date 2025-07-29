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
		if event_prefix.length() > 0:
			specificity += 10

class CSSStylesheet:
	var rules: Array[CSSRule] = []
	
	func add_rule(rule: CSSRule):
		rules.append(rule)
	
	func get_styles_for_element(tag_name: String, event: String = "") -> Dictionary:
		var styles = {}
		
		# Sort rules by specificity
		var applicable_rules: Array[CSSRule] = []
		for rule in rules:
			if selector_matches(rule, tag_name, event):
				applicable_rules.append(rule)
		
		applicable_rules.sort_custom(func(a, b): return a.specificity < b.specificity)
		
		# Apply styles in order of specificity
		for rule in applicable_rules:
			for property in rule.properties:
				styles[property] = rule.properties[property]
		
		return styles
	
	func selector_matches(rule: CSSRule, tag_name: String, event: String = "") -> bool:
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
		var color_value = extract_bracket_content(utility_name, 5)  # after 'text-'
		rule.properties["color"] = parse_color(color_value)
		return

	# Handle background color classes like bg-[#ff0000]
	if utility_name.begins_with("bg-[") and utility_name.ends_with("]"):
		var color_value = extract_bracket_content(utility_name, 3)  # after 'bg-'
		var color = parse_color(color_value)
		rule.properties["background-color"] = color
		return

	# e.g. max-w-[123px], w-[50%], h-[2rem]
	if utility_name.match("^max-w-\\[.*\\]$"):
		var val = extract_bracket_content(utility_name, 6)
		rule.properties["max-width"] = val
		return
	if utility_name.match("^max-h-\\[.*\\]$"):
		var val = extract_bracket_content(utility_name, 6)
		rule.properties["max-height"] = val
		return
	if utility_name.match("^min-w-\\[.*\\]$"):
		var val = extract_bracket_content(utility_name, 6)
		rule.properties["min-width"] = val
		return
	if utility_name.match("^min-h-\\[.*\\]$"):
		var val = extract_bracket_content(utility_name, 6)
		rule.properties["min-height"] = val
		return
	if utility_name.match("^w-\\[.*\\]$"):
		var val = extract_bracket_content(utility_name, 2)
		rule.properties["width"] = val
		return
	if utility_name.match("^h-\\[.*\\]$"):
		var val = extract_bracket_content(utility_name, 2)
		rule.properties["height"] = val
		return

	# Handle font weight
	if utility_name == "font-bold":
		rule.properties["font-bold"] = true
		return

	# Handle font mono
	if utility_name == "font-mono":
		rule.properties["font-mono"] = true
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
		rule.properties["width"] = parse_size(val)
		return
	# Height
	if utility_name.begins_with("h-"):
		var val = utility_name.substr(2)
		rule.properties["height"] = parse_size(val)
		return
	# Min width
	if utility_name.begins_with("min-w-"):
		var val = utility_name.substr(6)
		rule.properties["min-width"] = parse_size(val)
		return
	# Min height
	if utility_name.begins_with("min-h-"):
		var val = utility_name.substr(6)
		rule.properties["min-height"] = parse_size(val)
		return
	# Max width
	if utility_name.begins_with("max-w-"):
		var val = utility_name.substr(6)
		rule.properties["max-width"] = parse_size(val)
		return
	# Max height
	if utility_name.begins_with("max-h-"):
		var val = utility_name.substr(6)
		rule.properties["max-height"] = parse_size(val)
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
		rule.properties["gap"] = parse_size(val)
		return
	if utility_name.begins_with("row-gap-"):
		var val = utility_name.substr(8)
		rule.properties["row-gap"] = parse_size(val)
		return
	if utility_name.begins_with("col-gap-"):
		var val = utility_name.substr(8)
		rule.properties["column-gap"] = parse_size(val)
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
		rule.properties["flex-basis"] = parse_size(val)
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
		var radius_value = extract_bracket_content(utility_name, 8)  # after 'rounded-'
		rule.properties["border-radius"] = radius_value
		return

	# Handle more utility classes as needed
	# Add more cases here for other utilities

static func parse_size(val: String) -> String:
	var named = {
		"0": "0px", "1": "4px", "2": "8px", "3": "12px", "4": "16px", "5": "20px", "6": "24px", "8": "32px", "10": "40px",
		"12": "48px", "16": "64px", "20": "80px", "24": "96px", "28": "112px", "32": "128px", "36": "144px", "40": "160px",
		"44": "176px", "48": "192px", "52": "208px", "56": "224px", "60": "240px", "64": "256px", "72": "288px", "80": "320px", "96": "384px",
		"3xs": "256px", "2xs": "288px", "xs": "320px", "sm": "384px", "md": "448px", "lg": "512px",
		"xl": "576px", "2xl": "672px", "3xl": "768px", "4xl": "896px", "5xl": "1024px", "6xl": "1152px", "7xl": "1280px"
	}
	if named.has(val):
		return named[val]
	# Fractional (e.g. 1/2, 1/3)
	if val.find("/") != -1:
		var parts = val.split("/")
		if parts.size() == 2 and parts[1].is_valid_int() and parts[0].is_valid_int():
			var frac = float(parts[0]) / float(parts[1])
			return str(frac * 100.0) + "%"
	if val.is_valid_int():
		return str(int(val) * 16) + "px"
	return val

# Helper to extract content inside first matching brackets after a given index
static func extract_bracket_content(string: String, start_idx: int) -> String:
	var open_idx = string.find("[", start_idx)
	if open_idx == -1:
		return ""
	var close_idx = string.find("]", open_idx)
	if close_idx == -1:
		return ""
	return string.substr(open_idx + 1, close_idx - open_idx - 1)

static  func parse_color(color_string: String) -> Color:
	color_string = color_string.strip_edges()
	
	# Handle hex colors
	if color_string.begins_with("#"):
		return Color.from_string(color_string, Color.WHITE)
	
	# Handle rgb/rgba
	if color_string.begins_with("rgb"):
		var regex = RegEx.new()
		regex.compile("rgba?\\(([^)]+)\\)")
		var result = regex.search(color_string)
		if result:
			var values = result.get_string(1).split(",")
			if values.size() >= 3:
				var r = values[0].strip_edges().to_float() / 255.0
				var g = values[1].strip_edges().to_float() / 255.0
				var b = values[2].strip_edges().to_float() / 255.0
				var a = 1.0
				if values.size() >= 4:
					a = values[3].strip_edges().to_float()
				return Color(r, g, b, a)
	
	# Handle named colors
	# TODO: map to actual Tailwind colors
	match color_string.to_lower():
		"red": return Color.RED
		"green": return Color.GREEN
		"blue": return Color.BLUE
		"white": return Color.WHITE
		"black": return Color.BLACK
		"yellow": return Color.YELLOW
		"cyan": return Color.CYAN
		"magenta": return Color.MAGENTA
		_: return Color.from_string(color_string, Color.WHITE)

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
