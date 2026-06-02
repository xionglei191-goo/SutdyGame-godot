extends Node

const MemorySparkController = preload("res://scripts/systems/memory_spark_controller.gd")
const MainFlowController = preload("res://scripts/systems/main_flow_controller.gd")
const WorldInteractionController = preload("res://scripts/systems/world_interaction_controller.gd")

@onready var town_map = $TownMap
@onready var dialogue_box = $DialogueBox
@onready var quest_diary = $QuestDiary
@onready var drag_place_game = $DragPlaceGame
@onready var reward_popup = $RewardPopup
@onready var story_show = $StoryShow
@onready var parent_summary = $ParentSummary
@onready var place_card = $PlaceCard
@onready var memory_spark_card = $MemorySparkCard

var dialogue_to_quest := {
	"mina_letter_box_intro": "prologue_letter_box",
	"mina_home_intro": "prologue_go_to_school",
	"mina_school_arrival_intro": "g4_u1_school_tour",
	"mina_intro": "g4_u1_school_tour",
	"leo_room_intro": "g4_u1_tidy_classroom",
	"nora_garden_intro": "g4_u1_garden_bird"
}

var memory_spark_defs: Dictionary = {}
var memory_spark_controller := MemorySparkController.new()
var main_flow_controller := MainFlowController.new()
var world_interaction_controller := WorldInteractionController.new()

func _ready() -> void:
	GameState.load_game()
	if not GameState.playtest_completed:
		GameState.start_playtest_timer()
	town_map.set_click_input_enabled(false)
	town_map.set_quest_active(false)
	town_map.npc_interaction_requested.connect(dialogue_box.start_dialogue)
	town_map.place_clicked.connect(_on_place_clicked)
	town_map.memory_anchor_clicked.connect(_on_memory_anchor_clicked)
	town_map.home_pet_action_requested.connect(_on_home_pet_action)
	if place_card.has_signal("closed") and not place_card.closed.is_connected(_on_place_card_closed):
		place_card.closed.connect(_on_place_card_closed)
	if place_card.has_signal("action_requested") and not place_card.action_requested.is_connected(_on_place_card_action_requested):
		place_card.action_requested.connect(_on_place_card_action_requested)
	if memory_spark_card.has_signal("completed") and not memory_spark_card.completed.is_connected(_on_memory_spark_completed):
		memory_spark_card.completed.connect(_on_memory_spark_completed)
	if memory_spark_card.has_signal("closed") and not memory_spark_card.closed.is_connected(_on_memory_spark_closed):
		memory_spark_card.closed.connect(_on_memory_spark_closed)
	GameState.coins_changed.connect(_on_game_state_coins_changed)
	if GameState.has_signal("pet_name_changed"):
		GameState.pet_name_changed.connect(_on_game_state_pet_name_changed)
	GameState.pet_state_changed.connect(_on_game_state_pet_state_changed)
	if GameState.has_signal("story_flags_changed"):
		GameState.story_flags_changed.connect(_on_game_state_story_flags_changed)
	memory_spark_controller.configure(town_map, memory_spark_card, _refresh_home_pet_ui)
	main_flow_controller.configure(
		town_map,
		dialogue_box,
		quest_diary,
		drag_place_game,
		reward_popup,
		story_show,
		parent_summary
	)
	world_interaction_controller.configure(
		town_map,
		quest_diary,
		dialogue_box,
		place_card,
		memory_spark_controller,
		_refresh_home_pet_ui,
		_hide_active_overlays
	)
	memory_spark_defs = memory_spark_controller.memory_spark_defs.duplicate(true)
	_refresh_home_pet_ui()
	_refresh_player_outfit()
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)
	quest_diary.quest_completed.connect(_on_quest_completed)
	quest_diary.quest_started.connect(_on_quest_started)
	drag_place_game.completed.connect(_on_drag_place_completed)
	story_show.completed.connect(_on_story_show_completed)
	_restore_scene_from_progress()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_parent_summary"):
		get_viewport().set_input_as_handled()
		return


func _on_dialogue_finished(dialogue_id: String) -> void:
	var quest_id := ""
	if dialogue_box.has_method("starts_quest"):
		quest_id = str(dialogue_box.starts_quest(dialogue_id))
	if quest_id.is_empty():
		quest_id = str(dialogue_to_quest.get(dialogue_id, ""))
	if not quest_id.is_empty() and not GameState.has_completed_quest(quest_id):
		GameState.record_playtest_event(_playtest_event_id_for_dialogue(dialogue_id), _event_label_for_dialogue(dialogue_id))
		quest_diary.start_quest(quest_id)
		return
	if memory_spark_controller.handle_anchor_dialogue_finished(dialogue_id, town_map.get_active_scene()):
		town_map.set_click_input_enabled(true)
		town_map.set_quest_active(false)


func _on_quest_completed(quest_id: String, reward_id: String, reward_name: String) -> void:
	main_flow_controller.handle_quest_completed(quest_id, reward_id, reward_name)


func _on_quest_started(quest_id: String) -> void:
	main_flow_controller.handle_quest_started(quest_id)


func _on_drag_place_completed() -> void:
	quest_diary.complete_drag_task()


func _on_story_show_completed() -> void:
	main_flow_controller.handle_story_show_completed()


func _restore_scene_from_progress() -> void:
	main_flow_controller.restore_scene_from_progress()


func _open_review_or_summary() -> void:
	main_flow_controller.open_review_or_summary()


func _hide_active_overlays() -> void:
	main_flow_controller.hide_active_overlays()


func _on_game_state_coins_changed(value: int) -> void:
	_refresh_home_pet_ui()


func _on_game_state_pet_state_changed(state: Dictionary) -> void:
	_refresh_home_pet_ui()


func _on_game_state_pet_name_changed(_value: String) -> void:
	_refresh_home_pet_ui()


func _on_game_state_story_flags_changed(_flags: Array[String]) -> void:
	_refresh_home_pet_ui()
	_refresh_player_outfit()

func _on_place_clicked(target_id: String) -> void:
	world_interaction_controller.handle_place_clicked(target_id)


func _on_home_pet_action(action_id: String) -> void:
	world_interaction_controller.handle_home_pet_action(action_id)


func _on_place_card_closed() -> void:
	world_interaction_controller.handle_place_card_closed()


func _on_memory_spark_completed(anchor_id: String) -> void:
	world_interaction_controller.handle_memory_spark_completed(anchor_id)


func _on_memory_spark_closed() -> void:
	world_interaction_controller.handle_memory_spark_closed()


func _on_place_card_action_requested(place_id: String, action_id: String) -> void:
	world_interaction_controller.handle_place_card_action(place_id, action_id)


func _refresh_home_pet_ui(feedback: String = "") -> void:
	if town_map.has_method("update_home_pet_ui"):
		town_map.update_home_pet_ui(
			GameState.coins,
			GameState.get_pet_state(),
			feedback,
			GameState.get_pet_item_status_text(),
			GameState.get_outfit_status_text(),
			GameState.get_room_decor_status_text(),
			GameState.get_pet_name()
		)


func _refresh_player_outfit() -> void:
	if town_map.player != null and town_map.player.has_method("set_explorer_cape_visible"):
		town_map.player.set_explorer_cape_visible(GameState.has_explorer_cape())


func _on_memory_anchor_clicked(anchor_id: String) -> void:
	world_interaction_controller.handle_memory_anchor_clicked(anchor_id)


func _event_label_for_dialogue(dialogue_id: String) -> String:
	match dialogue_id:
		"mina_home_intro", "mina_intro":
			return "Mina 对话结束"
		"mina_letter_box_intro":
			return "Mina Welcome Box 对话结束"
		"leo_room_intro":
			return "Leo 对话结束"
		"nora_garden_intro":
			return "Nora 对话结束"
		_:
			return "%s 对话结束" % dialogue_id


func _playtest_event_id_for_dialogue(dialogue_id: String) -> String:
	match dialogue_id:
		"mina_letter_box_intro":
			return "mina_letter_box_intro_finished"
		"mina_home_intro":
			return "mina_intro_dialogue_finished"
		_:
			return "%s_dialogue_finished" % dialogue_id
