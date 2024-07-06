extends Node2D
class_name TerisGrid

var grid_pos: Vector2i
var manager: TerisManager
var is_solid: bool = false
var teris_hold: TerisGrid

func _process(delta: float) -> void:
	if manager:
		if teris_hold:
			$Sprite.modulate = Color.RED
			teris_hold.scale = Vector2(0.1, 0.1)
			#teris_hold.visible = false
			teris_hold.global_position = lerp(teris_hold.global_position, self.global_position, 0.3)
		elif manager:
			$Sprite.modulate = Color.WHITE
