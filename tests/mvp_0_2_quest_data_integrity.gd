extends SceneTree

const QUEST_DIR := "res://data/quests"
const DIALOGUE_DIR := "res://data/dialogues"
const SCENE_CLICK_TARGETS_PATH := "res://data/maps/scene_click_targets_v001.json"
const SUPPORTED_SCENE_IDS := [
	"home",
	"world_overview",
	"campus_gate",
	"classroom",
	"garden"
]
const SUPPORTED_WORLD_PLACE_ACTIONS := [
	"scene",
	"place_card"
]
const SUPPORTED_PLACE_CARD_ACTION_IDS := [
	"buy_pet_bowl",
	"buy_pet_ball",
	"buy_explorer_cape",
	"buy_star_rug",
	"choose_town_route",
	"find_town_road",
	"choose_train_stop",
	"help_find_book",
	"help_carry_parcel",
	"help_choose_snack",
	"help_make_poster",
	"help_with_bandage",
	"check_travel_weather",
	"check_train_time",
	"find_music_sound",
	"pick_art_color"
]
const SUPPORTED_PLACE_CARD_VISIBLE_WHEN := [
	"always",
	"missing_pet_bowl",
	"missing_pet_ball",
	"missing_explorer_cape",
	"missing_star_rug",
	"missing_town_route",
	"missing_town_road",
	"missing_train_stop"
]
const SUPPORTED_WORLD_ENABLED_MODES := [
	"",
	"disabled",
	"quest_only",
	"pilot_recall",
	"after_prologue"
]
const PLACE_CARD_ACTION_CONTRACTS := {
	"post_office": {
		"help_carry_parcel": {
			"visible_when": "quest_not_completed:town_post_office_small_parcel",
			"start_quest_id": "town_post_office_small_parcel"
		}
	},
	"hospital": {
		"help_with_bandage": {
			"visible_when": "quest_not_completed:town_hospital_bandage_helper",
			"start_dialogue_id": "mina_hospital_bandage_intro",
			"start_quest_id": "town_hospital_bandage_helper",
			"success_focus_hotspot": true
		}
	},
	"supermarket": {
		"buy_pet_bowl": {
			"visible_when": "missing_pet_bowl",
			"game_state_action": "buy_pet_bowl",
			"success_status_text": true,
			"home_feedback": true
		}
	},
	"pet_shop": {
		"buy_pet_ball": {
			"visible_when": "missing_pet_ball",
			"game_state_action": "buy_pet_ball",
			"success_status_text": true,
			"home_feedback": true
		}
	},
	"clothes_shop": {
		"buy_explorer_cape": {
			"visible_when": "missing_explorer_cape",
			"game_state_action": "buy_explorer_cape",
			"success_status_text": true,
			"home_feedback": true
		}
	},
	"general_store": {
		"buy_star_rug": {
			"visible_when": "missing_star_rug",
			"game_state_action": "buy_star_rug",
			"success_status_text": true,
			"home_feedback": true
		}
	},
	"restaurant": {
		"help_choose_snack": {
			"visible_when": "quest_not_completed:town_restaurant_snack_order",
			"start_quest_id": "town_restaurant_snack_order"
		}
	},
	"cinema": {
		"help_make_poster": {
			"visible_when": "quest_not_completed:town_cinema_show_poster",
			"start_quest_id": "town_cinema_show_poster"
		}
	},
	"bus_station": {
		"choose_town_route": {
			"visible_when": "missing_town_route",
			"game_state_action": "choose_town_route",
			"success_status_text": true,
			"success_focus_hotspot": true
		}
	},
	"taxi": {
		"find_town_road": {
			"visible_when": "missing_town_road",
			"game_state_action": "find_town_road",
			"success_status_text": true,
			"success_focus_hotspot": true
		}
	},
	"railway_station": {
		"choose_train_stop": {
			"visible_when": "missing_train_stop",
			"game_state_action": "choose_train_stop",
			"success_status_text": true,
			"success_focus_hotspot": true
		},
		"check_train_time": {
			"visible_when": "quest_not_completed:town_railway_time_stop",
			"start_dialogue_id": "mina_railway_time_intro",
			"start_quest_id": "town_railway_time_stop",
			"success_focus_hotspot": true
		}
	},
	"airport": {
		"check_travel_weather": {
			"visible_when": "quest_not_completed:town_airport_weather_check",
			"start_dialogue_id": "mina_airport_weather_intro",
			"start_quest_id": "town_airport_weather_check",
			"success_focus_hotspot": true
		}
	},
	"bookshop": {
		"help_find_book": {
			"visible_when": "quest_not_completed:town_bookshop_find_book",
			"start_quest_id": "town_bookshop_find_book"
		}
	},
	"music_room": {
		"find_music_sound": {
			"visible_when": "quest_not_completed:school_music_room_sound_find",
			"start_dialogue_id": "mina_music_room_sound_intro",
			"start_quest_id": "school_music_room_sound_find",
			"success_focus_hotspot": true
		}
	},
	"art_room": {
		"pick_art_color": {
			"visible_when": "quest_not_completed:school_art_room_color_pick",
			"start_dialogue_id": "mina_art_room_color_intro",
			"start_quest_id": "school_art_room_color_pick",
			"success_focus_hotspot": true
		}
	}
}

const DRAG_SCENE_IDS := ["classroom"]
const SUPPORTED_COMPLETION_ACTIONS := [
	"",
	"open_review_or_summary"
]

var failed := false


func _initialize() -> void:
	var quest_paths := _collect_quest_paths()
	_assert(not quest_paths.is_empty(), "quest data directory should contain quest JSON files")
	for path: String in quest_paths:
		_assert_quest_file(path)
	_assert_world_place_actions()
	if failed:
		quit(1)
		return
	print("mvp_0_2_quest_data_integrity passed.")
	quit(0)


func _collect_quest_paths() -> Array[String]:
	var paths: Array[String] = []
	var dir := DirAccess.open(QUEST_DIR)
	_assert(dir != null, "quest data directory should open: %s" % QUEST_DIR)
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			paths.append("%s/%s" % [QUEST_DIR, file_name])
		file_name = dir.get_next()
	dir.list_dir_end()
	paths.sort()
	return paths


func _assert_quest_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	_assert(file != null, "quest file should open: %s" % path)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	_assert(typeof(parsed) == TYPE_DICTIONARY, "quest file should parse as dictionary: %s" % path)
	var quest := parsed as Dictionary
	var file_stem := path.get_file().get_basename()
	var quest_id := str(quest.get("id", ""))
	_assert(quest_id == file_stem, "quest id should match filename stem: %s" % path)
	_assert(not str(quest.get("title", "")).is_empty(), "quest title should be present: %s" % path)
	var scene_id := str(quest.get("scene_id", ""))
	_assert(SUPPORTED_SCENE_IDS.has(scene_id), "quest scene_id should map to a supported TownMap scene: %s -> %s" % [quest_id, scene_id])
	var next_quest := str(quest.get("next_quest", ""))
	if not next_quest.is_empty():
		_assert(FileAccess.file_exists("%s/%s.json" % [QUEST_DIR, next_quest]), "next_quest should point to an existing quest: %s -> %s" % [quest_id, next_quest])
	_assert(not str(quest.get("prompt", "")).is_empty(), "quest prompt should be present: %s" % path)
	_assert(not str(quest.get("reward_id", "")).is_empty(), "quest reward_id should be present: %s" % path)
	_assert(not str(quest.get("reward_name", "")).is_empty(), "quest reward_name should be present: %s" % path)
	_assert(quest.has("reward_coins"), "quest reward_coins should be present: %s" % path)
	_assert(typeof(quest.get("reward_coins")) == TYPE_FLOAT, "quest reward_coins should be a JSON number: %s" % path)
	_assert(float(quest.get("reward_coins", -1.0)) == int(quest.get("reward_coins", -1)), "quest reward_coins should be an integer: %s" % path)
	_assert(int(quest.get("reward_coins", -1)) >= 0, "quest reward_coins should be non-negative: %s" % path)
	if quest.has("repeatable"):
		_assert(typeof(quest.get("repeatable")) == TYPE_BOOL, "quest repeatable should be bool: %s" % path)
		if bool(quest.get("repeatable", false)):
			_assert(not str(quest.get("reward_once_story_flag", "")).is_empty(), "repeatable quest should declare reward_once_story_flag: %s" % path)
	_assert(quest.has("start_focus_hotspot"), "quest start_focus_hotspot should be present: %s" % path)
	var start_focus_hotspot := str(quest.get("start_focus_hotspot", ""))
	if not start_focus_hotspot.is_empty():
		_assert(scene_id == "world_overview", "start_focus_hotspot should only be used by world_overview quests: %s" % quest_id)
		_assert(_world_hotspot_ids().has(start_focus_hotspot), "start_focus_hotspot should resolve to a world hotspot: %s -> %s" % [quest_id, start_focus_hotspot])
	_assert_completion_contract(quest, quest_id)
	var quest_type := str(quest.get("type", ""))
	match quest_type:
		"click_target":
			_assert_click_target_contract(quest, scene_id, quest_id)
		"drag_place":
			_assert_drag_place_contract(quest, scene_id, quest_id)
		"pet_care":
			_assert_pet_care_contract(quest, scene_id, quest_id)
		_:
			_assert(false, "quest type should be supported: %s -> %s" % [quest_id, quest_type])


func _assert_completion_contract(quest: Dictionary, quest_id: String) -> void:
	_assert(quest.has("completion"), "quest completion should be present: %s" % quest_id)
	var completion_value: Variant = quest.get("completion")
	_assert(typeof(completion_value) == TYPE_DICTIONARY, "quest completion should be a dictionary: %s" % quest_id)
	if typeof(completion_value) != TYPE_DICTIONARY:
		return
	var completion := completion_value as Dictionary
	var scene_id := str(completion.get("scene_id", ""))
	if not scene_id.is_empty():
		_assert(SUPPORTED_SCENE_IDS.has(scene_id), "quest completion scene_id should map to a supported TownMap scene: %s -> %s" % [quest_id, scene_id])
	var action := str(completion.get("action", ""))
	_assert(SUPPORTED_COMPLETION_ACTIONS.has(action), "quest completion action should be supported: %s -> %s" % [quest_id, action])
	_assert(not scene_id.is_empty() or not action.is_empty(), "quest completion should define scene_id or action: %s" % quest_id)
	if completion.has("click_input_enabled"):
		_assert(typeof(completion.get("click_input_enabled")) == TYPE_BOOL, "quest completion click_input_enabled should be bool: %s" % quest_id)
	if completion.has("npc_prompts_visible"):
		_assert(typeof(completion.get("npc_prompts_visible")) == TYPE_BOOL, "quest completion npc_prompts_visible should be bool: %s" % quest_id)
	if completion.has("story_flags"):
		var story_flags: Variant = completion.get("story_flags")
		_assert(typeof(story_flags) == TYPE_ARRAY, "quest completion story_flags should be an array: %s" % quest_id)
		if typeof(story_flags) == TYPE_ARRAY:
			for flag_value: Variant in story_flags:
				_assert(not str(flag_value).is_empty(), "quest completion story flag should be non-empty: %s" % quest_id)
	if completion.has("dialogue_id"):
		_assert(not str(completion.get("dialogue_id", "")).is_empty(), "quest completion dialogue_id should be non-empty: %s" % quest_id)
	if completion.has("pet_name"):
		_assert(scene_id == "home", "quest completion pet_name should only be used by home quests: %s" % quest_id)
		_assert(not str(completion.get("pet_name", "")).strip_edges().is_empty(), "quest completion pet_name should be non-empty: %s" % quest_id)
	if completion.has("focus_hotspot"):
		var focus_hotspot := str(completion.get("focus_hotspot", ""))
		_assert(not focus_hotspot.is_empty(), "quest completion focus_hotspot should be non-empty: %s" % quest_id)
		_assert(scene_id == "world_overview", "quest completion focus_hotspot should only be used on world_overview completions: %s" % quest_id)
		_assert(_world_hotspot_ids().has(focus_hotspot), "quest completion focus_hotspot should resolve to a world hotspot: %s -> %s" % [quest_id, focus_hotspot])


func _assert_click_target_contract(quest: Dictionary, scene_id: String, quest_id: String) -> void:
	var correct_target := str(quest.get("correct_target", ""))
	_assert(not correct_target.is_empty(), "click quest correct_target should be present: %s" % quest_id)
	var targets: Array = quest.get("targets", [])
	_assert(not targets.is_empty(), "click quest targets should be present: %s" % quest_id)
	_assert(targets.has(correct_target), "click quest correct_target should be listed in targets: %s -> %s" % [quest_id, correct_target])
	var allowed_targets := _allowed_targets_for_scene(scene_id)
	for target_value: Variant in targets:
		var target_id := str(target_value)
		_assert(allowed_targets.has(target_id), "click quest target should resolve through scene target provider: %s %s -> %s" % [quest_id, scene_id, target_id])


func _assert_drag_place_contract(quest: Dictionary, scene_id: String, quest_id: String) -> void:
	_assert(DRAG_SCENE_IDS.has(scene_id), "drag quest scene should be a supported drag scene: %s -> %s" % [quest_id, scene_id])
	_assert(str(quest.get("start_focus_hotspot", "")).is_empty(), "drag quest should not configure start_focus_hotspot: %s" % quest_id)
	var targets: Array = quest.get("targets", [])
	var placement_targets: Dictionary = quest.get("placement_targets", {})
	_assert(not targets.is_empty(), "drag quest targets should be present: %s" % quest_id)
	_assert(not placement_targets.is_empty(), "drag quest placement_targets should be present: %s" % quest_id)
	for target_value: Variant in targets:
		var target_id := str(target_value)
		_assert(placement_targets.has(target_id), "drag quest target should have a placement target: %s -> %s" % [quest_id, target_id])


func _assert_pet_care_contract(quest: Dictionary, scene_id: String, quest_id: String) -> void:
	_assert(scene_id == "home", "pet care quest should run in home: %s -> %s" % [quest_id, scene_id])
	var correct_action := str(quest.get("correct_action", ""))
	_assert(not correct_action.is_empty(), "pet care quest correct_action should be present: %s" % quest_id)
	var targets: Array = quest.get("targets", [])
	_assert(targets.has(correct_action), "pet care quest correct_action should be listed in targets: %s -> %s" % [quest_id, correct_action])
	_assert(["feed", "clean", "play", "rest", "sleep"].has(correct_action), "pet care quest correct_action should be supported by GameState.care_for_pet: %s -> %s" % [quest_id, correct_action])


func _allowed_targets_for_scene(scene_id: String) -> Array[String]:
	if scene_id == "world_overview":
		return _world_hotspot_ids()
	var raw_targets: Array = _scene_targets_from_runtime_provider().get(scene_id, [])
	var targets: Array[String] = []
	for target_value: Variant in raw_targets:
		targets.append(str(target_value))
	return targets


func _scene_targets_from_runtime_provider() -> Dictionary:
	var file := FileAccess.open(SCENE_CLICK_TARGETS_PATH, FileAccess.READ)
	_assert(file != null, "scene click target data should open")
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	_assert(typeof(parsed) == TYPE_DICTIONARY, "scene click target data should parse as dictionary")
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var data: Dictionary = parsed
	var scenes: Dictionary = data.get("scenes", {})
	var scene_targets := {}
	for scene_id_value: Variant in scenes.keys():
		var scene_id := str(scene_id_value)
		var scene_data: Dictionary = scenes.get(scene_id_value, {})
		var targets: Array[String] = []
		for target_value: Variant in scene_data.get("targets", []):
			_assert(typeof(target_value) == TYPE_DICTIONARY, "scene target should be a dictionary: %s" % scene_id)
			if typeof(target_value) != TYPE_DICTIONARY:
				continue
			var target: Dictionary = target_value
			var target_id := str(target.get("id", ""))
			var rect: Dictionary = target.get("rect", {})
			_assert(not target_id.is_empty(), "scene target id should be present: %s" % scene_id)
			_assert(_rect_fields_valid(rect), "scene target rect should be valid: %s -> %s" % [scene_id, target_id])
			targets.append(target_id)
		scene_targets[scene_id] = targets
	return scene_targets


func _rect_fields_valid(rect: Dictionary) -> bool:
	for field: String in ["x", "y", "w", "h"]:
		if not rect.has(field):
			return false
	return float(rect.get("w", 0.0)) > 0.0 and float(rect.get("h", 0.0)) > 0.0


func _world_hotspot_ids() -> Array[String]:
	var parsed: Variant = _read_world_hotspot_data()
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	var ids: Array[String] = []
	for hotspot: Variant in (parsed as Dictionary).get("hotspots", []):
		_assert(typeof(hotspot) == TYPE_DICTIONARY, "world hotspot should be a dictionary")
		ids.append(str((hotspot as Dictionary).get("id", "")))
	return ids


func _assert_world_place_actions() -> void:
	var parsed: Variant = _read_world_hotspot_data()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	for hotspot_value: Variant in (parsed as Dictionary).get("hotspots", []):
		_assert(typeof(hotspot_value) == TYPE_DICTIONARY, "world hotspot should be a dictionary")
		if typeof(hotspot_value) != TYPE_DICTIONARY:
			continue
		var hotspot := hotspot_value as Dictionary
		if str(hotspot.get("kind", "")) != "place":
			continue
		var world_enabled_mode := str(hotspot.get("world_enabled_mode", ""))
		_assert(SUPPORTED_WORLD_ENABLED_MODES.has(world_enabled_mode), "world_enabled_mode should be supported: %s -> %s" % [str(hotspot.get("id", "")), world_enabled_mode])
		if world_enabled_mode == "disabled":
			continue
		var hotspot_id := str(hotspot.get("id", ""))
		_assert(hotspot.has("world_place_action"), "world place hotspot should declare world_place_action: %s" % hotspot_id)
		var action_value: Variant = hotspot.get("world_place_action", {})
		_assert(typeof(action_value) == TYPE_DICTIONARY, "world_place_action should be a dictionary: %s" % hotspot_id)
		if typeof(action_value) != TYPE_DICTIONARY:
			continue
		var action_data := action_value as Dictionary
		var action := str(action_data.get("action", ""))
		_assert(SUPPORTED_WORLD_PLACE_ACTIONS.has(action), "world_place_action action should be supported: %s -> %s" % [hotspot_id, action])
		if action == "scene":
			var scene_id := str(action_data.get("scene_id", ""))
			_assert(SUPPORTED_SCENE_IDS.has(scene_id), "world_place_action scene_id should be supported: %s -> %s" % [hotspot_id, scene_id])
		if action == "place_card":
			_assert(not str(hotspot.get("place_card_hint", "")).is_empty(), "place_card hotspot should declare place_card_hint: %s" % hotspot_id)
			var actions: Variant = hotspot.get("place_card_actions", [])
			if hotspot.has("place_card_actions"):
				_assert(typeof(actions) == TYPE_ARRAY, "place_card_actions should be an array: %s" % hotspot_id)
			if typeof(actions) == TYPE_ARRAY:
				for place_card_action_value: Variant in actions:
					_assert(typeof(place_card_action_value) == TYPE_DICTIONARY, "place_card action should be a dictionary: %s" % hotspot_id)
					if typeof(place_card_action_value) != TYPE_DICTIONARY:
						continue
					var place_card_action := place_card_action_value as Dictionary
					var action_id := str(place_card_action.get("id", ""))
					_assert(SUPPORTED_PLACE_CARD_ACTION_IDS.has(action_id), "place_card action id should be supported: %s -> %s" % [hotspot_id, action_id])
					_assert(not str(place_card_action.get("label", "")).is_empty(), "place_card action label should be present: %s -> %s" % [hotspot_id, action_id])
					var visible_when := str(place_card_action.get("visible_when", ""))
					_assert(not visible_when.is_empty(), "place_card action visible_when should be present: %s -> %s" % [hotspot_id, action_id])
					_assert_place_card_action_contract(hotspot_id, action_id, visible_when, place_card_action)
					var game_state_action := str(place_card_action.get("game_state_action", ""))
					var start_quest_id := str(place_card_action.get("start_quest_id", ""))
					var start_dialogue_id := str(place_card_action.get("start_dialogue_id", ""))
					_assert(not game_state_action.is_empty() or not start_quest_id.is_empty(), "place_card action should declare game_state_action or start_quest_id: %s -> %s" % [hotspot_id, action_id])
					_assert(game_state_action.is_empty() or root.get_node("GameState").has_method(game_state_action), "place_card game_state_action should resolve to GameState method: %s -> %s" % [hotspot_id, game_state_action])
					_assert(start_quest_id.is_empty() or FileAccess.file_exists("%s/%s.json" % [QUEST_DIR, start_quest_id]), "place_card start_quest_id should point to an existing quest: %s -> %s" % [hotspot_id, start_quest_id])
					if not start_dialogue_id.is_empty():
						_assert(FileAccess.file_exists("%s/%s.json" % [DIALOGUE_DIR, start_dialogue_id]), "place_card start_dialogue_id should point to an existing dialogue: %s -> %s" % [hotspot_id, start_dialogue_id])
						_assert(_dialogue_starts_quest(start_dialogue_id) == start_quest_id, "place_card dialogue starts_quest should match start_quest_id: %s -> %s" % [hotspot_id, action_id])
					if visible_when.begins_with("quest_not_completed:"):
						var quest_id := visible_when.trim_prefix("quest_not_completed:")
						_assert(FileAccess.file_exists("%s/%s.json" % [QUEST_DIR, quest_id]), "place_card quest visibility should point to an existing quest: %s -> %s" % [hotspot_id, visible_when])
					else:
						_assert(SUPPORTED_PLACE_CARD_VISIBLE_WHEN.has(visible_when), "place_card visible_when should be supported: %s -> %s" % [hotspot_id, visible_when])
					if place_card_action.has("success_status_text"):
						_assert(typeof(place_card_action.get("success_status_text")) == TYPE_STRING, "place_card success_status_text should be a string: %s -> %s" % [hotspot_id, action_id])
					if place_card_action.has("home_feedback"):
						_assert(typeof(place_card_action.get("home_feedback")) == TYPE_STRING, "place_card home_feedback should be a string: %s -> %s" % [hotspot_id, action_id])
					var success_focus_hotspot := str(place_card_action.get("success_focus_hotspot", ""))
					if not success_focus_hotspot.is_empty():
						_assert(_world_hotspot_ids().has(success_focus_hotspot), "place_card success_focus_hotspot should resolve to a world hotspot: %s -> %s" % [hotspot_id, success_focus_hotspot])


func _assert_place_card_action_contract(hotspot_id: String, action_id: String, visible_when: String, action: Dictionary = {}) -> void:
	_assert(PLACE_CARD_ACTION_CONTRACTS.has(hotspot_id), "place_card action should only appear on known starter places: %s -> %s" % [hotspot_id, action_id])
	if not PLACE_CARD_ACTION_CONTRACTS.has(hotspot_id):
		return
	var place_contract: Dictionary = PLACE_CARD_ACTION_CONTRACTS.get(hotspot_id, {})
	_assert(place_contract.has(action_id), "place_card action should be allowed on this place: %s -> %s" % [hotspot_id, action_id])
	if not place_contract.has(action_id):
		return
	var action_contract: Dictionary = place_contract.get(action_id, {})
	_assert(str(action_contract.get("visible_when", "")) == visible_when, "place_card action visible_when should match place/action contract: %s -> %s -> %s" % [hotspot_id, action_id, visible_when])
	if bool(action_contract.get("success_status_text", false)):
		_assert(not str(action.get("success_status_text", "")).is_empty(), "place_card action should declare success_status_text: %s -> %s" % [hotspot_id, action_id])
	if bool(action_contract.get("home_feedback", false)):
		_assert(not str(action.get("home_feedback", "")).is_empty(), "place_card action should declare home_feedback: %s -> %s" % [hotspot_id, action_id])
	if bool(action_contract.get("success_focus_hotspot", false)):
		_assert(not str(action.get("success_focus_hotspot", "")).is_empty(), "place_card action should declare success_focus_hotspot: %s -> %s" % [hotspot_id, action_id])
	var expected_game_state_action := str(action_contract.get("game_state_action", ""))
	if not expected_game_state_action.is_empty():
		_assert(str(action.get("game_state_action", "")) == expected_game_state_action, "place_card action should declare the expected GameState action: %s -> %s" % [hotspot_id, action_id])
	var expected_start_quest_id := str(action_contract.get("start_quest_id", ""))
	if not expected_start_quest_id.is_empty():
		_assert(str(action.get("start_quest_id", "")) == expected_start_quest_id, "place_card action should declare the expected start_quest_id: %s -> %s" % [hotspot_id, action_id])
	var expected_start_dialogue_id := str(action_contract.get("start_dialogue_id", ""))
	if not expected_start_dialogue_id.is_empty():
		_assert(str(action.get("start_dialogue_id", "")) == expected_start_dialogue_id, "place_card action should declare the expected start_dialogue_id: %s -> %s" % [hotspot_id, action_id])


func _read_world_hotspot_data() -> Variant:
	var file := FileAccess.open("res://data/maps/sunshine_world_hotspots_v001.json", FileAccess.READ)
	_assert(file != null, "world hotspot data should open")
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	_assert(typeof(parsed) == TYPE_DICTIONARY, "world hotspot data should parse as dictionary")
	return parsed


func _read_json_dict(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	_assert(file != null, "JSON file should open: %s" % path)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	_assert(typeof(parsed) == TYPE_DICTIONARY, "JSON file should parse as dictionary: %s" % path)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed as Dictionary


func _dialogue_starts_quest(dialogue_id: String) -> String:
	var dialogue := _read_json_dict("%s/%s.json" % [DIALOGUE_DIR, dialogue_id])
	return str(dialogue.get("starts_quest", ""))


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)
