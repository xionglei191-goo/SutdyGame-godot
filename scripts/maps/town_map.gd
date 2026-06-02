extends Node2D

signal mina_interaction_requested(dialogue_id: String)
signal place_clicked(target_id: String)
signal memory_anchor_clicked(anchor_id: String)
signal npc_interaction_requested(dialogue_id: String)
signal home_pet_action_requested(action_id: String)

const STANDARD_SCENE_SIZE := Vector2(1280.0, 720.0)
const DEFAULT_WORLD_OVERVIEW_SIZE := Vector2(2560.0, 1440.0)
const VIEWPORT_SIZE := Vector2(1280.0, 720.0)

@onready var mina: Area2D = $NpcLayer/Mina
@onready var leo: Area2D = $NpcLayer/Leo
@onready var nora: Area2D = $NpcLayer/Nora
@onready var home_pet_panel: Panel = $HomeLayer/PetPanel
@onready var home_pet_name_label: Label = $HomeLayer/PetPanel/MarginContainer/VBoxContainer/StatsGrid/PetNameValue
@onready var home_pet_coins_label: Label = $HomeLayer/PetPanel/MarginContainer/VBoxContainer/StatsGrid/CoinsValue
@onready var home_pet_state_label: Label = $HomeLayer/PetPanel/MarginContainer/VBoxContainer/StatsGrid/PetStateValue
@onready var home_pet_item_label: Label = $HomeLayer/PetPanel/MarginContainer/VBoxContainer/StatsGrid/PetItemValue
@onready var home_outfit_label: Label = $HomeLayer/PetPanel/MarginContainer/VBoxContainer/StatsGrid/OutfitValue
@onready var home_room_decor_label: Label = $HomeLayer/PetPanel/MarginContainer/VBoxContainer/StatsGrid/RoomDecorValue
@onready var home_pet_feedback_label: Label = $HomeLayer/PetPanel/MarginContainer/VBoxContainer/FeedbackLabel
@onready var home_pet_corner_label: Label = $HomeLayer/PetCorner/PetCornerLabel
@onready var home_return_button: Button = $HomeLayer/ReturnButton
@onready var click_game = $ClickGame
@onready var player: CharacterBody2D = $Player
@onready var world_camera: Camera2D = $Player/Camera2D
@onready var ground: ColorRect = $Ground
@onready var top_wall_shape: RectangleShape2D = $Boundaries/TopWall/CollisionShape2D.shape
@onready var left_wall_shape: RectangleShape2D = $Boundaries/LeftWall/CollisionShape2D.shape

var active_scene_id := "home"
var _world_pan_dragging := false
var _world_pan_active_pointer := MOUSE_BUTTON_RIGHT


func _ready() -> void:
	_connect_npc(mina)
	_connect_npc(leo)
	_connect_npc(nora)
	if home_return_button != null and not home_return_button.pressed.is_connected(_on_home_return_pressed):
		home_return_button.pressed.connect(_on_home_return_pressed)
	if has_node("HomeLayer/PetPanel/MarginContainer/VBoxContainer/ActionButtons/FeedButton"):
		var feed_button: Button = $HomeLayer/PetPanel/MarginContainer/VBoxContainer/ActionButtons/FeedButton
		if not feed_button.pressed.is_connected(_on_home_pet_feed_pressed):
			feed_button.pressed.connect(_on_home_pet_feed_pressed)
	if has_node("HomeLayer/PetPanel/MarginContainer/VBoxContainer/ActionButtons/CleanButton"):
		var clean_button: Button = $HomeLayer/PetPanel/MarginContainer/VBoxContainer/ActionButtons/CleanButton
		if not clean_button.pressed.is_connected(_on_home_pet_clean_pressed):
			clean_button.pressed.connect(_on_home_pet_clean_pressed)
	if has_node("HomeLayer/PetPanel/MarginContainer/VBoxContainer/ActionButtons/PlayButton"):
		var play_button: Button = $HomeLayer/PetPanel/MarginContainer/VBoxContainer/ActionButtons/PlayButton
		if not play_button.pressed.is_connected(_on_home_pet_play_pressed):
			play_button.pressed.connect(_on_home_pet_play_pressed)
	if has_node("HomeLayer/PetPanel/MarginContainer/VBoxContainer/ActionButtons/RestButton"):
		var rest_button: Button = $HomeLayer/PetPanel/MarginContainer/VBoxContainer/ActionButtons/RestButton
		if not rest_button.pressed.is_connected(_on_home_pet_rest_pressed):
			rest_button.pressed.connect(_on_home_pet_rest_pressed)
	if home_pet_panel != null:
		home_pet_panel.visible = false
	click_game.target_clicked.connect(func(target_id: String) -> void:
		place_clicked.emit(target_id)
	)
	click_game.memory_anchor_clicked.connect(func(anchor_id: String) -> void:
		memory_anchor_clicked.emit(anchor_id)
	)
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
	active_scene_id = scene_id
	_world_pan_dragging = false
	for scene_node in [$WorldOverviewLayer, $HomeLayer, $CampusGateLayer, $ClassroomLayer, $GardenLayer]:
		scene_node.visible = scene_node.name.to_snake_case().replace("_layer", "") == scene_id
	$Paths.visible = scene_id == "campus_gate"
	$PlaceLayer.visible = scene_id == "campus_gate"
	if click_game.has_method("set_active_scene"):
		click_game.set_active_scene(scene_id)
	if scene_id == "world_overview":
		_configure_scene_geometry(get_world_overview_size())
		player.visible = true
		player.position = get_world_overview_spawn_position()
		_set_npc_active(mina, false)
		_set_npc_active(leo, false)
		_set_npc_active(nora, false)
	elif scene_id == "home":
		_configure_scene_geometry(STANDARD_SCENE_SIZE)
		player.visible = true
		player.position = Vector2(320, 525)
		if home_pet_panel != null:
			home_pet_panel.visible = true
		_set_npc_active(mina, true)
		if mina.has_method("set_dialogue_id"):
			if GameState.has_completed_quest("prologue_letter_box"):
				mina.set_dialogue_id("mina_home_intro")
			else:
				mina.set_dialogue_id("mina_letter_box_intro")
		mina.position = Vector2(760, 410)
		_set_npc_active(leo, false)
		_set_npc_active(nora, false)
	elif scene_id == "campus_gate":
		_configure_scene_geometry(STANDARD_SCENE_SIZE)
		player.visible = true
		player.position = Vector2(640, 420)
		if home_pet_panel != null:
			home_pet_panel.visible = false
		_set_npc_active(mina, true)
		if mina.has_method("set_dialogue_id"):
			mina.set_dialogue_id("mina_intro")
		mina.position = Vector2(560, 320)
		_set_npc_active(leo, false)
		_set_npc_active(nora, false)
	elif scene_id == "classroom":
		_configure_scene_geometry(STANDARD_SCENE_SIZE)
		player.visible = true
		player.position = Vector2(310, 520)
		if home_pet_panel != null:
			home_pet_panel.visible = false
		_set_npc_active(mina, false)
		_set_npc_active(leo, true)
		leo.position = Vector2(530, 318)
		_set_npc_active(nora, false)
	elif scene_id == "garden":
		_configure_scene_geometry(STANDARD_SCENE_SIZE)
		player.visible = true
		player.position = Vector2(300, 560)
		if home_pet_panel != null:
			home_pet_panel.visible = false
		_set_npc_active(mina, false)
		_set_npc_active(nora, true)
		nora.position = Vector2(735, 320)
		_set_npc_active(leo, false)
	if world_camera != null:
		world_camera.force_update_scroll()


func get_active_scene() -> String:
	return active_scene_id


func get_hotspot_by_id(hotspot_id: String) -> Dictionary:
	if click_game.has_method("get_hotspot_by_id"):
		return click_game.get_hotspot_by_id(hotspot_id)
	return {}


func get_world_overview_size() -> Vector2:
	if click_game.has_method("get_world_canvas_size"):
		return click_game.get_world_canvas_size()
	return DEFAULT_WORLD_OVERVIEW_SIZE


func get_world_overview_spawn_position() -> Vector2:
	if click_game.has_method("get_hotspot_rect"):
		var home_rect: Rect2 = click_game.get_hotspot_rect("home")
		var school_rect: Rect2 = click_game.get_hotspot_rect("sunshine_school")
		if home_rect.size != Vector2.ZERO and school_rect.size != Vector2.ZERO:
			return Vector2(
				(home_rect.position.x + home_rect.size.x * 0.5 + school_rect.position.x + school_rect.size.x * 0.18) * 0.5,
				clamp(home_rect.position.y + home_rect.size.y * 0.78, 0.0, get_world_overview_size().y)
			)
	if click_game.has_method("get_hotspot_rect"):
		var school_rect: Rect2 = click_game.get_hotspot_rect("sunshine_school")
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
	if not click_game.has_method("get_hotspot_rect"):
		return
	var hotspot_rect: Rect2 = click_game.get_hotspot_rect(hotspot_id)
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
	if click_game.has_method("set_input_enabled"):
		click_game.set_input_enabled(is_enabled)


func set_quest_active(is_active: bool) -> void:
	if click_game.has_method("set_quest_active"):
		click_game.set_quest_active(is_active)


func set_task_active(is_active: bool) -> void:
	# Legacy compatibility wrapper. New code should call set_quest_active().
	set_quest_active(is_active)


func set_current_quest_id(quest_id: String) -> void:
	if click_game.has_method("set_current_quest_id"):
		click_game.set_current_quest_id(quest_id)


func set_current_lesson_id(lesson_id: String) -> void:
	# Legacy compatibility wrapper. New code should call set_current_quest_id().
	set_current_quest_id(lesson_id)


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


func _on_home_return_pressed() -> void:
	if active_scene_id != "home":
		return
	show_scene("world_overview")
	set_click_input_enabled(true)
	set_quest_active(false)


func _on_home_pet_feed_pressed() -> void:
	home_pet_action_requested.emit("feed")


func _on_home_pet_clean_pressed() -> void:
	home_pet_action_requested.emit("clean")


func _on_home_pet_play_pressed() -> void:
	home_pet_action_requested.emit("play")


func _on_home_pet_rest_pressed() -> void:
	home_pet_action_requested.emit("rest")


func update_home_pet_ui(
	coins: int,
	pet_state: Dictionary,
	feedback: String = "",
	pet_item_status_text: String = "No pet bowl yet",
	outfit_status_text: String = "Everyday outfit",
	room_decor_status_text: String = "Cozy room",
	pet_name: String = "Sunny"
) -> void:
	if home_pet_name_label != null:
		home_pet_name_label.text = pet_name
	if home_pet_corner_label != null:
		home_pet_corner_label.text = "%s's corner" % pet_name
	if home_pet_coins_label != null:
		home_pet_coins_label.text = str(coins)
	if home_pet_state_label != null:
		home_pet_state_label.text = "Hunger %s / Clean %s / Mood %s / Bond %s" % [
			str(int(pet_state.get("hunger", 0))),
			str(int(pet_state.get("cleanliness", 0))),
			str(int(pet_state.get("mood", 0))),
			str(int(pet_state.get("bond", 0)))
		]
		if pet_state.has("rest"):
			home_pet_state_label.text += " / Rest %s" % str(int(pet_state.get("rest", 0)))
	if home_pet_item_label != null:
		home_pet_item_label.text = pet_item_status_text
	if home_outfit_label != null:
		home_outfit_label.text = outfit_status_text
	if home_room_decor_label != null:
		home_room_decor_label.text = room_decor_status_text
	if home_pet_feedback_label != null and not feedback.is_empty():
		home_pet_feedback_label.text = feedback
