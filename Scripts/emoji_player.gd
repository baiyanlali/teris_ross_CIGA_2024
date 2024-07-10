extends Node2D
class_name EmojiPlayer


@export var EMOJI_NORMAL: Texture
@export var EMOJI_HIT: Texture
@export var EMOJI_HAPPY: Texture
@export var EMOJI_LOWHP: Texture
@export var HitDirection: Vector2

@onready var health_change: Label = $Control/HealthChange

@export var MAXHP: int = 100
@onready var HP: int = MAXHP:
	set(val):
		
		if health_change.text != "":
			health_change.text = str(health_change.text.to_int() + (val - HP))
		else:
			health_change.text = str(val - HP)
		
		get_tree().create_timer(7 / Absolute.SPEED_VAR).timeout.connect(func(): health_change.text = "")
		
		var final_pos := sprite.position + HitDirection * log(abs(health_change.text.to_int()))
		
		
		var tn := create_tween().tween_property(sprite, "position", final_pos, 0.5 / Absolute.SPEED_VAR)
		tn.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
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
@onready var initial_pos: Vector2


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	initial_pos = sprite.position
	sprite.texture = EMOJI_NORMAL
	progress_bar.max_value = MAXHP
	HP = MAXHP
	$Timer.timeout.connect(back_to_normal_face)

func back_to_normal_face():
	if HP / float(MAXHP) < 0.2:
		sprite.texture = EMOJI_LOWHP
	else:
		sprite.texture = EMOJI_NORMAL
	
	var tn := create_tween().tween_property(sprite, "position", initial_pos, 0.2 / Absolute.SPEED_VAR)
	tn.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
