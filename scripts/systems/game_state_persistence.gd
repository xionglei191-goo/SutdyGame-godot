extends RefCounted
class_name GameStatePersistence

var game_state


func _init(game_state_ref = null) -> void:
	game_state = game_state_ref


func save_to_path(path: String) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Save open failed: %s" % path)
		return false
	file.store_string(JSON.stringify(debug_snapshot(), "\t"))
	return true


func load_from_path(path: String) -> bool:
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
	_apply_loaded_data(parsed as Dictionary)
	return true


func reset() -> void:
	game_state.completed_quests.clear()
	game_state.rewards.clear()
	game_state.learned_words.clear()
	game_state.learned_patterns.clear()
	game_state.completed_reviews.clear()
	game_state.story_flags.clear()
	game_state.owned_items.clear()
	game_state.coins = game_state.DEFAULT_COINS
	game_state.parent_bonus = game_state.DEFAULT_PARENT_BONUS
	game_state.pet_name = game_state.DEFAULT_PET_NAME
	game_state.pet_state = game_state.DEFAULT_PET_STATE.duplicate(true)
	game_state.playtest_started_at_msec = -1
	game_state.playtest_elapsed_msec = 0
	game_state.playtest_completed = false
	game_state.playtest_events.clear()
	_emit_state_signals()


func debug_snapshot() -> Dictionary:
	return {
		"completed_tasks": game_state.completed_quests.duplicate(),
		"completed_quests": game_state.get_completed_quests(),
		"rewards": game_state.rewards.duplicate(),
		"learned_words": game_state.learned_words.duplicate(),
		"learned_patterns": game_state.learned_patterns.duplicate(),
		"completed_reviews": game_state.completed_reviews.duplicate(),
		"story_flags": game_state.story_flags.duplicate(),
		"owned_items": game_state.owned_items.duplicate(),
		"coins": game_state.coins,
		"parent_bonus": game_state.parent_bonus,
		"pet_name": game_state.pet_name,
		"pet_state": game_state.get_pet_state(),
		"playtest_elapsed_msec": game_state.get_playtest_elapsed_msec(),
		"playtest_elapsed_seconds": game_state.get_playtest_elapsed_seconds(),
		"playtest_elapsed_text": game_state.format_playtest_elapsed(),
		"playtest_completed": game_state.playtest_completed,
		"playtest_events": game_state.playtest_events.duplicate(true)
	}


func sync_owned_item_from_legacy_flag(flag_id: String) -> void:
	var item_id := str(game_state.LEGACY_ITEM_FLAGS.get(flag_id, ""))
	if item_id.is_empty() or game_state.owned_items.has(item_id):
		return
	game_state.owned_items.append(item_id)
	game_state.owned_items_changed.emit(game_state.owned_items.duplicate())


func _apply_loaded_data(data: Dictionary) -> void:
	game_state.completed_quests = _string_array_from(data.get("completed_quests", data.get("completed_tasks", [])))
	game_state.rewards = _string_array_from(data.get("rewards", []))
	game_state.learned_words = _string_array_from(data.get("learned_words", []))
	game_state.learned_patterns = _string_array_from(data.get("learned_patterns", []))
	game_state.completed_reviews = _string_array_from(data.get("completed_reviews", []))
	game_state.story_flags = _string_array_from(data.get("story_flags", []))
	game_state.owned_items = _string_array_from(data.get("owned_items", []))
	_migrate_legacy_item_flags()
	_migrate_owned_items_to_legacy_flags()
	game_state.coins = int(data.get("coins", game_state.DEFAULT_COINS))
	game_state.parent_bonus = int(data.get("parent_bonus", game_state.DEFAULT_PARENT_BONUS))
	game_state.pet_state = _pet_state_from(data.get("pet_state", game_state.DEFAULT_PET_STATE))
	game_state.pet_name = str(data.get("pet_name", game_state.DEFAULT_PET_NAME)).strip_edges()
	if game_state.pet_name.is_empty():
		game_state.pet_name = game_state.DEFAULT_PET_NAME
	game_state.playtest_elapsed_msec = int(data.get("playtest_elapsed_msec", 0))
	game_state.playtest_completed = bool(data.get("playtest_completed", false))
	game_state.playtest_events = _event_array_from(data.get("playtest_events", []))
	_migrate_missing_first_trip_completion()
	game_state.playtest_started_at_msec = -1
	_emit_state_signals()


func _emit_state_signals() -> void:
	game_state.coins_changed.emit(game_state.coins)
	game_state.parent_bonus_changed.emit(game_state.parent_bonus)
	game_state.pet_name_changed.emit(game_state.pet_name)
	game_state.pet_state_changed.emit(game_state.get_pet_state())
	game_state.story_flags_changed.emit(game_state.story_flags.duplicate())
	game_state.owned_items_changed.emit(game_state.owned_items.duplicate())


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
	return game_state._playtest().event_array_from(value)


func _pet_state_from(value: Variant) -> Dictionary:
	return game_state._pet_care().pet_state_from(value, game_state.DEFAULT_PET_STATE)


func _migrate_missing_first_trip_completion() -> void:
	if game_state.completed_quests.has("prologue_go_to_school"):
		return
	if not _has_any_completed_quest(["g4_u1_school_tour", "g4_u1_tidy_classroom", "g4_u1_garden_bird"]):
		return
	game_state.completed_quests.append("prologue_go_to_school")
	_add_missing_story_flag("prologue_go_to_school_done")
	_add_missing_story_flag("az_full_unlocked_after_prologue")
	if not game_state._playtest().has_event("prologue_go_to_school_completed"):
		game_state._playtest().insert_event_before(
			"g4_u1_school_tour_started",
			game_state._playtest().synthetic_event_from_neighbor(
				"prologue_go_to_school_completed",
				"First Trip 完成",
				"g4_u1_school_tour_started"
			)
		)


func _has_any_completed_quest(quest_ids: Array[String]) -> bool:
	for quest_id: String in quest_ids:
		if game_state.completed_quests.has(quest_id):
			return true
	return false


func _add_missing_story_flag(flag_id: String) -> void:
	if not game_state.story_flags.has(flag_id):
		game_state.story_flags.append(flag_id)


func _migrate_legacy_item_flags() -> void:
	for flag_id: String in game_state.LEGACY_ITEM_FLAGS.keys():
		if game_state.story_flags.has(flag_id):
			sync_owned_item_from_legacy_flag(flag_id)


func _migrate_owned_items_to_legacy_flags() -> void:
	for flag_id: String in game_state.LEGACY_ITEM_FLAGS.keys():
		var item_id := str(game_state.LEGACY_ITEM_FLAGS[flag_id])
		if game_state.owned_items.has(item_id) and not game_state.story_flags.has(flag_id):
			game_state.story_flags.append(flag_id)
