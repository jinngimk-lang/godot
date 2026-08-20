extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var path := "res://scripts/presentation/guided_journey_presentation.gd"
	if not ResourceLoader.exists(path):
		return ["GUIDE_RED: missing guided multi-scene journey presentation"]
	var script = load(path)
	if script == null:
		return ["GUIDE_RED: guided journey script failed to load"]

	var root := Node.new()
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	root.add_child(layer)
	var reward := Label.new()
	reward.name = "Reward"
	layer.add_child(reward)
	var continue_button := Button.new()
	continue_button.name = "Continue"
	layer.add_child(continue_button)
	var guide = script.new()
	root.add_child(guide)
	guide._process(0.0)

	var rail := layer.get_node_or_null("JourneyRail") as Control
	if rail == null:
		failures.append("GUIDE_RED: HUD must expose JourneyRail")
		root.free()
		return failures
	var expected_names := ["COFFEE SHOP", "JAR", "TIN CAN", "SUPERMARKET", "CAN"]
	for i in range(5):
		var button := layer.get_node_or_null("JourneyRail/Scene%d" % i) as Button
		if button == null:
			failures.append("GUIDE_RED: journey rail missing scene button %d" % (i+1))
		elif not button.text.to_upper().contains(expected_names[i]):
			failures.append("GUIDE_RED: scene button %d must identify %s" % [i+1,expected_names[i]])

	guide.set_state(0, "PEEL", "inspect", 0.38, false)
	if guide.get_active_scene_index() != 0:
		failures.append("GUIDE_RED: Coffee Shop must report active scene index 0")
	if not rail.visible:
		failures.append("GUIDE_RED: five-scene rail must remain visible during active peel to match the approved mockup")

	guide.set_inspection_active(true)
	if not rail.visible:
		failures.append("GUIDE_RED: scene rail is persistent even while rotating/zooming the object")
	guide.set_inspection_active(false)

	guide.set_state(4, "PEEL", "inspect", 0.33, false)
	if guide.get_active_scene_index() != 4:
		failures.append("GUIDE_RED: Can must report active scene index 4")
	if not String(guide.get_action_text()).to_lower().contains("peel"):
		failures.append("GUIDE_RED: active scene state must retain peel guidance")

	guide.set_state(4,"RESOLVED","inspect",1.0,true)
	if rail.visible:
		failures.append("GUIDE_FOCUS_RED: resolved object play must hide the five-scene rail so the bare product dominates")
	if not continue_button.visible:
		failures.append("GUIDE_FOCUS_RED: Continue must remain available while the rail is hidden")
	if not String(guide.get_action_text()).to_upper().contains("OBJECT"):
		failures.append("GUIDE_FOCUS_RED: resolved action copy must identify object play rather than another peel step")

	guide.set_state(4,"PEEL","inspect",0.33,false)
	if not rail.visible:
		failures.append("GUIDE_FOCUS_RED: returning to peel state must restore scene rail")

	var requested: Array[int] = [-1]
	if not guide.has_signal("scene_requested"):
		failures.append("GUIDE_RED: journey rail must expose scene_requested")
	else:
		guide.connect("scene_requested", func(index): requested[0] = int(index))
		var can_button := layer.get_node_or_null("JourneyRail/Scene4") as Button
		if can_button != null:
			can_button.emit_signal("pressed")
		if requested[0] != 4:
			failures.append("GUIDE_RED: clicking Can control must request scene index 4")

	if reward.visible:
		failures.append("GUIDE_RED: legacy Reward chrome must remain hidden behind the unified HUD")
	root.free()
	return failures
