@tool
extends Control

signal pop_up_closed(accepted: bool)

var active: bool = false

@onready var tab_container: TabContainer = %TabContainer


func _ready() -> void:
	if ClassDB.class_exists("AmbientCG"):
		AmbientCG.file_handler.check_dirs()
		AmbientCG.logger.info("AmbientCG UI initialized and folders checked", "UI")


func open() -> void:
	active = true


func popup_accept(title: String, content: String, ok_text := "Ok", cancel_text := "Cancel") -> bool:
	var dialog := ConfirmationDialog.new()
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS
	add_child(dialog)
	dialog.visible = true
	dialog.title = title
	dialog.dialog_text = content

	dialog.ok_button_text = ok_text
	dialog.cancel_button_text = cancel_text

	dialog.canceled.connect(pop_up_closed.emit.bind(false))
	dialog.confirmed.connect(pop_up_closed.emit.bind(true))

	var result: bool = await pop_up_closed
	dialog.queue_free()

	return result
