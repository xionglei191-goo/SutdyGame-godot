extends CanvasLayer

signal dialogue_finished(dialogue_id: String)

@onready var panel: Panel = $Panel
@onready var speaker_label: Label = $Panel/MarginContainer/VBoxContainer/SpeakerLabel
@onready var body_label: Label = $Panel/MarginContainer/VBoxContainer/BodyLabel
@onready var continue_label: Label = $Panel/MarginContainer/VBoxContainer/ContinueLabel

var dialogue_id := ""
var lines: Array = []
var current_index := 0


func _ready() -> void:
	visible = false


func start_dialogue(id: String) -> void:
	var data := _load_dialogue(id)
	dialogue_id = id
	lines = data.get("lines", [])
	current_index = 0
	if lines.is_empty():
		dialogue_finished.emit(dialogue_id)
		return
	visible = true
	_show_current_line()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_next_line()
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_finish()


func _show_current_line() -> void:
	var line: Dictionary = lines[current_index]
	speaker_label.text = line.get("speaker", "Mina")
	body_label.text = line.get("text", "")
	continue_label.text = "Press E / Space"


func _next_line() -> void:
	current_index += 1
	if current_index >= lines.size():
		_finish()
	else:
		_show_current_line()


func _finish() -> void:
	visible = false
	dialogue_finished.emit(dialogue_id)


func _load_dialogue(id: String) -> Dictionary:
	var file := FileAccess.open("res://data/dialogues/%s.json" % id, FileAccess.READ)
	if file == null:
		push_error("Dialogue not found: %s" % id)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Dialogue parse failed: %s" % id)
		return {}
	return parsed
