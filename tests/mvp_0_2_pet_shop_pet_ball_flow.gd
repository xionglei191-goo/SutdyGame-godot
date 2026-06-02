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

	click_game.target_clicked.emit("pet_shop")
	await process_frame
	_assert(place_card.visible, "pet shop should open a place card")
	_assert(game_state.coins == 6, "first pet shop visit should add the discovery coin")
	var action_button: Button = place_card.get_node("Panel/MarginContainer/VBoxContainer/ActionButton")
	var reward_label: Label = place_card.get_node("Panel/MarginContainer/VBoxContainer/RewardLabel")
	_assert(action_button.visible, "pet shop should offer the starter toy purchase")
	_assert(action_button.text == PlaceCardDataAssertions.action_label(town_map, "pet_shop", "buy_pet_ball"), "pet shop should offer the pet ball purchase from hotspot data")
	action_button.pressed.emit()
	await process_frame
	_assert(game_state.has_pet_ball(), "buying the pet ball should set the owned flag")
	_assert(game_state.coins == 4, "buying the pet ball should spend 2 coins after the visit bonus")
	_assert(game_state.learned_words.has("pet"), "buying the pet ball should add pet to word records")
	_assert(game_state.learned_words.has("ball"), "buying the pet ball should add ball to word records")
	_assert(game_state.learned_words.has("play"), "buying the pet ball should add play to word records")
	_assert(game_state.learned_patterns.has("Buy a pet ball."), "buying the pet ball should add a starter play pattern")
	_assert(reward_label.text == PlaceCardDataAssertions.action_success_status_text(town_map, "pet_shop", "buy_pet_ball"), "successful purchase should update the place card status from action data")
	_assert(not action_button.visible, "action button should hide after the pet ball purchase")

	var close_event := InputEventAction.new()
	close_event.action = "ui_accept"
	close_event.pressed = true
	place_card._unhandled_input(close_event)
	await process_frame
	click_game.target_clicked.emit("home")
	await process_frame
	_assert(town_map.get_active_scene() == "home", "home should stay routable after buying the pet ball")
	var pet_item_value: Label = town_map.get_node("HomeLayer/PetPanel/MarginContainer/VBoxContainer/StatsGrid/PetItemValue")
	_assert(pet_item_value.text == "Pet ball ready", "home pet panel should show the purchased pet ball")
	var play_button: Button = town_map.get_node("HomeLayer/PetPanel/MarginContainer/VBoxContainer/ActionButtons/PlayButton")
	play_button.pressed.emit()
	await process_frame
	var feedback_label: Label = town_map.get_node("HomeLayer/PetPanel/MarginContainer/VBoxContainer/FeedbackLabel")
	_assert(feedback_label.text == "Your pet had fun with the new ball.", "play feedback should mention the new ball after purchase")
	_assert(game_state.coins == 4, "playing after the ball purchase should not spend coins")

	print("mvp_0_2_pet_shop_pet_ball_flow passed.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
