extends Control
class_name ShopElement


@onready var button: Button = $Button
@onready var label: Label = $Label

	
func _make_custom_tooltip(for_text):
	print(for_text)
	var tooltip = preload("res://Scenes/tool_tip.tscn").instantiate()
	tooltip.get_node("Label").text = for_text
	return tooltip
