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
var _starter_actions_cache: Dictionary = {}


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
	return pet_state.duplicate(true)


func get_pet_name() -> String:
	return pet_name


func set_pet_name(value: String) -> void:
	var cleaned := value.strip_edges()
	if cleaned.is_empty():
		cleaned = DEFAULT_PET_NAME
	if pet_name == cleaned:
		return
	pet_name = cleaned
	pet_name_changed.emit(pet_name)


func care_for_pet(action_id: String) -> Dictionary:
	var action := str(action_id).strip_edges().to_lower()
	var result := {
		"success": false,
		"message": "Your pet is waiting.",
		"coins_spent": 0,
		"pet_state": get_pet_state()
	}
	match action:
		"feed":
			if not spend_coins(2):
				result["message"] = "You need 2 coins for pet food."
				return result
			_adjust_pet_stat("hunger", 22)
			_adjust_pet_stat("mood", 6)
			_adjust_pet_stat("bond", 2)
			result["success"] = true
			if has_pet_bowl():
				result["message"] = "Your pet enjoyed a snack in the new bowl."
			else:
				result["message"] = "Your pet enjoyed a snack."
			result["coins_spent"] = 2
		"clean":
			_adjust_pet_stat("cleanliness", 24)
			_adjust_pet_stat("mood", 4)
			_adjust_pet_stat("bond", 1)
			result["success"] = true
			result["message"] = "Your pet feels fresh and clean."
		"play":
			_adjust_pet_stat("mood", 20)
			_adjust_pet_stat("hunger", -4)
			_adjust_pet_stat("bond", 3)
			result["success"] = true
			if has_pet_ball():
				result["message"] = "Your pet had fun with the new ball."
			else:
				result["message"] = "Your pet had fun playing with you."
		"rest", "sleep":
			_adjust_pet_stat("rest", 20)
			_adjust_pet_stat("mood", 12)
			_adjust_pet_stat("hunger", -2)
			_adjust_pet_stat("bond", 1)
			result["success"] = true
			result["message"] = "%s had a cozy rest." % pet_name
		_:
			result["message"] = "That pet action is not ready."
			return result
	result["pet_state"] = get_pet_state()
	pet_state_changed.emit(get_pet_state())
	return result


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
	_sync_owned_item_from_legacy_flag(flag_id)


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
	if playtest_completed and not force_restart:
		return
	if playtest_started_at_msec >= 0 and not force_restart:
		return
	if force_restart:
		playtest_elapsed_msec = 0
		playtest_completed = false
		playtest_events.clear()
	playtest_started_at_msec = Time.get_ticks_msec()
	record_playtest_event("playtest_started", "试玩开始")


func finish_playtest_timer() -> void:
	if playtest_completed:
		return
	if playtest_started_at_msec >= 0:
		playtest_elapsed_msec += max(1, Time.get_ticks_msec() - playtest_started_at_msec)
	playtest_started_at_msec = -1
	playtest_completed = true
	record_playtest_event("playtest_completed", "试玩完成")


func get_playtest_elapsed_msec() -> int:
	if playtest_started_at_msec < 0:
		return playtest_elapsed_msec
	return playtest_elapsed_msec + max(0, Time.get_ticks_msec() - playtest_started_at_msec)


func get_playtest_elapsed_seconds() -> int:
	return int(round(float(get_playtest_elapsed_msec()) / 1000.0))


func format_playtest_elapsed() -> String:
	var total_seconds := get_playtest_elapsed_seconds()
	var minutes := int(total_seconds / 60)
	var seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]


func record_playtest_event(event_id: String, label: String = "") -> void:
	if event_id.is_empty():
		return
	for event: Dictionary in playtest_events:
		if str(event.get("id", "")) == event_id:
			return
	var elapsed_msec := get_playtest_elapsed_msec()
	playtest_events.append({
		"id": event_id,
		"label": label if not label.is_empty() else event_id,
		"elapsed_msec": elapsed_msec,
		"elapsed_seconds": int(round(float(elapsed_msec) / 1000.0)),
		"elapsed_text": _format_elapsed_msec(elapsed_msec)
	})


func save_to_path(path: String = DEFAULT_SAVE_PATH) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Save open failed: %s" % path)
		return false
	file.store_string(JSON.stringify(debug_snapshot(), "\t"))
	return true


func load_from_path(path: String = DEFAULT_SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		reset()
		return false
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Save read failed: %s" % path)
		reset()
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Save parse failed: %s" % path)
		reset()
		return false
	var data: Dictionary = parsed
	completed_quests = _string_array_from(data.get("completed_quests", data.get("completed_tasks", [])))
	rewards = _string_array_from(data.get("rewards", []))
	learned_words = _string_array_from(data.get("learned_words", []))
	learned_patterns = _string_array_from(data.get("learned_patterns", []))
	completed_reviews = _string_array_from(data.get("completed_reviews", []))
	story_flags = _string_array_from(data.get("story_flags", []))
	owned_items = _string_array_from(data.get("owned_items", []))
	_migrate_legacy_item_flags()
	_migrate_owned_items_to_legacy_flags()
	coins = int(data.get("coins", DEFAULT_COINS))
	parent_bonus = int(data.get("parent_bonus", DEFAULT_PARENT_BONUS))
	pet_state = _pet_state_from(data.get("pet_state", DEFAULT_PET_STATE))
	pet_name = str(data.get("pet_name", DEFAULT_PET_NAME)).strip_edges()
	if pet_name.is_empty():
		pet_name = DEFAULT_PET_NAME
	playtest_elapsed_msec = int(data.get("playtest_elapsed_msec", 0))
	playtest_completed = bool(data.get("playtest_completed", false))
	playtest_events = _event_array_from(data.get("playtest_events", []))
	_migrate_missing_first_trip_completion()
	playtest_started_at_msec = -1
	coins_changed.emit(coins)
	parent_bonus_changed.emit(parent_bonus)
	pet_name_changed.emit(pet_name)
	pet_state_changed.emit(get_pet_state())
	story_flags_changed.emit(story_flags.duplicate())
	owned_items_changed.emit(owned_items.duplicate())
	return true


func reset() -> void:
	completed_quests.clear()
	rewards.clear()
	learned_words.clear()
	learned_patterns.clear()
	completed_reviews.clear()
	story_flags.clear()
	owned_items.clear()
	coins = DEFAULT_COINS
	parent_bonus = DEFAULT_PARENT_BONUS
	pet_name = DEFAULT_PET_NAME
	pet_state = DEFAULT_PET_STATE.duplicate(true)
	playtest_started_at_msec = -1
	playtest_elapsed_msec = 0
	playtest_completed = false
	playtest_events.clear()
	coins_changed.emit(coins)
	parent_bonus_changed.emit(parent_bonus)
	pet_name_changed.emit(pet_name)
	pet_state_changed.emit(get_pet_state())
	story_flags_changed.emit(story_flags.duplicate())
	owned_items_changed.emit(owned_items.duplicate())


func save_game(path: String = DEFAULT_SAVE_PATH) -> bool:
	return save_to_path(path)


func load_game(path: String = DEFAULT_SAVE_PATH) -> bool:
	return load_from_path(path)


func build_playtest_report() -> Dictionary:
	return QA_TIMING_REPORT_SCRIPT.build(debug_snapshot())


func save_playtest_report(path: String = DEFAULT_PLAYTEST_REPORT_PATH) -> bool:
	if not _can_export_playtest_report():
		print("Playtest report export rejected: complete the full MVP flow and parent summary reading first.")
		return false
	return QA_TIMING_REPORT_SCRIPT.save(path, debug_snapshot())


func reset_progress() -> void:
	reset()


func debug_snapshot() -> Dictionary:
	return {
		"completed_tasks": _completed_tasks_legacy_snapshot(),
		"completed_quests": get_completed_quests(),
		"rewards": rewards.duplicate(),
		"learned_words": learned_words.duplicate(),
		"learned_patterns": learned_patterns.duplicate(),
		"completed_reviews": completed_reviews.duplicate(),
		"story_flags": story_flags.duplicate(),
		"owned_items": owned_items.duplicate(),
		"coins": coins,
		"parent_bonus": parent_bonus,
		"pet_name": pet_name,
		"pet_state": get_pet_state(),
		"playtest_elapsed_msec": get_playtest_elapsed_msec(),
		"playtest_elapsed_seconds": get_playtest_elapsed_seconds(),
		"playtest_elapsed_text": format_playtest_elapsed(),
		"playtest_completed": playtest_completed,
		"playtest_events": playtest_events.duplicate(true)
	}


func _string_array_from(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for item: Variant in value:
		var text: String = str(item)
		if not result.has(text):
			result.append(text)
	return result


func _event_array_from(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for item: Variant in value:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var event: Dictionary = item
		var event_id := str(event.get("id", ""))
		if event_id.is_empty():
			continue
		result.append({
			"id": event_id,
			"label": str(event.get("label", event_id)),
			"elapsed_msec": int(event.get("elapsed_msec", 0)),
			"elapsed_seconds": int(event.get("elapsed_seconds", 0)),
			"elapsed_text": str(event.get("elapsed_text", _format_elapsed_msec(int(event.get("elapsed_msec", 0)))))
		})
	return result


func _migrate_missing_first_trip_completion() -> void:
	if completed_quests.has("prologue_go_to_school"):
		return
	if not _has_any_completed_quest([
		"g4_u1_school_tour",
		"g4_u1_tidy_classroom",
		"g4_u1_garden_bird"
	]):
		return
	completed_quests.append("prologue_go_to_school")
	if not story_flags.has("prologue_go_to_school_done"):
		story_flags.append("prologue_go_to_school_done")
	if not story_flags.has("az_full_unlocked_after_prologue"):
		story_flags.append("az_full_unlocked_after_prologue")
	if not _has_playtest_event("prologue_go_to_school_completed"):
		_insert_playtest_event_before(
			"g4_u1_school_tour_started",
			_synthetic_playtest_event_from_neighbor(
				"prologue_go_to_school_completed",
				"First Trip 完成",
				"g4_u1_school_tour_started"
			)
		)


func _has_any_completed_quest(quest_ids: Array[String]) -> bool:
	for quest_id: String in quest_ids:
		if completed_quests.has(quest_id):
			return true
	return false


func _synthetic_playtest_event_from_neighbor(event_id: String, label: String, neighbor_event_id: String) -> Dictionary:
	var elapsed_msec := playtest_elapsed_msec
	for event: Dictionary in playtest_events:
		if str(event.get("id", "")) == neighbor_event_id:
			elapsed_msec = int(event.get("elapsed_msec", elapsed_msec))
			break
	return {
		"id": event_id,
		"label": label,
		"elapsed_msec": elapsed_msec,
		"elapsed_seconds": int(round(float(elapsed_msec) / 1000.0)),
		"elapsed_text": _format_elapsed_msec(elapsed_msec)
	}


func _insert_playtest_event_before(before_event_id: String, event_to_insert: Dictionary) -> void:
	for index in range(playtest_events.size()):
		if str(playtest_events[index].get("id", "")) == before_event_id:
			playtest_events.insert(index, event_to_insert)
			return
	playtest_events.append(event_to_insert)


func _pet_state_from(value: Variant) -> Dictionary:
	var result := DEFAULT_PET_STATE.duplicate(true)
	if typeof(value) != TYPE_DICTIONARY:
		return result
	var data: Dictionary = value
	for key in DEFAULT_PET_STATE.keys():
		result[key] = clampi(int(data.get(key, DEFAULT_PET_STATE[key])), 0, 100)
	return result


func _adjust_pet_stat(key: String, delta: int) -> void:
	pet_state[key] = clampi(int(pet_state.get(key, DEFAULT_PET_STATE.get(key, 0))) + delta, 0, 100)


func _format_elapsed_msec(elapsed_msec: int) -> String:
	var total_seconds := int(round(float(max(0, elapsed_msec)) / 1000.0))
	var minutes := int(total_seconds / 60)
	var seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]


func _can_export_playtest_report() -> bool:
	if not playtest_completed:
		return false
	if not _has_completed_quest_set(REQUIRED_FORMAL_QUEST_IDS) and not _has_completed_quest_set(LEGACY_REPORT_QUEST_IDS):
		return false
	if completed_reviews.is_empty():
		return false
	for event_id in REQUIRED_PLAYTEST_EVENT_IDS:
		if not _has_playtest_event(event_id):
			return false
	return true


func _has_completed_quest_set(quest_ids: Array[String]) -> bool:
	for quest_id: String in quest_ids:
		if not completed_quests.has(quest_id):
			return false
	return true


func _sync_owned_item_from_legacy_flag(flag_id: String) -> void:
	var item_id := str(LEGACY_ITEM_FLAGS.get(flag_id, ""))
	if item_id.is_empty() or owned_items.has(item_id):
		return
	owned_items.append(item_id)
	owned_items_changed.emit(owned_items.duplicate())


func _migrate_legacy_item_flags() -> void:
	for flag_id: String in LEGACY_ITEM_FLAGS.keys():
		if story_flags.has(flag_id):
			_sync_owned_item_from_legacy_flag(flag_id)


func _migrate_owned_items_to_legacy_flags() -> void:
	for flag_id: String in LEGACY_ITEM_FLAGS.keys():
		var item_id := str(LEGACY_ITEM_FLAGS[flag_id])
		if owned_items.has(item_id) and not story_flags.has(flag_id):
			story_flags.append(flag_id)


func _has_playtest_event(event_id: String) -> bool:
	for event: Dictionary in playtest_events:
		if str(event.get("id", "")) == event_id:
			return true
	return false


func _completed_tasks_legacy_snapshot() -> Array[String]:
	return completed_quests.duplicate()


func _run_starter_action(action_id: String, default_message: String) -> Dictionary:
	var result := {
		"success": false,
		"message": default_message
	}
	var config := _starter_action_config(action_id)
	if config.is_empty():
		result["message"] = "That action is not ready."
		return result
	var owned_item := str(config.get("owned_item", ""))
	var legacy_flag := str(config.get("legacy_flag", ""))
	if not owned_item.is_empty() and (has_owned_item(owned_item) or (not legacy_flag.is_empty() and has_story_flag(legacy_flag))):
		result["message"] = str(config.get("already_message", default_message))
		return result
	var story_flag := str(config.get("story_flag", ""))
	if not story_flag.is_empty() and has_story_flag(story_flag):
		result["message"] = str(config.get("already_message", default_message))
		return result
	var cost := int(config.get("cost", 0))
	var currency := str(config.get("currency", "coins"))
	if currency == "parent_bonus":
		if not spend_parent_bonus(cost):
			result["message"] = str(config.get("not_enough_message", default_message))
			return result
	else:
		if not spend_coins(cost):
			result["message"] = str(config.get("not_enough_message", default_message))
			return result
	if not owned_item.is_empty():
		own_item(owned_item, legacy_flag)
	if not story_flag.is_empty():
		mark_story_flag(story_flag)
	var reward_coins := int(config.get("reward_coins", 0))
	if reward_coins > 0:
		add_coins(reward_coins)
	for word_value: Variant in config.get("learned_words", []):
		add_learned_word(str(word_value))
	for pattern_value: Variant in config.get("learned_patterns", []):
		add_learned_pattern(str(pattern_value))
	result["success"] = true
	result["message"] = str(config.get("success_message", default_message))
	return result


func _starter_action_config(action_id: String) -> Dictionary:
	var actions := _starter_actions()
	var config: Variant = actions.get(action_id, {})
	if typeof(config) != TYPE_DICTIONARY:
		return {}
	return config as Dictionary


func _starter_actions() -> Dictionary:
	if not _starter_actions_cache.is_empty():
		return _starter_actions_cache
	var file := FileAccess.open(STARTER_ACTIONS_PATH, FileAccess.READ)
	if file == null:
		push_warning("Starter action config not found: %s" % STARTER_ACTIONS_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Starter action config parse failed: %s" % STARTER_ACTIONS_PATH)
		return {}
	var data: Dictionary = parsed
	var actions: Variant = data.get("actions", {})
	if typeof(actions) != TYPE_DICTIONARY:
		return {}
	_starter_actions_cache = actions as Dictionary
	return _starter_actions_cache
