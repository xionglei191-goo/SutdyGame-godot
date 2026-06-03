extends RefCounted
class_name PetVisualController

const HAPPY_TEXTURE := preload("res://assets/generated/characters/pet/pet_mood_happy_v001.png")
const NEUTRAL_TEXTURE := preload("res://assets/generated/characters/pet/pet_mood_neutral_v001.png")
const SLEEPY_TEXTURE := preload("res://assets/generated/characters/pet/pet_mood_sleepy_v001.png")
const EATING_TEXTURE := preload("res://assets/generated/characters/pet/pet_action_eating_v001.png")
const PLAYING_TEXTURE := preload("res://assets/generated/characters/pet/pet_action_playing_v001.png")
const SLEEPING_TEXTURE := preload("res://assets/generated/characters/pet/pet_action_sleeping_v001.png")

const FEEDBACK_SECONDS := 0.5

var display: Sprite2D
var current_pet_state: Dictionary = {}
var feedback_token := 0


func configure(display_node: Sprite2D, initial_state: Dictionary) -> void:
	display = display_node
	current_pet_state = initial_state.duplicate(true)
	if display != null:
		display.visible = true
		display.texture = _mood_texture(current_pet_state)


func apply_pet_state(state: Dictionary) -> void:
	current_pet_state = state.duplicate(true)
	if display == null:
		return
	if feedback_token > 0:
		return
	display.texture = _mood_texture(current_pet_state)


func play_action_feedback(action_id: String) -> void:
	if display == null:
		return
	feedback_token += 1
	var token := feedback_token
	var action := action_id.strip_edges().to_lower()
	var action_texture := _action_texture(action)
	if action_texture != null:
		display.texture = action_texture
	var tween := display.create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(display, "scale", Vector2(0.4, 0.4), FEEDBACK_SECONDS * 0.5)
	tween.tween_property(display, "scale", Vector2(0.34, 0.34), FEEDBACK_SECONDS * 0.5)
	tween.finished.connect(func() -> void:
		if token != feedback_token:
			return
		feedback_token = 0
		if display != null:
			display.texture = _mood_texture(current_pet_state)
	)


func _mood_texture(state: Dictionary) -> Texture2D:
	var mood := int(state.get("mood", 0))
	if mood >= 70:
		return HAPPY_TEXTURE
	if mood < 40:
		return SLEEPY_TEXTURE
	return NEUTRAL_TEXTURE


func _action_texture(action_id: String) -> Texture2D:
	match action_id:
		"feed":
			return EATING_TEXTURE
		"play":
			return PLAYING_TEXTURE
		"rest", "sleep":
			return SLEEPING_TEXTURE
	return null
