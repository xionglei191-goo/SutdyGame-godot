extends SceneTree


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
	var dialogue_box: CanvasLayer = main.get_node("DialogueBox")
	var memory_spark_card: CanvasLayer = main.get_node("MemorySparkCard")
	_assert(town_map.get_active_scene() == "home", "new game should start at home")
	town_map.show_scene("world_overview")
	town_map.set_click_input_enabled(true)
	await process_frame
	game_state.mark_story_flag("az_full_unlocked_after_prologue")

	click_game.memory_anchor_clicked.emit("anchor_b_bear")
	await process_frame
	_assert(dialogue_box.visible, "first anchor visit should still open anchor dialogue")
	_assert(dialogue_box.dialogue_id == "anchor_b_bear", "first anchor visit should load the anchor dialogue")
	dialogue_box._finish()
	await process_frame
	_assert(game_state.has_story_flag("anchor_seen_anchor_b_bear"), "finishing anchor dialogue should record the seen flag")

	click_game.memory_anchor_clicked.emit("anchor_b_bear")
	await process_frame
	_assert(memory_spark_card.visible, "second anchor visit should open memory spark card")
	var title_label: Label = memory_spark_card.get_node("Panel/MarginContainer/VBoxContainer/TitleLabel")
	_assert(title_label.text == "Memory Spark", "memory spark card should use child-facing title")
	var prompt_label: Label = memory_spark_card.get_node("Panel/MarginContainer/VBoxContainer/PromptLabel")
	_assert(prompt_label.text == "Look at letter B. What comes back?", "memory spark should use memory-palace prompt without exposing anchor jargon")
	var b_hotspot: Dictionary = town_map.get_hotspot_by_id("anchor_b_bear")
	var b_spark_data: Dictionary = b_hotspot.get("memory_spark", {})
	var memory_spark_defs: Dictionary = main.memory_spark_defs
	_assert(not b_spark_data.is_empty(), "anchor B should declare parameterized Memory Spark data")
	_assert(str(memory_spark_defs.get("anchor_b_bear", {}).get("prompt", "")) == str(b_spark_data.get("prompt", "")), "anchor B Memory Spark prompt should come from hotspot data")
	_assert(int(memory_spark_defs.get("anchor_b_bear", {}).get("reward_coins", 0)) == int(b_spark_data.get("reward_coins", 0)), "anchor B Memory Spark reward should come from hotspot data")
	var choices_grid: GridContainer = memory_spark_card.get_node("Panel/MarginContainer/VBoxContainer/ChoicesGrid")
	_assert(choices_grid.get_child_count() == 3, "Memory Spark should show configured choices")
	var choice_texts: Array[String] = []
	for child: Node in choices_grid.get_children():
		if child is Button:
			choice_texts.append((child as Button).text)
	_assert(choice_texts.has("Bear"), "Memory Spark should include the hotspot keyword as the correct choice")
	var wrong_button: Button = _choice_button_not_matching(choices_grid, "Bear")
	wrong_button.pressed.emit()
	await process_frame
	var feedback_label: Label = memory_spark_card.get_node("Panel/MarginContainer/VBoxContainer/FeedbackLabel")
	_assert(feedback_label.text == "Try again. Look at the picture clue.", "wrong recall choice should keep low-pressure picture-clue feedback")
	var correct_button: Button = _choice_button_matching(choices_grid, "Bear")
	correct_button.pressed.emit()
	await process_frame
	_assert(not memory_spark_card.visible, "correct memory spark should close the card")
	_assert(game_state.has_story_flag("anchor_recall_done_anchor_b_bear"), "correct memory spark should record completion flag")
	_assert(game_state.coins == 6, "first completed memory spark should grant 1 coin")
	_assert(game_state.learned_words.has("bear"), "memory spark should add configured word records")
	_assert(game_state.learned_patterns.has("B is for Bear."), "memory spark should add configured expression record")
	_assert(_has_event(game_state.playtest_events, "anchor_b_bear_memory_spark_completed"), "memory spark completion should record a playtest event")

	click_game.memory_anchor_clicked.emit("anchor_b_bear")
	await process_frame
	_assert(dialogue_box.visible, "completed memory spark should fall back to normal anchor dialogue")
	_assert(dialogue_box.dialogue_id == "anchor_b_bear", "completed memory spark should still allow anchor dialogue revisit")
	dialogue_box._finish()
	await process_frame

	click_game.memory_anchor_clicked.emit("anchor_h_hat")
	await process_frame
	_assert(dialogue_box.visible, "pilot anchor H should still start with anchor dialogue")
	dialogue_box._finish()
	await process_frame
	click_game.memory_anchor_clicked.emit("anchor_h_hat")
	await process_frame
	_assert(memory_spark_card.visible, "pilot anchor H should also open memory spark on revisit")
	prompt_label = memory_spark_card.get_node("Panel/MarginContainer/VBoxContainer/PromptLabel")
	_assert(prompt_label.text == "Look at letter H. What comes back?", "pilot H memory spark should derive memory-palace prompt from hotspot letter")
	memory_spark_card.visible = false

	click_game.memory_anchor_clicked.emit("anchor_y_yo_yo")
	await process_frame
	_assert(dialogue_box.visible, "full A-Z anchor Y should start with anchor dialogue after prologue unlock")
	_assert(dialogue_box.dialogue_id == "anchor_y_yo_yo", "full A-Z anchor Y should keep its stable anchor dialogue id")
	dialogue_box._finish()
	await process_frame
	click_game.memory_anchor_clicked.emit("anchor_y_yo_yo")
	await process_frame
	_assert(memory_spark_card.visible, "full A-Z anchor Y should open Memory Spark on revisit")
	prompt_label = memory_spark_card.get_node("Panel/MarginContainer/VBoxContainer/PromptLabel")
	_assert(prompt_label.text == "Look at letter Y. What comes back?", "full A-Z memory spark should derive prompt from frozen hotspot letter")
	choices_grid = memory_spark_card.get_node("Panel/MarginContainer/VBoxContainer/ChoicesGrid")
	_assert(_choice_button_matching(choices_grid, "Yo-yo") != null, "full A-Z memory spark should include the frozen keyword")

	print("mvp_0_2_memory_spark_flow passed.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)


func _choice_button_matching(choices_grid: GridContainer, text: String) -> Button:
	for child: Node in choices_grid.get_children():
		if child is Button and (child as Button).text == text:
			return child as Button
	push_error("Missing choice button: %s" % text)
	quit(1)
	return null


func _choice_button_not_matching(choices_grid: GridContainer, text: String) -> Button:
	for child: Node in choices_grid.get_children():
		if child is Button and (child as Button).text != text:
			return child as Button
	push_error("Missing non-matching choice button for: %s" % text)
	quit(1)
	return null


func _has_event(events: Array, event_id: String) -> bool:
	for event: Variant in events:
		if event is Dictionary and str((event as Dictionary).get("id", "")) == event_id:
			return true
	return false
