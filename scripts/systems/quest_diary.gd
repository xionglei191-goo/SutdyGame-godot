extends CanvasLayer

signal quest_started(quest_id: String)
signal quest_feedback(message: String)
signal quest_completed(quest_id: String, reward_id: String, reward_name: String)

# Legacy task_* signals are compatibility mirrors for older scenes/tests/reports.
# New systems should connect to quest_* signals.
signal task_started(task_id: String)
signal task_feedback(message: String)
signal task_completed(task_id: String, reward_id: String, reward_name: String)

@export var quest_id := "g4_u1_school_tour"

const PANEL_TITLE := "Quest Diary"
const STATUS_OPEN := "Quest open"
const STATUS_RETRY := "Look again"
const STATUS_DONE := "Done"
const STATUS_TALK_FIRST := "Talk first"

@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var event_label: Label = $Panel/MarginContainer/VBoxContainer/EventLabel
@onready var status_label: Label = $Panel/MarginContainer/VBoxContainer/StatusLabel
@onready var prompt_label: Label = $Panel/MarginContainer/VBoxContainer/PromptLabel
@onready var words_label: Label = $Panel/MarginContainer/VBoxContainer/WordsLabel
@onready var reward_label: Label = $Panel/MarginContainer/VBoxContainer/RewardLabel
@onready var feedback_label: Label = $Panel/MarginContainer/VBoxContainer/FeedbackLabel

var current_quest: Dictionary = {}
var active := false


func _ready() -> void:
	panel.visible = false
	title_label.text = PANEL_TITLE
	event_label.text = ""
	status_label.text = STATUS_OPEN
	reward_label.text = ""


func start_quest(id: String = "") -> void:
	if not id.is_empty():
		quest_id = id
	current_quest = _load_quest(quest_id)
	if current_quest.is_empty():
		return
	active = true
	panel.visible = true
	title_label.text = PANEL_TITLE
	event_label.text = str(current_quest.get("title", quest_id))
	status_label.text = STATUS_OPEN
	prompt_label.text = current_quest.get("prompt", "Follow the story clue.")
	var vocabulary: Array = current_quest.get("vocabulary", [])
	words_label.text = "Quest clues: " + ", ".join(vocabulary)
	reward_label.text = _reward_hint_text()
	feedback_label.text = _start_feedback_text()
	var started_id := str(current_quest.get("id", quest_id))
	quest_started.emit(started_id)
	_emit_legacy_task_started(started_id)


func start_lesson(id: String = "") -> void:
	start_quest(id)


func get_lesson_id() -> String:
	return quest_id


func set_lesson_id(value: String) -> void:
	quest_id = value


func get_current_lesson() -> Dictionary:
	return current_quest


func check_target(target_id: String) -> void:
	if not active:
		status_label.text = STATUS_TALK_FIRST
		_set_feedback("Talk to Mina first.")
		return
	var correct_target: String = str(current_quest.get("correct_target", ""))
	if target_id == correct_target:
		_complete_current_task()
	else:
		var target_labels: Dictionary = current_quest.get("target_labels", {})
		var label: String = str(target_labels.get(target_id, target_id))
		var feedback: String = str(current_quest.get("wrong_target_text", "This is the %s. Try again."))
		if feedback.contains("%s"):
			_set_feedback(feedback % label)
		else:
			_set_feedback(feedback)
		status_label.text = STATUS_RETRY


func complete_drag_task() -> void:
	if not active:
		return
	if str(current_quest.get("type", "")) != "drag_place":
		return
	_complete_current_task()


func complete_pet_care_action(action_id: String) -> void:
	if not active:
		return
	if str(current_quest.get("type", "")) != "pet_care":
		return
	var correct_action := str(current_quest.get("correct_action", ""))
	if action_id == correct_action:
		_complete_current_task()
		return
	status_label.text = STATUS_RETRY
	_set_feedback(str(current_quest.get("wrong_target_text", "Try another pet care button.")))


func dismiss() -> void:
	active = false
	panel.visible = false


func _complete_current_task() -> void:
	var completed_id: String = str(current_quest.get("id", quest_id))
	var reward_id: String = str(current_quest.get("reward_id", ""))
	var reward_name: String = str(current_quest.get("reward_name", reward_id))
	active = false
	status_label.text = STATUS_DONE
	_set_feedback(current_quest.get("success_text", "Great!"))
	GameState.complete_quest(completed_id, current_quest.get("vocabulary", []), current_quest.get("patterns", []))
	quest_completed.emit(completed_id, reward_id, reward_name)
	_emit_legacy_task_completed(completed_id, reward_id, reward_name)


func _set_feedback(message: String) -> void:
	feedback_label.text = message
	quest_feedback.emit(message)
	_emit_legacy_task_feedback(message)


func _emit_legacy_task_started(task_id: String) -> void:
	task_started.emit(task_id)


func _emit_legacy_task_feedback(message: String) -> void:
	task_feedback.emit(message)


func _emit_legacy_task_completed(task_id: String, reward_id: String, reward_name: String) -> void:
	task_completed.emit(task_id, reward_id, reward_name)


func _load_quest(id: String) -> Dictionary:
	var file := FileAccess.open("res://data/quests/%s.json" % id, FileAccess.READ)
	if file == null:
		push_error("Quest data not found in data/quests: %s" % id)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Quest data parse failed: %s" % id)
		return {}
	var quest: Dictionary = parsed
	return quest


func _start_feedback_text() -> String:
	var configured := str(current_quest.get("start_feedback", ""))
	if not configured.is_empty():
		return configured
	if str(current_quest.get("type", "")) == "drag_place":
		return "Set up the story room."
	return "Tap a place on the map."


func _reward_hint_text() -> String:
	var reward_name := str(current_quest.get("reward_name", ""))
	if reward_name.is_empty():
		return ""
	return "Keepsake: %s" % reward_name
