extends Control


func _on_Button_Avoid_pressed():
	GameBus.game_mode = GameBus.GameMode.Avoid
	get_tree().change_scene("res://game/Game.tscn")


func _on_Button_Grab_pressed():
	GameBus.game_mode = GameBus.GameMode.Grab
	get_tree().change_scene("res://game/Game.tscn")
