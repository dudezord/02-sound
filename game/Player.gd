extends Node2D

var speed = 300
var rotation_speed = 6.75
var _dir = 0.0


func _ready():
	GameBus.player = self


func _input(event):
	_dir = 0.0
	
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		_dir += -1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		_dir += 1.0


func _process(delta):
	if position.x < 63 and _dir < 0:
		return
		
	if position.x > 640 - 20 and _dir > 0:
		return
	
	position.x += delta * speed * _dir
	rotation += delta * rotation_speed * _dir


func _on_Area2D_area_entered(area):
	GameBus.emit_signal("signal_droplet_grabbed", area.owner)
	area.owner.die()
