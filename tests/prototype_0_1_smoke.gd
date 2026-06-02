extends SceneTree


func _initialize() -> void:
	var game_state: Node = root.get_node("GameState")
	game_state.reset()

	var quest_diary_scene: PackedScene = load("res://scenes/ui/QuestDiary.tscn")
	var quest_diary: CanvasLayer = quest_diary_scene.instantiate()
	root.add_child(quest_diary)
	await process_frame

	quest_diary.start_quest()
	quest_diary.check_target("classroom")
	quest_diary.check_target("library")

	var snapshot: Dictionary = game_state.debug_snapshot()
	_assert_contains(snapshot["completed_quests"], "g4_u1_school_tour", "completed quest")
	_assert_contains(snapshot["learned_words"], "classroom", "word record classroom")
	_assert_contains(snapshot["learned_words"], "library", "word record library")
	_assert_contains(snapshot["learned_words"], "playground", "word record playground")

	game_state.start_playtest_timer(true)
	await create_timer(0.05).timeout
	game_state.record_playtest_event("prototype_checkpoint", "原型检查点")
	game_state.finish_playtest_timer()
	snapshot = game_state.debug_snapshot()
	if int(snapshot["playtest_elapsed_msec"]) <= 0:
		push_error("Playtest timer should record elapsed time.")
		quit(1)
	if not bool(snapshot["playtest_completed"]):
		push_error("Playtest timer should mark completion.")
		quit(1)
	if not _has_event(snapshot["playtest_events"], "prototype_checkpoint"):
		push_error("Playtest events should include checkpoint.")
		quit(1)

	var reward_popup_scene: PackedScene = load("res://scenes/ui/RewardPopup.tscn")
	var reward_popup: CanvasLayer = reward_popup_scene.instantiate()
	root.add_child(reward_popup)
	await process_frame
	reward_popup.show_reward("school_star_piece", "Adventure Star")
	_assert_contains(game_state.rewards, "school_star_piece", "reward")

	var save_path: String = "user://prototype_0_1_smoke_save.json"
	if not game_state.save_game(save_path):
		push_error("Save failed.")
		quit(1)
	game_state.reset()
	if not game_state.get_completed_quests().is_empty():
		push_error("Reset failed.")
		quit(1)
	if not game_state.load_game(save_path):
		push_error("Load failed.")
		quit(1)
	_assert_contains(game_state.get_completed_quests(), "g4_u1_school_tour", "loaded completed quest")
	_assert_contains(game_state.rewards, "school_star_piece", "loaded reward")
	_assert_contains(game_state.learned_words, "library", "loaded word record")
	if not game_state.playtest_completed:
		push_error("Loaded save should restore playtest completion.")
		quit(1)
	if game_state.get_playtest_elapsed_msec() <= 0:
		push_error("Loaded save should restore playtest elapsed time.")
		quit(1)
	if not _has_event(game_state.playtest_events, "prototype_checkpoint"):
		push_error("Loaded save should restore playtest events.")
		quit(1)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))

	var parent_summary_scene: PackedScene = load("res://scenes/ui/ParentSummary.tscn")
	var parent_summary: CanvasLayer = parent_summary_scene.instantiate()
	root.add_child(parent_summary)
	await process_frame
	parent_summary.refresh()
	var completed_value: Label = parent_summary.get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/StatsGrid/CompletedValue")
	if completed_value.text != "1":
		push_error("Parent summary completed count mismatch: %s" % completed_value.text)
		quit(1)

	print("Prototype 0.1 smoke test passed.")
	quit(0)


func _assert_contains(values: Array, expected: String, label: String) -> void:
	if not values.has(expected):
		push_error("Missing %s: %s" % [label, expected])
		quit(1)


func _has_event(events: Array, event_id: String) -> bool:
	for event: Variant in events:
		if typeof(event) == TYPE_DICTIONARY and str(event.get("id", "")) == event_id:
			return true
	return false
