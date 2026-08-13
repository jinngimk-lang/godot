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

	hand.set_pinch_amount(1.0)
	hand.set_grip_target(Vector3(1.0, 0.5, 0.8))
	hand.tick(0.016)
	hand.free()
	return failures
