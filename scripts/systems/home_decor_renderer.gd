extends RefCounted
class_name HomeDecorRenderer

const STAR_RUG_TEXTURE := preload("res://assets/generated/props/home/prop_star_rug_placed_v001.png")
const EXPLORER_CAPE_TEXTURE := preload("res://assets/generated/props/home/prop_explorer_cape_display_v001.png")

var rug_slot: Sprite2D
var cape_slot: Sprite2D


func configure(rug_node: Sprite2D, cape_node: Sprite2D) -> void:
	rug_slot = rug_node
	cape_slot = cape_node
	if rug_slot != null:
		rug_slot.texture = STAR_RUG_TEXTURE
	if cape_slot != null:
		cape_slot.texture = EXPLORER_CAPE_TEXTURE
	refresh()


func refresh(_items: Array[String] = []) -> void:
	if rug_slot != null:
		rug_slot.visible = GameState.has_star_rug()
	if cape_slot != null:
		cape_slot.visible = GameState.has_explorer_cape()
