extends Node2D

export var speed = 400

func _ready():
	pass


func _process(delta):
	position.y += speed * delta
	if(position.y > 600):
		die()


func die():
	queue_free()
