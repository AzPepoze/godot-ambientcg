extends GutTest

var Parser = load("res://addons/ambientcg/global/ambient_parser.gd")
var _parser = null


func before_each():
	_parser = Parser.new()


func after_each():
	_parser.free()


func test_api_info_to_version_string():
	var mock_json = {
		"id": "ambientCG",
		"meta": {"version": "1.0"},
		"data": {"text": {"description": "A test description"}}
	}
	var result = _parser.api_info_to_version_string(mock_json)
	assert_string_contains(result, "ambientCG")
	assert_string_contains(result, "v1.0")
	assert_string_contains(result, "A test description")


func test_asset_list_query():
	var mock_json = {
		"data": {"asset_list_query": {"uri": "https://api.ambientcg.com/v2/full/list"}}
	}
	var result = _parser.asset_list_query(mock_json)
	assert_eq(result.get("uri"), "https://api.ambientcg.com/v2/full/list")
