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
	var dialogue_box: CanvasLayer = main.get_node("DialogueBox")
	var quest_diary: CanvasLayer = main.get_node("QuestDiary")
	var player: CharacterBody2D = town_map.get_node("Player")
	var camera: Camera2D = player.get_node("Camera2D")
	var click_game: Node = town_map.get_node("ClickGame")

	_assert(town_map.has_method("get_active_scene"), "town map should expose active scene")
	_assert(town_map.get_active_scene() == "home", "new game should start at home for the Welcome Box opener")
	var mina: Area2D = town_map.get_node("NpcLayer/Mina")
	_assert(mina.dialogue_id == "mina_letter_box_intro", "new home scene should begin with the Welcome Box dialogue")
	town_map.show_scene("world_overview")
	town_map.set_click_input_enabled(true)
	await process_frame
	_assert(click_game.has_method("get_world_canvas_size"), "click game should expose world overview canvas size")
	_assert(click_game.get_world_canvas_size() == Vector2(2560.0, 1440.0), "world overview should use 2560x1440 logic size")
	_assert(town_map.has_method("get_world_overview_spawn_position"), "town map should expose world overview spawn position")
	_assert(player.position == town_map.get_world_overview_spawn_position(), "player should spawn at the home-to-school starting focus point")
	_assert(camera.limit_right == 2560, "camera should clamp to world overview width")
	_assert(camera.limit_bottom == 1440, "camera should clamp to world overview height")
	_assert(town_map.has_method("get_world_overview_camera_rect"), "town map should expose current world overview camera rect")
	var initial_camera_rect: Rect2 = town_map.get_world_overview_camera_rect()
	var home_rect: Rect2 = click_game.get_hotspot_rect("home")
	var school_rect: Rect2 = click_game.get_hotspot_rect("sunshine_school")
	_assert(home_rect.size != Vector2.ZERO, "world overview should include a home hotspot")
	_assert(initial_camera_rect.intersects(home_rect), "initial camera rect should include home")
	_assert(initial_camera_rect.intersects(school_rect), "initial camera rect should include Sunshine School")
	var classroom_rect: Rect2 = click_game.get_hotspot_rect("classroom")
	var library_rect: Rect2 = click_game.get_hotspot_rect("library")
	var canteen_rect: Rect2 = click_game.get_hotspot_rect("canteen")
	var music_room_rect: Rect2 = click_game.get_hotspot_rect("music_room")
	var art_room_rect: Rect2 = click_game.get_hotspot_rect("art_room")
	var playground_rect: Rect2 = click_game.get_hotspot_rect("playground")
	_assert(school_rect.encloses(classroom_rect), "classroom hotspot should live inside the school cluster")
	_assert(school_rect.encloses(library_rect), "library hotspot should live inside the school cluster")
	_assert(school_rect.encloses(canteen_rect), "canteen hotspot should stay fully inside the school cluster")
	_assert(school_rect.encloses(music_room_rect), "music room hotspot should stay fully inside the school cluster")
	_assert(school_rect.encloses(art_room_rect), "art room hotspot should stay fully inside the school cluster")
	_assert(school_rect.encloses(playground_rect), "playground hotspot should stay fully inside the school cluster")
	var bus_station_rect: Rect2 = click_game.get_hotspot_rect("bus_station")
	var supermarket_rect: Rect2 = click_game.get_hotspot_rect("supermarket")
	_assert(bus_station_rect.position.y < supermarket_rect.position.y, "bus station should sit closer to the main road than supermarket")

	click_game.target_clicked.emit("home")
	await process_frame
	_assert(town_map.get_active_scene() == "home", "home click should route to the home subscene before Walk With Mina completion")
	_assert(town_map.get_node("HomeLayer").visible, "home layer should become visible after routing to home")
	_assert(mina.dialogue_id == "mina_letter_box_intro", "new home scene should begin with the Welcome Box dialogue")
	var main_dialogue_box: CanvasLayer = main.get_node("DialogueBox")
	mina.interaction_requested.emit(mina.dialogue_id)
	await process_frame
	_assert(main_dialogue_box.visible, "home Mina interaction should open the dialogue box")
	_assert(main_dialogue_box.dialogue_id == "mina_letter_box_intro", "home Mina should open the Welcome Box dialogue")
	var home_body_label: Label = main_dialogue_box.get_node("Panel/MarginContainer/VBoxContainer/BodyLabel")
	_assert(home_body_label.text.contains("welcome box"), "home intro should point to the Welcome Box")
	main_dialogue_box._finish()
	await process_frame
	_assert(quest_diary.active, "Welcome Box intro should start the starter quest")
	_assert(quest_diary.quest_id == "prologue_letter_box", "home intro should start Welcome Box before First Trip")
	_assert(quest_diary.prompt_label.text == "Open Mina's welcome box.", "starter quest should use Welcome Box wording")
	quest_diary.check_target("home")
	_assert(quest_diary.active, "wrong home target should not complete Welcome Box")
	quest_diary.check_target("home_letter_box")
	await process_frame
	_assert(not quest_diary.active, "Welcome Box should complete after tapping home_letter_box")
	_assert(game_state.has_completed_quest("prologue_letter_box"), "Welcome Box completion should be saved")
	_assert(town_map.get_active_scene() == "home", "Welcome Box completion should leave the player at home")
	_assert(mina.dialogue_id == "mina_home_intro", "Welcome Box completion should retarget Mina to First Trip")
	mina.interaction_requested.emit(mina.dialogue_id)
	await process_frame
	main_dialogue_box._finish()
	await process_frame
	_assert(quest_diary.active, "home intro should start First Trip after Welcome Box")
	_assert(quest_diary.quest_id == "prologue_go_to_school", "home intro should start First Trip before Walk With Mina")
	_assert(quest_diary.prompt_label.text == "Start Mina's first trip.", "First Trip should keep adventure wording")
	town_map.show_scene("world_overview")
	await process_frame
	player.position += Vector2(320.0, 180.0)
	camera.force_update_scroll()
	var moved_camera_rect: Rect2 = town_map.get_world_overview_camera_rect()
	_assert(moved_camera_rect.position != initial_camera_rect.position, "camera rect should move when the player moves across the world overview")

	click_game.target_clicked.emit("sunshine_school")
	await process_frame
	_assert(not quest_diary.active, "prologue quest should complete on school arrival")
	_assert(town_map.get_active_scene() == "campus_gate", "school arrival should route to campus gate after prologue completion")
	_assert(game_state.has_story_flag("az_full_unlocked_after_prologue"), "school arrival should unlock the full A-Z memory palace")
	_assert(main_dialogue_box.visible, "school arrival should open Mina arrival dialogue")
	_assert(main_dialogue_box.dialogue_id == "mina_school_arrival_intro", "school arrival should use dedicated handoff dialogue")
	main_dialogue_box._finish()
	await process_frame
	_assert(quest_diary.active, "school arrival handoff should start Walk With Mina")
	_assert(quest_diary.quest_id == "g4_u1_school_tour", "school arrival handoff should continue into Walk With Mina")
	quest_diary.dismiss()
	town_map.show_scene("world_overview")
	town_map.set_click_input_enabled(true)
	town_map.set_quest_active(false)
	await process_frame

	var anchor_events: Array[String] = []
	town_map.memory_anchor_clicked.connect(func(anchor_id: String) -> void:
		anchor_events.append(anchor_id)
	)
	click_game.memory_anchor_clicked.emit("anchor_a_apple")
	await process_frame
	_assert(anchor_events.has("anchor_a_apple"), "world overview should emit memory anchor signal")
	_assert(dialogue_box.visible, "anchor click should open dialogue box")
	_assert(dialogue_box.dialogue_id == "anchor_a_apple", "dialogue box should load anchor dialogue")
	var body_label: Label = dialogue_box.get_node("Panel/MarginContainer/VBoxContainer/BodyLabel")
	_assert(body_label.text.contains("A is for Apple."), "anchor dialogue should show apple prompt")

	print("MVP 0.2 world overview input flow smoke passed.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
