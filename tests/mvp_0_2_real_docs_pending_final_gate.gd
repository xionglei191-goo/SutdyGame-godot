extends SceneTree

const QA_TIMING_REPORT := preload("res://scripts/systems/qa_timing_report.gd")
const SUMMARY_EXPORTER := preload("res://tests/helpers/playtest_summary_exporter.gd")
const FINAL_GATE := preload("res://tests/helpers/playtest_manual_final_gate.gd")

const TIMING_RECORD_PATH := "res://docs/development/MVP_0_2_试玩计时记录.md"
const ACCEPTANCE_PATH := "res://docs/development/MVP_0_2_验收记录.md"

var failed := false


func _initialize() -> void:
	var report := QA_TIMING_REPORT.build(_fixture_snapshot())
	report["elapsed_vs_target_seconds"] = {
		"below_min": 0.0,
		"above_max": 0.0,
		"within_window": true
	}
	var summary := SUMMARY_EXPORTER.build_summary(report)
	var timing_record := _read_text(TIMING_RECORD_PATH)
	var acceptance := _read_text(ACCEPTANCE_PATH)
	var errors: Array[String] = FINAL_GATE.validate(report, summary, timing_record, acceptance)

	if not errors.is_empty():
		push_error("\n".join(errors))
	_assert(errors.is_empty(), "real docs should pass final gate with the recorded manual evidence")

	if failed:
		quit(1)
		return
	print("MVP 0.2 real docs final gate consistency fixture passed.")
	quit(0)


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	_assert(file != null, "document should be readable: %s" % path)
	if file == null:
		return ""
	return file.get_as_text()


func _fixture_snapshot() -> Dictionary:
	# Event timestamps aligned with real timing record: total 02:59 (179s)
	var event_specs := [
		["playtest_started", "试玩开始", 0],
		["prologue_go_to_school_started", "First Trip 开始", 3],
		["prologue_go_to_school_completed", "First Trip 完成", 23],
		["mina_intro_dialogue_finished", "Mina 对话结束", 23],
		["g4_u1_school_tour_started", "Walk With Mina 开始", 23],
		["g4_u1_school_tour_completed", "Walk With Mina 完成", 38],
		["leo_room_intro_dialogue_finished", "Leo 对话结束", 46],
		["g4_u1_tidy_classroom_started", "Room Helper 开始", 46],
		["g4_u1_tidy_classroom_completed", "Room Helper 完成", 55],
		["nora_garden_intro_dialogue_finished", "Nora 对话结束", 61],
		["g4_u1_garden_bird_started", "Bird Watch 开始", 61],
		["g4_u1_garden_bird_completed", "Bird Watch 完成", 71],
		["review_challenge_started", "Story Show 开始", 71],
		["review_challenge_completed", "Story Show 完成", 179],
		["parent_summary_shown", "家长摘要显示", 179],
		["parent_summary_read", "家长摘要阅读完成", 179],
		["playtest_completed", "试玩完成", 179]
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
		"playtest_elapsed_msec": 179000,
		"playtest_elapsed_seconds": 179,
		"playtest_elapsed_text": "02:59",
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
		failed = true
