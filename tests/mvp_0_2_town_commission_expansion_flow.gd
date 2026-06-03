extends SceneTree

const PlaceCardDataAssertions = preload("res://tests/helpers/place_card_data_assertions.gd")

const COMMISSIONS := [
	{
		"place_id": "post_office",
		"action_id": "help_carry_parcel",
		"quest_id": "town_post_office_small_parcel",
		"title": "Parcel Helper",
		"prompt": "Help carry a small parcel at the post office.",
		"reward_id": "parcel_stamp",
		"reward_name": "Parcel Stamp",
		"word": "parcel",
		"pattern": "Take the parcel."
	},
	{
		"place_id": "restaurant",
		"action_id": "help_choose_snack",
		"quest_id": "town_restaurant_snack_order",
		"title": "Snack Stop",
		"prompt": "Help choose a snack at the restaurant.",
		"reward_id": "snack_star",
		"reward_name": "Snack Star",
		"word": "snack",
		"pattern": "Choose a snack."
	},
	{
		"place_id": "cinema",
		"action_id": "help_make_poster",
		"quest_id": "town_cinema_show_poster",
		"title": "Show Poster",
		"prompt": "Help make a bright show poster at the cinema.",
		"reward_id": "poster_spark",
		"reward_name": "Poster Spark",
		"word": "poster",
		"pattern": "Put up the poster."
	}
]


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
	var action_button: Button = place_card.get_node("Panel/MarginContainer/VBoxContainer/ActionButton")
	var reward_label: Label = place_card.get_node("Panel/MarginContainer/VBoxContainer/RewardLabel")
	var close_event := InputEventAction.new()
	close_event.action = "ui_accept"
	close_event.pressed = true

	town_map.show_scene("world_overview")
	town_map.set_click_input_enabled(true)
	await process_frame

	var expected_coins: int = game_state.coins
	for commission: Dictionary in COMMISSIONS:
		await _run_commission(
			commission,
			game_state,
			town_map,
			click_game,
			place_card,
			quest_diary,
			reward_popup,
			action_button,
			reward_label,
			close_event,
			expected_coins
		)
		expected_coins += 2

	print("mvp_0_2_town_commission_expansion_flow passed.")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))
	quit(0)


func _run_commission(
	commission: Dictionary,
	game_state: Node,
	town_map: Node,
	click_game: Node,
	place_card: CanvasLayer,
	quest_diary: CanvasLayer,
	reward_popup: CanvasLayer,
	action_button: Button,
	reward_label: Label,
	close_event: InputEvent,
	expected_starting_coins: int
) -> void:
	var place_id := str(commission.get("place_id", ""))
	var action_id := str(commission.get("action_id", ""))
	var quest_id := str(commission.get("quest_id", ""))

	town_map.set_click_input_enabled(true)
	click_game.target_clicked.emit(place_id)
	await process_frame
	_assert(place_card.visible, "%s should open a PlaceCard" % place_id)
	_assert(game_state.coins == expected_starting_coins + 1, "%s first visit should add a discovery coin" % place_id)
	_assert(action_button.visible, "%s should show its commission action" % place_id)
	_assert(action_button.text == PlaceCardDataAssertions.action_label(town_map, place_id, action_id), "%s action label should come from hotspot data" % place_id)
	_assert(PlaceCardDataAssertions.action_visible_when(town_map, place_id, action_id) == "quest_not_completed:%s" % quest_id, "%s action visibility should point to the quest" % place_id)

	action_button.pressed.emit()
	await process_frame
	_assert(not place_card.visible, "%s action should hide the PlaceCard before Quest Diary starts" % place_id)
	_assert(quest_diary.active, "%s action should start Quest Diary" % place_id)
	_assert(quest_diary.quest_id == quest_id, "%s should start the configured quest" % place_id)
	_assert(quest_diary.event_label.text == str(commission.get("title", "")), "%s quest should show its child-facing title" % place_id)
	_assert(quest_diary.prompt_label.text == str(commission.get("prompt", "")), "%s quest should show its child-facing prompt" % place_id)
	_assert(quest_diary.reward_label.text == "Keepsake: %s" % str(commission.get("reward_name", "")), "%s quest should show its keepsake" % place_id)

	click_game.target_clicked.emit("bookshop")
	await process_frame
	_assert(quest_diary.active, "%s wrong target should not complete the commission" % place_id)
	_assert(quest_diary.status_label.text == "Look again", "%s wrong target should show retry status" % place_id)
	click_game.target_clicked.emit(place_id)
	await process_frame
	_assert(not quest_diary.active, "%s target should complete the commission" % place_id)
	_assert(game_state.has_completed_quest(quest_id), "%s quest should be saved as completed" % place_id)
	_assert(game_state.has_story_flag("%s_done" % quest_id), "%s quest should write its completion story flag" % place_id)
	_assert(game_state.rewards.has(str(commission.get("reward_id", ""))), "%s quest should add its keepsake" % place_id)
	_assert(game_state.learned_words.has(str(commission.get("word", ""))), "%s quest should add its themed word" % place_id)
	_assert(game_state.learned_patterns.has(str(commission.get("pattern", ""))), "%s quest should add its themed pattern" % place_id)
	_assert(game_state.coins == expected_starting_coins + 2, "%s commission should add one quest coin after the discovery coin" % place_id)
	_assert(reward_popup.visible, "%s commission should show a keepsake popup" % place_id)
	_assert(town_map.get_world_overview_camera_rect().has_point(click_game.get_hotspot_rect(place_id).get_center()), "%s completion should focus the place hotspot" % place_id)

	reward_popup._unhandled_input(close_event)
	await process_frame
	town_map.set_click_input_enabled(true)
	click_game.target_clicked.emit(place_id)
	await process_frame
	_assert(place_card.visible, "%s revisit should still open a PlaceCard" % place_id)
	_assert(not action_button.visible, "%s completed commission should hide its action" % place_id)
	_assert(reward_label.text == "Already visited", "%s revisit should not repeat the discovery reward" % place_id)
	place_card._unhandled_input(close_event)
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
