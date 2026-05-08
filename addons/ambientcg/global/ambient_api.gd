@tool
extends Node

signal download_progress_updated(url: String, bytes_downloaded: int, total_bytes: int)
signal download_started(url: String, asset_name: String)

const HOME_URL: String = "https://ambientcg.com/api/af/"

var user_agent := ""
var api_information: Dictionary = {}
var download_progress: Dictionary[String, int] = {}


func update_user_agent() -> void:
	user_agent = (
		"VenitStudios AmbientCG Godot Plugin (Godot %s)"
		% str(Engine.get_version_info().major, ".", Engine.get_version_info().minor)
	)


func http_request(
	url: String,
	custom_headers: PackedStringArray = PackedStringArray(),
	method: HTTPClient.Method = 0,
	request_data: String = ""
):
	update_user_agent()
	if url.is_empty() or not url.begins_with("http"):
		AmbientLogger.warn("Attempted to request invalid URL: '%s'" % url, "Network")
		return [1, 0, {}, PackedByteArray()]

	AmbientLogger.debug("Requesting URL: %s" % url, "Network")
	var http_request = HTTPRequest.new()
	add_child(http_request)
	custom_headers.append("User-Agent: %s" % user_agent)
	http_request.request(url, custom_headers, method, request_data)
	var response = await http_request.request_completed

	AmbientLogger.debug("Response received for %s (Status: %d)" % [url, response[1]], "Network")

	remove_child(http_request)
	http_request.queue_free()
	return response


func http_request_raw(
	url: String,
	custom_headers: PackedStringArray = PackedStringArray(),
	method: HTTPClient.Method = 0,
	request_data: PackedByteArray = []
):
	update_user_agent()
	if not url.is_empty():
		var http_request = HTTPRequest.new()
		add_child(http_request)
		custom_headers.append("User-Agent: %s" % user_agent)
		http_request.request_raw(url, custom_headers, method, request_data)
		var response = await http_request.request_completed
		remove_child(http_request)
		http_request.queue_free()
		return response
	return [1, 0, {}, PackedByteArray()]


func http_request_download(url: String, path: String, file_size: int) -> void:
	if url.is_empty():
		return
	update_user_agent()
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.download_file = path
	http_request.request(url, ["User-Agent: %s" % user_agent], HTTPClient.METHOD_GET, "")

	var bytes_left = file_size - http_request.get_downloaded_bytes()

	while bytes_left > 0:
		# Check for request errors to prevent infinite loop
		var status = http_request.get_http_client_status()
		if (
			status == HTTPClient.STATUS_DISCONNECTED
			or status == HTTPClient.STATUS_CONNECTION_ERROR
			or status == HTTPClient.STATUS_CANT_RESOLVE
		):
			AmbientLogger.error("Download failed: Connection lost or error", "Network")
			break

		var downloaded = http_request.get_downloaded_bytes()
		bytes_left = file_size - downloaded
		download_progress[url] = downloaded
		download_progress_updated.emit(url, downloaded, file_size)
		await get_tree().create_timer(0.1).timeout

	remove_child(http_request)
	download_progress.erase(url)
	download_progress_updated.emit(url, file_size, file_size)  # Final signal
	http_request.queue_free()


func parse_pba_json(data: PackedByteArray) -> Dictionary:
	var json_string = data.get_string_from_utf8()
	if json_string.is_empty():
		return {}

	var parsed = JSON.parse_string(json_string)
	if parsed == null:
		return {}
	return parsed


func search_assets(query: String, type: String = "", override_uri: String = "") -> Dictionary:
	var asset_list_query = AmbientParser.asset_list_query(api_information)
	var search_uri = asset_list_query.get("uri", "")

	if not override_uri.is_empty():
		var final_override = override_uri
		if not final_override.begins_with("http"):
			# If it's a relative URL from the API, prepend the base domain
			final_override = "https://ambientcg.com" + final_override

		var request = await http_request(final_override, ["User-Agent: %s" % user_agent])
		return parse_pba_json(request[3])

	if not search_uri.is_empty():
		var id: String = (
			AmbientParser
			. get_parameter_from_key_and_type(
				"type", "text", AmbientParser.asset_list_query(AmbientAPI.api_information)
			)
			. get("id", "")
		)

		if not id.is_empty():
			var final_uri = search_uri + "?%s=%s&type=%s" % [id, query.replacen(" ", ","), type]
			var request = await http_request(final_uri, ["User-Agent: %s" % user_agent])
			return parse_pba_json(request[3])

	return {}


func api_init() -> Dictionary:
	var request_response = await http_request(HOME_URL + "init")
	match request_response[1]:
		200:
			var data = parse_pba_json(request_response[3])
			api_information = data
			return data
		404:
			return {}
	return {}


func api_implementation_list(implementation_uri: String) -> Dictionary:
	var request_response = await http_request(implementation_uri)
	match request_response[1]:
		200:
			var data = parse_pba_json(request_response[3])
			return data
		404:
			return {}
	return {}
