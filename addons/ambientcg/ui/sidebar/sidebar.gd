@tool
extends PanelContainer

const DOWNLOAD_ITEM_SCENE = preload(
	"res://addons/ambientcg/ui/components/download/download_item.tscn"
)
const CONFIG = preload("res://addons/ambientcg/core/ambient_config.gd")

var current_asset_id: String = ""
var asset_data: Dictionary = {}

@onready var asset_title: Label = %AssetTitle
@onready var asset_description: Label = %AssetDescription
@onready var quality_option: OptionButton = %QualityOption
@onready var download_container: VBoxContainer = %DownloadContainer
@onready var loading_indicator: Control = %LoadingIndicator
@onready var detail_container: Control = %DetailContainer


func _ready() -> void:
	detail_container.hide()
	loading_indicator.hide()
	AmbientCG.signals.download_started.connect(_on_download_started)


func display_asset(asset_id: String) -> void:
	current_asset_id = asset_id
	detail_container.hide()
	loading_indicator.show()

	quality_option.clear()

	var data = await AmbientCG.api.api_init_implementation(
		CONFIG.BASE_DOMAIN + "/api/af/implementation/" + asset_id
	)
	asset_data = data

	if asset_data.is_empty():
		AmbientCG.logger.error("Failed to fetch asset details", "UI")
		loading_indicator.hide()
		return

	asset_title.text = asset_id
	asset_description.text = asset_data.get("description", "No description available.")

	var downloads = asset_data.get("download_options", [])
	for i in range(downloads.size()):
		var d = downloads[i]
		quality_option.add_item(d.get("label", "Unknown Quality"), i)

	loading_indicator.hide()
	detail_container.show()


func _on_download_button_pressed() -> void:
	var idx = quality_option.get_selected_id()
	var downloads = asset_data.get("download_options", [])
	if idx < downloads.size():
		var download_data = downloads[idx]
		AmbientCG.file_handler.download_file_from_data(download_data, self)


func _on_download_started(_url: String, asset_name: String) -> void:
	var item = DOWNLOAD_ITEM_SCENE.instantiate()
	download_container.add_child(item)
	item.setup(_url, asset_name)
