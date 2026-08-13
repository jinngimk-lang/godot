extends Node3D
class_name HandVisual

const LEFT_HAND_ASSET := "res://assets/models/hands/hand_left.glb"
const RIGHT_HAND_ASSET := "res://assets/models/hands/hand_right.glb"
const PRESENTATION_SCALE := 2.35
const EXPECTED_FINGER_COUNT := 5

var follow_rate := 11.0
var pinch_follow_rate := 16.0

var _target := Vector3.ZERO
var _dynamic := false
var _is_right_hand := false
var _pinch_target := 0.0
var _pinch_amount := 0.0
var _setup_called := false
var _anchors_built := false
var _active_pose := ""

var _model_root: Node3D
var _skeleton: Skeleton3D
var _animation_player: AnimationPlayer
var _thumb_tip: Marker3D
var _index_tip: Marker3D
var _pinch_point: Marker3D

func _ready() -> void:
	if _setup_called:
		_ensure_rigged_presentation()
		_sync_pose(true)
		_update_pinch_anchors()

func setup(dynamic_hand: bool) -> void:
	_dynamic = dynamic_hand
	_is_right_hand = dynamic_hand
	_setup_called = true
	_pinch_target = 0.18 if dynamic_hand else 0.42
	_pinch_amount = _pinch_target
	_ensure_pinch_anchors()
	if is_inside_tree():
		_ensure_rigged_presentation()
		_sync_pose(true)
		_update_pinch_anchors()

# Target is the world-space point that thumb and index should pinch around.
func set_grip_target(target: Vector3) -> void:
	_target = target

func set_target(target: Vector3) -> void:
	set_grip_target(target)

func set_pinch_amount(amount: float) -> void:
	_pinch_target = clampf(amount if is_finite(amount) else 0.0, 0.0, 1.0)

func get_finger_count() -> int:
	if _skeleton == null:
		return EXPECTED_FINGER_COUNT
	var count := 0
	for finger_name in ["Thumb", "Index", "Middle", "Ring"]:
		if _find_tip_bone(finger_name) >= 0:
			count += 1
	if _find_tip_bone("Pinky") >= 0 or _find_tip_bone("Little") >= 0:
		count += 1
	return count

# Explicitly exposes the presentation backend so tests/callers need not infer it from child meshes.
func is_using_authored_asset() -> bool:
	var asset_path: String = RIGHT_HAND_ASSET if _is_right_hand else LEFT_HAND_ASSET
	return _model_root != null or ResourceLoader.exists(asset_path)

func get_pinch_world_position() -> Vector3:
	if _pinch_point == null:
		return global_position
	return to_global(_pinch_point.position)

# Snap keeps legacy root-position semantics for initial scene placement.
func snap_to(target: Vector3) -> void:
	position = target
	_update_pinch_anchors()
	if _pinch_point != null:
		_target = to_global(_pinch_point.position)
	else:
		_target = target

func tick(delta: float) -> void:
	var safe_delta := clampf(delta if is_finite(delta) else 0.0, 0.0, 0.1)
	var pinch_weight := 1.0 - exp(-pinch_follow_rate * safe_delta)
	_pinch_amount = lerpf(_pinch_amount, _pinch_target, pinch_weight)
	if is_inside_tree():
		_ensure_rigged_presentation()
		_sync_pose(false)
	_update_pinch_anchors()
	if _dynamic:
		var desired_root := _target
		if _pinch_point != null:
			desired_root = _target - basis * _pinch_point.position
		var position_weight := 1.0 - exp(-follow_rate * safe_delta)
		position = position.lerp(desired_root, position_weight)

func has_rigged_asset() -> bool:
	return _model_root != null and _skeleton != null and get_finger_count() == EXPECTED_FINGER_COUNT

func get_available_poses() -> PackedStringArray:
	if _animation_player == null:
		return PackedStringArray()
	return _animation_player.get_animation_list()

func _ensure_pinch_anchors() -> void:
	if _anchors_built:
		return
	_anchors_built = true
	_thumb_tip = Marker3D.new()
	_thumb_tip.name = "ThumbTip"
	add_child(_thumb_tip)
	_index_tip = Marker3D.new()
	_index_tip.name = "IndexTip"
	add_child(_index_tip)
	_pinch_point = Marker3D.new()
	_pinch_point.name = "PinchPoint"
	add_child(_pinch_point)

func _ensure_rigged_presentation() -> void:
	if _model_root != null:
		return
	_ensure_pinch_anchors()
	var asset_path: String = RIGHT_HAND_ASSET if _is_right_hand else LEFT_HAND_ASSET
	if not ResourceLoader.exists(asset_path):
		push_error("HandVisual missing rigged hand asset: %s" % asset_path)
		return
	var packed: PackedScene = load(asset_path) as PackedScene
	if packed == null:
		push_error("HandVisual expected PackedScene hand asset: %s" % asset_path)
		return
	_model_root = packed.instantiate() as Node3D
	if _model_root == null:
		push_error("HandVisual failed to instantiate hand asset: %s" % asset_path)
		return
	_model_root.name = "RiggedHand"
	_model_root.scale = Vector3.ONE * PRESENTATION_SCALE
	add_child(_model_root)
	_skeleton = _find_skeleton(_model_root)
	_animation_player = _find_animation_player(_model_root)
	if _skeleton == null:
		push_error("HandVisual rigged hand has no Skeleton3D: %s" % asset_path)
	if _animation_player == null:
		push_error("HandVisual rigged hand has no AnimationPlayer: %s" % asset_path)

func _sync_pose(force: bool) -> void:
	if _animation_player == null:
		return
	var desired_pose := "Cup" if not _dynamic else _pose_for_pinch(_pinch_amount)
	if not force and desired_pose == _active_pose:
		return
	if not _animation_player.has_animation(StringName(desired_pose)):
		push_error("HandVisual missing authored pose: %s" % desired_pose)
		return
	_active_pose = desired_pose
	_animation_player.play(StringName(desired_pose))
	_animation_player.seek(0.0, true)
	_animation_player.pause()

func _pose_for_pinch(amount: float) -> String:
	if amount >= 0.70:
		return "Pinch Tight"
	if amount >= 0.38 and _animation_player != null and _animation_player.has_animation(&"Pinch Up"):
		return "Pinch Up"
	return "Default pose"

func _update_pinch_anchors() -> void:
	if _skeleton == null or _thumb_tip == null or _index_tip == null or _pinch_point == null:
		return
	var thumb_index: int = _find_tip_bone("Thumb")
	var index_index: int = _find_tip_bone("Index")
	if thumb_index < 0 or index_index < 0:
		return
	_thumb_tip.position = _bone_position_in_hand(thumb_index)
	_index_tip.position = _bone_position_in_hand(index_index)
	_pinch_point.position = (_thumb_tip.position + _index_tip.position) * 0.5

func _bone_position_in_hand(bone_index: int) -> Vector3:
	var pose: Transform3D = _skeleton.get_bone_global_pose(bone_index)
	return to_local(_skeleton.to_global(pose.origin))

func _find_tip_bone(finger_name: String) -> int:
	if _skeleton == null:
		return -1
	var suffix := "R" if _is_right_hand else "L"
	return _skeleton.find_bone("%s_Tip_%s" % [finger_name, suffix])

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found: Skeleton3D = _find_skeleton(child)
		if found != null:
			return found
	return null

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found: AnimationPlayer = _find_animation_player(child)
		if found != null:
			return found
	return null
