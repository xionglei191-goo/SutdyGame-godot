extends SceneTree

const GUARD_REPORT_PATH := "user://mvp_0_2_incomplete_guard_report.json"


func _initialize() -> void:
	var game_state: Node = root.get_node("GameState")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GUARD_REPORT_PATH))
	game_state.reset_progress()
	game_state.start_playtest_timer(true)
	_assert(not game_state.save_playtest_report(GUARD_REPORT_PATH), "incomplete report export should be rejected")
	_assert(not FileAccess.file_exists(GUARD_REPORT_PATH), "incomplete report export should not create a file")
	game_state.reset_progress()
	print("MVP 0.2 report export guard passed.")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
