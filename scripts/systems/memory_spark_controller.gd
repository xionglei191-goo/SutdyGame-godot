extends RefCounted
class_name MemorySparkController

const WorldOverviewRules = preload("res://scripts/systems/world_overview_rules.gd")

var town_map: Node
var card: CanvasLayer
var refresh_home_pet_ui_callback: Callable
var memory_spark_defs: Dictionary = {}
var pilot_memory_spark_anchor_ids: Array[String] = []


func configure(town_map_node: Node, card_node: CanvasLayer, refresh_callback: Callable) -> void:
	town_map = town_map_node
	card = card_node
	refresh_home_pet_ui_callback = refresh_callback
	pilot_memory_spark_anchor_ids = WorldOverviewRules.collect_pilot_recall_anchor_ids(_all_world_hotspots())
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
		var hotspot: Dictionary = town_map.get_hotspot_by_id(anchor_id)
		if hotspot.is_empty():
			continue
		keywords_by_id[anchor_id] = str(hotspot.get("keyword", anchor_id))
	for anchor_id in pilot_memory_spark_anchor_ids:
		var hotspot: Dictionary = town_map.get_hotspot_by_id(anchor_id)
		if hotspot.is_empty():
			continue
		var keyword := str(hotspot.get("keyword", anchor_id))
		var letter := str(hotspot.get("letter", "")).strip_edges()
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
		var learned_words: Array[String] = []
		for word_value: Variant in hotspot.get("vocabulary_cluster", []):
			var word := str(word_value)
			if not learned_words.has(word):
				learned_words.append(word)
		defs[anchor_id] = {
				"prompt": "Look at letter %s. What comes back?" % letter,
			"choices": choices,
			"answer": keyword,
				"success_text": "Letter %s brings back %s." % [letter, keyword],
			"reward_coins": 1,
			"learned_words": learned_words,
			"learned_patterns": ["%s is for %s." % [letter, keyword]]
		}
	return defs


func _all_world_hotspots() -> Array[Dictionary]:
	if town_map != null and town_map.has_node("ClickGame"):
		var click_game: Node = town_map.get_node("ClickGame")
		if "_world_map_hotspots" in click_game:
			return click_game._world_map_hotspots
	return []


func _anchor_seen_flag(anchor_id: String) -> String:
	return "anchor_seen_%s" % anchor_id


func _anchor_recall_done_flag(anchor_id: String) -> String:
	# Legacy save key retained so existing playtest saves keep their completed Memory Spark state.
	return "anchor_recall_done_%s" % anchor_id


func _should_show_memory_spark(anchor_id: String, quest_active: bool) -> bool:
	if town_map == null or town_map.get_active_scene() != "world_overview":
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
