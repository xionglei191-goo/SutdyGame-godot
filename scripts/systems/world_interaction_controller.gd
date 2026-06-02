extends RefCounted
class_name WorldInteractionController

const WorldOverviewRules = preload("res://scripts/systems/world_overview_rules.gd")
const PlaceCardController = preload("res://scripts/systems/place_card_controller.gd")

const SCHOOL_TOUR_QUEST_ID := WorldOverviewRules.SCHOOL_TOUR_QUEST_ID
const BOOKSHOP_QUEST_ID := "town_bookshop_find_book"

var town_map: Node
var quest_diary: CanvasLayer
var dialogue_box: CanvasLayer
var place_card: CanvasLayer
var memory_spark_controller: RefCounted
var refresh_home_pet_ui_callback: Callable
var hide_active_overlays_callback: Callable


func configure(
	town_map_node: Node,
	quest_diary_node: CanvasLayer,
	dialogue_box_node: CanvasLayer,
	place_card_node: CanvasLayer,
	memory_spark_controller_ref: RefCounted,
	refresh_callback: Callable,
	hide_overlays_callback: Callable
) -> void:
	town_map = town_map_node
	quest_diary = quest_diary_node
	dialogue_box = dialogue_box_node
	place_card = place_card_node
	memory_spark_controller = memory_spark_controller_ref
	refresh_home_pet_ui_callback = refresh_callback
	hide_active_overlays_callback = hide_overlays_callback


func handle_place_clicked(target_id: String) -> void:
	if quest_diary.active:
		quest_diary.check_target(target_id)
		return
	var resolution := _resolve_world_overview_target(target_id)
	match str(resolution.get("action", "")):
		"scene":
			var scene_id := str(resolution.get("scene_id", ""))
			if not scene_id.is_empty():
				town_map.show_scene(scene_id)
				town_map.set_click_input_enabled(false)
				town_map.set_quest_active(false)
				if not quest_diary.active:
					town_map.set_current_quest_id("")
				if scene_id == "home" and refresh_home_pet_ui_callback.is_valid():
					refresh_home_pet_ui_callback.call()
				return
		"place_card":
			show_place_card(target_id)
			return
	if not quest_diary.active:
		return
	quest_diary.check_target(target_id)


func handle_home_pet_action(action_id: String) -> void:
	if town_map.get_active_scene() != "home":
		return
	var result: Dictionary = GameState.care_for_pet(action_id)
	if bool(result.get("success", false)):
		GameState.save_game()
	if refresh_home_pet_ui_callback.is_valid():
		refresh_home_pet_ui_callback.call(str(result.get("message", "")))


func handle_place_card_closed() -> void:
	if town_map.get_active_scene() == "world_overview":
		town_map.set_click_input_enabled(true)
		town_map.set_quest_active(false)
		town_map.set_current_quest_id("")


func handle_memory_spark_completed(anchor_id: String) -> void:
	if memory_spark_controller == null:
		handle_memory_spark_closed()
		return
	if not memory_spark_controller.handle_spark_completed(anchor_id):
		handle_memory_spark_closed()
		return
	handle_memory_spark_closed()


func handle_memory_spark_closed() -> void:
	if town_map.get_active_scene() == "world_overview":
		town_map.set_click_input_enabled(true)
		town_map.set_quest_active(false)
		town_map.set_current_quest_id("")


func handle_memory_anchor_clicked(anchor_id: String) -> void:
	var quest_was_active: bool = quest_diary.active
	if hide_active_overlays_callback.is_valid():
		hide_active_overlays_callback.call()
	if memory_spark_controller != null and memory_spark_controller.handle_anchor_clicked(anchor_id, quest_was_active) == "memory_spark":
		return
	dialogue_box.start_dialogue(anchor_id)


func show_place_card(target_id: String) -> void:
	PlaceCardController.show_place_card(place_card, town_map, target_id, Callable())


func handle_place_card_action(place_id: String, action_id: String) -> void:
	if place_id == "bookshop" and action_id == PlaceCardController.PLACE_CARD_ACTION_HELP_FIND_BOOK:
		if not PlaceCardController.is_action_currently_available(place_card, place_id, action_id):
			if place_card.has_method("set_status"):
				place_card.set_status("That action is not ready.")
			return
		_start_bookshop_commission()
		return
	PlaceCardController.handle_action(place_card, place_id, action_id, refresh_home_pet_ui_callback)


func _resolve_world_overview_target(target_id: String) -> Dictionary:
	if town_map.get_active_scene() != "world_overview":
		return {}
	var hotspot: Dictionary = town_map.get_hotspot_by_id(target_id)
	if hotspot.is_empty():
		return {}
	if str(hotspot.get("kind", "")) != "place":
		return {}
	return WorldOverviewRules.resolve_world_place_action(
		hotspot,
		quest_diary.active,
		quest_diary.quest_id if quest_diary.active else "",
		GameState.has_completed_quest(SCHOOL_TOUR_QUEST_ID)
	)


func _start_bookshop_commission() -> void:
	if place_card != null:
		place_card.visible = false
	if hide_active_overlays_callback.is_valid():
		hide_active_overlays_callback.call()
	town_map.show_scene("world_overview")
	town_map.set_click_input_enabled(true)
	town_map.set_quest_active(true)
	town_map.set_current_quest_id(BOOKSHOP_QUEST_ID)
	if town_map.has_method("focus_world_hotspot"):
		town_map.focus_world_hotspot("bookshop")
	quest_diary.start_quest(BOOKSHOP_QUEST_ID)
