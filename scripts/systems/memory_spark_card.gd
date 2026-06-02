extends CanvasLayer

signal completed(anchor_id: String)
signal closed

@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var prompt_label: Label = $Panel/MarginContainer/VBoxContainer/PromptLabel
@onready var reward_label: Label = $Panel/MarginContainer/VBoxContainer/RewardLabel
@onready var choices_grid: GridContainer = $Panel/MarginContainer/VBoxContainer/ChoicesGrid
@onready var feedback_label: Label = $Panel/MarginContainer/VBoxContainer/FeedbackLabel

var anchor_id := ""
var answer := ""
var success_text := ""


func _ready() -> void:
	visible = false


func show_spark(id: String, spark_data: Dictionary) -> void:
	anchor_id = id
	answer = str(spark_data.get("answer", ""))
	success_text = str(spark_data.get("success_text", "Great memory!"))
	title_label.text = "Memory Spark"
	prompt_label.text = str(spark_data.get("prompt", "Look at the picture clue. What comes back?"))
	reward_label.text = "+%s coin for this memory spark" % str(int(spark_data.get("reward_coins", 1)))
	feedback_label.text = "Use the picture clue and tap the memory word."
	for child in choices_grid.get_children():
		child.queue_free()
	for choice_value: Variant in spark_data.get("choices", []):
		var choice := str(choice_value)
		var button := Button.new()
		button.text = choice
		button.custom_minimum_size = Vector2(150, 46)
		button.pressed.connect(_on_choice_pressed.bind(choice))
		choices_grid.add_child(button)
	visible = true


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		visible = false
		closed.emit()


func _on_choice_pressed(choice: String) -> void:
	if choice != answer:
		feedback_label.text = "Try again. Look at the picture clue."
		return
	feedback_label.text = success_text
	visible = false
	completed.emit(anchor_id)
