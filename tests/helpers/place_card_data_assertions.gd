extends RefCounted
class_name PlaceCardDataAssertions


static func action_label(town_map: Node, place_id: String, action_id: String) -> String:
	var action := action_data(town_map, place_id, action_id)
	return str(action.get("label", ""))


static func action_visible_when(town_map: Node, place_id: String, action_id: String) -> String:
	var action := action_data(town_map, place_id, action_id)
	return str(action.get("visible_when", ""))


static func action_home_feedback(town_map: Node, place_id: String, action_id: String) -> String:
	var action := action_data(town_map, place_id, action_id)
	return str(action.get("home_feedback", ""))


static func action_success_status_text(town_map: Node, place_id: String, action_id: String) -> String:
	var action := action_data(town_map, place_id, action_id)
	return str(action.get("success_status_text", ""))


static func action_success_focus_hotspot(town_map: Node, place_id: String, action_id: String) -> String:
	var action := action_data(town_map, place_id, action_id)
	return str(action.get("success_focus_hotspot", ""))


static func action_is_visible(town_map: Node, place_id: String, action_id: String) -> bool:
	return _action_is_visible(action_data(town_map, place_id, action_id))


static func has_visible_action(town_map: Node, place_id: String) -> bool:
	var hotspot: Dictionary = town_map.get_hotspot_by_id(place_id)
	for action_value: Variant in hotspot.get("place_card_actions", []):
		if typeof(action_value) != TYPE_DICTIONARY:
			continue
		if _action_is_visible(action_value as Dictionary):
			return true
	return false


static func action_data(town_map: Node, place_id: String, action_id: String) -> Dictionary:
	var hotspot: Dictionary = town_map.get_hotspot_by_id(place_id)
	for action_value: Variant in hotspot.get("place_card_actions", []):
		if typeof(action_value) != TYPE_DICTIONARY:
			continue
		var action := action_value as Dictionary
		if str(action.get("id", "")) == action_id:
			return action
	return {}


static func hint(town_map: Node, place_id: String) -> String:
	var hotspot: Dictionary = town_map.get_hotspot_by_id(place_id)
	return str(hotspot.get("place_card_hint", ""))


static func _action_is_visible(action: Dictionary) -> bool:
	var game_state: Node = (Engine.get_main_loop() as SceneTree).root.get_node("GameState")
	var visible_when := str(action.get("visible_when", "always"))
	match visible_when:
		"always", "":
			return true
		"missing_pet_bowl":
			return not game_state.has_pet_bowl()
		"missing_pet_ball":
			return not game_state.has_pet_ball()
		"missing_explorer_cape":
			return not game_state.has_explorer_cape()
		"missing_star_rug":
			return not game_state.has_star_rug()
		"missing_town_route":
			return not game_state.has_town_route()
		"missing_town_road":
			return not game_state.has_town_road()
		"missing_train_stop":
			return not game_state.has_train_stop()
	if visible_when.begins_with("quest_not_completed:"):
		return not game_state.has_completed_quest(visible_when.trim_prefix("quest_not_completed:"))
	return false
