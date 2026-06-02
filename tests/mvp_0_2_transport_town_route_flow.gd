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

	click_game.target_clicked.emit("bus_station")
	await process_frame
	_assert(place_card.visible, "bus station should open a place card")
	_assert(game_state.coins == 6, "first bus station visit should add the discovery coin")
	var action_button: Button = place_card.get_node("Panel/MarginContainer/VBoxContainer/ActionButton")
	var reward_label: Label = place_card.get_node("Panel/MarginContainer/VBoxContainer/RewardLabel")
	_assert(action_button.visible, "bus station should offer a route choice")
	_assert(action_button.text == PlaceCardDataAssertions.action_label(town_map, "bus_station", "choose_town_route"), "bus station should expose the town route action from hotspot data")
	var bus_rect: Rect2 = click_game.get_hotspot_rect("bus_station")
	action_button.pressed.emit()
	await process_frame
	_assert(game_state.has_town_route(), "choosing the town route should set the route flag")
	_assert(game_state.coins == 7, "choosing the town route should add a route coin after the visit bonus")
	_assert(game_state.learned_words.has("bus"), "choosing the town route should add bus to word records")
	_assert(game_state.learned_words.has("route"), "choosing the town route should add route to word records")
	_assert(game_state.learned_words.has("town"), "choosing the town route should add town to word records")
	_assert(game_state.learned_patterns.has("Take the bus to town."), "choosing the town route should add a travel pattern")
	_assert(reward_label.text == PlaceCardDataAssertions.action_success_status_text(town_map, "bus_station", "choose_town_route"), "route action should update the place card status from action data")
	_assert(not action_button.visible, "route action should hide after the route is marked")
	_assert(town_map.get_active_scene() == "world_overview", "route choice should keep the player on the world overview")
	_assert(PlaceCardDataAssertions.action_success_focus_hotspot(town_map, "bus_station", "choose_town_route") == "bus_station", "route action should declare the bus station focus hotspot")
	_assert(town_map.get_world_overview_camera_rect().has_point(bus_rect.get_center()), "route choice should focus the bus station arrival area")

	var close_event := InputEventAction.new()
	close_event.action = "ui_accept"
	close_event.pressed = true
	place_card._unhandled_input(close_event)
	await process_frame
	click_game.target_clicked.emit("bus_station")
	await process_frame
	_assert(place_card.visible, "bus station revisit should still open a place card")
	_assert(game_state.coins == 7, "bus station revisit should not repeat travel route reward")
	_assert(not action_button.visible, "marked route should not expose the route action again")
	_assert(reward_label.text == "Already visited", "bus station revisit should use the normal visited status")

	print("mvp_0_2_transport_town_route_flow passed.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
