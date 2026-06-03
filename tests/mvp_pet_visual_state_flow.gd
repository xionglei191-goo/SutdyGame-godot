extends SceneTree

const HAPPY_PATH := "res://assets/generated/characters/pet/pet_mood_happy_v001.png"
const NEUTRAL_PATH := "res://assets/generated/characters/pet/pet_mood_neutral_v001.png"
const SLEEPY_PATH := "res://assets/generated/characters/pet/pet_mood_sleepy_v001.png"
const EATING_PATH := "res://assets/generated/characters/pet/pet_action_eating_v001.png"
const PLAYING_PATH := "res://assets/generated/characters/pet/pet_action_playing_v001.png"
const SLEEPING_PATH := "res://assets/generated/characters/pet/pet_action_sleeping_v001.png"


func _initialize() -> void:
	var game_state: Node = root.get_node("GameState")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))
	game_state.reset_progress()
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	await process_frame

	var town_map: Node = main.get_node("TownMap")
	var display: Sprite2D = town_map.get_node("HomeLayer/PetCorner/PetStateDisplay")
	_assert(display.visible, "pet state display should be visible")
	_assert(_texture_path(display) == NEUTRAL_PATH, "default pet mood should show neutral texture")

	game_state.pet_state["mood"] = 78
	game_state.pet_state_changed.emit(game_state.get_pet_state())
	await process_frame
	_assert(_texture_path(display) == HAPPY_PATH, "mood >= 70 should show happy texture")

	game_state.pet_state["mood"] = 30
	game_state.pet_state_changed.emit(game_state.get_pet_state())
	await process_frame
	_assert(_texture_path(display) == SLEEPY_PATH, "mood < 40 should show sleepy texture")

	game_state.pet_state = game_state.DEFAULT_PET_STATE.duplicate(true)
	game_state.coins = 8
	game_state.coins_changed.emit(game_state.coins)
	game_state.pet_state_changed.emit(game_state.get_pet_state())
	await process_frame

	var feed_button: Button = town_map.get_node("HomeLayer/PetPanel/MarginContainer/VBoxContainer/ActionButtons/FeedButton")
	var play_button: Button = town_map.get_node("HomeLayer/PetPanel/MarginContainer/VBoxContainer/ActionButtons/PlayButton")
	var rest_button: Button = town_map.get_node("HomeLayer/PetPanel/MarginContainer/VBoxContainer/ActionButtons/RestButton")
	var clean_button: Button = town_map.get_node("HomeLayer/PetPanel/MarginContainer/VBoxContainer/ActionButtons/CleanButton")

	feed_button.pressed.emit()
	await process_frame
	_assert(_texture_path(display) == EATING_PATH, "feed should briefly show eating texture")
	await create_timer(0.65).timeout
	_assert(_texture_path(display) == HAPPY_PATH, "feed feedback should restore the updated mood texture")

	play_button.pressed.emit()
	await process_frame
	_assert(_texture_path(display) == PLAYING_PATH, "play should briefly show playing texture")
	await create_timer(0.65).timeout

	rest_button.pressed.emit()
	await process_frame
	_assert(_texture_path(display) == SLEEPING_PATH, "rest should briefly show sleeping texture")
	await create_timer(0.65).timeout

	var scale_before := display.scale
	clean_button.pressed.emit()
	await create_timer(0.12).timeout
	_assert(display.scale != scale_before, "clean should play a short scale feedback animation")

	print("mvp_pet_visual_state_flow passed.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))
	quit(0)


func _texture_path(sprite: Sprite2D) -> String:
	if sprite.texture == null:
		return ""
	return sprite.texture.resource_path


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
