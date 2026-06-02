extends RefCounted
class_name PlaceCardController

const PLACE_CARD_ACTION_BUY_PET_BOWL := "buy_pet_bowl"
const PLACE_CARD_ACTION_BUY_PET_BALL := "buy_pet_ball"
const PLACE_CARD_ACTION_BUY_EXPLORER_CAPE := "buy_explorer_cape"
const PLACE_CARD_ACTION_BUY_STAR_RUG := "buy_star_rug"
const PLACE_CARD_ACTION_CHOOSE_TOWN_ROUTE := "choose_town_route"
const PLACE_CARD_ACTION_HELP_FIND_BOOK := "help_find_book"


static func show_place_card(place_card: CanvasLayer, town_map: Node, target_id: String, feedback_callback: Callable) -> void:
	if not place_card.has_method("show_place"):
		return
	town_map.set_click_input_enabled(false)
	town_map.set_quest_active(false)
	var hotspot: Dictionary = town_map.get_hotspot_by_id(target_id)
	var display_name := str(hotspot.get("label", target_id))
	var first_visit := not GameState.has_story_flag("visited_place_%s" % target_id)
	if first_visit:
		GameState.mark_story_flag("visited_place_%s" % target_id)
		GameState.add_coins(1)
	place_card.show_place(target_id, display_name, first_visit, place_card_hint(target_id, hotspot), place_card_action(target_id, hotspot))
	GameState.save_game()
	if feedback_callback.is_valid():
		feedback_callback.call()


static func handle_action(place_card: CanvasLayer, place_id: String, action_id: String, refresh_home_pet_ui: Callable) -> void:
	if not is_action_currently_available(place_card, place_id, action_id):
		if place_card.has_method("set_status"):
			place_card.set_status("That action is not ready.")
		return
	var hotspot := _hotspot_from_place_card(place_card, place_id)
	var current_action := place_card_action(place_id, hotspot)
	var result: Dictionary = {}
	if place_id == "supermarket" and action_id == PLACE_CARD_ACTION_BUY_PET_BOWL:
		result = GameState.buy_pet_bowl()
	elif place_id == "pet_shop" and action_id == PLACE_CARD_ACTION_BUY_PET_BALL:
		result = GameState.buy_pet_ball()
	elif place_id == "clothes_shop" and action_id == PLACE_CARD_ACTION_BUY_EXPLORER_CAPE:
		result = GameState.buy_explorer_cape()
	elif place_id == "general_store" and action_id == PLACE_CARD_ACTION_BUY_STAR_RUG:
		result = GameState.buy_star_rug()
	elif place_id == "bus_station" and action_id == PLACE_CARD_ACTION_CHOOSE_TOWN_ROUTE:
		result = GameState.choose_town_route()
	else:
		return
	if bool(result.get("success", false)):
		if place_card.has_method("set_status"):
			place_card.set_status(_success_status_text(current_action, result))
		if place_card.has_method("set_primary_action"):
			place_card.set_primary_action(place_card_action(place_id, hotspot))
		if refresh_home_pet_ui.is_valid():
			refresh_home_pet_ui.call(str(current_action.get("home_feedback", "")))
		_apply_success_focus_hotspot(place_card, current_action)
		GameState.save_game()
		return
	if place_card.has_method("set_status"):
		place_card.set_status(str(result.get("message", "")))


static func place_card_hint(_target_id: String, hotspot: Dictionary = {}) -> String:
	return str(hotspot.get("place_card_hint", "You found a new town place."))


static func place_card_action(_target_id: String, hotspot: Dictionary = {}) -> Dictionary:
	var actions: Variant = hotspot.get("place_card_actions", [])
	if typeof(actions) != TYPE_ARRAY:
		return {}
	for action_value: Variant in actions:
		if typeof(action_value) != TYPE_DICTIONARY:
			continue
		var action := action_value as Dictionary
		if _place_card_action_is_visible(action):
			return _place_card_action_result(action)
	return {}


static func is_action_currently_available(place_card: CanvasLayer, place_id: String, action_id: String) -> bool:
	if place_card == null or not place_card.visible:
		return false
	if str(place_card.get("place_id")) != place_id:
		return false
	if str(place_card.get("primary_action_id")) != action_id:
		return false
	var hotspot := _hotspot_from_place_card(place_card, place_id)
	var current_action := place_card_action(place_id, hotspot)
	return str(current_action.get("id", "")) == action_id


static func _place_card_action_is_visible(action: Dictionary) -> bool:
	var visible_when := str(action.get("visible_when", "always"))
	match visible_when:
		"always", "":
			return true
		"missing_pet_bowl":
			return not GameState.has_pet_bowl()
		"missing_pet_ball":
			return not GameState.has_pet_ball()
		"missing_explorer_cape":
			return not GameState.has_explorer_cape()
		"missing_star_rug":
			return not GameState.has_star_rug()
		"missing_town_route":
			return not GameState.has_town_route()
	if visible_when.begins_with("quest_not_completed:"):
		var quest_id := visible_when.trim_prefix("quest_not_completed:")
		return not GameState.has_completed_quest(quest_id)
	return false


static func _place_card_action_result(action: Dictionary) -> Dictionary:
	var action_id := str(action.get("id", ""))
	return {
		"id": action_id,
		"label": str(action.get("label", action_id)),
		"success_status_text": str(action.get("success_status_text", "")),
		"home_feedback": str(action.get("home_feedback", "")),
		"success_focus_hotspot": str(action.get("success_focus_hotspot", ""))
	}


static func _success_status_text(action: Dictionary, result: Dictionary) -> String:
	var success_status_text := str(action.get("success_status_text", ""))
	if not success_status_text.is_empty():
		return success_status_text
	return str(result.get("message", ""))


static func _apply_success_focus_hotspot(place_card: CanvasLayer, action: Dictionary) -> void:
	var focus_hotspot := str(action.get("success_focus_hotspot", ""))
	if focus_hotspot.is_empty() or place_card.get_parent() == null:
		return
	var main := place_card.get_parent()
	if not main.has_node("TownMap"):
		return
	var town_map := main.get_node("TownMap")
	if town_map.has_method("focus_world_hotspot"):
		town_map.focus_world_hotspot(focus_hotspot)


static func _hotspot_from_place_card(place_card: CanvasLayer, place_id: String) -> Dictionary:
	if place_card == null or place_card.get_parent() == null:
		return {}
	var main := place_card.get_parent()
	if not main.has_node("TownMap"):
		return {}
	var town_map := main.get_node("TownMap")
	if not town_map.has_method("get_hotspot_by_id"):
		return {}
	return town_map.get_hotspot_by_id(place_id)
