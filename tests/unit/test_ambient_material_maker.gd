extends GutTest

var MaterialMaker = load("res://addons/ambientcg/handlers/ambient_material_maker.gd")


func test_make_standard_material_mapping():
	var dummy_color = "user://test_color.png"
	var dummy_normal = "user://test_normal.png"
	
	var img = Image.create(1, 1, false, Image.FORMAT_RGB8)
	img.fill(Color.RED)
	img.save_png(dummy_color)
	
	img.fill(Color(0.5, 0.5, 1.0))
	img.save_png(dummy_normal)

	var files: PackedStringArray = [dummy_color, dummy_normal]
	var options = {"use_triplanar_uv": false}
	
	var mat = MaterialMaker.make_standard_material(files, options)
	assert_not_null(mat, "Material should be created")
	assert_true(mat.normal_enabled, "Normal mapping should be enabled")
	
	mat = null
	
	DirAccess.remove_absolute(dummy_color)
	DirAccess.remove_absolute(dummy_normal)


func test_make_standard_material_no_files():
	var mat = MaterialMaker.make_standard_material(PackedStringArray(), {})
	assert_not_null(mat)
	assert_false(mat.normal_enabled)
	mat = null
