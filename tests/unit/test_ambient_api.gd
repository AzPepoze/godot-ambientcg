extends GutTest

var API_SCRIPT = load("res://addons/ambientcg/core/ambient_api.gd")
var _api = null


class MockManager:
	extends Node
	var api_information: Dictionary = {
		"data":
		{
			"asset_list_query":
			{"uri": "https://api.test/list", "parameters": [{"id": "q", "type": "text"}]}
		}
	}


func before_each():
	_api = partial_double(API_SCRIPT).new()
	_api.config = load("res://addons/ambientcg/core/ambient_config.gd")
	_api.parser = load("res://addons/ambientcg/core/ambient_parser.gd")
	_api.logger = load("res://addons/ambientcg/core/ambient_logger.gd").new()
	_api.signals = load("res://addons/ambientcg/core/ambient_signals.gd").new()
	_api.manager = MockManager.new()
	_api.add_child(_api.logger)
	_api.add_child(_api.signals)
	_api.add_child(_api.manager)
	add_child(_api)


func after_each():
	_api.free()


func test_update_user_agent():
	_api.update_user_agent()
	assert_string_contains(_api.user_agent, "AmbientCG Plugin")


func test_http_request_invalid_url():
	var result = await _api.http_request(
		"invalid_url", PackedStringArray(), HTTPClient.METHOD_GET, ""
	)
	assert_eq(result[0], 1)


func test_search_assets_mocked():
	# Mock response from server
	var mock_response = [0, 200, {}, '{"assets": []}'.to_utf8_buffer()]
	stub(_api, "http_request").to_return(mock_response)

	var result = await _api.search_assets("wood", "Material")
	assert_typeof(result, TYPE_DICTIONARY)
	# result should be {"assets": []} parsed from our mock string
	assert_eq(result.get("assets"), [])
