@tool
class_name AmbientBrowserWidget extends Button

var material_json: Dictionary

var root_ui: AmbientUI

var browser: AmbientBrowser


func update(ui: AmbientUI, p_browser: AmbientBrowser) -> void:
	root_ui = ui
	browser = p_browser
	hide()
	await ready
	tooltip_text = material_json.get("title", "")

	var thumb_url = material_json.get("thumbnail", "")
	if not thumb_url.is_empty():
		var texture_buffer = await AmbientAPI.http_request_raw(thumb_url)
		if texture_buffer and texture_buffer.size() >= 4:
			var thumbnail_image := Image.new()
			var err = thumbnail_image.load_png_from_buffer(texture_buffer[3])
			if err == OK:
				%Thumbnail.texture = ImageTexture.create_from_image(thumbnail_image)
	show()


func _pressed() -> void:
	if browser:
		browser.select_asset(material_json, %Thumbnail.texture)
