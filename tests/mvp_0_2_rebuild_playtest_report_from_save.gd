extends SceneTree

const SUMMARY_EXPORTER := preload("res://tests/helpers/playtest_summary_exporter.gd")


func _initialize() -> void:
	var game_state: Node = root.get_node("GameState")
	if not game_state.load_game():
		push_error("Missing default save. Run a manual playtest and click 完成摘要阅读 first.")
		quit(1)
		return
	if not bool(game_state.playtest_completed):
		push_error("Default save exists, but playtest is not completed. Finish parent summary reading first.")
		quit(1)
		return
	if not game_state.save_playtest_report():
		push_error("Failed to rebuild default playtest report from current default save.")
		quit(1)
		return
	if not FileAccess.file_exists(game_state.DEFAULT_PLAYTEST_REPORT_PATH):
		push_error("Rebuilt report should exist.")
		quit(1)
		return
	print("MVP 0.2 playtest report rebuilt from default save.")
	print("Report path: %s" % ProjectSettings.globalize_path(game_state.DEFAULT_PLAYTEST_REPORT_PATH))
	print("Next: godot --headless --path . -s res://tests/mvp_0_2_manual_playtest_postflight.gd")
	print("Summary path will be regenerated at: %s" % ProjectSettings.globalize_path(SUMMARY_EXPORTER.SUMMARY_PATH))
	quit(0)
