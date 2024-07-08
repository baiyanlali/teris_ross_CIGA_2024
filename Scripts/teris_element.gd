extends Node2D
class_name TerisElement
signal post_eliminate
class ElementType:
	var target: String = "null"
	var power: int = 1
	var description: String = "Oh, no"
	var emoji: String = "👋"
	var cost: int = 1
	var max_count_down: int = 3
	var on_eliminate_target : String = "null"
	func _init() -> void:
		pass
	
	func before_take_effect(element: TerisElement):
		pass
	
	func take_effect(player: EmojiPlayer, opponent: EmojiPlayer):
		pass
		
	func get_target(player: EmojiPlayer, opponent: EmojiPlayer):
		if self.target == "null":
			return null
		if self.target == "opponent":
			return opponent
		if self.target == "self":
			return player
		return null
	func get_eliminate_target(player: EmojiPlayer, opponent: EmojiPlayer):
		if self.on_eliminate_target == "null":
			return null
		if self.on_eliminate_target == "opponent":
			return opponent
		if self.on_eliminate_target == "self":
			return player
		return null
	func on_elimited(player: EmojiPlayer, opponent: EmojiPlayer):
		#var target = get_target(player, opponent)
		pass

class Rose extends ElementType:
	func _init() -> void:
		self.emoji = "🌹"
		self.power = 1
		self.description = "攻击1HP.\n消除时攻击5HP."
		self.target = "opponent"
		self.cost = 1
		self.on_eliminate_target = "opponent"
		var max_count_down: int = 2
	
	func take_effect(player: EmojiPlayer, opponent: EmojiPlayer):
		opponent.HP -= self.power
		
	func on_elimited(player: EmojiPlayer, opponent: EmojiPlayer):
		opponent.HP -= self.power * 5


class Immortal extends ElementType:
	func _init() -> void:
		self.emoji = "👑"
		self.power = 50
		self.description = "攻击1HP.\n消除时攻击5HP."
		self.target = "opponent"
		self.cost = 1
		self.on_eliminate_target = "opponent"
		var max_count_down: int = 1
	
	func take_effect(player: EmojiPlayer, opponent: EmojiPlayer):
		opponent.HP -= self.power
		
	func on_elimited(player: EmojiPlayer, opponent: EmojiPlayer):
		opponent.HP -= self.power * 5

class Lotus extends ElementType:
	func _init() -> void:
		self.emoji = "🪷"
		self.power = 1
		self.description = "治疗1HP."
		self.target = "self"
		self.cost = 10
		var max_count_down: int = 3
		
	func take_effect(player: EmojiPlayer, opponent: EmojiPlayer):
		player.HP += self.power

class SunFlower extends ElementType:
	func _init() -> void:
		self.emoji = "🌻"
		self.power = 1
		self.description = "周围冷却-1."
		self.target == "null"
		self.cost = 6
		var max_count_down: int = 2
		
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
				surr.count_down -= 1


@onready var sprite: Sprite2D = $Sprite
@onready var emoji: Label = $Control/Emoji
@onready var count_down_label: Label = $Control/CountDown

var teris_owner: TerisGrid
@onready var element_type : ElementType = Rose.new()

@onready var count_down := 3:
	set(value):
		if count_down != value:
			count_down = value
			count_down_label.text = str(count_down)
			var tween = create_tween()
			var origin_scale = count_down_label.scale
			tween.tween_property(count_down_label, "scale", origin_scale * 1.2, 0.1)
			tween.tween_property(count_down_label, "scale", origin_scale, 0.1)
		
		

var player_owner: TerisManager.Player
var emoji_player: EmojiPlayer
var opponent_player: EmojiPlayer
const BORDER_BLUE = preload("res://Assets/Border_blue.png")
const BORDER_YELLOW = preload("res://Assets/Border_yellow.png")

func _ready() -> void:
	count_down = element_type.max_count_down
	count_down_label.text = str(count_down)
	emoji.text = "🌹"
	
	if player_owner == TerisManager.Player.BLUE:
		sprite.texture = BORDER_BLUE
	else:
		sprite.texture = BORDER_YELLOW

var decay = 0.8  # How quickly the shaking stops [0, 1].
var max_offset = Vector2(30, 30)  # Maximum hor/ver shake in pixels.
var max_roll = 0.1  # Maximum rotation in radians (use sparingly).

var trauma = 0.0  # Current shake strength.
var trauma_power = 2  # Trauma exponent. Use [2, 3].
var offset: Vector2 = Vector2.ZERO


func shake(trauma: float, trauma_power: float):
	var amount = pow(trauma, trauma_power)
	rotation = max_roll * amount * randf_range(-1, 1)
	offset.x = max_offset.x * amount * randf_range(-1, 1)
	offset.y = max_offset.y * amount * randf_range(-1, 1)

func teris_count_down():
	count_down -= 1
	if count_down <= 0:
		# Play animation
		Absolute.start_hit_anim(
			self,
			emoji_player,
			element_type.get_target(emoji_player, opponent_player), 
			func(): 
				if not self:
					return
				trauma = 1
				element_type.before_take_effect(self),
			func(): 
				if not self:
					return
				element_type.take_effect(emoji_player, opponent_player)
				count_down = element_type.max_count_down
		)
	

func on_elimited():
	count_down = 6
	var target = element_type.get_eliminate_target(emoji_player, opponent_player)
	if target == null:
		Absolute.start_eliminate_anim(func():
			await create_tween().tween_property(self, "scale", Vector2.ZERO, 0.2 / Absolute.SPEED_VAR).finished
			post_eliminate.emit()
			self.queue_free()
		)
		
	else:
		Absolute.start_hit_anim(
			self,
			emoji_player,
			element_type.get_eliminate_target(emoji_player, opponent_player), 
			func(): 
				if not self:
					return
				trauma = 1,
			func(): 
				if not self:
					return
				element_type.on_elimited(emoji_player, opponent_player)
				await create_tween().tween_property(self, "scale", Vector2.ZERO, 0.2 / Absolute.SPEED_VAR).finished
				post_eliminate.emit()
				self.queue_free()
				,
		)
	
func _process(delta):
	emoji.text = element_type.emoji
	if trauma:
		trauma = max(trauma - decay * delta, 0)
		shake(trauma, trauma_power)
		self.position += offset
