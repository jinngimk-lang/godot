extends Node3D
class_name CrumpleHandStaging

const SUPPORT_MAX_INWARD_OFFSET := 0.085
const PEEL_MAX_INWARD_OFFSET := 0.150
const MAX_DOWN_OFFSET := 0.018

var _support_hand: Node3D
var _peel_hand: Node3D
var _source: CupCrumplePresentation
var _support_home := Vector3.ZERO
var _peel_home := Vector3.ZERO
var _has_support_home := false
var _has_peel_home := false

func _ready() -> void:
	call_deferred("_bind")

func _bind() -> void:
	var parent := get_parent()
	if parent == null:
		return
	_support_hand = parent.get_node_or_null("LeftHand") as Node3D
	_peel_hand = parent.get_node_or_null("RightHand") as Node3D
	_source = parent.get_node_or_null("CupCrumplePresentation") as CupCrumplePresentation
	if _support_hand == null or _source == null:
		return
	_support_home = _support_hand.position
	_has_support_home = true
	if _peel_hand != null:
		_peel_home = _peel_hand.position
		_has_peel_home = true
	if not _source.crumple_changed.is_connected(_on_crumple_changed):
		_source.crumple_changed.connect(_on_crumple_changed)
	_on_crumple_changed(_source.get_progress())

func _on_crumple_changed(progress: float) -> void:
	if not _has_support_home or _support_hand == null:
		return
	var safe_progress := clampf(progress if is_finite(progress) else 0.0, 0.0, 1.0)
	# Smoothstep keeps the first touch calm, then adds visible pressure as the
	# paper shell yields. Only presentation roots move; the independently
	# verified authored skeleton poses remain untouched.
	var eased := safe_progress * safe_progress * (3.0 - 2.0 * safe_progress)
	var support_inward := SUPPORT_MAX_INWARD_OFFSET * eased
	var peel_inward := PEEL_MAX_INWARD_OFFSET * eased
	var down := MAX_DOWN_OFFSET * eased
	_support_hand.position = _support_home + Vector3(-support_inward, -down, 0.0)
	if _has_peel_home and _peel_hand != null:
		_peel_hand.position = _peel_home + Vector3(peel_inward, -down, 0.0)

	# The authored root choreography above establishes the ritual silhouette,
	# but a fixed offset cannot track a deforming paper shell. Once the cup is
	# visibly crumpling, finish each motion by translating the whole hand so its
	# actual rendered pinch anchor lands on the nearest vertex of the current
	# CrumpledCup ArrayMesh. This is a geometry-derived residual, not an IK or
	# parameter search, and it leaves the authored skeleton pose untouched.
	if safe_progress > 0.001:
		_ground_visible_pinch_on_shell(_support_hand)
		if _has_peel_home and _peel_hand != null:
			_ground_visible_pinch_on_shell(_peel_hand)

func _ground_visible_pinch_on_shell(hand: Node3D) -> void:
	if _source == null or not (hand is HandVisual):
		return
	var shell := _source.get_node_or_null("CrumpledCup") as MeshInstance3D
	if shell == null or not shell.visible or not (shell.mesh is ArrayMesh):
		return
	var mesh := shell.mesh as ArrayMesh
	if mesh.get_surface_count() <= 0:
		return
	var arrays := mesh.surface_get_arrays(0)
	var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	if vertices.is_empty():
		return

	var visual := hand as HandVisual
	var pinch_world := visual.get_pinch_world_position()
	var target_world := pinch_world
	var best_distance_squared := INF
	for vertex in vertices:
		var candidate_world := shell.to_global(vertex)
		var distance_squared := candidate_world.distance_squared_to(pinch_world)
		if distance_squared < best_distance_squared:
			best_distance_squared = distance_squared
			target_world = candidate_world
	visual.global_position += target_world - pinch_world

func reset_staging() -> void:
	if _has_support_home and _support_hand != null:
		_support_hand.position = _support_home
	if _has_peel_home and _peel_hand != null:
		_peel_hand.position = _peel_home

func get_home_position() -> Vector3:
	return _support_home
