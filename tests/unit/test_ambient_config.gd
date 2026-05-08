extends GutTest

var Config = load("res://addons/ambientcg/core/ambient_config.gd")


func test_get_setting_default():
	# Test that it returns default value when setting doesn't exist
	var val = Config.get_setting("non_existent/setting", "default")
	assert_eq(val, "default")


func test_constants_not_empty():
	assert_not_empty(Config.PLUGIN_NAME)
	assert_not_empty(Config.HOME_URL)
	assert_not_empty(Config.BASE_DOMAIN)


func test_set_and_get_setting():
	var test_key = "ambientcg/test_setting"
	var test_val = "hello_world"
	Config.set_setting(test_key, test_val)
	assert_eq(Config.get_setting(test_key, ""), test_val)
