extends SceneTree

var _completed_count := 0
var _feedback_events: Array[String] = []


func _initialize() -> void:
	var drag_place_scene: PackedScene = load("res://scenes/minigames/DragPlaceGame.tscn")
	var game: Node = drag_place_scene.instantiate()
	root.add_child(game)
	await process_frame

	game.completed.connect(func() -> void:
		_completed_count += 1
	)
	game.feedback.connect(func(message: String, item_id: String, target_id: String) -> void:
		_feedback_events.append("%s:%s:%s" % [message, item_id, target_id])
	)

	_assert(not game.place_item("book", "desk"), "book should not fit desk")
	_assert(_feedback_events.has("wrong_target:book:desk"), "wrong placement should emit feedback")
	_assert(game.place_item("book", "shelf"), "book should fit shelf")
	_assert(game.place_item("pencil", "desk"), "pencil should fit desk")
	_assert(_completed_count == 0, "game should wait for every item")
	_assert(game.place_item("bag", "under_desk"), "bag should fit under desk")
	_assert(game.is_complete(), "game should be complete")
	_assert(_completed_count == 1, "completed signal should emit once")
	_assert(game.placed_count() == 3, "all items should be placed")

	print("Drag place game smoke test passed.")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
