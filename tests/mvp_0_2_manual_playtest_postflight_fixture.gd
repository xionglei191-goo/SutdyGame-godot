extends SceneTree

const QA_TIMING_REPORT := preload("res://scripts/systems/qa_timing_report.gd")
const REPORT_VALIDATOR := preload("res://tests/helpers/playtest_report_validator.gd")
const SUMMARY_EXPORTER := preload("res://tests/helpers/playtest_summary_exporter.gd")
const POSTFLIGHT_RUNNER := preload("res://tests/helpers/playtest_postflight_runner.gd")


func _initialize() -> void:
	var game_state: Node = root.get_node("GameState")
	var report := QA_TIMING_REPORT.build(_fixture_snapshot())
	var errors: Array[String] = REPORT_VALIDATOR.validate(report) + SUMMARY_EXPORTER.validate_report(report)
	_assert(errors.is_empty(), "fixture report should pass postflight validation: %s" % ", ".join(errors))
	_assert(QA_TIMING_REPORT.save(game_state.DEFAULT_PLAYTEST_REPORT_PATH, _fixture_snapshot()), "fixture report should save to default report path")
	var result: Dictionary = POSTFLIGHT_RUNNER.run(game_state.DEFAULT_PLAYTEST_REPORT_PATH, SUMMARY_EXPORTER.SUMMARY_PATH)
	_assert(bool(result.get("ok", false)), "fixture postflight runner should pass: %s" % ", ".join(result.get("errors", [])))
	_assert(result.get("warnings", []).is_empty(), "in-window fixture should not warn")
	_assert(FileAccess.file_exists(game_state.DEFAULT_PLAYTEST_REPORT_PATH), "fixture report should exist")
	_assert(FileAccess.file_exists(SUMMARY_EXPORTER.SUMMARY_PATH), "fixture summary should exist")
	var summary_file := FileAccess.open(SUMMARY_EXPORTER.SUMMARY_PATH, FileAccess.READ)
	_assert(summary_file != null, "fixture summary should be readable")
	var summary_text := summary_file.get_as_text()
	_assert(summary_text.contains("### Timing Record Paste"), "postflight summary should include paste block")
	_assert(summary_text.contains("### Segment Timing Helper"), "postflight summary should include segment helper")
	_assert(summary_text.contains("| Manual result |  |"), "postflight summary should keep manual result blank")
	_assert(bool(result.get("summary_saved", false)), "postflight runner should mark summary saved")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SUMMARY_EXPORTER.SUMMARY_PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_PLAYTEST_REPORT_PATH))
	print("MVP 0.2 manual playtest postflight fixture passed.")
	quit(0)


func _fixture_snapshot() -> Dictionary:
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
	return {
		"completed_quests": ["prologue_go_to_school", "g4_u1_school_tour", "g4_u1_tidy_classroom", "g4_u1_garden_bird"],
		"completed_tasks": ["prologue_go_to_school", "g4_u1_school_tour", "g4_u1_tidy_classroom", "g4_u1_garden_bird"],
		"rewards": ["first_trip_ticket", "school_star_piece", "tidy_badge_piece", "garden_leaf_piece"],
		"learned_words": ["library", "book", "bird"],
		"learned_patterns": ["This is the library.", "Put the book on the shelf.", "Where is the bird?"],
		"completed_reviews": ["mvp_0_2_review_challenge"],
		"playtest_elapsed_msec": 180000,
		"playtest_elapsed_seconds": 180,
		"playtest_elapsed_text": "03:00",
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
