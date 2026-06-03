extends SceneTree


func _initialize() -> void:
	var game_state: Node = root.get_node("GameState")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))
	game_state.reset_progress()
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	await process_frame

	var town_map: Node = main.get_node("TownMap")
	var click_game: Node = town_map.get_node("ClickGame")
	var quest_diary: CanvasLayer = main.get_node("QuestDiary")
	var reward_popup: CanvasLayer = main.get_node("RewardPopup")
	var room_button: Button = town_map.get_node("HomeLayer/RoomExploreButton")
	var room_panel: Panel = town_map.get_node("HomeLayer/RoomExplorePanel")
	var room_light_button: Button = town_map.get_node("HomeLayer/RoomExplorePanel/MarginContainer/VBoxContainer/RoomLightButton")
	var window_watch_button: Button = town_map.get_node("HomeLayer/RoomExplorePanel/MarginContainer/VBoxContainer/WindowWatchButton")
	var close_event := InputEventAction.new()
	close_event.action = "ui_accept"
	close_event.pressed = true

	var home_rects: Dictionary = click_game.get_place_rects_for_scene("home")
	for target_id in ["home_lamp", "home_clock", "home_window"]:
		_assert(home_rects.has(target_id), "home room target should come from scene_click_targets data: %s" % target_id)
	for node_path in [
		"HomeLayer/HomeSpaces/HomeLampProp",
		"HomeLayer/HomeSpaces/HomeClockProp",
		"HomeLayer/HomeSpaces/HomeWindowProp"
	]:
		var sprite: Sprite2D = town_map.get_node(node_path)
		_assert(sprite.texture != null, "%s should use generated room prop art" % node_path)

	_assert(room_button.visible, "Room Finds button should be visible at home")
	room_button.pressed.emit()
	await process_frame
	_assert(room_panel.visible, "Room Finds panel should open")
	var starting_coins: int = game_state.coins
	room_light_button.pressed.emit()
	await process_frame
	_assert(quest_diary.active, "Room Light should start Quest Diary")
	_assert(quest_diary.quest_id == "home_room_explore_a", "Room Light should start the configured quest")
	click_game.target_clicked.emit("home_clock")
	await process_frame
	_assert(quest_diary.active, "wrong room target should not complete Room Light")
	_assert(quest_diary.status_label.text == "Look again", "wrong room target should show retry status")
	click_game.target_clicked.emit("home_lamp")
	await process_frame
	_assert(game_state.has_completed_quest("home_room_explore_a"), "Room Light should complete")
	_assert(game_state.coins == starting_coins + 1, "Room Light should give its first coin once")
	_assert(game_state.has_story_flag("home_room_explore_a_reward_claimed"), "Room Light should mark its one-time reward flag")
	_assert(reward_popup.visible, "Room Light should show a keepsake popup")
	reward_popup._unhandled_input(close_event)
	await process_frame

	room_button.pressed.emit()
	await process_frame
	room_light_button.pressed.emit()
	await process_frame
	click_game.target_clicked.emit("home_lamp")
	await process_frame
	_assert(game_state.coins == starting_coins + 1, "Room Light repeat should not give another coin")
	reward_popup._unhandled_input(close_event)
	await process_frame

	room_button.pressed.emit()
	await process_frame
	window_watch_button.pressed.emit()
	await process_frame
	_assert(quest_diary.active, "Window Watch should start Quest Diary")
	_assert(quest_diary.quest_id == "home_room_explore_b", "Window Watch should start the configured quest")
	click_game.target_clicked.emit("home_window")
	await process_frame
	_assert(game_state.has_completed_quest("home_room_explore_b"), "Window Watch should complete")
	_assert(game_state.coins == starting_coins + 2, "Window Watch should give its first coin once")

	print("mvp_home_room_explore_flow passed.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
