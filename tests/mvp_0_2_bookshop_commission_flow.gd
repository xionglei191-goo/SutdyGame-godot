extends SceneTree

const PlaceCardDataAssertions = preload("res://tests/helpers/place_card_data_assertions.gd")


func _initialize() -> void:
	var game_state: Node = root.get_node("GameState")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))
	game_state.reset_progress()
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	await process_frame

	var town_map: Node = main.get_node("SceneHost")
	var click_game: Node = town_map.get_click_game()
	var place_card: CanvasLayer = main.get_node("PlaceCard")
	var quest_diary: CanvasLayer = main.get_node("QuestDiary")
	var reward_popup: CanvasLayer = main.get_node("RewardPopup")
	_assert(town_map.get_active_scene() == "home", "new game should start at home")
	town_map.show_scene("world_overview")
	town_map.set_click_input_enabled(true)
	await process_frame

	click_game.target_clicked.emit("bookshop")
	await process_frame
	_assert(place_card.visible, "bookshop should open a place card")
	_assert(game_state.coins == 6, "first bookshop visit should add the discovery coin")
	var action_button: Button = place_card.get_node("Panel/MarginContainer/VBoxContainer/ActionButton")
	var reward_label: Label = place_card.get_node("Panel/MarginContainer/VBoxContainer/RewardLabel")
	_assert(action_button.visible, "bookshop should offer the commission action")
	_assert(action_button.text == PlaceCardDataAssertions.action_label(town_map, "bookshop", "help_find_book"), "bookshop should expose the helper action from hotspot data")
	action_button.pressed.emit()
	await process_frame
	_assert(not place_card.visible, "starting the commission should hide the place card")
	_assert(quest_diary.active, "bookshop action should start Quest Diary")
	_assert(quest_diary.quest_id == "town_bookshop_find_book", "bookshop commission should use its quest id")
	_assert(quest_diary.event_label.text == "Bookshop Helper", "bookshop commission should use child-facing event name")
	_assert(quest_diary.prompt_label.text == "Help the reading bear find a book.", "bookshop commission should use adventure wording")
	_assert(quest_diary.reward_label.text == "Keepsake: Bookshop Leafmark", "bookshop commission should show its keepsake")
	_assert(town_map.get_active_scene() == "world_overview", "bookshop commission should stay on world overview")

	click_game.target_clicked.emit("restaurant")
	await process_frame
	_assert(quest_diary.active, "wrong town target should not complete the bookshop commission")
	_assert(quest_diary.status_label.text == "Look again", "wrong town target should show retry status")
	click_game.target_clicked.emit("bookshop")
	await process_frame
	_assert(not quest_diary.active, "bookshop target should complete the commission")
	_assert(game_state.has_completed_quest("town_bookshop_find_book"), "bookshop commission should be recorded as completed")
	_assert(game_state.learned_words.has("bookshop"), "bookshop commission should add bookshop to word records")
	_assert(game_state.learned_words.has("book"), "bookshop commission should add book to word records")
	_assert(game_state.learned_words.has("read"), "bookshop commission should add read to word records")
	_assert(game_state.learned_patterns.has("Find a book."), "bookshop commission should add a find-book pattern")
	_assert(game_state.learned_patterns.has("Read at the bookshop."), "bookshop commission should add a read pattern")
	_assert(game_state.coins == 7, "bookshop commission should add one quest coin after the visit bonus")
	_assert(reward_popup.visible, "bookshop commission should show a keepsake popup")
	_assert(game_state.rewards.has("bookshop_leafmark"), "bookshop commission should add its keepsake")
	_assert(town_map.get_active_scene() == "world_overview", "bookshop commission should return to world overview")

	var close_event := InputEventAction.new()
	close_event.action = "ui_accept"
	close_event.pressed = true
	reward_popup._unhandled_input(close_event)
	await process_frame
	town_map.set_click_input_enabled(true)
	click_game.target_clicked.emit("bookshop")
	await process_frame
	_assert(place_card.visible, "bookshop revisit should still open a place card")
	_assert(not action_button.visible, "completed bookshop commission should not expose the action again")
	_assert(reward_label.text == "Already visited", "bookshop revisit should keep already-visited status")

	quest_diary.dismiss()
	town_map.show_scene("world_overview")
	var bookshop_rect: Rect2 = click_game.get_hotspot_rect("bookshop")
	var player: CharacterBody2D = town_map.get_node("Player")
	player.position = Vector2.ZERO
	quest_diary.start_quest("town_bookshop_find_book")
	await process_frame
	_assert(town_map.get_active_scene() == "world_overview", "direct bookshop quest should start in scene_id from quest data")
	_assert(bookshop_rect.has_point(player.position), "direct bookshop quest should focus start_focus_hotspot from quest data")

	print("mvp_0_2_bookshop_commission_flow passed.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
