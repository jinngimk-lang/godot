extends AudioStreamPlayer
class_name PeelAudio

var _generator := AudioStreamGenerator.new()
var _playback
var _phase := 0.0
var _target_intensity := 0.0
var _intensity := 0.0
var _tone_hz := 420.0
var _pop_time := 0.0

func _ready() -> void:
	_generator.mix_rate = 22050.0
	_generator.buffer_length = 0.18
	stream = _generator
	volume_db = -16.0
	play()
	_playback = get_stream_playback()

func set_peel_feedback(speed: float, tension: float, released: float) -> void:
	var safe_speed := clampf(speed, 0.0, 30.0)
	var safe_tension := clampf(tension, 0.0, 80.0)
	_target_intensity = clampf(0.04 + released * 9.0 + safe_tension / 180.0, 0.0, 0.65)
	_tone_hz = 300.0 + safe_speed * 38.0 + safe_tension * 3.2

func quiet() -> void:
	_target_intensity = 0.0

func trigger_release_tick() -> void:
	_pop_time = maxf(_pop_time, 0.035)

func trigger_completion() -> void:
	_pop_time = 0.16

func _process(delta: float) -> void:
	_intensity = move_toward(_intensity, _target_intensity, delta * 2.8)
	_pop_time = maxf(_pop_time - delta, 0.0)
	if _playback == null:
		return
	var frames: int = _playback.get_frames_available()
	var rate := _generator.mix_rate
	for _i in range(frames):
		_phase = fmod(_phase + TAU * _tone_hz / rate, TAU)
		var paper_noise := randf_range(-1.0, 1.0) * _intensity * 0.28
		var adhesive := sin(_phase) * _intensity * 0.11
		var pop := 0.0
		if _pop_time > 0.0:
			pop = sin(_phase * 0.43) * clampf(_pop_time / 0.16, 0.0, 1.0) * 0.55
		var sample := clampf(paper_noise + adhesive + pop, -0.82, 0.82)
		_playback.push_frame(Vector2(sample, sample))
