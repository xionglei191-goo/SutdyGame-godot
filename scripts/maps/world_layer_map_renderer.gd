extends Node2D

const LAYER_MAP_PATH := "res://data/maps/sunshine_world_layer_map_v001.json"
const DEFAULT_CANVAS_SIZE := Vector2(2560.0, 2560.0)
const DEFAULT_TILE_SIZE := 128

var layer_map_path := LAYER_MAP_PATH
var _map_id := ""
var _render_mode := ""
var _canvas_size := DEFAULT_CANVAS_SIZE
var _grid_columns := 20
var _grid_rows := 20
var _tile_size := DEFAULT_TILE_SIZE
var _tile_palette: Dictionary = {}
var _tile_layers: Array = []
var _object_layers: Array = []
var _tile_map_layers: Array[TileMapLayer] = []
var _tile_set: TileSet
var _tile_source_ids: Dictionary = {}
var _tile_cells_written := 0
var _loaded := false


func _ready() -> void:
	load_layer_map()


func load_layer_map() -> void:
	_loaded = false
	_clear_tile_map_layers()
	_tile_palette.clear()
	_tile_layers.clear()
	_object_layers.clear()
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
	_render_mode = str(data.get("render_mode", ""))
	var canvas_data: Dictionary = data.get("canvas_size", {})
	_canvas_size = Vector2(
		float(canvas_data.get("width", DEFAULT_CANVAS_SIZE.x)),
		float(canvas_data.get("height", DEFAULT_CANVAS_SIZE.y))
	)
	var grid_data: Dictionary = data.get("grid_size", {})
	_grid_columns = int(grid_data.get("columns", int(_canvas_size.x / DEFAULT_TILE_SIZE)))
	_grid_rows = int(grid_data.get("rows", int(_canvas_size.y / DEFAULT_TILE_SIZE)))
	_tile_size = int(data.get("tile_size", DEFAULT_TILE_SIZE))
	_tile_palette = data.get("tile_palette", {})
	for layer_value: Variant in data.get("tile_layers", []):
		if typeof(layer_value) == TYPE_DICTIONARY:
			_tile_layers.append(layer_value)
	for layer_value: Variant in data.get("object_layers", []):
		if typeof(layer_value) == TYPE_DICTIONARY:
			_object_layers.append(layer_value)
	_loaded = true
	_rebuild_tile_map_layers()
	queue_redraw()


func has_loaded_layer_map() -> bool:
	return _loaded


func get_layer_map_id() -> String:
	return _map_id


func get_render_mode() -> String:
	return _render_mode


func get_tile_layer_count() -> int:
	return _tile_layers.size()


func get_native_tile_map_layer_count() -> int:
	return _tile_map_layers.size()


func get_native_tile_cell_count() -> int:
	return _tile_cells_written


func get_object_layer_count() -> int:
	return _object_layers.size()


func get_landmark_object_count() -> int:
	var count := 0
	for layer_value: Variant in _object_layers:
		if typeof(layer_value) != TYPE_DICTIONARY:
			continue
		var layer: Dictionary = layer_value
		for object_value: Variant in layer.get("objects", []):
			if typeof(object_value) == TYPE_DICTIONARY and str((object_value as Dictionary).get("type", "")) == "landmark_asset":
				count += 1
	return count


func get_pending_landmark_asset_count() -> int:
	var count := 0
	for layer_value: Variant in _object_layers:
		if typeof(layer_value) != TYPE_DICTIONARY:
			continue
		var layer: Dictionary = layer_value
		for object_value: Variant in layer.get("objects", []):
			if typeof(object_value) != TYPE_DICTIONARY:
				continue
			var object_data: Dictionary = object_value
			if str(object_data.get("type", "")) == "landmark_asset" and str(object_data.get("asset_status", "")) == "pending_builtin_imagegen":
				count += 1
	return count


func get_layer_canvas_size() -> Vector2:
	return _canvas_size


func _draw() -> void:
	if not _loaded:
		draw_rect(Rect2(Vector2.ZERO, DEFAULT_CANVAS_SIZE), Color("#bfe7b2"))
		return
	for layer_value: Variant in _object_layers:
		if typeof(layer_value) != TYPE_DICTIONARY:
			continue
		_draw_object_layer(layer_value)


func _clear_tile_map_layers() -> void:
	for child: Node in get_children():
		if child is TileMapLayer:
			remove_child(child)
			child.queue_free()
	_tile_map_layers.clear()
	_tile_set = null
	_tile_source_ids.clear()
	_tile_cells_written = 0


func _rebuild_tile_map_layers() -> void:
	_tile_set = _build_tile_set()
	for layer_value: Variant in _tile_layers:
		if typeof(layer_value) != TYPE_DICTIONARY:
			continue
		var layer_data: Dictionary = layer_value
		var tile_map_layer := TileMapLayer.new()
		tile_map_layer.name = "TileLayer_%s" % str(layer_data.get("id", "unnamed"))
		tile_map_layer.tile_set = _tile_set
		tile_map_layer.z_index = -100 + _tile_map_layers.size()
		add_child(tile_map_layer)
		_tile_map_layers.append(tile_map_layer)
		match str(layer_data.get("type", "")):
			"tile_fill":
				_fill_native_tile_layer(tile_map_layer, layer_data)
			"tile_rects":
				_fill_native_tile_rects(tile_map_layer, layer_data)
			"tile_path":
				_fill_native_tile_path(tile_map_layer, layer_data)


func _build_tile_set() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(_tile_size, _tile_size)
	_tile_source_ids.clear()
	for tile_id_value: Variant in _tile_palette.keys():
		var tile_id := str(tile_id_value)
		_add_tile_source(tile_set, tile_id, false)
		_add_tile_source(tile_set, tile_id, true)
	return tile_set


func _add_tile_source(tile_set: TileSet, tile_id: String, alternate: bool) -> void:
	var image := Image.create(_tile_size, _tile_size, false, Image.FORMAT_RGBA8)
	image.fill(_tile_color_for_variant(tile_id, alternate))
	var outline_width := int(_tile_outline_width(tile_id))
	if outline_width > 0:
		_paint_tile_outline(image, _tile_outline_color(tile_id), outline_width)
	var texture := ImageTexture.create_from_image(image)
	var atlas_source := TileSetAtlasSource.new()
	atlas_source.texture = texture
	atlas_source.texture_region_size = Vector2i(_tile_size, _tile_size)
	atlas_source.create_tile(Vector2i.ZERO)
	var source_id := tile_set.add_source(atlas_source)
	_tile_source_ids[_tile_variant_key(tile_id, alternate)] = source_id


func _paint_tile_outline(image: Image, color: Color, width: int) -> void:
	var max_width: int = int(_tile_size * 0.5)
	if max_width > 16:
		max_width = 16
	var clamped_width: int = width
	if clamped_width < 0:
		clamped_width = 0
	if clamped_width > max_width:
		clamped_width = max_width
	for offset in range(clamped_width):
		for x in range(_tile_size):
			image.set_pixel(x, offset, color)
			image.set_pixel(x, _tile_size - 1 - offset, color)
		for y in range(_tile_size):
			image.set_pixel(offset, y, color)
			image.set_pixel(_tile_size - 1 - offset, y, color)


func _fill_native_tile_layer(tile_map_layer: TileMapLayer, layer: Dictionary) -> void:
	var tile_id := str(layer.get("tile_id", "grass"))
	var bounds: Dictionary = layer.get("bounds", {})
	var columns := int(bounds.get("columns", _grid_columns))
	var rows := int(bounds.get("rows", _grid_rows))
	for row in range(rows):
		for column in range(columns):
			_set_native_tile_cell(tile_map_layer, tile_id, column, row)


func _fill_native_tile_rects(tile_map_layer: TileMapLayer, layer: Dictionary) -> void:
	for rect_value: Variant in layer.get("rects", []):
		if typeof(rect_value) != TYPE_DICTIONARY:
			continue
		var rect_data: Dictionary = rect_value
		var tile_id := str(rect_data.get("tile_id", "grass"))
		var col := int(rect_data.get("col", 0))
		var row := int(rect_data.get("row", 0))
		var cols := int(rect_data.get("cols", 1))
		var rows := int(rect_data.get("rows", 1))
		for row_offset in range(rows):
			for col_offset in range(cols):
				_set_native_tile_cell(tile_map_layer, tile_id, col + col_offset, row + row_offset)


func _fill_native_tile_path(tile_map_layer: TileMapLayer, layer: Dictionary) -> void:
	var tile_id := str(layer.get("tile_id", "road"))
	for cell_value: Variant in layer.get("cells", []):
		if typeof(cell_value) != TYPE_DICTIONARY:
			continue
		var cell_data: Dictionary = cell_value
		_set_native_tile_cell(tile_map_layer, tile_id, int(cell_data.get("col", 0)), int(cell_data.get("row", 0)))


func _set_native_tile_cell(tile_map_layer: TileMapLayer, tile_id: String, column: int, row: int) -> void:
	if column < 0 or row < 0 or column >= _grid_columns or row >= _grid_rows:
		return
	var alternate := (column + row) % 2 != 0
	var source_id := int(_tile_source_ids.get(_tile_variant_key(tile_id, alternate), -1))
	if source_id < 0:
		return
	tile_map_layer.set_cell(Vector2i(column, row), source_id, Vector2i.ZERO)
	_tile_cells_written += 1


func _draw_object_layer(layer: Dictionary) -> void:
	for object_value: Variant in layer.get("objects", []):
		if typeof(object_value) != TYPE_DICTIONARY:
			continue
		var object_data: Dictionary = object_value
		match str(object_data.get("type", "")):
			"landmark_asset":
				_draw_landmark_asset(object_data)
			"circle_cluster":
				_draw_circle_cluster(object_data)


func _draw_landmark_asset(object_data: Dictionary) -> void:
	var rect := _rect_from_data(object_data.get("rect", {}))
	var asset_path := str(object_data.get("asset_path", ""))
	if not asset_path.is_empty() and ResourceLoader.exists(asset_path):
		var texture := load(asset_path)
		if texture is Texture2D:
			draw_texture_rect(texture, rect, false)
			return
	var fallback_tile_id := str(object_data.get("fallback_tile_id", "shop_building"))
	var color := _tile_color(fallback_tile_id, 0, 0)
	var outline_color := _tile_outline_color(fallback_tile_id)
	var outline_width := _tile_outline_width(fallback_tile_id)
	draw_rect(rect, color)
	if outline_width > 0.0:
		draw_rect(rect, outline_color, false, outline_width)
	var requested_roof_height: float = rect.size.y * 0.32
	var roof_height: float = requested_roof_height if requested_roof_height < 56.0 else 56.0
	var roof_points := PackedVector2Array([
		Vector2(rect.position.x + rect.size.x * 0.08, rect.position.y + roof_height),
		Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y),
		Vector2(rect.position.x + rect.size.x * 0.92, rect.position.y + roof_height)
	])
	draw_colored_polygon(roof_points, outline_color)


func _draw_circle_cluster(object_data: Dictionary) -> void:
	var tile_id := str(object_data.get("tile_id", "tree"))
	var radius := float(object_data.get("radius", 24.0))
	var color := _tile_color(tile_id, 0, 0)
	var outline_color := _tile_outline_color(tile_id)
	var outline_width := _tile_outline_width(tile_id)
	for point_value: Variant in object_data.get("points", []):
		if typeof(point_value) != TYPE_DICTIONARY:
			continue
		var point_data: Dictionary = point_value
		var point := Vector2(float(point_data.get("x", 0.0)), float(point_data.get("y", 0.0)))
		if outline_width > 0.0:
			draw_circle(point, radius + outline_width, outline_color)
		draw_circle(point, radius, color)


func _tile_color(tile_id: String, column: int, row: int) -> Color:
	var entry := _tile_entry(tile_id)
	var color := _color_from_value(entry.get("color", "#ffffff"), Color.WHITE)
	var alternate := _color_from_value(entry.get("alternate_color", entry.get("color", "#ffffff")), color)
	return color if (column + row) % 2 == 0 else alternate


func _tile_color_for_variant(tile_id: String, alternate: bool) -> Color:
	var entry := _tile_entry(tile_id)
	var color := _color_from_value(entry.get("color", "#ffffff"), Color.WHITE)
	if not alternate:
		return color
	return _color_from_value(entry.get("alternate_color", entry.get("color", "#ffffff")), color)


func _tile_variant_key(tile_id: String, alternate: bool) -> String:
	return "%s:%s" % [tile_id, "alternate" if alternate else "base"]


func _tile_outline_color(tile_id: String) -> Color:
	var entry := _tile_entry(tile_id)
	return _color_from_value(entry.get("outline_color", "#000000"), Color.BLACK)


func _tile_outline_width(tile_id: String) -> float:
	var entry := _tile_entry(tile_id)
	return float(entry.get("outline_width", 0.0))


func _tile_entry(tile_id: String) -> Dictionary:
	var entry_value: Variant = _tile_palette.get(tile_id, {})
	if typeof(entry_value) == TYPE_DICTIONARY:
		return entry_value
	return {}


func _rect_from_data(value: Variant) -> Rect2:
	if typeof(value) != TYPE_DICTIONARY:
		return Rect2()
	var rect_data: Dictionary = value
	return Rect2(
		Vector2(float(rect_data.get("x", 0.0)), float(rect_data.get("y", 0.0))),
		Vector2(float(rect_data.get("w", 0.0)), float(rect_data.get("h", 0.0)))
	)


func _color_from_value(value: Variant, fallback: Color) -> Color:
	if typeof(value) != TYPE_STRING:
		return fallback
	var text := str(value)
	if text.is_empty():
		return fallback
	return Color(text)
