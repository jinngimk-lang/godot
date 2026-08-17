extends Node3D
class_name CrumpleHandStaging

const MAX_INWARD_OFFSET := 0.085
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
	var inward := MAX_INWARD_OFFSET * eased
	var down := MAX_DOWN_OFFSET * eased
	_support_hand.position = _support_home + Vector3(-inward, -down, 0.0)
	if _has_peel_home and _peel_hand != null:
		_peel_hand.position = _peel_home + Vector3(inward, -down, 0.0)

func reset_staging() -> void:
	if _has_support_home and _support_hand != null:
		_support_hand.position = _support_home
	if _has_peel_home and _peel_hand != null:
		_peel_hand.position = _peel_home

func get_home_position() -> Vector3:
	return _support_home
