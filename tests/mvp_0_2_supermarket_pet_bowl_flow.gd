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
	_assert(town_map.get_active_scene() == "home", "new game should start at home")
	town_map.show_scene("world_overview")
	town_map.set_click_input_enabled(true)
	await process_frame

	click_game.target_clicked.emit("supermarket")
	await process_frame
	_assert(place_card.visible, "supermarket should open a place card")
	_assert(game_state.coins == 6, "first supermarket visit should add the discovery coin")
	var action_button: Button = place_card.get_node("Panel/MarginContainer/VBoxContainer/ActionButton")
	var reward_label: Label = place_card.get_node("Panel/MarginContainer/VBoxContainer/RewardLabel")
	_assert(action_button.visible, "supermarket should offer the starter pet item purchase")
	_assert(action_button.text == PlaceCardDataAssertions.action_label(town_map, "supermarket", "buy_pet_bowl"), "supermarket should offer the pet bowl purchase from hotspot data")
	action_button.pressed.emit()
	await process_frame
	_assert(game_state.has_pet_bowl(), "buying the pet bowl should set the owned flag")
	_assert(game_state.coins == 3, "buying the pet bowl should spend 3 coins after the visit bonus")
	_assert(game_state.learned_words.has("shop"), "buying the pet bowl should add shop to word records")
	_assert(game_state.learned_words.has("bowl"), "buying the pet bowl should add bowl to word records")
	_assert(game_state.learned_words.has("food"), "buying the pet bowl should add food to word records")
	_assert(game_state.learned_patterns.has("Buy a pet bowl."), "buying the pet bowl should add a starter shop pattern")
	_assert(reward_label.text == PlaceCardDataAssertions.action_success_status_text(town_map, "supermarket", "buy_pet_bowl"), "successful purchase should update the place card status from action data")
	_assert(not action_button.visible, "action button should hide after the starter purchase")

	var close_event := InputEventAction.new()
	close_event.action = "ui_accept"
	close_event.pressed = true
	place_card._unhandled_input(close_event)
	await process_frame
	click_game.target_clicked.emit("home")
	await process_frame
	_assert(town_map.get_active_scene() == "home", "home should stay routable after buying the pet bowl")
	var pet_item_value: Label = town_map.get_scene_root("home").get_node("PetPanel/MarginContainer/VBoxContainer/StatsGrid/PetItemValue")
	_assert(pet_item_value.text == "Pet bowl ready", "home pet panel should show the purchased pet bowl")
	var feed_button: Button = town_map.get_scene_root("home").get_node("PetPanel/MarginContainer/VBoxContainer/ActionButtons/FeedButton")
	feed_button.pressed.emit()
	await process_frame
	var feedback_label: Label = town_map.get_scene_root("home").get_node("PetPanel/MarginContainer/VBoxContainer/FeedbackLabel")
	_assert(feedback_label.text == "Your pet enjoyed a snack in the new bowl.", "feed feedback should mention the new bowl after purchase")
	_assert(game_state.coins == 1, "feeding after the bowl purchase should still spend 2 coins")

	print("mvp_0_2_supermarket_pet_bowl_flow passed.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
