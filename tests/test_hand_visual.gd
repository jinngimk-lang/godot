extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var hand_path := "res://scripts/hands/hand_visual.gd"
	var hand_script = load(hand_path)
	if hand_script == null:
		failures.append("HandVisual script did not load")
		return failures

	var method_names: Array[String] = []
	for method in hand_script.get_script_method_list():
		method_names.append(String(method.get("name", "")))
	for required in ["set_grip_target", "set_pinch_amount", "get_finger_count", "snap_to", "tick"]:
		if not method_names.has(required):
			failures.append("RED: HandVisual missing semi-realistic contract method %s" % required)
	if not failures.is_empty():
		return failures

	var hand = hand_script.new()
	hand.setup(true)
	if hand.get_finger_count() != 5:
		failures.append("HandVisual must expose five fingers")
	for required_node in ["ThumbTip", "IndexTip", "PinchPoint"]:
		if hand.find_child(required_node, true, false) == null:
			failures.append("HandVisual missing pinch anchor %s" % required_node)

	# Owner playtest showed the fully open dynamic rest pose reads as a deformed
	# two-finger claw in the game camera. The authored Pinch Up pose keeps the
	# hand relaxed while visually preparing thumb/index around the peel edge.
	var dynamic_player := _find_animation_player(hand)
	if dynamic_player == null:
		failures.append("authored dynamic hand must expose AnimationPlayer")
	elif dynamic_player.current_animation != "Pinch Up":
		failures.append("RED: relaxed dynamic authored hand must use Pinch Up, got %s" % dynamic_player.current_animation)

	# Real-render diagnostics proved the authored GLBs end directly at their
	# root Wrist_L/Wrist_R plane. Normal close-up presentation must therefore
	# cover that open wrist end instead of exposing a cropped skin cylinder.
	var sleeve := hand.find_child("WristSleeve", true, false) as MeshInstance3D
	var cuff := hand.find_child("WristCuff", true, false) as MeshInstance3D
	if sleeve == null:
		failures.append("RED: authored hand must cover the open wrist with WristSleeve")
	elif sleeve.mesh == null or sleeve.material_override == null:
		failures.append("WristSleeve must have visible mesh and fabric material")
	elif sleeve.material_override.resource_name != "SleeveFabric":
		failures.append("WristSleeve must use semantic SleeveFabric material")
	if cuff == null:
		failures.append("RED: authored hand must finish the wrist cover with WristCuff")
	elif cuff.mesh == null or cuff.material_override == null:
		failures.append("WristCuff must have visible mesh and cuff material")
	elif cuff.material_override.resource_name != "SleeveRib":
		failures.append("WristCuff must use semantic SleeveRib material")

	hand.set_pinch_amount(1.0)
	hand.set_grip_target(Vector3(1.0, 0.5, 0.8))
	hand.tick(0.1)
	if dynamic_player != null and dynamic_player.current_animation != "Pinch Tight":
		failures.append("active authored hand must close to Pinch Tight")
	hand.free()

	# The upstream Cup pose has strong multi-finger flexion and owner playtest
	# shows it reading as twisted anatomy from the current support-hand camera
	# angle. A neutral open hand pressed to the cup reads as calm support without
	# skin collapse; cup holding is conveyed by placement/forearm direction.
	var support = hand_script.new()
	support.setup(false)
	var support_player := _find_animation_player(support)
	if support_player == null:
		failures.append("authored support hand must expose AnimationPlayer")
	elif support_player.current_animation != "Default pose":
		failures.append("RED: authored support hand must use neutral Default pose, got %s" % support_player.current_animation)
	support.free()
	return failures

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null
