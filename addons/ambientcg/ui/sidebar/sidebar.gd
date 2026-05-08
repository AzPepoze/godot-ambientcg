@tool
extends VBoxContainer

const DOWNLOAD_ITEM_SCENE = preload(
	"res://addons/ambientcg/ui/components/download/download_item.tscn"
)
const CONFIG = preload("res://addons/ambientcg/core/ambient_config.gd")

var current_asset_id: String = ""
var asset_data: Dictionary = {}

# Variables for the fetched implementations
var _fetching_count: int = 0
var _parsed_implementations: Array[Dictionary] = []

@onready var asset_inspector: VBoxContainer = %AssetInspector
@onready var sidebar_placeholder: CenterContainer = %SidebarPlaceholder
@onready var asset_title: Label = %AssetTitle
@onready var preview_rect: TextureRect = %PreviewRect
@onready var groups_container: VBoxContainer = %GroupsContainer
@onready var download_list: VBoxContainer = %DownloadList
@onready var zip_radio: CheckBox = %ZipRadio
@onready var usdz_radio: CheckBox = %UsdzRadio


func _ready() -> void:
	asset_inspector.hide()
	sidebar_placeholder.show()
	AmbientCG.signals.download_started.connect(_on_download_started)


func display_asset(asset: Dictionary) -> void:
	var new_asset_id = asset.get("id", "")

	# Skip re-fetching if the user clicked the exact same asset again
	if current_asset_id == new_asset_id and not current_asset_id.is_empty():
		asset_inspector.show()
		sidebar_placeholder.hide()
		return

	current_asset_id = new_asset_id
	asset_inspector.hide()
	sidebar_placeholder.show()

	for child in groups_container.get_children():
		child.queue_free()

	asset_data = asset

	if asset_data.is_empty():
		AmbientCG.logger.error("Failed to fetch asset details", "UI")
		return

	asset_title.text = current_asset_id

	# Try to get thumbnail (some API formats might use different keys)
	var thumbnail_url = asset_data.get("thumbnail", "")
	if not thumbnail_url.is_empty():
		_load_preview(thumbnail_url)
	else:
		preview_rect.texture = null

	var loader_label = Label.new()
	loader_label.name = "LoaderLabel"
	loader_label.text = "Fetching download sizes..."
	loader_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	groups_container.add_child(loader_label)

	sidebar_placeholder.hide()
	asset_inspector.show()

	# Start fetching implementations
	_parsed_implementations.clear()
	var implementation_uris = asset_data.get("implementation_uris", {})
	_fetching_count = implementation_uris.size()

	if _fetching_count == 0:
		loader_label.text = "No downloads available."
		return

	for qual in implementation_uris.keys():
		_fetch_single_implementation(implementation_uris[qual])


func _fetch_single_implementation(uri: String) -> void:
	var impl_data = await AmbientCG.api.api_init_implementation(uri)
	var parsed_impl = AmbientCG.Parser.parse_asset_implementation(impl_data)
	if parsed_impl.size() > 0:
		_parsed_implementations.append(parsed_impl[0])

	_fetching_count -= 1
	if _fetching_count <= 0:
		_build_download_ui()


func _on_container_changed(_toggled: bool):
	if _toggled:
		_build_download_ui()


func _build_download_ui() -> void:
	for c in groups_container.get_children():
		c.queue_free()

	if _parsed_implementations.is_empty():
		var err_label = Label.new()
		err_label.text = "Failed to load downloads."
		err_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		groups_container.add_child(err_label)
		return

	var filter_ext = "zip" if zip_radio.button_pressed else "usdz"

	# Grouping: JPEG first, then PNG
	var formats = ["JPG", "PNG"]
	var grouped_data = {"JPG": [], "PNG": []}

	for opt in _parsed_implementations:
		var file_name = str(opt.get("local_file_name", ""))
		if not file_name.to_lower().ends_with(filter_ext):
			continue

		if file_name.contains("JPG"):
			grouped_data["JPG"].append(opt)
		elif file_name.contains("PNG"):
			grouped_data["PNG"].append(opt)

	for fmt in formats:
		var list = grouped_data[fmt]
		if list.is_empty():
			continue

		list.sort_custom(_sort_by_resolution)

		var group_vbox = VBoxContainer.new()
		group_vbox.add_theme_constant_override("separation", 5)

		var group_label = Label.new()
		group_label.text = fmt + " Formats"
		group_label.add_theme_font_size_override("font_size", 14)
		group_label.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
		group_vbox.add_child(group_label)

		var columns_hbox = HBoxContainer.new()
		columns_hbox.add_theme_constant_override("separation", 5)
		group_vbox.add_child(columns_hbox)

		var col1 = VBoxContainer.new()
		col1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col1.add_theme_constant_override("separation", 5)
		columns_hbox.add_child(col1)

		var col2 = VBoxContainer.new()
		col2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col2.add_theme_constant_override("separation", 5)
		columns_hbox.add_child(col2)

		var half_point = ceil(list.size() / 2.0)
		for i in range(list.size()):
			var opt = list[i]
			var btn = Button.new()
			var file_size = AmbientCG.Utils.format_file_size(opt.get("file_size", 0))
			# Show resolution like "1K" and the file size nicely
			btn.text = (
				opt.get("local_file_name", "").replace("." + filter_ext, "").replace(
					current_asset_id + "_", ""
				)
				+ " ("
				+ file_size
				+ ")"
			)
			btn.add_theme_font_size_override("font_size", 11)
			btn.custom_minimum_size = Vector2(100, 30)
			btn.pressed.connect(func(): AmbientCG.file_handler.download_file_from_data(opt, self))

			if i < half_point:
				col1.add_child(btn)
			else:
				col2.add_child(btn)

		groups_container.add_child(group_vbox)


func _sort_by_resolution(a: Dictionary, b: Dictionary) -> bool:
	var res_a = _extract_res(a.get("local_file_name", ""))
	var res_b = _extract_res(b.get("local_file_name", ""))
	return res_a < res_b


func _extract_res(file_name: String) -> int:
	var regex = RegEx.new()
	regex.compile("(\\d+)K")
	var result = regex.search(file_name)
	if result:
		return result.get_string(1).to_int()
	return 0


func _load_preview(url: String) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	http.request(url)
	var response = await http.request_completed
	remove_child(http)
	http.queue_free()

	if response[1] == 200:
		var headers: PackedStringArray = response[2]
		var buffer: PackedByteArray = response[3]
		var img = Image.new()
		var err = FAILED

		var content_type = ""
		for header in headers:
			if header.to_lower().begins_with("content-type:"):
				content_type = header.to_lower()
				break

		if "webp" in content_type:
			err = img.load_webp_from_buffer(buffer)
		elif "png" in content_type:
			err = img.load_png_from_buffer(buffer)
		else:
			err = img.load_jpg_from_buffer(buffer)

		if err == OK:
			preview_rect.texture = ImageTexture.create_from_image(img)


func _on_download_started(_url: String, asset_name: String) -> void:
	var item = DOWNLOAD_ITEM_SCENE.instantiate()
	download_list.add_child(item)
	item.setup(_url, asset_name)
