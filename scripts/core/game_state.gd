extends Node

signal quest_completed(quest_id: String)
# Legacy task_completed signal mirrors quest_completed for saved report/test compatibility.
# New runtime systems should use quest_completed.
signal task_completed(task_id: String)
signal reward_added(reward_id: String)
signal review_completed(review_id: String)
signal coins_changed(value: int)
signal parent_bonus_changed(value: int)
signal pet_name_changed(value: String)
signal pet_state_changed(state: Dictionary)
signal story_flags_changed(flags: Array[String])
signal owned_items_changed(items: Array[String])

const DEFAULT_SAVE_PATH: String = "user://study_game_save.json"
const DEFAULT_PLAYTEST_REPORT_PATH: String = "user://mvp_0_2_playtest_report.json"
const STARTER_ACTIONS_PATH: String = "res://data/economy/starter_actions_v001.json"
const REQUIRED_PLAYTEST_EVENT_IDS: Array[String] = [
	"playtest_started",
	"prologue_go_to_school_started",
	"prologue_go_to_school_completed",
	"g4_u1_school_tour_started",
	"g4_u1_school_tour_completed",
	"g4_u1_tidy_classroom_started",
	"g4_u1_tidy_classroom_completed",
	"g4_u1_garden_bird_started",
	"g4_u1_garden_bird_completed",
	"review_challenge_started",
	"review_challenge_completed",
	"parent_summary_shown",
	"parent_summary_read",
	"playtest_completed"
]
const REQUIRED_FORMAL_QUEST_IDS: Array[String] = [
	"prologue_letter_box",
	"prologue_room_starter",
	"prologue_pet_hello",
	"prologue_home_pet_care",
	"prologue_go_to_school",
	"g4_u1_school_tour",
	"g4_u1_tidy_classroom",
	"g4_u1_garden_bird"
]
const LEGACY_REPORT_QUEST_IDS: Array[String] = [
	"prologue_go_to_school",
	"g4_u1_school_tour",
	"g4_u1_tidy_classroom",
	"g4_u1_garden_bird"
]
const QA_TIMING_REPORT_SCRIPT := preload("res://scripts/systems/qa_timing_report.gd")
const DEFAULT_COINS := 5
const DEFAULT_PARENT_BONUS := 0
const DEFAULT_PET_NAME := "Sunny"
const LEGACY_PARENT_BONUS_CONFIRM_FLAG := "parent_bonus_confirmed_mvp_0_2"
const PARENT_BONUS_CONFIRM_FLAG := "parent_bonus_confirmed_home_prologue_v001"
const PARENT_BONUS_REWARD := 2
const EXPLORER_CAPE_FLAG := "owned_explorer_cape"
const EXPLORER_CAPE_ITEM := "explorer_cape"
const EXPLORER_CAPE_PARENT_BONUS_COST := 1
const STAR_RUG_FLAG := "owned_star_rug"
const STAR_RUG_ITEM := "star_rug"
const STAR_RUG_COST := 4
const PET_BOWL_FLAG := "owned_pet_bowl"
const PET_BOWL_ITEM := "pet_bowl"
const PET_BOWL_COST := 3
const PET_BALL_FLAG := "owned_pet_ball"
const PET_BALL_ITEM := "pet_ball"
const PET_BALL_COST := 2
const TOWN_ROUTE_FLAG := "travel_route_town_edge"
const TOWN_ROAD_FLAG := "travel_route_town_road"
const TRAIN_STOP_FLAG := "travel_route_train_stop"
const LEGACY_ITEM_FLAGS := {
	PET_BOWL_FLAG: PET_BOWL_ITEM,
	PET_BALL_FLAG: PET_BALL_ITEM,
	EXPLORER_CAPE_FLAG: EXPLORER_CAPE_ITEM,
	STAR_RUG_FLAG: STAR_RUG_ITEM
}
const DEFAULT_PET_STATE := {
	"hunger": 62,
	"cleanliness": 58,
	"mood": 66,
	"bond": 10,
	"rest": 70
}
const PET_CARE_MANAGER_SCRIPT := preload("res://scripts/systems/pet_care_manager.gd")
const STARTER_ACTION_ENGINE_SCRIPT := preload("res://scripts/systems/starter_action_engine.gd")
const PLAYTEST_REPORTER_SCRIPT := preload("res://scripts/systems/playtest_reporter.gd")
const GAME_STATE_PERSISTENCE_SCRIPT := preload("res://scripts/systems/game_state_persistence.gd")

var completed_quests: Array[String] = []
var rewards: Array[String] = []
var learned_words: Array[String] = []
var learned_patterns: Array[String] = []
var completed_reviews: Array[String] = []
var story_flags: Array[String] = []
var owned_items: Array[String] = []
var coins: int = DEFAULT_COINS
var parent_bonus: int = DEFAULT_PARENT_BONUS
var pet_name: String = DEFAULT_PET_NAME
var pet_state: Dictionary = DEFAULT_PET_STATE.duplicate(true)
var playtest_started_at_msec: int = -1
var playtest_elapsed_msec: int = 0
var playtest_completed: bool = false
var playtest_events: Array[Dictionary] = []
var _pet_care_manager
var _starter_action_engine
var _playtest_reporter
var _persistence_manager


func complete_task(task_id: String, words: Array = [], patterns: Array = []) -> void:
	complete_quest(task_id, words, patterns)


func complete_quest(quest_id: String, words: Array = [], patterns: Array = []) -> void:
	if not completed_quests.has(quest_id):
		completed_quests.append(quest_id)
		quest_completed.emit(quest_id)
		_emit_legacy_task_completed(quest_id)
	for word in words:
		add_learned_word(str(word))
	for pattern in patterns:
		add_learned_pattern(str(pattern))


func _emit_legacy_task_completed(task_id: String) -> void:
	task_completed.emit(task_id)


func add_reward(reward_id: String) -> void:
	if not rewards.has(reward_id):
		rewards.append(reward_id)
		reward_added.emit(reward_id)


func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	coins += amount
	coins_changed.emit(coins)


func spend_coins(amount: int) -> bool:
	if amount <= 0:
		return true
	if coins < amount:
		return false
	coins -= amount
	coins_changed.emit(coins)
	return true


func add_parent_bonus(amount: int) -> void:
	if amount <= 0:
		return
	parent_bonus += amount
	parent_bonus_changed.emit(parent_bonus)


func spend_parent_bonus(amount: int) -> bool:
	if amount <= 0:
		return true
	if parent_bonus < amount:
		return false
	parent_bonus -= amount
	parent_bonus_changed.emit(parent_bonus)
	return true


func can_confirm_parent_bonus(required_quest_ids: Array[String] = [], required_review_id: String = "") -> bool:
	if has_confirmed_parent_bonus():
		return false
	for quest_id in required_quest_ids:
		if not has_completed_quest(quest_id):
			return false
	if not required_review_id.is_empty() and not has_completed_review(required_review_id):
		return false
	return true


func confirm_parent_bonus(required_quest_ids: Array[String] = [], required_review_id: String = "") -> Dictionary:
	var result := {
		"success": false,
		"message": "Complete the Story Show first.",
		"amount": 0,
		"parent_bonus": parent_bonus
	}
	if has_confirmed_parent_bonus():
		result["message"] = "Parent Bonus already confirmed."
		return result
	if not can_confirm_parent_bonus(required_quest_ids, required_review_id):
		return result
	add_parent_bonus(PARENT_BONUS_REWARD)
	mark_story_flag(PARENT_BONUS_CONFIRM_FLAG)
	result["success"] = true
	result["message"] = "Parent Bonus added: +%d." % PARENT_BONUS_REWARD
	result["amount"] = PARENT_BONUS_REWARD
	result["parent_bonus"] = parent_bonus
	return result


func has_confirmed_parent_bonus() -> bool:
	return has_story_flag(PARENT_BONUS_CONFIRM_FLAG) or has_story_flag(LEGACY_PARENT_BONUS_CONFIRM_FLAG)


func get_pet_state() -> Dictionary:
	return _pet_care().get_pet_state()


func get_pet_name() -> String:
	return _pet_care().get_pet_name()


func set_pet_name(value: String) -> void:
	_pet_care().set_pet_name(value, DEFAULT_PET_NAME)


func care_for_pet(action_id: String) -> Dictionary:
	return _pet_care().care_for_pet(action_id, DEFAULT_PET_STATE)


func add_learned_word(word: String) -> void:
	if not learned_words.has(word):
		learned_words.append(word)


func add_learned_pattern(pattern: String) -> void:
	if not learned_patterns.has(pattern):
		learned_patterns.append(pattern)


func has_completed_task(task_id: String) -> bool:
	return has_completed_quest(task_id)


func has_completed_quest(quest_id: String) -> bool:
	return completed_quests.has(quest_id)


func get_completed_quests() -> Array[String]:
	return completed_quests.duplicate()


func get_rewards() -> Array[String]:
	return rewards.duplicate()


func get_learned_words() -> Array[String]:
	return learned_words.duplicate()


func get_learned_patterns() -> Array[String]:
	return learned_patterns.duplicate()


func get_completed_reviews() -> Array[String]:
	return completed_reviews.duplicate()


func get_story_flags() -> Array[String]:
	return story_flags.duplicate()


func get_playtest_events() -> Array[Dictionary]:
	return playtest_events.duplicate(true)


func get_parent_summary_state() -> Dictionary:
	return {
		"completed_quests": get_completed_quests(),
		"rewards": get_rewards(),
		"learned_words": get_learned_words(),
		"learned_patterns": get_learned_patterns(),
		"completed_reviews": get_completed_reviews(),
		"story_flags": get_story_flags(),
		"owned_items": get_owned_items(),
		"parent_bonus": parent_bonus,
		"playtest_elapsed_text": format_playtest_elapsed(),
		"playtest_completed": playtest_completed,
		"playtest_events": get_playtest_events()
	}


func complete_review(review_id: String) -> void:
	if not completed_reviews.has(review_id):
		completed_reviews.append(review_id)
		review_completed.emit(review_id)


func has_completed_review(review_id: String) -> bool:
	return completed_reviews.has(review_id)


func mark_story_flag(flag_id: String) -> void:
	if flag_id.is_empty():
		return
	if not story_flags.has(flag_id):
		story_flags.append(flag_id)
		story_flags_changed.emit(story_flags.duplicate())
	_persistence().sync_owned_item_from_legacy_flag(flag_id)


func has_story_flag(flag_id: String) -> bool:
	return story_flags.has(flag_id)


func own_item(item_id: String, legacy_flag_id: String = "") -> void:
	var cleaned := item_id.strip_edges()
	if cleaned.is_empty():
		return
	if not owned_items.has(cleaned):
		owned_items.append(cleaned)
		owned_items_changed.emit(owned_items.duplicate())
	if not legacy_flag_id.is_empty() and not story_flags.has(legacy_flag_id):
		story_flags.append(legacy_flag_id)
		story_flags_changed.emit(story_flags.duplicate())


func has_owned_item(item_id: String) -> bool:
	return owned_items.has(item_id)


func get_owned_items() -> Array[String]:
	return owned_items.duplicate()


func has_pet_bowl() -> bool:
	return has_owned_item(PET_BOWL_ITEM) or has_story_flag(PET_BOWL_FLAG)


func has_pet_ball() -> bool:
	return has_owned_item(PET_BALL_ITEM) or has_story_flag(PET_BALL_FLAG)


func has_explorer_cape() -> bool:
	return has_owned_item(EXPLORER_CAPE_ITEM) or has_story_flag(EXPLORER_CAPE_FLAG)


func has_star_rug() -> bool:
	return has_owned_item(STAR_RUG_ITEM) or has_story_flag(STAR_RUG_FLAG)


func has_town_route() -> bool:
	return has_story_flag(TOWN_ROUTE_FLAG)


func has_town_road() -> bool:
	return has_story_flag(TOWN_ROAD_FLAG)


func has_train_stop() -> bool:
	return has_story_flag(TRAIN_STOP_FLAG)


func buy_pet_bowl() -> Dictionary:
	return _run_starter_action("buy_pet_bowl", "Visit the supermarket for pet things.")


func buy_pet_ball() -> Dictionary:
	return _run_starter_action("buy_pet_ball", "Visit the pet shop for a new toy.")


func buy_explorer_cape() -> Dictionary:
	return _run_starter_action("buy_explorer_cape", "Ask a parent for Parent Bonus first.")


func buy_star_rug() -> Dictionary:
	return _run_starter_action("buy_star_rug", "Visit the general store for room decor.")


func choose_town_route() -> Dictionary:
	return _run_starter_action("choose_town_route", "The town route is already marked.")


func find_town_road() -> Dictionary:
	return _run_starter_action("find_town_road", "The town road is already marked.")


func choose_train_stop() -> Dictionary:
	return _run_starter_action("choose_train_stop", "The train stop is already marked.")


func get_pet_item_status_text() -> String:
	if has_pet_bowl() and has_pet_ball():
		return "Pet bowl and ball ready"
	if has_pet_bowl():
		return "Pet bowl ready"
	if has_pet_ball():
		return "Pet ball ready"
	return "No pet bowl yet"


func get_outfit_status_text() -> String:
	if has_explorer_cape():
		return "Explorer cape ready"
	return "Everyday outfit"


func get_room_decor_status_text() -> String:
	if has_star_rug():
		return "Star rug ready"
	return "Cozy room"


func start_playtest_timer(force_restart: bool = false) -> void:
	_playtest().start_timer(force_restart)


func finish_playtest_timer() -> void:
	_playtest().finish_timer()


func get_playtest_elapsed_msec() -> int:
	return _playtest().get_elapsed_msec()


func get_playtest_elapsed_seconds() -> int:
	return _playtest().get_elapsed_seconds()


func format_playtest_elapsed() -> String:
	return _playtest().format_elapsed()


func record_playtest_event(event_id: String, label: String = "") -> void:
	_playtest().record_event(event_id, label)


func save_to_path(path: String = DEFAULT_SAVE_PATH) -> bool:
	return _persistence().save_to_path(path)


func load_from_path(path: String = DEFAULT_SAVE_PATH) -> bool:
	return _persistence().load_from_path(path)


func reset() -> void:
	_persistence().reset()


func save_game(path: String = DEFAULT_SAVE_PATH) -> bool:
	return save_to_path(path)


func load_game(path: String = DEFAULT_SAVE_PATH) -> bool:
	return load_from_path(path)


func build_playtest_report() -> Dictionary:
	return _playtest().build_report(QA_TIMING_REPORT_SCRIPT)


func save_playtest_report(path: String = DEFAULT_PLAYTEST_REPORT_PATH) -> bool:
	return _playtest().save_report(
		path,
		QA_TIMING_REPORT_SCRIPT,
		REQUIRED_FORMAL_QUEST_IDS,
		LEGACY_REPORT_QUEST_IDS,
		REQUIRED_PLAYTEST_EVENT_IDS
	)


func reset_progress() -> void:
	reset()


func debug_snapshot() -> Dictionary:
	return _persistence().debug_snapshot()


func _run_starter_action(action_id: String, default_message: String) -> Dictionary:
	return _starter_engine().run_starter_action(action_id, default_message)


func _pet_care():
	if _pet_care_manager == null:
		_pet_care_manager = PET_CARE_MANAGER_SCRIPT.new(self)
	return _pet_care_manager


func _starter_engine():
	if _starter_action_engine == null:
		_starter_action_engine = STARTER_ACTION_ENGINE_SCRIPT.new(self, STARTER_ACTIONS_PATH)
	return _starter_action_engine


func _playtest():
	if _playtest_reporter == null:
		_playtest_reporter = PLAYTEST_REPORTER_SCRIPT.new(self)
	return _playtest_reporter


func _persistence():
	if _persistence_manager == null:
		_persistence_manager = GAME_STATE_PERSISTENCE_SCRIPT.new(self)
	return _persistence_manager
