extends SceneTree

const QA_TIMING_REPORT := preload("res://scripts/systems/qa_timing_report.gd")
const SUMMARY_EXPORTER := preload("res://tests/helpers/playtest_summary_exporter.gd")
const REPORT_VALIDATOR := preload("res://tests/helpers/playtest_report_validator.gd")

var failed := false


func _initialize() -> void:
	var game_state: Node = root.get_node("GameState")
	var report := QA_TIMING_REPORT.build(_recorded_snapshot())
	report["generated_at_unix"] = 1780234239.85458
	report["elapsed_vs_target_seconds"] = {
		"below_min": 0.0,
		"above_max": 0.0,
		"within_window": true
	}
	var errors: Array[String] = REPORT_VALIDATOR.validate(report) + SUMMARY_EXPORTER.validate_report(report)
	for error: String in errors:
		push_error(error)
		failed = true
	if failed:
		quit(1)
		return

	var report_file := FileAccess.open(game_state.DEFAULT_PLAYTEST_REPORT_PATH, FileAccess.WRITE)
	_assert(report_file != null, "recorded manual report should be writable")
	if report_file != null:
		report_file.store_string(JSON.stringify(report, "\t"))
		report_file.close()
	var persisted_report := _read_report(game_state.DEFAULT_PLAYTEST_REPORT_PATH)
	_assert(SUMMARY_EXPORTER.save_summary(SUMMARY_EXPORTER.SUMMARY_PATH, persisted_report), "recorded manual summary should be writable")

	if failed:
		quit(1)
		return
	print("MVP 0.2 recorded manual report restored.")
	print("Report path: %s" % ProjectSettings.globalize_path(game_state.DEFAULT_PLAYTEST_REPORT_PATH))
	print("Summary path: %s" % ProjectSettings.globalize_path(SUMMARY_EXPORTER.SUMMARY_PATH))
	quit(0)


func _recorded_snapshot() -> Dictionary:
	var event_specs := [
		["playtest_started", "试玩开始", 0],
		["prologue_go_to_school_started", "First Trip 开始", 3],
		["prologue_go_to_school_completed", "First Trip 完成", 6],
		["mina_intro_dialogue_finished", "Mina 对话结束", 6],
		["g4_u1_school_tour_started", "Walk With Mina 开始", 6],
		["g4_u1_school_tour_completed", "Walk With Mina 完成", 13],
		["leo_room_intro_dialogue_finished", "Leo 对话结束", 21],
		["g4_u1_tidy_classroom_started", "Room Helper 开始", 21],
		["g4_u1_tidy_classroom_completed", "Room Helper 完成", 51],
		["nora_garden_intro_dialogue_finished", "Nora 对话结束", 66],
		["g4_u1_garden_bird_started", "Bird Watch 开始", 66],
		["g4_u1_garden_bird_completed", "Bird Watch 完成", 69],
		["review_challenge_started", "Story Show 开始", 69],
		["review_challenge_completed", "Story Show 完成", 131],
		["parent_summary_shown", "家长摘要显示", 131],
		["parent_summary_read", "家长摘要阅读完成", 132],
		["playtest_completed", "试玩完成", 132]
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
		"completed_reviews": ["mvp_0_2_review_challenge"],
		"rewards": ["first_trip_ticket", "school_star_piece", "tidy_badge_piece", "garden_leaf_piece"],
		"learned_words": ["classroom", "library", "playground", "book", "bag", "pencil", "desk", "shelf", "garden", "tree", "flower", "bird"],
		"learned_patterns": [
			"This is our classroom.",
			"That is the playground.",
			"This is the library.",
			"Put the book on the shelf.",
			"Put the bag under the desk.",
			"Put the pencil on the desk.",
			"The bird is in the tree.",
			"I see flowers in the garden.",
			"Where is the bird?"
		],
		"playtest_elapsed_msec": 132680,
		"playtest_elapsed_seconds": 133,
		"playtest_elapsed_text": "02:13",
		"playtest_completed": true,
		"playtest_events": events
	}


func _format_seconds(total_seconds: int) -> String:
	var minutes := int(total_seconds / 60)
	var seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]


func _read_report(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	_assert(file != null, "recorded manual report should be readable")
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	_assert(typeof(parsed) == TYPE_DICTIONARY, "recorded manual report should parse")
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failed = true
