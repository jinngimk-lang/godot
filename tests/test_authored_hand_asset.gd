extends RefCounted

const RIGHT_PATH := "res://assets/models/hands/hand_right.glb"
const LEFT_PATH := "res://assets/models/hands/hand_left.glb"

func run() -> Array[String]:
	var failures: Array[String] = []
	for path in [LEFT_PATH, RIGHT_PATH]:
		if not ResourceLoader.exists(path):
			failures.append("authored hand GLB missing: %s" % path)
			continue
		var packed = load(path)
		if packed == null or not (packed is PackedScene):
			failures.append("authored hand GLB did not import as PackedScene: %s" % path)
			continue
		var instance = packed.instantiate()
		if _find_first(instance, "Skeleton3D") == null:
			failures.append("authored hand must contain Skeleton3D: %s" % path)
		var animation_player = _find_first(instance, "AnimationPlayer")
		if animation_player == null:
			failures.append("authored hand must contain AnimationPlayer: %s" % path)
		else:
			var names: PackedStringArray = animation_player.get_animation_list()
			if not names.has("Pinch Tight"):
				failures.append("authored hand missing Pinch Tight animation: %s" % path)
			if not names.has("Cup"):
				failures.append("authored hand missing Cup animation: %s" % path)
		instance.free()

	var hand_script = load("res://scripts/hands/hand_visual.gd")
	if hand_script == null:
		failures.append("HandVisual script did not load")
		return failures
	var methods: Array[String] = []
	for method in hand_script.get_script_method_list():
		methods.append(String(method.get("name", "")))
	if not methods.has("is_using_authored_asset"):
		failures.append("RED: HandVisual does not expose authored-hand runtime contract")
		return failures

	var hand = hand_script.new()
	hand.setup(true)
	if not hand.is_using_authored_asset():
		failures.append("HandVisual should prefer repository-local authored GLB")
	hand.free()
	return failures

func _find_first(node: Node, class_name_text: String) -> Node:
	if node.get_class() == class_name_text:
		return node
	for child in node.get_children():
		var found := _find_first(child, class_name_text)
		if found != null:
			return found
	return null
