extends SceneTree

const QA_TIMING_REPORT := preload("res://scripts/systems/qa_timing_report.gd")
const REPORT_VALIDATOR := preload("res://tests/helpers/playtest_report_validator.gd")
const POSTFLIGHT_RUNNER := preload("res://tests/helpers/playtest_postflight_runner.gd")

const TEMP_REPORT_PATH := "user://mvp_0_2_timing_window_guard_report.json"
const TEMP_SUMMARY_PATH := "user://mvp_0_2_timing_window_guard_summary.md"


func _initialize() -> void:
	_assert_timing_case(119, 1, 0, false, "below_target_manual_review_required")
	_assert_timing_case(120, 0, 0, true, "inside_target_manual_review_required")
	_assert_timing_case(300, 0, 0, true, "inside_target_manual_review_required")
	_assert_timing_case(301, 0, 1, false, "above_target_manual_review_required")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_REPORT_PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SUMMARY_PATH))
	print("MVP 0.2 timing window guard passed.")
	quit(0)


func _assert_timing_case(
	elapsed_seconds: int,
	expected_below_min: int,
	expected_above_max: int,
	expected_within_window: bool,
	expected_hint: String
) -> void:
	var report := QA_TIMING_REPORT.build(_fixture_snapshot(elapsed_seconds))
	var errors: Array[String] = REPORT_VALIDATOR.validate(report)
	_assert(errors.is_empty(), "timing case should still be structurally valid: %s" % ", ".join(errors))

	var delta: Dictionary = report.get("elapsed_vs_target_seconds", {})
	_assert(int(delta.get("below_min", -1)) == expected_below_min, "below-min delta mismatch for %s" % elapsed_seconds)
	_assert(int(delta.get("above_max", -1)) == expected_above_max, "above-max delta mismatch for %s" % elapsed_seconds)
	_assert(bool(delta.get("within_window", false)) == expected_within_window, "within-window mismatch for %s" % elapsed_seconds)
	_assert(str(report.get("manual_timing_hint", "")) == expected_hint, "manual timing hint mismatch for %s" % elapsed_seconds)
	_assert(bool(report.get("manual_verdict_required", false)), "manual verdict should remain required")
	_assert(str(report.get("manual_result", "")) == "", "manual result should stay blank")

	_assert(QA_TIMING_REPORT.save(TEMP_REPORT_PATH, _fixture_snapshot(elapsed_seconds)), "timing guard report should save")
	var result: Dictionary = POSTFLIGHT_RUNNER.run(TEMP_REPORT_PATH, TEMP_SUMMARY_PATH)
	_assert(bool(result.get("ok", false)), "postflight runner should accept complete timing report: %s" % ", ".join(result.get("errors", [])))
	_assert(FileAccess.file_exists(TEMP_SUMMARY_PATH), "postflight runner should save timing guard summary")
	_assert(result.get("warnings", []).has("TIMING_OUT_OF_TARGET") != expected_within_window, "postflight timing warning mismatch for %s" % elapsed_seconds)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_REPORT_PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SUMMARY_PATH))


func _fixture_snapshot(elapsed_seconds: int) -> Dictionary:
	var l1_start: int = min(15, max(1, elapsed_seconds - 11))
	var prologue_start: int = min(5, max(1, l1_start - 10))
	var prologue_end: int = min(12, max(prologue_start + 1, l1_start - 3))
	var l1_end: int = min(30, max(l1_start + 1, elapsed_seconds - 10))
	var l2_start: int = min(40, max(l1_end + 1, elapsed_seconds - 9))
	var l2_end: int = min(70, max(l2_start + 1, elapsed_seconds - 8))
	var l3_start: int = min(80, max(l2_end + 1, elapsed_seconds - 7))
	var l3_end: int = min(100, max(l3_start + 1, elapsed_seconds - 6))
	var review_start: int = min(110, max(l3_end + 1, elapsed_seconds - 5))
	var review_end: int = min(115, max(review_start + 1, elapsed_seconds - 3))
	var summary_shown: int = min(116, max(review_end + 1, elapsed_seconds - 2))
	var summary_read: int = min(118, max(summary_shown + 1, elapsed_seconds - 1))
	var event_specs := [
		["playtest_started", "试玩开始", 0],
		["prologue_go_to_school_started", "First Trip 开始", prologue_start],
		["prologue_go_to_school_completed", "First Trip 完成", prologue_end],
		["g4_u1_school_tour_started", "Walk With Mina 开始", l1_start],
		["g4_u1_school_tour_completed", "Walk With Mina 完成", l1_end],
		["g4_u1_tidy_classroom_started", "Room Helper 开始", l2_start],
		["g4_u1_tidy_classroom_completed", "Room Helper 完成", l2_end],
		["g4_u1_garden_bird_started", "Bird Watch 开始", l3_start],
		["g4_u1_garden_bird_completed", "Bird Watch 完成", l3_end],
		["review_challenge_started", "Story Show 开始", review_start],
		["review_challenge_completed", "Story Show 完成", review_end],
		["parent_summary_shown", "家长摘要显示", summary_shown],
		["parent_summary_read", "家长摘要阅读完成", summary_read],
		["playtest_completed", "试玩完成", elapsed_seconds]
	]
	var events: Array[Dictionary] = []
	for spec: Array in event_specs:
		var seconds := int(spec[2])
		events.append({
			"id": str(spec[0]),
			"label": str(spec[1]),
			"elapsed_msec": seconds * 1000,
			"elapsed_seconds": seconds,
			"elapsed_text": _format_seconds(seconds)
		})
	return {
		"completed_quests": ["prologue_go_to_school", "g4_u1_school_tour", "g4_u1_tidy_classroom", "g4_u1_garden_bird"],
		"completed_tasks": ["prologue_go_to_school", "g4_u1_school_tour", "g4_u1_tidy_classroom", "g4_u1_garden_bird"],
		"rewards": ["first_trip_ticket", "school_star_piece", "tidy_badge_piece", "garden_leaf_piece"],
		"learned_words": ["library", "book", "bird"],
		"learned_patterns": ["This is the library.", "Put the book on the shelf.", "Where is the bird?"],
		"completed_reviews": ["mvp_0_2_review_challenge"],
		"playtest_elapsed_msec": elapsed_seconds * 1000,
		"playtest_elapsed_seconds": elapsed_seconds,
		"playtest_elapsed_text": _format_seconds(elapsed_seconds),
		"playtest_completed": true,
		"playtest_events": events
	}


func _format_seconds(total_seconds: int) -> String:
	var minutes := int(total_seconds / 60)
	var seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
