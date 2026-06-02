extends CanvasLayer

signal completed

const REVIEW_ID := "mvp_0_2_review_challenge"
const REVIEW_TITLE := "Story Show"

@onready var panel: Panel = $Panel
@onready var progress_label: Label = $Panel/MarginContainer/VBoxContainer/ProgressLabel
@onready var prompt_label: Label = $Panel/MarginContainer/VBoxContainer/PromptLabel
@onready var timer_label: Label = $Panel/MarginContainer/VBoxContainer/TimerLabel
@onready var choices_container: GridContainer = $Panel/MarginContainer/VBoxContainer/ChoicesGrid
@onready var feedback_label: Label = $Panel/MarginContainer/VBoxContainer/FeedbackLabel
@onready var read_timer: Timer = $ReadTimer

var prompts: Array[Dictionary] = [
	{"prompt": "Show Mina's story stop.", "answer": "library", "choices": ["library", "classroom", "playground"]},
	{"prompt": "Finish Mina's line: This is the ...", "answer": "library", "choices": ["library", "flower", "bag"]},
	{"prompt": "Pack the story book.", "answer": "book", "choices": ["book", "tree", "bird"]},
	{"prompt": "Place the pencil on the right spot.", "answer": "desk", "choices": ["desk", "garden", "playground"]},
	{"prompt": "Pack Leo's blue bag.", "answer": "bag", "choices": ["bag", "library", "flower"]},
	{"prompt": "Spot Nora's garden friend.", "answer": "bird", "choices": ["bird", "book", "desk"]},
	{"prompt": "Send the bird to its home.", "answer": "tree", "choices": ["tree", "shelf", "classroom"]},
	{"prompt": "Add garden color to the show.", "answer": "flower", "choices": ["flower", "pencil", "library"]},
	{"prompt": "Point to the play place: 操场.", "answer": "playground", "choices": ["playground", "shelf", "bag"]},
	{"prompt": "Say Mina's story line.", "answer": "This is the library.", "choices": ["This is the library.", "Put the bag under the desk.", "Where is the bird?"]},
	{"prompt": "Help Leo place the book.", "answer": "Put the book on the shelf.", "choices": ["Put the book on the shelf.", "This is our classroom.", "I see flowers in the garden."]},
	{"prompt": "Ask about Nora's bird.", "answer": "Where is the bird?", "choices": ["Where is the bird?", "This is the library.", "Put the pencil on the desk."]},
	{"prompt": "Say on stage: Mina's story line.", "answer": "I read it", "choices": ["I read it"], "mode": "read_aloud", "read_seconds": 5.0},
	{"prompt": "Say on stage: Put the book on the shelf.", "answer": "I read it", "choices": ["I read it"], "mode": "read_aloud", "read_seconds": 5.0},
	{"prompt": "Say on stage: Where is the bird?", "answer": "I read it", "choices": ["I read it"], "mode": "read_aloud", "read_seconds": 5.0},
	{"prompt": "Next scene: story room stop.", "answer": "classroom", "choices": ["classroom", "flower", "bag"]},
	{"prompt": "Next scene: Mina's reading stop.", "answer": "library", "choices": ["library", "desk", "tree"]},
	{"prompt": "Next scene: outdoor play place.", "answer": "playground", "choices": ["playground", "shelf", "pencil"]},
	{"prompt": "Next scene: tidy item.", "answer": "pencil", "choices": ["pencil", "bird", "garden"]},
	{"prompt": "Help Leo place the pencil.", "answer": "Put the pencil on the desk.", "choices": ["Put the pencil on the desk.", "Where is the bird?", "This is the library."]},
	{"prompt": "Show Nora's garden line.", "answer": "I see flowers in the garden.", "choices": ["I see flowers in the garden.", "Put the bag under the desk.", "This is our classroom."]},
	{"prompt": "Answer Nora's bird question.", "answer": "The bird is in the tree.", "choices": ["The bird is in the tree.", "The book is on the shelf.", "This is the playground."]},
	{"prompt": "Say on stage: Put the pencil on the desk.", "answer": "I read it", "choices": ["I read it"], "mode": "read_aloud", "read_seconds": 5.0},
	{"prompt": "Say on stage: I see flowers in the garden.", "answer": "I read it", "choices": ["I read it"], "mode": "read_aloud", "read_seconds": 5.0},
	{"prompt": "Great job! Say your favorite word.", "answer": "done", "choices": ["done"], "mode": "read_aloud", "read_seconds": 5.0}
]
var current_index := 0
var waiting_for_read_timer := false


func _ready() -> void:
	visible = false
	read_timer.timeout.connect(_on_read_timer_timeout)
	timer_label.visible = false


func _process(_delta: float) -> void:
	if not visible or not _is_read_aloud_prompt() or not waiting_for_read_timer or read_timer.is_stopped():
		return
	timer_label.visible = true
	timer_label.text = "Stage time: %ds" % int(ceil(read_timer.time_left))


func start_review() -> void:
	if GameState.has_completed_review(REVIEW_ID):
		visible = false
		completed.emit()
		return
	current_index = 0
	visible = true
	_show_prompt()


func choose(choice: String) -> void:
	if not visible:
		return
	var answer: String = str(prompts[current_index]["answer"])
	if choice != answer:
		feedback_label.text = "Try again. Look at the story clue."
		return
	if _is_read_aloud_prompt() and choice != "start_reading" and waiting_for_read_timer:
		feedback_label.text = "Say it aloud first. Wait for the button."
		return
	feedback_label.text = "Nice show!"
	current_index += 1
	if current_index >= prompts.size():
		visible = false
		GameState.complete_review(REVIEW_ID)
		GameState.save_game()
		completed.emit()
	else:
		_show_prompt()


func _show_prompt() -> void:
	progress_label.text = "Show %d / %d" % [current_index + 1, prompts.size()]
	prompt_label.text = str(prompts[current_index]["prompt"])
	feedback_label.text = ""
	timer_label.visible = false
	timer_label.text = ""
	for child in choices_container.get_children():
		child.queue_free()
	if _is_read_aloud_prompt():
		waiting_for_read_timer = true
		feedback_label.text = "Tap Start, say it aloud, then wait for Continue."
		_add_choice_button("Start", "start_reading")
		return
	for choice: String in prompts[current_index]["choices"]:
		_add_choice_button(choice, choice)


func _add_choice_button(text: String, choice: String) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(150, 46)
	if choice == "start_reading":
		button.pressed.connect(_start_reading_timer)
	else:
		button.pressed.connect(choose.bind(choice))
	choices_container.add_child(button)


func _is_read_aloud_prompt() -> bool:
	return str(prompts[current_index].get("mode", "")) == "read_aloud"


func _start_reading_timer() -> void:
	if not visible or not _is_read_aloud_prompt():
		return
	for child in choices_container.get_children():
		child.queue_free()
	feedback_label.text = "Say it aloud now and wait for Continue."
	read_timer.wait_time = float(prompts[current_index].get("read_seconds", 5.0))
	read_timer.start()
	timer_label.visible = true
	timer_label.text = "Stage time: %ds" % int(ceil(read_timer.time_left))


func _on_read_timer_timeout() -> void:
	if not visible or not _is_read_aloud_prompt():
		return
	waiting_for_read_timer = false
	timer_label.visible = true
	timer_label.text = "Stage time: 0s"
	feedback_label.text = "Tap Continue when your show line is done."
	_add_choice_button(_continue_button_text(), str(prompts[current_index]["answer"]))


func _continue_button_text() -> String:
	var answer: String = str(prompts[current_index].get("answer", ""))
	if answer == "done":
		return "Continue"
	return "Line done"
