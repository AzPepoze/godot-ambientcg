@tool
# AmbientParser
# Utility class for parsing JSON data from the AmbientCG API.

const UTILS = preload("res://addons/ambientcg/utils/ambient_utils.gd")
const TEMP_FILE_PATH := "user://temp_acg_tres.tres"


static func api_info_to_version_string(json: Dictionary) -> String:
	if json.is_empty():
		return ""

	var string = (
		json.get("id", "")
		+ " v"
		+ json.get("meta", {}).get("version", "")
		+ "\n"
		+ json.get("data", {}).get("text", {}).get("description", "")
	)
	return string


static func asset_list_query(json: Dictionary) -> Dictionary:
	var data: Dictionary = json.get("data", {})
	return data.get("asset_list_query", {})


static func get_parameter_from_key_and_type(
	key: String, type: String, json: Dictionary
) -> Dictionary:
	var parameters = json.get("parameters", [])
	for parameter in parameters:
		if parameter.get(key, "") == type:
			return parameter
	return {}


static func api_info_to_option_button(button: OptionButton, json: Dictionary) -> void:
	button.clear()
	var alq = asset_list_query(json)
	if alq.is_empty():
		return

	var choices: Array = get_parameter_from_key_and_type("type", "select", alq).get("choices", [])
	for choice: Dictionary in choices:
		button.add_item(str(choice.get("value", "")).capitalize())


static func parse_search_query_data(json: Dictionary, api_info: Dictionary) -> Dictionary:
	var output: Dictionary = {}
	var data: Dictionary = json.get("data", {})
	var response_statistics: Dictionary = data.get("response_statistics", {})
	var next_query: Dictionary = data.get("next_query", {})
	var payload: Dictionary = next_query.get("payload", {})

	output["result_count_total"] = response_statistics.get("result_count_total", 0)

	var alq = asset_list_query(api_info)
	var id: String = get_parameter_from_key_and_type("type", "text", alq).get("id", "")

	var payload_str = (
		"?%s=%s&offset=%d&type=%s"
		% [id, payload.get(id, ""), payload.get("offset", 0), payload.get("type", "any")]
	)

	output["next_query_uri"] = str(next_query.get("uri", ""), payload_str)
	output["assets"] = parse_assets_from_search(json.get("assets", []))
	return output


static func parse_assets_from_search(list: Array) -> Array:
	var output: Array = []
	for asset: Dictionary in list:
		var asset_output: Dictionary
		var id: String = asset.get("id", "")
		var data: Dictionary = asset.get("data", {})
		var implementation_list_query: Dictionary = data.get("implementation_list_query", {})
		var base_uri: String = implementation_list_query.get("uri", "")
		var parameters = implementation_list_query.get("parameters", [])

		if not parameters.is_empty():
			var param_dict_a: Dictionary = parameters[0]
			var implementation_id_str: String = param_dict_a.get("id", "")
			var param_dict_b: Dictionary = parameters[1]
			var implementation_quality_str: String = param_dict_b.get("id", "")

			var choices = param_dict_b.get("choices", [])
			var implementation_uris: Dictionary

			for choice in choices:
				var full_uri = (
					"%s?%s=%s&%s=%s"
					% [
						base_uri,
						implementation_id_str,
						id,
						implementation_quality_str,
						choice.get("value", "")
					]
				)
				implementation_uris[choice.get("value", "")] = full_uri
			asset_output["implementation_uris"] = implementation_uris

		var preview_image_thumbnail: Dictionary = data.get("preview_image_thumbnail", {})
		asset_output["thumbnail"] = preview_image_thumbnail.get("uris", {}).get("128", "")
		asset_output["title"] = data.get("text", {}).get("title", "")
		asset_output["id"] = id
		if id.to_lower().contains("hdri"):
			asset_output["asset_type"] = "hdri"
		else:
			asset_output["asset_type"] = "material"

		output.append(asset_output)
	return output


static func parse_asset_implementation(json: Dictionary) -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	for implementation: Dictionary in json.get("implementations", []):
		var components = implementation.get("components", [])

		for component in components:
			var data: Dictionary = component.get("data", {})
			var fetch_download: Dictionary = data.get("fetch.download", {})
			var uri: String = fetch_download.get("download_query", {}).get("uri", "")

			if not uri.is_empty():
				var store: Dictionary = data.get("store", {})
				var format: Dictionary = data.get("format", {})
				output.append(
					{
						"id": component.get("id", ""),
						"uri": uri,
						"file_size": store.get("bytes", 0),
						"extension": format.get("extension", ""),
						"local_file_name": store.get("local_file_path", "")
					}
				)
	return output


static func pull_tres_dependencies(zip_reader: ZIPReader, tres_file: String) -> Dictionary:
	var content: PackedByteArray = zip_reader.read_file(tres_file, false)
	UTILS.save_buffer(TEMP_FILE_PATH, content)
	var dependencies: PackedStringArray = ResourceLoader.get_dependencies(TEMP_FILE_PATH)
	DirAccess.remove_absolute(TEMP_FILE_PATH)
	return {"tres_content": content, "dependencies": dependencies}
