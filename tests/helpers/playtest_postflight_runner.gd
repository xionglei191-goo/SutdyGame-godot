class_name PlaytestPostflightRunner
extends RefCounted

const REPORT_VALIDATOR := preload("res://tests/helpers/playtest_report_validator.gd")
const SUMMARY_EXPORTER := preload("res://tests/helpers/playtest_summary_exporter.gd")


static func run(report_path: String, summary_path: String = SUMMARY_EXPORTER.SUMMARY_PATH) -> Dictionary:
	var result := {
		"ok": false,
		"errors": [],
		"warnings": [],
		"report": {},
		"summary_path": summary_path,
		"summary_saved": false
	}
	if not FileAccess.file_exists(report_path):
		result["errors"].append("Missing playtest report: %s" % ProjectSettings.globalize_path(report_path))
		return result

	var report: Dictionary = REPORT_VALIDATOR.load_report(report_path)
	if report.is_empty():
		result["errors"].append("playtest report should parse as a JSON object")
		return result

	var errors: Array[String] = REPORT_VALIDATOR.validate(report) + SUMMARY_EXPORTER.validate_report(report)
	if not errors.is_empty():
		result["errors"].append_array(errors)
		result["report"] = report
		return result

	result["report"] = report
	if not SUMMARY_EXPORTER.save_summary(summary_path, report):
		result["errors"].append("playtest summary should save: %s" % ProjectSettings.globalize_path(summary_path))
		return result

	result["summary_saved"] = true
	var target: Dictionary = report.get("elapsed_vs_target_seconds", {})
	if not bool(target.get("within_window", false)):
		result["warnings"].append("TIMING_OUT_OF_TARGET")
	result["ok"] = true
	return result
