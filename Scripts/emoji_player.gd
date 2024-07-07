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
		
		get_tree().create_timer(5).timeout.connect(func(): health_change.text = "")
		
		var tn := create_tween().tween_property(sprite, "position", sprite.position + HitDirection, 0.5)
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
	
	var tn := create_tween().tween_property(sprite, "position", sprite.position - HitDirection, 0.2)
	tn.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
