class_name QATimingReport
extends RefCounted

const REPORT_TYPE := "mvp_0_2_playtest_timing"
const SCHEMA_VERSION := 2
const TARGET_MIN_SECONDS := 2 * 60
const TARGET_MAX_SECONDS := 5 * 60
const REVIEW_PROMPT_COUNT := 25
const FIXED_REVIEW_READ_SECONDS := [5, 5, 5, 5, 5, 5]
const EXPECTED_EVENT_IDS := [
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
]


static func build(snapshot: Dictionary) -> Dictionary:
	var events: Array = snapshot.get("playtest_events", [])
	var elapsed_seconds := int(snapshot.get("playtest_elapsed_seconds", 0))
	var fixed_review_seconds := _sum_ints(FIXED_REVIEW_READ_SECONDS)
	var event_coverage := _event_coverage(events)
	var completed_quests: Array = snapshot.get("completed_quests", [])
	return {
		"schema_version": SCHEMA_VERSION,
		"report_type": REPORT_TYPE,
		"generated_at_unix": Time.get_unix_time_from_system(),
		"engine_version": Engine.get_version_info(),
		"project_name": str(ProjectSettings.get_setting("application/config/name", "StudyGame")),
		"target_duration_minutes": {
			"min": 2,
			"max": 5
		},
		"target_duration_seconds": {
			"min": TARGET_MIN_SECONDS,
			"max": TARGET_MAX_SECONDS
		},
		"playtest_completed": bool(snapshot.get("playtest_completed", false)),
		"playtest_elapsed_msec": int(snapshot.get("playtest_elapsed_msec", 0)),
		"playtest_elapsed_seconds": elapsed_seconds,
		"playtest_elapsed_text": str(snapshot.get("playtest_elapsed_text", "00:00")),
		"elapsed_vs_target_seconds": {
			"below_min": max(0, TARGET_MIN_SECONDS - elapsed_seconds),
			"above_max": max(0, elapsed_seconds - TARGET_MAX_SECONDS),
			"within_window": elapsed_seconds >= TARGET_MIN_SECONDS and elapsed_seconds <= TARGET_MAX_SECONDS
		},
		"playtest_events": events,
		"playtest_event_count": events.size(),
		"playtest_events_monotonic": _events_are_monotonic(events),
		"event_ids_present": event_coverage,
		"timeline_coverage_complete": not event_coverage.values().has(false),
		"event_elapsed_deltas": _event_elapsed_deltas(events),
		"fixed_review_read_aloud": {
			"review_prompt_count": REVIEW_PROMPT_COUNT,
			"prompt_count": FIXED_REVIEW_READ_SECONDS.size(),
			"seconds_by_prompt": FIXED_REVIEW_READ_SECONDS.duplicate(),
			"total_seconds": fixed_review_seconds,
			"total_text": _format_seconds(fixed_review_seconds)
		},
		"minimum_fixed_wait_seconds": fixed_review_seconds,
		"completed_quests": completed_quests,
		"completed_tasks": completed_quests.duplicate(),
		"completed_reviews": snapshot.get("completed_reviews", []),
		"rewards": snapshot.get("rewards", []),
		"learned_words": snapshot.get("learned_words", []),
		"learned_patterns": snapshot.get("learned_patterns", []),
		"manual_context": {
			"tester": "",
			"device": "",
			"resolution": "",
			"input_method": "",
			"player_type": "",
			"first_play": ""
		},
		"manual_result": "",
		"manual_notes": "",
		"manual_timing_hint": _manual_timing_hint(elapsed_seconds),
		"manual_checklist_required": {
			"real_play_required": true,
			"child_reading_pressure_required": true,
			"input_feel_required": true,
			"visual_review_required": true
		},
		"manual_verdict_required": true,
		"manual_verdict_note": "人工验收以成人熟练试玩 2-5 分钟闭环为参考窗口；儿童首次试玩允许更长，但仍需记录儿童阅读压力、触控/鼠标手感和美术观感。"
	}


static func save(path: String, snapshot: Dictionary) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("QA timing report open failed: %s" % path)
		return false
	file.store_string(JSON.stringify(build(snapshot), "\t"))
	return true


static func _event_coverage(events: Array) -> Dictionary:
	var present := {}
	for expected_id: String in EXPECTED_EVENT_IDS:
		present[expected_id] = false
	for event: Variant in events:
		if typeof(event) != TYPE_DICTIONARY:
			continue
		var event_id := str(event.get("id", ""))
		if present.has(event_id):
			present[event_id] = true
	return present


static func _event_elapsed_deltas(events: Array) -> Array[Dictionary]:
	var deltas: Array[Dictionary] = []
	for i in range(1, events.size()):
		var previous: Variant = events[i - 1]
		var current: Variant = events[i]
		if typeof(previous) != TYPE_DICTIONARY or typeof(current) != TYPE_DICTIONARY:
			continue
		var start_msec: int = int(previous.get("elapsed_msec", 0))
		var end_msec: int = int(current.get("elapsed_msec", 0))
		var delta_msec: int = max(0, end_msec - start_msec)
		deltas.append({
			"from": str(previous.get("id", "")),
			"to": str(current.get("id", "")),
			"delta_msec": delta_msec,
			"delta_seconds": int(round(float(delta_msec) / 1000.0)),
			"delta_text": _format_seconds(int(round(float(delta_msec) / 1000.0)))
		})
	return deltas


static func _events_are_monotonic(events: Array) -> bool:
	var previous_msec := -1
	for event: Variant in events:
		if typeof(event) != TYPE_DICTIONARY:
			return false
		var elapsed_msec := int(event.get("elapsed_msec", -1))
		if elapsed_msec < previous_msec:
			return false
		previous_msec = elapsed_msec
	return true


static func _sum_ints(values: Array) -> int:
	var total := 0
	for value: Variant in values:
		total += int(value)
	return total


static func _format_seconds(total_seconds: int) -> String:
	var minutes := int(total_seconds / 60)
	var seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]


static func _manual_timing_hint(elapsed_seconds: int) -> String:
	if elapsed_seconds < TARGET_MIN_SECONDS:
		return "below_target_manual_review_required"
	if elapsed_seconds > TARGET_MAX_SECONDS:
		return "above_target_manual_review_required"
	return "inside_target_manual_review_required"
