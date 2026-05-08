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

@onready var sidebar: Control = %Sidebar
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
	setup_filters()
	init_browser()


func setup_filters():
	resolution_options.clear()
	for res in ["Any", "1K", "2K", "4K", "8K"]:
		resolution_options.add_item(res)

	sort_options.clear()
	for s in ["Popular", "Latest", "Alphabetical"]:
		sort_options.add_item(s)


func init_browser():
	var info = await AmbientCG.api.api_init()
	if info.is_empty():
		status_overlay.show()
		status_label.text = "Error: Could not connect to API"
		return

	api_version_info_label.text = AmbientCG.Parser.api_info_to_version_string(info)
	AmbientCG.Parser.api_info_to_option_button(type_options, info)
	search(search_bar.text)


func search(query: String = "", use_next: bool = false):
	if awaiting_search_finish:
		return
	awaiting_search_finish = true

	if not use_next:
		status_overlay.show()
		status_label.text = "Searching..."
		for c in search_grid.get_children():
			c.queue_free()

	var result = await AmbientCG.api.search_assets(
		query, type_text, next_query_uri if use_next else ""
	)
	var parsed = AmbientCG.Parser.parse_search_query_data(result, AmbientCG.api_information)

	next_query_uri = parsed.get("next_query_uri", "")
	var assets = parsed.get("assets", [])

	for asset in assets:
		var widget = BROWSER_WIDGET.instantiate()
		search_grid.add_child(widget)
		widget.setup(asset, owner, self)

	search_result_count.text = "%d Results Found" % parsed.get("result_count_total", 0)
	status_overlay.visible = assets.size() == 0 and not use_next
	if status_overlay.visible:
		status_label.text = "No Results Found"

	awaiting_search_finish = false


func display_asset_details(asset_id: String):
	if sidebar and sidebar.has_method("display_asset"):
		sidebar.display_asset(asset_id)
