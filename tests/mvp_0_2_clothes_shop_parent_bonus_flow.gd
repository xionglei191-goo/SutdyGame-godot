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
	var explorer_cape: Polygon2D = town_map.get_node("Player/ExplorerCape")
	_assert(town_map.get_active_scene() == "home", "new game should start at home")
	town_map.show_scene("world_overview")
	town_map.set_click_input_enabled(true)
	await process_frame
	_assert(not explorer_cape.visible, "explorer cape should start hidden before purchase")

	click_game.target_clicked.emit("clothes_shop")
	await process_frame
	_assert(place_card.visible, "clothes shop should open a place card")
	_assert(game_state.coins == 6, "first clothes shop visit should add the discovery coin")
	var action_button: Button = place_card.get_node("Panel/MarginContainer/VBoxContainer/ActionButton")
	var reward_label: Label = place_card.get_node("Panel/MarginContainer/VBoxContainer/RewardLabel")
	_assert(action_button.visible, "clothes shop should offer the starter outfit purchase")
	_assert(action_button.text == PlaceCardDataAssertions.action_label(town_map, "clothes_shop", "buy_explorer_cape"), "clothes shop should price the cape from hotspot data")
	action_button.pressed.emit()
	await process_frame
	_assert(not game_state.has_explorer_cape(), "cape purchase should fail without Parent Bonus")
	_assert(game_state.parent_bonus == 0, "failed cape purchase should not change Parent Bonus")
	_assert(reward_label.text == "You need 1 Parent Bonus for the explorer cape.", "failed cape purchase should explain Parent Bonus need")

	game_state.add_parent_bonus(1)
	action_button.pressed.emit()
	await process_frame
	_assert(game_state.has_explorer_cape(), "buying the explorer cape should set the owned flag")
	_assert(game_state.parent_bonus == 0, "buying the explorer cape should spend Parent Bonus")
	_assert(game_state.coins == 6, "buying the explorer cape should not spend coins")
	_assert(game_state.learned_words.has("clothes"), "buying the cape should add clothes to word records")
	_assert(game_state.learned_words.has("cape"), "buying the cape should add cape to word records")
	_assert(game_state.learned_words.has("wear"), "buying the cape should add wear to word records")
	_assert(game_state.learned_patterns.has("Wear the explorer cape."), "buying the cape should add an outfit pattern")
	_assert(reward_label.text == PlaceCardDataAssertions.action_success_status_text(town_map, "clothes_shop", "buy_explorer_cape"), "successful cape purchase should update the place card status from action data")
	_assert(not action_button.visible, "action button should hide after the cape purchase")
	_assert(explorer_cape.visible, "buying the explorer cape should show the cape on the player")

	var close_event := InputEventAction.new()
	close_event.action = "ui_accept"
	close_event.pressed = true
	place_card._unhandled_input(close_event)
	await process_frame
	click_game.target_clicked.emit("home")
	await process_frame
	_assert(town_map.get_active_scene() == "home", "home should stay routable after buying the explorer cape")
	_assert(explorer_cape.visible, "explorer cape should remain visible after routing home")
	var pet_item_value: Label = town_map.get_scene_root("home").get_node("PetPanel/MarginContainer/VBoxContainer/StatsGrid/PetItemValue")
	var outfit_value: Label = town_map.get_scene_root("home").get_node("PetPanel/MarginContainer/VBoxContainer/StatsGrid/OutfitValue")
	var decor_slot_cape: Sprite2D = town_map.get_scene_root("home").get_node("DecorSlot_Cape")
	_assert(pet_item_value.text != "Explorer cape ready", "explorer cape should not pollute pet item status")
	_assert(outfit_value.text == "Explorer cape ready", "home outfit status should show the purchased explorer cape")
	_assert(decor_slot_cape.visible, "buying the explorer cape should show the cape display at home")
	_assert(decor_slot_cape.texture != null and decor_slot_cape.texture.resource_path == "res://assets/generated/props/home/prop_explorer_cape_display_v001.png", "cape display should use generated home decor art")

	var save_path := "user://mvp_0_2_clothes_shop_save.json"
	_assert(game_state.save_game(save_path), "clothes shop save should succeed")
	game_state.reset_progress()
	_assert(game_state.load_game(save_path), "clothes shop load should succeed")
	_assert(game_state.has_explorer_cape(), "load should restore explorer cape ownership")
	_assert(game_state.parent_bonus == 0, "load should restore spent Parent Bonus balance")
	_assert(game_state.coins == 6, "load should restore coins separately from Parent Bonus")
	await process_frame
	_assert(decor_slot_cape.visible, "load should restore visible explorer cape display")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))

	print("mvp_0_2_clothes_shop_parent_bonus_flow passed.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
