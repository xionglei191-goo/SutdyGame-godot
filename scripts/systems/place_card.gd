extends CanvasLayer

signal closed
signal action_requested(place_id: String, action_id: String)

@onready var blocker: Control = $Blocker
@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var place_label: Label = $Panel/MarginContainer/VBoxContainer/PlaceLabel
@onready var hint_label: Label = $Panel/MarginContainer/VBoxContainer/HintLabel
@onready var reward_label: Label = $Panel/MarginContainer/VBoxContainer/RewardLabel
@onready var action_button: Button = $Panel/MarginContainer/VBoxContainer/ActionButton
@onready var continue_label: Label = $Panel/MarginContainer/VBoxContainer/ContinueLabel

var place_id := ""
var primary_action_id := ""


func _ready() -> void:
	visible = false
	if blocker != null:
		blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	if action_button != null and not action_button.pressed.is_connected(_on_action_button_pressed):
		action_button.pressed.connect(_on_action_button_pressed)


func show_place(id: String, display_name: String, is_first_visit: bool, hint_text: String = "", primary_action: Dictionary = {}) -> void:
	place_id = id
	title_label.text = "Town Visit"
	place_label.text = display_name
	hint_label.text = hint_text if not hint_text.is_empty() else "You visited a new place."
	reward_label.text = "+1 coin" if is_first_visit else "Already visited"
	set_primary_action(primary_action)
	continue_label.text = "Press E / Space"
	visible = true


func set_status(message: String) -> void:
	reward_label.text = message


func set_primary_action(primary_action: Dictionary = {}) -> void:
	primary_action_id = str(primary_action.get("id", ""))
	if action_button == null:
		return
	if primary_action_id.is_empty():
		action_button.visible = false
		action_button.text = "Buy"
		return
	action_button.visible = true
	action_button.text = str(primary_action.get("label", "Continue"))


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		visible = false
		closed.emit()


func _on_action_button_pressed() -> void:
	if primary_action_id.is_empty():
		return
	action_requested.emit(place_id, primary_action_id)
