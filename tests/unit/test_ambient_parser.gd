@tool
extends GutTest

var Parser = load("res://addons/ambientcg/core/ambient_parser.gd")


func test_parse_assets_complex():
	var mock_json = {
		"totalResults": 1,
		"assets":
		[
			{
				"id": "Wood01",
				"title": "Wood 01",
				"thumbnails": {"128-PNG": "thumb.jpg"},
				"downloads":
				[
					{
						"attributes": "1K-JPG",
						"url": "https://api.test/1k",
						"size": 100,
						"extension": "zip"
					}
				]
			}
		]
	}
	var results = Parser.parse_assets(mock_json)
	assert_eq(results.get("result_count_total"), 1)
	var assets = results.get("assets", [])
	assert_eq(assets.size(), 1)
	assert_eq(assets[0].get("id"), "Wood01")
	assert_eq(assets[0].get("title"), "Wood 01")
	assert_eq(assets[0].get("thumbnail"), "thumb.jpg")
	assert_true(assets[0].get("implementation_uris", {}).has("1K-JPG"))
	assert_eq(assets[0].get("download_data").size(), 1)
