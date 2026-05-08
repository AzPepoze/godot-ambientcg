@tool
class_name AmbientLogger extends Node

enum Level { DEBUG, INFO, WARNING, ERROR }

static var current_level: Level = Level.DEBUG  # DEBUG level for maximum detail


static func debug(message: String, category: String = "General") -> void:
	_print_log(Level.DEBUG, message, category)


static func info(message: String, category: String = "General") -> void:
	_print_log(Level.INFO, message, category)


static func warn(message: String, category: String = "General") -> void:
	_print_log(Level.WARNING, message, category)


static func error(message: String, category: String = "General") -> void:
	_print_log(Level.ERROR, message, category)


static func _print_log(level: Level, message: String, category: String) -> void:
	if level < current_level:
		return

	var level_str: String = ""
	match level:
		Level.DEBUG:
			level_str = "[DEBUG]"
		Level.INFO:
			level_str = "[INFO]"
		Level.WARNING:
			level_str = "[WARNING]"
		Level.ERROR:
			level_str = "[ERROR]"

	var output = "AmbientCG %s [%s] %s" % [level_str, category, message]

	if level == Level.ERROR:
		printerr(output)
	elif level == Level.WARNING:
		print_rich("[color=yellow]%s[/color]" % output)
	else:
		print(output)
