extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var path := "res://scripts/presentation/guided_journey_presentation.gd"
	if not ResourceLoader.exists(path):
		failures.append("GUIDE_RED: missing guided multi-scene journey presentation")
		return failures
	var script = load(path)
	if script == null:
		failures.append("GUIDE_RED: guided journey script failed to load")
		return failures

	var methods: Array[String] = []
	for method in script.get_script_method_list():
		methods.append(String(method.get("name", "")))
	for required_method in ["set_state", "set_inspection_active", "get_active_scene_index", "get_action_text"]:
		if not methods.has(required_method):
			failures.append("GUIDE_RED: journey presentation missing %s" % required_method)
	if not failures.is_empty():
		return failures

	var root := Node.new()
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	root.add_child(layer)
	var reward := Label.new()
	reward.name = "Reward"
	reward.text = "CLEAN RELEASE\nnext scene unlocked\noptional squeeze • continue when ready"
	layer.add_child(reward)
	var continue_button := Button.new()
	continue_button.name = "Continue"
	continue_button.text = "Continue to Bar"
	layer.add_child(continue_button)
	var guide = script.new()
	root.add_child(guide)
	guide._process(0.0)

	var rail := layer.get_node_or_null("JourneyRail") as Control
	if rail == null:
		failures.append("GUIDE_RED: HUD must expose the pointer/touch JourneyRail")
		root.free()
		return failures
	if layer.get_node_or_null("JourneyGuide") != null:
		failures.append("GUIDE_RED: guided journey must not render a second persistent top-left scene/action panel beside the compact reference HUD")

	var expected_names: Array[String] = ["WINDOW CAFÉ", "AMBER BAR", "MARKET COOLER"]
	for i in range(3):
		var button := layer.get_node_or_null("JourneyRail/Scene%d" % i) as Button
		if button == null:
			failures.append("GUIDE_RED: journey rail missing scene button %d" % (i+1))
		elif not button.text.contains(expected_names[i]):
			failures.append("GUIDE_RED: scene button %d must identify %s" % [i+1, expected_names[i]])

	if reward.visible:
		failures.append("GUIDE_RED: legacy Reward chrome must be hidden when journey presentation owns completion status")
	if continue_button.anchor_left != 0.5 or continue_button.anchor_top != 1.0:
		failures.append("GUIDE_RED: Continue should be anchored beside the bottom JourneyRail instead of floating at a fixed screen corner")
	if continue_button.offset_left < 294.0 or continue_button.offset_top > -50.0:
		failures.append("GUIDE_RED: Continue must sit directly beside the rail without overlapping its three scene controls")

	guide.set_state(0, "PEEL", "crumple", 0.18, false)
	if guide.get_active_scene_index() != 0:
		failures.append("GUIDE_RED: café must report active journey scene index 0")
	if not String(guide.get_action_text()).to_lower().contains("peel"):
		failures.append("GUIDE_RED: attached café journey state must retain peeling guidance even when it is not rendered as duplicate chrome")
	if rail.visible:
		failures.append("GUIDE_RED: bottom journey rail must hide during active peel so the reference interaction frame stays visually quiet")

	guide.set_state(0, "HELD", "crumple", 1.0, true)
	var cafe_post: String = String(guide.get_action_text()).to_lower()
	if not cafe_post.contains("squeeze") or not cafe_post.contains("continue"):
		failures.append("GUIDE_RED: completed café must retain optional squeeze and Continue state guidance")
	if not rail.visible:
		failures.append("GUIDE_RED: journey rail must return after detach so touch users can navigate scenes")

	guide.set_state(0, "CRUMPLING", "crumple", 1.0, true)
	if rail.visible:
		failures.append("GUIDE_RED: bottom journey rail must hide during active café crumple so the hand-and-cup ritual owns the frame")
	guide.set_state(0, "CRUMPLE_READY", "crumple", 1.0, true)
	if not rail.visible:
		failures.append("GUIDE_RED: journey rail must return when café crumple is idle so touch users retain scene navigation")

	guide.set_state(1, "HELD", "inspect", 1.0, true)
	var bar_post: String = String(guide.get_action_text()).to_lower()
	if guide.get_active_scene_index() != 1:
		failures.append("GUIDE_RED: bar must report scene index 1")
	if not bar_post.contains("inspect") or not bar_post.contains("continue"):
		failures.append("GUIDE_RED: completed bar must retain inspect and Continue state guidance")

	guide.set_state(2, "PEEL", "inspect", 0.0, false)
	if guide.get_active_scene_index() != 2:
		failures.append("GUIDE_RED: market must report scene index 2")
	if not rail.visible:
		failures.append("GUIDE_RED: journey rail must remain available before peeling starts")

	guide.set_inspection_active(true)
	if rail.visible:
		failures.append("GUIDE_RED: bottom journey rail must hide while RMB inspection is active so the product silhouette owns the frame")
	guide.set_inspection_active(false)
	if not rail.visible:
		failures.append("GUIDE_RED: journey rail must return after inspection ends when peel has not started")

	var requested: Array[int] = [-1]
	if not guide.has_signal("scene_requested"):
		failures.append("GUIDE_RED: journey rail must expose scene_requested for pointer navigation")
	else:
		guide.connect("scene_requested", func(index): requested[0] = int(index))
		var market_button := layer.get_node_or_null("JourneyRail/Scene2") as Button
		if market_button != null:
			market_button.emit_signal("pressed")
		if requested[0] != 2:
			failures.append("GUIDE_RED: clicking Market scene control must request scene index 2")

	root.free()
	return failures
