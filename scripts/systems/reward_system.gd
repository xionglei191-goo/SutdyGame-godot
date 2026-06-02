extends CanvasLayer

@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var reward_icon: TextureRect = $Panel/MarginContainer/VBoxContainer/RewardIcon
@onready var reward_label: Label = $Panel/MarginContainer/VBoxContainer/RewardLabel
@onready var hint_label: Label = $Panel/MarginContainer/VBoxContainer/HintLabel

const REWARD_ICON_CONFIG_PATH := "res://data/rewards/reward_icons_v001.json"
const FALLBACK_REWARD_ICON_PATHS := {
	"welcome_box_star": "res://assets/generated/rewards/reward_adventure_star_piece_v001.png",
	"first_trip_ticket": "res://assets/generated/rewards/reward_first_trip_ticket_v001.png",
	"school_star_piece": "res://assets/generated/rewards/reward_adventure_star_piece_v001.png",
	"bookshop_leafmark": "res://assets/generated/rewards/reward_garden_leaf_piece_v001.png",
	"tidy_badge_piece": "res://assets/generated/rewards/reward_tidy_badge_piece_v001.png",
	"garden_leaf_piece": "res://assets/generated/rewards/reward_garden_leaf_piece_v001.png"
}

var reward_id := ""
var _reward_icon_paths: Dictionary = {}


func _ready() -> void:
	visible = false
	_reward_icon_paths = _load_reward_icon_paths()


func show_reward(id: String, display_name: String) -> void:
	reward_id = id
	GameState.add_reward(id)
	title_label.text = "Keepsake"
	var icon_path := str(_reward_icon_paths.get(id, ""))
	if not icon_path.is_empty():
		reward_icon.texture = load(icon_path)
	reward_label.text = display_name
	hint_label.text = "Press E / Space to continue"
	visible = true


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		visible = false


func _load_reward_icon_paths() -> Dictionary:
	var file := FileAccess.open(REWARD_ICON_CONFIG_PATH, FileAccess.READ)
	if file == null:
		return FALLBACK_REWARD_ICON_PATHS.duplicate()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return FALLBACK_REWARD_ICON_PATHS.duplicate()
	var icons: Variant = (parsed as Dictionary).get("icons", {})
	if typeof(icons) != TYPE_DICTIONARY:
		return FALLBACK_REWARD_ICON_PATHS.duplicate()
	var result: Dictionary = FALLBACK_REWARD_ICON_PATHS.duplicate()
	for reward_key: Variant in (icons as Dictionary).keys():
		var reward_id_key := str(reward_key)
		var icon_path := str((icons as Dictionary).get(reward_key, ""))
		if not reward_id_key.is_empty() and not icon_path.is_empty():
			result[reward_id_key] = icon_path
	return result
