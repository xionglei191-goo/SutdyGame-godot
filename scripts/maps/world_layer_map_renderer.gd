extends Node2D

const LAYER_MAP_PATH := "res://data/maps/sunshine_world_layer_map_v001.json"
const WORLD_HOTSPOTS_PATH := "res://data/maps/sunshine_world_hotspots_v001.json"
const DEFAULT_CANVAS_SIZE := Vector2(2560.0, 2560.0)
const DEFAULT_TILE_SIZE := 128

var layer_map_path := LAYER_MAP_PATH
var _map_id := ""
var _render_mode := ""
var _canvas_size := DEFAULT_CANVAS_SIZE
var _grid_columns := 20
var _grid_rows := 20
var _tile_size := DEFAULT_TILE_SIZE
var _tile_atlas: Dictionary = {}
var _tile_palette: Dictionary = {}
var _tile_layers: Array = []
var _object_layers: Array = []
var _grid_rules: Dictionary = {}
var _asset_generation: Dictionary = {}
var _place_hotspot_objects: Array[Dictionary] = []
var _memory_anchor_objects: Array[Dictionary] = []
var _tile_map_layers: Array[TileMapLayer] = []
var _tile_set: TileSet
var _tile_source_ids: Dictionary = {}
var _tile_atlas_loaded := false
var _tile_cells_written := 0
var _loaded := false


func _ready() -> void:
	load_layer_map()


func load_layer_map() -> void:
	_loaded = false
	_clear_tile_map_layers()
	_tile_atlas.clear()
	_tile_palette.clear()
	_tile_layers.clear()
	_object_layers.clear()
	_grid_rules.clear()
	_asset_generation.clear()
	_place_hotspot_objects.clear()
	_memory_anchor_objects.clear()
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
	_tile_atlas = data.get("tile_atlas", {})
	_tile_palette = data.get("tile_palette", {})
	for layer_value: Variant in data.get("tile_layers", []):
		if typeof(layer_value) == TYPE_DICTIONARY:
			_tile_layers.append(layer_value)
	for layer_value: Variant in data.get("object_layers", []):
		if typeof(layer_value) == TYPE_DICTIONARY:
			_object_layers.append(layer_value)
	_grid_rules = data.get("grid_rules", {})
	_asset_generation = data.get("asset_generation", {})
	_load_hotspot_objects()
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


func has_loaded_tile_atlas() -> bool:
	return _tile_atlas_loaded


func get_tile_atlas_path() -> String:
	return str(_tile_atlas.get("asset_path", ""))


func get_tile_atlas_status() -> String:
	return str(_tile_atlas.get("status", ""))


func get_object_layer_count() -> int:
	return _object_layers.size()


func get_landmark_object_count() -> int:
	return _landmark_objects().size()


func get_pending_landmark_asset_count() -> int:
	var count := 0
	for object_data: Dictionary in _landmark_objects():
		if str(object_data.get("asset_status", "")) == "pending_builtin_imagegen":
			count += 1
	return count


func get_generated_landmark_asset_count() -> int:
	var count := 0
	for object_data: Dictionary in _landmark_objects():
		if _landmark_asset_exists(str(object_data.get("asset_path", ""))):
			count += 1
	return count


func get_missing_landmark_asset_count() -> int:
	var count := 0
	for object_data: Dictionary in _landmark_objects():
		var asset_path := str(object_data.get("asset_path", ""))
		if not asset_path.is_empty() and not _landmark_asset_exists(asset_path):
			count += 1
	return count


func get_asset_generation_mode() -> String:
	return str(_asset_generation.get("mode", ""))


func get_asset_generation_preferred_tool() -> String:
	return str(_asset_generation.get("preferred_tool", ""))


func get_asset_generation_current_source() -> String:
	return str(_asset_generation.get("current_source", ""))


func get_asset_generation_status() -> String:
	return str(_asset_generation.get("status", ""))


func get_memory_anchor_marker_count() -> int:
	return _memory_anchor_objects.size()


func get_place_marker_count() -> int:
	var count := 0
	for place_data: Dictionary in _place_hotspot_objects:
		if _place_marker_visual_state(place_data) != "":
			count += 1
	return count


func get_layer_canvas_size() -> Vector2:
	return _canvas_size


func get_grid_rule_style_goal() -> String:
	return str(_grid_rules.get("style_goal", ""))


func get_grid_rule_movement_mode() -> String:
	var movement: Dictionary = _grid_rules.get("movement", {})
	return str(movement.get("mode", ""))


func grid_rules_snap_interactions_to_grid() -> bool:
	var movement: Dictionary = _grid_rules.get("movement", {})
	return bool(movement.get("snap_interactions_to_grid", false))


func get_grid_cell_size() -> int:
	return int(_grid_rules.get("cell_size", _tile_size))


func get_grid_district_count() -> int:
	return _grid_rules_array("districts").size()


func get_grid_occupied_cell_count() -> int:
	var count := 0
	for cell_value: Variant in _grid_rules_array("occupied_cells"):
		if typeof(cell_value) != TYPE_DICTIONARY:
			continue
		var cell_data: Dictionary = cell_value
		count += int(cell_data.get("cols", 1)) * int(cell_data.get("rows", 1))
	return count


func get_grid_interaction_cell_count() -> int:
	return _grid_rules_array("interaction_cells").size()


func get_grid_road_cell_count() -> int:
	var roads: Dictionary = _grid_rules.get("roads", {})
	var count := 0
	for route_id_value: Variant in roads.keys():
		var route_value: Variant = roads.get(route_id_value, [])
		if typeof(route_value) == TYPE_ARRAY:
			count += (route_value as Array).size()
	return count


func get_grid_occupied_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	var cell_size := float(get_grid_cell_size())
	for cell_value: Variant in _grid_rules_array("occupied_cells"):
		if typeof(cell_value) != TYPE_DICTIONARY:
			continue
		var cell_data: Dictionary = cell_value
		rects.append(Rect2(
			Vector2(float(cell_data.get("col", 0)) * cell_size, float(cell_data.get("row", 0)) * cell_size),
			Vector2(float(cell_data.get("cols", 1)) * cell_size, float(cell_data.get("rows", 1)) * cell_size)
		))
	return rects


func get_grid_interaction_cell_for_hotspot(hotspot_id: String) -> Vector2i:
	for cell_value: Variant in _grid_rules_array("interaction_cells"):
		if typeof(cell_value) != TYPE_DICTIONARY:
			continue
		var cell_data: Dictionary = cell_value
		if str(cell_data.get("hotspot_id", "")) == hotspot_id:
			return Vector2i(int(cell_data.get("col", -1)), int(cell_data.get("row", -1)))
	return Vector2i(-1, -1)


func get_grid_interaction_position_for_hotspot(hotspot_id: String) -> Vector2:
	var cell := get_grid_interaction_cell_for_hotspot(hotspot_id)
	if cell.x < 0 or cell.y < 0:
		return Vector2.ZERO
	var cell_size := float(get_grid_cell_size())
	return Vector2((float(cell.x) + 0.5) * cell_size, (float(cell.y) + 0.5) * cell_size)


func is_grid_cell_occupied(column: int, row: int) -> bool:
	for cell_value: Variant in _grid_rules_array("occupied_cells"):
		if typeof(cell_value) != TYPE_DICTIONARY:
			continue
		var cell_data: Dictionary = cell_value
		var start_col := int(cell_data.get("col", -1))
		var start_row := int(cell_data.get("row", -1))
		var cols := int(cell_data.get("cols", 1))
		var rows := int(cell_data.get("rows", 1))
		if column >= start_col and column < start_col + cols and row >= start_row and row < start_row + rows:
			return true
	return false


func is_grid_cell_walkable(column: int, row: int) -> bool:
	if column < 0 or row < 0 or column >= _grid_columns or row >= _grid_rows:
		return false
	return not is_grid_cell_occupied(column, row)


func get_grid_district_id_for_cell(column: int, row: int) -> String:
	for district_value: Variant in _grid_rules_array("districts"):
		if typeof(district_value) != TYPE_DICTIONARY:
			continue
		var district: Dictionary = district_value
		for cell_value: Variant in district.get("cells", []):
			if typeof(cell_value) != TYPE_DICTIONARY:
				continue
			var cell_data: Dictionary = cell_value
			if int(cell_data.get("col", -1)) == column and int(cell_data.get("row", -1)) == row:
				return str(district.get("id", ""))
	return ""


func _draw() -> void:
	if not _loaded:
		draw_rect(Rect2(Vector2.ZERO, DEFAULT_CANVAS_SIZE), Color("#bfe7b2"))
		return
	for layer_value: Variant in _object_layers:
		if typeof(layer_value) != TYPE_DICTIONARY:
			continue
		_draw_object_layer(layer_value)
	_draw_place_markers()
	_draw_memory_anchor_markers()


func _clear_tile_map_layers() -> void:
	for child: Node in get_children():
		if child is TileMapLayer:
			remove_child(child)
			child.queue_free()
	_tile_map_layers.clear()
	_tile_set = null
	_tile_source_ids.clear()
	_tile_atlas_loaded = false
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
	_tile_atlas_loaded = false
	if _try_build_atlas_tile_set(tile_set):
		return tile_set
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
	_tile_source_ids[_tile_variant_key(tile_id, alternate)] = {
		"source_id": source_id,
		"atlas_coord": Vector2i.ZERO
	}


func _try_build_atlas_tile_set(tile_set: TileSet) -> bool:
	var atlas_path := str(_tile_atlas.get("asset_path", ""))
	if atlas_path.is_empty() or not ResourceLoader.exists(atlas_path):
		return false
	var texture := load(atlas_path)
	if not texture is Texture2D:
		return false
	var atlas_source := TileSetAtlasSource.new()
	atlas_source.texture = texture
	atlas_source.texture_region_size = Vector2i(int(_tile_atlas.get("tile_size", _tile_size)), int(_tile_atlas.get("tile_size", _tile_size)))
	var variant_entries: Array[Dictionary] = []
	var created_coords: Dictionary = {}
	for tile_id_value: Variant in _tile_palette.keys():
		var tile_id := str(tile_id_value)
		for alternate in [false, true]:
			var atlas_coord := _atlas_coord_for_variant(tile_id, alternate)
			if atlas_coord.x < 0 or atlas_coord.y < 0:
				return false
			var coord_key := "%s,%s" % [atlas_coord.x, atlas_coord.y]
			if not created_coords.has(coord_key):
				atlas_source.create_tile(atlas_coord)
				created_coords[coord_key] = true
			variant_entries.append({
				"variant_key": _tile_variant_key(tile_id, alternate),
				"atlas_coord": atlas_coord
			})
	var source_id := tile_set.add_source(atlas_source)
	for entry: Dictionary in variant_entries:
		_tile_source_ids[str(entry.get("variant_key", ""))] = {
			"source_id": source_id,
			"atlas_coord": entry.get("atlas_coord", Vector2i.ZERO)
		}
	_tile_atlas_loaded = true
	return true


func _atlas_coord_for_variant(tile_id: String, alternate: bool) -> Vector2i:
	var entry := _tile_entry(tile_id)
	var coord_value: Variant = entry.get("alternate_atlas_coord" if alternate else "atlas_coord", entry.get("atlas_coord", {}))
	if typeof(coord_value) != TYPE_DICTIONARY:
		return Vector2i(-1, -1)
	var coord_data: Dictionary = coord_value
	return Vector2i(int(coord_data.get("x", -1)), int(coord_data.get("y", -1)))


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
	var source_entry: Variant = _tile_source_ids.get(_tile_variant_key(tile_id, alternate), {})
	if typeof(source_entry) != TYPE_DICTIONARY:
		return
	var source_data: Dictionary = source_entry
	var source_id := int(source_data.get("source_id", -1))
	if source_id < 0:
		return
	var atlas_coord: Vector2i = source_data.get("atlas_coord", Vector2i.ZERO)
	tile_map_layer.set_cell(Vector2i(column, row), source_id, atlas_coord)
	_tile_cells_written += 1


func _load_hotspot_objects() -> void:
	if not FileAccess.file_exists(WORLD_HOTSPOTS_PATH):
		push_warning("World hotspot file not found for layer-map overlays: %s" % WORLD_HOTSPOTS_PATH)
		return
	var file := FileAccess.open(WORLD_HOTSPOTS_PATH, FileAccess.READ)
	if file == null:
		push_warning("Failed to open world hotspot file for layer-map overlays: %s" % WORLD_HOTSPOTS_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Failed to parse world hotspot file for layer-map overlays: %s" % WORLD_HOTSPOTS_PATH)
		return
	var data: Dictionary = parsed
	for hotspot_value: Variant in data.get("hotspots", []):
		if typeof(hotspot_value) != TYPE_DICTIONARY:
			continue
		var hotspot: Dictionary = hotspot_value
		match str(hotspot.get("kind", "")):
			"place":
				_place_hotspot_objects.append(hotspot)
			"memory_anchor":
				_memory_anchor_objects.append(hotspot)


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


func _draw_place_markers() -> void:
	for place_data: Dictionary in _place_hotspot_objects:
		_draw_place_marker(place_data)


func _draw_place_marker(place_data: Dictionary) -> void:
	var visual_state := _place_marker_visual_state(place_data)
	if visual_state == "":
		return
	var rect := _rect_from_data(place_data.get("rect", {}))
	if rect.size == Vector2.ZERO:
		return
	var palette := _place_palette(place_data, visual_state)
	var fill_color: Color = palette["fill"]
	var outline_color: Color = palette["outline"]
	var label_fill_color: Color = palette["label_fill"]
	var text_color: Color = palette["text"]
	var should_draw_body := not _place_has_landmark_slot(str(place_data.get("id", ""))) or visual_state == "future"
	if should_draw_body:
		draw_rect(rect, fill_color)
	var outline_width := 4.0 if visual_state == "default" else 3.0
	draw_rect(rect, outline_color, false, outline_width)
	var label := str(place_data.get("label", ""))
	if label.is_empty():
		return
	var font := ThemeDB.get_fallback_font()
	var font_size := _place_label_font_size(rect, visual_state)
	var label_width: float = clampf(rect.size.x * 0.92, 88.0, 340.0)
	var label_height: float = float(font_size) + 14.0
	var label_position := Vector2(
		rect.position.x + (rect.size.x - label_width) * 0.5,
		rect.position.y + 8.0
	)
	if rect.size.y <= label_height + 20.0:
		label_position.y = rect.position.y - label_height - 6.0
	draw_rect(Rect2(label_position, Vector2(label_width, label_height)), label_fill_color)
	draw_rect(Rect2(label_position, Vector2(label_width, label_height)), outline_color, false, 2.0)
	draw_string(
		font,
		Vector2(label_position.x + 6.0, label_position.y + float(font_size) + 2.0),
		label,
		HORIZONTAL_ALIGNMENT_CENTER,
		label_width - 12.0,
		font_size,
		text_color
	)


func _draw_memory_anchor_markers() -> void:
	for anchor_data: Dictionary in _memory_anchor_objects:
		_draw_memory_anchor_marker(anchor_data)


func _draw_memory_anchor_marker(anchor_data: Dictionary) -> void:
	var rect := _rect_from_data(anchor_data.get("rect", {}))
	if rect.size == Vector2.ZERO:
		return
	var center := rect.get_center()
	var radius: float = clamp(min(rect.size.x, rect.size.y) * 0.2, 16.0, 34.0)
	var palette := _memory_anchor_palette(anchor_data)
	var outline_color: Color = palette["outline"]
	var fill_color: Color = palette["fill"]
	var text_color: Color = palette["text"]
	draw_circle(center, radius + 5.0, Color(1.0, 1.0, 1.0, 0.78))
	draw_circle(center, radius + 2.0, outline_color)
	draw_circle(center, radius, fill_color)
	var route_order := int(anchor_data.get("route_order", 0))
	if route_order > 0:
		var tick_angle := -PI * 0.5 + float(route_order - 1) * TAU / 26.0
		var tick_start := center + Vector2(cos(tick_angle), sin(tick_angle)) * (radius + 6.0)
		var tick_end := center + Vector2(cos(tick_angle), sin(tick_angle)) * (radius + 15.0)
		draw_line(tick_start, tick_end, outline_color, 4.0)
	var font := ThemeDB.get_fallback_font()
	var font_size := int(clamp(radius * 1.12, 18.0, 30.0))
	var letter := str(anchor_data.get("letter", ""))
	if not letter.is_empty():
		draw_string(
			font,
			Vector2(center.x - radius, center.y + float(font_size) * 0.36),
			letter,
			HORIZONTAL_ALIGNMENT_CENTER,
			radius * 2.0,
			font_size,
			text_color
		)


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


func _memory_anchor_palette(anchor_data: Dictionary) -> Dictionary:
	var az_unlock_mode := str(anchor_data.get("az_unlock_mode", "after_prologue"))
	var world_enabled_mode := str(anchor_data.get("world_enabled_mode", ""))
	if az_unlock_mode == "starter":
		return {
			"fill": Color("#fff2bd"),
			"outline": Color("#d39b1f"),
			"text": Color("#674a12")
		}
	if world_enabled_mode == "pilot_recall":
		return {
			"fill": Color("#e6f2ff"),
			"outline": Color("#5d84bf"),
			"text": Color("#365f91")
		}
	return {
		"fill": Color("#f4f0e6"),
		"outline": Color("#8f9aa7"),
		"text": Color("#56616d")
	}


func _place_marker_visual_state(place_data: Dictionary) -> String:
	if bool(place_data.get("default_visible", false)):
		return "default"
	if str(place_data.get("world_enabled_mode", "")) == "after_prologue":
		return "future"
	return ""


func _grid_rules_array(key: String) -> Array:
	var value: Variant = _grid_rules.get(key, [])
	if typeof(value) == TYPE_ARRAY:
		return value
	return []


func _place_palette(place_data: Dictionary, visual_state: String) -> Dictionary:
	var zone := str(place_data.get("zone", "community_ring"))
	var fill := Color("#f2e3bd")
	var outline := Color("#9b7a3f")
	var label_fill := Color("#fffaf0")
	var text := Color("#57452a")
	match zone:
		"home_core":
			fill = Color("#f7d7b1")
			outline = Color("#a56c3a")
			text = Color("#6a3f20")
		"school_core":
			fill = Color("#d9ebff")
			outline = Color("#517fb4")
			text = Color("#2f557d")
		"outskirts_transport":
			fill = Color("#dfe8ed")
			outline = Color("#667f8d")
			text = Color("#3f5661")
	if visual_state == "future":
		fill = _with_alpha(fill, 0.26)
		outline = _with_alpha(outline, 0.58)
		label_fill = _with_alpha(label_fill, 0.62)
		text = _with_alpha(text, 0.72)
	else:
		fill = _with_alpha(fill, 0.42)
		label_fill = _with_alpha(label_fill, 0.88)
	return {
		"fill": fill,
		"outline": outline,
		"label_fill": label_fill,
		"text": text
	}


func _place_label_font_size(rect: Rect2, visual_state: String) -> int:
	var size := 24
	if rect.size.x < 160.0:
		size = 18
	elif rect.size.x < 240.0:
		size = 20
	elif rect.size.x > 420.0:
		size = 28
	if visual_state == "future":
		size = max(16, size - 2)
	return size


func _place_has_landmark_slot(hotspot_id: String) -> bool:
	for object_data: Dictionary in _landmark_objects():
		if str(object_data.get("hotspot_id", "")) == hotspot_id:
			return true
	return false


func _landmark_objects() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for layer_value: Variant in _object_layers:
		if typeof(layer_value) != TYPE_DICTIONARY:
			continue
		var layer: Dictionary = layer_value
		for object_value: Variant in layer.get("objects", []):
			if typeof(object_value) != TYPE_DICTIONARY:
				continue
			var object_data: Dictionary = object_value
			if str(object_data.get("type", "")) == "landmark_asset":
				results.append(object_data)
	return results


func _landmark_asset_exists(asset_path: String) -> bool:
	if asset_path.is_empty() or not ResourceLoader.exists(asset_path):
		return false
	var texture := load(asset_path)
	return texture is Texture2D


func _with_alpha(color: Color, alpha: float) -> Color:
	var result := color
	result.a = alpha
	return result


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
