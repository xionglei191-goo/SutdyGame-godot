extends SceneTree

const LAYER_MAP_PATH := "res://data/maps/sunshine_world_layer_map_v001.json"
const HOTSPOTS_PATH := "res://data/maps/sunshine_world_hotspots_v001.json"
const LANDMARK_PROMPT_PATH := "res://assets/source_prompts/maps/world_landmark_assets_pending_v001.md"


func _initialize() -> void:
	var data: Dictionary = _read_json_dict(LAYER_MAP_PATH)
	var hotspot_data: Dictionary = _read_json_dict(HOTSPOTS_PATH)
	_assert(str(data.get("render_mode", "")) == "tile_grid_object_layers", "world layer map should use tile-grid object-layer render mode")
	_assert(not data.has("layers"), "world layer map should not fall back to shape-only layers as the primary map contract")
	var canvas_size: Dictionary = data.get("canvas_size", {})
	var grid_size: Dictionary = data.get("grid_size", {})
	_assert(int(canvas_size.get("width", 0)) == 2560, "world layer map should preserve 2560 width")
	_assert(int(canvas_size.get("height", 0)) == 2560, "world layer map should preserve 2560 height")
	_assert(int(data.get("tile_size", 0)) == 128, "world layer map should use 128px tiles")
	_assert(int(grid_size.get("columns", 0)) == 20, "world layer map should define 20 columns")
	_assert(int(grid_size.get("rows", 0)) == 20, "world layer map should define 20 rows")

	var tile_palette: Dictionary = data.get("tile_palette", {})
	for tile_id in ["grass", "home_yard", "school_ground", "town_plaza", "transport_ground", "road", "school_path"]:
		_assert(tile_palette.has(tile_id), "tile palette should include %s" % tile_id)
	var tile_layers: Array = data.get("tile_layers", [])
	_assert(tile_layers.size() >= 5, "world layer map should define multiple tile layers")
	_assert(_has_tile_layer(tile_layers, "base_grass", "tile_fill"), "world layer map should have a base grass tile fill")
	_assert(_has_tile_layer(tile_layers, "district_tiles", "tile_rects"), "world layer map should have district tile rects")
	_assert(_has_tile_layer(tile_layers, "main_road_tiles", "tile_path"), "world layer map should have a main road tile path")
	_assert(_has_tile_layer(tile_layers, "school_loop_tiles", "tile_path"), "world layer map should have a school loop tile path")
	_assert(_has_tile_layer(tile_layers, "town_shop_street_tiles", "tile_path"), "world layer map should have a town shop street tile path")
	_assert(_has_tile_layer(tile_layers, "transport_route_tiles", "tile_path"), "world layer map should have a transport route tile path")

	var hotspot_rects: Dictionary = _collect_hotspot_rects(hotspot_data.get("hotspots", []))
	var landmark_objects: Dictionary = _collect_landmark_objects(data.get("object_layers", []))
	var required_hotspots := [
		"home",
		"sunshine_school",
		"post_office",
		"bookshop",
		"restaurant",
		"park",
		"hospital",
		"cinema",
		"clothes_shop",
		"general_store",
		"pet_shop",
		"supermarket",
		"bus_station",
		"taxi",
		"railway_station"
	]
	for hotspot_id in required_hotspots:
		_assert(landmark_objects.has(hotspot_id), "landmark object layer should reserve an asset slot for %s" % hotspot_id)
		_assert(hotspot_rects.has(hotspot_id), "hotspot data should include %s" % hotspot_id)
		var object_data: Dictionary = landmark_objects[hotspot_id]
		_assert(str(object_data.get("asset_status", "")) == "pending_builtin_imagegen", "%s landmark should be explicitly pending built-in imagegen" % hotspot_id)
		var asset_path := str(object_data.get("asset_path", ""))
		_assert(asset_path.begins_with("res://assets/generated/maps/world/landmarks/"), "%s landmark should target the world landmark asset folder" % hotspot_id)
		_assert(asset_path.ends_with(".png"), "%s landmark should target a PNG asset" % hotspot_id)
		_assert(_rects_match(_rect_from_data(object_data.get("rect", {})), hotspot_rects[hotspot_id]), "%s landmark object rect should match the hotspot rect" % hotspot_id)

	var district_rects: Dictionary = _collect_tile_rects_by_tile_id(tile_layers)
	_assert(_point_in_any_rect((hotspot_rects["home"] as Rect2).get_center(), district_rects.get("home_yard", [])), "home hotspot should sit inside home_yard tiles")
	_assert(_point_in_any_rect((hotspot_rects["sunshine_school"] as Rect2).get_center(), district_rects.get("school_ground", [])), "school hotspot should sit inside school_ground tiles")
	for hotspot_id in ["post_office", "bookshop", "restaurant", "park", "hospital", "cinema", "clothes_shop", "general_store", "pet_shop", "supermarket"]:
		_assert(_point_in_any_rect((hotspot_rects[hotspot_id] as Rect2).get_center(), district_rects.get("town_plaza", [])), "%s hotspot should sit inside town_plaza tiles" % hotspot_id)
	for hotspot_id in ["bus_station", "taxi", "railway_station"]:
		var center: Vector2 = (hotspot_rects[hotspot_id] as Rect2).get_center()
		_assert(_point_in_any_rect(center, district_rects.get("transport_ground", [])), "%s hotspot should sit inside transport_ground tiles" % hotspot_id)
		_assert(_point_in_any_rect(center, _collect_road_tile_rects(tile_layers)), "%s hotspot should connect to a road tile path" % hotspot_id)

	var asset_generation: Dictionary = data.get("asset_generation", {})
	_assert(str(asset_generation.get("mode", "")) == "built_in_imagegen_required", "landmark generation mode should require built-in imagegen")
	_assert(str(asset_generation.get("status", "")) == "pending_tool_unavailable", "landmark generation should stay pending when the built-in tool is unavailable")
	_assert(str(asset_generation.get("prompt_record", "")) == LANDMARK_PROMPT_PATH, "landmark generation prompt record should be linked")
	_assert(FileAccess.file_exists(LANDMARK_PROMPT_PATH), "pending landmark prompt record should exist")
	var prompt_text := _read_text(LANDMARK_PROMPT_PATH)
	_assert(prompt_text.contains("pending built-in image generation"), "prompt record should mark pending built-in generation")
	_assert(prompt_text.contains("Do not use external image-generation"), "prompt record should forbid external generation backends")
	for object_data: Dictionary in landmark_objects.values():
		_assert(prompt_text.contains(str(object_data.get("asset_path", "")).replace("res://", "")), "prompt record should mention %s" % object_data.get("asset_path", ""))

	print("MVP 0.2 world layer map data passed.")
	quit(0)


func _has_tile_layer(tile_layers: Array, layer_id: String, layer_type: String) -> bool:
	for layer_value: Variant in tile_layers:
		if typeof(layer_value) != TYPE_DICTIONARY:
			continue
		var layer: Dictionary = layer_value
		if str(layer.get("id", "")) == layer_id and str(layer.get("type", "")) == layer_type:
			return true
	return false


func _collect_landmark_objects(object_layers: Array) -> Dictionary:
	var landmark_objects: Dictionary = {}
	for layer_value: Variant in object_layers:
		if typeof(layer_value) != TYPE_DICTIONARY:
			continue
		var layer: Dictionary = layer_value
		for object_value: Variant in layer.get("objects", []):
			if typeof(object_value) != TYPE_DICTIONARY:
				continue
			var object_data: Dictionary = object_value
			if str(object_data.get("type", "")) != "landmark_asset":
				continue
			landmark_objects[str(object_data.get("hotspot_id", ""))] = object_data
	return landmark_objects


func _collect_hotspot_rects(hotspots: Array) -> Dictionary:
	var hotspot_rects: Dictionary = {}
	for hotspot_value: Variant in hotspots:
		if typeof(hotspot_value) != TYPE_DICTIONARY:
			continue
		var hotspot: Dictionary = hotspot_value
		if str(hotspot.get("kind", "")) != "place":
			continue
		hotspot_rects[str(hotspot.get("id", ""))] = _rect_from_data(hotspot.get("rect", {}))
	return hotspot_rects


func _collect_tile_rects_by_tile_id(tile_layers: Array) -> Dictionary:
	var rects_by_tile_id: Dictionary = {}
	for layer_value: Variant in tile_layers:
		if typeof(layer_value) != TYPE_DICTIONARY:
			continue
		var layer: Dictionary = layer_value
		if str(layer.get("type", "")) != "tile_rects":
			continue
		for rect_value: Variant in layer.get("rects", []):
			if typeof(rect_value) != TYPE_DICTIONARY:
				continue
			var rect_data: Dictionary = rect_value
			var tile_id := str(rect_data.get("tile_id", ""))
			if tile_id.is_empty():
				continue
			if not rects_by_tile_id.has(tile_id):
				rects_by_tile_id[tile_id] = []
			(rects_by_tile_id[tile_id] as Array).append(_tile_rect_from_grid_rect(rect_data))
	return rects_by_tile_id


func _collect_road_tile_rects(tile_layers: Array) -> Array:
	var road_rects: Array = []
	for layer_value: Variant in tile_layers:
		if typeof(layer_value) != TYPE_DICTIONARY:
			continue
		var layer: Dictionary = layer_value
		if str(layer.get("type", "")) != "tile_path" or str(layer.get("tile_id", "")) != "road":
			continue
		for cell_value: Variant in layer.get("cells", []):
			if typeof(cell_value) != TYPE_DICTIONARY:
				continue
			var cell: Dictionary = cell_value
			road_rects.append(_tile_rect_from_cell(int(cell.get("col", 0)), int(cell.get("row", 0))))
	return road_rects
func _tile_rect_from_grid_rect(rect_data: Dictionary) -> Rect2:
	var tile_size := 128.0
	return Rect2(
		Vector2(float(rect_data.get("col", 0)) * tile_size, float(rect_data.get("row", 0)) * tile_size),
		Vector2(float(rect_data.get("cols", 1)) * tile_size, float(rect_data.get("rows", 1)) * tile_size)
	)


func _tile_rect_from_cell(column: int, row: int) -> Rect2:
	var tile_size := 128.0
	return Rect2(Vector2(column * tile_size, row * tile_size), Vector2(tile_size, tile_size))


func _point_in_any_rect(point: Vector2, rects: Array) -> bool:
	for rect_value: Variant in rects:
		if rect_value is Rect2 and (rect_value as Rect2).has_point(point):
			return true
	return false


func _rects_match(a: Rect2, b: Rect2) -> bool:
	return a.position.distance_to(b.position) <= 0.01 and a.size.distance_to(b.size) <= 0.01


func _rect_from_data(value: Variant) -> Rect2:
	if typeof(value) != TYPE_DICTIONARY:
		return Rect2()
	var rect_data: Dictionary = value
	return Rect2(
		Vector2(float(rect_data.get("x", 0.0)), float(rect_data.get("y", 0.0))),
		Vector2(float(rect_data.get("w", 0.0)), float(rect_data.get("h", 0.0)))
	)


func _read_json_dict(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	_assert(file != null, "file should open: %s" % path)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	_assert(typeof(parsed) == TYPE_DICTIONARY, "file should parse as dictionary: %s" % path)
	return parsed


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	_assert(file != null, "file should open: %s" % path)
	return file.get_as_text()


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
