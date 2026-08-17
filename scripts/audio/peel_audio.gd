extends Node
class_name PeelAudio

signal crumple_pulse_played(strength: float)

const SLOW_PATH := "res://assets/audio/peel/adhesive_slow.wav"
const FAST_PATH := "res://assets/audio/peel/adhesive_fast.wav"
const PAPER_PATH := "res://assets/audio/peel/paper_flex.wav"
const MICRO_PATH := "res://assets/audio/peel/micro_release.wav"
const FINAL_PATH := "res://assets/audio/peel/final_release.wav"

var _router := PeelFoleyRouter.new()
var _slow: AudioStreamPlayer
var _fast: AudioStreamPlayer
var _paper: AudioStreamPlayer
var _micro: AudioStreamPlayer
var _final: AudioStreamPlayer
var _slow_target_db := -80.0
var _fast_target_db := -80.0

func _ready() -> void:
	_slow = _make_player("AdhesiveSlow", SLOW_PATH, -80.0)
	_fast = _make_player("AdhesiveFast", FAST_PATH, -80.0)
	_paper = _make_player("PaperFlex", PAPER_PATH, -22.0)
	_micro = _make_player("MicroRelease", MICRO_PATH, -16.0)
	_final = _make_player("FinalRelease", FINAL_PATH, -10.0)
	_router.reset()

func get_continuous_mix_targets(active: bool, speed: float, tension: float) -> Vector2:
	if not active:
		return Vector2(-80.0,-80.0)
	var safe_speed := clampf(speed if is_finite(speed) else 0.0,0.0,30.0)
	var safe_tension := clampf(tension if is_finite(tension) else 0.0,0.0,80.0)
	var speed_mix := clampf(safe_speed/9.0,0.0,1.0)
	# Continuous adhesive friction is environmental texture, not foreground music.
	# Tension adds only a small lift; release transients remain the foreground.
	var tension_lift := clampf(safe_tension/80.0,0.0,1.0)*2.0
	var slow_db := lerpf(-24.0+tension_lift,-39.0,speed_mix)
	var fast_db := lerpf(-39.0,-23.0+tension_lift,speed_mix)
	return Vector2(slow_db,fast_db)

func set_feedback(
	active: bool,
	speed: float,
	tension: float,
	released: float,
	detached_now: bool,
	delta: float
) -> void:
	var safe_speed := clampf(speed if is_finite(speed) else 0.0,0.0,30.0)
	var safe_tension := clampf(tension if is_finite(tension) else 0.0,0.0,80.0)
	var targets := get_continuous_mix_targets(active,safe_speed,safe_tension)
	_slow_target_db = targets.x
	_fast_target_db = targets.y

	for event_name in _router.update(active,safe_speed,safe_tension,released,detached_now,delta):
		match event_name:
			"paper_flex":
				_play_one_shot(_paper,0.94,1.06,-3.0,2.0)
			"micro_release":
				_play_one_shot(_micro,0.92,1.10,-2.0,2.0)
			"final_release":
				_play_one_shot(_final,0.97,1.04,-1.0,1.0)

func trigger_crumple(strength: float) -> void:
	var safe_strength := clampf(strength if is_finite(strength) else 0.0,0.0,1.0)
	if safe_strength <= 0.0 or _paper == null or _paper.stream == null:
		return
	_paper.pitch_scale = randf_range(0.78,0.92)+safe_strength*0.06
	_paper.volume_db = lerpf(-28.0,-20.0,safe_strength)+randf_range(-1.2,1.2)
	_paper.play()
	crumple_pulse_played.emit(safe_strength)

func reset_feedback() -> void:
	_router.reset()
	_slow_target_db = -80.0
	_fast_target_db = -80.0
	_stop_if_valid(_slow)
	_stop_if_valid(_fast)
	_stop_if_valid(_paper)
	_stop_if_valid(_micro)
	_stop_if_valid(_final)

func set_peel_feedback(speed: float, tension: float, released: float) -> void:
	set_feedback(true,speed,tension,released,false,get_process_delta_time())

func quiet() -> void:
	_slow_target_db = -80.0
	_fast_target_db = -80.0

func trigger_release_tick() -> void:
	if _micro != null:
		_play_one_shot(_micro,0.92,1.10,-2.0,2.0)

func trigger_completion() -> void:
	if _final != null:
		_play_one_shot(_final,0.97,1.04,-1.0,1.0)

func _process(delta: float) -> void:
	if _slow == null or _fast == null:
		return
	var safe_delta := clampf(delta,0.0,0.1)
	_slow.volume_db = move_toward(_slow.volume_db,_slow_target_db,safe_delta*70.0)
	_fast.volume_db = move_toward(_fast.volume_db,_fast_target_db,safe_delta*70.0)
	_update_loop_player(_slow,_slow_target_db)
	_update_loop_player(_fast,_fast_target_db)

func _make_player(node_name: String, resource_path: String, initial_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = node_name
	player.volume_db = initial_db
	player.stream = load(resource_path)
	add_child(player)
	return player

func _update_loop_player(player: AudioStreamPlayer, target_db: float) -> void:
	if target_db > -55.0:
		if not player.playing:
			player.play()
	elif player.playing and player.volume_db <= -55.0:
		player.stop()

func _play_one_shot(
	player: AudioStreamPlayer,
	pitch_min: float,
	pitch_max: float,
	volume_jitter_min: float,
	volume_jitter_max: float
) -> void:
	if player == null or player.stream == null:
		return
	player.pitch_scale = randf_range(pitch_min,pitch_max)
	var base_db := -18.0
	if player == _paper:
		base_db = -23.0
	elif player == _micro:
		base_db = -17.0
	elif player == _final:
		base_db = -10.0
	player.volume_db = base_db+randf_range(volume_jitter_min,volume_jitter_max)
	player.play()

func _stop_if_valid(player: AudioStreamPlayer) -> void:
	if player != null and player.playing:
		player.stop()
