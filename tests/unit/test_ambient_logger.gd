extends GutTest

var LOGGER_SCRIPT = load("res://addons/ambientcg/core/ambient_logger.gd")
var _logger = null

func before_each():
	_logger = LOGGER_SCRIPT.new()
	_logger.signals = load("res://addons/ambientcg/core/ambient_signals.gd").new()
	_logger.add_child(_logger.signals)
	add_child(_logger)

func after_each():
	_logger.free()

func test_error_emits_signal():
	watch_signals(_logger.signals)
	_logger.error("Test error", "TestCat")
	assert_signal_emitted_with_parameters(_logger.signals, "notification_requested", ["Test error", "error"])

func test_warn_does_not_emit_notification():
	watch_signals(_logger.signals)
	_logger.warn("Test warn")
	assert_signal_not_emitted(_logger.signals, "notification_requested")
