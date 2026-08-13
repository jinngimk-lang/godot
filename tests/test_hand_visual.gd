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
	hand.tick(0.016)
	hand.free()
	return failures
