extends Node2D
class_name EmojiPlayer

@export var EMOJI_NORMAL: Texture
@export var EMOJI_HIT: Texture
@export var EMOJI_HAPPY: Texture
@export var EMOJI_LOWHP: Texture

@export var MAXHP: int = 100
@onready var HP: int = MAXHP:
	set(val):
		if val < HP:
			sprite.texture = EMOJI_HIT
		else:
			sprite.texture = EMOJI_HAPPY
		HP = val
		progress_bar.value = HP
		
		$Timer.start()
		if HP < 0:
			pass
		

@onready var sprite: Sprite2D = $Sprite

@onready var progress_bar: ProgressBar = $Control/ProgressBar
@onready var timer: Timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite.texture = EMOJI_NORMAL
	progress_bar.max_value = MAXHP
	HP = MAXHP
	$Timer.timeout.connect(back_to_normal_face)

func back_to_normal_face():
	if HP / float(MAXHP) < 0.2:
		sprite.texture = EMOJI_LOWHP
	else:
		sprite.texture = EMOJI_NORMAL
