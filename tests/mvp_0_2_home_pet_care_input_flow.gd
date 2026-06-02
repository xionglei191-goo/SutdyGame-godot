extends SceneTree

const PlaceCardDataAssertions = preload("res://tests/helpers/place_card_data_assertions.gd")


func _initialize() -> void:
	var game_state: Node = root.get_node("GameState")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))
	game_state.reset_progress()
	game_state.start_playtest_timer(true)
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	await process_frame

	var town_map: Node = main.get_node("TownMap")
	var quest_diary: CanvasLayer = main.get_node("QuestDiary")
	_assert(town_map.get_active_scene() == "home", "new game should start at home")
	var feed_button: Button = town_map.get_node("HomeLayer/PetPanel/MarginContainer/VBoxContainer/ActionButtons/FeedButton")
	var clean_button: Button = town_map.get_node("HomeLayer/PetPanel/MarginContainer/VBoxContainer/ActionButtons/CleanButton")
	var play_button: Button = town_map.get_node("HomeLayer/PetPanel/MarginContainer/VBoxContainer/ActionButtons/PlayButton")
	var rest_button: Button = town_map.get_node("HomeLayer/PetPanel/MarginContainer/VBoxContainer/ActionButtons/RestButton")
	var pet_name_value: Label = town_map.get_node("HomeLayer/PetPanel/MarginContainer/VBoxContainer/StatsGrid/PetNameValue")
	var pet_corner_label: Label = town_map.get_node("HomeLayer/PetCorner/PetCornerLabel")
	_assert(pet_name_value.text == "Sunny", "home pet panel should show the starter pet name")
	_assert(pet_corner_label.text == "Sunny's corner", "home should show a visible pet corner")
	var starting_coins: int = game_state.coins
	feed_button.pressed.emit()
	await process_frame
	_assert(game_state.coins == starting_coins - 2, "feed should spend 2 coins")
	_assert(int(game_state.get_pet_state().get("hunger", -1)) == 84, "feed should raise hunger")
	var saved_snapshot: String = FileAccess.get_file_as_string(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))
	var saved_data: Variant = JSON.parse_string(saved_snapshot)
	_assert(typeof(saved_data) == TYPE_DICTIONARY, "pet care action should save a valid JSON snapshot")
	_assert(int(saved_data.get("coins", -1)) == game_state.coins, "pet care action should save updated coins immediately")
	var saved_pet_state: Dictionary = saved_data.get("pet_state", {})
	_assert(int(saved_pet_state.get("hunger", -1)) == 84, "pet care action should save updated pet hunger immediately")
	clean_button.pressed.emit()
	play_button.pressed.emit()
	rest_button.pressed.emit()
	await process_frame
	_assert(game_state.coins == starting_coins - 2, "clean/play should not spend coins")
	_assert(int(game_state.get_pet_state().get("cleanliness", -1)) >= 82, "clean should raise cleanliness")
	_assert(int(game_state.get_pet_state().get("mood", -1)) >= 92, "play should raise mood")
	_assert(int(game_state.get_pet_state().get("bond", -1)) >= 16, "rest should add one more bond point")
	var return_button: Button = town_map.get_node("HomeLayer/ReturnButton")
	return_button.pressed.emit()
	await process_frame
	_assert(town_map.get_active_scene() == "world_overview", "return button should go back to world overview")
	var place_card: CanvasLayer = main.get_node("PlaceCard")
	var place_click_game: Node = town_map.get_node("ClickGame")
	place_click_game.target_clicked.emit("bookshop")
	await process_frame
	_assert(place_card.visible, "non-school place click should open a place card")
	_assert(game_state.coins == 4, "first place visit should grant 1 coin")
	var close_event := InputEventAction.new()
	close_event.action = "ui_accept"
	close_event.pressed = true
	place_card._unhandled_input(close_event)
	await process_frame
	var mina: Area2D = town_map.get_node("NpcLayer/Mina")
	place_click_game.target_clicked.emit("home")
	await process_frame
	_assert(town_map.get_active_scene() == "home", "home click should route back to home before Welcome Box")
	mina.interaction_requested.emit("mina_letter_box_intro")
	await process_frame
	var dialogue_box: CanvasLayer = main.get_node("DialogueBox")
	dialogue_box._finish()
	await process_frame
	_assert(quest_diary.active, "Welcome Box intro should start the starter quest")
	_assert(quest_diary.quest_id == "prologue_letter_box", "Welcome Box should come before First Trip")
	_assert(quest_diary.event_label.text == "Welcome Box", "Quest Diary should show the Welcome Box event")
	_assert(quest_diary.prompt_label.text == "Open Mina's welcome box.", "Welcome Box should use the starter prompt")
	quest_diary.check_target("home_letter_box")
	await process_frame
	_assert(game_state.has_completed_quest("prologue_letter_box"), "Welcome Box completion should be saved")
	mina.interaction_requested.emit("mina_home_intro")
	await process_frame
	dialogue_box._finish()
	await process_frame
	_assert(quest_diary.active, "home intro should still start First Trip after Welcome Box")
	_assert(quest_diary.quest_id == "prologue_go_to_school", "home intro should still hand off to First Trip")
	quest_diary.dismiss()
	town_map.show_scene("world_overview")
	town_map.set_click_input_enabled(true)
	town_map.set_quest_active(false)
	await process_frame
	var coins_before_supermarket: int = game_state.coins
	place_click_game.target_clicked.emit("supermarket")
	await process_frame
	_assert(place_card.visible, "supermarket should open a place card")
	_assert(game_state.coins == coins_before_supermarket + 1, "first supermarket visit should grant 1 coin")
	var action_button: Button = place_card.get_node("Panel/MarginContainer/VBoxContainer/ActionButton")
	_assert(action_button.visible, "supermarket place card should offer starter pet purchase")
	action_button.pressed.emit()
	await process_frame
	_assert(game_state.has_pet_bowl(), "buying from supermarket should unlock the pet bowl")
	_assert(game_state.coins == coins_before_supermarket - 2, "buying the pet bowl should spend 3 coins after first-visit reward")
	var reward_label: Label = place_card.get_node("Panel/MarginContainer/VBoxContainer/RewardLabel")
	_assert(reward_label.text == PlaceCardDataAssertions.action_success_status_text(town_map, "supermarket", "buy_pet_bowl"), "successful supermarket purchase should update place card status from action data")
	place_card._unhandled_input(close_event)
	await process_frame
	place_click_game.target_clicked.emit("home")
	await process_frame
	_assert(town_map.get_active_scene() == "home", "home should stay accessible after school-tour-compatible progress begins")
	var pet_item_value: Label = town_map.get_node("HomeLayer/PetPanel/MarginContainer/VBoxContainer/StatsGrid/PetItemValue")
	_assert(pet_item_value.text == "Pet bowl ready", "home pet panel should reflect the purchased pet bowl")
	print("mvp_0_2_home_pet_care_input_flow passed.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))
	quit(0)


func click_home(town_map: Node) -> void:
	var click_game: Node = town_map.get_node("ClickGame")
	click_game.target_clicked.emit("home")


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
