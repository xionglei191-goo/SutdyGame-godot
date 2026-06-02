extends SceneTree

const SUMMARY_EXPORTER := preload("res://tests/helpers/playtest_summary_exporter.gd")
const REPORT_VALIDATOR := preload("res://tests/helpers/playtest_report_validator.gd")


func _initialize() -> void:
	var game_state: Node = root.get_node("GameState")
	var report_path: String = game_state.DEFAULT_PLAYTEST_REPORT_PATH
	var report_absolute_path := ProjectSettings.globalize_path(report_path)
	if not FileAccess.file_exists(report_path):
		push_error("Missing playtest report: %s" % report_absolute_path)
		push_error("Run a full manual playtest, click 完成摘要阅读, then 导出计时报告.")
		push_error("Then verify with: godot --headless --path . -s res://tests/mvp_0_2_verify_playtest_report.gd")
		quit(1)
		return

	var file := FileAccess.open(report_path, FileAccess.READ)
	if file == null:
		push_error("playtest report should be readable")
		quit(1)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("playtest report should parse as a JSON object")
		quit(1)
		return

	var report: Dictionary = parsed
	var errors: Array[String] = REPORT_VALIDATOR.validate(report) + SUMMARY_EXPORTER.validate_report(report)
	if not errors.is_empty():
		for error: String in errors:
			push_error(error)
		quit(1)
		return

	var summary_text: String = SUMMARY_EXPORTER.build_summary(report)
	if not SUMMARY_EXPORTER.save_summary(SUMMARY_EXPORTER.SUMMARY_PATH, report):
		quit(1)
		return

	print("MVP 0.2 playtest summary exported.")
	print("Summary path: %s" % ProjectSettings.globalize_path(SUMMARY_EXPORTER.SUMMARY_PATH))
	print(summary_text)
	print("Manual result is intentionally blank; fill pass / conditional_pass / fail after human review.")
	quit(0)
