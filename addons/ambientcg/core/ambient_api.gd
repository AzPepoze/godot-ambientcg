@tool
extends Node

var config: Script
var parser: Script
var logger: Node
var signals: Node
var manager: Node

var user_agent := ""


func _ready() -> void:
	update_user_agent()


func update_user_agent() -> void:
	user_agent = (
		"AmbientCG Plugin (Godot %s)"
		% str(Engine.get_version_info().major, ".", Engine.get_version_info().minor)
	)


func http_request(
	url: String,
	custom_headers: PackedStringArray = PackedStringArray(),
	method: HTTPClient.Method = 0,
	request_data: String = ""
):
	if url.is_empty() or not url.begins_with("http"):
		logger.warn("Attempted to request invalid URL: '%s'" % url, "Network")
		return [1, 0, {}, PackedByteArray()]

	var http_request = HTTPRequest.new()
	add_child(http_request)
	custom_headers.append("User-Agent: %s" % user_agent)
	http_request.request(url, custom_headers, method, request_data)
	var response = await http_request.request_completed

	remove_child(http_request)
	http_request.queue_free()
	return response


func http_request_download(url: String, path: String, file_size: int) -> void:
	if url.is_empty():
		return
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.download_file = path
	var request_status = {"finished": false, "success": false}
	http_request.request_completed.connect(
		func(result: int, _response_code: int, _headers: PackedStringArray, _body: PackedByteArray):
			request_status["finished"] = true
			request_status["success"] = (result == HTTPRequest.RESULT_SUCCESS)
	)

	http_request.request(url, ["User-Agent: %s" % user_agent], HTTPClient.METHOD_GET, "")

	while not request_status["finished"]:
		var downloaded = http_request.get_downloaded_bytes()
		if signals:
			# Prevent UI math errors if downloaded bytes slightly exceed reported size
			var actual_total = max(file_size, downloaded) if file_size > 0 else max(1, downloaded)
			signals.download_progress_updated.emit(url, downloaded, actual_total)
		await get_tree().create_timer(0.1).timeout

	remove_child(http_request)
	http_request.queue_free()

	if request_status["success"]:
		if signals:
			# Force UI to 100%
			signals.download_progress_updated.emit(url, file_size, file_size)
			signals.download_completed.emit(path)
	else:
		if signals:
			signals.download_failed.emit(url, "Download failed or connection lost")


func search_assets(query: String, type: String = "", override_uri: String = "") -> Dictionary:
	var final_uri = ""
	if not override_uri.is_empty():
		final_uri = (
			override_uri if override_uri.begins_with("http") else config.BASE_DOMAIN + override_uri
		)
	else:
		var alq = parser.asset_list_query(manager.api_information)
		var search_uri = alq.get("uri", "")
		if not search_uri.is_empty():
			var id: String = parser.get_parameter_from_key_and_type("type", "text", alq).get(
				"id", ""
			)
			if not id.is_empty():
				final_uri = search_uri + "?%s=%s&type=%s" % [id, query.replacen(" ", ","), type]

	if not final_uri.is_empty():
		var request = await http_request(final_uri)
		var json_string = request[3].get_string_from_utf8()
		return JSON.parse_string(json_string) if not json_string.is_empty() else {}

	return {}


func api_init() -> Dictionary:
	var request_response = await http_request(config.HOME_URL + "init")
	if request_response[1] == 200:
		var json_string = request_response[3].get_string_from_utf8()
		var data = JSON.parse_string(json_string) if not json_string.is_empty() else {}
		if manager:
			manager.api_information = data
		return data
	return {}


func api_init_implementation(implementation_uri: String) -> Dictionary:
	var request_response = await http_request(implementation_uri)
	if request_response[1] == 200:
		var json_string = request_response[3].get_string_from_utf8()
		return JSON.parse_string(json_string) if not json_string.is_empty() else {}
	return {}
