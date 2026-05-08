extends GutTest

var Utils = load("res://addons/ambientcg/utils/ambient_utils.gd")


func test_format_file_size():
	assert_eq(Utils.format_file_size(500), "500 B")
	assert_eq(Utils.format_file_size(1024), "1.00 KiB")
	assert_eq(Utils.format_file_size(1024 * 1024), "1.00 MiB")
	assert_eq(Utils.format_file_size(1024 * 1024 * 1024), "1.00 GiB")


func test_ensure_dir():
	var test_dir = "user://test_dir_creation/"
	Utils.ensure_dir(test_dir)
	assert_true(DirAccess.dir_exists_absolute(test_dir))
	# Cleanup
	DirAccess.remove_absolute(test_dir)


func test_clean_dir_content():
	var test_dir = "user://test_cleanup/"
	var test_file = test_dir + "dummy.txt"
	Utils.ensure_dir(test_dir)
	
	var f = FileAccess.open(test_file, FileAccess.WRITE)
	f.store_string("test")
	f.close()
	
	assert_true(FileAccess.file_exists(test_file))
	Utils.clean_dir_content(test_dir)
	assert_false(FileAccess.file_exists(test_file))
	
	# Cleanup
	DirAccess.remove_absolute(test_dir)
