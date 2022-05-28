extends Node2D

var speed = 300
var delta_speed = 20
var delta_position = 5
var acceleration = 100

var _horizontal_speed = 0.0

func _ready():
	speed += rand_range(-delta_speed, delta_speed)
	position.x += rand_range(-delta_position, delta_position)
	
	_horizontal_speed = GameBus.player.position.x - position.x
	_horizontal_speed *= rand_range(0.3, 0.5)

func _process(delta):
	speed += acceleration * delta
	position.y += speed * delta

	position.x += _horizontal_speed * delta
	if(position.x > 640):
		position.x = -20


func die():
	queue_free()
