extends SceneTree

var coins_changed_count := 0
var pet_state_changed_count := 0


func _initialize() -> void:
	var game_state: Node = root.get_node("GameState")
	game_state.reset_progress()
	_assert(game_state.coins == 5, "new game should start with 5 coins")
	_assert(game_state.get_pet_name() == "Sunny", "new game should start with the starter pet name")
	var pet_state: Dictionary = game_state.get_pet_state()
	_assert(int(pet_state.get("hunger", -1)) == 62, "pet hunger should start at 62")
	_assert(int(pet_state.get("cleanliness", -1)) == 58, "pet cleanliness should start at 58")
	_assert(int(pet_state.get("mood", -1)) == 66, "pet mood should start at 66")
	_assert(int(pet_state.get("bond", -1)) == 10, "pet bond should start at 10")
	_assert(int(pet_state.get("rest", -1)) == 70, "pet rest should start at 70")
	game_state.coins_changed.connect(_on_coins_changed)
	game_state.pet_state_changed.connect(_on_pet_state_changed)

	var feed_result: Dictionary = game_state.care_for_pet("feed")
	_assert(bool(feed_result.get("success", false)), "feed action should succeed")
	_assert(int(feed_result.get("coins_spent", 0)) == 2, "feed action should spend 2 coins")
	_assert(game_state.coins == 3, "feed should reduce coins to 3")
	pet_state = game_state.get_pet_state()
	_assert(int(pet_state.get("hunger", -1)) == 84, "feed should raise hunger to 84")
	_assert(int(pet_state.get("mood", -1)) == 72, "feed should raise mood to 72")
	_assert(int(pet_state.get("bond", -1)) == 12, "feed should raise bond to 12")
	_assert(coins_changed_count > 0, "coins_changed should emit after feed")
	_assert(pet_state_changed_count > 0, "pet_state_changed should emit after feed")

	var invalid_result: Dictionary = game_state.care_for_pet("invalid")
	_assert(not bool(invalid_result.get("success", true)), "invalid action should fail")
	_assert(game_state.coins == 3, "invalid action should not change coins")
	game_state.set_pet_name("Mochi")
	var rest_result: Dictionary = game_state.care_for_pet("rest")
	_assert(bool(rest_result.get("success", false)), "rest action should succeed")
	_assert(str(rest_result.get("message", "")) == "Mochi had a cozy rest.", "rest action should use the pet name")
	_assert(game_state.coins == 3, "rest action should not spend coins")
	pet_state = game_state.get_pet_state()
	_assert(int(pet_state.get("mood", -1)) == 84, "rest should raise mood to 84")
	_assert(int(pet_state.get("bond", -1)) == 13, "rest should raise bond to 13")
	_assert(int(pet_state.get("rest", -1)) == 90, "rest should raise rest to 90")
	var buy_bowl_result: Dictionary = game_state.buy_pet_bowl()
	_assert(bool(buy_bowl_result.get("success", false)), "buy pet bowl should succeed with enough coins")
	_assert(game_state.has_pet_bowl(), "buy pet bowl should set the owned flag")
	_assert(game_state.has_owned_item("pet_bowl"), "buy pet bowl should set the item layer")
	_assert(game_state.get_owned_items().has("pet_bowl"), "owned items should include pet bowl")
	_assert(game_state.coins == 0, "buy pet bowl should spend 3 coins")
	game_state.add_coins(2)
	var buy_ball_result: Dictionary = game_state.buy_pet_ball()
	_assert(bool(buy_ball_result.get("success", false)), "buy pet ball should succeed with enough coins")
	_assert(game_state.has_pet_ball(), "buy pet ball should set the owned flag")
	_assert(game_state.has_owned_item("pet_ball"), "buy pet ball should set the item layer")
	_assert(game_state.get_owned_items().has("pet_ball"), "owned items should include pet ball")
	_assert(game_state.coins == 0, "buy pet ball should spend 2 coins")
	_assert(game_state.learned_words.has("pet"), "buy pet ball should add pet to word records")
	_assert(game_state.learned_words.has("ball"), "buy pet ball should add ball to word records")
	_assert(game_state.learned_words.has("play"), "buy pet ball should add play to word records")
	_assert(game_state.learned_patterns.has("Buy a pet ball."), "buy pet ball should add a starter play pattern")
	var save_path := "user://mvp_0_2_pet_care_save.json"
	_assert(game_state.save_game(save_path), "pet care save should succeed")
	game_state.reset_progress()
	_assert(game_state.load_game(save_path), "pet care load should succeed")
	_assert(game_state.coins == 0, "load should restore coins")
	_assert(game_state.get_pet_name() == "Mochi", "load should restore pet name")
	_assert(game_state.has_pet_bowl(), "load should restore owned pet bowl flag")
	_assert(game_state.has_pet_ball(), "load should restore owned pet ball flag")
	_assert(game_state.has_owned_item("pet_bowl"), "load should restore pet bowl item")
	_assert(game_state.has_owned_item("pet_ball"), "load should restore pet ball item")
	pet_state = game_state.get_pet_state()
	_assert(int(pet_state.get("hunger", -1)) == 82, "load should restore hunger")
	_assert(int(pet_state.get("mood", -1)) == 84, "load should restore mood")
	_assert(int(pet_state.get("bond", -1)) == 13, "load should restore bond")
	_assert(int(pet_state.get("rest", -1)) == 90, "load should restore rest")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	print("mvp_0_2_game_state_pet_care passed.")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)


func _on_coins_changed(_value: int) -> void:
	coins_changed_count += 1


func _on_pet_state_changed(_state: Dictionary) -> void:
	pet_state_changed_count += 1
