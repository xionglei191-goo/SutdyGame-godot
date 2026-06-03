extends SceneTree

const PlaceCardDataAssertions = preload("res://tests/helpers/place_card_data_assertions.gd")

const COMMISSIONS := [
	{
		"place_id": "hospital",
		"action_id": "help_with_bandage",
		"dialogue_id": "mina_hospital_bandage_intro",
		"quest_id": "town_hospital_bandage_helper",
		"title": "Bandage Helper",
		"prompt": "Help Mina bring a clean bandage at the hospital.",
		"reward_id": "bandage_care_badge",
		"reward_name": "Bandage Care Badge",
		"discovery_coin": true,
		"words": ["hospital", "hello", "help", "bandage"],
		"patterns": ["Hello, can I help?", "Use a clean bandage."]
	},
	{
		"place_id": "airport",
		"action_id": "check_travel_weather",
		"dialogue_id": "mina_airport_weather_intro",
		"quest_id": "town_airport_weather_check",
		"title": "Weather Sticker",
		"prompt": "Help check the travel weather at the airport.",
		"reward_id": "weather_sticker",
		"reward_name": "Weather Sticker",
		"discovery_coin": true,
		"words": ["airport", "travel", "weather", "sunny"],
		"patterns": ["How is the weather?", "It is sunny today."]
	},
	{
		"place_id": "railway_station",
		"action_id": "check_train_time",
		"dialogue_id": "mina_railway_time_intro",
		"quest_id": "town_railway_time_stop",
		"title": "Time Stop",
		"prompt": "Help check the train time at the railway station.",
		"reward_id": "train_time_ticket",
		"reward_name": "Train Time Ticket",
		"discovery_coin": false,
		"words": ["railway", "train", "time", "stop"],
		"patterns": ["What time is it?", "The train stops here."]
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

	var town_map: Node = main.get_node("TownMap")
	var click_game: Node = town_map.get_node("ClickGame")
	var place_card: CanvasLayer = main.get_node("PlaceCard")
	var dialogue_box: CanvasLayer = main.get_node("DialogueBox")
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
		if str(commission.get("place_id", "")) == "railway_station":
			await _prepare_railway_time_action(game_state, town_map, click_game, place_card, action_button, reward_label, close_event)
			expected_coins = game_state.coins
		await _run_commission(
			commission,
			game_state,
			town_map,
			click_game,
			place_card,
			dialogue_box,
			quest_diary,
			reward_popup,
			action_button,
			reward_label,
			close_event,
			expected_coins
		)
		expected_coins += 2 if bool(commission.get("discovery_coin", true)) else 1

	print("mvp_town_chapter1_flow passed.")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))
	quit(0)


func _prepare_railway_time_action(
	game_state: Node,
	town_map: Node,
	click_game: Node,
	place_card: CanvasLayer,
	action_button: Button,
	reward_label: Label,
	close_event: InputEvent
) -> void:
	town_map.set_click_input_enabled(true)
	click_game.target_clicked.emit("railway_station")
	await process_frame
	_assert(place_card.visible, "railway station should open before the time helper")
	_assert(action_button.visible, "railway station should first expose the route action")
	_assert(action_button.text == PlaceCardDataAssertions.action_label(town_map, "railway_station", "choose_train_stop"), "railway route action should stay first until marked")
	action_button.pressed.emit()
	await process_frame
	_assert(game_state.has_train_stop(), "railway route action should mark the train stop before time helper appears")
	_assert(reward_label.text == PlaceCardDataAssertions.action_success_status_text(town_map, "railway_station", "choose_train_stop"), "railway route action should show its success text")
	_assert(action_button.visible, "railway station should expose the time helper after the route is marked")
	_assert(action_button.text == PlaceCardDataAssertions.action_label(town_map, "railway_station", "check_train_time"), "railway station should advance to the time helper action")
	place_card._unhandled_input(close_event)
	await process_frame


func _run_commission(
	commission: Dictionary,
	game_state: Node,
	town_map: Node,
	click_game: Node,
	place_card: CanvasLayer,
	dialogue_box: CanvasLayer,
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
	var dialogue_id := str(commission.get("dialogue_id", ""))

	town_map.set_click_input_enabled(true)
	click_game.target_clicked.emit(place_id)
	await process_frame
	_assert(place_card.visible, "%s should open a PlaceCard" % place_id)
	var discovery_coin := bool(commission.get("discovery_coin", true))
	var expected_after_open := expected_starting_coins + (1 if discovery_coin else 0)
	_assert(game_state.coins == expected_after_open, "%s visit reward should match discovery state" % place_id)
	_assert(action_button.visible, "%s should show its Chapter 1 action" % place_id)
	_assert(action_button.text == PlaceCardDataAssertions.action_label(town_map, place_id, action_id), "%s action label should come from hotspot data" % place_id)
	_assert(PlaceCardDataAssertions.action_visible_when(town_map, place_id, action_id) == "quest_not_completed:%s" % quest_id, "%s action visibility should point to the quest" % place_id)
	_assert(str(PlaceCardDataAssertions.action_data(town_map, place_id, action_id).get("start_dialogue_id", "")) == dialogue_id, "%s action should declare the start dialogue" % place_id)

	action_button.pressed.emit()
	await process_frame
	await _finish_dialogue_if_visible(dialogue_box, close_event)
	_assert(not place_card.visible, "%s action should hide the PlaceCard before Quest Diary starts" % place_id)
	_assert(quest_diary.active, "%s action should start Quest Diary" % place_id)
	_assert(quest_diary.quest_id == quest_id, "%s should start the configured quest" % place_id)
	_assert(quest_diary.event_label.text == str(commission.get("title", "")), "%s quest should show its child-facing title" % place_id)
	_assert(quest_diary.prompt_label.text == str(commission.get("prompt", "")), "%s quest should show its child-facing prompt" % place_id)
	_assert(quest_diary.reward_label.text == "Keepsake: %s" % str(commission.get("reward_name", "")), "%s quest should show its keepsake" % place_id)

	click_game.target_clicked.emit("bookshop")
	await process_frame
	_assert(quest_diary.active, "%s wrong town target should not complete the quest" % place_id)
	_assert(quest_diary.status_label.text == "Look again", "%s wrong target should show retry status" % place_id)
	click_game.target_clicked.emit(place_id)
	await process_frame
	_assert(not quest_diary.active, "%s target should complete the quest" % place_id)
	_assert(game_state.has_completed_quest(quest_id), "%s quest should be saved as completed" % place_id)
	_assert(game_state.has_story_flag("%s_done" % quest_id), "%s quest should write its completion story flag" % place_id)
	_assert(game_state.rewards.has(str(commission.get("reward_id", ""))), "%s quest should add its keepsake" % place_id)
	for word_value: Variant in commission.get("words", []):
		_assert(game_state.learned_words.has(str(word_value)), "%s quest should add word: %s" % [place_id, word_value])
	for pattern_value: Variant in commission.get("patterns", []):
		_assert(game_state.learned_patterns.has(str(pattern_value)), "%s quest should add pattern: %s" % [place_id, pattern_value])
	_assert(game_state.coins == expected_after_open + 1, "%s quest should add one quest coin after the visit state" % place_id)
	_assert(reward_popup.visible, "%s quest should show a keepsake popup" % place_id)
	_assert(town_map.get_world_overview_camera_rect().has_point(click_game.get_hotspot_rect(place_id).get_center()), "%s completion should focus the place hotspot" % place_id)

	reward_popup._unhandled_input(close_event)
	await process_frame
	town_map.set_click_input_enabled(true)
	click_game.target_clicked.emit(place_id)
	await process_frame
	_assert(place_card.visible, "%s revisit should still open a PlaceCard" % place_id)
	_assert(not action_button.visible, "%s completed quest should hide its action" % place_id)
	_assert(reward_label.text == "Already visited", "%s revisit should not repeat the discovery reward" % place_id)
	place_card._unhandled_input(close_event)
	await process_frame


func _finish_dialogue_if_visible(dialogue_box: CanvasLayer, close_event: InputEvent) -> void:
	var safety := 8
	while dialogue_box.visible and safety > 0:
		dialogue_box._unhandled_input(close_event)
		await process_frame
		safety -= 1


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
