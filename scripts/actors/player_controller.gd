extends CharacterBody2D

@export var speed := 230.0

@onready var explorer_cape: Polygon2D = $ExplorerCape

var nearby_interactable: Node = null


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and nearby_interactable != null:
		get_viewport().set_input_as_handled()
		if nearby_interactable.has_method("interact"):
			nearby_interactable.interact()


func set_nearby_interactable(interactable: Node) -> void:
	nearby_interactable = interactable


func clear_nearby_interactable(interactable: Node) -> void:
	if nearby_interactable == interactable:
		nearby_interactable = null


func set_explorer_cape_visible(is_visible: bool) -> void:
	if explorer_cape != null:
		explorer_cape.visible = is_visible
