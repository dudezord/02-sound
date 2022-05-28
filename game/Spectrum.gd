extends Node2D

export var tear : PackedScene

const FREQ_OFFSET = 0.1
const NOTES_WINDOW_SIZE  = 15

const MULTIPLE_NOTES = 2
const MULTIPLE_NOTES_VOLUME_SIMILARITY = 0.85

const BASE_OCTAVE = 3
const NUM_OCTAVES = 3

const NOTES_IN_OCTAVE = 12
const A_BASE = 55 * pow(2, BASE_OCTAVE - 1)
const A = 1.059463094359
const TOTAL_NOTES = NOTES_IN_OCTAVE * NUM_OCTAVES

const WIDTH = 640
const HEIGHT = 480

var spectrum : AudioEffectInstance

var prev_note_values = []
var note_values = []

var notes_window = []

var loudest_note_str = ""
var loudest_note = 0
var loudest_note_idx = 0

var loop_speed = 66

const MIN_DB = 60

var score = 0

class MyNoteSorter:
	static func sort_descending(a, b):
		return a[1] > b[1]

func _ready() -> void:
	$SilentAudioStreamPlayer2D.play(0)
	$AudioStreamPlayer2D.play(0)
	
	spectrum = AudioServer.get_bus_effect_instance(1, 0)

	if GameBus.game_mode == GameBus.GameMode.Avoid:
		$Mission.text = "Avoid the droplets!"
	elif GameBus.game_mode == GameBus.GameMode.Grab:
		$Mission.text = "Grab the droplets!"

	GameBus.connect("signal_droplet_avoided", self, "_on_droplet_avoided")
	GameBus.connect("signal_droplet_grabbed", self, "_on_droplet_grabbed")


func _process(_delta) -> void:
	_update_notes()
	_spawn_tears()
	
	_update_score()
	
	var remaining_total_seconds = $AudioStreamPlayer2D.stream.get_length() - $AudioStreamPlayer2D.get_playback_position()
	var remaining_minutes = remaining_total_seconds / 60
	var remaining_seconds = (remaining_total_seconds as int) % 60
	
	$Timer.text = "%02d:%02d" % [remaining_minutes, remaining_seconds]


func _update_score() -> void:
	if GameBus.game_mode == GameBus.GameMode.Avoid:
		score = GameBus.droplets_avoided
		score -= GameBus.droplets_grabbed
	elif GameBus.game_mode == GameBus.GameMode.Grab:
		score = GameBus.droplets_grabbed
		score -= GameBus.droplets_avoided

	$Avoided/Label.text = String(score)
	GameBus.score = score


func _update_notes() -> void:
	prev_note_values = note_values
	note_values = []
	
	for _i in range(0, NOTES_IN_OCTAVE):
		note_values.push_back([0,0])

	for i in range(0, TOTAL_NOTES):
		var index = i % NOTES_IN_OCTAVE
		var from_hz := A_BASE * pow(A, i - FREQ_OFFSET)
		var to_hz := A_BASE * pow(A, i + FREQ_OFFSET)
		var mode := AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_MAX
		
		var magnitude = spectrum.get_magnitude_for_frequency_range(from_hz, to_hz, mode).length()
		var energy = clamp((MIN_DB + linear2db(magnitude)) / MIN_DB, 0, 1)
		note_values[index][0] = index
		note_values[index][1] += energy
	
		from_hz = to_hz
			
	notes_window.append(note_values)
	
	if notes_window.size() > NOTES_WINDOW_SIZE:
		notes_window.remove(0)


func _spawn_tears() -> void:
	if notes_window.size() != NOTES_WINDOW_SIZE:
		return
	
	var accum_notes = []
	for _i in range(0, NOTES_IN_OCTAVE):
		accum_notes.push_back([0,0])
		
	for window_idx in range(0, NOTES_WINDOW_SIZE):
		var notes = notes_window[window_idx]
		
		for i in range(0, notes.size()):
			accum_notes[i][0] = notes[i][0]
			accum_notes[i][1] += notes[i][1]
			
	notes_window = []
	
	accum_notes.sort_custom(MyNoteSorter, "sort_descending")
	
	loudest_note = accum_notes[0][1]
	
	for i in range(0, MULTIPLE_NOTES):
		var real_range = range(i, accum_notes.size())
		
		for j in real_range:
			var abs_result = abs(accum_notes[j][0] - accum_notes[i][0])
			if abs_result == 1 || abs_result == 11:
				accum_notes.remove(j)
				real_range.pop_back()

		if accum_notes[i][1] > accum_notes[0][1] * MULTIPLE_NOTES_VOLUME_SIMILARITY:
			var new_tear = tear.instance()
			new_tear.position = Vector2(60 + accum_notes[i][0] * (WIDTH - 60) / note_values.size(), -40)
			$Holder.add_child(new_tear)


func _on_AudioStreamPlayer2D_finished():
	get_tree().change_scene("res://game/End.tscn")


func _on_droplet_avoided(droplet):
	if GameBus.game_mode == GameBus.GameMode.Grab:
		spawn_point_lost(droplet)
	
	
func _on_droplet_grabbed(droplet):
	if GameBus.game_mode == GameBus.GameMode.Avoid:
		spawn_point_lost(droplet)

var scene_point_lost = load("res://game/PointsLost.tscn")

func spawn_point_lost(droplet):
	var point_lost = scene_point_lost.instance()
	point_lost.position = droplet.position
	get_tree().root.add_child(point_lost)


func _on_Area2D_area_entered(area):
	GameBus.emit_signal("signal_droplet_avoided", area.owner)
	area.owner.die()
