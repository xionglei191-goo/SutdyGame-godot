extends RefCounted
class_name PetCareManager

var game_state


func _init(game_state_ref = null) -> void:
	game_state = game_state_ref


func get_pet_state() -> Dictionary:
	return game_state.pet_state.duplicate(true)


func get_pet_name() -> String:
	return game_state.pet_name


func set_pet_name(value: String, default_pet_name: String) -> void:
	var cleaned := value.strip_edges()
	if cleaned.is_empty():
		cleaned = default_pet_name
	if game_state.pet_name == cleaned:
		return
	game_state.pet_name = cleaned
	game_state.pet_name_changed.emit(game_state.pet_name)


func care_for_pet(action_id: String, default_pet_state: Dictionary) -> Dictionary:
	var action := str(action_id).strip_edges().to_lower()
	var result := {
		"success": false,
		"message": "Your pet is waiting.",
		"coins_spent": 0,
		"pet_state": get_pet_state()
	}
	match action:
		"feed":
			if not game_state.spend_coins(2):
				result["message"] = "You need 2 coins for pet food."
				return result
			_adjust_pet_stat("hunger", 22, default_pet_state)
			_adjust_pet_stat("mood", 6, default_pet_state)
			_adjust_pet_stat("bond", 2, default_pet_state)
			result["success"] = true
			if game_state.has_pet_bowl():
				result["message"] = "Your pet enjoyed a snack in the new bowl."
			else:
				result["message"] = "Your pet enjoyed a snack."
			result["coins_spent"] = 2
		"clean":
			_adjust_pet_stat("cleanliness", 24, default_pet_state)
			_adjust_pet_stat("mood", 4, default_pet_state)
			_adjust_pet_stat("bond", 1, default_pet_state)
			result["success"] = true
			result["message"] = "Your pet feels fresh and clean."
		"play":
			_adjust_pet_stat("mood", 20, default_pet_state)
			_adjust_pet_stat("hunger", -4, default_pet_state)
			_adjust_pet_stat("bond", 3, default_pet_state)
			result["success"] = true
			if game_state.has_pet_ball():
				result["message"] = "Your pet had fun with the new ball."
			else:
				result["message"] = "Your pet had fun playing with you."
		"rest", "sleep":
			_adjust_pet_stat("rest", 20, default_pet_state)
			_adjust_pet_stat("mood", 12, default_pet_state)
			_adjust_pet_stat("hunger", -2, default_pet_state)
			_adjust_pet_stat("bond", 1, default_pet_state)
			result["success"] = true
			result["message"] = "%s had a cozy rest." % game_state.pet_name
		_:
			result["message"] = "That pet action is not ready."
			return result
	result["pet_state"] = get_pet_state()
	game_state.pet_state_changed.emit(get_pet_state())
	return result


func pet_state_from(value: Variant, default_pet_state: Dictionary) -> Dictionary:
	var result := default_pet_state.duplicate(true)
	if typeof(value) != TYPE_DICTIONARY:
		return result
	var data: Dictionary = value
	for key: String in default_pet_state.keys():
		result[key] = clampi(int(data.get(key, default_pet_state[key])), 0, 100)
	return result


func _adjust_pet_stat(key: String, delta: int, default_pet_state: Dictionary) -> void:
	game_state.pet_state[key] = clampi(
		int(game_state.pet_state.get(key, default_pet_state.get(key, 0))) + delta,
		0,
		100
	)
