extends SceneTree

var _drag_completed_count := 0
var _quest_completed_count := 0


func _initialize() -> void:
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	await process_frame

	var town_map: Node = main.get_node("SceneHost")
	var player: CharacterBody2D = town_map.get_node("Player")
	_assert_npc_prompt_cycle(player, town_map.get_node("NpcLayer/Mina"))

	var quest_diary: CanvasLayer = main.get_node("QuestDiary")
	quest_diary.quest_completed.connect(func(_quest_id: String, _reward_id: String, _reward_name: String) -> void:
		_quest_completed_count += 1
	)
	var click_game: Node = town_map.get_click_game()
	quest_diary.start_quest("prologue_letter_box")
	_assert(town_map.get_active_scene() == "home", "Welcome Box should start in scene_id from quest data")
	_assert(bool(click_game.input_enabled), "click_target quest should enable click input from quest data")
	quest_diary.dismiss()

	quest_diary.start_quest("prologue_go_to_school")
	_assert(town_map.get_active_scene() == "world_overview", "First Trip should start in scene_id from quest data")
	_assert(bool(click_game.input_enabled), "world click_target quest should enable click input from quest data")
	quest_diary.dismiss()

	quest_diary.start_quest("g4_u1_school_tour")
	_assert(town_map.get_active_scene() == "campus_gate", "Walk With Mina should start in scene_id from quest data")
	_assert(bool(click_game.input_enabled), "school click_target quest should enable click input from quest data")
	quest_diary.dismiss()

	quest_diary.start_quest("g4_u1_garden_bird")
	_assert(town_map.get_active_scene() == "garden", "Bird Watch should start in scene_id from quest data")
	_assert(bool(click_game.input_enabled), "garden click_target quest should enable click input from quest data")
	quest_diary.dismiss()

	quest_diary.start_quest("g4_u1_tidy_classroom")
	_assert(town_map.get_active_scene() == "classroom", "Room Helper should start in scene_id from quest data")
	_assert(not bool(click_game.input_enabled), "drag_place quest should disable click input from quest data")

	var drag_game: Node2D = main.get_node("DragPlaceGame")
	_assert(drag_game.visible, "drag_place quest should show drag game from quest data")
	drag_game.completed.connect(func() -> void:
		_drag_completed_count += 1
	)
	await process_frame
	_drag_item_to_target(drag_game, "book", "shelf")
	_drag_item_to_target(drag_game, "pencil", "desk")
	_drag_item_to_target(drag_game, "bag", "under_desk")
	await process_frame

	_assert(drag_game.is_complete(), "drag game should complete through input events")
	_assert(_drag_completed_count == 1, "drag completed signal should emit once")
	_assert(_quest_completed_count == 1, "quest completed should emit once from drag input")
	_drag_item_to_target(drag_game, "book", "shelf")
	await process_frame
	_assert(_drag_completed_count == 1, "drag completed should not repeat after complete")
	_assert(_quest_completed_count == 1, "quest completed should not repeat after complete")

	print("MVP 0.2 input flow smoke passed.")
	quit(0)


func _assert_npc_prompt_cycle(player: CharacterBody2D, npc: Area2D) -> void:
	var prompt: Label = npc.get_node("PromptLabel")
	_assert(not prompt.visible, "NPC prompt should start hidden")
	npc.body_entered.emit(player)
	_assert(prompt.visible, "NPC prompt should show when player enters range")
	_assert(player.nearby_interactable == npc, "player should track nearby NPC")
	npc.body_exited.emit(player)
	_assert(not prompt.visible, "NPC prompt should hide when player exits range")
	_assert(player.nearby_interactable == null, "player should clear nearby NPC")


func _drag_item_to_target(drag_game: Node2D, item_id: String, target_id: String) -> void:
	var item: ColorRect = drag_game.get_node("%sItem" % item_id.capitalize())
	var target: ColorRect = drag_game.get_node("%sTarget" % target_id.capitalize())
	var from := item.global_position + item.size * 0.5
	var to := target.global_position + target.size * 0.5
	_send_mouse_button(item, from, true)
	_send_mouse_motion(item, from, to)
	_send_mouse_button(item, to, false)


func _send_mouse_button(item: ColorRect, position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = position
	event.global_position = position
	item.gui_input.emit(event)


func _send_mouse_motion(item: ColorRect, from: Vector2, to: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = to
	event.global_position = to
	event.relative = to - from
	item.gui_input.emit(event)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
