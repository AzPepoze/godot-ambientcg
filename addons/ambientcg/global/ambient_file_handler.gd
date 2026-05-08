@tool
extends Node

signal file_downloaded(file: String)


func download_file_from_data(file_information: Dictionary, source_window: Node) -> void:
	check_dirs()
	var download_path: String = ProjectSettings.get_setting(
		"ambientcg/download_path", "res://ambientcg/temp"
	)
	var path: String = (
		download_path.trim_suffix("/") + "/%s" % file_information.get("local_file_name", "")
	)
	var file_uri = file_information.get("uri", "")

	AmbientLogger.info("Initiating download to Project: %s" % file_uri, "FileHandler")
	AmbientLogger.debug("Target project path: %s" % path, "FileHandler")

	var text = (
		"File will be Downloaded to %s and is Approx. %sMiB.\nDownload?"
		% [path, snappedf(float(file_information.get("file_size", 0)) / 1049000.0, 0.01)]
	)

	await confirm_file_path(path, text)

	source_window.grab_focus()

	AmbientAPI.download_started.emit(file_uri, file_information.get("local_file_name", ""))

	AmbientLogger.debug("Starting HTTP request for download...", "Network")
	await AmbientAPI.http_request_download(file_uri, path, file_information.get("file_size", 0))

	AmbientLogger.info("Download completed in Project: %s" % path, "FileHandler")
	file_downloaded.emit(path)


func extract_all(source_file: String, target_path: String = "", options: Dictionary = {}) -> void:
	AmbientLogger.info("Starting automatic extraction for: %s" % source_file, "FileHandler")
	var file_sys := EditorInterface.get_resource_filesystem()
	var reader := ZIPReader.new()
	var err = reader.open(source_file)

	if err != OK:
		AmbientLogger.error("Failed to open ZIP file: %d" % err, "FileHandler")
		return

	var files = reader.get_files()
	AmbientLogger.debug("Found %d files to extract" % files.size(), "FileHandler")

	var extraction_path: String = target_path
	if extraction_path.is_empty():
		extraction_path = await open_directory_dialog_for_path("Select path to Extract to")

	if extraction_path.is_empty():
		AmbientLogger.warn("Extraction cancelled: No directory selected", "FileHandler")
		return

	AmbientLogger.info("Extracting everything to: %s" % extraction_path, "FileHandler")
	var saved_files: PackedStringArray
	var asset_name: String = source_file.get_file().get_basename()
	var final_extract_path: String = extraction_path.trim_suffix("/") + "/" + asset_name

	var mat_dir: String = ProjectSettings.get_setting(
		"ambientcg/material_file_directory", "res://ambientcg/materials"
	)

	# Clean up old extraction if exists
	if DirAccess.dir_exists_absolute(final_extract_path):
		AmbientLogger.debug("Cleaning up old folder: %s" % final_extract_path, "FileHandler")
		var dir = DirAccess.open(final_extract_path)
		if dir:
			dir.list_dir_begin()
			var fn = dir.get_next()
			while fn != "":
				dir.remove(fn)
				fn = dir.get_next()
		DirAccess.remove_absolute(final_extract_path)

	DirAccess.make_dir_recursive_absolute(final_extract_path)

	for file in files:
		var ext = file.get_extension().to_lower()
		if ext == "blend" or ext == "mtlx" or ext == "usdc" or ext == "usdz":
			AmbientLogger.debug("Skipping extra file: %s" % file, "FileHandler")
			continue

		# Skip preview images (files that don't contain resolution info like 1K, 2K, etc.)
		var is_image = ["jpg", "jpeg", "png"].has(ext)
		if is_image:
			var res_regex = RegEx.new()
			res_regex.compile("\\d+K")
			if not res_regex.search(file):
				AmbientLogger.debug("Skipping preview image: %s" % file, "FileHandler")
				continue

		AmbientLogger.debug("Extracting: %s" % file, "FileHandler")
		var file_data: PackedByteArray = reader.read_file(file)

		# If it's a tres file, move it to mat_dir instead of extract_path
		var target_folder = final_extract_path
		if ext == "tres":
			target_folder = mat_dir

		var new_file_path = target_folder.trim_suffix("/") + "/%s" % file.get_file()
		var fs := FileAccess.open(new_file_path, FileAccess.WRITE)

		if fs.is_open():
			fs.store_buffer(file_data)
			fs.close()
			file_sys.update_file(new_file_path)
			saved_files.append(new_file_path)

			# Apply scaling if needed
			if ["jpg", "jpeg", "png"].has(new_file_path.get_extension()):
				if options.get("use_custom_size", false):
					var scaled_image = Image.load_from_file(new_file_path)
					if scaled_image and not scaled_image.is_empty():
						var new_size = options.get("img_size", scaled_image.get_size())
						if not new_size == Vector2(scaled_image.get_size()):
							scaled_image.resize(new_size.x, new_size.y, Image.INTERPOLATE_BILINEAR)
							match new_file_path.get_extension():
								"jpg", "jpeg":
									scaled_image.save_jpg(new_file_path)
								"png":
									scaled_image.save_png(new_file_path)
				file_sys.update_file(new_file_path)
		else:
			AmbientLogger.error("Failed to write file: %s" % new_file_path, "FileHandler")

	AmbientLogger.debug("Refreshing filesystem...", "FileHandler")
	file_sys.scan()
	file_sys.scan_sources()
	reader.close()

	# Wait for Godot to import the files with a safety timeout
	AmbientLogger.debug("Waiting for resource import...", "FileHandler")
	var timeout = 5.0
	while timeout > 0:
		var all_imported = true
		for f in saved_files:
			if not ResourceLoader.exists(f):
				all_imported = false
				break
		if all_imported:
			break
		await get_tree().create_timer(0.5).timeout
		timeout -= 0.5
		file_sys.scan()

	AmbientLogger.debug("Resources imported (or timed out), creating materials...", "FileHandler")

	var mat_save_path: String = mat_dir.trim_suffix("/") + "/" + asset_name

	# Material Creation
	if options.get("enable_packing", false):
		AmbientLogger.info("Creating ORM Material in %s" % mat_dir, "FileHandler")
		var mat = AmbientMaterialMaker.make_orm_material(saved_files, options)
		ResourceSaver.save(mat, mat_save_path + ".tres")
	else:
		AmbientLogger.info("Creating Standard Material in %s" % mat_dir, "FileHandler")
		var mat = AmbientMaterialMaker.make_standard_material(saved_files, options)
		ResourceSaver.save(mat, mat_save_path + ".tres")

	AmbientLogger.info("Success! Materials created and folders populated", "FileHandler")
	# Clean up zip
	DirAccess.remove_absolute(source_file)


func confirm_file_path(_path: String, dialog_text: String) -> void:
	var confirmation_dialog = ConfirmationDialog.new()
	add_child(confirmation_dialog)
	confirmation_dialog.hide()
	confirmation_dialog.exclusive = false
	confirmation_dialog.initial_position = (
		Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS
	)
	confirmation_dialog.title = "Confirm File Path"
	confirmation_dialog.dialog_text = dialog_text

	confirmation_dialog.show()

	await confirmation_dialog.confirmed


func open_file_dialog_for_path(file_name: String, filtered_extension: String) -> String:
	var dialog := FileDialog.new()
	add_child(dialog)
	dialog.current_file = file_name
	dialog.filters = ["*%s" % filtered_extension]
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS
	dialog.show()
	return await dialog.file_selected


func open_directory_dialog_for_path(title: String) -> String:
	var dialog := FileDialog.new()
	add_child(dialog)
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	dialog.title = title
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS
	dialog.show()
	dialog.current_dir = ProjectSettings.get_setting("ambientcg/extract_path")
	return await dialog.dir_selected


func save_buffer(path: String, buffer: PackedByteArray) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)

	if file.is_open():
		file.store_buffer(buffer)
		file.close()


func check_dirs() -> void:
	var temp_path: String = ProjectSettings.get_setting(
		"ambientcg/download_path", "res://ambientcg/temp"
	)
	var extract_path: String = ProjectSettings.get_setting(
		"ambientcg/extract_path", "res://ambientcg/extracted"
	)
	var material_file_directory: String = ProjectSettings.get_setting(
		"ambientcg/material_file_directory", "res://ambientcg/materials"
	)
	var environment_file_directory: String = ProjectSettings.get_setting(
		"ambientcg/environment_file_directory", "res://ambientcg/environments"
	)

	for i in [temp_path, extract_path, material_file_directory, environment_file_directory]:
		if not DirAccess.dir_exists_absolute(i):
			DirAccess.make_dir_recursive_absolute(i)
