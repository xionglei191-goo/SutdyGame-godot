extends SceneTree

const POSTFLIGHT_RUNNER := preload("res://tests/helpers/playtest_postflight_runner.gd")
const SUMMARY_EXPORTER := preload("res://tests/helpers/playtest_summary_exporter.gd")


func _initialize() -> void:
	var game_state: Node = root.get_node("GameState")
	var report_path: String = game_state.DEFAULT_PLAYTEST_REPORT_PATH
	var report_absolute_path := ProjectSettings.globalize_path(report_path)
	if not FileAccess.file_exists(report_path):
		push_error("Missing playtest report: %s" % report_absolute_path)
		push_error("Run a full manual playtest, click 完成摘要阅读, then 导出计时报告.")
		quit(1)
		return

	var result: Dictionary = POSTFLIGHT_RUNNER.run(report_path, SUMMARY_EXPORTER.SUMMARY_PATH)
	if not bool(result.get("ok", false)):
		for error: String in result.get("errors", []):
			push_error(error)
		quit(1)
		return

	var report: Dictionary = result.get("report", {})
	var summary_absolute_path := ProjectSettings.globalize_path(SUMMARY_EXPORTER.SUMMARY_PATH)
	var target: Dictionary = report.get("elapsed_vs_target_seconds", {})
	var fixed_review: Dictionary = report.get("fixed_review_read_aloud", {})
	print("MVP 0.2 manual playtest postflight passed.")
	print("Report path: %s" % report_absolute_path)
	print("Summary path: %s" % summary_absolute_path)
	print("Elapsed: %s (%s seconds)" % [str(report.get("playtest_elapsed_text", "")), str(report.get("playtest_elapsed_seconds", ""))])
	print("Target delta: below_min=%s, above_max=%s, within_window=%s" % [
		str(target.get("below_min", "")),
		str(target.get("above_max", "")),
		str(target.get("within_window", ""))
	])
	if result.get("warnings", []).has("TIMING_OUT_OF_TARGET"):
		print("TIMING_OUT_OF_TARGET: report is complete, but elapsed time is outside the 2-5 minute skilled-adult reference window. Record this as conditional_pass or fail after human review.")
	print("Fixed Review wait: %s seconds / %s" % [
		str(fixed_review.get("total_seconds", "")),
		str(fixed_review.get("total_text", ""))
	])
	print("Timeline: monotonic=%s, coverage_complete=%s, events=%s" % [
		str(report.get("playtest_events_monotonic", "")),
		str(report.get("timeline_coverage_complete", "")),
		str(report.get("playtest_event_count", ""))
	])
	print("Manual result is intentionally blank; fill pass / conditional_pass / fail after human timing and experience review.")
	quit(0)
