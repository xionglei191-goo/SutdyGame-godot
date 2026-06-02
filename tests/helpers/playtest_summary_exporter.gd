class_name PlaytestSummaryExporter
extends RefCounted

const SUMMARY_PATH := "user://mvp_0_2_playtest_report_summary.md"
const QUEST_LABELS := {
	"prologue_go_to_school": "First Trip",
	"g4_u1_school_tour": "Walk With Mina",
	"g4_u1_tidy_classroom": "Room Helper",
	"g4_u1_garden_bird": "Bird Watch"
}
const REVIEW_LABELS := {
	"mvp_0_2_review_challenge": "Story Show"
}
const REWARD_LABELS := {
	"first_trip_ticket": "First Trip Ticket",
	"school_star_piece": "Adventure Star",
	"tidy_badge_piece": "Room Helper Badge",
	"garden_leaf_piece": "Garden Leaf Charm"
}


static func validate_report(report: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	_require(errors, int(report.get("schema_version", 0)) == 2, "playtest report should use schema version 2")
	_require(errors, str(report.get("report_type", "")) == "mvp_0_2_playtest_timing", "playtest report should use MVP 0.2 timing type")
	_require(errors, bool(report.get("playtest_completed", false)), "playtest report should be completed before summary export")
	_require(errors, bool(report.get("timeline_coverage_complete", false)), "playtest report should have complete timeline coverage")
	_require(errors, bool(report.get("playtest_events_monotonic", false)), "playtest report should have monotonic timeline events")
	_require(errors, bool(report.get("manual_verdict_required", false)), "playtest report should still require manual verdict")
	_require(errors, str(report.get("manual_result", "")) == "", "playtest report manual result should remain blank before human verdict")
	_require(errors, report.has("completed_quests"), "playtest report should include primary completed_quests")
	var completed_quests: Array = report.get("completed_quests", [])
	if report.has("completed_tasks"):
		_require(errors, report.get("completed_tasks", []) == completed_quests, "legacy completed_tasks should mirror completed_quests")
	_require_contains(errors, completed_quests, "prologue_go_to_school", "completed First Trip quest")
	_require_contains(errors, completed_quests, "g4_u1_school_tour", "completed Walk With Mina quest")
	_require_contains(errors, completed_quests, "g4_u1_tidy_classroom", "completed Room Helper quest")
	_require_contains(errors, completed_quests, "g4_u1_garden_bird", "completed Bird Watch quest")
	_require_contains(errors, report.get("completed_reviews", []), "mvp_0_2_review_challenge", "completed Story Show")
	var fixed_review: Dictionary = report.get("fixed_review_read_aloud", {})
	_require(errors, int(fixed_review.get("review_prompt_count", 0)) == 25, "playtest report should include 25 review prompts")
	_require(errors, int(fixed_review.get("prompt_count", 0)) == 6, "playtest report should include 6 timed read-aloud prompts")
	_require(errors, int(fixed_review.get("total_seconds", 0)) == 30, "playtest report should include 30 fixed read-aloud seconds")
	_require(errors, str(fixed_review.get("total_text", "")) == "00:30", "playtest report should include formatted fixed read-aloud time")
	_require_int_array(errors, fixed_review.get("seconds_by_prompt", []), [5, 5, 5, 5, 5, 5], "fixed read-aloud sequence")
	return errors


static func build_summary(report: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("## MVP 0.2 Playtest Report Summary")
	lines.append("")
	lines.append("| Field | Value |")
	lines.append("|---|---|")
	lines.append("| Report schema | %s |" % str(report.get("schema_version", "")))
	lines.append("| Report type | %s |" % str(report.get("report_type", "")))
	lines.append("| Project | %s |" % str(report.get("project_name", "")))
	lines.append("| Generated at unix | %s |" % str(report.get("generated_at_unix", "")))
	lines.append("| Godot version | %s |" % _engine_version_text(report.get("engine_version", {})))
	lines.append("| Playtest completed | %s |" % str(report.get("playtest_completed", false)))
	lines.append("| Playtest elapsed | %s (%s seconds) |" % [str(report.get("playtest_elapsed_text", "")), str(report.get("playtest_elapsed_seconds", ""))])
	var target: Dictionary = report.get("elapsed_vs_target_seconds", {})
	lines.append("| Target delta | below_min=%s, above_max=%s, within_window=%s |" % [
		str(target.get("below_min", "")),
		str(target.get("above_max", "")),
		str(target.get("within_window", ""))
	])
	var fixed_review: Dictionary = report.get("fixed_review_read_aloud", {})
	lines.append("| Fixed Review wait | %s seconds / %s |" % [
		str(fixed_review.get("total_seconds", "")),
		str(fixed_review.get("total_text", ""))
	])
	lines.append("| Timeline monotonic | %s |" % str(report.get("playtest_events_monotonic", false)))
	lines.append("| Timeline coverage complete | %s |" % str(report.get("timeline_coverage_complete", false)))
	lines.append("| Event count | %s |" % str(report.get("playtest_event_count", "")))
	var completed_quests: Array = report.get("completed_quests", [])
	lines.append("| Completed quests | %s |" % _join_mapped_array(completed_quests, QUEST_LABELS))
	lines.append("| Completed show | %s |" % _join_mapped_array(report.get("completed_reviews", []), REVIEW_LABELS))
	lines.append("| Keepsakes | %s |" % _join_mapped_array(report.get("rewards", []), REWARD_LABELS))
	lines.append("| Word records | %s |" % _join_array(report.get("learned_words", [])))
	lines.append("| Expression records | %s |" % _join_array(report.get("learned_patterns", [])))
	lines.append("| Manual timing hint | %s |" % str(report.get("manual_timing_hint", "")))
	lines.append("| Manual verdict required | %s |" % str(report.get("manual_verdict_required", "")))
	lines.append("| Manual result |  |")
	lines.append("| Manual notes |  |")
	lines.append("")
	lines.append("### Timing Record Paste")
	lines.append("")
	lines.append("| Item | Record |")
	lines.append("|---|---|")
	lines.append("| 是否点击“完成摘要阅读” | %s |" % ("是" if bool(report.get("playtest_completed", false)) else "否"))
	lines.append("| 是否点击“导出计时报告” | 是 |")
	lines.append("| 报告路径 | `user://mvp_0_2_playtest_report.json` |")
	lines.append("| 报告 `playtest_elapsed_text` | %s |" % str(report.get("playtest_elapsed_text", "")))
	lines.append("| 报告 `elapsed_vs_target_seconds` | below_min: %s / above_max: %s / within_window: %s |" % [
		str(target.get("below_min", "")),
		str(target.get("above_max", "")),
		str(target.get("within_window", ""))
	])
	lines.append("| 报告 `fixed_review_read_aloud.total_seconds` | %s |" % str(fixed_review.get("total_seconds", "")))
	lines.append("| 报告 `playtest_events_monotonic` | %s |" % str(report.get("playtest_events_monotonic", false)))
	lines.append("| 报告 `timeline_coverage_complete` | %s |" % str(report.get("timeline_coverage_complete", false)))
	lines.append("| 报告 `manual_result` | 留空 |")
	lines.append("")
	lines.append("### Debug IDs")
	lines.append("")
	lines.append("| Field | Raw IDs |")
	lines.append("|---|---|")
	lines.append("| completed_quests | %s |" % _join_array(completed_quests))
	lines.append("| completed_tasks | %s |" % _join_array(report.get("completed_tasks", [])))
	lines.append("| completed_reviews | %s |" % _join_array(report.get("completed_reviews", [])))
	lines.append("| rewards | %s |" % _join_array(report.get("rewards", [])))
	lines.append("")
	lines.append("### Segment Timing Helper")
	lines.append("")
	lines.append("> 报告节点参考，不替代人工秒表。")
	lines.append("")
	lines.append("| From | To | Delta |")
	lines.append("|---|---|---:|")
	for delta: Variant in report.get("event_elapsed_deltas", []):
		if typeof(delta) != TYPE_DICTIONARY:
			continue
		var data: Dictionary = delta
		lines.append("| %s | %s | %s |" % [str(data.get("from", "")), str(data.get("to", "")), str(data.get("delta_text", ""))])
	lines.append("")
	lines.append("### Timeline")
	lines.append("")
	lines.append("| Event | Elapsed |")
	lines.append("|---|---:|")
	for event: Variant in report.get("playtest_events", []):
		if typeof(event) != TYPE_DICTIONARY:
			continue
		var data: Dictionary = event
		lines.append("| %s | %s |" % [str(data.get("label", data.get("id", ""))), str(data.get("elapsed_text", ""))])
	lines.append("")
	lines.append("### Segment Deltas")
	lines.append("")
	lines.append("| From | To | Delta |")
	lines.append("|---|---|---:|")
	for delta: Variant in report.get("event_elapsed_deltas", []):
		if typeof(delta) != TYPE_DICTIONARY:
			continue
		var data: Dictionary = delta
		lines.append("| %s | %s | %s |" % [str(data.get("from", "")), str(data.get("to", "")), str(data.get("delta_text", ""))])
	lines.append("")
	lines.append("> This summary is evidence only. It does not approve MVP completion; fill the manual result after human timing and experience review.")
	lines.append("")
	return "\n".join(lines)


static func save_summary(path: String, report: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("summary file should be writable: %s" % path)
		return false
	file.store_string(build_summary(report))
	return true


static func _engine_version_text(value: Variant) -> String:
	if typeof(value) != TYPE_DICTIONARY:
		return str(value)
	var data: Dictionary = value
	return "%s.%s.%s %s" % [
		str(data.get("major", "")),
		str(data.get("minor", "")),
		str(data.get("patch", "")),
		str(data.get("status", ""))
	]


static func _join_array(value: Variant) -> String:
	if typeof(value) != TYPE_ARRAY:
		return str(value)
	var items: Array[String] = []
	for item: Variant in value:
		items.append(str(item))
	return ", ".join(items)


static func _join_mapped_array(value: Variant, labels: Dictionary) -> String:
	if typeof(value) != TYPE_ARRAY:
		return str(value)
	var items: Array[String] = []
	for item: Variant in value:
		var key := str(item)
		items.append(str(labels.get(key, key)))
	if items.is_empty():
		return "-"
	return ", ".join(items)


static func _require(errors: Array[String], condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)


static func _require_contains(errors: Array[String], value: Variant, expected: String, message: String) -> void:
	if typeof(value) != TYPE_ARRAY:
		errors.append("%s should be an array" % message)
		return
	var items: Array = value
	if not items.has(expected):
		errors.append("Missing %s: %s" % [message, expected])


static func _require_int_array(errors: Array[String], actual: Variant, expected: Array, label: String) -> void:
	if typeof(actual) != TYPE_ARRAY:
		errors.append("%s should be an array" % label)
		return
	var actual_array: Array = actual
	if actual_array.size() != expected.size():
		errors.append("%s size mismatch" % label)
		return
	for i in range(expected.size()):
		if int(actual_array[i]) != int(expected[i]):
			errors.append("%s mismatch at index %d" % [label, i])
			return
