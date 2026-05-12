@tool
extends Control

const CONFIG = preload("res://addons/ambientcg/core/ambient_config.gd")

@onready var mat_path_edit: LineEdit = %MatPath
@onready var ext_path_edit: LineEdit = %ExtPath
@onready var env_path_edit: LineEdit = %EnvPath
@onready var down_path_edit: LineEdit = %DownPath


func _ready() -> void:
	load_settings()


func load_settings():
	var settings_map = {
		CONFIG.SETTING_MATERIAL_DIR: [CONFIG.DEFAULT_MATERIAL_DIR, mat_path_edit],
		CONFIG.SETTING_EXTRACT_PATH: [CONFIG.DEFAULT_EXTRACT_PATH, ext_path_edit],
		CONFIG.SETTING_ENVIRONMENT_DIR: [CONFIG.DEFAULT_ENVIRONMENT_DIR, env_path_edit],
		CONFIG.SETTING_DOWNLOAD_PATH: [CONFIG.DEFAULT_DOWNLOAD_PATH, down_path_edit]
	}

	for key in settings_map:
		var info = settings_map[key]
		var val = CONFIG.get_setting(key, info[0])
		info[1].text = val


func _on_save_button_pressed() -> void:
	CONFIG.set_setting(CONFIG.SETTING_MATERIAL_DIR, mat_path_edit.text)
	CONFIG.set_setting(CONFIG.SETTING_EXTRACT_PATH, ext_path_edit.text)
	CONFIG.set_setting(CONFIG.SETTING_ENVIRONMENT_DIR, env_path_edit.text)
	CONFIG.set_setting(CONFIG.SETTING_DOWNLOAD_PATH, down_path_edit.text)

	if CONFIG.is_plugin_enabled():
		AmbientCG.logger.info("Settings saved successfully", "Settings")
	
	load_settings()
