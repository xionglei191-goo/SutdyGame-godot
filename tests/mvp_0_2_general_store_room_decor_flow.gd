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

	var town_map: Node = main.get_node("TownMap")
	var click_game: Node = town_map.get_node("ClickGame")
	var place_card: CanvasLayer = main.get_node("PlaceCard")
	_assert(town_map.get_active_scene() == "home", "new game should start at home")
	town_map.show_scene("world_overview")
	town_map.set_click_input_enabled(true)
	await process_frame

	click_game.target_clicked.emit("general_store")
	await process_frame
	_assert(place_card.visible, "general store should open a place card")
	_assert(game_state.coins == 6, "first general store visit should add the discovery coin")
	var action_button: Button = place_card.get_node("Panel/MarginContainer/VBoxContainer/ActionButton")
	var reward_label: Label = place_card.get_node("Panel/MarginContainer/VBoxContainer/RewardLabel")
	_assert(action_button.visible, "general store should offer the starter room decor purchase")
	_assert(action_button.text == PlaceCardDataAssertions.action_label(town_map, "general_store", "buy_star_rug"), "general store should price the star rug from hotspot data")
	action_button.pressed.emit()
	await process_frame
	_assert(game_state.has_star_rug(), "buying the star rug should set the owned flag")
	_assert(game_state.coins == 2, "buying the star rug should spend 4 coins after first-visit reward")
	_assert(game_state.parent_bonus == 0, "buying the star rug should not spend Parent Bonus")
	_assert(game_state.learned_words.has("room"), "buying the star rug should add room to word records")
	_assert(game_state.learned_words.has("rug"), "buying the star rug should add rug to word records")
	_assert(game_state.learned_words.has("star"), "buying the star rug should add star to word records")
	_assert(game_state.learned_patterns.has("Put the star rug in your room."), "buying the star rug should add a room decor pattern")
	_assert(reward_label.text == PlaceCardDataAssertions.action_success_status_text(town_map, "general_store", "buy_star_rug"), "successful star rug purchase should update the place card status from action data")
	_assert(not action_button.visible, "action button should hide after the star rug purchase")

	var close_event := InputEventAction.new()
	close_event.action = "ui_accept"
	close_event.pressed = true
	place_card._unhandled_input(close_event)
	await process_frame
	click_game.target_clicked.emit("home")
	await process_frame
	_assert(town_map.get_active_scene() == "home", "home should stay routable after buying room decor")
	var pet_item_value: Label = town_map.get_node("HomeLayer/PetPanel/MarginContainer/VBoxContainer/StatsGrid/PetItemValue")
	var outfit_value: Label = town_map.get_node("HomeLayer/PetPanel/MarginContainer/VBoxContainer/StatsGrid/OutfitValue")
	var room_decor_value: Label = town_map.get_node("HomeLayer/PetPanel/MarginContainer/VBoxContainer/StatsGrid/RoomDecorValue")
	_assert(pet_item_value.text != "Star rug ready", "star rug should not pollute pet item status")
	_assert(outfit_value.text != "Star rug ready", "star rug should not pollute outfit status")
	_assert(room_decor_value.text == "Star rug ready", "home room decor status should show the purchased star rug")

	var save_path := "user://mvp_0_2_general_store_save.json"
	_assert(game_state.save_game(save_path), "general store save should succeed")
	game_state.reset_progress()
	_assert(game_state.load_game(save_path), "general store load should succeed")
	_assert(game_state.has_star_rug(), "load should restore star rug ownership")
	_assert(game_state.coins == 2, "load should restore coins after the star rug purchase")
	_assert(game_state.parent_bonus == 0, "load should keep Parent Bonus separate from room decor")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))

	print("mvp_0_2_general_store_room_decor_flow passed.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
