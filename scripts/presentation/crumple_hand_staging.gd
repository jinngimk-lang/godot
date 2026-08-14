extends Node3D
class_name CrumpleHandStaging

const MAX_INWARD_OFFSET := 0.085
const MAX_DOWN_OFFSET := 0.018

var _support_hand: Node3D
var _source: CupCrumplePresentation
var _home := Vector3.ZERO
var _has_home := false

func _ready() -> void:
	call_deferred("_bind")

func _bind() -> void:
	var parent := get_parent()
	if parent == null:
		return
	_support_hand = parent.get_node_or_null("LeftHand") as Node3D
	_source = parent.get_node_or_null("CupCrumplePresentation") as CupCrumplePresentation
	if _support_hand == null or _source == null:
		return
	_home = _support_hand.position
	_has_home = true
	if not _source.crumple_changed.is_connected(_on_crumple_changed):
		_source.crumple_changed.connect(_on_crumple_changed)
	_on_crumple_changed(_source.get_progress())

func _on_crumple_changed(progress: float) -> void:
	if not _has_home or _support_hand == null:
		return
	var safe_progress := clampf(progress if is_finite(progress) else 0.0, 0.0, 1.0)
	# Smoothstep keeps the first touch calm, then adds visible pressure as the
	# paper shell yields. This moves only the root presentation transform; the
	# independently verified authored skeleton/pose remains untouched.
	var eased := safe_progress * safe_progress * (3.0 - 2.0 * safe_progress)
	_support_hand.position = _home + Vector3(-MAX_INWARD_OFFSET * eased, -MAX_DOWN_OFFSET * eased, 0.0)

func reset_staging() -> void:
	_on_crumple_changed(0.0)

func get_home_position() -> Vector3:
	return _home
