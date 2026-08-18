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
	for required in ["set_grip_target", "set_pinch_amount", "get_finger_count", "snap_to", "tick", "is_using_realtime_shell", "get_realtime_shell_vertex_count"]:
		if not method_names.has(required):
			failures.append("RED: HandVisual missing realtime hand contract method %s" % required)
	if not failures.is_empty():
		return failures

	var hand = hand_script.new()
	hand.setup(true)
	if hand.get_finger_count() != 5:
		failures.append("HandVisual must expose five fingers")
	for required_node in ["ThumbTip", "IndexTip", "PinchPoint"]:
		if hand.find_child(required_node, true, false) == null:
			failures.append("HandVisual missing pinch anchor %s" % required_node)

	var relaxed_pose := String(hand.get("_last_authored_pose"))
	if relaxed_pose != "Pinch Up":
		failures.append("RED: relaxed dynamic authored hand must use Pinch Up, got %s" % relaxed_pose)
	if not hand.is_using_realtime_shell():
		failures.append("RED: dynamic hand must render the dense realtime presentation shell")
	elif hand.get_realtime_shell_vertex_count() < 20000:
		failures.append("RED: realtime dynamic hand shell is still too low density (%d vertices)" % hand.get_realtime_shell_vertex_count())

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
	var active_pose := String(hand.get("_last_authored_pose"))
	if active_pose != "Pinch Tight":
		failures.append("active authored hand must close to Pinch Tight, got %s" % active_pose)
	hand.free()

	var support = hand_script.new()
	support.setup(false)
	var support_pose := String(support.get("_last_authored_pose"))
	if support_pose != "Cup":
		failures.append("RED: authored support hand must use vessel-wrapping Cup pose, got %s" % support_pose)
	if not support.is_using_realtime_shell():
		failures.append("RED: support hand must render the dense realtime presentation shell")
	elif support.get_realtime_shell_vertex_count() < 20000:
		failures.append("RED: realtime support hand shell is still too low density (%d vertices)" % support.get_realtime_shell_vertex_count())
	support.free()
	return failures
