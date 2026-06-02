class_name PlaytestReportValidator
extends RefCounted


static func validate(report: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	_require(errors, int(report.get("schema_version", 0)) == 2, "report schema should be v2")
	_require(errors, str(report.get("report_type", "")) == "mvp_0_2_playtest_timing", "report type should match MVP timing report")
	_require(errors, bool(report.get("playtest_completed", false)), "report should come from a completed playtest")
	_require(errors, int(report.get("playtest_elapsed_msec", 0)) > 0, "report should include elapsed msec")
	_require(errors, int(report.get("playtest_elapsed_seconds", 0)) > 0, "report should include elapsed seconds")
	_require(errors, str(report.get("playtest_elapsed_text", "")).contains(":"), "report should include formatted elapsed time")
	_require(errors, bool(report.get("playtest_events_monotonic", false)), "report timeline should be monotonic")
	_require(errors, bool(report.get("timeline_coverage_complete", false)), "report should include all expected timeline events")
	_require(errors, bool(report.get("manual_verdict_required", false)), "report should require manual verdict")
	_require(errors, str(report.get("manual_result", "")) == "", "report should not auto-fill manual result")
	for forbidden_field in ["auto_pass", "passed", "is_passed", "qa_passed"]:
		_require(errors, not report.has(forbidden_field), "report should not include %s field" % forbidden_field)

	var target_seconds: Dictionary = report.get("target_duration_seconds", {})
	_require(errors, int(target_seconds.get("min", 0)) == 120, "report should include 2 minute lower bound")
	_require(errors, int(target_seconds.get("max", 0)) == 300, "report should include 5 minute upper bound")
	var elapsed_vs_target: Dictionary = report.get("elapsed_vs_target_seconds", {})
	_require(errors, elapsed_vs_target.has("below_min"), "report should include below-min delta")
	_require(errors, elapsed_vs_target.has("above_max"), "report should include above-max delta")
	_require(errors, elapsed_vs_target.has("within_window"), "report should include within-window evidence")

	var fixed_review: Dictionary = report.get("fixed_review_read_aloud", {})
	_require(errors, int(fixed_review.get("review_prompt_count", 0)) == 25, "report should include review prompt count")
	_require(errors, int(fixed_review.get("prompt_count", 0)) == 6, "report should include read-aloud prompt count")
	_require(errors, int(fixed_review.get("total_seconds", 0)) == 30, "report should include fixed read-aloud seconds")
	_require(errors, str(fixed_review.get("total_text", "")) == "00:30", "report should include formatted fixed read-aloud time")
	_require_int_array(errors, fixed_review.get("seconds_by_prompt", []), [5, 5, 5, 5, 5, 5], "fixed read-aloud sequence")

	_require(errors, report.has("completed_quests"), "report should include primary completed_quests")
	var completed_quests: Array = report.get("completed_quests", [])
	if report.has("completed_tasks"):
		_require(errors, report.get("completed_tasks", []) == completed_quests, "legacy completed_tasks should mirror completed_quests")
	_require_contains(errors, completed_quests, "prologue_go_to_school", "completed prologue quest")
	_require_contains(errors, completed_quests, "g4_u1_school_tour", "completed Walk With Mina quest")
	_require_contains(errors, completed_quests, "g4_u1_tidy_classroom", "completed Room Helper quest")
	_require_contains(errors, completed_quests, "g4_u1_garden_bird", "completed Bird Watch quest")
	_require_contains(errors, report.get("completed_reviews", []), "mvp_0_2_review_challenge", "completed review")
	_require_event_coverage(errors, report.get("event_ids_present", {}))
	_require_event_deltas(errors, report.get("event_elapsed_deltas", []), int(report.get("playtest_event_count", 0)))
	return errors


static func load_report(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


static func _require_event_coverage(errors: Array[String], coverage: Dictionary) -> void:
	for event_id in [
		"playtest_started",
		"prologue_go_to_school_started",
		"prologue_go_to_school_completed",
		"g4_u1_school_tour_started",
		"g4_u1_school_tour_completed",
		"g4_u1_tidy_classroom_started",
		"g4_u1_tidy_classroom_completed",
		"g4_u1_garden_bird_started",
		"g4_u1_garden_bird_completed",
		"review_challenge_started",
		"review_challenge_completed",
		"parent_summary_shown",
		"parent_summary_read",
		"playtest_completed"
	]:
		_require(errors, bool(coverage.get(event_id, false)), "report should mark event present: %s" % event_id)


static func _require_event_deltas(errors: Array[String], deltas: Array, event_count: int) -> void:
	_require(errors, deltas.size() == event_count - 1, "report should include one delta between each event")
	for delta: Variant in deltas:
		_require(errors, typeof(delta) == TYPE_DICTIONARY, "event delta should be a dictionary")
		if typeof(delta) != TYPE_DICTIONARY:
			continue
		var data: Dictionary = delta
		_require(errors, int(data.get("delta_msec", -1)) >= 0, "event delta should be non-negative")
		_require(errors, str(data.get("delta_text", "")).contains(":"), "event delta should include formatted text")


static func _require_contains(errors: Array[String], values: Variant, expected: String, label: String) -> void:
	_require(errors, typeof(values) == TYPE_ARRAY, "%s collection should be an array" % label)
	if typeof(values) != TYPE_ARRAY:
		return
	var array: Array = values
	_require(errors, array.has(expected), "missing %s: %s" % [label, expected])


static func _require_int_array(errors: Array[String], actual: Variant, expected: Array, label: String) -> void:
	_require(errors, typeof(actual) == TYPE_ARRAY, "%s should be an array" % label)
	if typeof(actual) != TYPE_ARRAY:
		return
	var actual_array: Array = actual
	_require(errors, actual_array.size() == expected.size(), "%s size mismatch" % label)
	for i in range(expected.size()):
		_require(errors, int(actual_array[i]) == int(expected[i]), "%s mismatch at index %d" % [label, i])


static func _require(errors: Array[String], condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
