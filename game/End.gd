extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	$HBoxContainer/Points.text = String(GameBus.score)


func _on_MainMenu_Avoid_pressed():
	get_tree().change_scene("res://game/Start.tscn")
