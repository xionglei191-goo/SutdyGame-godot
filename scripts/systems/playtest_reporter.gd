extends RefCounted
class_name PlaytestReporter

var game_state


func _init(game_state_ref = null) -> void:
	game_state = game_state_ref


func start_timer(force_restart: bool = false) -> void:
	if game_state.playtest_completed and not force_restart:
		return
	if game_state.playtest_started_at_msec >= 0 and not force_restart:
		return
	if force_restart:
		game_state.playtest_elapsed_msec = 0
		game_state.playtest_completed = false
		game_state.playtest_events.clear()
	game_state.playtest_started_at_msec = Time.get_ticks_msec()
	record_event("playtest_started", "试玩开始")


func finish_timer() -> void:
	if game_state.playtest_completed:
		return
	if game_state.playtest_started_at_msec >= 0:
		game_state.playtest_elapsed_msec += max(1, Time.get_ticks_msec() - game_state.playtest_started_at_msec)
	game_state.playtest_started_at_msec = -1
	game_state.playtest_completed = true
	record_event("playtest_completed", "试玩完成")


func get_elapsed_msec() -> int:
	if game_state.playtest_started_at_msec < 0:
		return game_state.playtest_elapsed_msec
	return game_state.playtest_elapsed_msec + max(0, Time.get_ticks_msec() - game_state.playtest_started_at_msec)


func get_elapsed_seconds() -> int:
	return int(round(float(get_elapsed_msec()) / 1000.0))


func format_elapsed() -> String:
	var total_seconds := get_elapsed_seconds()
	var minutes := int(total_seconds / 60)
	var seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]


func record_event(event_id: String, label: String = "") -> void:
	if event_id.is_empty():
		return
	for event: Dictionary in game_state.playtest_events:
		if str(event.get("id", "")) == event_id:
			return
	var elapsed_msec := get_elapsed_msec()
	game_state.playtest_events.append({
		"id": event_id,
		"label": label if not label.is_empty() else event_id,
		"elapsed_msec": elapsed_msec,
		"elapsed_seconds": int(round(float(elapsed_msec) / 1000.0)),
		"elapsed_text": format_elapsed_msec(elapsed_msec)
	})


func build_report(qa_timing_report_script) -> Dictionary:
	return qa_timing_report_script.build(game_state.debug_snapshot())


func save_report(path: String, qa_timing_report_script, required_formal_quest_ids: Array[String], legacy_report_quest_ids: Array[String], required_event_ids: Array[String]) -> bool:
	if not can_export_report(required_formal_quest_ids, legacy_report_quest_ids, required_event_ids):
		print("Playtest report export rejected: complete the full MVP flow and parent summary reading first.")
		return false
	return qa_timing_report_script.save(path, game_state.debug_snapshot())


func can_export_report(required_formal_quest_ids: Array[String], legacy_report_quest_ids: Array[String], required_event_ids: Array[String]) -> bool:
	if not game_state.playtest_completed:
		return false
	if not _has_completed_quest_set(required_formal_quest_ids) and not _has_completed_quest_set(legacy_report_quest_ids):
		return false
	if game_state.completed_reviews.is_empty():
		return false
	for event_id: String in required_event_ids:
		if not has_event(event_id):
			return false
	return true


func has_event(event_id: String) -> bool:
	for event: Dictionary in game_state.playtest_events:
		if str(event.get("id", "")) == event_id:
			return true
	return false


func event_array_from(value: Variant) -> Array[Dictionary]:
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
			"elapsed_text": str(event.get("elapsed_text", format_elapsed_msec(int(event.get("elapsed_msec", 0)))))
		})
	return result


func synthetic_event_from_neighbor(event_id: String, label: String, neighbor_event_id: String) -> Dictionary:
	var elapsed_msec: int = game_state.playtest_elapsed_msec
	for event: Dictionary in game_state.playtest_events:
		if str(event.get("id", "")) == neighbor_event_id:
			elapsed_msec = int(event.get("elapsed_msec", elapsed_msec))
			break
	return {
		"id": event_id,
		"label": label,
		"elapsed_msec": elapsed_msec,
		"elapsed_seconds": int(round(float(elapsed_msec) / 1000.0)),
		"elapsed_text": format_elapsed_msec(elapsed_msec)
	}


func insert_event_before(before_event_id: String, event_to_insert: Dictionary) -> void:
	for index in range(game_state.playtest_events.size()):
		if str(game_state.playtest_events[index].get("id", "")) == before_event_id:
			game_state.playtest_events.insert(index, event_to_insert)
			return
	game_state.playtest_events.append(event_to_insert)


func format_elapsed_msec(elapsed_msec: int) -> String:
	var total_seconds := int(round(float(max(0, elapsed_msec)) / 1000.0))
	var minutes := int(total_seconds / 60)
	var seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]


func _has_completed_quest_set(quest_ids: Array[String]) -> bool:
	for quest_id: String in quest_ids:
		if not game_state.completed_quests.has(quest_id):
			return false
	return true
