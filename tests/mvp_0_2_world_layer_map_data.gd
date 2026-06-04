extends SceneTree

const LAYER_MAP_PATH := "res://data/maps/sunshine_world_layer_map_v001.json"
const HOTSPOTS_PATH := "res://data/maps/sunshine_world_hotspots_v001.json"
const LANDMARK_PROMPT_PATH := "res://assets/source_prompts/maps/world_landmark_assets_pending_v001.md"
const LANDMARK_MANIFEST_PATH := "res://assets/source_prompts/maps/world_landmark_assets_manifest_v001.json"


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
		_assert(_tile_has_atlas_coord(tile_palette[tile_id]), "%s tile should have an atlas coordinate" % tile_id)
	var tile_atlas: Dictionary = data.get("tile_atlas", {})
	_assert(str(tile_atlas.get("asset_path", "")) == "res://assets/generated/maps/world/tiles/tile_atlas_world_v001.png", "world layer map should point at the generated tile atlas")
	_assert(int(tile_atlas.get("tile_size", 0)) == 128, "world tile atlas should use 128px cells")
	_assert(str(tile_atlas.get("status", "")) == "generated_programmatic", "world tile atlas should be generated and ready")
	_assert(_resource_loads_as_texture(str(tile_atlas.get("asset_path", ""))), "world tile atlas should load as Texture2D")
	var tile_layers: Array = data.get("tile_layers", [])
	_assert(tile_layers.size() >= 5, "world layer map should define multiple tile layers")
	_assert(_has_tile_layer(tile_layers, "base_grass", "tile_fill"), "world layer map should have a base grass tile fill")
	_assert(_has_tile_layer(tile_layers, "district_tiles", "tile_rects"), "world layer map should have district tile rects")
	_assert(_has_tile_layer(tile_layers, "main_road_tiles", "tile_path"), "world layer map should have a main road tile path")
	_assert(_has_tile_layer(tile_layers, "school_loop_tiles", "tile_path"), "world layer map should have a school loop tile path")
	_assert(_has_tile_layer(tile_layers, "town_shop_street_tiles", "tile_path"), "world layer map should have a town shop street tile path")
	_assert(_has_tile_layer(tile_layers, "transport_route_tiles", "tile_path"), "world layer map should have a transport route tile path")
	var grid_rules: Dictionary = data.get("grid_rules", {})
	_assert(str(grid_rules.get("style_goal", "")) == "continuous_player_on_discrete_life_grid", "world layer map should record the Animal Crossing style grid contract")
	_assert(int(grid_rules.get("cell_size", 0)) == 128, "world life grid should use the same 128px cells as the tile map")
	var movement: Dictionary = grid_rules.get("movement", {})
	_assert(str(movement.get("mode", "")) == "continuous", "world life grid should keep continuous player movement")
	_assert(bool(movement.get("snap_interactions_to_grid", false)), "world life grid should snap interactions to stable cells")
	for tile_id in ["grass", "home_yard", "school_ground", "town_plaza", "transport_ground", "road", "school_path"]:
		_assert((movement.get("walkable_tile_ids", []) as Array).has(tile_id), "world life grid walkable set should include %s" % tile_id)
	var district_cells: Dictionary = _collect_district_cells(grid_rules.get("districts", []))
	for district_id in ["home_cluster", "school_footprint", "town_shop_street"]:
		_assert(district_cells.has(district_id), "world life grid should define %s district cells" % district_id)
	_assert(_district_has_cell(district_cells, "home_cluster", 2, 7), "home district should include the starter road cell")
	_assert(_district_has_cell(district_cells, "school_footprint", 9, 8), "school district should include the school interaction footprint")
	_assert(_district_has_cell(district_cells, "town_shop_street", 5, 14), "town shop street should include starter shop interaction cells")
	var road_cells: Dictionary = _collect_grid_road_cells(grid_rules.get("roads", {}))
	for cell_key in ["2,7", "9,14", "1,11", "14,14"]:
		_assert(road_cells.has(cell_key), "world life grid road cells should include %s" % cell_key)
	var occupied_cells: Dictionary = _collect_occupied_cells(grid_rules.get("occupied_cells", []))
	for cell_key in ["1,6", "2,6", "6,5", "7,5", "1,13", "4,13", "13,13"]:
		_assert(occupied_cells.has(cell_key), "world life grid occupied cells should reserve %s" % cell_key)
	var interaction_cells: Dictionary = _collect_interaction_cells(grid_rules.get("interaction_cells", []))
	for hotspot_id in ["home", "sunshine_school", "supermarket", "pet_shop", "bookshop", "bus_station", "railway_station", "airport"]:
		_assert(interaction_cells.has(hotspot_id), "%s should have a stable grid interaction cell" % hotspot_id)
		var cell_key: String = interaction_cells[hotspot_id]
		_assert(not occupied_cells.has(cell_key), "%s interaction cell should not be on an occupied building cell" % hotspot_id)
		_assert(road_cells.has(cell_key) or _district_has_cell_key(district_cells, "school_footprint", cell_key), "%s interaction cell should connect to road or school path cells" % hotspot_id)

	var hotspot_rects: Dictionary = _collect_hotspot_rects(hotspot_data.get("hotspots", []))
	var landmark_objects: Dictionary = _collect_landmark_objects(data.get("object_layers", []))
	var manifest: Dictionary = _read_json_dict(LANDMARK_MANIFEST_PATH)
	var manifest_assets: Dictionary = _collect_manifest_assets(manifest.get("assets", []))
	_assert(str(manifest.get("preferred_tool", "")) == "built_in_imagegen", "landmark manifest should prefer built-in imagegen")
	_assert(str(manifest.get("current_source", "")) in ["built_in_imagegen", "local_fallback"], "landmark manifest should record the current asset source")
	_assert(bool(manifest.get("transparent_output", false)), "landmark manifest should keep transparent-output requirements")
	var memory_anchor_count := _count_memory_anchors(hotspot_data.get("hotspots", []))
	_assert(memory_anchor_count == 26, "world layer map renderer should have 26 data-derived A-Z memory anchors available")
	var required_hotspots := _collect_required_landmark_hotspot_ids(hotspot_data.get("hotspots", []))
	_assert(required_hotspots.size() >= 16, "default-visible non-school landmarks should reserve built-in imagegen slots")
	for hotspot_id in required_hotspots:
		_assert(landmark_objects.has(hotspot_id), "landmark object layer should reserve an asset slot for %s" % hotspot_id)
		_assert(hotspot_rects.has(hotspot_id), "hotspot data should include %s" % hotspot_id)
		var object_data: Dictionary = landmark_objects[hotspot_id]
		var asset_path := str(object_data.get("asset_path", ""))
		_assert(str(object_data.get("preferred_generation", "")) == "built_in_imagegen", "%s landmark should keep built-in imagegen as the preferred generation path" % hotspot_id)
		_assert(str(object_data.get("generation_source", "")) in ["built_in_imagegen", "local_fallback"], "%s landmark should record whether the current PNG came from built-in or fallback generation" % hotspot_id)
		_assert(asset_path.begins_with("res://assets/generated/maps/world/landmarks/"), "%s landmark should target the world landmark asset folder" % hotspot_id)
		_assert(asset_path.ends_with(".png"), "%s landmark should target a PNG asset" % hotspot_id)
		_assert(manifest_assets.has(hotspot_id), "landmark manifest should include %s" % hotspot_id)
		var manifest_entry: Dictionary = manifest_assets[hotspot_id]
		_assert(str(manifest_entry.get("asset_path", "")) == asset_path, "%s manifest asset path should match world layer map data" % hotspot_id)
		_assert(str(manifest_entry.get("preferred_generation", "")) == str(object_data.get("preferred_generation", "")), "%s manifest should keep the same preferred generation path as world layer map data" % hotspot_id)
		_assert(str(manifest_entry.get("current_source", "")) == str(object_data.get("generation_source", "")), "%s manifest should keep the same current source as world layer map data" % hotspot_id)
		_assert(str(manifest_entry.get("prompt", "")).length() >= 32, "%s manifest should keep a usable built-in image prompt" % hotspot_id)
		var asset_status := str(object_data.get("asset_status", ""))
		var has_generated_asset := _resource_loads_as_texture(asset_path)
		match asset_status:
			"pending_builtin_imagegen":
				_assert(not has_generated_asset, "%s landmark should not stay pending after a generated PNG is loadable" % hotspot_id)
			"generated_builtin_imagegen":
				_assert(has_generated_asset, "%s landmark marked generated should load as Texture2D" % hotspot_id)
			"generated_local_image_generator_fallback":
				_assert(has_generated_asset, "%s landmark generated through local fallback should load as Texture2D" % hotspot_id)
			_:
				_assert(false, "%s landmark should use a known built-in imagegen status, got %s" % [hotspot_id, asset_status])
		_assert(_rects_match(_rect_from_data(object_data.get("rect", {})), hotspot_rects[hotspot_id]), "%s landmark object rect should match the hotspot rect" % hotspot_id)

	var district_rects: Dictionary = _collect_tile_rects_by_tile_id(tile_layers)
	_assert(_point_in_any_rect((hotspot_rects["home"] as Rect2).get_center(), district_rects.get("home_yard", [])), "home hotspot should sit inside home_yard tiles")
	_assert(_point_in_any_rect((hotspot_rects["sunshine_school"] as Rect2).get_center(), district_rects.get("school_ground", [])), "school hotspot should sit inside school_ground tiles")
	for hotspot_id in ["post_office", "bookshop", "restaurant", "park", "hospital", "cinema", "clothes_shop", "general_store", "pet_shop", "supermarket"]:
		_assert(_point_in_any_rect((hotspot_rects[hotspot_id] as Rect2).get_center(), district_rects.get("town_plaza", [])), "%s hotspot should sit inside town_plaza tiles" % hotspot_id)
	for hotspot_id in ["bus_station", "taxi", "railway_station", "airport"]:
		var center: Vector2 = (hotspot_rects[hotspot_id] as Rect2).get_center()
		_assert(_point_in_any_rect(center, district_rects.get("transport_ground", [])), "%s hotspot should sit inside transport_ground tiles" % hotspot_id)
		_assert(_point_in_any_rect(center, _collect_road_tile_rects(tile_layers)), "%s hotspot should connect to a road tile path" % hotspot_id)

	var asset_generation: Dictionary = data.get("asset_generation", {})
	_assert(str(asset_generation.get("mode", "")) == "built_in_imagegen_with_local_script_fallback", "landmark generation mode should prefer built-in imagegen and record the local fallback")
	_assert(str(asset_generation.get("preferred_tool", "")) == "built_in_imagegen", "landmark generation metadata should keep built-in imagegen as the preferred tool")
	var current_source := str(asset_generation.get("current_source", ""))
	_assert(current_source in ["built_in_imagegen", "local_fallback"], "landmark generation metadata should record the current asset source")
	_assert(str(asset_generation.get("prompt_manifest", "")) == LANDMARK_MANIFEST_PATH, "landmark generation metadata should link the machine-readable prompt manifest")
	var landmark_asset_counts := _count_landmark_asset_states(landmark_objects.values())
	if int(landmark_asset_counts.get("missing", 0)) > 0:
		_assert(str(asset_generation.get("status", "")) == "pending_tool_unavailable", "landmark generation should stay pending while generated PNGs are missing")
		_assert(int(landmark_asset_counts.get("pending", 0)) == int(landmark_asset_counts.get("missing", 0)), "missing landmark PNGs should be explicitly pending built-in imagegen")
	else:
		var generation_status := str(asset_generation.get("status", ""))
		if current_source == "local_fallback":
			_assert(generation_status == "generated_local_image_generator_fallback_complete", "local-fallback landmark generation should record fallback completion after all generated PNGs are loadable")
			_assert(str(asset_generation.get("fallback_tool", "")) == "tools/image_generator.js", "local-fallback landmark generation should record the local fallback tool")
		else:
			_assert(generation_status == "generated_builtin_imagegen_complete", "built-in landmark generation should record built-in completion after all generated PNGs are loadable")
		_assert(int(landmark_asset_counts.get("generated", 0)) == landmark_objects.size(), "all landmark PNGs should be generated before marking generation complete")
	_assert(str(asset_generation.get("prompt_record", "")) == LANDMARK_PROMPT_PATH, "landmark generation prompt record should be linked")
	_assert(FileAccess.file_exists(LANDMARK_PROMPT_PATH), "pending landmark prompt record should exist")
	_assert(FileAccess.file_exists(LANDMARK_MANIFEST_PATH), "landmark manifest should exist")
	var prompt_text := _read_text(LANDMARK_PROMPT_PATH)
	_assert(prompt_text.contains("Local fallback result"), "prompt record should document the local fallback generation result")
	if int(landmark_asset_counts.get("missing", 0)) > 0:
		_assert(prompt_text.contains("pending built-in image generation"), "prompt record should mark pending built-in generation while assets are missing")
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


func _tile_has_atlas_coord(tile_entry_value: Variant) -> bool:
	if typeof(tile_entry_value) != TYPE_DICTIONARY:
		return false
	var tile_entry: Dictionary = tile_entry_value
	return typeof(tile_entry.get("atlas_coord", {})) == TYPE_DICTIONARY


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


func _collect_manifest_assets(asset_values: Array) -> Dictionary:
	var manifest_assets: Dictionary = {}
	for asset_value: Variant in asset_values:
		if typeof(asset_value) != TYPE_DICTIONARY:
			continue
		var asset_data: Dictionary = asset_value
		var hotspot_id := str(asset_data.get("hotspot_id", ""))
		if hotspot_id.is_empty():
			continue
		manifest_assets[hotspot_id] = asset_data
	return manifest_assets


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


func _collect_required_landmark_hotspot_ids(hotspots: Array) -> Array[String]:
	var hotspot_ids: Array[String] = []
	for hotspot_value: Variant in hotspots:
		if typeof(hotspot_value) != TYPE_DICTIONARY:
			continue
		var hotspot: Dictionary = hotspot_value
		if str(hotspot.get("kind", "")) != "place" or not bool(hotspot.get("default_visible", false)):
			continue
		var hotspot_id := str(hotspot.get("id", ""))
		var zone := str(hotspot.get("zone", ""))
		if hotspot_id.is_empty():
			continue
		if zone == "school_core" and hotspot_id != "sunshine_school":
			continue
		hotspot_ids.append(hotspot_id)
	return hotspot_ids


func _count_memory_anchors(hotspots: Array) -> int:
	var count := 0
	var route_orders: Dictionary = {}
	for hotspot_value: Variant in hotspots:
		if typeof(hotspot_value) != TYPE_DICTIONARY:
			continue
		var hotspot: Dictionary = hotspot_value
		if str(hotspot.get("kind", "")) != "memory_anchor":
			continue
		var letter := str(hotspot.get("letter", ""))
		var route_order := int(hotspot.get("route_order", 0))
		_assert(not letter.is_empty(), "memory anchor should keep a letter")
		_assert(route_order >= 1 and route_order <= 26, "memory anchor route_order should stay in A-Z route range")
		_assert(not route_orders.has(route_order), "memory anchor route_order should be unique: %s" % route_order)
		route_orders[route_order] = true
		count += 1
	return count


func _count_landmark_asset_states(landmark_values: Array) -> Dictionary:
	var counts := {
		"pending": 0,
		"generated": 0,
		"missing": 0
	}
	for landmark_value: Variant in landmark_values:
		if typeof(landmark_value) != TYPE_DICTIONARY:
			continue
		var landmark: Dictionary = landmark_value
		var asset_path := str(landmark.get("asset_path", ""))
		var has_generated_asset := _resource_loads_as_texture(asset_path)
		if str(landmark.get("asset_status", "")) == "pending_builtin_imagegen":
			counts["pending"] = int(counts["pending"]) + 1
		if has_generated_asset:
			counts["generated"] = int(counts["generated"]) + 1
		else:
			counts["missing"] = int(counts["missing"]) + 1
	return counts


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


func _collect_district_cells(district_values: Array) -> Dictionary:
	var district_cells: Dictionary = {}
	for district_value: Variant in district_values:
		if typeof(district_value) != TYPE_DICTIONARY:
			continue
		var district: Dictionary = district_value
		var district_id := str(district.get("id", ""))
		if district_id.is_empty():
			continue
		district_cells[district_id] = {}
		for cell_value: Variant in district.get("cells", []):
			if typeof(cell_value) != TYPE_DICTIONARY:
				continue
			var cell: Dictionary = cell_value
			(district_cells[district_id] as Dictionary)[_cell_key(int(cell.get("col", -1)), int(cell.get("row", -1)))] = true
	return district_cells


func _collect_grid_road_cells(roads: Dictionary) -> Dictionary:
	var road_cells: Dictionary = {}
	for route_id_value: Variant in roads.keys():
		var cells_value: Variant = roads.get(route_id_value, [])
		if typeof(cells_value) != TYPE_ARRAY:
			continue
		for cell_value: Variant in cells_value:
			if typeof(cell_value) != TYPE_DICTIONARY:
				continue
			var cell: Dictionary = cell_value
			road_cells[_cell_key(int(cell.get("col", -1)), int(cell.get("row", -1)))] = true
	return road_cells


func _collect_occupied_cells(occupied_values: Array) -> Dictionary:
	var occupied_cells: Dictionary = {}
	for occupied_value: Variant in occupied_values:
		if typeof(occupied_value) != TYPE_DICTIONARY:
			continue
		var occupied: Dictionary = occupied_value
		var start_col := int(occupied.get("col", -1))
		var start_row := int(occupied.get("row", -1))
		var cols := int(occupied.get("cols", 1))
		var rows := int(occupied.get("rows", 1))
		for row_offset in range(rows):
			for col_offset in range(cols):
				occupied_cells[_cell_key(start_col + col_offset, start_row + row_offset)] = true
	return occupied_cells


func _collect_interaction_cells(interaction_values: Array) -> Dictionary:
	var interaction_cells: Dictionary = {}
	for interaction_value: Variant in interaction_values:
		if typeof(interaction_value) != TYPE_DICTIONARY:
			continue
		var interaction: Dictionary = interaction_value
		var hotspot_id := str(interaction.get("hotspot_id", ""))
		if hotspot_id.is_empty():
			continue
		interaction_cells[hotspot_id] = _cell_key(int(interaction.get("col", -1)), int(interaction.get("row", -1)))
	return interaction_cells


func _district_has_cell(district_cells: Dictionary, district_id: String, column: int, row: int) -> bool:
	return _district_has_cell_key(district_cells, district_id, _cell_key(column, row))


func _district_has_cell_key(district_cells: Dictionary, district_id: String, cell_key: String) -> bool:
	if not district_cells.has(district_id):
		return false
	var cells: Dictionary = district_cells[district_id]
	return cells.has(cell_key)


func _cell_key(column: int, row: int) -> String:
	return "%s,%s" % [column, row]


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


func _resource_loads_as_texture(path: String) -> bool:
	if path.is_empty() or not ResourceLoader.exists(path):
		return false
	var resource := load(path)
	return resource is Texture2D


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
