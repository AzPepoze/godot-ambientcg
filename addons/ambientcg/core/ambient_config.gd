@tool

const PLUGIN_NAME = "AmbientCG"
const VERSION = "1.0.0"

const SETTING_DOWNLOAD_PATH = "ambientcg/download_path"
const SETTING_EXTRACT_PATH = "ambientcg/extract_path"
const SETTING_MATERIAL_DIR = "ambientcg/material_file_directory"
const SETTING_ENVIRONMENT_DIR = "ambientcg/environment_file_directory"

const DEFAULT_DOWNLOAD_PATH = "res://ambientcg/temp"
const DEFAULT_EXTRACT_PATH = "res://ambientcg/extracted"
const DEFAULT_MATERIAL_DIR = "res://ambientcg/materials"
const DEFAULT_ENVIRONMENT_DIR = "res://ambientcg/environments"

const HOME_URL = "https://ambientcg.com/api/v3/"
const BASE_DOMAIN = "https://ambientcg.com"

const THEME_PATH = "res://addons/ambientcg/resources/themes/ambient_theme.tres"
const ICON_PATH = "res://addons/ambientcg/resources/icons/"


static func get_setting(key: String, default_value: Variant) -> Variant:
	return ProjectSettings.get_setting(key, default_value)


static func get_instance(node: Node) -> Node:
	if node.is_inside_tree():
		return node.get_node_or_null("/root/AmbientCG")
	return null


static func is_plugin_enabled() -> bool:
	return ProjectSettings.has_setting("autoload/AmbientCG")


static func set_setting(key: String, value: Variant) -> void:
	if (
		key
		in [
			SETTING_DOWNLOAD_PATH,
			SETTING_EXTRACT_PATH,
			SETTING_MATERIAL_DIR,
			SETTING_ENVIRONMENT_DIR
		]
	):
		if typeof(value) == TYPE_STRING:
			value = value.to_lower()
	ProjectSettings.set_setting(key, value)
	ProjectSettings.save()
