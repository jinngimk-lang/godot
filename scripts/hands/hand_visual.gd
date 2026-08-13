extends Node3D
class_name HandVisual

const LEFT_HAND_ASSET := "res://assets/models/hands/hand_left.glb"
const RIGHT_HAND_ASSET := "res://assets/models/hands/hand_right.glb"
const PRESENTATION_SCALE := 2.35

var follow_rate := 11.0
var _target := Vector3.ZERO
var _dynamic := false
var _is_right_hand := false
var _pinch_amount := 0.0
var _model_root: Node3D
var _skeleton: Skeleton3D
var _animation_player: AnimationPlayer
var _thumb_tip: Marker3D
var _index_tip: Marker3D
var _pinch_point: Marker3D

func setup(dynamic_hand: bool, handedness: int = -1) -> void:
	_dynamic = dynamic_hand
	_is_right_hand = dynamic_hand if handedness < 0 else handedness > 0
	_clear_presentation()
	_build_rigged_presentation()
	_build_pinch_anchors()
	if _dynamic:
		set_pinch_amount(1.0)
	else:
		_apply_pose("Cup", 0.0)
	_update_pinch_anchors()

func set_target(target: Vector3) -> void:
	set_grip_target(target)

func set_grip_target(target: Vector3) -> void:
	_target = target

func set_pinch_amount(amount: float) -> void:
	_pinch_amount = clampf(amount, 0.0, 1.0)
	if _pinch_amount >= 0.55:
		_apply_pose("Pinch Tight", 0.08)
	elif _pinch_amount <= 0.15:
		_apply_pose("Default pose", 0.08)

func get_finger_count() -> int:
	if _skeleton == null:
		return 0
	var count := 0
	for finger_name in ["Thumb", "Index", "Middle", "Ring", "Little"]:
		if _skeleton.find_bone(_tip_bone_name(finger_name)) >= 0:
			count += 1
	return count

func snap_to(target: Vector3) -> void:
	_target = target
	position = target
	_update_pinch_anchors()

func tick(delta: float) -> void:
	if _dynamic:
		var weight := 1.0 - exp(-follow_rate * clampf(delta, 0.0, 0.1))
		position = position.lerp(_target, weight)
	_update_pinch_anchors()

func has_rigged_asset() -> bool:
	return _model_root != null and _skeleton != null and get_finger_count() == 5

func get_available_poses() -> PackedStringArray:
	if _animation_player == null:
		return PackedStringArray()
	return _animation_player.get_animation_list()

func _clear_presentation() -> void:
	for child in get_children():
		child.free()
	_model_root = null
	_skeleton = null
	_animation_player = null
	_thumb_tip = null
	_index_tip = null
	_pinch_point = null

func _build_rigged_presentation() -> void:
	var asset_path := RIGHT_HAND_ASSET if _is_right_hand else LEFT_HAND_ASSET
	if not ResourceLoader.exists(asset_path):
		push_error("HandVisual missing rigged hand asset: %s" % asset_path)
		return
	var packed = load(asset_path)
	if not packed is PackedScene:
		push_error("HandVisual expected PackedScene hand asset: %s" % asset_path)
		return
	_model_root = (packed as PackedScene).instantiate() as Node3D
	if _model_root == null:
		push_error("HandVisual failed to instantiate hand asset: %s" % asset_path)
		return
	_model_root.name = "RiggedHand"
	_model_root.scale = Vector3.ONE * PRESENTATION_SCALE
	add_child(_model_root)
	_skeleton = _find_skeleton(_model_root)
	_animation_player = _find_animation_player(_model_root)
	if _skeleton == null:
		push_error("HandVisual hand asset has no Skeleton3D: %s" % asset_path)

func _build_pinch_anchors() -> void:
	_thumb_tip = Marker3D.new()
	_thumb_tip.name = "ThumbTip"
	add_child(_thumb_tip)
	_index_tip = Marker3D.new()
	_index_tip.name = "IndexTip"
	add_child(_index_tip)
	_pinch_point = Marker3D.new()
	_pinch_point.name = "PinchPoint"
	add_child(_pinch_point)

func _update_pinch_anchors() -> void:
	if _skeleton == null or _thumb_tip == null or _index_tip == null or _pinch_point == null:
		return
	var thumb_position: Variant = _bone_position(_tip_bone_name("Thumb"))
	var index_position: Variant = _bone_position(_tip_bone_name("Index"))
	if thumb_position != null:
		_thumb_tip.position = thumb_position as Vector3
	if index_position != null:
		_index_tip.position = index_position as Vector3
	_pinch_point.position = (_thumb_tip.position + _index_tip.position) * 0.5

func _bone_position(bone_name: String) -> Variant:
	if _skeleton == null:
		return null
	var bone_index := _skeleton.find_bone(bone_name)
	if bone_index < 0:
		return null
	var pose := _skeleton.get_bone_global_pose(bone_index)
	return to_local(_skeleton.to_global(pose.origin))

func _apply_pose(pose_name: String, blend_time: float) -> void:
	if _animation_player == null:
		return
	var animation := StringName(pose_name)
	if not _animation_player.has_animation(animation):
		return
	_animation_player.play(animation, blend_time, 0.0)
	_animation_player.seek(0.0, true)

func _tip_bone_name(finger_name: String) -> String:
	return "%s_Tip_%s" % [finger_name, "R" if _is_right_hand else "L"]

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null
