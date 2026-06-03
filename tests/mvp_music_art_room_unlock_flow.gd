extends SceneTree

const PlaceCardDataAssertions = preload("res://tests/helpers/place_card_data_assertions.gd")

const ROOM_COMMISSIONS := [
	{
		"place_id": "music_room",
		"action_id": "find_music_sound",
		"dialogue_id": "mina_music_room_sound_intro",
		"quest_id": "school_music_room_sound_find",
		"title": "Sound Finder",
		"prompt": "Find the music room and listen for a bright sound.",
		"reward_id": "sound_note",
		"reward_name": "Sound Note",
		"words": ["music", "sound", "listen"],
		"patterns": ["Listen to the sound.", "The music room is here."]
	},
	{
		"place_id": "art_room",
		"action_id": "pick_art_color",
		"dialogue_id": "mina_art_room_color_intro",
		"quest_id": "school_art_room_color_pick",
		"title": "Color Pick",
		"prompt": "Find the art room and pick a happy color.",
		"reward_id": "color_dot",
		"reward_name": "Color Dot",
		"words": ["art", "color", "paint"],
		"patterns": ["Pick a color.", "I like blue paint."]
	}
]


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
	var dialogue_box: CanvasLayer = main.get_node("DialogueBox")
	var quest_diary: CanvasLayer = main.get_node("QuestDiary")
	var reward_popup: CanvasLayer = main.get_node("RewardPopup")
	var action_button: Button = place_card.get_node("Panel/MarginContainer/VBoxContainer/ActionButton")
	var reward_label: Label = place_card.get_node("Panel/MarginContainer/VBoxContainer/RewardLabel")
	var close_event := InputEventAction.new()
	close_event.action = "ui_accept"
	close_event.pressed = true

	town_map.show_scene("world_overview")
	town_map.set_click_input_enabled(true)
	await process_frame
	var before_prologue_rects: Dictionary = click_game.get_place_rects_for_scene("world_overview")
	_assert(not before_prologue_rects.has("music_room"), "music room should stay locked before the prologue")
	_assert(not before_prologue_rects.has("art_room"), "art room should stay locked before the prologue")

	game_state.complete_quest("prologue_go_to_school")
	town_map.show_scene("world_overview")
	town_map.set_click_input_enabled(true)
	await process_frame
	var after_prologue_rects: Dictionary = click_game.get_place_rects_for_scene("world_overview")
	_assert(after_prologue_rects.has("music_room"), "music room should unlock after the prologue")
	_assert(after_prologue_rects.has("art_room"), "art room should unlock after the prologue")

	var expected_coins: int = game_state.coins
	for commission: Dictionary in ROOM_COMMISSIONS:
		await _run_room_commission(
			commission,
			game_state,
			town_map,
			click_game,
			place_card,
			dialogue_box,
			quest_diary,
			reward_popup,
			action_button,
			reward_label,
			close_event,
			expected_coins
		)
		expected_coins += 2

	print("mvp_music_art_room_unlock_flow passed.")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))
	quit(0)


func _run_room_commission(
	commission: Dictionary,
	game_state: Node,
	town_map: Node,
	click_game: Node,
	place_card: CanvasLayer,
	dialogue_box: CanvasLayer,
	quest_diary: CanvasLayer,
	reward_popup: CanvasLayer,
	action_button: Button,
	reward_label: Label,
	close_event: InputEvent,
	expected_starting_coins: int
) -> void:
	var place_id := str(commission.get("place_id", ""))
	var action_id := str(commission.get("action_id", ""))
	var quest_id := str(commission.get("quest_id", ""))
	var dialogue_id := str(commission.get("dialogue_id", ""))

	town_map.set_click_input_enabled(true)
	click_game.target_clicked.emit(place_id)
	await process_frame
	_assert(place_card.visible, "%s should open a PlaceCard after prologue" % place_id)
	_assert(game_state.coins == expected_starting_coins + 1, "%s first visit should add a discovery coin" % place_id)
	_assert(action_button.visible, "%s should show its activity room action" % place_id)
	_assert(action_button.text == PlaceCardDataAssertions.action_label(town_map, place_id, action_id), "%s action label should come from hotspot data" % place_id)
	_assert(PlaceCardDataAssertions.action_visible_when(town_map, place_id, action_id) == "quest_not_completed:%s" % quest_id, "%s action visibility should point to the quest" % place_id)
	_assert(str(PlaceCardDataAssertions.action_data(town_map, place_id, action_id).get("start_dialogue_id", "")) == dialogue_id, "%s action should declare the start dialogue" % place_id)

	action_button.pressed.emit()
	await process_frame
	await _finish_dialogue_if_visible(dialogue_box, close_event)
	_assert(not place_card.visible, "%s action should hide the PlaceCard before Quest Diary starts" % place_id)
	_assert(quest_diary.active, "%s action should start Quest Diary" % place_id)
	_assert(quest_diary.quest_id == quest_id, "%s should start the configured quest" % place_id)
	_assert(quest_diary.event_label.text == str(commission.get("title", "")), "%s quest should show its child-facing title" % place_id)
	_assert(quest_diary.prompt_label.text == str(commission.get("prompt", "")), "%s quest should show its child-facing prompt" % place_id)
	_assert(quest_diary.reward_label.text == "Keepsake: %s" % str(commission.get("reward_name", "")), "%s quest should show its keepsake" % place_id)

	click_game.target_clicked.emit("sunshine_school")
	await process_frame
	_assert(quest_diary.active, "%s wrong world target should not complete the quest" % place_id)
	_assert(quest_diary.status_label.text == "Look again", "%s wrong target should show retry status" % place_id)
	click_game.target_clicked.emit(place_id)
	await process_frame
	_assert(not quest_diary.active, "%s target should complete the quest" % place_id)
	_assert(game_state.has_completed_quest(quest_id), "%s quest should be saved as completed" % place_id)
	_assert(game_state.has_story_flag("%s_done" % quest_id), "%s quest should write its completion story flag" % place_id)
	_assert(game_state.rewards.has(str(commission.get("reward_id", ""))), "%s quest should add its keepsake" % place_id)
	for word_value: Variant in commission.get("words", []):
		_assert(game_state.learned_words.has(str(word_value)), "%s quest should add word: %s" % [place_id, word_value])
	for pattern_value: Variant in commission.get("patterns", []):
		_assert(game_state.learned_patterns.has(str(pattern_value)), "%s quest should add pattern: %s" % [place_id, pattern_value])
	_assert(game_state.coins == expected_starting_coins + 2, "%s quest should add one quest coin after the discovery coin" % place_id)
	_assert(reward_popup.visible, "%s quest should show a keepsake popup" % place_id)

	reward_popup._unhandled_input(close_event)
	await process_frame
	town_map.set_click_input_enabled(true)
	click_game.target_clicked.emit(place_id)
	await process_frame
	_assert(place_card.visible, "%s revisit should still open a PlaceCard" % place_id)
	_assert(not action_button.visible, "%s completed quest should hide its action" % place_id)
	_assert(reward_label.text == "Already visited", "%s revisit should not repeat the discovery reward" % place_id)
	place_card._unhandled_input(close_event)
	await process_frame


func _finish_dialogue_if_visible(dialogue_box: CanvasLayer, close_event: InputEvent) -> void:
	var safety := 8
	while dialogue_box.visible and safety > 0:
		dialogue_box._unhandled_input(close_event)
		await process_frame
		safety -= 1


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
