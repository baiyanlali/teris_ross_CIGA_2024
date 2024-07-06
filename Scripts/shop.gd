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
	
	tween.tween_property(self, "position:y", 0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	next.pressed.connect(close_shop)
func on_buy_type(element: TerisElement.ElementType):
	if Absolute.player_money <= 0:
		return
	print("buy %s" % element.emoji)
	Absolute.player_type.append(element)
	Absolute.player_money -= 1
	sync_type(Absolute.player_type)

func show_shop():
	sync_money(Absolute.player_money)
	tween = create_tween()
	tween.tween_property(self, "position:y", 0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)


func close_shop():
	#self.position.y = 1080
	tween = create_tween()
	await tween.tween_property(self, "position:y", 1080, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	on_shop_close.emit()

func sync_type(arr: Array):
	owned_flowers.text = "Your flowers: \n"
	for a in arr:
		owned_flowers.text += a.emoji

func sync_money(money: int):
	money_label.text = ""
	for i in range(money):
		money_label.text += "$"
	print(money_label.text)
