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
	var starting_coins: int = game_state.coins
	_assert(town_map.get_active_scene() == "home", "new game should start at home")
	town_map.show_scene("world_overview")
	town_map.set_click_input_enabled(true)
	await process_frame
	_assert(not place_card.visible, "place card should start hidden")

	click_game.target_clicked.emit("bookshop")
	await process_frame
	_assert(place_card.visible, "bookshop should open a place card in free explore")
	_assert(game_state.coins == starting_coins + 1, "first place visit should grant 1 coin")
	_assert(not bool(click_game.input_enabled), "place card should disable world click input while open")
	var blocker: Control = place_card.get_node("Blocker")
	_assert(blocker.mouse_filter == Control.MOUSE_FILTER_STOP, "place card should block background pointer input")
	var title_label: Label = place_card.get_node("Panel/MarginContainer/VBoxContainer/TitleLabel")
	var place_label: Label = place_card.get_node("Panel/MarginContainer/VBoxContainer/PlaceLabel")
	var reward_label: Label = place_card.get_node("Panel/MarginContainer/VBoxContainer/RewardLabel")
	var action_button: Button = place_card.get_node("Panel/MarginContainer/VBoxContainer/ActionButton")
	_assert(title_label.text == "Helper Stop", "bookshop commission card should use the helper stop title")
	_assert(place_label.text == "bookshop", "place card should show hotspot label")
	_assert(reward_label.text == "+1 coin", "first visit should show a coin reward")
	_assert(action_button.visible, "bookshop should expose the starter commission action")
	_assert(action_button.text == PlaceCardDataAssertions.action_label(town_map, "bookshop", "help_find_book"), "bookshop should offer the story book commission from hotspot data")

	var close_event := InputEventAction.new()
	close_event.action = "ui_accept"
	close_event.pressed = true
	place_card._unhandled_input(close_event)
	await process_frame
	_assert(not place_card.visible, "accept input should close the place card")

	click_game.target_clicked.emit("bookshop")
	await process_frame
	_assert(place_card.visible, "revisit should still open the place card")
	_assert(game_state.coins == starting_coins + 1, "repeat visits should not award extra coins")
	_assert(reward_label.text == "Already visited", "revisit should show already-visited state")
	_assert(action_button.visible, "bookshop should still offer the commission until it is complete")
	place_card._unhandled_input(close_event)
	await process_frame
	_assert(not place_card.visible, "place card should close again on revisit")
	click_game.target_clicked.emit("supermarket")
	await process_frame
	_assert(title_label.text == "Shop Stop", "supermarket purchase card should use the shop stop title")
	_assert(action_button.visible, "supermarket should expose a starter purchase action")
	place_card._unhandled_input(close_event)
	await process_frame

	print("mvp_0_2_place_card_visit_flow passed.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
