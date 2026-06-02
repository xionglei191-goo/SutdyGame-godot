extends SceneTree

const QA_TIMING_REPORT := preload("res://scripts/systems/qa_timing_report.gd")
const REPORT_VALIDATOR := preload("res://tests/helpers/playtest_report_validator.gd")
const SUMMARY_EXPORTER := preload("res://tests/helpers/playtest_summary_exporter.gd")
const FIXTURE_SUMMARY_PATH := "user://mvp_0_2_fixture_playtest_report_summary.md"


func _initialize() -> void:
	var report := QA_TIMING_REPORT.build(_fixture_snapshot())
	var errors: Array[String] = REPORT_VALIDATOR.validate(report) + SUMMARY_EXPORTER.validate_report(report)
	_assert(errors.is_empty(), "fixture report should be valid for summary export: %s" % ", ".join(errors))

	var summary := SUMMARY_EXPORTER.build_summary(report)
	_assert(summary.contains("## MVP 0.2 Playtest Report Summary"), "summary should include title")
	_assert(summary.contains("within_window=true"), "summary should include target window result")
	_assert(summary.contains("| Completed quests | First Trip, Walk With Mina, Room Helper, Bird Watch |"), "summary should lead with front-end quest names")
	_assert(summary.contains("| Completed show | Story Show |"), "summary should lead with front-end show name")
	_assert(summary.contains("| Keepsakes | First Trip Ticket, Adventure Star, Room Helper Badge, Garden Leaf Charm |"), "summary should lead with front-end keepsake names")
	_assert(summary.contains("| Word records | library, book, bird |"), "summary should use parent-layer word record wording")
	_assert(summary.contains("| Expression records | This is the library., Put the book on the shelf., Where is the bird? |"), "summary should use parent-layer expression record wording")
	_assert(summary.contains("| Fixed Review wait | 30 seconds / 00:30 |"), "summary should include fixed review wait")
	_assert(summary.contains("### Timing Record Paste"), "summary should include timing-record paste section")
	_assert(summary.contains("| 是否点击“完成摘要阅读” | 是 |"), "summary should include finish-reading paste field")
	_assert(summary.contains("| 是否点击“导出计时报告” | 是 |"), "summary should include report-export paste field")
	_assert(summary.contains("| 报告路径 | `user://mvp_0_2_playtest_report.json` |"), "summary should include report path paste field")
	_assert(summary.contains("| 报告 `playtest_elapsed_text` | 03:00 |"), "summary should include timing record elapsed field")
	_assert(summary.contains("| 报告 `elapsed_vs_target_seconds` | below_min: 0 / above_max: 0 / within_window: true |"), "summary should include timing record target delta field")
	_assert(summary.contains("| 报告 `fixed_review_read_aloud.total_seconds` | 30 |"), "summary should include timing record fixed review field")
	_assert(summary.contains("| 报告 `playtest_events_monotonic` | true |"), "summary should include timing record monotonic field")
	_assert(summary.contains("| 报告 `timeline_coverage_complete` | true |"), "summary should include timing record coverage field")
	_assert(summary.contains("| 报告 `manual_result` | 留空 |"), "summary should keep timing record manual result blank")
	_assert(summary.contains("### Debug IDs"), "summary should keep raw ids in a debug section")
	_assert(summary.contains("| completed_quests | prologue_go_to_school, g4_u1_school_tour, g4_u1_tidy_classroom, g4_u1_garden_bird |"), "summary should keep quest ids in debug section")
	_assert(summary.contains("| completed_tasks | prologue_go_to_school, g4_u1_school_tour, g4_u1_tidy_classroom, g4_u1_garden_bird |"), "summary should keep raw task ids in debug section")
	_assert(summary.contains("| completed_reviews | mvp_0_2_review_challenge |"), "summary should keep raw review id in debug section")
	_assert(summary.contains("### Segment Timing Helper"), "summary should include segment timing helper")
	_assert(summary.contains("报告节点参考，不替代人工秒表"), "summary should warn segment helper is reference only")
	_assert(summary.contains("| review_challenge_started | review_challenge_completed | 00:30 |"), "summary should include review segment helper delta")
	_assert(summary.contains("| parent_summary_shown | parent_summary_read | 00:05 |"), "summary should include parent summary segment helper delta")
	_assert(summary.contains("### Timeline"), "summary should include timeline section")
	_assert(summary.contains("### Segment Deltas"), "summary should include segment deltas")
	_assert(summary.contains("| Manual result |  |"), "summary should keep manual result blank")
	_assert(summary.contains("| Manual notes |  |"), "summary should keep manual notes blank")
	_assert(summary.contains("This summary is evidence only"), "summary should include evidence-only note")

	_assert(SUMMARY_EXPORTER.save_summary(FIXTURE_SUMMARY_PATH, report), "fixture summary should save")
	var file := FileAccess.open(FIXTURE_SUMMARY_PATH, FileAccess.READ)
	_assert(file != null, "fixture summary file should be readable")
	_assert(file.get_as_text() == summary, "saved fixture summary should match generated summary")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(FIXTURE_SUMMARY_PATH))

	print("MVP 0.2 playtest summary fixture passed.")
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
		"completed_quests": [
			"prologue_go_to_school",
			"g4_u1_school_tour",
			"g4_u1_tidy_classroom",
			"g4_u1_garden_bird"
		],
		"completed_tasks": [
			"prologue_go_to_school",
			"g4_u1_school_tour",
			"g4_u1_tidy_classroom",
			"g4_u1_garden_bird"
		],
		"rewards": [
			"first_trip_ticket",
			"school_star_piece",
			"tidy_badge_piece",
			"garden_leaf_piece"
		],
		"learned_words": [
			"library",
			"book",
			"bird"
		],
		"learned_patterns": [
			"This is the library.",
			"Put the book on the shelf.",
			"Where is the bird?"
		],
		"completed_reviews": [
			"mvp_0_2_review_challenge"
		],
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
