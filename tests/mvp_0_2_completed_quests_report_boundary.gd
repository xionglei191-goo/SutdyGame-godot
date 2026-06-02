extends SceneTree

const QA_TIMING_REPORT := preload("res://scripts/systems/qa_timing_report.gd")
const REPORT_VALIDATOR := preload("res://tests/helpers/playtest_report_validator.gd")
const SUMMARY_EXPORTER := preload("res://tests/helpers/playtest_summary_exporter.gd")


func _initialize() -> void:
	var legacy_only_report := _valid_report()
	legacy_only_report.erase("completed_quests")
	legacy_only_report["completed_tasks"] = ["prologue_go_to_school", "g4_u1_school_tour", "g4_u1_tidy_classroom", "g4_u1_garden_bird"]
	var legacy_errors: Array[String] = REPORT_VALIDATOR.validate(legacy_only_report) + SUMMARY_EXPORTER.validate_report(legacy_only_report)
	_assert(legacy_errors.has("report should include primary completed_quests"), "validator should reject reports without primary completed_quests")
	_assert(legacy_errors.has("playtest report should include primary completed_quests"), "summary exporter should reject reports without primary completed_quests")

	var mismatched_report := _valid_report()
	mismatched_report["completed_tasks"] = ["g4_u1_school_tour"]
	var mismatch_errors: Array[String] = REPORT_VALIDATOR.validate(mismatched_report) + SUMMARY_EXPORTER.validate_report(mismatched_report)
	_assert(mismatch_errors.has("legacy completed_tasks should mirror completed_quests"), "validator should reject mismatched legacy completed_tasks")

	var built_from_legacy_snapshot := QA_TIMING_REPORT.build(_legacy_only_snapshot())
	_assert(built_from_legacy_snapshot.get("completed_quests", []).is_empty(), "report builder should not promote legacy completed_tasks to completed_quests")
	_assert(built_from_legacy_snapshot.get("completed_tasks", []).is_empty(), "report builder should derive legacy completed_tasks from completed_quests only")

	print("MVP 0.2 completed_quests report boundary passed.")
	quit(0)


func _valid_report() -> Dictionary:
	return QA_TIMING_REPORT.build(_valid_snapshot())


func _valid_snapshot() -> Dictionary:
	var quests := ["prologue_go_to_school", "g4_u1_school_tour", "g4_u1_tidy_classroom", "g4_u1_garden_bird"]
	return {
		"completed_quests": quests,
		"completed_tasks": quests,
		"completed_reviews": ["mvp_0_2_review_challenge"],
		"rewards": ["first_trip_ticket", "school_star_piece", "tidy_badge_piece", "garden_leaf_piece"],
		"learned_words": ["library", "book", "bird"],
		"learned_patterns": ["This is the library.", "Put the book on the shelf.", "Where is the bird?"],
		"playtest_elapsed_msec": 180000,
		"playtest_elapsed_seconds": 180,
		"playtest_elapsed_text": "03:00",
		"playtest_completed": true,
		"playtest_events": _valid_events()
	}


func _legacy_only_snapshot() -> Dictionary:
	var snapshot := _valid_snapshot()
	snapshot.erase("completed_quests")
	snapshot["completed_tasks"] = ["prologue_go_to_school", "g4_u1_school_tour", "g4_u1_tidy_classroom", "g4_u1_garden_bird"]
	return snapshot


func _valid_events() -> Array[Dictionary]:
	var event_specs := [
		["playtest_started", "试玩开始", 0],
		["prologue_go_to_school_started", "First Trip 开始", 5],
		["prologue_go_to_school_completed", "First Trip 完成", 12],
		["g4_u1_school_tour_started", "Walk With Mina 开始", 15],
		["g4_u1_school_tour_completed", "Walk With Mina 完成", 30],
		["g4_u1_tidy_classroom_started", "Room Helper 开始", 40],
		["g4_u1_tidy_classroom_completed", "Room Helper 完成", 70],
		["g4_u1_garden_bird_started", "Bird Watch 开始", 80],
		["g4_u1_garden_bird_completed", "Bird Watch 完成", 100],
		["review_challenge_started", "Story Show 开始", 120],
		["review_challenge_completed", "Story Show 完成", 150],
		["parent_summary_shown", "家长摘要显示", 170],
		["parent_summary_read", "家长摘要阅读完成", 175],
		["playtest_completed", "试玩完成", 180]
	]
	var events: Array[Dictionary] = []
	for spec: Array in event_specs:
		var elapsed_seconds := int(spec[2])
		events.append({
			"id": str(spec[0]),
			"label": str(spec[1]),
			"elapsed_msec": elapsed_seconds * 1000,
			"elapsed_seconds": elapsed_seconds,
			"elapsed_text": _format_seconds(elapsed_seconds)
		})
	return events


func _format_seconds(total_seconds: int) -> String:
	var minutes := int(total_seconds / 60)
	var seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
