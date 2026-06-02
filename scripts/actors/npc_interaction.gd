extends Area2D

signal interaction_requested(dialogue_id: String)

@export var dialogue_id := "mina_intro"
@export var npc_id := "mina"

@onready var prompt_label: Label = $PromptLabel
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var name_label: Label = $NameLabel
@onready var sprite: Sprite2D = $Sprite

const SPRITE_PATHS := {
	"mina": "res://assets/generated/characters/npcs/char_mina_sprite_v001.png",
	"leo": "res://assets/generated/characters/npcs/char_leo_sprite_v001.png",
	"nora": "res://assets/generated/characters/npcs/char_nora_sprite_v001.png"
}


func _ready() -> void:
	_apply_npc_presentation()
	prompt_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func interact() -> void:
	interaction_requested.emit(dialogue_id)


func set_dialogue_id(id: String) -> void:
	dialogue_id = id


func set_prompt_visible(is_visible: bool) -> void:
	prompt_label.visible = is_visible


func set_active_state(is_active: bool) -> void:
	visible = is_active
	monitoring = is_active
	monitorable = is_active
	prompt_label.visible = false
	if collision_shape != null:
		collision_shape.disabled = not is_active


func _apply_npc_presentation() -> void:
	match npc_id:
		"leo":
			if name_label != null:
				name_label.text = "Leo"
		"nora":
			if name_label != null:
				name_label.text = "Nora"
		_:
			if name_label != null:
				name_label.text = "Mina"
	if sprite != null and SPRITE_PATHS.has(npc_id):
		sprite.texture = load(SPRITE_PATHS[npc_id])


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("set_nearby_interactable"):
		body.set_nearby_interactable(self)
		prompt_label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.has_method("clear_nearby_interactable"):
		body.clear_nearby_interactable(self)
		prompt_label.visible = false
