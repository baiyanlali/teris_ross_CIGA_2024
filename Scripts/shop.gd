extends Control
class_name Shop

signal on_shop_close
const SHOP_ELEMENT = preload("res://Scenes/shop_element.tscn")
@onready var h_box_container: HBoxContainer = $NinePatchRect/HBoxContainer

const buy_type := [TerisElement.Rose, TerisElement.Lotus, TerisElement.SunFlower]

@onready var next: Button = $NinePatchRect/Next
@onready var money_label: Label = $NinePatchRect/Money
@onready var owned_flowers: Label = $NinePatchRect/OwnedFlowers

@onready var tween := create_tween()
@onready var enemy_element: VBoxContainer = $NinePatchRect/EnemyRegion/EnemyElement

var on_shop = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Absolute.shop_window = self
	Absolute.on_money_changed.connect(sync_money)
	for b in buy_type:
		var type: TerisElement.ElementType = b.new()
		var go: ShopElement = SHOP_ELEMENT.instantiate()
		h_box_container.add_child(go)
		go.button.text = type.emoji
		go.button.pressed.connect(on_buy_type.bind(type))
		go.button.tooltip_text = type.description
		go.label.text = ""
		for i in range(type.cost):
			go.label.text += "$"
	
	tween.tween_property(self, "position:y", 0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	next.pressed.connect(close_shop)
	sync_type(Absolute.player_type)
	
func on_buy_type(element: TerisElement.ElementType):
	if Absolute.player_money <= 0 or Absolute.player_money - element.cost < 0:
		return
	Absolute.player_type.append(element)
	Absolute.player_money -= element.cost
	sync_type(Absolute.player_type)

func show_shop():
	on_shop = true
	sync_money(Absolute.player_money)
	sync_enemy_type()
	tween = create_tween()
	tween.tween_property(self, "position:y", 0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)


func close_shop():
	#self.position.y = 1080
	tween = create_tween()
	await tween.tween_property(self, "position:y", 1080, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	on_shop_close.emit()
	on_shop = false

func sync_enemy_type():
	var enemy_type = Absolute.enemy_type
	
	for enemy in enemy_element.get_children():
		enemy.queue_free()
	
	for enemy in enemy_type:
		var go : ShopElement= SHOP_ELEMENT.instantiate()
		enemy_element.add_child(go)
		
		go.button.text = enemy.emoji
		go.button.tooltip_text = enemy.description
		go.label.text = enemy.description	

func sync_type(arr: Array):
	owned_flowers.text = "\n"
	for a in arr:
		owned_flowers.text += a.emoji

func sync_money(money: int):
	money_label.text = ""
	for i in range(money):
		money_label.text += "$"
	print(money_label.text)
