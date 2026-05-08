@tool
extends Node

# Injected dependencies
var config: Script
var utils: Script
var logger: Node
var signals: Node
var api: Node
var material_maker: Script


func download_file_from_data(file_information: Dictionary, _source_window: Node) -> void:
	check_dirs()
	var download_path: String = config.get_setting(
		config.SETTING_DOWNLOAD_PATH, config.DEFAULT_DOWNLOAD_PATH
	)
	var path: String = (
		download_path.trim_suffix("/") + "/%s" % file_information.get("local_file_name", "")
	)
	var file_uri = file_information.get("uri", "")

	if logger:
		logger.info("Initiating download to Project: %s" % file_uri, "FileHandler")

	var text = (
		"File will be Downloaded to %s and is Approx. %s.\nDownload?"
		% [path, utils.format_file_size(file_information.get("file_size", 0))]
	)

	var confirmed = await confirm_file_path(path, text)
	if not confirmed:
		if logger:
			logger.info("Download cancelled by user.", "FileHandler")
		return

	if signals:
		signals.download_started.emit(file_uri, file_information.get("local_file_name", ""))
	if api:
		await api.http_request_download(file_uri, path, file_information.get("file_size", 0))


func extract_all(source_file: String, target_path: String = "", options: Dictionary = {}) -> void:
	if logger:
		logger.info("Starting automatic extraction for: %s" % source_file, "FileHandler")

	var file_sys = null
	if Engine.is_editor_hint() and is_instance_valid(EditorInterface):
		file_sys = EditorInterface.get_resource_filesystem()


	var reader := ZIPReader.new()
	var err = reader.open(source_file)

	if err != OK:
		if logger:
			logger.error("Failed to open ZIP file: %d" % err, "FileHandler")
		if signals:
			signals.extraction_failed.emit(source_file.get_file(), "Failed to open ZIP")
		return

	var files = reader.get_files()
	if logger:
		logger.debug("Found %d files to extract" % files.size(), "FileHandler")

	var extraction_path: String = target_path
	if extraction_path.is_empty():
		extraction_path = await open_directory_dialog_for_path("Select path to Extract to")

	if extraction_path.is_empty():
		if logger:
			logger.warn("Extraction cancelled: No directory selected", "FileHandler")
		return

	if logger:
		logger.info("Extracting everything to: %s" % extraction_path, "FileHandler")

	var asset_name: String = source_file.get_file().get_basename()
	var final_extract_path: String = extraction_path.trim_suffix("/") + "/" + asset_name
	var mat_dir: String = config.get_setting(
		config.SETTING_MATERIAL_DIR, config.DEFAULT_MATERIAL_DIR
	)

	if signals:
		signals.extraction_started.emit(asset_name)

	if DirAccess.dir_exists_absolute(final_extract_path):
		if logger:
			logger.debug("Cleaning up old folder: %s" % final_extract_path, "FileHandler")
		utils.clean_dir_content(final_extract_path)

	utils.ensure_dir(final_extract_path)
	utils.ensure_dir(mat_dir)

	var saved_files: PackedStringArray
	for file in files:
		var ext = file.get_extension().to_lower()
		if ext in ["blend", "mtlx", "usdc", "usdz"]:
			if logger:
				logger.debug("Skipping extra file: %s" % file, "FileHandler")
			continue

		if ext in ["jpg", "jpeg", "png"]:
			var res_regex = RegEx.new()
			res_regex.compile("\\d+K")
			if not res_regex.search(file):
				if logger:
					logger.debug("Skipping preview image: %s" % file, "FileHandler")
				continue

		if logger:
			logger.debug("Extracting: %s" % file, "FileHandler")

		var file_data: PackedByteArray = reader.read_file(file)
		var new_file_path = final_extract_path.trim_suffix("/") + "/%s" % file.get_file()

		var fs := FileAccess.open(new_file_path, FileAccess.WRITE)
		if fs:
			fs.store_buffer(file_data)
			fs.close()
			if file_sys:
				file_sys.update_file(new_file_path)

			saved_files.append(new_file_path)

			if ext in ["jpg", "jpeg", "png"] and options.get("use_custom_size", false):
				_process_image_scaling(new_file_path, options)
				if file_sys:
					file_sys.update_file(new_file_path)


	if logger:
		logger.debug("Refreshing filesystem...", "FileHandler")

	if file_sys:
		file_sys.scan()
		file_sys.scan_sources()

	reader.close()

	await _wait_for_import(saved_files, file_sys)


	var mat_save_path: String = mat_dir.trim_suffix("/") + "/" + asset_name + ".tres"
	var extracted_tres_path: String = ""
	for f in saved_files:
		if f.get_extension().to_lower() == "tres":
			extracted_tres_path = f
			break

	if not extracted_tres_path.is_empty():
		var tres_content = FileAccess.get_file_as_string(extracted_tres_path)
		var fixed_content = _fix_tres_texture_paths(tres_content, final_extract_path)
		var out_file = FileAccess.open(mat_save_path, FileAccess.WRITE)
		if out_file:
			out_file.store_string(fixed_content)
			out_file.close()
		DirAccess.remove_absolute(extracted_tres_path)
		if file_sys:
			file_sys.update_file(mat_save_path)

	else:
		var mat: Resource
		if options.get("enable_packing", false):
			mat = material_maker.make_orm_material(saved_files, options)
		else:
			mat = material_maker.make_standard_material(saved_files, options)
		ResourceSaver.save(mat, mat_save_path)
		if file_sys:
			file_sys.update_file(mat_save_path)


	if logger:
		logger.info("Success! Materials created and folders populated", "FileHandler")
	if signals:
		signals.extraction_completed.emit(asset_name, {"path": final_extract_path})
	DirAccess.remove_absolute(source_file)


func _fix_tres_texture_paths(content: String, extract_folder: String) -> String:
	var absolute_prefix = extract_folder.trim_suffix("/") + "/"
	var path_regex = RegEx.new()
	path_regex.compile('path="([^"]+)"')
	var result = content
	for match in path_regex.search_all(content):
		var original_path = match.get_string(1)
		if not original_path.begins_with("res://"):
			var absolute_path = absolute_prefix + original_path
			result = result.replace('path="%s"' % original_path, 'path="%s"' % absolute_path)
	return result


func _process_image_scaling(path: String, options: Dictionary) -> void:
	var img = Image.load_from_file(path)
	if img and not img.is_empty():
		var new_size = options.get("img_size", img.get_size())
		if not new_size == Vector2(img.get_size()):
			img.resize(new_size.x, new_size.y, Image.INTERPOLATE_BILINEAR)
			match path.get_extension().to_lower():
				"jpg", "jpeg":
					img.save_jpg(path)
				"png":
					img.save_png(path)


func _wait_for_import(files: PackedStringArray, file_sys: Variant) -> void:
	if logger:
		logger.debug("Waiting for resource import...", "FileHandler")

	var timeout = 5.0
	while timeout > 0:
		var all_imported = true
		for f in files:
			if not ResourceLoader.exists(f):
				all_imported = false
				break
		if all_imported:
			break
		await get_tree().create_timer(0.5).timeout
		timeout -= 0.5
		if file_sys:
			file_sys.scan()



func confirm_file_path(_path: String, dialog_text: String) -> bool:
	if not Engine.is_editor_hint():
		return true  # Skip dialog in non-editor/unit tests

	var confirmation_dialog = ConfirmationDialog.new()
	add_child(confirmation_dialog)
	confirmation_dialog.exclusive = false
	confirmation_dialog.title = "Confirm Download"
	confirmation_dialog.dialog_text = dialog_text

	var state = [false, false]  # [finished, confirmed]

	confirmation_dialog.confirmed.connect(
		func():
			state[0] = true
			state[1] = true
	)

	confirmation_dialog.canceled.connect(func(): state[0] = true)

	confirmation_dialog.popup_centered()

	# Bulletproof wait for user to explicitly click a button or close the window
	while not state[0]:
		await get_tree().process_frame

	confirmation_dialog.queue_free()

	return state[1]


func open_directory_dialog_for_path(title: String) -> String:
	if not Engine.is_editor_hint():
		return "user://test_extract/"  # Mock for tests

	var dialog := FileDialog.new()
	add_child(dialog)
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	dialog.title = title
	dialog.current_dir = config.get_setting(
		config.SETTING_EXTRACT_PATH, config.DEFAULT_EXTRACT_PATH
	)
	dialog.show()
	return await dialog.dir_selected


func check_dirs() -> void:
	var paths = [
		config.get_setting(config.SETTING_DOWNLOAD_PATH, config.DEFAULT_DOWNLOAD_PATH),
		config.get_setting(config.SETTING_EXTRACT_PATH, config.DEFAULT_EXTRACT_PATH),
		config.get_setting(config.SETTING_MATERIAL_DIR, config.DEFAULT_MATERIAL_DIR),
		config.get_setting(config.SETTING_ENVIRONMENT_DIR, config.DEFAULT_ENVIRONMENT_DIR)
	]
	for p in paths:
		utils.ensure_dir(p)
