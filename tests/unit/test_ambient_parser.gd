extends GutTest

var Parser = load("res://addons/ambientcg/core/ambient_parser.gd")


func test_api_info_to_version_string_valid():
	var mock_json = {
		"id": "ambientCG",
		"meta": {"version": "1.0"},
		"data": {"text": {"description": "A test description"}}
	}
	var result = Parser.api_info_to_version_string(mock_json)
	assert_string_contains(result, "ambientCG")
	assert_string_contains(result, "v1.0")


func test_api_info_to_version_string_empty():
	assert_eq(Parser.api_info_to_version_string({}), "")


func test_api_info_to_version_string_malformed():
	var malformed = {"id": "test"}  # Missing meta and data
	var result = Parser.api_info_to_version_string(malformed)
	# Should not crash and handle missing keys gracefully
	assert_string_contains(result, "test")


func test_asset_list_query_valid():
	var mock_json = {"data": {"asset_list_query": {"uri": "https://api.test"}}}
	assert_eq(Parser.asset_list_query(mock_json).get("uri"), "https://api.test")


func test_asset_list_query_invalid():
	assert_eq(Parser.asset_list_query({}), {})


func test_parse_assets_from_search_empty():
	assert_eq(Parser.parse_assets_from_search([]), [])


func test_parse_assets_from_search_complex():
	var mock_list = [
		{
			"id": "Wood01",
			"data":
			{
				"implementation_list_query":
				{
					"uri": "https://api.test/imp",
					"parameters": [{"id": "id"}, {"id": "q", "choices": [{"value": "1K"}]}]
				},
				"preview_image_thumbnail": {"uris": {"128": "thumb.jpg"}},
				"text": {"title": "Wood 01"}
			}
		}
	]
	var results = Parser.parse_assets_from_search(mock_list)
	assert_eq(results.size(), 1)
	assert_eq(results[0].get("id"), "Wood01")
	assert_eq(results[0].get("title"), "Wood 01")
	assert_eq(results[0].get("thumbnail"), "thumb.jpg")
	assert_true(results[0].get("implementation_uris", {}).has("1K"))
