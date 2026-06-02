class_name PlaytestManualFinalGate
extends RefCounted

const REPORT_VALIDATOR := preload("res://tests/helpers/playtest_report_validator.gd")
const SUMMARY_EXPORTER := preload("res://tests/helpers/playtest_summary_exporter.gd")
const MANUAL_REPORT_TOLERANCE_SECONDS := 60


static func validate(report: Dictionary, summary_text: String, timing_record: String, acceptance: String) -> Array[String]:
	var errors: Array[String] = []
	if report.is_empty():
		errors.append("manual playtest report should exist and parse as JSON")
	else:
		errors.append_array(REPORT_VALIDATOR.validate(report))
		errors.append_array(SUMMARY_EXPORTER.validate_report(report))
		_require_summary_matches_report(errors, summary_text, report)
		_require_contains(errors, summary_text, "### Timing Record Paste", "summary should include timing paste section")
		_require_contains(errors, summary_text, "### Segment Timing Helper", "summary should include segment helper")
		_require_contains(errors, summary_text, "| Manual result |  |", "summary should keep manual result blank before human doc verdict")
		_require_contains(errors, timing_record, str(report.get("playtest_elapsed_text", "")), "timing record should include report elapsed text")
		var target: Dictionary = report.get("elapsed_vs_target_seconds", {})
		_require_contains(errors, timing_record, "below_min: %s / above_max: %s / within_window: %s" % [
			str(target.get("below_min", "")),
			str(target.get("above_max", "")),
			str(target.get("within_window", ""))
		], "timing record should include target delta from report")
	if summary_text.is_empty():
		errors.append("manual postflight summary should exist and be readable")

	_require_not_contains(errors, timing_record, "状态：待人工计时", "timing record should no longer be pending")
	_require_exactly_one_result_checked(errors, timing_record)
	_require_manual_info_rows_filled(errors, timing_record)
	_require_segment_rows_filled(errors, timing_record)
	if not report.is_empty():
		_require_manual_total_matches_report(errors, timing_record, report)
	_require_contains(errors, timing_record, "| 是否点击“完成摘要阅读” | 是 |", "timing record should confirm parent summary reading completion")
	_require_contains(errors, timing_record, "| 是否点击“导出计时报告” | 是 |", "timing record should confirm report export")
	_require_contains(errors, timing_record, "| 报告 `playtest_elapsed_text` |", "timing record should keep report elapsed row")
	_require_not_contains(errors, timing_record, "| 报告 `playtest_elapsed_text` |  |", "timing record should include exported elapsed text")
	_require_contains(errors, timing_record, "| 报告 `elapsed_vs_target_seconds` | below_min:", "timing record should include exported target delta")
	_require_not_contains(errors, timing_record, "within_window: |", "timing record should include within-window value")
	_require_contains(errors, timing_record, "| 报告 `playtest_events_monotonic` | true |", "timing record should confirm monotonic timeline")
	_require_contains(errors, timing_record, "| 报告 `timeline_coverage_complete` | true |", "timing record should confirm timeline coverage")
	_require_not_contains(errors, timing_record, "```text\n\n```", "timing record should include manual notes")

	var passed := timing_record.contains("- [x] 通过")
	var conditional := timing_record.contains("- [x] 有条件通过")
	var failed_result := timing_record.contains("- [x] 不通过")
	if passed:
		_require_contains(errors, timing_record, "within_window: true", "passing timing record should be inside target window")
		_require_manual_total_in_range(errors, timing_record, 120, 300, "passing timing record should have manual total inside target window")
		_require_contains(errors, acceptance, "[x] 成人熟练试玩可形成 2-5 分钟闭环，儿童首次试玩预期更长需单独记录", "acceptance should check 2-5 minute skilled-adult item only for pass")
		_require_not_contains(errors, acceptance, "[ ] 成人熟练试玩可形成 2-5 分钟闭环，儿童首次试玩预期更长需单独记录", "acceptance should not leave pass item unchecked after pass")
	elif conditional:
		_require_contains(errors, acceptance, "[ ] 成人熟练试玩可形成 2-5 分钟闭环，儿童首次试玩预期更长需单独记录", "acceptance should keep 2-5 minute skilled-adult item unchecked unless fully passing")
		_require_not_contains(errors, acceptance, "[x] 成人熟练试玩可形成 2-5 分钟闭环，儿童首次试玩预期更长需单独记录", "acceptance should not check 2-5 minute item for conditional/fail")
	elif failed_result:
		_require_contains(errors, acceptance, "[ ] 成人熟练试玩可形成 2-5 分钟闭环，儿童首次试玩预期更长需单独记录", "acceptance should keep 2-5 minute skilled-adult item unchecked unless fully passing")
		_require_not_contains(errors, acceptance, "[x] 成人熟练试玩可形成 2-5 分钟闭环，儿童首次试玩预期更长需单独记录", "acceptance should not check 2-5 minute item for conditional/fail")
	return errors


static func _require_summary_matches_report(errors: Array[String], summary_text: String, report: Dictionary) -> void:
	if summary_text.is_empty():
		return
	var expected := SUMMARY_EXPORTER.build_summary(report).strip_edges()
	var actual := summary_text.strip_edges()
	_require(errors, actual == expected, "manual postflight summary should match current playtest report")


static func _require_exactly_one_result_checked(errors: Array[String], text: String) -> void:
	var checked_count := 0
	for marker in ["- [x] 通过", "- [x] 有条件通过", "- [x] 不通过"]:
		if text.contains(marker):
			checked_count += 1
	_require(errors, checked_count == 1, "timing record should check exactly one manual result")


static func _require_manual_info_rows_filled(errors: Array[String], text: String) -> void:
	for label in ["测试日期", "测试者", "Godot 版本", "设备/分辨率", "输入方式", "玩家类型", "是否首次游玩"]:
		_require(errors, _row_has_filled_values(text, label, 1), "timing record should fill manual info row: %s" % label)


static func _require_segment_rows_filled(errors: Array[String], text: String) -> void:
	for label in [
		"新存档进入到 Mina 对话结束",
		"Walk With Mina 完成",
		"Leo 对话结束",
		"Room Helper 完成",
		"Nora 对话结束",
		"Bird Watch 完成",
		"Story Show 25 题完成",
		"家长摘要阅读并点击完成",
		"总用时"
	]:
		_require_time_segment_row(errors, text, label)


static func _require_time_segment_row(errors: Array[String], text: String, label: String) -> void:
	var cells := _row_cells(text, label)
	if cells.size() < 4:
		errors.append("timing record should fill segment start/end/duration row: %s" % label)
		return
	var start_seconds := _parse_mm_ss(cells[1])
	var end_seconds := _parse_mm_ss(cells[2])
	var duration_seconds := _parse_mm_ss(cells[3])
	if start_seconds < 0 or end_seconds < 0 or duration_seconds < 0:
		errors.append("timing record segment row should use MM:SS times: %s" % label)
		return
	if end_seconds < start_seconds:
		errors.append("timing record segment end should not be before start: %s" % label)
		return
	if abs((end_seconds - start_seconds) - duration_seconds) > 1:
		errors.append("timing record segment duration should match start/end: %s" % label)


static func _require_manual_total_matches_report(errors: Array[String], text: String, report: Dictionary) -> void:
	var cells := _row_cells(text, "总用时")
	if cells.size() < 4:
		return
	var manual_seconds := _parse_mm_ss(cells[3])
	var report_seconds := int(report.get("playtest_elapsed_seconds", -1))
	if manual_seconds < 0 or report_seconds < 0:
		return
	if abs(manual_seconds - report_seconds) > MANUAL_REPORT_TOLERANCE_SECONDS:
		errors.append("timing record total should be within %s seconds of report elapsed_seconds" % MANUAL_REPORT_TOLERANCE_SECONDS)


static func _require_manual_total_in_range(errors: Array[String], text: String, min_seconds: int, max_seconds: int, message: String) -> void:
	var cells := _row_cells(text, "总用时")
	if cells.size() < 4:
		return
	var manual_seconds := _parse_mm_ss(cells[3])
	if manual_seconds < 0:
		return
	_require(errors, manual_seconds >= min_seconds and manual_seconds <= max_seconds, message)


static func _row_has_filled_values(text: String, label: String, min_filled_cells: int) -> bool:
	var cells := _row_cells(text, label)
	if cells.is_empty():
		return false
	var filled_cells := 0
	for i in range(1, cells.size()):
		if not cells[i].strip_edges().is_empty():
			filled_cells += 1
	return filled_cells >= min_filled_cells


static func _row_cells(text: String, label: String) -> Array[String]:
	var result: Array[String] = []
	for line in text.split("\n"):
		var raw_cells := line.split("|")
		if raw_cells.size() < 3:
			continue
		if raw_cells[1].strip_edges() != label:
			continue
		for i in range(1, raw_cells.size() - 1):
			result.append(raw_cells[i].strip_edges())
		return result
	return result


static func _parse_mm_ss(value: String) -> int:
	var parts := value.strip_edges().split(":")
	if parts.size() != 2:
		return -1
	if not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return -1
	var minutes := int(parts[0])
	var seconds := int(parts[1])
	if minutes < 0 or seconds < 0 or seconds >= 60:
		return -1
	return minutes * 60 + seconds


static func _require_contains(errors: Array[String], text: String, expected: String, message: String) -> void:
	if not text.contains(expected):
		errors.append("Missing %s: %s" % [message, expected])


static func _require_not_contains(errors: Array[String], text: String, unexpected: String, message: String) -> void:
	if text.contains(unexpected):
		errors.append("Unexpected %s: %s" % [message, unexpected])


static func _require(errors: Array[String], condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
