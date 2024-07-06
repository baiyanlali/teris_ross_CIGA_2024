extends Node2D
class_name TerisGrid

var grid_pos: Vector2i
var manager: TerisManager
var is_solid: bool = false
var teris_hold: TerisElement

func _process(delta: float) -> void:
	if manager and teris_hold:
		teris_hold.teris_owner = self
		teris_hold.global_position = lerp(teris_hold.global_position, self.global_position, 0.3)
