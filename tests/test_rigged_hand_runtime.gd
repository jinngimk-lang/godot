extends RefCounted

const HAND_ASSETS := {
	"left": "res://assets/models/hands/hand_left.glb",
	"right": "res://assets/models/hands/hand_right.glb"
}

func run() -> Array[String]:
	var failures: Array[String] = []
	for side in HAND_ASSETS:
		_validate_asset(String(side), String(HAND_ASSETS[side]), failures)

	var hand_script = load("res://scripts/hands/hand_visual.gd")
	if hand_script == null:
		failures.append("HandVisual script did not load for rigged runtime contract")
		return failures

	var right_hand = hand_script.new()
	right_hand.setup(true)
	var rigged_root := right_hand.find_child("RiggedHand", true, false)
	if rigged_root == null:
		failures.append("RED: HandVisual must mount the repository-local rigged hand asset")
	else:
		if _find_skeleton(rigged_root) == null:
			failures.append("mounted RiggedHand must contain Skeleton3D")
		if _find_animation_player(rigged_root) == null:
			failures.append("mounted RiggedHand must contain AnimationPlayer")
	for anchor_name in ["ThumbTip", "IndexTip", "PinchPoint"]:
		if right_hand.find_child(anchor_name, true, false) == null:
			failures.append("rigged HandVisual missing project-owned anchor %s" % anchor_name)
	right_hand.free()
	return failures

func _validate_asset(side: String, path: String, failures: Array[String]) -> void:
	if not ResourceLoader.exists(path):
		failures.append("missing %s rigged hand asset: %s" % [side, path])
		return
	var packed = load(path)
	if not packed is PackedScene:
		failures.append("%s hand asset is not a PackedScene" % side)
		return
	var instance = (packed as PackedScene).instantiate()
	var skeleton := _find_skeleton(instance)
	if skeleton == null:
		failures.append("%s hand asset has no Skeleton3D" % side)
	else:
		for finger_name in ["Thumb", "Index", "Middle", "Ring"]:
			if not _has_tip_bone(skeleton, finger_name, side):
				failures.append("%s hand missing %s fingertip bone" % [side, finger_name])
		if not (_has_tip_bone(skeleton, "Pinky", side) or _has_tip_bone(skeleton, "Little", side)):
			failures.append("%s hand missing fifth fingertip bone" % side)
	var player := _find_animation_player(instance)
	if player == null:
		failures.append("%s hand asset has no AnimationPlayer" % side)
	else:
		for pose_name in ["Cup", "Pinch Tight"]:
			if not player.has_animation(StringName(pose_name)):
				failures.append("%s hand asset missing authored pose %s" % [side, pose_name])
	instance.free()

func _has_tip_bone(skeleton: Skeleton3D, finger_name: String, side: String) -> bool:
	var suffix := "L" if side == "left" else "R"
	return skeleton.find_bone("%s_Tip_%s" % [finger_name, suffix]) >= 0

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
