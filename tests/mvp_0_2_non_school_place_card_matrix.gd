extends SceneTree

const PlaceCardDataAssertions = preload("res://tests/helpers/place_card_data_assertions.gd")


const MATRIX_PLACE_IDS := [
	"post_office",
	"hospital",
	"restaurant",
	"cinema",
	"bus_station",
	"taxi",
	"railway_station",
	"airport"
]

const EXPECTED_ACTIONS := {
	"post_office": "help_carry_parcel",
	"restaurant": "help_choose_snack",
	"cinema": "help_make_poster",
	"bus_station": "choose_town_route",
	"taxi": "find_town_road",
	"railway_station": "choose_train_stop"
}


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
	var place_label: Label = place_card.get_node("Panel/MarginContainer/VBoxContainer/PlaceLabel")
	var hint_label: Label = place_card.get_node("Panel/MarginContainer/VBoxContainer/HintLabel")
	var reward_label: Label = place_card.get_node("Panel/MarginContainer/VBoxContainer/RewardLabel")
	var action_button: Button = place_card.get_node("Panel/MarginContainer/VBoxContainer/ActionButton")
	var close_event := InputEventAction.new()
	close_event.action = "ui_accept"
	close_event.pressed = true

	_assert(town_map.get_active_scene() == "home", "new game should start at home")
	town_map.show_scene("world_overview")
	town_map.set_click_input_enabled(true)
	await process_frame
	_assert(town_map.get_active_scene() == "world_overview", "matrix should switch to world overview for place-card coverage")
	var starting_coins: int = game_state.coins
	var expected_coins := starting_coins
	for place_id in MATRIX_PLACE_IDS:
		var hotspot: Dictionary = town_map.get_hotspot_by_id(place_id)
		var world_place_action: Dictionary = hotspot.get("world_place_action", {})
		_assert(str(world_place_action.get("action", "")) == "place_card", "%s should declare place_card routing in hotspot data" % place_id)
		click_game.target_clicked.emit(place_id)
		await process_frame
		expected_coins += 1
		_assert(place_card.visible, "%s should open a place card" % place_id)
		_assert(place_label.text == _expected_label(town_map, place_id), "%s should show hotspot label" % place_id)
		_assert(hint_label.text == PlaceCardDataAssertions.hint(town_map, place_id), "%s should show the hotspot place card hint" % place_id)
		_assert(reward_label.text == "+1 coin", "%s first visit should show coin reward" % place_id)
		_assert(game_state.coins == expected_coins, "%s first visit should add exactly 1 coin" % place_id)
		var expected_action_id := str(EXPECTED_ACTIONS.get(place_id, ""))
		if not expected_action_id.is_empty():
			_assert(action_button.visible, "%s should expose its starter action" % place_id)
			_assert(action_button.text == PlaceCardDataAssertions.action_label(town_map, place_id, expected_action_id), "%s should expose the action label from hotspot data" % place_id)
			_assert(not PlaceCardDataAssertions.action_visible_when(town_map, place_id, expected_action_id).is_empty(), "%s action should declare its visible_when condition" % place_id)
		else:
			_assert(not action_button.visible, "%s should not expose a starter action in the generic matrix" % place_id)
		place_card._unhandled_input(close_event)
		await process_frame
		_assert(not place_card.visible, "%s card should close cleanly" % place_id)
		_assert(bool(click_game.input_enabled), "%s close should restore world click input" % place_id)

	for place_id in MATRIX_PLACE_IDS:
		click_game.target_clicked.emit(place_id)
		await process_frame
		_assert(place_card.visible, "%s revisit should still open a place card" % place_id)
		_assert(reward_label.text == "Already visited", "%s revisit should not show a new reward" % place_id)
		_assert(game_state.coins == expected_coins, "%s revisit should not add coins" % place_id)
		place_card._unhandled_input(close_event)
		await process_frame

	print("mvp_0_2_non_school_place_card_matrix passed.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))
	quit(0)


func _expected_label(town_map: Node, place_id: String) -> String:
	var hotspot: Dictionary = town_map.get_hotspot_by_id(place_id)
	return str(hotspot.get("label", place_id))


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
