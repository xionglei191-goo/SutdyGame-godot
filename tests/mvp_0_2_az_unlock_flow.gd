extends SceneTree


const STARTER_ANCHORS := [
	"anchor_a_apple",
	"anchor_c_clock",
	"anchor_e_elephant",
	"anchor_g_gate",
	"anchor_s_sun",
	"anchor_u_umbrella"
]

const LOCKED_SAMPLE_ANCHOR := "anchor_y_yo_yo"
const PILOT_NON_STARTER_ANCHOR := "anchor_b_bear"


func _initialize() -> void:
	var game_state: Node = root.get_node("GameState")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))
	game_state.reset_progress()
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	await process_frame

	var town_map: Node = main.get_node("TownMap")
	var click_game: Node = town_map.get_node("ClickGame")
	var dialogue_box: CanvasLayer = main.get_node("DialogueBox")
	_assert(town_map.get_active_scene() == "home", "A-Z unlock test should start from the home opener")
	town_map.show_scene("world_overview")
	town_map.set_click_input_enabled(true)
	await process_frame
	_assert(not game_state.has_story_flag("az_full_unlocked_after_prologue"), "new game should not start with full A-Z unlocked")

	var starter_ids := _memory_anchor_ids(click_game)
	_assert(starter_ids.size() == STARTER_ANCHORS.size(), "only starter anchors should be clickable before prologue")
	for anchor_id in STARTER_ANCHORS:
		_assert(starter_ids.has(anchor_id), "starter anchor should be enabled before prologue: %s" % anchor_id)
	_assert(not starter_ids.has(LOCKED_SAMPLE_ANCHOR), "non-starter anchor should stay locked before prologue")
	_assert(not starter_ids.has(PILOT_NON_STARTER_ANCHOR), "pilot recall should not override A-Z unlock mode")

	click_game.memory_anchor_clicked.emit("anchor_a_apple")
	await process_frame
	_assert(dialogue_box.visible, "starter anchor should still open dialogue before prologue")
	_assert(dialogue_box.dialogue_id == "anchor_a_apple", "starter anchor should load its dialogue before prologue")
	dialogue_box._finish()
	await process_frame

	game_state.mark_story_flag("az_full_unlocked_after_prologue")
	var unlocked_ids := _memory_anchor_ids(click_game)
	_assert(unlocked_ids.size() == 26, "all 26 memory anchors should unlock after prologue flag")
	_assert(unlocked_ids.has(LOCKED_SAMPLE_ANCHOR), "non-starter anchor should unlock after prologue flag")
	_assert(_route_order_count(click_game) == 26, "A-Z route order should still cover 26 anchors")

	click_game.memory_anchor_clicked.emit(LOCKED_SAMPLE_ANCHOR)
	await process_frame
	_assert(dialogue_box.visible, "unlocked non-starter anchor should open dialogue")
	_assert(dialogue_box.dialogue_id == LOCKED_SAMPLE_ANCHOR, "unlocked non-starter anchor should load its own dialogue")

	print("mvp_0_2_az_unlock_flow passed.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))
	quit(0)


func _memory_anchor_ids(click_game: Node) -> Array[String]:
	var ids: Array[String] = []
	for hotspot: Dictionary in click_game.get_hotspots_for_scene("world_overview"):
		if str(hotspot.get("kind", "")) == "memory_anchor":
			ids.append(str(hotspot.get("id", "")))
	return ids


func _route_order_count(click_game: Node) -> int:
	var route_orders: Array[int] = []
	for hotspot: Dictionary in click_game._world_map_hotspots:
		if str(hotspot.get("kind", "")) != "memory_anchor":
			continue
		var order := int(hotspot.get("route_order", 0))
		if order > 0 and not route_orders.has(order):
			route_orders.append(order)
	return route_orders.size()


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
