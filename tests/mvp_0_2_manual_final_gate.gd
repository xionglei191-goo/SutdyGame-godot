extends SceneTree

const FINAL_GATE := preload("res://tests/helpers/playtest_manual_final_gate.gd")
const SUMMARY_EXPORTER := preload("res://tests/helpers/playtest_summary_exporter.gd")

const TIMING_RECORD_PATH := "res://docs/development/MVP_0_2_试玩计时记录.md"
const ACCEPTANCE_PATH := "res://docs/development/MVP_0_2_验收记录.md"

func _initialize() -> void:
	var game_state: Node = root.get_node("GameState")
	var report_path: String = game_state.DEFAULT_PLAYTEST_REPORT_PATH
	var summary_path: String = SUMMARY_EXPORTER.SUMMARY_PATH
	var timing_record := _read_text(TIMING_RECORD_PATH)
	var acceptance := _read_text(ACCEPTANCE_PATH)
	var report := _read_report(report_path)
	var summary_text := _read_user_text(summary_path)
	var errors: Array[String] = FINAL_GATE.validate(report, summary_text, timing_record, acceptance)
	if not errors.is_empty():
		for error: String in errors:
			push_error(error)
		push_error("MVP 0.2 manual final gate is not satisfied. Complete a real manual playtest, rerun postflight so the summary matches the current report, paste the summary into the timing record, choose exactly one manual result, and update acceptance state.")
		quit(1)
		return

	print("MVP 0.2 manual final gate passed.")
	print("This script checks recorded human evidence only; it does not approve MVP by itself.")
	quit(0)


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("document should be readable: %s" % path)
		return ""
	return file.get_as_text()


func _read_user_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		push_error("Missing manual postflight summary: %s" % ProjectSettings.globalize_path(path))
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("manual postflight summary should be readable: %s" % ProjectSettings.globalize_path(path))
		return ""
	return file.get_as_text()


func _read_report(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Missing manual playtest report: %s" % ProjectSettings.globalize_path(path))
		return {}
	var report := FINAL_GATE.REPORT_VALIDATOR.load_report(path)
	if report.is_empty():
		push_error("manual playtest report should parse as a JSON object")
	return report
