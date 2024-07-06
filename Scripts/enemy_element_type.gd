extends Node
class_name EnemyElementType


class Archer extends TerisElement.ElementType:
	func _init() -> void:
		self.emoji = "🫷"
		self.power = 2
		self.description = "Hit player."
		self.target = "opponent"
		self.cost = 999
	
	func take_effect(player: EmojiPlayer, opponent: EmojiPlayer):
		opponent.HP -= self.power


class Reaper extends TerisElement.ElementType:
	func _init() -> void:
		self.emoji = "𓀏"
		self.power = 1
		self.description = "Enpower surroundings."
		self.target == "null"
		self.cost = 9999
		
	func before_take_effect(element: TerisElement):
		var pos = element.teris_owner.grid_pos
		var direction = [
			Vector2i.UP, Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN
		]
		for dir in direction:
			var target_pos = dir + pos
			if not Absolute.TerisManager.check_boundary(target_pos):
				continue
			var surr: TerisElement = Absolute.TerisManager.Grid[target_pos.x][target_pos.y].teris_hold
			if surr:
				surr.count_down += 1
