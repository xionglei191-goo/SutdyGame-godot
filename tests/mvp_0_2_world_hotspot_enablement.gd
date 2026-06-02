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
	var quest_diary: CanvasLayer = main.get_node("QuestDiary")

	_assert(town_map.get_active_scene() == "home", "new game should start at home")
	town_map.show_scene("world_overview")
	town_map.set_click_input_enabled(true)
	await process_frame

	var free_explore_rects: Dictionary = click_game.get_place_rects_for_scene("world_overview")
	_assert(not free_explore_rects.has("tree"), "tree should stay hidden in free explore")
	_assert(not free_explore_rects.has("flower"), "flower should stay hidden in free explore")
	_assert(not free_explore_rects.has("bench"), "bench should stay hidden in free explore")
	_assert(not free_explore_rects.has("bird"), "bird should stay hidden in free explore")
	_assert(not free_explore_rects.has("music_room"), "music room should not be world-clickable before a route exists")
	_assert(not free_explore_rects.has("art_room"), "art room should not be world-clickable before a route exists")
	_assert(free_explore_rects.has("home"), "home should stay available in free explore")
	_assert(free_explore_rects.has("bookshop"), "bookshop should stay available in free explore")
	_assert(free_explore_rects.has("pet_shop"), "pet shop should stay available in free explore")
	_assert(free_explore_rects.has("clothes_shop"), "clothes shop should stay available in free explore")
	_assert(free_explore_rects.has("general_store"), "general store should stay available in free explore")
	_assert(free_explore_rects.has("airport"), "airport should stay available in free explore")

	quest_diary.start_quest("g4_u1_garden_bird")
	town_map.show_scene("world_overview")
	town_map.set_click_input_enabled(true)
	town_map.set_quest_active(true)
	town_map.set_current_quest_id("g4_u1_garden_bird")
	await process_frame

	var garden_quest_rects: Dictionary = click_game.get_place_rects_for_scene("world_overview")
	_assert(garden_quest_rects.has("tree"), "tree should become clickable during the Bird Watch event")
	_assert(garden_quest_rects.has("flower"), "flower should become clickable during the Bird Watch event")
	_assert(garden_quest_rects.has("bench"), "bench should become clickable during the Bird Watch event")
	_assert(garden_quest_rects.has("bird"), "bird should become clickable during the Bird Watch event")
	_assert(not garden_quest_rects.has("music_room"), "music room should stay disabled during the Bird Watch event")
	_assert(not garden_quest_rects.has("art_room"), "art room should stay disabled during the Bird Watch event")

	print("mvp_0_2_world_hotspot_enablement passed.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
