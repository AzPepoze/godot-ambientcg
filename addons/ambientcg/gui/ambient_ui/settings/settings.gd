@tool
class_name AmbientSettings extends Control

@onready var mat_path_edit: LineEdit = %MatPath
@onready var ext_path_edit: LineEdit = %ExtPath
@onready var env_path_edit: LineEdit = %EnvPath
@onready var down_path_edit: LineEdit = %DownPath


func _ready() -> void:
	load_settings()
	connect_signals()


func connect_signals():
	if not mat_path_edit.text_changed.is_connected(_on_setting_changed):
		mat_path_edit.text_changed.connect(
			_on_setting_changed.bind("ambientcg/material_file_directory")
		)
		ext_path_edit.text_changed.connect(_on_setting_changed.bind("ambientcg/extract_path"))
		env_path_edit.text_changed.connect(
			_on_setting_changed.bind("ambientcg/environment_file_directory")
		)
		down_path_edit.text_changed.connect(_on_setting_changed.bind("ambientcg/download_path"))


func load_settings():
	var settings = {
		"ambientcg/material_file_directory": ["res://ambientcg/materials", mat_path_edit],
		"ambientcg/extract_path": ["res://ambientcg/extracted", ext_path_edit],
		"ambientcg/environment_file_directory": ["res://ambientcg/environments", env_path_edit],
		"ambientcg/download_path": ["res://ambientcg/temp", down_path_edit]
	}

	for path in settings:
		var default_val = settings[path][0]
		var edit_node = settings[path][1]
		var current_val = ProjectSettings.get_setting(path, default_val)

		if str(current_val).is_empty():
			current_val = default_val

		edit_node.text = str(current_val)


func _on_setting_changed(new_text: String, setting_path: String):
	ProjectSettings.set_setting(setting_path, new_text)
	ProjectSettings.save()
