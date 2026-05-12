@tool
extends MarginContainer

const BROWSER_WIDGET = preload(
	"res://addons/ambientcg/ui/components/browser_widget/browser_widget.tscn"
)
const CONFIG = preload("res://addons/ambientcg/core/ambient_config.gd")

var type_text: String = "Any"
var resolution_text: String = "Any"
var sort_text: String = "Popular"
var next_query_uri: String = ""
var awaiting_search_finish: bool = false

var v_scroll_bar: VScrollBar
@onready var sidebar: Control = %Sidebar
@onready var search_result_count: Label = %SearchResultCount
@onready var api_version_info_label: Label = %APIVersionInfo
@onready var type_options: OptionButton = %TypeOptions
@onready var resolution_options: OptionButton = %ResolutionOptions
@onready var sort_options: OptionButton = %SortOptions
@onready var search_bar: LineEdit = %SearchBar
@onready var search_scroll: ScrollContainer = %SearchScroll
@onready var search_grid: HFlowContainer = %SearchGrid
@onready var searching_indicator: Label = %SearchingIndicator
@onready var status_overlay: CenterContainer = %StatusOverlay
@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	setup_filters()
	init_browser()

	type_options.item_selected.connect(_on_filter_changed)
	resolution_options.item_selected.connect(_on_filter_changed)
	sort_options.item_selected.connect(_on_filter_changed)
	search_bar.text_submitted.connect(func(_text): search(search_bar.text))


func _on_filter_changed(_index: int = 0) -> void:
	type_text = type_options.get_item_text(type_options.selected)
	resolution_text = resolution_options.get_item_text(resolution_options.selected)
	sort_text = sort_options.get_item_text(sort_options.selected)
	search(search_bar.text)


func setup_filters():
	_populate_resolution_options()
	_populate_sort_options()


func _populate_resolution_options():
	resolution_options.clear()
	for res in ["Any", "1K", "2K", "4K", "8K"]:
		resolution_options.add_item(res)


func _populate_sort_options():
	sort_options.clear()
	for s in ["Popular", "Latest", "Alphabetical"]:
		sort_options.add_item(s)


func init_browser():
	var ambient_cg = CONFIG.get_instance(self)
	if not ambient_cg:
		_show_error("Error: AmbientCG plugin not enabled")
		return

	var info = await ambient_cg.api.api_init()
	if info.is_empty():
		_show_error("Error: Could not connect to API")
		return

	api_version_info_label.text = ambient_cg.Parser.api_info_to_version_string(info)
	ambient_cg.Parser.api_info_to_option_button(type_options, info)
	search(search_bar.text)


func _process(_delta: float) -> void:
	if not visible:
		return
	if v_scroll_bar == null:
		v_scroll_bar = search_scroll.get_v_scroll_bar()
	else:
		var current_y = v_scroll_bar.size.y + v_scroll_bar.value
		var should_load_more = current_y > v_scroll_bar.max_value * 0.8

		if should_load_more and not awaiting_search_finish and not next_query_uri.is_empty():
			search(search_bar.text, true)

	if searching_indicator:
		searching_indicator.visible = awaiting_search_finish


func search(query: String = "", use_next: bool = false):
	if awaiting_search_finish:
		return
	var ambient_cg = CONFIG.get_instance(self)
	if not ambient_cg:
		return
	awaiting_search_finish = true

	if not use_next:
		_show_status("Searching...")
		_clear_search_grid()

	var result = await ambient_cg.api.search_assets(
		query, type_text, next_query_uri if use_next else ""
	)
	var parsed = ambient_cg.Parser.parse_search_query_data(result, ambient_cg.api_information)

	next_query_uri = parsed.get("next_query_uri", "")
	var assets = parsed.get("assets", [])

	for asset in assets:
		if not _asset_matches_resolution(asset):
			continue

		_add_asset_widget(asset)

	search_result_count.text = "%d Results Found" % parsed.get("result_count_total", 0)

	status_overlay.visible = search_grid.get_child_count() == 0 and not use_next
	if status_overlay.visible:
		status_label.text = "No Results Found"

	awaiting_search_finish = false


func display_asset_details(asset: Dictionary):
	if sidebar and sidebar.has_method("display_asset"):
		sidebar.display_asset(asset)


func _show_error(message: String) -> void:
	status_overlay.show()
	status_label.text = message


func _show_status(message: String) -> void:
	status_overlay.show()
	status_label.text = message


func _clear_search_grid() -> void:
	for c in search_grid.get_children():
		c.queue_free()


func _asset_matches_resolution(asset: Dictionary) -> bool:
	if resolution_text == "Any":
		return true

	var res_array: Array = asset.get("implementation_uris", {}).keys()
	for r in res_array:
		if str(r).contains(resolution_text):
			return true
	return false


func _add_asset_widget(asset: Dictionary) -> void:
	var widget = BROWSER_WIDGET.instantiate()
	search_grid.add_child(widget)
	widget.setup(asset, owner, self)
