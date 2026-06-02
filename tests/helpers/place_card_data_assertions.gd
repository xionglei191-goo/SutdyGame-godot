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
