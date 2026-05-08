@tool
extends PanelContainer

var asset_data: Dictionary = {}
var main_owner: Control
var browser: Control

@onready var texture_rect: TextureRect = %TextureRect
@onready var title_label: Label = %TitleLabel
@onready var download_button: Button = %DownloadButton


func setup(data: Dictionary, p_owner: Control, p_browser: Control) -> void:
	asset_data = data
	main_owner = p_owner
	browser = p_browser

	title_label.text = asset_data.get("title", "Unknown Asset")
	var thumbnail_url = asset_data.get("thumbnail", "")

	if not thumbnail_url.is_empty():
		_load_thumbnail(thumbnail_url)


func _load_thumbnail(url: String) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	http.request(url)
	var response = await http.request_completed
	remove_child(http)
	http.queue_free()

	if response[1] == 200:
		var img = Image.new()
		var err = img.load_jpg_from_buffer(response[3])
		if err == OK:
			texture_rect.texture = ImageTexture.create_from_image(img)


func _on_button_pressed() -> void:
	if browser and browser.has_method("display_asset_details"):
		browser.display_asset_details(asset_data.get("id", ""))
