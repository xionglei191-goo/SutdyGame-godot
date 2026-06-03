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

	place_card._unhandled_input(close_event)
	await process_frame
	town_map.set_click_input_enabled(true)
	click_game.target_clicked.emit("taxi")
	await process_frame
	_assert(place_card.visible, "taxi should open a place card")
	_assert(game_state.coins == 8, "first taxi visit should add the discovery coin after the bus route")
	_assert(action_button.visible, "taxi should offer a town road action")
	_assert(action_button.text == PlaceCardDataAssertions.action_label(town_map, "taxi", "find_town_road"), "taxi should expose the road action from hotspot data")
	var taxi_rect: Rect2 = click_game.get_hotspot_rect("taxi")
	action_button.pressed.emit()
	await process_frame
	_assert(game_state.has_town_road(), "finding the town road should set the road flag")
	_assert(game_state.coins == 9, "finding the town road should add a route coin after the visit bonus")
	_assert(game_state.learned_words.has("taxi"), "finding the town road should add taxi to word records")
	_assert(game_state.learned_words.has("road"), "finding the town road should add road to word records")
	_assert(game_state.learned_patterns.has("Take a taxi to the road."), "finding the town road should add a taxi pattern")
	_assert(reward_label.text == PlaceCardDataAssertions.action_success_status_text(town_map, "taxi", "find_town_road"), "taxi action should update status from action data")
	_assert(not action_button.visible, "taxi action should hide after the road is marked")
	_assert(town_map.get_world_overview_camera_rect().has_point(taxi_rect.get_center()), "taxi action should focus the taxi area")

	place_card._unhandled_input(close_event)
	await process_frame
	town_map.set_click_input_enabled(true)
	click_game.target_clicked.emit("railway_station")
	await process_frame
	_assert(place_card.visible, "railway station should open a place card")
	_assert(game_state.coins == 10, "first railway visit should add the discovery coin after taxi")
	_assert(action_button.visible, "railway station should offer a train stop action")
	_assert(action_button.text == PlaceCardDataAssertions.action_label(town_map, "railway_station", "choose_train_stop"), "railway station should expose the train action from hotspot data")
	var train_rect: Rect2 = click_game.get_hotspot_rect("railway_station")
	action_button.pressed.emit()
	await process_frame
	_assert(game_state.has_train_stop(), "choosing the train stop should set the train stop flag")
	_assert(game_state.coins == 11, "choosing the train stop should add a route coin after the visit bonus")
	_assert(game_state.learned_words.has("train"), "choosing the train stop should add train to word records")
	_assert(game_state.learned_words.has("station"), "choosing the train stop should add station to word records")
	_assert(game_state.learned_words.has("stop"), "choosing the train stop should add stop to word records")
	_assert(game_state.learned_patterns.has("Take the train to the station."), "choosing the train stop should add a train pattern")
	_assert(reward_label.text == PlaceCardDataAssertions.action_success_status_text(town_map, "railway_station", "choose_train_stop"), "railway action should update status from action data")
	_assert(action_button.visible, "railway station should expose the next helper action after the route is marked")
	_assert(action_button.text == PlaceCardDataAssertions.action_label(town_map, "railway_station", "check_train_time"), "railway station should advance to the time helper action")
	_assert(town_map.get_world_overview_camera_rect().has_point(train_rect.get_center()), "train action should focus the railway area")

	print("mvp_0_2_transport_town_route_flow passed.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
