extends Node2D

signal target_clicked(target_id: String)
signal memory_anchor_clicked(anchor_id: String)

const WorldOverviewRules = preload("res://scripts/systems/world_overview_rules.gd")

const SCENE_CLICK_TARGETS_PATH := "res://data/maps/scene_click_targets_v001.json"
const WORLD_HOTSPOTS_PATH := "res://data/maps/sunshine_world_hotspots_v001.json"

var active_scene_id := "home"
var input_enabled := false
var quest_active := false
var current_quest_id := ""
var _scene_target_rects: Dictionary = {}
var _scene_targets_by_scene: Dictionary = {}
var _world_map_hotspots: Array[Dictionary] = []
var _world_default_scene := "world_overview"
var _world_canvas_size := Vector2(1280.0, 720.0)


func set_active_scene(scene_id: String) -> void:
	active_scene_id = scene_id


func set_input_enabled(is_enabled: bool) -> void:
	input_enabled = is_enabled


func set_quest_active(is_active: bool) -> void:
	quest_active = is_active


func set_task_active(is_active: bool) -> void:
	# Legacy compatibility wrapper. New code should call set_quest_active().
	set_quest_active(is_active)


func set_current_quest_id(quest_id: String) -> void:
	current_quest_id = quest_id


func set_current_lesson_id(lesson_id: String) -> void:
	# Legacy compatibility wrapper. New code should call set_current_quest_id().
	set_current_quest_id(lesson_id)


func is_task_active() -> bool:
	# Legacy compatibility wrapper. New code should call is_quest_active().
	return quest_active


func is_quest_active() -> bool:
	return quest_active


func get_world_canvas_size() -> Vector2:
	return _world_canvas_size


func get_place_rects_for_scene(scene_id: String) -> Dictionary:
	var rects: Dictionary = {}
	if scene_id == "world_overview":
		for hotspot: Dictionary in get_hotspots_for_scene(scene_id):
			if str(hotspot.get("kind", "")) != "place":
				continue
			rects[str(hotspot.get("id", ""))] = _rect_from_hotspot(hotspot)
		return rects
	var target_ids: Array = _scene_targets_by_scene.get(scene_id, [])
	for target_id in target_ids:
		if _scene_target_rects.has(target_id):
			rects[target_id] = _scene_target_rects[target_id]
	return rects


func get_hotspots_for_scene(scene_id: String) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	if scene_id != "world_overview":
		return results
	for hotspot: Dictionary in _world_map_hotspots:
		if _is_world_hotspot_enabled(hotspot):
			results.append(hotspot)
	return results


func get_hotspot_by_id(hotspot_id: String) -> Dictionary:
	for hotspot: Dictionary in _world_map_hotspots:
		if str(hotspot.get("id", "")) == hotspot_id:
			return hotspot
	return {}


func get_hotspot_rect(hotspot_id: String) -> Rect2:
	var hotspot := get_hotspot_by_id(hotspot_id)
	if hotspot.is_empty():
		return Rect2()
	return _rect_from_hotspot(hotspot)


func _ready() -> void:
	_load_scene_targets()
	_load_world_hotspots()
	for marker in get_tree().get_nodes_in_group("place_markers"):
		if marker is Area2D:
			marker.input_pickable = true
		if marker is Area2D and not marker.input_event.is_connected(_on_marker_input_event.bind(marker)):
			marker.input_event.connect(_on_marker_input_event.bind(marker))


func _input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var click_position := get_global_mouse_position()
		if active_scene_id == _world_default_scene:
			var hotspot := _pick_world_hotspot(click_position)
			if not hotspot.is_empty():
				var hotspot_id := str(hotspot.get("id", ""))
				var hotspot_kind := str(hotspot.get("kind", ""))
				if hotspot_kind == "memory_anchor":
					memory_anchor_clicked.emit(hotspot_id)
				else:
					target_clicked.emit(hotspot_id)
				get_viewport().set_input_as_handled()
				return
		var target_ids: Array = _scene_targets_by_scene.get(active_scene_id, [])
		for target_id in target_ids:
			if _scene_target_rects.has(target_id) and (_scene_target_rects[target_id] as Rect2).has_point(click_position):
				print("Place clicked: %s" % target_id)
				target_clicked.emit(target_id)
				get_viewport().set_input_as_handled()
				return


func _on_marker_input_event(_viewport: Node, event: InputEvent, _shape_idx: int, marker: Area2D) -> void:
	if not input_enabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var target_id := str(marker.get_meta("target_id", marker.name.to_snake_case().replace("_marker", "")))
		target_clicked.emit(target_id)


func _load_scene_targets() -> void:
	_scene_target_rects.clear()
	_scene_targets_by_scene.clear()
	if not FileAccess.file_exists(SCENE_CLICK_TARGETS_PATH):
		push_warning("Scene target file not found: %s" % SCENE_CLICK_TARGETS_PATH)
		return
	var file := FileAccess.open(SCENE_CLICK_TARGETS_PATH, FileAccess.READ)
	if file == null:
		push_warning("Failed to open scene target file: %s" % SCENE_CLICK_TARGETS_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Failed to parse scene target file: %s" % SCENE_CLICK_TARGETS_PATH)
		return
	var data: Dictionary = parsed
	var scenes: Dictionary = data.get("scenes", {})
	for scene_id_value: Variant in scenes.keys():
		var scene_id := str(scene_id_value)
		var scene_data: Dictionary = scenes.get(scene_id_value, {})
		var target_ids: Array[String] = []
		for target_value: Variant in scene_data.get("targets", []):
			if typeof(target_value) != TYPE_DICTIONARY:
				continue
			var target: Dictionary = target_value
			var target_id := str(target.get("id", ""))
			if target_id.is_empty():
				continue
			target_ids.append(target_id)
			_scene_target_rects[target_id] = _rect_from_target(target)
		_scene_targets_by_scene[scene_id] = target_ids


func _load_world_hotspots() -> void:
	if not FileAccess.file_exists(WORLD_HOTSPOTS_PATH):
		push_warning("World hotspot file not found: %s" % WORLD_HOTSPOTS_PATH)
		return
	var file := FileAccess.open(WORLD_HOTSPOTS_PATH, FileAccess.READ)
	if file == null:
		push_warning("Failed to open world hotspot file: %s" % WORLD_HOTSPOTS_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Failed to parse world hotspot file: %s" % WORLD_HOTSPOTS_PATH)
		return
	var data: Dictionary = parsed
	_world_default_scene = str(data.get("default_scene", "world_overview"))
	var canvas_size: Dictionary = data.get("canvas_size", {})
	_world_canvas_size = Vector2(
		float(canvas_size.get("width", 1280.0)),
		float(canvas_size.get("height", 720.0))
	)
	_world_map_hotspots.clear()
	for item: Variant in data.get("hotspots", []):
		if typeof(item) == TYPE_DICTIONARY:
			_world_map_hotspots.append(item)


func _pick_world_hotspot(position: Vector2) -> Dictionary:
	var matches: Array[Dictionary] = []
	for hotspot: Dictionary in _world_map_hotspots:
		if not _is_world_hotspot_enabled(hotspot):
			continue
		var rect := _rect_from_hotspot(hotspot)
		if rect.has_point(position):
			matches.append(hotspot)
	if matches.is_empty():
		return {}
	matches.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_priority := int(a.get("priority", 0))
		var b_priority := int(b.get("priority", 0))
		var a_kind := str(a.get("kind", ""))
		var b_kind := str(b.get("kind", ""))
		if quest_active:
			if a_kind == "place" and b_kind != "place":
				return true
			if b_kind == "place" and a_kind != "place":
				return false
		else:
			if a_kind == "memory_anchor" and b_kind != "memory_anchor":
				return true
			if b_kind == "memory_anchor" and a_kind != "memory_anchor":
				return false
		if a_priority != b_priority:
			return a_priority > b_priority
		var a_rect := _rect_from_hotspot(a)
		var b_rect := _rect_from_hotspot(b)
		return a_rect.size.x * a_rect.size.y < b_rect.size.x * b_rect.size.y
	)
	return matches[0]


func _rect_from_hotspot(hotspot: Dictionary) -> Rect2:
	var rect_data: Dictionary = hotspot.get("rect", {})
	return Rect2(
		Vector2(float(rect_data.get("x", 0.0)), float(rect_data.get("y", 0.0))),
		Vector2(float(rect_data.get("w", 0.0)), float(rect_data.get("h", 0.0)))
	)


func _rect_from_target(target: Dictionary) -> Rect2:
	var rect_data: Dictionary = target.get("rect", {})
	return Rect2(
		Vector2(float(rect_data.get("x", 0.0)), float(rect_data.get("y", 0.0))),
		Vector2(float(rect_data.get("w", 0.0)), float(rect_data.get("h", 0.0)))
	)


func _is_world_hotspot_enabled(hotspot: Dictionary) -> bool:
	var after_prologue_unlocked := (
		GameState.has_story_flag(WorldOverviewRules.STORY_FLAG_AZ_FULL_UNLOCKED)
		or GameState.has_completed_quest(WorldOverviewRules.PROLOGUE_QUEST_ID)
	)
	return WorldOverviewRules.is_hotspot_enabled(
		hotspot,
		current_quest_id,
		after_prologue_unlocked
	)
