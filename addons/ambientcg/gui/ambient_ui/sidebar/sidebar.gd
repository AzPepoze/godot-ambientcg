@tool
class_name AmbientSidebar extends VBoxContainer

const DOWNLOAD_ITEM = preload("res://addons/ambientcg/gui/download_item/download_item.tscn")

var selected_asset_json: Dictionary
var parsed_implementations: Array[Dictionary]
var _pending_tasks: int = 0

@onready var asset_inspector: VBoxContainer = %AssetInspector
@onready var sidebar_placeholder: CenterContainer = %SidebarPlaceholder
@onready var preview_rect: TextureRect = %PreviewRect
@onready var asset_title_label: Label = %AssetTitle
@onready var zip_radio: CheckBox = %ZipRadio
@onready var usdz_radio: CheckBox = %UsdzRadio
@onready var groups_container: VBoxContainer = %GroupsContainer
@onready var download_list: VBoxContainer = %DownloadList


func _ready() -> void:
	if not Engine.is_editor_hint():
		return

	if not AmbientAPI.download_started.is_connected(_on_download_started):
		AmbientAPI.download_started.connect(_on_download_started)

	zip_radio.toggled.connect(_on_container_changed)
	usdz_radio.toggled.connect(_on_container_changed)


func display_asset(asset_json: Dictionary, thumb: Texture2D):
	selected_asset_json = asset_json
	asset_inspector.show()
	sidebar_placeholder.hide()

	preview_rect.texture = thumb
	asset_title_label.text = asset_json.get("title", "Unknown Asset")

	# Clear and show loading
	for c in groups_container.get_children():
		c.queue_free()

	var loading_label = Label.new()
	loading_label.text = "Loading qualities..."
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	groups_container.add_child(loading_label)

	await fetch_qualities()
	render_qualities()


func fetch_qualities():
	var implementations = selected_asset_json.get("implementation_uris", {})
	parsed_implementations.clear()

	if not implementations is Dictionary:
		AmbientLogger.warn("Asset implementations data is invalid or empty", "UI")
		return

	_pending_tasks = implementations.size()
	if _pending_tasks == 0:
		AmbientLogger.info("No implementations found for this asset", "UI")
		return

	AmbientLogger.debug("Starting parallel fetch for %d implementations" % _pending_tasks, "UI")
	for implementation_uri in implementations.values():
		_start_fetch_task(implementation_uri)

	# Polling wait for parallel tasks to finish
	while _pending_tasks > 0:
		await get_tree().process_frame

	AmbientLogger.info(
		"Successfully fetched %d quality options" % parsed_implementations.size(), "UI"
	)


# Helper to run parallel fetch without blocking the main loop
func _start_fetch_task(uri: String):
	if uri.is_empty():
		_pending_tasks -= 1
		return

	AmbientLogger.debug("Fetching implementation: %s" % uri, "Network")
	var request = await AmbientAPI.http_request(uri)
	if request.size() >= 4:
		var result := AmbientAPI.parse_pba_json(request[3])
		var options = AmbientParser.parse_asset_implementation(result)
		AmbientLogger.debug("Parsed %d options from %s" % [options.size(), uri], "Data")
		parsed_implementations.append_array(options)
	else:
		AmbientLogger.error("Failed to fetch implementation: %s" % uri, "Network")

	_pending_tasks -= 1


func _on_container_changed(_toggled: bool):
	if _toggled:
		render_qualities()


func render_qualities():
	for c in groups_container.get_children():
		c.queue_free()

	var filter_ext = "zip" if zip_radio.button_pressed else "usdz"

	# Grouping: JPEG first, then PNG
	var formats = ["JPG", "PNG"]
	var grouped_data = {"JPG": [], "PNG": []}

	for opt in parsed_implementations:
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

		var grid = GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 5)
		grid.add_theme_constant_override("v_separation", 5)
		group_vbox.add_child(grid)

		for opt in list:
			var btn = Button.new()
			btn.text = opt.get("local_file_name", "").replace("." + filter_ext, "")
			btn.add_theme_font_size_override("font_size", 11)
			btn.custom_minimum_size = Vector2(100, 30)
			btn.pressed.connect(_on_download_pressed.bind(opt))
			grid.add_child(btn)

		groups_container.add_child(group_vbox)


func _sort_by_resolution(a: Dictionary, b: Dictionary) -> bool:
	var res_a = _extract_res(a.get("local_file_name", ""))
	var res_b = _extract_res(b.get("local_file_name", ""))
	return res_a < res_b


func _extract_res(file_name: String) -> int:
	# Use RegEx for more reliable extraction of the "NK" pattern
	var regex = RegEx.new()
	regex.compile("(\\d+)K")
	var result = regex.search(file_name)
	if result:
		return result.get_string(1).to_int()
	return 0


func _on_download_pressed(data: Dictionary):
	# Find root UI
	var root = get_parent()
	while root and not root is AmbientUI:
		root = root.get_parent()

	if root:
		AmbientFileHandler.download_file_from_data(data, root)


func _on_download_started(url: String, asset_name: String):
	var item = DOWNLOAD_ITEM.instantiate()
	download_list.add_child(item)
	item.setup(url, asset_name)
