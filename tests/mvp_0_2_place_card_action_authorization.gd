extends SceneTree


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
	var world_interaction_controller: RefCounted = main.world_interaction_controller
	town_map.show_scene("world_overview")
	town_map.set_click_input_enabled(true)
	await process_frame

	var start_coins: int = game_state.coins
	world_interaction_controller.handle_place_card_action("supermarket", "buy_pet_bowl")
	await process_frame
	_assert(game_state.coins == start_coins, "direct purchase should not run before the matching PlaceCard is open")
	_assert(not game_state.has_pet_bowl(), "direct purchase should not grant item before the matching PlaceCard is open")

	click_game.target_clicked.emit("restaurant")
	await process_frame
	world_interaction_controller.handle_place_card_action("supermarket", "buy_pet_bowl")
	await process_frame
	_assert(not game_state.has_pet_bowl(), "direct purchase should not run while another PlaceCard is open")
	place_card.visible = false

	town_map.set_click_input_enabled(true)
	click_game.target_clicked.emit("supermarket")
	await process_frame
	game_state.own_item(game_state.PET_BOWL_ITEM, game_state.PET_BOWL_FLAG)
	var coins_before: int = game_state.coins
	world_interaction_controller.handle_place_card_action("supermarket", "buy_pet_bowl")
	await process_frame
	_assert(game_state.coins == coins_before, "hidden pet bowl action should not spend coins through direct signal")
	_assert(place_card.get_node("Panel/MarginContainer/VBoxContainer/RewardLabel").text == "That action is not ready.", "hidden purchase should show not-ready status")

	place_card.visible = false
	town_map.set_click_input_enabled(true)
	click_game.target_clicked.emit("bus_station")
	await process_frame
	game_state.mark_story_flag(game_state.TOWN_ROUTE_FLAG)
	var route_coins_before: int = game_state.coins
	world_interaction_controller.handle_place_card_action("bus_station", "choose_town_route")
	await process_frame
	_assert(game_state.coins == route_coins_before, "hidden town route action should not repeat reward through direct signal")

	place_card.visible = false
	town_map.set_click_input_enabled(true)
	click_game.target_clicked.emit("bookshop")
	await process_frame
	game_state.complete_quest("town_bookshop_find_book")
	var quest_completed_count: int = game_state.get_completed_quests().size()
	world_interaction_controller.handle_place_card_action("bookshop", "help_find_book")
	await process_frame
	var quest_diary: CanvasLayer = main.get_node("QuestDiary")
	_assert(not quest_diary.active, "completed bookshop action should not restart Quest Diary through direct signal")
	_assert(game_state.get_completed_quests().size() == quest_completed_count, "completed bookshop action should not duplicate quest state")

	print("mvp_0_2_place_card_action_authorization passed.")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
