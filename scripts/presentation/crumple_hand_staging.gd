extends Node3D
class_name CrumpleHandStaging

# Crumple is a two-hand tactile ritual. Once the shell begins deforming, both
# hands should reach the actual rendered shell instead of hovering beside a cup
# that appears to crumple by itself. Contact is derived from the current shell
# vertices, not from a pose/angle search.
const CONTACT_SETTLE_PROGRESS := 0.22

var _support_hand: HandVisual
var _peel_hand: HandVisual
var _source: CupCrumplePresentation
var _support_home := Vector3.ZERO
var _peel_home := Vector3.ZERO
var _has_home := false
var _active := false
var _support_entry_global := Vector3.ZERO
var _peel_entry_global := Vector3.ZERO
var _support_entry_pinch := Vector3.ZERO
var _peel_entry_pinch := Vector3.ZERO
var _support_last_contact_world := Vector3(INF, INF, INF)
var _peel_last_contact_world := Vector3(INF, INF, INF)
var _last_contact_weight := 0.0
var _bind_count := 0
var _changed_count := 0
var _activation_count := 0
var _progress_trace: Array[float] = []

func _ready() -> void:
	process_priority = 100
	call_deferred("_bind")

func _process(_delta: float) -> void:
	if _active and _source != null:
		_apply_contact(_source.get_progress())

func _bind() -> void:
	_bind_count += 1
	var parent := get_parent()
	if parent == null:
		return
	_support_hand = parent.get_node_or_null("LeftHand") as HandVisual
	_peel_hand = parent.get_node_or_null("RightHand") as HandVisual
	_source = parent.get_node_or_null("CupCrumplePresentation") as CupCrumplePresentation
	if _support_hand == null or _peel_hand == null or _source == null:
		return
	_support_home = _support_hand.position
	_peel_home = _peel_hand.position
	_has_home = true
	if not _source.crumple_changed.is_connected(_on_crumple_changed):
		_source.crumple_changed.connect(_on_crumple_changed)
	_on_crumple_changed(_source.get_progress())

func _on_crumple_changed(progress: float) -> void:
	_changed_count += 1
	_progress_trace.append(progress)
	if not _has_home or _support_hand == null or _peel_hand == null:
		return
	var safe_progress := clampf(progress if is_finite(progress) else 0.0, 0.0, 1.0)
	if safe_progress <= 0.001:
		_active = false
		_support_hand.position = _support_home
		_peel_hand.position = _peel_home
		return
	if not _active:
		_activation_count += 1
		_active = true
		_support_entry_global = _support_hand.global_position
		_peel_entry_global = _peel_hand.global_position
		_support_entry_pinch = _support_hand.get_pinch_world_position()
		_peel_entry_pinch = _peel_hand.get_pinch_world_position()
	_apply_contact(safe_progress)

func _apply_contact(progress: float) -> void:
	if not _active or _source == null or _support_hand == null or _peel_hand == null:
		return
	var shell := _source.get_node_or_null("CrumpledCup") as MeshInstance3D
	if shell == null or shell.mesh == null or shell.mesh.get_surface_count() == 0:
		return
	var t := clampf(progress / CONTACT_SETTLE_PROGRESS, 0.0, 1.0)
	var contact_weight := t * t * (3.0 - 2.0 * t)
	_last_contact_weight = contact_weight
	_support_last_contact_world = _stage_hand(_support_hand, _support_entry_global, _support_entry_pinch, shell, contact_weight)
	_peel_last_contact_world = _stage_hand(_peel_hand, _peel_entry_global, _peel_entry_pinch, shell, contact_weight)

func _stage_hand(hand: HandVisual, entry_global: Vector3, entry_pinch: Vector3, shell: MeshInstance3D, weight: float) -> Vector3:
	var contact_world := _closest_shell_point(shell, entry_pinch)
	if not contact_world.is_finite():
		return contact_world
	var target_root := entry_global + (contact_world - entry_pinch)
	hand.global_position = entry_global.lerp(target_root, weight)
	return contact_world

func _closest_shell_point(shell: MeshInstance3D, reference_world: Vector3) -> Vector3:
	var arrays := shell.mesh.surface_get_arrays(0)
	var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	if vertices.is_empty():
		return Vector3(INF, INF, INF)
	var best_world := shell.to_global(vertices[0])
	var best_distance := reference_world.distance_squared_to(best_world)
	for vertex in vertices:
		var world := shell.to_global(vertex)
		var distance := reference_world.distance_squared_to(world)
		if distance < best_distance:
			best_distance = distance
			best_world = world
	return best_world

func reset_staging() -> void:
	_on_crumple_changed(0.0)

func get_home_position() -> Vector3:
	return _support_home