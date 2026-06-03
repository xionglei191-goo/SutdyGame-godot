extends Node2D

const LAYER_MAP_PATH := "res://data/maps/sunshine_world_layer_map_v001.json"
const DEFAULT_CANVAS_SIZE := Vector2(2560.0, 2560.0)
const DEFAULT_TILE_SIZE := 128

var layer_map_path := LAYER_MAP_PATH
var _map_id := ""
var _canvas_size := DEFAULT_CANVAS_SIZE
var _tile_size := DEFAULT_TILE_SIZE
var _layers: Array = []
var _loaded := false


func _ready() -> void:
	load_layer_map()


func load_layer_map() -> void:
	_loaded = false
	_layers.clear()
	if not FileAccess.file_exists(layer_map_path):
		push_warning("World layer map file not found: %s" % layer_map_path)
		queue_redraw()
		return
	var file := FileAccess.open(layer_map_path, FileAccess.READ)
	if file == null:
		push_warning("Failed to open world layer map file: %s" % layer_map_path)
		queue_redraw()
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Failed to parse world layer map file: %s" % layer_map_path)
		queue_redraw()
		return
	var data: Dictionary = parsed
	_map_id = str(data.get("map_id", ""))
	var canvas_data: Dictionary = data.get("canvas_size", {})
	_canvas_size = Vector2(
		float(canvas_data.get("width", DEFAULT_CANVAS_SIZE.x)),
		float(canvas_data.get("height", DEFAULT_CANVAS_SIZE.y))
	)
	_tile_size = int(data.get("tile_size", DEFAULT_TILE_SIZE))
	for layer_value: Variant in data.get("layers", []):
		if typeof(layer_value) == TYPE_DICTIONARY:
			_layers.append(layer_value)
	_loaded = true
	queue_redraw()


func has_loaded_layer_map() -> bool:
	return _loaded


func get_layer_map_id() -> String:
	return _map_id


func get_layer_count() -> int:
	return _layers.size()


func get_layer_canvas_size() -> Vector2:
	return _canvas_size


func _draw() -> void:
	if not _loaded:
		draw_rect(Rect2(Vector2.ZERO, DEFAULT_CANVAS_SIZE), Color("#bfe7b2"))
		return
	for layer_value: Variant in _layers:
		if typeof(layer_value) != TYPE_DICTIONARY:
			continue
		var layer: Dictionary = layer_value
		match str(layer.get("type", "")):
			"tile_rect":
				_draw_tile_rect(layer)
			"rect":
				_draw_rect_layer(layer)
			"landmark":
				_draw_rect_layer(layer)
			"polyline":
				_draw_polyline_layer(layer)
			"circle_cluster":
				_draw_circle_cluster(layer)


func _draw_tile_rect(layer: Dictionary) -> void:
	var rect: Rect2 = _rect_from_data(layer.get("rect", {}))
	var requested_size: int = int(layer.get("tile_size", _tile_size))
	var size: int = requested_size if requested_size > 16 else 16
	var color: Color = _color_from_value(layer.get("color", "#bfe7b2"), Color("#bfe7b2"))
	var alternate_color: Color = _color_from_value(layer.get("alternate_color", layer.get("color", "#bfe7b2")), color)
	var columns: int = int(ceil(rect.size.x / float(size)))
	var rows: int = int(ceil(rect.size.y / float(size)))
	for row in range(rows):
		for column in range(columns):
			var tile_rect: Rect2 = Rect2(
				rect.position + Vector2(column * size, row * size),
				Vector2(size, size)
			)
			tile_rect = tile_rect.intersection(rect)
			var tile_color: Color = color if (row + column) % 2 == 0 else alternate_color
			draw_rect(tile_rect, tile_color)


func _draw_rect_layer(layer: Dictionary) -> void:
	var rect := _rect_from_data(layer.get("rect", {}))
	var color := _color_from_value(layer.get("color", "#ffffff"), Color.WHITE)
	draw_rect(rect, color)
	var outline_width := float(layer.get("outline_width", 0.0))
	if outline_width <= 0.0:
		return
	var outline_color := _color_from_value(layer.get("outline_color", "#000000"), Color.BLACK)
	draw_rect(rect, outline_color, false, outline_width)


func _draw_polyline_layer(layer: Dictionary) -> void:
	var points := _points_from_data(layer.get("points", []))
	if points.size() < 2:
		return
	var outline_width := float(layer.get("outline_width", 0.0))
	if outline_width > 0.0:
		var outline_color := _color_from_value(layer.get("outline_color", "#000000"), Color.BLACK)
		_draw_lines(points, outline_color, outline_width)
	var width := float(layer.get("width", 8.0))
	var color := _color_from_value(layer.get("color", "#ffffff"), Color.WHITE)
	_draw_lines(points, color, width)


func _draw_circle_cluster(layer: Dictionary) -> void:
	var points := _points_from_data(layer.get("points", []))
	var radius := float(layer.get("radius", 24.0))
	var color := _color_from_value(layer.get("color", "#7fc46c"), Color("#7fc46c"))
	var outline_color := _color_from_value(layer.get("outline_color", "#4d8d4b"), Color("#4d8d4b"))
	var outline_width := float(layer.get("outline_width", 0.0))
	for point in points:
		if outline_width > 0.0:
			draw_circle(point, radius + outline_width, outline_color)
		draw_circle(point, radius, color)


func _draw_lines(points: PackedVector2Array, color: Color, width: float) -> void:
	for index in range(points.size() - 1):
		draw_line(points[index], points[index + 1], color, width, true)


func _rect_from_data(value: Variant) -> Rect2:
	if typeof(value) != TYPE_DICTIONARY:
		return Rect2()
	var rect_data: Dictionary = value
	return Rect2(
		Vector2(float(rect_data.get("x", 0.0)), float(rect_data.get("y", 0.0))),
		Vector2(float(rect_data.get("w", 0.0)), float(rect_data.get("h", 0.0)))
	)


func _points_from_data(value: Variant) -> PackedVector2Array:
	var points := PackedVector2Array()
	if typeof(value) != TYPE_ARRAY:
		return points
	for point_value: Variant in value:
		if typeof(point_value) != TYPE_DICTIONARY:
			continue
		var point_data: Dictionary = point_value
		points.append(Vector2(
			float(point_data.get("x", 0.0)),
			float(point_data.get("y", 0.0))
		))
	return points


func _color_from_value(value: Variant, fallback: Color) -> Color:
	if typeof(value) != TYPE_STRING:
		return fallback
	var text := str(value)
	if text.is_empty():
		return fallback
	return Color(text)
