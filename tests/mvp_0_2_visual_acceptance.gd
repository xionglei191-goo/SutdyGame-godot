extends SceneTree

func _initialize() -> void:
	var game_state: Node = root.get_node("GameState")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))
	game_state.reset_progress()
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	await process_frame
	game_state.reset_progress()

	var town_map: Node = main.get_node("TownMap")
	_assert_marker_center_in_click_rect(town_map, "PlaceLayer/ClassroomMarker", "classroom")
	_assert_marker_center_in_click_rect(town_map, "PlaceLayer/LibraryMarker", "library")
	_assert_marker_center_in_click_rect(town_map, "PlaceLayer/PlaygroundMarker", "playground")
	_assert_garden_bird_in_click_rect(town_map)
	_assert_garden_target_in_click_rect(town_map, "GardenLayer/TreeTrunk", "tree")
	_assert_garden_target_in_click_rect(town_map, "GardenLayer/FlowerBed", "flower")
	_assert_garden_target_in_click_rect(town_map, "GardenLayer/Bench", "bench")
	_assert_boundaries_present(town_map)
	_assert_player_outfit_layer(town_map)
	_assert_npc_dialogues_short()
	_assert_drag_targets_large_enough(main.get_node("DragPlaceGame"))
	_assert_review_read_aloud_timers(main.get_node("StoryShow"))
	_assert_review_layout(main.get_node("StoryShow"))
	_assert_dialogue_layout(main.get_node("DialogueBox"))
	_assert_memory_spark_layout(main.get_node("MemorySparkCard"))
	_assert_memory_spark_data_is_derived_from_hotspots(main)
	_assert_world_hotspot_enablement_baseline(town_map)
	_assert_quest_diary_layout(main.get_node("QuestDiary"))
	_assert_parent_summary_layout(main.get_node("ParentSummary"))
	_assert_home_pet_layout(main.get_node("TownMap"))
	_assert_school_subscene_backgrounds(main.get_node("TownMap"))
	_assert_place_card_layout(main.get_node("PlaceCard"))
	_assert_child_visible_copy_baseline(main)
	_assert_child_data_source_copy_baseline()
	_assert_generated_assets_present()
	_assert_world_overview_assets_present()
	_assert_anchor_dialogues_complete()
	_assert_no_generated_asset_safety_risk()

	print("MVP 0.2 visual acceptance smoke passed.")
	quit(0)


func _assert_marker_center_in_click_rect(town_map: Node, node_path: String, target_id: String) -> void:
	var marker: Node2D = town_map.get_node(node_path)
	var click_game: Node = town_map.get_node("ClickGame")
	var rects: Dictionary = click_game.get_place_rects_for_scene("campus_gate")
	_assert(rects.has(target_id), "missing click rect for %s" % target_id)
	_assert(rects[target_id].has_point(marker.global_position), "click rect should cover %s visual center" % target_id)


func _assert_garden_bird_in_click_rect(town_map: Node) -> void:
	var bird: Polygon2D = town_map.get_node("GardenLayer/Bird")
	var click_game: Node = town_map.get_node("ClickGame")
	var rects: Dictionary = click_game.get_place_rects_for_scene("garden")
	_assert(rects.has("bird"), "missing click rect for bird")
	var bounds := Rect2(bird.polygon[0], Vector2.ZERO)
	for point: Vector2 in bird.polygon:
		bounds = bounds.expand(point)
	_assert(rects["bird"].has_point(bounds.get_center()), "bird click rect should cover bird center")


func _assert_garden_target_in_click_rect(town_map: Node, node_path: String, target_id: String) -> void:
	var visual: Control = town_map.get_node(node_path)
	var click_game: Node = town_map.get_node("ClickGame")
	var rects: Dictionary = click_game.get_place_rects_for_scene("garden")
	_assert(rects.has(target_id), "missing click rect for %s" % target_id)
	_assert(rects[target_id].has_point(visual.global_position + visual.size * 0.5), "click rect should cover %s visual center" % target_id)


func _assert_boundaries_present(town_map: Node) -> void:
	for wall_name in ["TopWall", "BottomWall", "LeftWall", "RightWall"]:
		var wall: StaticBody2D = town_map.get_node("Boundaries/%s" % wall_name)
		_assert(wall.get_child_count() > 0, "%s should have collision" % wall_name)


func _assert_player_outfit_layer(town_map: Node) -> void:
	var explorer_cape: Polygon2D = _required_node(town_map, "Player/ExplorerCape")
	var sprite: Sprite2D = _required_node(town_map, "Player/Sprite")
	_assert(not explorer_cape.visible, "explorer cape should start hidden before outfit purchase")
	_assert(explorer_cape.z_index < sprite.z_index, "explorer cape should render behind the player sprite")
	_assert(explorer_cape.polygon.size() >= 3, "explorer cape should have visible polygon points")


func _assert_npc_dialogues_short() -> void:
	for dialogue_id in ["mina_letter_box_intro", "mina_home_intro", "mina_intro", "leo_room_intro", "nora_garden_intro"]:
		var file: FileAccess = FileAccess.open("res://data/dialogues/%s.json" % dialogue_id, FileAccess.READ)
		_assert(file != null, "dialogue should exist: %s" % dialogue_id)
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		_assert(typeof(parsed) == TYPE_DICTIONARY, "dialogue should parse: %s" % dialogue_id)
		for line: Dictionary in parsed.get("lines", []):
			var text: String = str(line.get("text", ""))
			_assert(text.length() <= 88, "dialogue line too long in %s: %s" % [dialogue_id, text])
			for phrase in ["Welcome to our school", "school garden", "This is our classroom"]:
				_assert(not text.contains(phrase), "NPC dialogue should avoid school-app wording in %s: %s" % [dialogue_id, text])


func _assert_drag_targets_large_enough(drag_game: Node) -> void:
	_assert(drag_game.TARGET_SIZE.x >= 140.0, "drag target width should be child-friendly")
	_assert(drag_game.TARGET_SIZE.y >= 80.0, "drag target height should be child-friendly")
	for item_id in drag_game.ITEM_DEFS:
		var item_def: Dictionary = drag_game.ITEM_DEFS[item_id]
		var target_id: String = str(item_def["target"])
		_assert(drag_game.TARGET_DEFS.has(target_id), "item target should exist: %s" % item_id)


func _assert_review_read_aloud_timers(story_show: Node) -> void:
	var read_prompts: Array[Dictionary] = []
	for prompt: Dictionary in story_show.prompts:
		if prompt.get("mode", "") == "read_aloud":
			read_prompts.append(prompt)
	_assert(read_prompts.size() == 6, "review should have 6 timed read-aloud prompts")
	if read_prompts.size() != 6:
		return
	_assert(float(read_prompts[0]["read_seconds"]) == 5.0, "first read prompt should be 5 seconds")
	_assert(float(read_prompts[1]["read_seconds"]) == 5.0, "second read prompt should be 5 seconds")
	_assert(float(read_prompts[2]["read_seconds"]) == 5.0, "third read prompt should be 5 seconds")
	_assert(float(read_prompts[3]["read_seconds"]) == 5.0, "fourth read prompt should be 5 seconds")
	_assert(float(read_prompts[4]["read_seconds"]) == 5.0, "fifth read prompt should be 5 seconds")
	_assert(float(read_prompts[5]["read_seconds"]) == 5.0, "sixth read prompt should be 5 seconds")


func _assert_review_layout(story_show: CanvasLayer) -> void:
	var panel: Panel = _required_node(story_show, "Panel")
	_assert(panel.size.x >= 560.0, "review panel should be wide enough for sentence choices")
	_assert(panel.size.y >= 380.0, "review panel should be tall enough for 25-prompt flow")
	var prompt_label: Label = _required_node(story_show, "Panel/MarginContainer/VBoxContainer/PromptLabel")
	var feedback_label: Label = _required_node(story_show, "Panel/MarginContainer/VBoxContainer/FeedbackLabel")
	_assert(prompt_label.autowrap_mode != TextServer.AUTOWRAP_OFF, "review prompt should wrap text")
	_assert(feedback_label.autowrap_mode != TextServer.AUTOWRAP_OFF, "review feedback should wrap text")
	var choices_grid: GridContainer = _required_node(story_show, "Panel/MarginContainer/VBoxContainer/ChoicesGrid")
	_assert(choices_grid.columns == 3, "review choices should keep predictable 3-column layout")
	for prompt: Dictionary in story_show.prompts:
		var prompt_text := str(prompt.get("prompt", ""))
		_assert(prompt_text.length() <= 64, "Story Show prompt should stay concise: %s" % prompt_text)
		_assert_story_show_prompt_tone(prompt_text)
		for choice: String in prompt.get("choices", []):
			_assert(choice.length() <= 42, "review choice should stay readable: %s" % choice)
	story_show.start_review()
	_assert(choices_grid.get_child_count() > 0, "review should create choice buttons")
	var title_label: Label = _required_node(story_show, "Panel/MarginContainer/VBoxContainer/TitleLabel")
	_assert(title_label.text == "Story Show", "review title should use current visible naming")
	if choices_grid.get_child_count() <= 0:
		return
	var first_button: Button = choices_grid.get_child(0)
	_assert(first_button.custom_minimum_size.x >= 150.0, "review choice button should be wide enough")
	_assert(first_button.custom_minimum_size.y >= 46.0, "review choice button should be tall enough")
	story_show.visible = false


func _assert_story_show_prompt_tone(prompt_text: String) -> void:
	for phrase in ["Find the word", "Choose:", "Choose the", "Which word means", "Round 2", "Read aloud:", "library card", "school place", "library scene"]:
		_assert(not prompt_text.contains(phrase), "Story Show prompt should avoid exercise wording: %s" % prompt_text)


func _assert_dialogue_layout(dialogue_box: CanvasLayer) -> void:
	var panel: Panel = _required_node(dialogue_box, "Panel")
	_assert(panel.size.x >= 760.0, "dialogue panel should be wide enough")
	_assert(panel.size.y >= 120.0, "dialogue panel should be tall enough")
	var body_label: Label = _required_node(dialogue_box, "Panel/MarginContainer/VBoxContainer/BodyLabel")
	_assert(body_label.autowrap_mode != TextServer.AUTOWRAP_OFF, "dialogue body should wrap text")


func _assert_memory_spark_layout(memory_spark_card: CanvasLayer) -> void:
	var panel: Panel = _required_node(memory_spark_card, "Panel")
	_assert(panel.size.x >= 500.0, "Memory Spark panel should be wide enough")
	_assert(panel.size.y >= 320.0, "Memory Spark panel should be tall enough for ornament plus choices")
	var prompt_label: Label = _required_node(memory_spark_card, "Panel/MarginContainer/VBoxContainer/PromptLabel")
	var reward_label: Label = _required_node(memory_spark_card, "Panel/MarginContainer/VBoxContainer/RewardLabel")
	var feedback_label: Label = _required_node(memory_spark_card, "Panel/MarginContainer/VBoxContainer/FeedbackLabel")
	var choices_grid: GridContainer = _required_node(memory_spark_card, "Panel/MarginContainer/VBoxContainer/ChoicesGrid")
	var title_label: Label = _required_node(memory_spark_card, "Panel/MarginContainer/VBoxContainer/TitleLabel")
	var ornament_texture: TextureRect = _required_node(memory_spark_card, "Panel/MarginContainer/VBoxContainer/OrnamentTexture")
	_assert(ornament_texture.texture != null, "Memory Spark ornament texture should be connected")
	_assert(ornament_texture.custom_minimum_size.x >= 44.0, "Memory Spark ornament should keep a stable cell")
	_assert(title_label.text == "Memory Spark", "Memory Spark card should use child-facing naming")
	_assert(prompt_label.autowrap_mode != TextServer.AUTOWRAP_OFF, "Memory Spark prompt should wrap text")
	_assert(reward_label.autowrap_mode != TextServer.AUTOWRAP_OFF, "Memory Spark reward should wrap text")
	_assert(feedback_label.autowrap_mode != TextServer.AUTOWRAP_OFF, "Memory Spark feedback should wrap text")
	_assert(choices_grid.columns == 3, "Memory Spark should keep a predictable 3-choice layout")
	_assert(prompt_label.text.contains("What comes back?"), "Memory Spark should use memory-palace wording")
	_assert(not prompt_label.text.contains("anchor"), "memory spark prompt should not expose internal anchor jargon")
	_assert(not reward_label.text.contains("first recall"), "memory spark reward should avoid mechanism wording")
	_assert(feedback_label.text.contains("picture clue"), "Memory Spark should point to the visual picture clue")


func _assert_quest_diary_layout(quest_diary: CanvasLayer) -> void:
	var panel: Panel = _required_node(quest_diary, "Panel")
	_assert(panel.size.x >= 420.0, "Quest Diary panel should be wide enough for event status")
	_assert(panel.size.y >= 220.0, "Quest Diary panel should be tall enough for event status")
	var ornament_texture: TextureRect = _required_node(quest_diary, "Panel/MarginContainer/VBoxContainer/OrnamentTexture")
	var title_label: Label = _required_node(quest_diary, "Panel/MarginContainer/VBoxContainer/TitleLabel")
	var event_label: Label = _required_node(quest_diary, "Panel/MarginContainer/VBoxContainer/EventLabel")
	var status_label: Label = _required_node(quest_diary, "Panel/MarginContainer/VBoxContainer/StatusLabel")
	var words_label: Label = _required_node(quest_diary, "Panel/MarginContainer/VBoxContainer/WordsLabel")
	var prompt_label: Label = _required_node(quest_diary, "Panel/MarginContainer/VBoxContainer/PromptLabel")
	var reward_label: Label = _required_node(quest_diary, "Panel/MarginContainer/VBoxContainer/RewardLabel")
	var feedback_label: Label = _required_node(quest_diary, "Panel/MarginContainer/VBoxContainer/FeedbackLabel")
	_assert(ornament_texture.texture != null, "Quest Diary ornament texture should be connected")
	_assert(ornament_texture.custom_minimum_size.x >= 44.0, "Quest Diary ornament should keep a stable cell")
	_assert(title_label.text == "Quest Diary", "Quest Diary title should use current front-end naming")
	_assert(event_label.autowrap_mode != TextServer.AUTOWRAP_OFF, "Quest Diary event name should wrap text")
	_assert(status_label.autowrap_mode != TextServer.AUTOWRAP_OFF, "Quest Diary status should wrap text")
	_assert(prompt_label.autowrap_mode != TextServer.AUTOWRAP_OFF, "quest prompt should wrap text")
	_assert(words_label.autowrap_mode != TextServer.AUTOWRAP_OFF, "quest clues should wrap text")
	_assert(reward_label.autowrap_mode != TextServer.AUTOWRAP_OFF, "Quest Diary keepsake hint should wrap text")
	_assert(feedback_label.autowrap_mode != TextServer.AUTOWRAP_OFF, "quest feedback should wrap text")
	_assert(words_label.text.begins_with("Quest clues:"), "Quest Diary should not show vocabulary as a Look for list")
	_assert(not words_label.text.begins_with("Look for:"), "Quest Diary should avoid word-list drill wording")


func _assert_parent_summary_layout(parent_summary: CanvasLayer) -> void:
	var panel: Panel = _required_node(parent_summary, "Panel")
	var size := panel.size
	_assert(size.x >= 460.0, "parent summary panel should be wide enough")
	_assert(size.y >= 380.0, "parent summary panel should be tall enough")
	var scroll_container: ScrollContainer = _required_node(parent_summary, "Panel/MarginContainer/VBoxContainer/ScrollContainer")
	_assert(scroll_container.size.y >= 300.0, "parent summary scroll area should stay tall enough")
	for label_path in [
		"Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/WordsValue",
		"Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/StatsGrid/RewardsValue",
		"Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/StatsGrid/ParentBonusValue",
		"Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/QuestsValue",
		"Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/PatternsValue",
		"Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/ReviewValue",
		"Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/TimelineValue",
		"Panel/MarginContainer/VBoxContainer/ReportStatusValue"
	]:
		var label: Label = _required_node(parent_summary, label_path)
		_assert(label.autowrap_mode != TextServer.AUTOWRAP_OFF, "%s should wrap text" % label_path)
	for button_path in [
		"Panel/MarginContainer/VBoxContainer/FinishReadingButton",
		"Panel/MarginContainer/VBoxContainer/ParentBonusButton",
		"Panel/MarginContainer/VBoxContainer/ExportReportButton"
	]:
		var button: Button = _required_node(parent_summary, button_path)
		_assert(button.custom_minimum_size.y >= 46.0, "%s should meet minimum touch height" % button_path)


func _assert_home_pet_layout(town_map: Node) -> void:
	var pet_panel: Panel = _required_node(town_map, "HomeLayer/PetPanel")
	_assert(pet_panel.size.x >= 360.0, "home pet panel should be wide enough")
	_assert(pet_panel.size.y >= 320.0, "home pet panel should be tall enough")
	var pet_corner_label: Label = _required_node(town_map, "HomeLayer/PetCorner/PetCornerLabel")
	var home_background_slot: Sprite2D = _required_node(town_map, "HomeLayer/HomeBackgroundSlot")
	var pet_name_value: Label = _required_node(town_map, "HomeLayer/PetPanel/MarginContainer/VBoxContainer/StatsGrid/PetNameValue")
	var feedback_label: Label = _required_node(town_map, "HomeLayer/PetPanel/MarginContainer/VBoxContainer/FeedbackLabel")
	var pet_state_value: Label = _required_node(town_map, "HomeLayer/PetPanel/MarginContainer/VBoxContainer/StatsGrid/PetStateValue")
	var outfit_value: Label = _required_node(town_map, "HomeLayer/PetPanel/MarginContainer/VBoxContainer/StatsGrid/OutfitValue")
	var room_decor_value: Label = _required_node(town_map, "HomeLayer/PetPanel/MarginContainer/VBoxContainer/StatsGrid/RoomDecorValue")
	var pet_bowl: TextureRect = _required_node(town_map, "HomeLayer/PetCorner/PetBowl")
	var pet_food: TextureRect = _required_node(town_map, "HomeLayer/PetCorner/PetFood")
	var pet_toy: TextureRect = _required_node(town_map, "HomeLayer/PetCorner/PetToy")
	var pet_soap: TextureRect = _required_node(town_map, "HomeLayer/PetCorner/PetSoap")
	var pet_state_display: Sprite2D = _required_node(town_map, "HomeLayer/PetCorner/PetStateDisplay")
	var decor_slot_rug: Sprite2D = _required_node(town_map, "HomeLayer/DecorSlot_Rug")
	var decor_slot_cape: Sprite2D = _required_node(town_map, "HomeLayer/DecorSlot_Cape")
	var room_explore_button: Button = _required_node(town_map, "HomeLayer/RoomExploreButton")
	var room_explore_panel: Panel = _required_node(town_map, "HomeLayer/RoomExplorePanel")
	var home_lamp: Sprite2D = _required_node(town_map, "HomeLayer/HomeSpaces/HomeLampProp")
	var home_clock: Sprite2D = _required_node(town_map, "HomeLayer/HomeSpaces/HomeClockProp")
	var home_window: Sprite2D = _required_node(town_map, "HomeLayer/HomeSpaces/HomeWindowProp")
	var bedroom_label: Label = _required_node(town_map, "HomeLayer/HomeSpaces/BedroomLabel")
	var kitchen_label: Label = _required_node(town_map, "HomeLayer/HomeSpaces/KitchenLabel")
	var yard_label: Label = _required_node(town_map, "HomeLayer/HomeSpaces/YardLabel")
	var pet_corner_space_label: Label = _required_node(town_map, "HomeLayer/HomeSpaces/PetCornerSpaceLabel")
	_assert(pet_corner_label.text.contains("corner"), "home should include a visible pet corner label")
	_assert(home_background_slot.visible, "home background slot should be visible after generated art is connected")
	_assert(home_background_slot.texture != null, "home background slot should use generated home interior art")
	_assert(pet_bowl.texture != null, "home pet bowl prop texture should be connected")
	_assert(pet_food.texture != null, "home pet food prop texture should be connected")
	_assert(pet_toy.texture != null, "home pet toy prop texture should be connected")
	_assert(pet_soap.texture != null, "home pet soap prop texture should be connected")
	_assert(pet_state_display.texture != null, "home pet visual state texture should be connected at runtime")
	_assert(pet_state_display.texture.resource_path == "res://assets/generated/characters/pet/pet_mood_neutral_v001.png", "default pet visual should use generated neutral pet art")
	_assert(not decor_slot_rug.visible, "star rug decor should start hidden before purchase")
	_assert(decor_slot_rug.texture != null, "star rug decor slot should have generated art assigned")
	_assert(not decor_slot_cape.visible, "cape display should start hidden before purchase")
	_assert(decor_slot_cape.texture != null, "cape decor slot should have generated art assigned")
	_assert(home_lamp.texture != null, "home lamp prop texture should be connected")
	_assert(home_clock.texture != null, "home clock prop texture should be connected")
	_assert(home_window.texture != null, "home window prop texture should be connected")
	_assert(room_explore_button.visible, "Room Finds button should be visible at home")
	_assert(room_explore_button.custom_minimum_size.y >= 46.0 or room_explore_button.size.y >= 46.0, "Room Finds button should meet minimum touch height")
	_assert(not room_explore_panel.visible, "Room Finds panel should start closed")
	_assert(pet_name_value.text == "Sunny", "home pet panel should include the starter pet name")
	_assert(feedback_label.autowrap_mode != TextServer.AUTOWRAP_OFF, "home pet feedback should wrap text")
	_assert(pet_state_value.autowrap_mode != TextServer.AUTOWRAP_OFF, "home pet state should wrap text")
	_assert(outfit_value.autowrap_mode != TextServer.AUTOWRAP_OFF, "home outfit status should wrap text")
	_assert(room_decor_value.autowrap_mode != TextServer.AUTOWRAP_OFF, "home room decor status should wrap text")
	_assert(bedroom_label.text == "Bedroom", "home should expose a bedroom section")
	_assert(kitchen_label.text == "Kitchen", "home should expose a kitchen section")
	_assert(yard_label.text == "Yard", "home should expose a yard section")
	_assert(pet_corner_space_label.text == "Pet Corner", "home should expose a pet corner section")
	var home_rects: Dictionary = town_map.get_node("ClickGame").get_place_rects_for_scene("home")
	for target_id in ["home_door", "home_kitchen", "home_yard", "home_pet_toy", "home_pet_bed", "home_lamp", "home_clock", "home_window"]:
		_assert(home_rects.has(target_id), "home expanded space target should come from scene_click_targets data: %s" % target_id)
	for button_path in [
		"HomeLayer/PetPanel/MarginContainer/VBoxContainer/ActionButtons/FeedButton",
		"HomeLayer/PetPanel/MarginContainer/VBoxContainer/ActionButtons/CleanButton",
		"HomeLayer/PetPanel/MarginContainer/VBoxContainer/ActionButtons/PlayButton",
		"HomeLayer/PetPanel/MarginContainer/VBoxContainer/ActionButtons/RestButton",
		"HomeLayer/ReturnButton"
	]:
		var button: Button = _required_node(town_map, button_path)
		_assert(button.custom_minimum_size.y >= 46.0 or button.size.y >= 46.0, "%s should meet minimum touch height" % button_path)


func _assert_school_subscene_backgrounds(town_map: Node) -> void:
	var classroom_background: Sprite2D = _required_node(town_map, "ClassroomLayer/Background")
	var garden_background: Sprite2D = _required_node(town_map, "GardenLayer/Background")
	_assert(classroom_background.texture != null, "classroom should use generated background art")
	_assert(garden_background.texture != null, "garden should use generated background art")
	_assert(classroom_background.texture.resource_path == "res://assets/generated/maps/classroom/map_classroom_interior_v002.png", "classroom should use v002 generated background")
	_assert(garden_background.texture.resource_path == "res://assets/generated/maps/garden/map_garden_bg_v002.png", "garden should use v002 generated background")
	var classroom_image := classroom_background.texture.get_image()
	var garden_image := garden_background.texture.get_image()
	_assert(classroom_image.get_width() == 1280 and classroom_image.get_height() == 720, "classroom background should be 1280x720")
	_assert(garden_image.get_width() == 1280 and garden_image.get_height() == 720, "garden background should be 1280x720")
	var classroom_floor: ColorRect = _required_node(town_map, "ClassroomLayer/ClassroomFloor")
	var garden_grass: ColorRect = _required_node(town_map, "GardenLayer/GardenGrass")
	_assert(classroom_floor.color.a <= 0.01, "classroom ColorRect should not be the visible main background")
	_assert(garden_grass.color.a <= 0.01, "garden ColorRect should not be the visible main background")


func _assert_place_card_layout(place_card: CanvasLayer) -> void:
	var panel: Panel = _required_node(place_card, "Panel")
	_assert(panel.size.x >= 460.0, "place card panel should be wide enough")
	_assert(panel.size.y >= 200.0, "place card panel should be tall enough")
	var place_label: Label = _required_node(place_card, "Panel/MarginContainer/VBoxContainer/PlaceLabel")
	var hint_label: Label = _required_node(place_card, "Panel/MarginContainer/VBoxContainer/HintLabel")
	var reward_label: Label = _required_node(place_card, "Panel/MarginContainer/VBoxContainer/RewardLabel")
	var action_button: Button = _required_node(place_card, "Panel/MarginContainer/VBoxContainer/ActionButton")
	var ornament_texture: TextureRect = _required_node(place_card, "Panel/MarginContainer/VBoxContainer/OrnamentTexture")
	_assert(ornament_texture.texture != null, "PlaceCard ornament texture should be connected")
	_assert(ornament_texture.custom_minimum_size.x >= 44.0, "PlaceCard ornament should keep a stable cell")
	_assert(place_label.autowrap_mode != TextServer.AUTOWRAP_OFF, "place card place label should wrap text")
	_assert(hint_label.autowrap_mode != TextServer.AUTOWRAP_OFF, "place card hint should wrap text")
	_assert(reward_label.autowrap_mode != TextServer.AUTOWRAP_OFF, "place card reward should wrap text")
	_assert(action_button.custom_minimum_size.y >= 46.0, "place card action button should meet minimum touch height")


func _assert_child_visible_copy_baseline(main: Node) -> void:
	var child_roots: Array[Node] = [
		main.get_node("TownMap"),
		main.get_node("QuestDiary"),
		main.get_node("DialogueBox"),
		main.get_node("RewardPopup"),
		main.get_node("StoryShow"),
		main.get_node("PlaceCard"),
		main.get_node("MemorySparkCard"),
		main.get_node("DragPlaceGame")
	]
	_assert_no_child_visible_banned_copy(child_roots, "initial child UI")

	var quest_diary: CanvasLayer = main.get_node("QuestDiary")
	if quest_diary.has_method("start_quest"):
		quest_diary.start_quest("prologue_go_to_school")
	_assert_no_child_visible_banned_copy(child_roots, "Quest Diary active")
	quest_diary.visible = false

	var story_show: CanvasLayer = main.get_node("StoryShow")
	if story_show.has_method("start_review"):
		story_show.start_review()
	_assert_no_child_visible_banned_copy(child_roots, "Story Show active")
	story_show.visible = false

	var memory_spark_card: CanvasLayer = main.get_node("MemorySparkCard")
	if memory_spark_card.has_method("show_spark"):
		memory_spark_card.show_spark("anchor_b_bear", {
			"prompt": "Look at letter B. What comes back?",
			"choices": ["Bear", "Gate", "Hat"],
			"answer": "Bear",
			"reward_coins": 1
		})
	_assert_no_child_visible_banned_copy(child_roots, "Memory Spark active")
	memory_spark_card.visible = false


func _assert_no_child_visible_banned_copy(roots: Array[Node], context: String) -> void:
	var texts := _collect_child_visible_texts(roots)
	for item: Dictionary in texts:
		_assert_child_visible_text_allowed(
			str(item.get("text", "")),
			"%s at %s" % [context, str(item.get("path", ""))]
		)


func _assert_child_visible_text_allowed(text: String, context: String) -> void:
	var banned_exact := [
		"QuestDiary",
		"Task Panel",
		"StoryShow",
		"Review Challenge",
		"Anchor Recall",
		"School Tour",
		"校园导览",
		"Look for:",
		"memory_anchor",
		"anchor_recall",
		"story_flag",
		"task_id",
		"review_id",
		"scene_id",
		"mvp_0_2",
		"lesson_id",
		"completed_tasks",
		"completed_reviews",
		"vocabulary_cluster",
		"pilot_recall",
		"QA",
		"TODO",
		"WIP",
		"uid://",
		"res://",
		"user://",
		".json",
		".gd",
		".tscn"
	]
	var banned_case_insensitive := [
		"lesson panel",
		"word list",
		"word-list",
		"review test",
		"school app",
		"find the word",
		"read aloud:",
		"library card",
		"school place",
		"first recall",
		"memory_anchor",
		"anchor_recall",
		"hotspot",
		"story_flag",
		"task_id",
		"review_id",
		"scene_id",
		"mvp_0_2",
		"debug",
		"snapshot",
		"export report",
		"timing report",
		"playtest",
		"fixture",
		"validator",
		"schema",
		"elapsed_msec",
		"manual_result",
		"assert",
		"error:"
	]
	var banned_token_case_insensitive := [
		"anchor",
		"recall",
		"hotspot",
		"flag",
		"lesson",
		"review",
		"report"
	]
	for phrase: String in banned_exact:
		_assert(not text.contains(phrase), "%s should not expose '%s': %s" % [context, phrase, text])
	var lower_text := text.to_lower()
	for phrase: String in banned_case_insensitive:
		_assert(not lower_text.contains(phrase), "%s should not expose '%s': %s" % [context, phrase, text])
	for token: String in banned_token_case_insensitive:
		_assert(not _contains_token(lower_text, token), "%s should not expose token '%s': %s" % [context, token, text])
	for shorthand: String in ["L1", "L2", "L3"]:
		_assert(not _contains_token(text, shorthand), "%s should not expose lesson shorthand %s: %s" % [context, shorthand, text])


func _assert_child_data_source_copy_baseline() -> void:
	_assert_dialogue_visible_copy_baseline()
	_assert_quest_visible_copy_baseline()
	_assert_hotspot_visible_copy_baseline()
	_assert_place_card_controller_copy_baseline()


func _assert_dialogue_visible_copy_baseline() -> void:
	for path: String in _collect_files_recursive("res://data/dialogues"):
		if not path.ends_with(".json"):
			continue
		var dialogue := _read_json_dict(path)
		_assert_child_visible_text_allowed(str(dialogue.get("speaker", "")), "dialogue speaker %s" % path)
		var lines_variant: Variant = dialogue.get("lines", [])
		if typeof(lines_variant) != TYPE_ARRAY:
			continue
		for line_variant: Variant in lines_variant:
			if typeof(line_variant) != TYPE_DICTIONARY:
				continue
			var line: Dictionary = line_variant
			_assert_child_visible_text_allowed(str(line.get("speaker", "")), "dialogue line speaker %s" % path)
			_assert_child_visible_text_allowed(str(line.get("text", "")), "dialogue line text %s" % path)


func _assert_quest_visible_copy_baseline() -> void:
	for path: String in _collect_files_recursive("res://data/quests"):
		if not path.ends_with(".json"):
			continue
		var quest := _read_json_dict(path)
		for field: String in ["title", "prompt", "wrong_target_text", "success_text", "reward_name", "start_feedback"]:
			if quest.has(field):
				_assert_child_visible_text_allowed(str(quest.get(field, "")), "quest data visible field %s in %s" % [field, path])
		for field: String in ["vocabulary", "patterns"]:
			var values_variant: Variant = quest.get(field, [])
			if typeof(values_variant) != TYPE_ARRAY:
				continue
			for value: Variant in values_variant:
				_assert_child_visible_text_allowed(str(value), "quest data visible array %s in %s" % [field, path])
		var target_labels_variant: Variant = quest.get("target_labels", {})
		if typeof(target_labels_variant) == TYPE_DICTIONARY:
			var target_labels: Dictionary = target_labels_variant
			for value: Variant in target_labels.values():
				_assert_child_visible_text_allowed(str(value), "quest target label in %s" % path)


func _assert_hotspot_visible_copy_baseline() -> void:
	var map_data := _read_json_dict("res://data/maps/sunshine_world_hotspots_v001.json")
	var hotspots_variant: Variant = map_data.get("hotspots", [])
	_assert(typeof(hotspots_variant) == TYPE_ARRAY, "world hotspot data should expose hotspot array")
	var hotspots: Array = hotspots_variant
	for hotspot_variant: Variant in hotspots:
		if typeof(hotspot_variant) != TYPE_DICTIONARY:
			continue
		var hotspot: Dictionary = hotspot_variant
		for field: String in ["label", "keyword", "display_label"]:
			if hotspot.has(field):
				_assert_child_visible_text_allowed(str(hotspot.get(field, "")), "hotspot visible field %s" % field)
		var cluster_variant: Variant = hotspot.get("vocabulary_cluster", [])
		if typeof(cluster_variant) != TYPE_ARRAY:
			continue
		for value: Variant in cluster_variant:
			_assert_child_visible_text_allowed(str(value), "hotspot vocabulary cluster")


func _assert_place_card_controller_copy_baseline() -> void:
	var visible_samples := [
		"Books, read, library.",
		"Eat, drink, and say hello.",
		"Watch, listen, and enjoy.",
		"Go, ride, and wait.",
		"Train, ticket, and travel.",
		"Fly, travel, and explore.",
		"Send letters and packages.",
		"Help, care, and heal.",
		"Buy food and daily things.",
		"Buy toys and care things for your pet.",
		"Choose clothes, colors, and a brave look.",
		"Choose cozy things for your room.",
		"You found a new town place.",
		"Buy Pet Bowl (3)",
		"Buy Pet Ball (2)",
		"Buy Explorer Cape (1 Parent Bonus)",
		"Buy Star Rug (4)",
		"Help Find a Book",
		"Bookshop Helper",
		"Bookshop Leafmark",
		"Help the reading bear find a book.",
		"Choose Town Route",
		"Town route marked: +1 coin.",
		"Take the bus to town."
	]
	for text: String in visible_samples:
		_assert_child_visible_text_allowed(text, "place card visible copy sample")


func _collect_child_visible_texts(roots: Array[Node]) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for root_node: Node in roots:
		_collect_child_visible_texts_into(root_node, results)
	return results


func _collect_child_visible_texts_into(node: Node, results: Array[Dictionary]) -> void:
	if node is CanvasItem and not (node as CanvasItem).is_visible_in_tree():
		return
	var text := ""
	if node is Label:
		text = (node as Label).text
	elif node is Button:
		text = (node as Button).text
	if not text.strip_edges().is_empty():
		results.append({
			"path": str(node.get_path()),
			"text": text
		})
	for child: Node in node.get_children():
		_collect_child_visible_texts_into(child, results)


func _contains_token(text: String, token: String) -> bool:
	var regex := RegEx.new()
	regex.compile("(^|[^A-Za-z0-9_])%s([^A-Za-z0-9_]|$)" % token)
	return regex.search(text) != null


func _assert_world_hotspot_enablement_baseline(town_map: Node) -> void:
	var click_game: Node = town_map.get_node("ClickGame")
	var world_rects: Dictionary = click_game.get_place_rects_for_scene("world_overview")
	_assert(not world_rects.has("music_room"), "music room should not yet be world-clickable without a route")
	_assert(not world_rects.has("art_room"), "art room should not yet be world-clickable without a route")
	_assert(not world_rects.has("tree"), "tree should stay hidden outside event-driven world enablement")
	_assert(not world_rects.has("flower"), "flower should stay hidden outside event-driven world enablement")
	_assert(not world_rects.has("bench"), "bench should stay hidden outside event-driven world enablement")
	_assert(not world_rects.has("bird"), "bird should stay hidden outside event-driven world enablement")
	_assert(world_rects.has("pet_shop"), "pet shop should be world-clickable as the second starter spend loop")
	_assert(world_rects.has("clothes_shop"), "clothes shop should be world-clickable as the Parent Bonus outfit spend loop")
	_assert(world_rects.has("general_store"), "general store should be world-clickable as the room decor spend loop")


func _assert_no_generated_asset_safety_risk() -> void:
	var generated_path := "res://assets/generated"
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(generated_path)):
		return
	var risk_terms := ["barbie", "disney", "pixar", "sanrio", "logo", "trademark"]
	for file_name: String in _collect_files_recursive(generated_path):
		var lower_name := file_name.to_lower()
		for term: String in risk_terms:
			_assert(not lower_name.contains(term), "generated asset filename contains risk term: %s" % file_name)


func _assert_generated_assets_present() -> void:
	for path in [
			"res://assets/generated/maps/school_arrival/map_school_arrival_bg_v002.png",
			"res://assets/generated/maps/home/map_home_interior_bg_v001.png",
			"res://assets/generated/maps/classroom/map_classroom_interior_v002.png",
			"res://assets/generated/maps/garden/map_garden_bg_v002.png",
			"res://assets/generated/maps/classroom/map_classroom_bg_v001.png",
		"res://assets/generated/maps/garden/map_garden_bg_v001.png",
		"res://assets/generated/characters/player/char_player_walk_v001.png",
		"res://assets/generated/characters/npcs/char_mina_sprite_v001.png",
		"res://assets/generated/characters/npcs/char_leo_sprite_v001.png",
		"res://assets/generated/characters/npcs/char_nora_sprite_v001.png",
		"res://assets/generated/props/room/prop_book_v001.png",
		"res://assets/generated/props/room/prop_pencil_v001.png",
		"res://assets/generated/props/room/prop_schoolbag_blue_v001.png",
		"res://assets/generated/rewards/reward_adventure_star_piece_v001.png",
		"res://assets/generated/rewards/reward_first_trip_ticket_v001.png",
		"res://assets/generated/rewards/reward_tidy_badge_piece_v001.png",
		"res://assets/generated/rewards/reward_garden_leaf_piece_v001.png",
		"res://assets/generated/props/home/prop_pet_bowl_v001.png",
		"res://assets/generated/props/home/prop_pet_food_v001.png",
		"res://assets/generated/props/home/prop_pet_toy_v001.png",
		"res://assets/generated/props/home/prop_soap_v001.png",
		"res://assets/generated/characters/pet/pet_mood_happy_v001.png",
		"res://assets/generated/characters/pet/pet_mood_neutral_v001.png",
		"res://assets/generated/characters/pet/pet_mood_sleepy_v001.png",
		"res://assets/generated/characters/pet/pet_action_eating_v001.png",
		"res://assets/generated/characters/pet/pet_action_playing_v001.png",
		"res://assets/generated/characters/pet/pet_action_sleeping_v001.png",
		"res://assets/generated/props/room/prop_lamp_v001.png",
		"res://assets/generated/props/room/prop_clock_v001.png",
		"res://assets/generated/props/room/prop_window_v001.png",
		"res://assets/generated/props/home/prop_star_rug_placed_v001.png",
		"res://assets/generated/props/home/prop_explorer_cape_display_v001.png",
		"res://assets/generated/characters/npcs/char_ava_portrait_neutral_v001.png",
		"res://assets/generated/ui/ui_place_card_ornament_v001.png",
		"res://assets/generated/ui/ui_quest_diary_ornament_v001.png",
		"res://assets/generated/ui/ui_memory_spark_ornament_v001.png",
		"res://assets/source_prompts/maps/map_backgrounds_v001.md",
		"res://assets/source_prompts/maps/school_subscene_backgrounds_v002.md",
		"res://assets/source_prompts/characters/character_sprites_v001.md",
		"res://assets/source_prompts/characters/pet_visual_states_v001.md",
		"res://assets/source_prompts/characters/npc_portraits_v001.md",
		"res://assets/source_prompts/props/home_room_explore_props_v001.md",
		"res://assets/source_prompts/props/home_decor_props_v001.md",
		"res://assets/source_prompts/props/icon_atlas_v001.md"
	]:
		_assert(FileAccess.file_exists(path), "generated asset or prompt should exist: %s" % path)
	var reward_icon_data := _read_json_dict("res://data/rewards/reward_icons_v001.json")
	var reward_icons: Dictionary = reward_icon_data.get("icons", {})
	_assert(str(reward_icons.get("first_trip_ticket", "")) == "res://assets/generated/rewards/reward_first_trip_ticket_v001.png", "First Trip Ticket should use its own reward icon")
	_assert(str(reward_icons.get("first_trip_ticket", "")) != str(reward_icons.get("school_star_piece", "")), "First Trip Ticket should not reuse Adventure Star icon")
	_assert(str(reward_icons.get("bookshop_leafmark", "")) != str(reward_icons.get("school_star_piece", "")), "Bookshop Leafmark should not reuse Adventure Star icon")


func _assert_world_overview_assets_present() -> void:
	var world_overview_path := "res://assets/generated/maps/world/map_sunshine_world_overview_v001.png"
	_assert(FileAccess.file_exists(world_overview_path), "world overview asset should exist: %s" % world_overview_path)
	var world_texture := load(world_overview_path)
	_assert(world_texture != null, "world overview texture should load: %s" % world_overview_path)
	_assert(world_texture is Texture2D, "world overview asset should load as Texture2D")
	var world_image: Image = (world_texture as Texture2D).get_image()
	_assert(world_image != null, "world overview texture should expose image data")
	_assert(world_image.get_width() == 2560, "world overview image should be 2560 pixels wide")
	_assert(world_image.get_height() == 1440, "world overview image should be 1440 pixels tall")
	for path in [
		"res://assets/generated/maps/world/map_sunshine_world_az_label_v001.png",
		"res://assets/generated/maps/world/map_sunshine_world_az_label_showcase_v001.png"
	]:
		_assert(FileAccess.file_exists(path), "world overview asset should exist: %s" % path)
		var file := FileAccess.open(path, FileAccess.READ)
		_assert(file != null, "world overview asset should be readable: %s" % path)
		_assert(file.get_length() > 0, "world overview asset should be non-empty: %s" % path)


func _assert_memory_spark_data_is_derived_from_hotspots(main: Node) -> void:
	var main_script: Node = main
	_assert("memory_spark_defs" in main_script, "main should keep in-memory Memory Spark defs")
	var memory_spark_defs: Dictionary = main_script.memory_spark_defs
	for anchor_id in ["anchor_b_bear", "anchor_g_gate", "anchor_h_hat", "anchor_o_orange", "anchor_t_taxi", "anchor_w_watch"]:
		_assert(memory_spark_defs.has(anchor_id), "Memory Spark defs should include pilot anchor %s" % anchor_id)
	_assert(memory_spark_defs.size() == 26, "Memory Spark defs should cover the full frozen A-Z memory palace")
	_assert(memory_spark_defs.has("anchor_a_apple"), "Memory Spark defs should preserve A = Apple coverage")
	_assert(memory_spark_defs.has("anchor_y_yo_yo"), "Memory Spark defs should cover non-pilot anchors after the home prologue foundation")
	var town_map: Node = main.get_node("TownMap")
	var b_hotspot: Dictionary = town_map.get_hotspot_by_id("anchor_b_bear")
	var b_spark: Dictionary = b_hotspot.get("memory_spark", {})
	_assert(not b_spark.is_empty(), "anchor B should keep parameterized Memory Spark data in hotspot data")
	_assert(str(memory_spark_defs["anchor_b_bear"].get("prompt", "")) == str(b_spark.get("prompt", "")), "Memory Spark should read parameterized prompt from hotspot data")
	_assert(int(memory_spark_defs["anchor_b_bear"].get("reward_coins", 0)) == int(b_spark.get("reward_coins", 0)), "Memory Spark should read parameterized reward from hotspot data")
	_assert(str(memory_spark_defs["anchor_h_hat"].get("prompt", "")) == "Look at letter H. What comes back?", "Memory Spark should still derive fallback prompt for pilot anchors without overrides")


func _assert_anchor_dialogues_complete() -> void:
	var expected_ids := [
		"anchor_a_apple",
		"anchor_b_bear",
		"anchor_c_clock",
		"anchor_d_dog",
		"anchor_e_elephant",
		"anchor_f_fox",
		"anchor_g_gate",
		"anchor_h_hat",
		"anchor_i_ice_cream",
		"anchor_j_jacket",
		"anchor_k_kite",
		"anchor_l_lion",
		"anchor_m_monkey",
		"anchor_n_net",
		"anchor_o_orange",
		"anchor_p_panda",
		"anchor_q_queen",
		"anchor_r_robot",
		"anchor_s_sun",
		"anchor_t_taxi",
		"anchor_u_umbrella",
		"anchor_v_violin",
		"anchor_w_watch",
		"anchor_x_x_mark_box",
		"anchor_y_yo_yo",
		"anchor_z_zebra"
	]
	for dialogue_id: String in expected_ids:
		var path := "res://data/dialogues/%s.json" % dialogue_id
		_assert(FileAccess.file_exists(path), "anchor dialogue should exist: %s" % path)
		var file := FileAccess.open(path, FileAccess.READ)
		_assert(file != null, "anchor dialogue should be readable: %s" % path)
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		_assert(typeof(parsed) == TYPE_DICTIONARY, "anchor dialogue should parse as dictionary: %s" % dialogue_id)
		var dialogue: Dictionary = parsed
		_assert(str(dialogue.get("id", "")) == dialogue_id, "anchor dialogue id should match filename: %s" % dialogue_id)
		_assert(str(dialogue.get("speaker", "")) == "Memory Guide", "anchor dialogue should use child-facing Memory Guide speaker: %s" % dialogue_id)
		var lines_variant: Variant = dialogue.get("lines", [])
		_assert(typeof(lines_variant) == TYPE_ARRAY, "anchor dialogue lines should be an array: %s" % dialogue_id)
		var lines: Array = lines_variant
		_assert(lines.size() == 3, "anchor dialogue should have exactly 3 lines: %s" % dialogue_id)
		for line_variant: Variant in lines:
			_assert(typeof(line_variant) == TYPE_DICTIONARY, "anchor dialogue line should be dictionary: %s" % dialogue_id)
			var line: Dictionary = line_variant
			_assert(str(line.get("speaker", "")) == "Memory Guide", "anchor dialogue line speaker should stay consistent: %s" % dialogue_id)
			var text: String = str(line.get("text", ""))
			_assert(text.length() <= 64, "anchor dialogue line should stay concise in %s: %s" % [dialogue_id, text])
			for phrase in ["Sunshine School", "school dog", "school play corner", "between the school and the town"]:
				_assert(not text.contains(phrase), "anchor dialogue should avoid school-first location wording in %s: %s" % [dialogue_id, text])


func _collect_files_recursive(path: String) -> Array[String]:
	var results: Array[String] = []
	var dir := DirAccess.open(path)
	if dir == null:
		return results
	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		if entry == "." or entry == "..":
			entry = dir.get_next()
			continue
		var child_path := "%s/%s" % [path, entry]
		if dir.current_is_dir():
			results.append_array(_collect_files_recursive(child_path))
		else:
			results.append(child_path)
		entry = dir.get_next()
	return results


func _read_json_dict(path: String) -> Dictionary:
	_assert(FileAccess.file_exists(path), "JSON file should exist: %s" % path)
	var file := FileAccess.open(path, FileAccess.READ)
	_assert(file != null, "JSON file should be readable: %s" % path)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	_assert(typeof(parsed) == TYPE_DICTIONARY, "JSON file should parse as dictionary: %s" % path)
	return parsed


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)


func _required_node(parent: Node, path: String) -> Node:
	if not parent.has_node(path):
		push_error("Missing node: %s" % path)
		quit(1)
	return parent.get_node(path)
