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
				event_prefix = parts[0]
				selector = parts[1]
	
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
	
	# Handle more utility classes as needed
	# Add more cases here for other utilities

# Helper to extract content inside first matching brackets after a given index
func extract_bracket_content(str: String, start_idx: int) -> String:
	var open_idx = str.find("[", start_idx)
	if open_idx == -1:
		return ""
	var close_idx = str.find("]", open_idx)
	if close_idx == -1:
		return ""
	return str.substr(open_idx + 1, close_idx - open_idx - 1)

func parse_color(color_string: String) -> Color:
	print("DEBUG: parsing color: ", color_string)
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
	var parser = CSSParser.new()
	var rule_data = {
		"selector": "",
		"properties": style_string
	}
	var rule = parser.parse_rule(rule_data)
	return rule.properties if rule else {}
