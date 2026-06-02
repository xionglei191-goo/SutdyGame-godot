extends SceneTree

const SCENE_CLICK_TARGETS_PATH := "res://data/maps/scene_click_targets_v001.json"
const WORLD_HOTSPOTS_PATH := "res://data/maps/sunshine_world_hotspots_v001.json"
const NEW_PROLOGUE_SAVE_PATH := "user://mvp_new_home_prologue_flow_save.json"
const PET_HELLO_QUEST_ID := "prologue_pet_hello"
const HOME_PET_CARE_QUEST_ID := "prologue_home_pet_care"

const REQUIRED_HOME_TARGETS := [
	"home_letter_box",
	"home_book",
	"home_bag",
	"home_bed",
	"home_door",
	"home_kitchen",
	"home_yard",
	"home_pet_corner",
	"home_pet_bowl",
	"home_pet_toy",
	"home_pet_bed"
]

const NEW_PROLOGUE_STEPS := [
	{
		"id": "prologue_letter_box",
		"title": "Welcome Box",
		"scene_id": "home",
		"type": "click_target",
		"target": "home_letter_box",
		"required_words_any": ["apple", "book", "bag", "home"]
	},
	{
		"id": "prologue_room_starter",
		"title": "Room Starter",
		"scene_id": "home",
		"type": "click_target",
		"target": "home_bag",
		"required_words_any": ["room", "book", "bag", "bed"]
	},
	{
		"id": "prologue_pet_hello",
		"title": "Pet Hello",
		"scene_id": "home",
		"type": "click_target",
		"target": "home_pet_corner",
		"required_words_any": ["pet", "hello", "name"]
	},
	{
		"id": "prologue_home_pet_care",
		"title": "Home Pet Care",
		"scene_id": "home",
		"type": "pet_care",
		"action": "feed",
		"required_words_any": ["feed", "clean", "play", "rest"]
	},
	{
		"id": "prologue_go_to_school",
		"title": "First Trip",
		"scene_id": "world_overview",
		"type": "click_target",
		"target": "sunshine_school",
		"required_words_any": ["home", "school", "go"]
	}
]

const REQUIRED_NEXT_QUESTS := {
	"prologue_letter_box": "prologue_room_starter",
	"prologue_room_starter": "prologue_pet_hello",
	"prologue_pet_hello": "prologue_home_pet_care",
	"prologue_home_pet_care": "prologue_go_to_school"
}

const CHILD_VISIBLE_QUEST_FIELDS := [
	"title",
	"prompt",
	"wrong_target_text",
	"success_text",
	"reward_name",
	"start_feedback"
]

var failed := false
var completed_quests: Array[String] = []


func _initialize() -> void:
	_assert_new_home_prologue_data_contract()
	if failed:
		push_error("mvp_new_home_prologue_flow data contract failed; runtime flow skipped.")
		quit(1)
		return
	await _run_runtime_flow()
	print("mvp_new_home_prologue_flow passed.")
	quit(0)


func _assert_new_home_prologue_data_contract() -> void:
	_assert_scene_click_targets_are_data_driven()
	var home_target_ids := _home_target_ids_from_data()
	for target_id: String in REQUIRED_HOME_TARGETS:
		_expect(home_target_ids.has(target_id), "home click target should be declared in scene_click_targets data: %s" % target_id)
	_assert_home_room_starter_target_alignment()

	var world_hotspot_ids := _world_hotspot_ids()
	for step: Dictionary in NEW_PROLOGUE_STEPS:
		var quest_id := str(step.get("id", ""))
		var quest := _read_quest_data(quest_id)
		if quest.is_empty():
			continue
		_assert_quest_step_contract(quest, step, home_target_ids, world_hotspot_ids)


func _assert_scene_click_targets_are_data_driven() -> void:
	var scene_click_game := _read_text("res://scripts/minigames/scene_click_game.gd")
	_expect(scene_click_game.contains("SCENE_CLICK_TARGETS_PATH"), "SceneClickGame should keep reading subscene targets from scene_click_targets data")
	_expect(not scene_click_game.contains("PLACE_RECTS"), "SceneClickGame should not reintroduce hard-coded PLACE_RECTS")
	_expect(not scene_click_game.contains("SCENE_TARGET_RECTS"), "SceneClickGame should not reintroduce hard-coded SCENE_TARGET_RECTS")


func _assert_quest_step_contract(
	quest: Dictionary,
	step: Dictionary,
	home_target_ids: Array[String],
	world_hotspot_ids: Array[String]
) -> void:
	var quest_id := str(step.get("id", ""))
	var expected_title := str(step.get("title", ""))
	var expected_scene_id := str(step.get("scene_id", ""))
	var expected_type := str(step.get("type", ""))
	var expected_target := str(step.get("target", ""))
	var expected_action := str(step.get("action", ""))

	_expect(str(quest.get("id", "")) == quest_id, "quest id should match expected step id: %s" % quest_id)
	_expect(str(quest.get("title", "")) == expected_title, "quest title should match new MVP chain: %s -> %s" % [quest_id, expected_title])
	_expect(str(quest.get("scene_id", "")) == expected_scene_id, "quest scene_id should match new MVP chain: %s -> %s" % [quest_id, expected_scene_id])
	_expect(str(quest.get("type", "")) == expected_type, "quest type should match new MVP step contract: %s -> %s" % [quest_id, expected_type])

	var targets: Array = quest.get("targets", [])
	if expected_type == "click_target":
		_expect(str(quest.get("correct_target", "")) == expected_target, "quest correct_target should match new MVP step target: %s -> %s" % [quest_id, expected_target])
		_expect(targets.has(expected_target), "quest targets should include the expected target: %s -> %s" % [quest_id, expected_target])
		for target_value: Variant in targets:
			var target_id := str(target_value)
			if expected_scene_id == "home":
				_expect(home_target_ids.has(target_id), "home quest target should resolve through scene_click_targets data: %s -> %s" % [quest_id, target_id])
			elif expected_scene_id == "world_overview":
				_expect(world_hotspot_ids.has(target_id), "world quest target should resolve through world hotspot data: %s -> %s" % [quest_id, target_id])
	elif expected_type == "pet_care":
		_expect(str(quest.get("correct_action", "")) == expected_action, "pet care quest correct_action should match new MVP step action: %s -> %s" % [quest_id, expected_action])
		_expect(targets.has(expected_action), "pet care quest targets should include the expected action: %s -> %s" % [quest_id, expected_action])
		for action_value: Variant in targets:
			_expect(_supported_pet_care_actions().has(str(action_value)), "pet care target should be a supported pet action: %s -> %s" % [quest_id, str(action_value)])
	else:
		_expect(false, "new MVP prologue step type should be supported by this test: %s -> %s" % [quest_id, expected_type])

	var expected_next := str(REQUIRED_NEXT_QUESTS.get(quest_id, ""))
	if not expected_next.is_empty():
		_expect(str(quest.get("next_quest", "")) == expected_next, "new MVP prologue should chain through next_quest: %s -> %s" % [quest_id, expected_next])

	var completion: Variant = quest.get("completion", {})
	_expect(typeof(completion) == TYPE_DICTIONARY, "quest completion should be a dictionary: %s" % quest_id)
	if typeof(completion) == TYPE_DICTIONARY and expected_scene_id == "home":
		var story_flags: Variant = (completion as Dictionary).get("story_flags", [])
		_expect(typeof(story_flags) == TYPE_ARRAY and not (story_flags as Array).is_empty(), "home prologue quest should write at least one completion story flag: %s" % quest_id)
		if quest_id == PET_HELLO_QUEST_ID:
			var pet_name := str((completion as Dictionary).get("pet_name", ""))
			_expect(not pet_name.is_empty(), "Pet Hello completion should set the starter pet name")
			_assert_child_visible_text_allowed(pet_name, "Pet Hello completion pet_name")

	_expect(_array_has_any(quest.get("vocabulary", []), step.get("required_words_any", [])), "quest vocabulary should cover the step theme: %s" % quest_id)
	_assert_quest_child_copy_allowed(quest, quest_id)


func _run_runtime_flow() -> void:
	var game_state: Node = root.get_node("GameState")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(NEW_PROLOGUE_SAVE_PATH))
	game_state.reset_progress()

	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	_assert(main_scene != null, "Main scene should load for new home prologue flow")
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	await process_frame

	var town_map: Node = main.get_node("TownMap")
	var quest_diary: CanvasLayer = main.get_node("QuestDiary")
	quest_diary.quest_completed.connect(func(quest_id: String, _reward_id: String, _reward_name: String) -> void:
		completed_quests.append(quest_id)
	)

	_assert(town_map.get_active_scene() == "home", "new MVP flow should still start at HomeLayer")
	_assert_runtime_home_target_provider(town_map)
	_assert(not _pet_panel(town_map).visible, "fresh home start should keep My Pet panel hidden until Pet Hello")
	_assert_no_child_visible_banned_copy(_child_visible_roots(main), "fresh home start")

	for step: Dictionary in NEW_PROLOGUE_STEPS:
		await _complete_step(main, step)

	_assert_pet_name_and_care_persist(game_state)

	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(NEW_PROLOGUE_SAVE_PATH))


func _complete_step(main: Node, step: Dictionary) -> void:
	var town_map: Node = main.get_node("TownMap")
	var quest_diary: CanvasLayer = main.get_node("QuestDiary")
	var game_state: Node = root.get_node("GameState")
	var quest_id := str(step.get("id", ""))
	var expected_title := str(step.get("title", ""))
	var expected_scene_id := str(step.get("scene_id", ""))
	var expected_type := str(step.get("type", ""))
	var correct_target := str(step.get("target", ""))
	var correct_action := str(step.get("action", ""))
	var player: CharacterBody2D = town_map.get_node("Player")

	if expected_scene_id == "home":
		town_map.show_scene("home")
	else:
		town_map.show_scene(expected_scene_id)
	await process_frame

	var preserved_position := Vector2(420.0, 525.0)
	if expected_scene_id == "world_overview":
		preserved_position = Vector2(980.0, 780.0)
	player.position = preserved_position
	quest_diary.start_quest(quest_id)
	await process_frame
	_assert(player.position == preserved_position, "starting a quest in the current scene should not reset player position: %s" % quest_id)
	_assert(quest_diary.active, "Quest Diary should open for %s" % quest_id)
	_assert(quest_diary.quest_id == quest_id, "Quest Diary should track %s" % quest_id)
	_assert(quest_diary.event_label.text == expected_title, "Quest Diary should show child-facing event title for %s" % quest_id)
	_assert_no_child_visible_banned_copy(_child_visible_roots(main), "Quest Diary active for %s" % quest_id)
	if ["prologue_letter_box", "prologue_room_starter", PET_HELLO_QUEST_ID].has(quest_id):
		_assert(not _pet_panel(town_map).visible, "My Pet panel should not cover early home quest: %s" % quest_id)
	if quest_id == HOME_PET_CARE_QUEST_ID:
		_assert(_pet_panel(town_map).visible, "Home Pet Care should show the My Pet panel")

	if expected_type == "pet_care":
		await _exercise_pet_care_buttons(town_map, game_state, quest_id, correct_action)
	else:
		var wrong_target := _wrong_target_for(correct_target)
		quest_diary.check_target(wrong_target)
		await process_frame
		_assert(not completed_quests.has(quest_id), "wrong target should not complete %s" % quest_id)
		_assert(quest_diary.active, "Quest Diary should remain active after wrong target for %s" % quest_id)
		quest_diary.check_target(correct_target)
	await process_frame
	if expected_scene_id == "home":
		_assert(player.position == preserved_position, "completing a home quest should not reset player position: %s" % quest_id)
	_assert(completed_quests.has(quest_id), "correct target should complete %s" % quest_id)
	_assert(game_state.has_completed_quest(quest_id), "GameState should save completed quest %s" % quest_id)
	if quest_id == PET_HELLO_QUEST_ID:
		var expected_pet_name := _expected_pet_name()
		_assert(game_state.get_pet_name() == expected_pet_name, "Pet Hello should save the starter pet name")
		_assert(_pet_panel(town_map).visible, "Pet Hello completion should unlock the My Pet panel")
		_assert(_pet_name_label(town_map).text == expected_pet_name, "Pet Hello should make the starter pet name visible at home")
		_assert(_pet_corner_label(town_map).text == "%s's corner" % expected_pet_name, "Pet Hello should update the visible pet corner name")
		await _assert_pet_panel_can_close_and_reopen(town_map)


func _exercise_pet_care_buttons(town_map: Node, game_state: Node, quest_id: String, correct_action: String) -> void:
	var feed_button: Button = town_map.get_node("HomeLayer/PetPanel/MarginContainer/VBoxContainer/ActionButtons/FeedButton")
	var clean_button: Button = town_map.get_node("HomeLayer/PetPanel/MarginContainer/VBoxContainer/ActionButtons/CleanButton")
	var play_button: Button = town_map.get_node("HomeLayer/PetPanel/MarginContainer/VBoxContainer/ActionButtons/PlayButton")
	var rest_button: Button = town_map.get_node("HomeLayer/PetPanel/MarginContainer/VBoxContainer/ActionButtons/RestButton")
	clean_button.pressed.emit()
	await process_frame
	_assert(not completed_quests.has(quest_id), "wrong pet care action should not complete %s" % quest_id)

	var starting_coins: int = game_state.coins
	var reward_coins := int(_read_quest_data(quest_id).get("reward_coins", 0))
	_assert(correct_action == "feed", "Home Pet Care flow test currently expects feed as the first care action")
	feed_button.pressed.emit()
	await process_frame
	_assert(completed_quests.has(quest_id), "correct pet care action should complete %s" % quest_id)
	play_button.pressed.emit()
	rest_button.pressed.emit()
	await process_frame

	var pet_state: Dictionary = game_state.get_pet_state()
	_assert(game_state.coins == starting_coins - 2 + reward_coins, "Home Pet Care should spend coins only for feed, then add quest reward coins")
	_assert(int(pet_state.get("hunger", 0)) > int(game_state.DEFAULT_PET_STATE.get("hunger", 0)), "Home Pet Care should raise hunger")
	_assert(int(pet_state.get("cleanliness", 0)) > int(game_state.DEFAULT_PET_STATE.get("cleanliness", 0)), "Home Pet Care should raise cleanliness")
	_assert(int(pet_state.get("mood", 0)) > int(game_state.DEFAULT_PET_STATE.get("mood", 0)), "Home Pet Care should raise mood")
	_assert(int(pet_state.get("rest", 0)) > int(game_state.DEFAULT_PET_STATE.get("rest", 0)), "Home Pet Care should raise rest")
	var feedback_label: Label = town_map.get_node("HomeLayer/PetPanel/MarginContainer/VBoxContainer/FeedbackLabel")
	_assert(feedback_label.text == "%s had a cozy rest." % _expected_pet_name(), "rest feedback should use the starter pet name")


func _assert_pet_name_and_care_persist(game_state: Node) -> void:
	var saved_pet_state: Dictionary = game_state.get_pet_state()
	var saved_coins: int = game_state.coins
	_assert(game_state.save_game(NEW_PROLOGUE_SAVE_PATH), "new home prologue save should succeed")
	game_state.reset_progress()
	_assert(game_state.load_game(NEW_PROLOGUE_SAVE_PATH), "new home prologue save should load")
	_assert(game_state.get_pet_name() == _expected_pet_name(), "load should restore starter pet name")
	_assert(game_state.coins == saved_coins, "load should restore prologue coin balance")
	for key: String in ["hunger", "cleanliness", "mood", "bond", "rest"]:
		_assert(int(game_state.get_pet_state().get(key, -1)) == int(saved_pet_state.get(key, -2)), "load should restore pet state key: %s" % key)
	for step: Dictionary in NEW_PROLOGUE_STEPS:
		_assert(game_state.has_completed_quest(str(step.get("id", ""))), "load should restore completed new MVP step: %s" % str(step.get("id", "")))


func _assert_runtime_home_target_provider(town_map: Node) -> void:
	var click_game: Node = town_map.get_node("ClickGame")
	var home_rects: Dictionary = click_game.get_place_rects_for_scene("home")
	for target_id: String in REQUIRED_HOME_TARGETS:
		_assert(home_rects.has(target_id), "runtime home target provider should expose data target: %s" % target_id)
		var rect: Rect2 = home_rects[target_id]
		_assert(rect.size.x > 0.0 and rect.size.y > 0.0, "runtime home target rect should be clickable: %s" % target_id)
	_assert((home_rects["home_bag"] as Rect2).has_point(Vector2(1165.0, 590.0)), "runtime home_bag target should cover the visible blue trip bag")
	_assert((home_rects["home_book"] as Rect2).has_point(Vector2(540.0, 505.0)), "runtime home_book target should cover the visible book card")


func _assert_home_room_starter_target_alignment() -> void:
	var rects := _home_target_rects_from_data()
	_expect(rects.has("home_bag"), "home_bag target should be present for Room Starter")
	_expect(rects.has("home_book"), "home_book target should be present for Room Starter")
	if rects.has("home_bag"):
		_expect((rects["home_bag"] as Rect2).has_point(Vector2(1165.0, 590.0)), "home_bag target should cover the visible blue trip bag center")
	if rects.has("home_book"):
		_expect((rects["home_book"] as Rect2).has_point(Vector2(540.0, 505.0)), "home_book target should cover the visible book card center")


func _assert_quest_child_copy_allowed(quest: Dictionary, quest_id: String) -> void:
	for field: String in CHILD_VISIBLE_QUEST_FIELDS:
		if quest.has(field):
			_assert_child_visible_text_allowed(str(quest.get(field, "")), "quest visible field %s in %s" % [field, quest_id])
	var arrays_to_check := ["vocabulary", "patterns"]
	for field: String in arrays_to_check:
		var values_variant: Variant = quest.get(field, [])
		if typeof(values_variant) != TYPE_ARRAY:
			continue
		for value: Variant in values_variant:
			_assert_child_visible_text_allowed(str(value), "quest visible array %s in %s" % [field, quest_id])
	var target_labels_variant: Variant = quest.get("target_labels", {})
	if typeof(target_labels_variant) == TYPE_DICTIONARY:
		var target_labels: Dictionary = target_labels_variant
		for value: Variant in target_labels.values():
			_assert_child_visible_text_allowed(str(value), "quest target label in %s" % quest_id)


func _assert_no_child_visible_banned_copy(roots: Array[Node], context: String) -> void:
	for item: Dictionary in _collect_child_visible_texts(roots):
		_assert_child_visible_text_allowed(str(item.get("text", "")), "%s at %s" % [context, str(item.get("path", ""))])


func _assert_child_visible_text_allowed(text: String, context: String) -> void:
	var banned_exact := [
		"Task Panel",
		"Review Challenge",
		"School Tour",
		"校园导览",
		"Look for:",
		"L1",
		"L2",
		"L3"
	]
	var banned_case_insensitive := [
		"lesson panel",
		"word list",
		"word-list",
		"sentence pattern",
		"review test",
		"school app",
		"worksheet"
	]
	for phrase: String in banned_exact:
		_assert(not text.contains(phrase), "%s should not expose '%s': %s" % [context, phrase, text])
	var lower_text := text.to_lower()
	for phrase: String in banned_case_insensitive:
		_assert(not lower_text.contains(phrase), "%s should not expose '%s': %s" % [context, phrase, text])
	for token: String in ["lesson", "test"]:
		_assert(not _contains_token(lower_text, token), "%s should not expose token '%s': %s" % [context, token, text])


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


func _child_visible_roots(main: Node) -> Array[Node]:
	return [
		main.get_node("TownMap"),
		main.get_node("DialogueBox"),
		main.get_node("QuestDiary"),
		main.get_node("DragPlaceGame"),
		main.get_node("RewardPopup"),
		main.get_node("StoryShow"),
		main.get_node("PlaceCard"),
		main.get_node("MemorySparkCard")
	]


func _home_target_ids_from_data() -> Array[String]:
	var rects := _home_target_rects_from_data()
	var ids: Array[String] = []
	for target_id: Variant in rects.keys():
		ids.append(str(target_id))
	return ids


func _home_target_rects_from_data() -> Dictionary:
	var data := _read_json_dict(SCENE_CLICK_TARGETS_PATH)
	var scenes: Dictionary = data.get("scenes", {})
	var home: Dictionary = scenes.get("home", {})
	var rects: Dictionary = {}
	for target_value: Variant in home.get("targets", []):
		if typeof(target_value) != TYPE_DICTIONARY:
			_expect(false, "home scene target entry should be a dictionary")
			continue
		var target: Dictionary = target_value
		var target_id := str(target.get("id", ""))
		var rect: Dictionary = target.get("rect", {})
		_expect(not target_id.is_empty(), "home scene target id should be present")
		_expect(_rect_fields_valid(rect), "home scene target rect should be valid: %s" % target_id)
		if not target_id.is_empty() and _rect_fields_valid(rect):
			rects[target_id] = Rect2(
				Vector2(float(rect.get("x", 0.0)), float(rect.get("y", 0.0))),
				Vector2(float(rect.get("w", 0.0)), float(rect.get("h", 0.0)))
			)
	return rects


func _world_hotspot_ids() -> Array[String]:
	var data := _read_json_dict(WORLD_HOTSPOTS_PATH)
	var ids: Array[String] = []
	for hotspot_value: Variant in data.get("hotspots", []):
		if typeof(hotspot_value) != TYPE_DICTIONARY:
			_expect(false, "world hotspot entry should be a dictionary")
			continue
		var hotspot: Dictionary = hotspot_value
		var hotspot_id := str(hotspot.get("id", ""))
		if not hotspot_id.is_empty():
			ids.append(hotspot_id)
	return ids


func _read_quest_data(quest_id: String) -> Dictionary:
	var path := "res://data/quests/%s.json" % quest_id
	_expect(FileAccess.file_exists(path), "new MVP quest data should exist: %s" % path)
	if not FileAccess.file_exists(path):
		return {}
	return _read_json_dict(path)


func _read_json_dict(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	_expect(file != null, "JSON file should open: %s" % path)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	_expect(typeof(parsed) == TYPE_DICTIONARY, "JSON file should parse as dictionary: %s" % path)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed as Dictionary


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	_expect(file != null, "text file should open: %s" % path)
	if file == null:
		return ""
	return file.get_as_text()


func _rect_fields_valid(rect: Dictionary) -> bool:
	for field: String in ["x", "y", "w", "h"]:
		if not rect.has(field):
			return false
	return float(rect.get("w", 0.0)) > 0.0 and float(rect.get("h", 0.0)) > 0.0


func _array_has_any(values: Variant, expected_values: Variant) -> bool:
	if typeof(values) != TYPE_ARRAY or typeof(expected_values) != TYPE_ARRAY:
		return false
	var normalized: Array[String] = []
	for value: Variant in values:
		normalized.append(str(value).to_lower())
	for expected: Variant in expected_values:
		if normalized.has(str(expected).to_lower()):
			return true
	return false


func _wrong_target_for(correct_target: String) -> String:
	if correct_target == "sunshine_school":
		return "home"
	if correct_target == "home_letter_box":
		return "home_book"
	return "home_letter_box"


func _expected_pet_name() -> String:
	var quest := _read_quest_data(PET_HELLO_QUEST_ID)
	var completion: Dictionary = quest.get("completion", {})
	var pet_name := str(completion.get("pet_name", ""))
	if pet_name.is_empty():
		return "Coco"
	return pet_name


func _supported_pet_care_actions() -> Array[String]:
	return ["feed", "clean", "play", "rest", "sleep"]


func _pet_name_label(town_map: Node) -> Label:
	return town_map.get_node("HomeLayer/PetPanel/MarginContainer/VBoxContainer/StatsGrid/PetNameValue")


func _pet_panel(town_map: Node) -> Panel:
	return town_map.get_node("HomeLayer/PetPanel")


func _assert_pet_panel_can_close_and_reopen(town_map: Node) -> void:
	var pet_panel := _pet_panel(town_map)
	var close_button: Button = town_map.get_node("HomeLayer/PetPanel/CloseButton")
	var open_button: Button = town_map.get_node("HomeLayer/PetCorner/OpenPetPanelButton")
	_assert(pet_panel.visible, "My Pet panel should start open after Pet Hello")
	var close_point := _control_screen_center(close_button)
	_assert(town_map._screen_point_in_button(close_button, close_point), "Close button screen center should be hittable")
	await _send_mouse_click(town_map, close_point)
	await process_frame
	_assert(not pet_panel.visible, "My Pet close button should hide the panel")
	_assert(open_button.visible, "Care button should appear after closing My Pet")
	await _send_mouse_click(town_map, _control_screen_center(open_button))
	await process_frame
	_assert(pet_panel.visible, "Care button should reopen My Pet")
	_assert(not open_button.visible, "Care button should hide while My Pet is open")


func _send_mouse_click(input_target: Node, position: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = position
	press.global_position = position
	input_target._input(press)
	await process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = position
	release.global_position = position
	input_target._input(release)
	await process_frame


func _control_screen_center(control: Control) -> Vector2:
	return control.get_global_transform_with_canvas() * (control.size * 0.5)


func _pet_corner_label(town_map: Node) -> Label:
	return town_map.get_node("HomeLayer/PetCorner/PetCornerLabel")


func _contains_token(text: String, token: String) -> bool:
	var regex := RegEx.new()
	regex.compile("(^|[^A-Za-z0-9_])%s([^A-Za-z0-9_]|$)" % token)
	return regex.search(text) != null


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
