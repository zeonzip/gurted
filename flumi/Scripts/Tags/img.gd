extends TextureRect

func init(element: HTMLParser.HTMLElement, _parser: HTMLParser = null) -> void:
	var src = element.get_attribute("src")
	if !src: return print("Ignoring <img/> tag without \"src\" attribute.")
	
	texture = await Network.fetch_image(src)
	
	var texture_size = texture.get_size()
	custom_minimum_size = texture_size
	size = texture_size
