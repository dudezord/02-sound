extends Node

var wind_speed = 0

var player

var droplets_avoided = 0
var droplets_grabbed = 0

enum GameMode {
	Avoid,
	Grab,
}

var game_mode = GameMode.Avoid

var score = 0

signal signal_droplet_avoided
signal signal_droplet_grabbed

func _ready():
	connect("signal_droplet_avoided", self, "_on_droplet_avoided")
	connect("signal_droplet_grabbed", self, "_on_droplet_grabbed")
	
	
func _on_droplet_avoided(droplet):
	droplets_avoided += 1
	pass
	

func _on_droplet_grabbed(droplet):
	droplets_grabbed += 1
	pass
