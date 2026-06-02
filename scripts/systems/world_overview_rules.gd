extends RefCounted
class_name WorldOverviewRules

const WORLD_ENABLED_MODE_DISABLED := "disabled"
const WORLD_ENABLED_MODE_QUEST_ONLY := "quest_only"
const WORLD_ENABLED_MODE_PILOT_RECALL := "pilot_recall"
const AZ_UNLOCK_MODE_STARTER := "starter"
const AZ_UNLOCK_MODE_AFTER_PROLOGUE := "after_prologue"
const AZ_UNLOCK_MODE_DISABLED := "disabled"
const STORY_FLAG_AZ_FULL_UNLOCKED := "az_full_unlocked_after_prologue"

const SCHOOL_CORE_GATE_IDS := [
	"sunshine_school",
	"classroom",
	"library",
	"playground",
	"canteen"
]

const PROLOGUE_QUEST_ID := "prologue_go_to_school"
const SCHOOL_TOUR_QUEST_ID := "g4_u1_school_tour"
const WORLD_PLACE_ACTION_SCENE := "scene"
const WORLD_PLACE_ACTION_PLACE_CARD := "place_card"


static func is_hotspot_enabled(hotspot: Dictionary, current_quest_id: String, az_full_unlocked: bool = false) -> bool:
	var enabled_mode := str(hotspot.get("world_enabled_mode", "")).strip_edges()
	match enabled_mode:
		WORLD_ENABLED_MODE_DISABLED:
			return false
		WORLD_ENABLED_MODE_QUEST_ONLY:
			return hotspot_matches_quest(hotspot, current_quest_id)
	if str(hotspot.get("kind", "")) == "memory_anchor":
		return is_memory_anchor_unlocked(hotspot, az_full_unlocked)
	if hotspot_matches_quest(hotspot, current_quest_id):
		return true
	return bool(hotspot.get("default_visible", true))


static func is_memory_anchor_unlocked(hotspot: Dictionary, az_full_unlocked: bool) -> bool:
	var unlock_mode := str(hotspot.get("az_unlock_mode", AZ_UNLOCK_MODE_AFTER_PROLOGUE)).strip_edges()
	match unlock_mode:
		AZ_UNLOCK_MODE_DISABLED:
			return false
		AZ_UNLOCK_MODE_STARTER:
			return true
		AZ_UNLOCK_MODE_AFTER_PROLOGUE:
			return az_full_unlocked
	return az_full_unlocked


static func hotspot_matches_quest(hotspot: Dictionary, current_quest_id: String) -> bool:
	if current_quest_id.is_empty():
		return false
	for quest_value: Variant in hotspot.get("quest_targets", []):
		if str(quest_value) == current_quest_id:
			return true
	return false


static func is_pilot_recall_anchor(hotspot: Dictionary) -> bool:
	return str(hotspot.get("kind", "")) == "memory_anchor" and str(hotspot.get("world_enabled_mode", "")).strip_edges() == WORLD_ENABLED_MODE_PILOT_RECALL


static func collect_pilot_recall_anchor_ids(hotspots: Array[Dictionary]) -> Array[String]:
	var anchor_ids: Array[String] = []
	for hotspot: Dictionary in hotspots:
		if not is_pilot_recall_anchor(hotspot):
			continue
		var hotspot_id := str(hotspot.get("id", ""))
		if hotspot_id.is_empty() or anchor_ids.has(hotspot_id):
			continue
		anchor_ids.append(hotspot_id)
	return anchor_ids


static func is_world_place_card_hotspot(hotspot: Dictionary) -> bool:
	if str(hotspot.get("kind", "")) != "place":
		return false
	if str(hotspot.get("zone", "")) == "school_core":
		return false
	return str(hotspot.get("interaction_mode", "")) == "scene_or_card" or str(hotspot.get("child_scene_link", "")).is_empty()


static func resolve_world_place_action(hotspot: Dictionary, quest_active: bool, current_quest_id: String, school_tour_completed: bool) -> Dictionary:
	if str(hotspot.get("kind", "")) != "place":
		return {}
	var hotspot_id := str(hotspot.get("id", ""))
	if should_route_school_core_to_campus_gate(hotspot_id, quest_active, current_quest_id, school_tour_completed):
		return {"action": WORLD_PLACE_ACTION_SCENE, "scene_id": "campus_gate"}
	if quest_active:
		return {}
	return world_place_action_from_data(hotspot)


static func world_place_action_from_data(hotspot: Dictionary) -> Dictionary:
	var action_value: Variant = hotspot.get("world_place_action", {})
	if typeof(action_value) != TYPE_DICTIONARY:
		return {}
	var action_data := action_value as Dictionary
	var action := str(action_data.get("action", ""))
	match action:
		WORLD_PLACE_ACTION_SCENE:
			var scene_id := str(action_data.get("scene_id", ""))
			if scene_id.is_empty():
				return {}
			return {"action": WORLD_PLACE_ACTION_SCENE, "scene_id": scene_id}
		WORLD_PLACE_ACTION_PLACE_CARD:
			return {"action": WORLD_PLACE_ACTION_PLACE_CARD}
	return {}


static func should_route_school_core_to_campus_gate(hotspot_id: String, quest_active: bool, current_quest_id: String, school_tour_completed: bool) -> bool:
	if quest_active and current_quest_id == PROLOGUE_QUEST_ID:
		return false
	if school_tour_completed:
		return false
	return hotspot_id in SCHOOL_CORE_GATE_IDS
