@tool
# AmbientConfig
# Central repository for plugin-wide constants and settings.
# Now used as a static class to avoid autoload overhead.

# Plugin Info
const PLUGIN_NAME = "AmbientCG"
const VERSION = "1.0.0"

# Project Settings Keys
const SETTING_DOWNLOAD_PATH = "ambientcg/download_path"
const SETTING_EXTRACT_PATH = "ambientcg/extract_path"
const SETTING_MATERIAL_DIR = "ambientcg/material_file_directory"
const SETTING_ENVIRONMENT_DIR = "ambientcg/environment_file_directory"

# Default Paths
const DEFAULT_DOWNLOAD_PATH = "res://ambientcg/temp"
const DEFAULT_EXTRACT_PATH = "res://ambientcg/extracted"
const DEFAULT_MATERIAL_DIR = "res://ambientcg/materials"
const DEFAULT_ENVIRONMENT_DIR = "res://ambientcg/environments"

# API Constants
const HOME_URL = "https://ambientcg.com/api/af/"
const BASE_DOMAIN = "https://ambientcg.com"

# Resource Paths
const THEME_PATH = "res://addons/ambientcg/resources/themes/ambient_theme.tres"
const ICON_PATH = "res://addons/ambientcg/resources/icons/"


static func get_setting(key: String, default_value: Variant) -> Variant:
	return ProjectSettings.get_setting(key, default_value)


static func is_plugin_enabled() -> bool:
	return ClassDB.class_exists("AmbientCG")


static func set_setting(key: String, value: Variant) -> void:
	# Normalize path values to lowercase for cross-platform compatibility
	if key in [SETTING_DOWNLOAD_PATH, SETTING_EXTRACT_PATH, SETTING_MATERIAL_DIR, SETTING_ENVIRONMENT_DIR]:
		if typeof(value) == TYPE_STRING:
			value = value.to_lower()
	ProjectSettings.set_setting(key, value)
	ProjectSettings.save()
