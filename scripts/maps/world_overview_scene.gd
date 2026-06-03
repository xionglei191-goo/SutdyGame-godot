extends Node2D

signal target_clicked(target_id: String)
signal memory_anchor_clicked(anchor_id: String)

const DEFAULT_WORLD_OVERVIEW_SIZE := Vector2(2560.0, 2560.0)

@onready var click_game: Node = $ClickGame
@onready var layer_map: Node2D = $LayerMap


func _ready() -> void:
	click_game.target_clicked.connect(func(target_id: String) -> void:
		target_clicked.emit(target_id)
	)
	click_game.memory_anchor_clicked.connect(func(anchor_id: String) -> void:
		memory_anchor_clicked.emit(anchor_id)
	)


func enter_scene() -> void:
	if click_game.has_method("set_active_scene"):
		click_game.set_active_scene("world_overview")


func exit_scene() -> void:
	pass


func set_active_scene(scene_id: String) -> void:
	if click_game.has_method("set_active_scene"):
		click_game.set_active_scene(scene_id)


func set_input_enabled(is_enabled: bool) -> void:
	if click_game.has_method("set_input_enabled"):
		click_game.set_input_enabled(is_enabled)


func set_quest_active(is_active: bool) -> void:
	if click_game.has_method("set_quest_active"):
		click_game.set_quest_active(is_active)


func set_current_quest_id(quest_id: String) -> void:
	if click_game.has_method("set_current_quest_id"):
		click_game.set_current_quest_id(quest_id)


func get_hotspot_by_id(hotspot_id: String) -> Dictionary:
	if click_game.has_method("get_hotspot_by_id"):
		return click_game.get_hotspot_by_id(hotspot_id)
	return {}


func get_hotspot_rect(hotspot_id: String) -> Rect2:
	if click_game.has_method("get_hotspot_rect"):
		return click_game.get_hotspot_rect(hotspot_id)
	return Rect2()


func get_world_canvas_size() -> Vector2:
	if click_game.has_method("get_world_canvas_size"):
		return click_game.get_world_canvas_size()
	return DEFAULT_WORLD_OVERVIEW_SIZE


func get_all_world_hotspots() -> Array[Dictionary]:
	if "_world_map_hotspots" in click_game:
		return click_game._world_map_hotspots
	return []


func has_layer_map() -> bool:
	return layer_map != null and layer_map.has_method("has_loaded_layer_map") and layer_map.has_loaded_layer_map()


func get_layer_map_id() -> String:
	if layer_map != null and layer_map.has_method("get_layer_map_id"):
		return layer_map.get_layer_map_id()
	return ""
