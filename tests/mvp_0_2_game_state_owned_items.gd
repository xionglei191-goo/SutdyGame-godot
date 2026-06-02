extends SceneTree


func _initialize() -> void:
	var game_state: Node = root.get_node("GameState")
	game_state.reset_progress()

	_assert(game_state.get_owned_items().is_empty(), "new progress should start with no owned items")
	game_state.add_coins(10)
	var bowl_result: Dictionary = game_state.buy_pet_bowl()
	var ball_result: Dictionary = game_state.buy_pet_ball()
	game_state.add_parent_bonus(1)
	var cape_result: Dictionary = game_state.buy_explorer_cape()
	var rug_result: Dictionary = game_state.buy_star_rug()
	_assert(bool(bowl_result.get("success", false)), "pet bowl purchase should succeed")
	_assert(bool(ball_result.get("success", false)), "pet ball purchase should succeed")
	_assert(bool(cape_result.get("success", false)), "explorer cape purchase should succeed")
	_assert(bool(rug_result.get("success", false)), "star rug purchase should succeed")
	for item_id in ["pet_bowl", "pet_ball", "explorer_cape", "star_rug"]:
		_assert(game_state.has_owned_item(item_id), "owned item should be present after purchase: %s" % item_id)
	var snapshot: Dictionary = game_state.debug_snapshot()
	_assert(snapshot.has("owned_items"), "debug snapshot should include owned_items")
	_assert((snapshot["owned_items"] as Array).has("explorer_cape"), "snapshot owned_items should include explorer cape")
	_assert((snapshot["story_flags"] as Array).has(game_state.EXPLORER_CAPE_FLAG), "legacy story flag should still be present")

	var save_path := "user://mvp_0_2_owned_items_save.json"
	_assert(game_state.save_game(save_path), "owned items save should succeed")
	game_state.reset_progress()
	_assert(game_state.load_game(save_path), "owned items load should succeed")
	for item_id in ["pet_bowl", "pet_ball", "explorer_cape", "star_rug"]:
		_assert(game_state.has_owned_item(item_id), "load should restore owned item: %s" % item_id)
	_assert(game_state.has_explorer_cape(), "load should keep legacy has_explorer_cape API working")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))

	var legacy_path := "user://mvp_0_2_legacy_owned_flags_save.json"
	var file := FileAccess.open(legacy_path, FileAccess.WRITE)
	_assert(file != null, "legacy save file should open")
	file.store_string(JSON.stringify({
		"story_flags": [
			game_state.PET_BOWL_FLAG,
			game_state.PET_BALL_FLAG,
			game_state.EXPLORER_CAPE_FLAG,
			game_state.STAR_RUG_FLAG
		],
		"coins": game_state.DEFAULT_COINS,
		"parent_bonus": game_state.DEFAULT_PARENT_BONUS,
		"pet_name": game_state.DEFAULT_PET_NAME,
		"pet_state": game_state.DEFAULT_PET_STATE
	}, "\t"))
	file = null
	game_state.reset_progress()
	_assert(game_state.load_game(legacy_path), "legacy owned flag save should load")
	for item_id in ["pet_bowl", "pet_ball", "explorer_cape", "star_rug"]:
		_assert(game_state.has_owned_item(item_id), "legacy flag save should migrate owned item: %s" % item_id)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(legacy_path))

	var item_only_path := "user://mvp_0_2_owned_items_only_save.json"
	file = FileAccess.open(item_only_path, FileAccess.WRITE)
	_assert(file != null, "owned-items-only save file should open")
	file.store_string(JSON.stringify({
		"owned_items": ["pet_bowl", "pet_ball", "explorer_cape", "star_rug"],
		"story_flags": [],
		"coins": game_state.DEFAULT_COINS,
		"parent_bonus": game_state.DEFAULT_PARENT_BONUS,
		"pet_name": game_state.DEFAULT_PET_NAME,
		"pet_state": game_state.DEFAULT_PET_STATE
	}, "\t"))
	file = null
	game_state.reset_progress()
	_assert(game_state.load_game(item_only_path), "owned-items-only save should load")
	for flag_id in [game_state.PET_BOWL_FLAG, game_state.PET_BALL_FLAG, game_state.EXPLORER_CAPE_FLAG, game_state.STAR_RUG_FLAG]:
		_assert(game_state.has_story_flag(flag_id), "owned-items-only save should backfill legacy flag: %s" % flag_id)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(item_only_path))

	print("mvp_0_2_game_state_owned_items passed.")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
