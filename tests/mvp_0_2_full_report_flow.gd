extends SceneTree

const POSTFLIGHT_RUNNER := preload("res://tests/helpers/playtest_postflight_runner.gd")
const SUMMARY_EXPORTER := preload("res://tests/helpers/playtest_summary_exporter.gd")

var _game_state: Node
var _failed := false


func _initialize() -> void:
	var game_state: Node = root.get_node("GameState")
	_game_state = game_state
	_cleanup_default_files(game_state)
	game_state.reset_progress()

	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	if not _assert(main_scene != null, "Main scene should load"):
		return
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	await process_frame

	game_state.reset_progress()
	game_state.start_playtest_timer(true)
	await _run_main_flow(main)
	if _failed:
		return
	if not _assert(game_state.save_playtest_report(game_state.DEFAULT_PLAYTEST_REPORT_PATH), "full flow should export default playtest report"):
		return

	var result: Dictionary = POSTFLIGHT_RUNNER.run(game_state.DEFAULT_PLAYTEST_REPORT_PATH, SUMMARY_EXPORTER.SUMMARY_PATH)
	if not _assert(bool(result.get("ok", false)), "postflight runner should accept full main-scene report: %s" % ", ".join(result.get("errors", []))):
		return
	if not _assert(bool(result.get("summary_saved", false)), "postflight runner should save summary"):
		return
	if not _assert(FileAccess.file_exists(game_state.DEFAULT_PLAYTEST_REPORT_PATH), "default report should exist before cleanup"):
		return
	if not _assert(FileAccess.file_exists(SUMMARY_EXPORTER.SUMMARY_PATH), "default summary should exist before cleanup"):
		return

	var report: Dictionary = result.get("report", {})
	if not _assert(bool(report.get("playtest_completed", false)), "full report should be completed"):
		return
	if not _assert(bool(report.get("timeline_coverage_complete", false)), "full report should have complete timeline coverage"):
		return
	if not _assert(str(report.get("manual_result", "")) == "", "full report should not auto-fill manual result"):
		return
	if not _assert(result.get("warnings", []).has("TIMING_OUT_OF_TARGET"), "fast headless flow should warn that real timing remains manual"):
		return

	var summary_file := FileAccess.open(SUMMARY_EXPORTER.SUMMARY_PATH, FileAccess.READ)
	if not _assert(summary_file != null, "summary should be readable"):
		return
	var summary_text := summary_file.get_as_text()
	if not _assert(summary_text.contains("### Timing Record Paste"), "summary should include timing paste section"):
		return
	if not _assert(summary_text.contains("### Segment Timing Helper"), "summary should include segment helper"):
		return
	if not _assert(summary_text.contains("| Manual result |  |"), "summary should keep manual result blank"):
		return

	main.queue_free()
	await process_frame
	game_state.reset_progress()
	_cleanup_default_files(game_state)
	if not _assert(not FileAccess.file_exists(game_state.DEFAULT_SAVE_PATH), "full report flow should clean default save"):
		return
	if not _assert(not FileAccess.file_exists(game_state.DEFAULT_PLAYTEST_REPORT_PATH), "full report flow should clean default report"):
		return
	if not _assert(not FileAccess.file_exists(SUMMARY_EXPORTER.SUMMARY_PATH), "full report flow should clean default summary"):
		return

	print("MVP 0.2 full report flow passed.")
	quit(0)


func _run_main_flow(main: Node) -> void:
	var quest_diary: CanvasLayer = main.get_node("QuestDiary")
	var drag_game: Node = main.get_node("DragPlaceGame")
	var parent_summary: CanvasLayer = main.get_node("ParentSummary")
	var story_show: CanvasLayer = main.get_node("StoryShow")

	quest_diary.start_quest("prologue_go_to_school")
	quest_diary.check_target("sunshine_school")
	await process_frame

	quest_diary.start_quest("g4_u1_school_tour")
	quest_diary.check_target("library")
	await process_frame

	quest_diary.start_quest("g4_u1_tidy_classroom")
	_assert(drag_game.place_item("book", "shelf"), "book should fit shelf")
	_assert(drag_game.place_item("pencil", "desk"), "pencil should fit desk")
	_assert(drag_game.place_item("bag", "under_desk"), "bag should fit under desk")
	await process_frame

	quest_diary.start_quest("g4_u1_garden_bird")
	quest_diary.check_target("bird")
	await process_frame
	_assert(story_show.visible, "review should be visible after three tasks")

	_complete_story_show(story_show)
	_assert(parent_summary.visible, "parent summary should open after review")
	parent_summary.refresh()
	var finish_reading_button: Button = parent_summary.get_node("Panel/MarginContainer/VBoxContainer/FinishReadingButton")
	_assert(not finish_reading_button.disabled, "finish reading should be enabled after review")
	await create_timer(1.1).timeout
	finish_reading_button.pressed.emit()
	await process_frame


func _complete_story_show(story_show: CanvasLayer) -> void:
	while story_show.visible:
		var prompt: Dictionary = story_show.prompts[story_show.current_index]
		if prompt.get("mode", "") == "read_aloud":
			story_show._start_reading_timer()
			story_show._on_read_timer_timeout()
		story_show.choose(str(prompt["answer"]))


func _cleanup_default_files(game_state: Node) -> void:
	for path: String in [
		game_state.DEFAULT_SAVE_PATH,
		game_state.DEFAULT_PLAYTEST_REPORT_PATH,
		SUMMARY_EXPORTER.SUMMARY_PATH
	]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _assert(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		if _game_state != null:
			_game_state.reset_progress()
			_cleanup_default_files(_game_state)
		_failed = true
		quit(1)
		return false
	return true
