extends Node2D

signal return_requested
signal pet_action_requested(action_id: String)
signal room_explore_requested(quest_id: String)

const PetVisualController = preload("res://scripts/systems/pet_visual_controller.gd")
const HomeDecorRenderer = preload("res://scripts/systems/home_decor_renderer.gd")

const PET_HELLO_QUEST_ID := "prologue_pet_hello"
const HOME_PET_CARE_QUEST_ID := "prologue_home_pet_care"

@onready var pet_panel: Panel = $PetPanel
@onready var pet_name_label: Label = $PetPanel/MarginContainer/VBoxContainer/StatsGrid/PetNameValue
@onready var coins_label: Label = $PetPanel/MarginContainer/VBoxContainer/StatsGrid/CoinsValue
@onready var pet_state_label: Label = $PetPanel/MarginContainer/VBoxContainer/StatsGrid/PetStateValue
@onready var pet_item_label: Label = $PetPanel/MarginContainer/VBoxContainer/StatsGrid/PetItemValue
@onready var outfit_label: Label = $PetPanel/MarginContainer/VBoxContainer/StatsGrid/OutfitValue
@onready var room_decor_label: Label = $PetPanel/MarginContainer/VBoxContainer/StatsGrid/RoomDecorValue
@onready var feedback_label: Label = $PetPanel/MarginContainer/VBoxContainer/FeedbackLabel
@onready var pet_corner_label: Label = $PetCorner/PetCornerLabel
@onready var return_button: Button = $ReturnButton
@onready var pet_close_button: Button = $PetPanel/CloseButton
@onready var pet_open_button: Button = $PetCorner/OpenPetPanelButton
@onready var pet_state_display: Sprite2D = $PetCorner/PetStateDisplay
@onready var decor_slot_rug: Sprite2D = $DecorSlot_Rug
@onready var decor_slot_cape: Sprite2D = $DecorSlot_Cape
@onready var room_explore_button: Button = $RoomExploreButton
@onready var room_explore_panel: Panel = $RoomExplorePanel
@onready var room_explore_light_button: Button = $RoomExplorePanel/MarginContainer/VBoxContainer/RoomLightButton
@onready var room_explore_window_button: Button = $RoomExplorePanel/MarginContainer/VBoxContainer/WindowWatchButton
@onready var room_explore_close_button: Button = $RoomExplorePanel/CloseButton

var current_quest_id := ""
var is_active_scene := false
var _pet_panel_manually_closed := false
var _pet_visual_controller := PetVisualController.new()
var _home_decor_renderer := HomeDecorRenderer.new()


func _ready() -> void:
	_pet_visual_controller.configure(pet_state_display, GameState.get_pet_state())
	_home_decor_renderer.configure(decor_slot_rug, decor_slot_cape)
	if GameState.has_signal("owned_items_changed") and not GameState.owned_items_changed.is_connected(_home_decor_renderer.refresh):
		GameState.owned_items_changed.connect(_home_decor_renderer.refresh)
	_connect_button(return_button, _on_return_pressed)
	_connect_button(pet_close_button, _on_pet_close_pressed)
	_connect_button(pet_open_button, _on_pet_open_pressed)
	_connect_button(room_explore_button, _on_room_explore_open_pressed)
	_connect_button(room_explore_light_button, _on_room_explore_light_pressed)
	_connect_button(room_explore_window_button, _on_room_explore_window_pressed)
	_connect_button(room_explore_close_button, _on_room_explore_close_pressed)
	_connect_button($PetPanel/MarginContainer/VBoxContainer/ActionButtons/FeedButton, _on_pet_feed_pressed)
	_connect_button($PetPanel/MarginContainer/VBoxContainer/ActionButtons/CleanButton, _on_pet_clean_pressed)
	_connect_button($PetPanel/MarginContainer/VBoxContainer/ActionButtons/PlayButton, _on_pet_play_pressed)
	_connect_button($PetPanel/MarginContainer/VBoxContainer/ActionButtons/RestButton, _on_pet_rest_pressed)
	pet_panel.visible = false
	room_explore_panel.visible = false


func _input(event: InputEvent) -> void:
	if not is_active_scene:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse_event := event as InputEventMouseButton
		var click_position: Vector2 = mouse_event.position
		if _screen_point_in_button(pet_close_button, click_position):
			_on_pet_close_pressed()
			get_viewport().set_input_as_handled()
			return
		if _screen_point_in_button(pet_open_button, click_position):
			_on_pet_open_pressed()
			get_viewport().set_input_as_handled()
			return


func enter_scene() -> void:
	is_active_scene = true
	_refresh_pet_panel_visibility()
	_refresh_room_explore_visibility()


func exit_scene() -> void:
	is_active_scene = false
	pet_panel.visible = false
	room_explore_panel.visible = false
	_refresh_room_explore_visibility()


func set_current_quest_id(quest_id: String) -> void:
	current_quest_id = quest_id
	if quest_id == HOME_PET_CARE_QUEST_ID:
		_pet_panel_manually_closed = false
	if is_active_scene:
		_refresh_pet_panel_visibility()


func update_pet_ui(
	coins: int,
	pet_state: Dictionary,
	feedback: String = "",
	pet_item_status_text: String = "No pet bowl yet",
	outfit_status_text: String = "Everyday outfit",
	room_decor_status_text: String = "Cozy room",
	pet_name: String = "Sunny"
) -> void:
	pet_name_label.text = pet_name
	pet_corner_label.text = "%s's corner" % pet_name
	coins_label.text = str(coins)
	pet_state_label.text = "H %s / C %s / M %s / B %s" % [
		str(int(pet_state.get("hunger", 0))),
		str(int(pet_state.get("cleanliness", 0))),
		str(int(pet_state.get("mood", 0))),
		str(int(pet_state.get("bond", 0)))
	]
	if pet_state.has("rest"):
		pet_state_label.text += " / R %s" % str(int(pet_state.get("rest", 0)))
	pet_item_label.text = pet_item_status_text
	outfit_label.text = outfit_status_text
	room_decor_label.text = room_decor_status_text
	if not feedback.is_empty():
		feedback_label.text = feedback
	_pet_visual_controller.apply_pet_state(pet_state)
	_home_decor_renderer.refresh()
	if is_active_scene:
		_refresh_pet_panel_visibility()
		_refresh_room_explore_visibility()


func play_pet_action_feedback(action_id: String) -> void:
	_pet_visual_controller.play_action_feedback(action_id)


func _connect_button(button: Button, callable: Callable) -> void:
	if button != null and not button.pressed.is_connected(callable):
		button.pressed.connect(callable)


func _on_return_pressed() -> void:
	if is_active_scene:
		return_requested.emit()


func _on_pet_close_pressed() -> void:
	_pet_panel_manually_closed = true
	_refresh_pet_panel_visibility()


func _on_pet_open_pressed() -> void:
	_pet_panel_manually_closed = false
	_refresh_pet_panel_visibility()


func _on_pet_feed_pressed() -> void:
	pet_action_requested.emit("feed")


func _on_pet_clean_pressed() -> void:
	pet_action_requested.emit("clean")


func _on_pet_play_pressed() -> void:
	pet_action_requested.emit("play")


func _on_pet_rest_pressed() -> void:
	pet_action_requested.emit("rest")


func _on_room_explore_open_pressed() -> void:
	if is_active_scene:
		room_explore_panel.visible = true


func _on_room_explore_close_pressed() -> void:
	room_explore_panel.visible = false


func _on_room_explore_light_pressed() -> void:
	_start_room_explore("home_room_explore_a")


func _on_room_explore_window_pressed() -> void:
	_start_room_explore("home_room_explore_b")


func _start_room_explore(quest_id: String) -> void:
	room_explore_panel.visible = false
	room_explore_requested.emit(quest_id)


func _screen_point_in_button(button: Button, screen_point: Vector2) -> bool:
	if button == null or not button.visible or not button.is_visible_in_tree() or button.disabled:
		return false
	var local_point := button.get_global_transform_with_canvas().affine_inverse() * screen_point
	return Rect2(Vector2.ZERO, button.size).has_point(local_point)


func _refresh_pet_panel_visibility() -> void:
	var unlocked := _is_pet_panel_unlocked()
	var should_show := is_active_scene and unlocked and not _pet_panel_manually_closed
	pet_panel.visible = should_show
	pet_open_button.visible = is_active_scene and unlocked and not should_show


func _refresh_room_explore_visibility() -> void:
	room_explore_button.visible = is_active_scene
	if not is_active_scene:
		room_explore_panel.visible = false


func _is_pet_panel_unlocked() -> bool:
	return GameState.has_completed_quest(PET_HELLO_QUEST_ID) or current_quest_id == HOME_PET_CARE_QUEST_ID
