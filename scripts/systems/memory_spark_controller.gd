extends RefCounted
class_name MemorySparkController

const WorldOverviewRules = preload("res://scripts/systems/world_overview_rules.gd")

var scene_host: Node
var card: CanvasLayer
var refresh_home_pet_ui_callback: Callable
var memory_spark_defs: Dictionary = {}
var pilot_memory_spark_anchor_ids: Array[String] = []


func configure(scene_host_node: Node, card_node: CanvasLayer, refresh_callback: Callable) -> void:
	scene_host = scene_host_node
	card = card_node
	refresh_home_pet_ui_callback = refresh_callback
	pilot_memory_spark_anchor_ids = WorldOverviewRules.collect_memory_spark_anchor_ids(_all_world_hotspots())
	memory_spark_defs = _build_memory_spark_defs()


func handle_anchor_clicked(anchor_id: String, quest_active: bool) -> String:
	if _should_show_memory_spark(anchor_id, quest_active):
		card.show_spark(anchor_id, memory_spark_defs.get(anchor_id, {}))
		return "memory_spark"
	return "dialogue"


func handle_anchor_dialogue_finished(dialogue_id: String, active_scene_id: String) -> bool:
	if not dialogue_id.begins_with("anchor_"):
		return false
	if active_scene_id != "world_overview":
		return false
	GameState.mark_story_flag(_anchor_seen_flag(dialogue_id))
	return true


func handle_spark_completed(anchor_id: String) -> bool:
	var spark_data: Dictionary = memory_spark_defs.get(anchor_id, {})
	if spark_data.is_empty():
		return false
	var reward_coins := int(spark_data.get("reward_coins", 1))
	GameState.mark_story_flag(_anchor_recall_done_flag(anchor_id))
	GameState.add_coins(reward_coins)
	for word_value: Variant in spark_data.get("learned_words", []):
		GameState.add_learned_word(str(word_value))
	for pattern_value: Variant in spark_data.get("learned_patterns", []):
		GameState.add_learned_pattern(str(pattern_value))
	GameState.record_playtest_event("%s_memory_spark_completed" % anchor_id, "%s Memory Spark" % anchor_id)
	GameState.save_game()
	if refresh_home_pet_ui_callback.is_valid():
		refresh_home_pet_ui_callback.call()
	return true


func anchor_seen_flag(anchor_id: String) -> String:
	return _anchor_seen_flag(anchor_id)


func anchor_recall_done_flag(anchor_id: String) -> String:
	return _anchor_recall_done_flag(anchor_id)


func _build_memory_spark_defs() -> Dictionary:
	var defs := {}
	var keywords_by_id := {}
	for anchor_id in pilot_memory_spark_anchor_ids:
		var hotspot: Dictionary = scene_host.get_hotspot_by_id(anchor_id)
		if hotspot.is_empty():
			continue
		keywords_by_id[anchor_id] = str(hotspot.get("keyword", anchor_id))
	for anchor_id in pilot_memory_spark_anchor_ids:
		var hotspot: Dictionary = scene_host.get_hotspot_by_id(anchor_id)
		if hotspot.is_empty():
			continue
		defs[anchor_id] = _memory_spark_def_from_hotspot(anchor_id, hotspot, keywords_by_id)
	return defs


func _memory_spark_def_from_hotspot(anchor_id: String, hotspot: Dictionary, keywords_by_id: Dictionary) -> Dictionary:
	var keyword := str(hotspot.get("keyword", anchor_id))
	var letter := str(hotspot.get("letter", "")).strip_edges()
	var choices := _fallback_choices(anchor_id, keyword, keywords_by_id)
	var learned_words: Array[String] = []
	for word_value: Variant in hotspot.get("vocabulary_cluster", []):
		var word := str(word_value)
		if not learned_words.has(word):
			learned_words.append(word)
	var spark_def := {
		"prompt": "Look at letter %s. What comes back?" % letter,
		"choices": choices,
		"answer": keyword,
		"success_text": "Letter %s brings back %s." % [letter, keyword],
		"reward_coins": 1,
		"learned_words": learned_words,
		"learned_patterns": ["%s is for %s." % [letter, keyword]]
	}
	return _apply_memory_spark_override(spark_def, hotspot)


func _fallback_choices(anchor_id: String, keyword: String, keywords_by_id: Dictionary) -> Array[String]:
	var choices: Array[String] = [keyword]
	for other_id in pilot_memory_spark_anchor_ids:
		if other_id == anchor_id:
			continue
		var other_keyword := str(keywords_by_id.get(other_id, ""))
		if other_keyword.is_empty() or choices.has(other_keyword):
			continue
		choices.append(other_keyword)
		if choices.size() >= 3:
			break
	return choices


func _apply_memory_spark_override(base_def: Dictionary, hotspot: Dictionary) -> Dictionary:
	var override_value: Variant = hotspot.get("memory_spark", {})
	if typeof(override_value) != TYPE_DICTIONARY:
		return base_def
	var override := override_value as Dictionary
	var spark_def := base_def.duplicate(true)
	for field in ["prompt", "answer", "success_text"]:
		if override.has(field):
			var text := str(override.get(field, "")).strip_edges()
			if not text.is_empty():
				spark_def[field] = text
	if override.has("reward_coins"):
		spark_def["reward_coins"] = max(0, int(override.get("reward_coins", 1)))
	var fallback_choices: Array[String] = spark_def.get("choices", [])
	var override_choices := _string_array_from(override.get("choices", []))
	if not override_choices.is_empty():
		spark_def["choices"] = _normalized_choices(override_choices, str(spark_def.get("answer", "")), fallback_choices)
	var learned_words := _string_array_from(override.get("learned_words", []))
	if not learned_words.is_empty():
		spark_def["learned_words"] = learned_words
	var learned_patterns := _string_array_from(override.get("learned_patterns", []))
	if not learned_patterns.is_empty():
		spark_def["learned_patterns"] = learned_patterns
	return spark_def


func _normalized_choices(raw_choices: Array[String], answer: String, fallback_choices: Array[String]) -> Array[String]:
	var choices: Array[String] = []
	if not answer.is_empty():
		choices.append(answer)
	for choice in raw_choices:
		if not choice.is_empty() and not choices.has(choice):
			choices.append(choice)
	for choice in fallback_choices:
		if not choice.is_empty() and not choices.has(choice):
			choices.append(choice)
		if choices.size() >= 3:
			break
	return choices


func _string_array_from(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for item: Variant in value:
		var text := str(item).strip_edges()
		if not text.is_empty() and not result.has(text):
			result.append(text)
	return result


func _all_world_hotspots() -> Array[Dictionary]:
	if scene_host != null and scene_host.has_method("get_all_world_hotspots"):
		return scene_host.get_all_world_hotspots()
	return []


func _anchor_seen_flag(anchor_id: String) -> String:
	return "anchor_seen_%s" % anchor_id


func _anchor_recall_done_flag(anchor_id: String) -> String:
	# Legacy save key retained so existing playtest saves keep their completed Memory Spark state.
	return "anchor_recall_done_%s" % anchor_id


func _should_show_memory_spark(anchor_id: String, quest_active: bool) -> bool:
	if scene_host == null or scene_host.get_active_scene() != "world_overview":
		return false
	if quest_active:
		return false
	if not memory_spark_defs.has(anchor_id):
		return false
	if not GameState.has_story_flag(_anchor_seen_flag(anchor_id)):
		return false
	if GameState.has_story_flag(_anchor_recall_done_flag(anchor_id)):
		return false
	return true
