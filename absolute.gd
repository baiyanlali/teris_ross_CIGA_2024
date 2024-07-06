extends Node
var TerisManager: TerisManager = null
var BluePlayer: EmojiPlayer
var YellowPlayer: EmojiPlayer

var player_money: int = 5:
	set(val):
		player_money = val
		on_money_changed.emit(player_money)

signal on_money_changed

var player_type: Array = []

var shop_window: Shop = null

func _process(delta: float) -> void:
	if BluePlayer and YellowPlayer:
		if YellowPlayer.HP <= 0:
			TerisManager.stop_game()
			await get_tree().create_timer(0.5).timeout
			shop_window.show_shop()
