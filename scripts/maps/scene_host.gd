extends Node2D

signal mina_interaction_requested(dialogue_id: String)
signal place_clicked(target_id: String)
signal memory_anchor_clicked(anchor_id: String)
signal npc_interaction_requested(dialogue_id: String)
signal home_pet_action_requested(action_id: String)
signal home_room_explore_requested(quest_id: String)

const STANDARD_SCENE_SIZE := Vector2(1280.0, 720.0)
const DEFAULT_WORLD_OVERVIEW_SIZE := Vector2(2560.0, 1440.0)
const VIEWPORT_SIZE := Vector2(1280.0, 720.0)
const HOME_DIALOGUE_SEQUENCE := [
	{"quest_id": "prologue_letter_box", "dialogue_id": "mina_letter_box_intro"},
	{"quest_id": "prologue_room_starter", "dialogue_id": "mina_room_starter_intro"},
	{"quest_id": "prologue_pet_hello", "dialogue_id": "mina_pet_hello_intro"},
	{"quest_id": "prologue_home_pet_care", "dialogue_id": "mina_home_pet_care_intro"},
	{"quest_id": "prologue_go_to_school", "dialogue_id": "mina_first_trip_handoff"}
]

@onready var scene_root: Node2D = $SceneRoot
@onready var home_scene: Node2D = $SceneRoot/HomeScene
@onready var world_overview_scene: Node2D = $SceneRoot/WorldOverviewScene
@onready var campus_gate_scene: Node2D = $SceneRoot/CampusGateScene
@onready var classroom_scene: Node2D = $SceneRoot/ClassroomScene
@onready var garden_scene: Node2D = $SceneRoot/GardenScene
@onready var mina: Area2D = $NpcLayer/Mina
@onready var leo: Area2D = $NpcLayer/Leo
@onready var nora: Area2D = $NpcLayer/Nora
@onready var player: CharacterBody2D = $Player
@onready var world_camera: Camera2D = $Player/Camera2D
@onready var ground: ColorRect = $Ground
@onready var top_wall_shape: RectangleShape2D = $Boundaries/TopWall/CollisionShape2D.shape
@onready var left_wall_shape: RectangleShape2D = $Boundaries/LeftWall/CollisionShape2D.shape

var active_scene_id := "home"
var current_quest_id := ""
var _world_pan_dragging := false
var _world_pan_active_pointer := MOUSE_BUTTON_RIGHT


func _ready() -> void:
	_connect_npc(mina)
	_connect_npc(leo)
	_connect_npc(nora)
	home_scene.return_requested.connect(_on_home_return_requested)
	home_scene.pet_action_requested.connect(home_pet_action_requested.emit)
	home_scene.room_explore_requested.connect(home_room_explore_requested.emit)
	world_overview_scene.target_clicked.connect(place_clicked.emit)
	world_overview_scene.memory_anchor_clicked.connect(memory_anchor_clicked.emit)
	for scene_node in _scene_nodes().values():
		scene_node.visible = false
	show_scene(active_scene_id)


func _unhandled_input(event: InputEvent) -> void:
	if active_scene_id != "world_overview":
		return
	if event is InputEventMouseButton and event.button_index == _world_pan_active_pointer:
		_world_pan_dragging = event.pressed
		get_viewport().set_input_as_handled()
		return
	if _world_pan_dragging and event is InputEventMouseMotion:
		player.position = _clamp_player_to_world(player.position - event.relative)
		if world_camera != null:
			world_camera.force_update_scroll()
		get_viewport().set_input_as_handled()


func show_scene(scene_id: String) -> void:
	if not _scene_nodes().has(scene_id):
		push_warning("Unknown scene id requested: %s" % scene_id)
		return
	var previous_scene_id := active_scene_id
	var preserved_player_position := player.position if player != null else Vector2.ZERO
	var should_preserve_player_position := previous_scene_id == scene_id
	var previous_scene := get_scene_root(previous_scene_id)
	if previous_scene != null and previous_scene.has_method("exit_scene"):
		previous_scene.exit_scene()
	active_scene_id = scene_id
	_world_pan_dragging = false
	for key in _scene_nodes().keys():
		_scene_nodes()[key].visible = key == scene_id
		if _scene_nodes()[key].has_method("set_active_scene"):
			_scene_nodes()[key].set_active_scene(scene_id)
	var current_scene := get_active_scene_root()
	if current_scene != null and current_scene.has_method("enter_scene"):
		current_scene.enter_scene()
	_apply_scene_setup(scene_id, preserved_player_position, should_preserve_player_position)
	if world_camera != null:
		world_camera.force_update_scroll()


func get_active_scene() -> String:
	return active_scene_id


func get_active_scene_root() -> Node:
	return get_scene_root(active_scene_id)


func get_scene_root(scene_id: String) -> Node:
	return _scene_nodes().get(scene_id, null)


func get_hotspot_by_id(hotspot_id: String) -> Dictionary:
	return world_overview_scene.get_hotspot_by_id(hotspot_id)


func get_all_world_hotspots() -> Array[Dictionary]:
	if world_overview_scene.has_method("get_all_world_hotspots"):
		return world_overview_scene.get_all_world_hotspots()
	return []


func get_click_game() -> Node:
	if world_overview_scene != null and world_overview_scene.has_node("ClickGame"):
		return world_overview_scene.get_node("ClickGame")
	return null


func get_world_overview_size() -> Vector2:
	if world_overview_scene.has_method("get_world_canvas_size"):
		return world_overview_scene.get_world_canvas_size()
	return DEFAULT_WORLD_OVERVIEW_SIZE


func get_world_overview_spawn_position() -> Vector2:
	var home_rect: Rect2 = world_overview_scene.get_hotspot_rect("home")
	var school_rect: Rect2 = world_overview_scene.get_hotspot_rect("sunshine_school")
	if home_rect.size != Vector2.ZERO and school_rect.size != Vector2.ZERO:
		return Vector2(
			(home_rect.position.x + home_rect.size.x * 0.5 + school_rect.position.x + school_rect.size.x * 0.18) * 0.5,
			clamp(home_rect.position.y + home_rect.size.y * 0.78, 0.0, get_world_overview_size().y)
		)
	if school_rect.size != Vector2.ZERO:
		return Vector2(
			school_rect.position.x + school_rect.size.x * 0.5,
			school_rect.position.y + school_rect.size.y * 0.75
		)
	return DEFAULT_WORLD_OVERVIEW_SIZE * 0.5


func get_world_overview_camera_rect() -> Rect2:
	var map_size := get_world_overview_size()
	var origin := Vector2(
		clamp(player.global_position.x - VIEWPORT_SIZE.x * 0.5, 0.0, map_size.x - VIEWPORT_SIZE.x),
		clamp(player.global_position.y - VIEWPORT_SIZE.y * 0.5, 0.0, map_size.y - VIEWPORT_SIZE.y)
	)
	return Rect2(origin, VIEWPORT_SIZE)


func focus_world_hotspot(hotspot_id: String) -> void:
	if active_scene_id != "world_overview":
		show_scene("world_overview")
	var hotspot_rect: Rect2 = world_overview_scene.get_hotspot_rect(hotspot_id)
	if hotspot_rect.size == Vector2.ZERO:
		return
	player.position = _clamp_player_to_world(hotspot_rect.get_center())
	if world_camera != null:
		world_camera.force_update_scroll()


func set_npc_prompts_visible(is_visible: bool) -> void:
	for npc: Area2D in [mina, leo, nora]:
		if npc.has_method("set_prompt_visible"):
			npc.set_prompt_visible(is_visible)


func set_click_input_enabled(is_enabled: bool) -> void:
	world_overview_scene.set_input_enabled(is_enabled)


func set_quest_active(is_active: bool) -> void:
	world_overview_scene.set_quest_active(is_active)


func set_task_active(is_active: bool) -> void:
	set_quest_active(is_active)


func set_current_quest_id(quest_id: String) -> void:
	current_quest_id = quest_id
	world_overview_scene.set_current_quest_id(quest_id)
	if home_scene.has_method("set_current_quest_id"):
		home_scene.set_current_quest_id(quest_id)


func set_current_lesson_id(lesson_id: String) -> void:
	set_current_quest_id(lesson_id)


func update_home_pet_ui(
	coins: int,
	pet_state: Dictionary,
	feedback: String = "",
	pet_item_status_text: String = "No pet bowl yet",
	outfit_status_text: String = "Everyday outfit",
	room_decor_status_text: String = "Cozy room",
	pet_name: String = "Sunny"
) -> void:
	if home_scene.has_method("update_pet_ui"):
		home_scene.update_pet_ui(coins, pet_state, feedback, pet_item_status_text, outfit_status_text, room_decor_status_text, pet_name)


func play_home_pet_action_feedback(action_id: String) -> void:
	if home_scene.has_method("play_pet_action_feedback"):
		home_scene.play_pet_action_feedback(action_id)


func _apply_scene_setup(scene_id: String, preserved_player_position: Vector2, should_preserve_player_position: bool) -> void:
	if scene_id == "world_overview":
		_configure_scene_geometry(get_world_overview_size())
		player.visible = true
		player.position = preserved_player_position if should_preserve_player_position else get_world_overview_spawn_position()
		_set_npc_active(mina, false)
		_set_npc_active(leo, false)
		_set_npc_active(nora, false)
	elif scene_id == "home":
		_configure_scene_geometry(STANDARD_SCENE_SIZE)
		player.visible = true
		player.position = preserved_player_position if should_preserve_player_position else Vector2(320, 525)
		_set_npc_active(mina, true)
		if mina.has_method("set_dialogue_id"):
			mina.set_dialogue_id(_next_home_dialogue_id())
		mina.position = Vector2(760, 410)
		_set_npc_active(leo, false)
		_set_npc_active(nora, false)
	elif scene_id == "campus_gate":
		_configure_scene_geometry(STANDARD_SCENE_SIZE)
		player.visible = true
		player.position = preserved_player_position if should_preserve_player_position else Vector2(640, 420)
		_set_npc_active(mina, true)
		if mina.has_method("set_dialogue_id"):
			mina.set_dialogue_id("mina_intro")
		mina.position = Vector2(560, 320)
		_set_npc_active(leo, false)
		_set_npc_active(nora, false)
	elif scene_id == "classroom":
		_configure_scene_geometry(STANDARD_SCENE_SIZE)
		player.visible = true
		player.position = preserved_player_position if should_preserve_player_position else Vector2(310, 520)
		_set_npc_active(mina, false)
		_set_npc_active(leo, true)
		leo.position = Vector2(530, 318)
		_set_npc_active(nora, false)
	elif scene_id == "garden":
		_configure_scene_geometry(STANDARD_SCENE_SIZE)
		player.visible = true
		player.position = preserved_player_position if should_preserve_player_position else Vector2(300, 560)
		_set_npc_active(mina, false)
		_set_npc_active(nora, true)
		nora.position = Vector2(735, 320)
		_set_npc_active(leo, false)


func _scene_nodes() -> Dictionary:
	return {
		"home": home_scene,
		"world_overview": world_overview_scene,
		"campus_gate": campus_gate_scene,
		"classroom": classroom_scene,
		"garden": garden_scene
	}


func _configure_scene_geometry(size: Vector2) -> void:
	if ground != null:
		ground.size = size
	var width := size.x
	var height := size.y
	if top_wall_shape != null:
		top_wall_shape.size = Vector2(width, 32.0)
	if left_wall_shape != null:
		left_wall_shape.size = Vector2(32.0, height)
	$Boundaries/TopWall.position = Vector2(width * 0.5, 16.0)
	$Boundaries/BottomWall.position = Vector2(width * 0.5, height - 16.0)
	$Boundaries/LeftWall.position = Vector2(16.0, height * 0.5)
	$Boundaries/RightWall.position = Vector2(width - 16.0, height * 0.5)
	if world_camera != null:
		world_camera.limit_left = 0
		world_camera.limit_top = 0
		world_camera.limit_right = int(width)
		world_camera.limit_bottom = int(height)


func _clamp_player_to_world(position: Vector2) -> Vector2:
	var map_size := get_world_overview_size()
	return Vector2(
		clamp(position.x, 32.0, map_size.x - 32.0),
		clamp(position.y, 32.0, map_size.y - 32.0)
	)


func _set_npc_active(npc: Area2D, is_active: bool) -> void:
	if npc.has_method("set_active_state"):
		npc.set_active_state(is_active)
	else:
		npc.visible = is_active


func _connect_npc(npc: Area2D) -> void:
	npc.interaction_requested.connect(func(dialogue_id: String) -> void:
		if npc == mina:
			mina_interaction_requested.emit(dialogue_id)
		npc_interaction_requested.emit(dialogue_id)
	)


func _on_home_return_requested() -> void:
	if active_scene_id != "home":
		return
	show_scene("world_overview")
	set_click_input_enabled(true)
	set_quest_active(false)


func _next_home_dialogue_id() -> String:
	for step: Dictionary in HOME_DIALOGUE_SEQUENCE:
		var quest_id := str(step.get("quest_id", ""))
		if not quest_id.is_empty() and not GameState.has_completed_quest(quest_id):
			return str(step.get("dialogue_id", "mina_home_intro"))
	return "mina_home_intro"
