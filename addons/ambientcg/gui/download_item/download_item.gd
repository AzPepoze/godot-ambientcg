@tool
extends PanelContainer

var url: String = ""
var asset_name: String = ""
var local_path: String = ""
var _is_extracting: bool = false

@onready var title_label: Label = %Title
@onready var status_label: Label = %Status
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var extract_button: Button = %ExtractButton


func _ready() -> void:
	title_label.text = asset_name
	extract_button.hide()
	AmbientAPI.download_progress_updated.connect(_on_progress_updated)


func setup(p_url: String, p_name: String):
	url = p_url
	asset_name = p_name
	var download_path = ProjectSettings.get_setting(
		"ambientcg/download_path", "res://ambientcg/temp"
	)
	local_path = download_path.trim_suffix("/") + "/%s" % p_name
	if is_inside_tree():
		title_label.text = asset_name


func _on_progress_updated(p_url: String, bytes_downloaded: int, total_bytes: int):
	if p_url == url:
		var progress = (float(bytes_downloaded) / float(total_bytes)) * 100.0
		progress_bar.value = progress

		if progress >= 100.0 and not _is_extracting:
			_is_extracting = true
			status_label.text = "Extracting..."
			progress_bar.hide()

			# ดึงค่าโฟลเดอร์ตั้งต้นจาก Project Settings
			var default_path = ProjectSettings.get_setting(
				"ambientcg/extract_path", "res://ambientcg/extracted"
			)

			# สั่งแตกไฟล์อัตโนมัติ
			await AmbientFileHandler.extract_all(local_path, default_path)
			queue_free()
		else:
			status_label.text = "Downloading"
