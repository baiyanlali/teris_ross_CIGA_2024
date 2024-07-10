extends Node
signal on_money_changed
var SPEED_VAR := 1.0

@onready var tween: Tween = create_tween()
const HIT_PARTICLE = preload("res://Scenes/hit_particle.tscn")

var TerisManager: TerisManager = null
var BluePlayer: EmojiPlayer = null
var YellowPlayer: EmojiPlayer = null

#var player_type: Array = [TerisElement.Immortal.new()]
var player_type: Array = [TerisElement.Rose.new()]

var current_level := 1

var on_shop := false

var enemy_type: Array = [
	EnemyElementType.Archer.new(),
]

var shop_window: Shop = null:
	set(val):
		shop_window = val
		shop_window.on_shop_close.connect(start_new_turn)
		

var player_money: int = 5:
	set(val):
		player_money = val
		on_money_changed.emit(player_money)

func next_level_config():
	
	TerisManager.stop_game()
	YellowPlayer.HP = YellowPlayer.MAXHP
	win_game = false
	print("stop game")
	
	var children = get_tree().root.get_children(true)
	
	for child in TerisManager.get_children():
		if is_instance_of(child, TerisElement):
			child.queue_free()
	
	hit_anim_bus = []
	current_level += 1
	
	if current_level == 2:
		player_money += 10
		
		enemy_type = [
			EnemyElementType.Archer.new(),
			EnemyElementType.Reaper.new()
		]
	if current_level == 3:
		player_money += 20
		
		enemy_type = [
			EnemyElementType.Reaper.new(),
			EnemyElementType.HoneyBee.new(),
			EnemyElementType.HoneyBee.new(),
		]
	if current_level == 4:
		game_end = true
		BluePlayer = null
		YellowPlayer = null
		get_tree().change_scene_to_file("res://Scenes/win_scene.tscn")

var game_end = false
func start_new_turn():
	win_game = false
	TerisManager.start_game()
	hit_anim_bus = []

var win_game := false

func _process(delta: float) -> void:
	if game_end:
		return
	if BluePlayer and YellowPlayer:
		if YellowPlayer.HP <= 0 and win_game == false and len(hit_anim_bus) == 0:
			win_game = true
			TerisManager.stop_game()
			next_level_config()
			
			await get_tree().create_timer(0.5).timeout
			if game_end:
				return
			if current_level < 4:
				shop_window.show_shop()
		if BluePlayer and BluePlayer.HP <= 0:
			get_tree().change_scene_to_file("res://Scenes/false_scene.tscn")
	if last_anim_bus_length !=0 and len(hit_anim_bus) == 0 and TerisManager:
		if not shop_window.on_shop:
			TerisManager.resume_game()
	last_anim_bus_length = len(hit_anim_bus)
	
	if Input.is_action_pressed("speed_up"):
		SPEED_VAR = 5.0
	else:
		SPEED_VAR = 1.0
		
var hit_anim_bus := []
var last_anim_bus_length := 0

const TRANS_TYPES_FOR_HIT = [
	Tween.TRANS_BACK,
	Tween.TRANS_CIRC,
	Tween.TRANS_CUBIC,
	Tween.TRANS_LINEAR,
	Tween.TRANS_QUAD,
]

func start_eliminate_anim(anim: Callable):
	
	var animation := func():
		await anim.call()
		
		hit_anim_bus.pop_front()
		if len(hit_anim_bus) != 0:
			var anim_func = hit_anim_bus[0]
			anim_func.call()
	
	hit_anim_bus.append(animation)
	
	if len(hit_anim_bus) == 1:
		await hit_anim_bus[0].call()


func start_hit_anim(elemt: TerisElement, origin: EmojiPlayer, target: EmojiPlayer, on_hit_anim_start: Callable, on_hit_anim_end: Callable):
	var animation := func():
		TerisManager.stop_game()
		
		if not elemt:
			hit_anim_bus.pop_front()
			if len(hit_anim_bus) != 0:
				var anim_func = hit_anim_bus[0]
				anim_func.call()
			return
			
		if on_hit_anim_start and on_hit_anim_start.is_valid() and on_hit_anim_start.get_object() != null:
			on_hit_anim_start.call()
			
		if not target:
			hit_anim_bus.pop_front()
			if len(hit_anim_bus) != 0:
				var anim_func = hit_anim_bus[0]
				anim_func.call()
			return
		var go: HitParticle = HIT_PARTICLE.instantiate()
		
		add_child(go)
		go.global_position = elemt.global_position
		
		if origin == target:
			go.sprite.modulate = Color.GREEN
		else:
			if target == BluePlayer:
				go.sprite.modulate = Color.YELLOW
			elif target == YellowPlayer:
				go.sprite.modulate = Color.BLUE
		
		tween = create_tween()
		tween.tween_property(go, "global_position:x", target.global_position.x, 1 / SPEED_VAR).set_ease(Tween.EASE_IN).set_trans(TRANS_TYPES_FOR_HIT.pick_random())
		tween.parallel().tween_property(go, "global_position:y", target.global_position.y, 1 / SPEED_VAR).set_ease(Tween.EASE_IN).set_trans(TRANS_TYPES_FOR_HIT.pick_random())
		tween.parallel().tween_property(go, "skew", 720, 1/SPEED_VAR).set_ease(Tween.EASE_IN).set_trans(TRANS_TYPES_FOR_HIT.pick_random())
		
		#await get_tree().create_timer(0.5).timeout
		await tween.finished
		if on_hit_anim_end and on_hit_anim_end.is_valid():
			on_hit_anim_end.call()
		
		go.queue_free()
		
		if not TerisManager:
			hit_anim_bus = []
			return
		hit_anim_bus.pop_front()
		if len(hit_anim_bus) != 0:
			var anim_func = hit_anim_bus[0]
			anim_func.call()

	hit_anim_bus.append(animation)
	
	if len(hit_anim_bus) == 1:
		await hit_anim_bus[0].call()


func start_eliminate_hit_anim(elemt: TerisElement, origin: EmojiPlayer, target: EmojiPlayer, on_hit_anim_start: Callable, on_hit_anim_end: Callable):
	var animation := func():
		TerisManager.stop_game()
		
		if not elemt:
			hit_anim_bus.pop_front()
			if len(hit_anim_bus) != 0:
				var anim_func = hit_anim_bus[0]
				anim_func.call()
			return
			
		if on_hit_anim_start and on_hit_anim_start.is_valid() and on_hit_anim_start.get_object() != null:
			on_hit_anim_start.call()
			
		if not target:
			hit_anim_bus.pop_front()
			if len(hit_anim_bus) != 0:
				var anim_func = hit_anim_bus[0]
				anim_func.call()
			return
		elemt.teris_owner.teris_hold = null
		tween = create_tween()
		tween.tween_property(elemt, "global_position:x", target.global_position.x, 1 / SPEED_VAR).set_ease(Tween.EASE_IN).set_trans(TRANS_TYPES_FOR_HIT.pick_random())
		tween.parallel().tween_property(elemt, "global_position:y", target.global_position.y, 1 / SPEED_VAR).set_ease(Tween.EASE_IN).set_trans(TRANS_TYPES_FOR_HIT.pick_random())
		
		await tween.finished
		if on_hit_anim_end and on_hit_anim_end.is_valid():
			on_hit_anim_end.call()
		
		if not TerisManager:
			hit_anim_bus = []
			return
		hit_anim_bus.pop_front()
		if len(hit_anim_bus) != 0:
			var anim_func = hit_anim_bus[0]
			anim_func.call()

	hit_anim_bus.append(animation)
	
	if len(hit_anim_bus) == 1:
		await hit_anim_bus[0].call()
