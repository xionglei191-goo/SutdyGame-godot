extends CanvasLayer

@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var reward_icon: TextureRect = $Panel/MarginContainer/VBoxContainer/RewardIcon
@onready var reward_label: Label = $Panel/MarginContainer/VBoxContainer/RewardLabel
@onready var hint_label: Label = $Panel/MarginContainer/VBoxContainer/HintLabel

const REWARD_ICON_PATHS := {
	"welcome_box_star": "res://assets/generated/rewards/reward_adventure_star_piece_v001.png",
	"first_trip_ticket": "res://assets/generated/rewards/reward_adventure_star_piece_v001.png",
	"school_star_piece": "res://assets/generated/rewards/reward_adventure_star_piece_v001.png",
	"bookshop_leafmark": "res://assets/generated/rewards/reward_adventure_star_piece_v001.png",
	"tidy_badge_piece": "res://assets/generated/rewards/reward_tidy_badge_piece_v001.png",
	"garden_leaf_piece": "res://assets/generated/rewards/reward_garden_leaf_piece_v001.png"
}

var reward_id := ""


func _ready() -> void:
	visible = false


func show_reward(id: String, display_name: String) -> void:
	reward_id = id
	GameState.add_reward(id)
	title_label.text = "Keepsake"
	if REWARD_ICON_PATHS.has(id):
		reward_icon.texture = load(REWARD_ICON_PATHS[id])
	reward_label.text = display_name
	hint_label.text = "Press E / Space to continue"
	visible = true


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		visible = false
