extends Node2D

export var tear : PackedScene

const FREQ_OFFSET = 0.1
const NOTES_WINDOW_SIZE  = 5

const MULTIPLE_NOTES = 1
const MULTIPLE_NOTES_VOLUME_SIMILARITY = 0.9

const BASE_OCTAVE = 3
const NUM_OCTAVES = 3

const NOTES_IN_OCTAVE = 12
const A_BASE = 55 * pow(2, BASE_OCTAVE - 1)
const A = 1.059463094359
const TOTAL_NOTES = NOTES_IN_OCTAVE * NUM_OCTAVES

const WIDTH = 640
const HEIGHT = 480

var spectrum : AudioEffectInstance
var dynamic_font : DynamicFont

var prev_note_values = []
var note_values = []

var notes_window = []

var loudest_note_str = ""
var loudest_note = 0
var loudest_note_idx = 0

const MIN_DB = 60


class MyNoteSorter:
	static func sort_descending(a, b):
		return a[1] > b[1]

func _ready() -> void:
	spectrum = AudioServer.get_bus_effect_instance(0, 0)
	
	dynamic_font = DynamicFont.new()
	dynamic_font.font_data = load("res://pixelmix.ttf")
	dynamic_font.size = 32


func _process(delta) -> void:
	_update_notes()
	_spawn_tears()
	
	update()


func _update_notes() -> void:
	prev_note_values = note_values
	note_values = []
	
	for i in range(0, NOTES_IN_OCTAVE):
		note_values.push_back([0,0])

	var string = ""
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
	for i in range(0, NOTES_IN_OCTAVE):
		accum_notes.push_back([0,0])
		
	for window_idx in range(0, NOTES_WINDOW_SIZE):
		var notes = notes_window[window_idx]
		
		for i in range(0, notes.size()):
			accum_notes[i][0] = notes[i][0]
			accum_notes[i][1] += notes[i][1]
			
	notes_window = []
	
	accum_notes.sort_custom(MyNoteSorter, "sort_descending")
	
	for i in range(0, MULTIPLE_NOTES):
		var real_range = range(i, accum_notes.size())
		
		for j in real_range:
			var abs_result = abs(accum_notes[j][0] - accum_notes[i][0])
			if abs_result == 1 || abs_result == 11:
				accum_notes.remove(j)
				real_range.pop_back()

		loudest_note_idx = accum_notes[i][0]
		loudest_note = accum_notes[i][1]
		
		if loudest_note > accum_notes[0][1] * MULTIPLE_NOTES_VOLUME_SIMILARITY:
			var new_tear = tear.instance()
			new_tear.position = Vector2(loudest_note_idx * WIDTH / note_values.size(), 0)
			add_child(new_tear)


func _draw() -> void:
	if not note_values:
		return
		
	var w = WIDTH / NOTES_IN_OCTAVE
		
	for i in range(0, NOTES_IN_OCTAVE):
		var note = _get_note_string(i)
		draw_string(dynamic_font, Vector2(25+50*i, 32), note, Color.white)
		var energy = note_values[i][1]
		var height = energy*HEIGHT
		draw_rect(Rect2(w * i, HEIGHT - height, w, height), Color.white)


func _get_note_string(index) -> String:
	var notes = ["A", "A#", "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#"]
	
	var note = notes[index % notes.size()]
	var octave = index / notes.size() + BASE_OCTAVE
	return note # + String(octave)
