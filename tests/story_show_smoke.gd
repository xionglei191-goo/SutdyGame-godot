extends SceneTree

var _completed_count := 0


func _initialize() -> void:
	var game_state: Node = root.get_node("GameState")
	game_state.reset_progress()
	var scene: PackedScene = load("res://scenes/ui/StoryShow.tscn")
	var story_show: CanvasLayer = scene.instantiate()
	root.add_child(story_show)
	await process_frame

	story_show.completed.connect(func() -> void:
		_completed_count += 1
	)
	story_show.start_review()
	_assert(story_show.prompts.size() == 25, "Story Show should have 25 prompts")
	_assert_timed_read_aloud_contract(story_show)
	_assert_story_show_prompt_tone(story_show)
	_assert(story_show.visible, "Story Show should be visible after start")
	_assert(story_show.current_index == 0, "Story Show should start at first prompt")
	story_show.choose("wrong")
	_assert(story_show.current_index == 0, "wrong answer should not advance")
	_assert(_completed_count == 0, "wrong answer should not complete")

	while story_show.visible:
		var previous_index: int = story_show.current_index
		var prompt: Dictionary = story_show.prompts[story_show.current_index]
		if prompt.get("mode", "") == "read_aloud":
			_assert(story_show.feedback_label.text.contains("say it aloud"), "read prompt should use show-line language")
			_assert(not story_show.timer_label.visible, "timer should stay hidden before reading starts")
			story_show.choose(str(prompt["answer"]))
			_assert(story_show.current_index == previous_index, "read prompt should not advance before timer")
			story_show._start_reading_timer()
			_assert(story_show.read_timer.wait_time == float(prompt["read_seconds"]), "read timer should use prompt seconds")
			_assert(story_show.feedback_label.text.contains("Say it aloud"), "read timer state should keep show-line instruction visible")
			_assert(story_show.timer_label.visible, "timer should show while reading is in progress")
			_assert(story_show.timer_label.text.begins_with("Stage time: "), "timer should use show-time wording")
			story_show._on_read_timer_timeout()
			_assert(story_show.feedback_label.text.contains("Tap Continue"), "read prompt should explain how to continue after timer")
			_assert(story_show.timer_label.text == "Stage time: 0s", "timer should reach zero when reading ends")
		story_show.choose(str(prompt["answer"]))

	_assert(_completed_count == 1, "Story Show should complete once")
	_assert(game_state.has_completed_review(story_show.REVIEW_ID), "Story Show completion should be saved in state")
	story_show.choose("done")
	_assert(_completed_count == 1, "hidden Story Show should not complete again")

	print("Story Show smoke test passed.")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)


func _assert_timed_read_aloud_contract(story_show: CanvasLayer) -> void:
	var read_prompts: Array[Dictionary] = []
	var total_seconds := 0.0
	var expected_seconds := [5.0, 5.0, 5.0, 5.0, 5.0, 5.0]
	for prompt: Dictionary in story_show.prompts:
		if str(prompt.get("mode", "")) != "read_aloud":
			continue
		read_prompts.append(prompt)
		_assert(prompt.has("read_seconds"), "every read prompt should define read_seconds")
		var seconds := float(prompt["read_seconds"])
		_assert(seconds >= 5.0, "each read prompt should be at least 5 seconds")
		total_seconds += seconds
	_assert(read_prompts.size() == 6, "Story Show should have 6 timed read-aloud prompts")
	if read_prompts.size() != 6:
		return
	for i in range(expected_seconds.size()):
		_assert(float(read_prompts[i]["read_seconds"]) == float(expected_seconds[i]), "read prompt %d should keep expected duration" % [i + 1])
	_assert(total_seconds >= 30.0, "read-aloud prompts should provide at least 30 fixed seconds")


func _assert_story_show_prompt_tone(story_show: CanvasLayer) -> void:
	var banned_phrases := [
		"Find the word",
		"Choose:",
		"Choose the",
			"Which word means",
			"Round 2",
			"Read aloud:",
			"library card",
			"school place",
			"library scene"
		]
	for prompt: Dictionary in story_show.prompts:
		var text := str(prompt.get("prompt", ""))
		for phrase in banned_phrases:
			_assert(not text.contains(phrase), "Story Show prompt should avoid exercise wording: %s" % text)
