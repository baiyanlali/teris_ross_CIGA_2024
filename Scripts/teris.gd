extends Node2D
class_name TerisManager

var Grid: Array[Array] = []

const GRID_WIDTH = 10
const GRID_HEIGHT = 14

const GRID_SIZE = 64

@export var grid_container_scene: PackedScene

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

#const AVAILABLE_CHUNK_TYPE = [
	#TYPE1,
	#TYPE2,
	#TYPE3,
	#TYPE4,
	#TYPE5,
	#TYPE6,
#]

const AVAILABLE_CHUNK_TYPE = [
	TYPE2,
]

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

var current_fall_chunk: Array[Vector2i] = []

func get_real_position(x: int, y: int) -> Vector2:
	return Vector2(100 + x * GRID_SIZE, 100 + y * GRID_SIZE)

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

func generate_chunks(chunks: Array, offset: Vector2i = Vector2i.ZERO) -> Array[Vector2i]:
	var chunks_pos: Array[Vector2i] = []
	for i in range(len(chunks)):
		for j in range(len(chunks[1])):
			var x := i + offset.x
			var y := j + offset.y
			if chunks[i][j] == 1:
				chunks_pos.append(Vector2i(x, y))
				var go: Node2D = grid_container_scene.instantiate()
				var sprite: Sprite2D = go.get_node("Sprite")
				var size := sprite.texture.get_size()
				sprite.modulate = Color(1, 0, 0, 1)
				
				go.scale = get_grid_size(size)
				Grid[x][y].teris_hold = go
				#go.position = get_real_position(i, j)
				self.add_child(go)
	return chunks_pos
	
func _ready() -> void:
	init_grid()
	$SpawnTimer.timeout.connect(func(): 
		if len(current_fall_chunk) == 0:
			var chunks := generate_chunks(TYPE3, Vector2i(randi_range(0, GRID_WIDTH - 1 - len(TYPE3)), 0))
			current_fall_chunk.append_array(chunks)
		)
	#current_fall_chunk.append_array(generate_chunks(AVAILABLE_CHUNK_TYPE.pick_random(), Vector2i(3, 1)))
	#$Button.pressed.connect(func(): current_fall_chunk.append_array(generate_chunks(AVAILABLE_CHUNK_TYPE.pick_random())))
	$Timer.timeout.connect(teris_down)

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
		if fall_grid.y != lowest_y:
			break
		if fall_grid.y + 1 == GRID_HEIGHT or Grid[fall_grid.x][fall_grid.y + 1].teris_hold:
			# 固定起来
			current_fall_chunk.clear()
			# 检查是否可以消除
			check_and_clear()
			$SpawnTimer.start()
			return
	# 没有问题，可以掉下去
	for fall_grid in fall_chunk:
			# 不固定，往下掉
			pass_teris_hold(Grid[fall_grid.x][fall_grid.y], Grid[fall_grid.x][fall_grid.y + 1])
			new_fall_chunk.append(Vector2i(fall_grid.x, fall_grid.y + 1))
	current_fall_chunk = new_fall_chunk

func check_and_clear() -> void:
	assert(len(current_fall_chunk) == 0)
	for j in range(GRID_HEIGHT-1, -1, -1):
		# 检查横向是否可以消除
		var is_clearable := true
		for i in range(GRID_WIDTH):
			if not Grid[i][j].teris_hold:
				is_clearable = false
				break
		
		if is_clearable:
			for i in range(GRID_WIDTH):
				var teris = Grid[i][j].teris_hold
				teris.queue_free()
				Grid[i][j].teris_hold = null
			#把这一行以上的所有内容设计为fall_chunks
			
			for jj in range(j - 1, -1, -1):
				for i in range(GRID_WIDTH):
					if Grid[i][jj]:
						current_fall_chunk.append(Vector2i(i, jj))
			while len(current_fall_chunk) != 0:
				teris_down()
				

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("move_left"):
		move_fall_chunks(-1)
	if Input.is_action_just_pressed("move_right"):
		move_fall_chunks(1)
	if Input.is_action_just_pressed("move_down"):
		teris_down()
	if Input.is_action_just_pressed("rotate"):
		rotate_fall_chunks()

func check_boundary(pos: Vector2i):
	if pos.x >=0 and pos.x <= GRID_WIDTH and pos.y >=0 and pos.y <=GRID_HEIGHT:
		return true
	return false

func get_grid(pos: Vector2i) -> TerisGrid:
	return Grid[pos.x][pos.y]


func rotate_fall_chunks() -> void:
	$Timer.stop()
	var fall_chunk := current_fall_chunk as Array[Vector2i]
	#var new_fall_chunk: Array[Vector2i] = []
	if(len(fall_chunk) == 0): return
	# 分别按照x, y 顺序升序排序
	var minx :int= fall_chunk.reduce(func(min: Vector2i, val: Vector2i): 
		return val if val.x < min.x else min).x
	var miny :int= fall_chunk.reduce(func(min: Vector2i, val: Vector2i): 
		return val if val.y < min.y else min).y
		
	# 求转制
	
	var new_fall_chunk := fall_chunk.map(func(pos: Vector2i): 
		return ROTATION(pos, 90, Vector2i(minx, miny)))
	if not new_fall_chunk.all(func(pos: Vector2i): return check_boundary(pos)):
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
