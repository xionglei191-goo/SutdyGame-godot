extends SceneTree

const REPORT_VALIDATOR := preload("res://tests/helpers/playtest_report_validator.gd")


func _initialize() -> void:
	var game_state: Node = root.get_node("GameState")
	var path: String = game_state.DEFAULT_PLAYTEST_REPORT_PATH
	var absolute_path := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(path):
		push_error("Missing playtest report: %s" % absolute_path)
		push_error("Run a full manual playtest, click 完成摘要阅读, then 导出计时报告.")
		push_error("Prepare a fresh run first with: godot --headless --path . -s res://tests/mvp_0_2_manual_playtest_preflight.gd")
		quit(1)
		return

	var report: Dictionary = REPORT_VALIDATOR.load_report(path)
	if report.is_empty():
		push_error("playtest report should parse as a JSON object")
		quit(1)
		return

	var errors: Array[String] = REPORT_VALIDATOR.validate(report)
	if not errors.is_empty():
		for error: String in errors:
			push_error(error)
		quit(1)
		return

	print("MVP 0.2 playtest report verification passed.")
	print("Report path: %s" % absolute_path)
	print("Manual result is still required; this script does not approve MVP completion.")
	quit(0)
