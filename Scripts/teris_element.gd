extends Node2D
class_name TerisElement

@onready var sprite: Sprite2D = $Sprite
@onready var emoji: Label = $Control/Emoji
@onready var count_down_label: Label = $Control/CountDown

@export var max_count_down := 3

@onready var count_down := 3:
	set(value):
		count_down = value
		count_down_label.text = str(count_down)

var player_owner: TerisManager.Player
var emoji_player: EmojiPlayer
var opponent_player: EmojiPlayer
const BORDER_BLUE = preload("res://Assets/Border_blue.png")
const BORDER_YELLOW = preload("res://Assets/Border_yellow.png")

func _ready() -> void:
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
	if count_down == 0:
		count_down = max_count_down
		trauma = 1
		if opponent_player:
			opponent_player.HP -= 1
		pass

func _process(delta):
	if trauma:
		trauma = max(trauma - decay * delta, 0)
		shake(trauma, trauma_power)
		self.position += offset
