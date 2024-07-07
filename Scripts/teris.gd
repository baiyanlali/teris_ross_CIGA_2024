extends Node2D
class_name TerisManager

signal OnTerisLand
signal OnTerisExplode

var Grid: Array[Array] = []

const GRID_WIDTH = 10
const GRID_HEIGHT = 14

const GRID_SIZE = 64

#@export var grid_container_scene: PackedScene
const grid_container_scene = preload("res://Scenes/teris_grid.tscn")
const teris_element_scene: PackedScene = preload("res://Scenes/teris_element.tscn")

const TYPE1 = [
	[1, 0],
	[1, 1],
	[0, 1]
]

const TYPE2 = [
	[0, 1],
	[1, 1],
	[0, 1]
]

const TYPE3 = [
	[1, 1],
	[1, 1],
]

const TYPE4 = [
	[1, 0],
	[1, 1],
	[1, 0]
]

const TYPE5 = [
	[1, 1],
	[1, 0],
	[1, 0]
]

const TYPE6 = [
	[1,],
	[1,],
	[1,],
	[1,],
]

const AVAILABLE_CHUNK_TYPE = [
	TYPE1,
	TYPE2,
	TYPE3,
	TYPE4,
	TYPE5,
	TYPE6,
]

#const AVAILABLE_CHUNK_TYPE = [
	#TYPE2,
#]
enum Player {
	BLUE, YELLOW
}

var current_player : Player= Player.BLUE
@onready var blue_player: EmojiPlayer = $Player1
@onready var yellow_player: EmojiPlayer = $Player2

var current_fall_chunk: Array[Vector2i] = []
@onready var shop: Shop = $Control/Shop

@onready var next_type = AVAILABLE_CHUNK_TYPE.pick_random()

func start_game():
	print("start game")
	Absolute.TerisManager = self
	Absolute.BluePlayer = blue_player
	Absolute.YellowPlayer = yellow_player
	
	Absolute.BluePlayer.HP = Absolute.BluePlayer.MAXHP
	Absolute.YellowPlayer.HP = Absolute.YellowPlayer.MAXHP

	for i in range(GRID_WIDTH):
		for j in range(GRID_HEIGHT):
			var go = Grid[i][j]
			if go.teris_hold:
				go.teris_hold.queue_free()
			go.teris_hold = null
	
	$SpawnTimer.start()
	$Timer.start()

func resume_game():
	$SpawnTimer.start()
	$Timer.start()

func stop_game():
	$SpawnTimer.stop()
	$Timer.stop()

func _ready() -> void:
	Absolute.TerisManager = self
	init_grid()
	shop.show_shop()
	
	$SpawnTimer.timeout.connect(func(): 
		if len(Absolute.hit_anim_bus) != 0:
			return
		if len(current_fall_chunk) == 0:
			#var type = AVAILABLE_CHUNK_TYPE.pick_random()
			var chunks := generate_chunks(next_type, Vector2i(randi_range(0, GRID_WIDTH - 1 - len(next_type)), 0))
			current_fall_chunk.append_array(chunks)
			next_type = AVAILABLE_CHUNK_TYPE.pick_random()
			show_next_type()
		)
	$Timer.timeout.connect(teris_down)
	
@onready var preview_teris: Node2D = $Control/Label/PreviewTeris
const TERIS_PREVIEW = preload("res://Scenes/teris_preview.tscn")
func show_next_type():
	for c in preview_teris.get_children():
		c.queue_free()
	for i in range(len(next_type)):
		for j in range(len(next_type[0])):
			if next_type[i][j] != 1:
				continue
			var go = TERIS_PREVIEW.instantiate()
			preview_teris.add_child(go)
			go.position = Vector2(i * 88 * 0.5, j * 88 * 0.5)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("move_left"):
		move_fall_chunks(-1)
	if Input.is_action_just_pressed("move_right"):
		move_fall_chunks(1)
	if Input.is_action_just_pressed("move_down"):
		teris_down()
	if Input.is_action_just_pressed("rotate"):
		rotate_fall_chunks()


func ROTATION(pos: Vector2i, degree: int = 90, rotation_center: Vector2i = Vector2i.ZERO):
	
	#var r := deg_to_rad(degree)
	#
	var new_pos := pos - rotation_center
	#var rx = cos(r) * new_pos.x - sin(r) * new_pos.y
	#var ry = sin(r) * new_pos.x + cos(r) * new_pos.y
	var rx = - new_pos.y
	var ry = new_pos.x
	# 很奇怪的代码，因为精度问题，只能这样子写
	var result := Vector2(rx, ry) as Vector2i
	return result + rotation_center


func get_real_position(x: int, y: int) -> Vector2:
	return Vector2(1920/2 - GRID_SIZE * GRID_WIDTH /2 + x * GRID_SIZE, 1080 /2 - GRID_SIZE * GRID_HEIGHT / 2 + 100 + y * GRID_SIZE)

func get_grid_size(size: Vector2) -> Vector2:
	return Vector2( GRID_SIZE / size.x, GRID_SIZE / size.y)

func init_grid():
	for i in range(GRID_WIDTH):
		Grid.append([])
		for j in range(GRID_HEIGHT):
			Grid[i].append(0)
			
	for i in range(GRID_WIDTH):
		for j in range(GRID_HEIGHT):
			var go: TerisGrid = grid_container_scene.instantiate()
			go.grid_pos = Vector2i(i, j)
			go.manager = self
			var sprite: Sprite2D = go.get_node("Sprite")
			var size := sprite.texture.get_size()
			go.scale = get_grid_size(size)
			go.position = get_real_position(i, j)
			self.add_child(go)
			Grid[i][j] = go
			go.name = "(%d, %d)" % [i, j]

func get_emoji_player(current_player = current_player):
	if current_player == Player.BLUE:
		return blue_player
	else:
		return yellow_player

func generate_chunks(chunks: Array, offset: Vector2i = Vector2i.ZERO) -> Array[Vector2i]:
	
	var chunks_pos: Array[Vector2i] = []
	for i in range(len(chunks)):
		for j in range(len(chunks[1])):
			var x := i + offset.x
			var y := j + offset.y
			if chunks[i][j] == 1:
				chunks_pos.append(Vector2i(x, y))
				var go: TerisElement = teris_element_scene.instantiate()
				go.player_owner = current_player
				go.emoji_player = get_emoji_player()
				go.opponent_player = get_emoji_player(1-current_player)
				self.add_child(go)
				OnTerisLand.connect(go.teris_count_down)
				var sprite: Sprite2D = go.sprite
				var size := sprite.texture.get_size()
				#sprite.modulate = Color(1, 0, 0, 1)
				go.scale = get_grid_size(size)
				Grid[x][y].teris_hold = go
				if current_player == Player.BLUE:
					go.element_type = Absolute.player_type.pick_random()
				else:
					go.element_type = Absolute.enemy_type.pick_random()
				#go.position = get_real_position(i, j)
	current_player = 1 - current_player
	return chunks_pos
	


func pass_teris_hold(s1: TerisGrid, s2: TerisGrid):
	var temp_hold = s2.teris_hold
	s2.teris_hold = s1.teris_hold
	s1.teris_hold = temp_hold
	#print("exchange ", s1.grid_pos, s2.grid_pos)



func pass_teris_many(s1: Array, s2: Array):
	assert(len(s1) ==  len(s2))
	var teris_containers = s1.map(func(pos: Vector2i): return get_grid(pos).teris_hold)
	s1.map(func(pos: Vector2i): get_grid(pos).teris_hold = null; return false)
	
	for i in range(len(s1)):
		var container_origin_hold = teris_containers[i]
		var new_container = get_grid(s2[i])
		new_container.teris_hold = container_origin_hold

func teris_down() -> void:
	#print("teris down!")
	var fall_chunk := current_fall_chunk as Array[Vector2i]
	var new_fall_chunk: Array[Vector2i] = []
	if(len(fall_chunk) == 0): return
	# 按照y轴降序排序
	fall_chunk.sort_custom(func(a, b): return a.y > b.y)
	# 监测最底下一层grid是否会往下掉，也就是y最大的grid
	var lowest_y = fall_chunk[0].y
	
	for fall_grid in fall_chunk:
		if fall_grid.y + 1 == GRID_HEIGHT \
			or (Grid[fall_grid.x][fall_grid.y + 1].teris_hold and Vector2i(fall_grid.x, fall_grid.y + 1) not in current_fall_chunk):
			# 固定起来
			current_fall_chunk.clear()
			# 检查是否可以消除
			await check_and_clear()
			OnTerisLand.emit()
			if len(Absolute.hit_anim_bus) == 0:
				$SpawnTimer.start()
	# 没有问题，可以掉下去
	for fall_grid in fall_chunk:
			# 不固定，往下掉
			pass_teris_hold(Grid[fall_grid.x][fall_grid.y], Grid[fall_grid.x][fall_grid.y + 1])
			new_fall_chunk.append(Vector2i(fall_grid.x, fall_grid.y + 1))
	current_fall_chunk = new_fall_chunk

func fall_down_fast(teris_above: Array[Vector2i]):
	#print("teris down!")
	var fall_chunk := teris_above as Array[Vector2i]
	var new_fall_chunk: Array[Vector2i] = []
	if(len(fall_chunk) == 0): return
	# 按照y轴降序排序
	fall_chunk.sort_custom(func(a, b): return a.y > b.y)
	# 监测最底下一层grid是否会往下掉，也就是y最大的grid
	var lowest_y = fall_chunk[0].y
	
	var has_reach_below := false
	
	while not has_reach_below:
		fall_chunk.sort_custom(func(a, b): return a.y > b.y)
		lowest_y = fall_chunk[0].y
		for fall_grid in fall_chunk:
			if fall_grid.y != lowest_y:
				break
			#print(fall_grid.y + 1)
			if fall_grid.y + 1 == GRID_HEIGHT \
				or (Grid[fall_grid.x][fall_grid.y + 1].teris_hold):
				# 固定起来
				has_reach_below = true
				print("reach below!")
				return
		# 没有问题，可以掉下去
		for fall_grid in fall_chunk:
			# 不固定，往下掉
			pass_teris_hold(Grid[fall_grid.x][fall_grid.y], Grid[fall_grid.x][fall_grid.y + 1])
			new_fall_chunk.append(Vector2i(fall_grid.x, fall_grid.y + 1))
		fall_chunk = new_fall_chunk

func check_and_clear() -> void:
	assert(len(current_fall_chunk) == 0)
	var new_fall_chunk: Array[Vector2i] = []
	for j in range(GRID_HEIGHT-1, -1, -1):
		# 检查横向是否可以消除
		var is_clearable := true
		for i in range(GRID_WIDTH):
			if not Grid[i][j].teris_hold:
				is_clearable = false
				break
		
		if is_clearable:
			for i in range(GRID_WIDTH):
				var teris: TerisElement = Grid[i][j].teris_hold
				teris.on_elimited()
				await teris.post_eliminate
				#teris.hide()
				#get_tree().create_timer(2).timeout.connect(func(): teris.queue_free())
				#teris.queue_free()
				Grid[i][j].teris_hold = null
			#把这一行以上的所有内容设计为fall_chunks
			
			for jj in range(j - 1, -1, -1):
				for i in range(GRID_WIDTH):
					if Grid[i][jj].teris_hold:
						new_fall_chunk.append(Vector2i(i, jj))
			fall_down_fast(new_fall_chunk)
				#teris_down()	


func check_boundary(pos: Vector2i):
	if pos.x >=0 and pos.x < GRID_WIDTH and pos.y >=0 and pos.y < GRID_HEIGHT:
		return true
	return false

func get_grid(pos: Vector2i) -> TerisGrid:
	return Grid[pos.x][pos.y]


func rotate_fall_chunks() -> void:
	$Timer.stop()
	var fall_chunk := current_fall_chunk as Array[Vector2i]
	#var new_fall_chunk: Array[Vector2i] = []
	if(len(fall_chunk) == 0): 
		$Timer.start()
		return
	# 分别按照x, y 顺序升序排序
	var minx :int= fall_chunk.reduce(func(min: Vector2i, val: Vector2i): 
		return val if val.x < min.x else min).x
	var miny :int= fall_chunk.reduce(func(min: Vector2i, val: Vector2i): 
		return val if val.y < min.y else min).y
		
	var maxx :int= fall_chunk.reduce(func(min: Vector2i, val: Vector2i): 
		return val if val.x > min.x else min).x
	var maxy :int= fall_chunk.reduce(func(min: Vector2i, val: Vector2i): 
		return val if val.y > min.y else min).y
	# 求旋转后的
	
	var new_fall_chunk := fall_chunk.map(func(pos: Vector2i): 
		$Timer.start()
		return ROTATION(pos, 90, Vector2i(int((minx + maxx) / 2), int((miny + maxy) / 2))))
	# 是否超出界限
	if not new_fall_chunk.all(func(pos: Vector2i): return check_boundary(pos)):
		$Timer.start()
		return
	# 是否已经有格子了
	
	var is_occupied := new_fall_chunk.any(func(pos: Vector2i): 
		if pos in fall_chunk:
			return false
		return get_grid(pos).teris_hold)
	if is_occupied:
		return
	
	#print(fall_chunk, new_fall_chunk)
	#$Timer.start()
	# 监测最右侧一层grid是否会往右掉
	pass_teris_many(fall_chunk, new_fall_chunk)
	#for i in range(len(fall_chunk)):
		#pass_teris_hold(get_grid(fall_chunk[i]), get_grid(new_fall_chunk[i]))
	fall_chunk.clear()
	fall_chunk.append_array(new_fall_chunk)
	
	$Timer.start()
	
	
func move_fall_chunks(move_x: int) -> void:
	var fall_chunk := current_fall_chunk as Array[Vector2i]
	var new_fall_chunk: Array[Vector2i] = []
	if(len(fall_chunk) == 0): return
	# 按照y轴降序排序
	fall_chunk.sort_custom(func(a, b): return a.x * move_x > b.x * move_x)
	# 监测最右侧一层grid是否会往右掉
	var right_most_x = fall_chunk[0].x
	
	for fall_grid in fall_chunk:
		if fall_grid.x != right_most_x:
			break
		if fall_grid.x + move_x >= GRID_WIDTH \
			or fall_grid.x + move_x <= -1 \
			or Grid[fall_grid.x + move_x][fall_grid.y].teris_hold:
			# 固定起来
			#current_fall_chunk.clear()
			return
	# 没有问题，可以往右边走
	for fall_grid in fall_chunk:
			# 不固定，往下掉
			pass_teris_hold(Grid[fall_grid.x][fall_grid.y], Grid[fall_grid.x + move_x][fall_grid.y])
			new_fall_chunk.append(Vector2i(fall_grid.x + move_x, fall_grid.y))
	current_fall_chunk = new_fall_chunk
