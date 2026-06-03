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
	var action_button: Button = place_card.get_node("Panel/MarginContainer/VBoxContainer/ActionButton")
	var close_event := InputEventAction.new()
	close_event.action = "ui_accept"
	close_event.pressed = true
	town_map.show_scene("world_overview")
	town_map.set_click_input_enabled(true)
	await process_frame

	await _assert_action_visibility(town_map, click_game, place_card, action_button, close_event, "supermarket", "buy_pet_bowl", "missing_pet_bowl", true)
	game_state.own_item(game_state.PET_BOWL_ITEM, game_state.PET_BOWL_FLAG)
	await _assert_action_visibility(town_map, click_game, place_card, action_button, close_event, "supermarket", "buy_pet_bowl", "missing_pet_bowl", false)

	await _assert_action_visibility(town_map, click_game, place_card, action_button, close_event, "bus_station", "choose_town_route", "missing_town_route", true)
	game_state.mark_story_flag(game_state.TOWN_ROUTE_FLAG)
	await _assert_action_visibility(town_map, click_game, place_card, action_button, close_event, "bus_station", "choose_town_route", "missing_town_route", false)

	await _assert_action_visibility(town_map, click_game, place_card, action_button, close_event, "taxi", "find_town_road", "missing_town_road", true)
	game_state.mark_story_flag(game_state.TOWN_ROAD_FLAG)
	await _assert_action_visibility(town_map, click_game, place_card, action_button, close_event, "taxi", "find_town_road", "missing_town_road", false)

	await _assert_action_visibility(town_map, click_game, place_card, action_button, close_event, "railway_station", "choose_train_stop", "missing_train_stop", true)
	game_state.mark_story_flag(game_state.TRAIN_STOP_FLAG)
	await _assert_action_visibility(town_map, click_game, place_card, action_button, close_event, "railway_station", "choose_train_stop", "missing_train_stop", false)

	await _assert_action_visibility(town_map, click_game, place_card, action_button, close_event, "bookshop", "help_find_book", "quest_not_completed:town_bookshop_find_book", true)
	game_state.complete_quest("town_bookshop_find_book")
	await _assert_action_visibility(town_map, click_game, place_card, action_button, close_event, "bookshop", "help_find_book", "quest_not_completed:town_bookshop_find_book", false)

	await _assert_action_visibility(town_map, click_game, place_card, action_button, close_event, "post_office", "help_carry_parcel", "quest_not_completed:town_post_office_small_parcel", true)
	game_state.complete_quest("town_post_office_small_parcel")
	await _assert_action_visibility(town_map, click_game, place_card, action_button, close_event, "post_office", "help_carry_parcel", "quest_not_completed:town_post_office_small_parcel", false)

	await _assert_action_visibility(town_map, click_game, place_card, action_button, close_event, "restaurant", "help_choose_snack", "quest_not_completed:town_restaurant_snack_order", true)
	game_state.complete_quest("town_restaurant_snack_order")
	await _assert_action_visibility(town_map, click_game, place_card, action_button, close_event, "restaurant", "help_choose_snack", "quest_not_completed:town_restaurant_snack_order", false)

	await _assert_action_visibility(town_map, click_game, place_card, action_button, close_event, "cinema", "help_make_poster", "quest_not_completed:town_cinema_show_poster", true)
	game_state.complete_quest("town_cinema_show_poster")
	await _assert_action_visibility(town_map, click_game, place_card, action_button, close_event, "cinema", "help_make_poster", "quest_not_completed:town_cinema_show_poster", false)

	print("mvp_0_2_place_card_visibility_data passed.")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))
	quit(0)


func _assert_action_visibility(
	town_map: Node,
	click_game: Node,
	place_card: CanvasLayer,
	action_button: Button,
	close_event: InputEvent,
	place_id: String,
	action_id: String,
	visible_when: String,
	should_be_visible: bool
) -> void:
	town_map.set_click_input_enabled(true)
	click_game.target_clicked.emit(place_id)
	await process_frame
	_assert(place_card.visible, "%s should open a place card" % place_id)
	_assert(PlaceCardDataAssertions.action_visible_when(town_map, place_id, action_id) == visible_when, "%s should declare visible_when for %s" % [place_id, action_id])
	_assert(PlaceCardDataAssertions.action_is_visible(town_map, place_id, action_id) == should_be_visible, "%s action visibility should follow %s" % [place_id, visible_when])
	if should_be_visible:
		_assert(action_button.visible, "%s should show its primary action button" % place_id)
		_assert(action_button.text == PlaceCardDataAssertions.action_label(town_map, place_id, action_id), "%s action label should come from hotspot data" % place_id)
	elif not PlaceCardDataAssertions.has_visible_action(town_map, place_id):
		_assert(not action_button.visible, "%s should hide the primary action button when no actions remain" % place_id)
	place_card._unhandled_input(close_event)
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
