@tool
class_name AmbientBrowser extends MarginContainer

const BROWSER_WIDGET = preload("res://addons/ambientcg/gui/browser_widget/browser_widget.tscn")

var type_text: String = "Any"
var resolution_text: String = "Any"
var sort_text: String = "Popular"
var v_scroll_bar: VScrollBar
var next_query_uri: String
var last_search_result: Dictionary
var awaiting_search_finish: bool = false

@onready var sidebar: AmbientSidebar = %Sidebar
@onready var search_result_count: Label = %SearchResultCount
@onready var api_version_info_label: Label = %APIVersionInfo
@onready var type_options: OptionButton = %TypeOptions
@onready var resolution_options: OptionButton = %ResolutionOptions
@onready var sort_options: OptionButton = %SortOptions
@onready var search_bar: LineEdit = %SearchBar
@onready var search_scroll: ScrollContainer = %SearchScroll
@onready var search_grid: GridContainer = %SearchGrid
@onready var searching_indicator: Label = %SearchingIndicator
@onready var status_overlay: CenterContainer = %StatusOverlay
@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	if not Engine.is_editor_hint():
		return

	setup_filters()
	connect_signals()
	init_browser()


func setup_filters():
	resolution_options.clear()
	resolution_options.add_item("Any")
	resolution_options.add_item("1K")
	resolution_options.add_item("2K")
	resolution_options.add_item("4K")
	resolution_options.add_item("8K")

	sort_options.clear()
	sort_options.add_item("Popular")
	sort_options.add_item("Latest")
	sort_options.add_item("Alphabetical")


func init_browser():
	await AmbientAPI.api_init()

	api_version_info_label.text = AmbientParser.api_info_to_version_string(
		AmbientAPI.api_information
	)
	AmbientParser.api_info_to_option_button(type_options, AmbientAPI.api_information)

	if not AmbientAPI.api_information.is_empty():
		search(search_bar.text)
	else:
		status_overlay.show()
		status_label.text = "Error: Could not connect to AmbientCG API"


func connect_signals():
	if not resized.is_connected(_resized):
		resized.connect(_resized)

	type_options.item_selected.connect(_on_filter_changed.bind("type"))
	resolution_options.item_selected.connect(_on_filter_changed.bind("resolution"))
	sort_options.item_selected.connect(_on_filter_changed.bind("sort"))

	if not search_bar.text_submitted.is_connected(search):
		search_bar.text_submitted.connect(search.bind(false))


func _on_filter_changed(index: int, filter_type: String):
	match filter_type:
		"type":
			type_text = type_options.get_item_text(index)
		"resolution":
			resolution_text = resolution_options.get_item_text(index)
		"sort":
			sort_text = sort_options.get_item_text(index)

	search(search_bar.text, false)


func select_asset(asset_json: Dictionary, thumb_texture: Texture2D):
	if sidebar:
		sidebar.display_asset(asset_json, thumb_texture)


func _process(_delta: float) -> void:
	if not visible:
		return
	if v_scroll_bar == null:
		v_scroll_bar = search_scroll.get_v_scroll_bar()
	else:
		var current_y = v_scroll_bar.size.y + v_scroll_bar.value
		var should_load_more = current_y > v_scroll_bar.max_value * 0.8

		if should_load_more and not awaiting_search_finish:
			search("", true)

	searching_indicator.visible = awaiting_search_finish


func _resized() -> void:
	if search_grid:
		search_grid.columns = max(1, floor(search_scroll.size.x / 140.0))


func search(search_query: String = "", use_next_query: bool = false):
	awaiting_search_finish = true

	if not use_next_query:
		status_overlay.show()
		status_label.text = "Searching..."
		search_result_count.text = ""

	var search_result := await AmbientAPI.search_assets(
		search_query, type_text, next_query_uri if use_next_query else ""
	)

	if awaiting_search_finish:
		var parsed := AmbientParser.parse_search_query_data(search_result)
		last_search_result = parsed
		next_query_uri = parsed.get("next_query_uri", "")

		var total_results = int(parsed.get("result_count_total", 0))

		create_search_results(parsed, not use_next_query)

		search_result_count.text = "%s Results Found" % total_results

		if total_results == 0:
			status_overlay.show()
			status_label.text = "No Results Found"
		else:
			status_overlay.hide()
	else:
		search_result_count.text = ""
		status_overlay.hide()

	awaiting_search_finish = false


func clear_search_results() -> void:
	for c in search_grid.get_children():
		c.queue_free()


func create_search_results(data: Dictionary, clear: bool) -> void:
	if clear:
		clear_search_results()

	await get_tree().process_frame

	for asset in data.get("assets"):
		if resolution_text != "Any":
			var title: String = asset.get("title", "")
			if not title.contains(resolution_text):
				continue

		var widget: AmbientBrowserWidget = BROWSER_WIDGET.instantiate()
		widget.material_json = asset
		widget.update(owner as AmbientUI, self)

		search_grid.add_child(widget)
