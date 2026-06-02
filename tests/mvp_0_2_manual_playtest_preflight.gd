extends SceneTree

const SUMMARY_PATH := "user://mvp_0_2_playtest_report_summary.md"


func _initialize() -> void:
	var game_state: Node = root.get_node("GameState")
	_cleanup_default_files(game_state)
	_assert_not_exists(game_state.DEFAULT_SAVE_PATH, "default save should be absent before manual playtest")
	_assert_not_exists(game_state.DEFAULT_PLAYTEST_REPORT_PATH, "default playtest report should be absent before manual playtest")
	_assert_not_exists(SUMMARY_PATH, "default playtest summary should be absent before manual playtest")

	game_state.reset_progress()
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	_assert(main_scene != null, "Main scene should load")
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	await process_frame

	var snapshot: Dictionary = game_state.debug_snapshot()
	_assert(snapshot["completed_quests"].is_empty(), "preflight should start with no completed quests")
	_assert(snapshot["rewards"].is_empty(), "preflight should start with no rewards")
	_assert(snapshot["completed_reviews"].is_empty(), "preflight should start with no completed review")
	_assert(not bool(snapshot["playtest_completed"]), "preflight should not be completed")
	_assert(int(snapshot["playtest_elapsed_msec"]) >= 0, "preflight timer should be initialized")
	_assert(_has_event(snapshot["playtest_events"], "playtest_started"), "preflight should record playtest start on Main ready")

	var town_map: Node = main.get_node("TownMap")
	_assert(town_map.get_node("HomeLayer").visible, "preflight should start at home")
	_assert(not town_map.get_node("WorldOverviewLayer").visible, "preflight should not start on world overview")
	_assert(not town_map.get_node("CampusGateLayer").visible, "preflight should not restore campus gate immediately")
	_assert(not town_map.get_node("ClassroomLayer").visible, "preflight should not restore classroom")
	_assert(not town_map.get_node("GardenLayer").visible, "preflight should not restore garden")

	var parent_summary: CanvasLayer = main.get_node("ParentSummary")
	parent_summary.refresh()
	var finish_button: Button = parent_summary.get_node("Panel/MarginContainer/VBoxContainer/FinishReadingButton")
	var export_button: Button = parent_summary.get_node("Panel/MarginContainer/VBoxContainer/ExportReportButton")
	_assert(finish_button.disabled, "preflight should not allow finishing parent summary early")
	_assert(finish_button.text == "完成 4 个 Quest 和 Story Show 后可用", "preflight should explain finish prerequisite")
	_assert(export_button.disabled, "preflight should not allow report export before completion")
	finish_button.pressed.emit()
	_assert(not game_state.playtest_completed, "early finish press should not complete playtest")
	_assert_not_exists(game_state.DEFAULT_PLAYTEST_REPORT_PATH, "preflight should not create report for incomplete playtest")

	main.queue_free()
	await process_frame
	game_state.reset_progress()
	_cleanup_default_files(game_state)
	_assert_not_exists(game_state.DEFAULT_SAVE_PATH, "preflight should leave default save absent")
	_assert_not_exists(game_state.DEFAULT_PLAYTEST_REPORT_PATH, "preflight should leave default report absent")
	_assert_not_exists(SUMMARY_PATH, "preflight should leave default summary absent")
	print("MVP 0.2 manual playtest preflight passed.")
	print("Recommended next: cd /home/xionglei/GameProject/SutdyGame-godot && ./scripts/dev/run_mvp_0_2_manual_playtest.sh")
	print("Step-by-step mode: start external timing, then run: cd /home/xionglei/GameProject/SutdyGame-godot && godot --path .")
	quit(0)


func _assert_not_exists(path: String, message: String) -> void:
	_assert(not FileAccess.file_exists(path), "%s: %s" % [message, ProjectSettings.globalize_path(path)])


func _cleanup_default_files(game_state: Node) -> void:
	for path: String in [
		game_state.DEFAULT_SAVE_PATH,
		game_state.DEFAULT_PLAYTEST_REPORT_PATH,
		SUMMARY_PATH
	]:
		if FileAccess.file_exists(path):
			var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
			_assert(error == OK, "preflight cleanup should remove %s" % ProjectSettings.globalize_path(path))


func _has_event(events: Array, event_id: String) -> bool:
	for event: Variant in events:
		if typeof(event) == TYPE_DICTIONARY and str(event.get("id", "")) == event_id:
			return true
	return false


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
