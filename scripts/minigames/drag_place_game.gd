extends Node2D

signal completed
signal feedback(message: String, item_id: String, target_id: String)

const ITEM_SIZE := Vector2(96, 56)
const TARGET_SIZE := Vector2(150, 92)

const ITEM_DEFS := {
	"book": {
		"label": "Book",
		"start": Vector2(145, 520),
		"target": "shelf",
		"color": Color(0.20, 0.45, 0.85, 0.18),
		"icon": "res://assets/generated/props/room/prop_book_v001.png"
	},
	"pencil": {
		"label": "Pencil",
		"start": Vector2(340, 520),
		"target": "desk",
		"color": Color(0.92, 0.68, 0.22, 0.18),
		"icon": "res://assets/generated/props/room/prop_pencil_v001.png"
	},
	"bag": {
		"label": "Bag",
		"start": Vector2(535, 520),
		"target": "under_desk",
		"color": Color(0.82, 0.28, 0.24, 0.18),
		"icon": "res://assets/generated/props/room/prop_schoolbag_blue_v001.png"
	}
}

const TARGET_DEFS := {
	"shelf": {
		"label": "Shelf",
		"center": Vector2(230, 170)
	},
	"desk": {
		"label": "Desk",
		"center": Vector2(520, 170)
	},
	"under_desk": {
		"label": "Under desk",
		"center": Vector2(810, 170)
	}
}

var _placed_items: Dictionary = {}
var _item_nodes: Dictionary = {}
var _target_nodes: Dictionary = {}
var _drag_item_id := ""
var _drag_offset := Vector2.ZERO
var _is_completed := false


func _ready() -> void:
	if _item_nodes.is_empty():
		_build_board()


func place_item(item_id: String, target_id: String) -> bool:
	if _is_completed or _placed_items.has(item_id):
		return false
	if not ITEM_DEFS.has(item_id) or not TARGET_DEFS.has(target_id):
		return false

	if ITEM_DEFS[item_id]["target"] != target_id:
		feedback.emit("wrong_target", item_id, target_id)
		return false

	_mark_item_placed(item_id, target_id)
	return true


func placed_count() -> int:
	return _placed_items.size()


func is_complete() -> bool:
	return _is_completed


func reset_game() -> void:
	_placed_items.clear()
	_is_completed = false
	_drag_item_id = ""
	for item_id in ITEM_DEFS:
		var item_node := _item_nodes.get(item_id) as ColorRect
		if item_node == null:
			continue
		item_node.position = _item_top_left(ITEM_DEFS[item_id]["start"])
		item_node.mouse_filter = Control.MOUSE_FILTER_STOP
		item_node.modulate = Color.WHITE


func _build_board() -> void:
	for target_id in TARGET_DEFS:
		var target := ColorRect.new()
		target.name = "%sTarget" % target_id.capitalize()
		target.position = _target_top_left(TARGET_DEFS[target_id]["center"])
		target.size = TARGET_SIZE
		target.color = Color(0.16, 0.18, 0.20, 0.72)
		add_child(target)
		_target_nodes[target_id] = target

		var label := Label.new()
		label.text = TARGET_DEFS[target_id]["label"]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size = TARGET_SIZE
		target.add_child(label)

	for item_id in ITEM_DEFS:
		var item := ColorRect.new()
		item.name = "%sItem" % item_id.capitalize()
		item.position = _item_top_left(ITEM_DEFS[item_id]["start"])
		item.size = ITEM_SIZE
		item.color = ITEM_DEFS[item_id]["color"]
		item.mouse_filter = Control.MOUSE_FILTER_STOP
		item.gui_input.connect(_on_item_gui_input.bind(item_id))
		add_child(item)
		_item_nodes[item_id] = item

		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.texture = load(str(ITEM_DEFS[item_id]["icon"]))
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.size = ITEM_SIZE
		item.add_child(icon)

		var label := Label.new()
		label.text = ITEM_DEFS[item_id]["label"]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size = ITEM_SIZE
		item.add_child(label)


func _on_item_gui_input(event: InputEvent, item_id: String) -> void:
	if _is_completed or _placed_items.has(item_id):
		return

	var item := _item_nodes[item_id] as ColorRect
	if item == null:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_item_id = item_id
			_drag_offset = event.global_position - item.global_position
			item.move_to_front()
		elif _drag_item_id == item_id:
			_drop_dragged_item(item_id)
	elif event is InputEventMouseMotion and _drag_item_id == item_id:
		item.global_position = event.global_position - _drag_offset


func _drop_dragged_item(item_id: String) -> void:
	_drag_item_id = ""
	var item := _item_nodes[item_id] as ColorRect
	if item == null:
		return

	var target_id := target_at_position(item.global_position + item.size * 0.5)
	if target_id.is_empty():
		feedback.emit("missed_target", item_id, "")
		item.position = _item_top_left(ITEM_DEFS[item_id]["start"])
		return

	if not place_item(item_id, target_id):
		item.position = _item_top_left(ITEM_DEFS[item_id]["start"])


func target_at_position(global_point: Vector2) -> String:
	for target_id in TARGET_DEFS:
		var target := _target_nodes.get(target_id) as ColorRect
		if target != null and Rect2(target.global_position, target.size).has_point(global_point):
			return target_id
	return ""


func _mark_item_placed(item_id: String, target_id: String) -> void:
	_placed_items[item_id] = target_id
	var item := _item_nodes.get(item_id) as ColorRect
	var target := _target_nodes.get(target_id) as ColorRect
	if item != null and target != null:
		item.position = target.position + (target.size - item.size) * 0.5
		item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.modulate = Color(0.9, 1.0, 0.9)

	if _placed_items.size() == ITEM_DEFS.size():
		_is_completed = true
		completed.emit()


func _item_top_left(center: Vector2) -> Vector2:
	return center - ITEM_SIZE * 0.5


func _target_top_left(center: Vector2) -> Vector2:
	return center - TARGET_SIZE * 0.5
