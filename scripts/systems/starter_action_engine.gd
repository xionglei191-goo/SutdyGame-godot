extends RefCounted
class_name StarterActionEngine

var game_state
var starter_actions_path: String
var starter_actions_cache: Dictionary = {}


func _init(game_state_ref = null, actions_path: String = "") -> void:
	game_state = game_state_ref
	starter_actions_path = actions_path


func run_starter_action(action_id: String, default_message: String) -> Dictionary:
	var result := {
		"success": false,
		"message": default_message
	}
	var config := starter_action_config(action_id)
	if config.is_empty():
		result["message"] = "That action is not ready."
		return result
	var owned_item := str(config.get("owned_item", ""))
	var legacy_flag := str(config.get("legacy_flag", ""))
	if not owned_item.is_empty() and (game_state.has_owned_item(owned_item) or (not legacy_flag.is_empty() and game_state.has_story_flag(legacy_flag))):
		result["message"] = str(config.get("already_message", default_message))
		return result
	var story_flag := str(config.get("story_flag", ""))
	if not story_flag.is_empty() and game_state.has_story_flag(story_flag):
		result["message"] = str(config.get("already_message", default_message))
		return result
	var cost := int(config.get("cost", 0))
	var currency := str(config.get("currency", "coins"))
	if currency == "parent_bonus":
		if not game_state.spend_parent_bonus(cost):
			result["message"] = str(config.get("not_enough_message", default_message))
			return result
	else:
		if not game_state.spend_coins(cost):
			result["message"] = str(config.get("not_enough_message", default_message))
			return result
	if not owned_item.is_empty():
		game_state.own_item(owned_item, legacy_flag)
	if not story_flag.is_empty():
		game_state.mark_story_flag(story_flag)
	var reward_coins := int(config.get("reward_coins", 0))
	if reward_coins > 0:
		game_state.add_coins(reward_coins)
	for word_value: Variant in config.get("learned_words", []):
		game_state.add_learned_word(str(word_value))
	for pattern_value: Variant in config.get("learned_patterns", []):
		game_state.add_learned_pattern(str(pattern_value))
	result["success"] = true
	result["message"] = str(config.get("success_message", default_message))
	return result


func starter_action_config(action_id: String) -> Dictionary:
	var actions := starter_actions()
	var config: Variant = actions.get(action_id, {})
	if typeof(config) != TYPE_DICTIONARY:
		return {}
	return config as Dictionary


func starter_actions() -> Dictionary:
	if not starter_actions_cache.is_empty():
		return starter_actions_cache
	var file := FileAccess.open(starter_actions_path, FileAccess.READ)
	if file == null:
		push_warning("Starter action config not found: %s" % starter_actions_path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Starter action config parse failed: %s" % starter_actions_path)
		return {}
	var data: Dictionary = parsed
	var actions: Variant = data.get("actions", {})
	if typeof(actions) != TYPE_DICTIONARY:
		return {}
	starter_actions_cache = actions as Dictionary
	return starter_actions_cache
