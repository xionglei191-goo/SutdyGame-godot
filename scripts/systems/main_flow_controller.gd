extends RefCounted
class_name MainFlowController

const WorldOverviewRules = preload("res://scripts/systems/world_overview_rules.gd")

const LETTER_BOX_QUEST_ID := "prologue_letter_box"
const PROLOGUE_QUEST_ID := WorldOverviewRules.PROLOGUE_QUEST_ID
const SCHOOL_TOUR_QUEST_ID := WorldOverviewRules.SCHOOL_TOUR_QUEST_ID
const TIDY_CLASSROOM_QUEST_ID := "g4_u1_tidy_classroom"
const GARDEN_BIRD_QUEST_ID := "g4_u1_garden_bird"
const BOOKSHOP_QUEST_ID := "town_bookshop_find_book"
const STORY_FLAG_LETTER_BOX_DONE := "prologue_letter_box_done"
const STORY_FLAG_PROLOGUE_DONE := "prologue_go_to_school_done"
const QUEST_DATA_DIR := "res://data/quests"

var town_map: Node
var dialogue_box: CanvasLayer
var quest_diary: CanvasLayer
var drag_place_game: Node
var reward_popup: CanvasLayer
var story_show: CanvasLayer
var parent_summary: CanvasLayer


func configure(
	town_map_node: Node,
	dialogue_box_node: CanvasLayer,
	quest_diary_node: CanvasLayer,
	drag_place_game_node: Node,
	reward_popup_node: CanvasLayer,
	story_show_node: CanvasLayer,
	parent_summary_node: CanvasLayer
) -> void:
	town_map = town_map_node
	dialogue_box = dialogue_box_node
	quest_diary = quest_diary_node
	drag_place_game = drag_place_game_node
	reward_popup = reward_popup_node
	story_show = story_show_node
	parent_summary = parent_summary_node


func handle_quest_started(quest_id: String) -> void:
	GameState.record_playtest_event("%s_started" % quest_id, "%s 开始" % quest_title(quest_id))
	parent_summary.visible = false
	reward_popup.visible = false
	dialogue_box.visible = false
	town_map.set_npc_prompts_visible(false)
	var quest_data := _load_quest_data(quest_id)
	var quest_type := str(quest_data.get("type", ""))
	var scene_id := str(quest_data.get("scene_id", ""))
	town_map.set_click_input_enabled(quest_type == "click_target")
	town_map.set_quest_active(true)
	town_map.set_current_quest_id(quest_id)
	if scene_id.is_empty():
		_show_legacy_quest_start_scene(quest_id)
	else:
		town_map.show_scene(scene_id)
	var start_focus_hotspot := str(quest_data.get("start_focus_hotspot", ""))
	if not start_focus_hotspot.is_empty() and town_map.has_method("focus_world_hotspot"):
		town_map.focus_world_hotspot(start_focus_hotspot)
	drag_place_game.visible = quest_type == "drag_place"
	if drag_place_game.visible and drag_place_game.has_method("reset_game"):
		drag_place_game.reset_game()


func handle_quest_completed(quest_id: String, reward_id: String, reward_name: String) -> void:
	GameState.record_playtest_event("%s_completed" % quest_id, "%s 完成" % quest_title(quest_id))
	if quest_diary.has_method("dismiss"):
		quest_diary.dismiss()
	dialogue_box.visible = false
	town_map.set_npc_prompts_visible(false)
	town_map.set_click_input_enabled(false)
	town_map.set_quest_active(false)
	town_map.set_current_quest_id("")
	if reward_popup.has_method("show_reward"):
		reward_popup.show_reward(reward_id, reward_name)
	_add_quest_reward_coins(quest_id)
	GameState.save_game()
	drag_place_game.visible = false
	if not _apply_quest_completion_from_data(quest_id):
		_apply_legacy_quest_completion(quest_id)
	GameState.save_game()


func handle_story_show_completed() -> void:
	GameState.record_playtest_event("review_challenge_completed", "Story Show 完成")
	GameState.record_playtest_event("parent_summary_shown", "家长摘要显示")
	GameState.save_game()
	hide_active_overlays()
	if parent_summary.has_method("refresh"):
		parent_summary.refresh()
	parent_summary.visible = true


func restore_scene_from_progress() -> void:
	if GameState.has_completed_quest(TIDY_CLASSROOM_QUEST_ID):
		town_map.show_scene("garden")
		if GameState.has_completed_quest(GARDEN_BIRD_QUEST_ID):
			open_review_or_summary()
	elif GameState.has_completed_quest(SCHOOL_TOUR_QUEST_ID):
		town_map.show_scene("classroom")
	elif GameState.has_completed_quest(PROLOGUE_QUEST_ID):
		town_map.show_scene("campus_gate")
		town_map.set_click_input_enabled(false)
		town_map.set_quest_active(false)
		town_map.set_current_quest_id("")
	elif GameState.has_completed_quest(LETTER_BOX_QUEST_ID):
		town_map.show_scene("home")
		town_map.set_click_input_enabled(false)
		town_map.set_quest_active(false)
		town_map.set_current_quest_id("")
	else:
		town_map.show_scene("home")
		town_map.set_click_input_enabled(false)
		town_map.set_quest_active(false)
		town_map.set_current_quest_id("")


func open_review_or_summary() -> void:
	if GameState.has_completed_review(story_show.REVIEW_ID):
		GameState.record_playtest_event("parent_summary_shown", "家长摘要显示")
		GameState.save_game()
		hide_active_overlays()
		if parent_summary.has_method("refresh"):
			parent_summary.refresh()
		parent_summary.visible = true
	else:
		GameState.record_playtest_event("review_challenge_started", "Story Show 开始")
		hide_active_overlays()
		if story_show.has_method("start_review"):
			story_show.start_review()


func hide_active_overlays() -> void:
	dialogue_box.visible = false
	reward_popup.visible = false
	drag_place_game.visible = false
	story_show.visible = false
	if quest_diary.has_method("dismiss"):
		quest_diary.dismiss()
	town_map.set_npc_prompts_visible(false)
	town_map.set_click_input_enabled(false)
	town_map.set_quest_active(false)
	town_map.set_current_quest_id("")


func quest_title(quest_id: String) -> String:
	var quest_data := _load_quest_data(quest_id)
	var title := str(quest_data.get("title", ""))
	if not title.is_empty():
		return title
	match quest_id:
		LETTER_BOX_QUEST_ID:
			return "Welcome Box"
		PROLOGUE_QUEST_ID:
			return "First Trip"
		SCHOOL_TOUR_QUEST_ID:
			return "Walk With Mina"
		TIDY_CLASSROOM_QUEST_ID:
			return "Room Helper"
		GARDEN_BIRD_QUEST_ID:
			return "Bird Watch"
		BOOKSHOP_QUEST_ID:
			return "Bookshop Helper"
		_:
			return quest_id


func _add_quest_reward_coins(quest_id: String) -> void:
	var reward_coins := _quest_reward_coins_from_data(quest_id)
	if reward_coins >= 0:
		var reward_once_flag := _quest_reward_once_flag_from_data(quest_id)
		if not reward_once_flag.is_empty():
			if GameState.has_story_flag(reward_once_flag):
				return
			GameState.mark_story_flag(reward_once_flag)
		GameState.add_coins(reward_coins)
		return
	match quest_id:
		LETTER_BOX_QUEST_ID:
			GameState.add_coins(1)
		PROLOGUE_QUEST_ID:
			GameState.add_coins(1)
		SCHOOL_TOUR_QUEST_ID:
			GameState.add_coins(2)
		TIDY_CLASSROOM_QUEST_ID:
			GameState.add_coins(2)
		GARDEN_BIRD_QUEST_ID:
			GameState.add_coins(3)
		BOOKSHOP_QUEST_ID:
			GameState.add_coins(1)


func _quest_reward_coins_from_data(quest_id: String) -> int:
	var quest_data := _load_quest_data(quest_id)
	if quest_data.is_empty() or not quest_data.has("reward_coins"):
		return -1
	return int(quest_data.get("reward_coins", 0))


func _quest_reward_once_flag_from_data(quest_id: String) -> String:
	var quest_data := _load_quest_data(quest_id)
	if quest_data.is_empty():
		return ""
	return str(quest_data.get("reward_once_story_flag", ""))


func _show_legacy_quest_start_scene(quest_id: String) -> void:
	match quest_id:
		LETTER_BOX_QUEST_ID:
			town_map.show_scene("home")
			town_map.set_click_input_enabled(true)
		PROLOGUE_QUEST_ID:
			town_map.show_scene("world_overview")
			town_map.set_click_input_enabled(true)
		BOOKSHOP_QUEST_ID:
			town_map.show_scene("world_overview")
			town_map.set_click_input_enabled(true)
			if town_map.has_method("focus_world_hotspot"):
				town_map.focus_world_hotspot("bookshop")
		SCHOOL_TOUR_QUEST_ID:
			town_map.show_scene("campus_gate")
		TIDY_CLASSROOM_QUEST_ID:
			town_map.show_scene("classroom")
			town_map.set_click_input_enabled(false)
		GARDEN_BIRD_QUEST_ID:
			town_map.show_scene("garden")


func _apply_quest_completion_from_data(quest_id: String) -> bool:
	var quest_data := _load_quest_data(quest_id)
	if quest_data.is_empty() or not quest_data.has("completion"):
		return false
	var completion: Variant = quest_data.get("completion")
	if typeof(completion) != TYPE_DICTIONARY:
		push_error("Quest completion data should be a dictionary: %s" % quest_id)
		return false
	var completion_data := completion as Dictionary
	var pet_name := str(completion_data.get("pet_name", ""))
	if not pet_name.is_empty():
		GameState.set_pet_name(pet_name)
	var story_flags: Variant = completion_data.get("story_flags", [])
	if typeof(story_flags) == TYPE_ARRAY:
		for story_flag: Variant in story_flags:
			var flag := str(story_flag)
			if not flag.is_empty():
				GameState.mark_story_flag(flag)
	var action := str(completion_data.get("action", ""))
	if action == "open_review_or_summary":
		open_review_or_summary()
		return true
	var scene_id := str(completion_data.get("scene_id", ""))
	if not scene_id.is_empty():
		town_map.show_scene(scene_id)
	var focus_hotspot := str(completion_data.get("focus_hotspot", ""))
	if not focus_hotspot.is_empty() and town_map.has_method("focus_world_hotspot"):
		town_map.focus_world_hotspot(focus_hotspot)
	if completion_data.has("npc_prompts_visible"):
		town_map.set_npc_prompts_visible(bool(completion_data.get("npc_prompts_visible", false)))
	if completion_data.has("click_input_enabled"):
		town_map.set_click_input_enabled(bool(completion_data.get("click_input_enabled", false)))
	var dialogue_id := str(completion_data.get("dialogue_id", ""))
	if not dialogue_id.is_empty():
		dialogue_box.start_dialogue(dialogue_id)
	return true


func _apply_legacy_quest_completion(quest_id: String) -> void:
	match quest_id:
		LETTER_BOX_QUEST_ID:
			GameState.mark_story_flag(STORY_FLAG_LETTER_BOX_DONE)
			town_map.show_scene("home")
			town_map.set_npc_prompts_visible(true)
		SCHOOL_TOUR_QUEST_ID:
			town_map.show_scene("classroom")
		TIDY_CLASSROOM_QUEST_ID:
			town_map.show_scene("garden")
		GARDEN_BIRD_QUEST_ID:
			open_review_or_summary()
		BOOKSHOP_QUEST_ID:
			town_map.show_scene("world_overview")
			town_map.set_click_input_enabled(true)
		PROLOGUE_QUEST_ID:
			GameState.mark_story_flag(STORY_FLAG_PROLOGUE_DONE)
			GameState.mark_story_flag(WorldOverviewRules.STORY_FLAG_AZ_FULL_UNLOCKED)
			town_map.show_scene("campus_gate")
			town_map.set_npc_prompts_visible(true)
			dialogue_box.start_dialogue("mina_school_arrival_intro")


func _load_quest_data(quest_id: String) -> Dictionary:
	var file := FileAccess.open("%s/%s.json" % [QUEST_DATA_DIR, quest_id], FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Quest data parse failed in MainFlowController: %s" % quest_id)
		return {}
	return parsed as Dictionary
