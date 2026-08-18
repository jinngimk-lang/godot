extends SceneTree

const MIN_REALTIME_HAND_DETAIL := 20000

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("SMOKE: main peel lab scene failed to load")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	for _frame in range(5):
		await process_frame

	var failures: Array[String] = []
	for child_name in [
		"Camera","Cup","PeelLabel","LabelPrint","LeftHand","RightHand",
		"PointerAdapter","PeelAudio","HUD","CafePresentation","CupContentsPresentation",
		"CinematicHandPresentation","HandChoreographyPresentation"
	]:
		if not scene.has_node(child_name):
			failures.append("RED: missing runtime node: %s" % child_name)

	var contents := scene.get_node_or_null("CupContentsPresentation")
	if contents == null or not contents.has_method("get_content_count"):
		failures.append("RED: production scene must own CupContentsPresentation contract")
	elif int(contents.call("get_content_count")) != 0:
		failures.append("fresh cafe scene must start with zero cup contents")

	var cafe := scene.get_node_or_null("CafePresentation") as Node3D
	if cafe == null:
		failures.append("RED: missing cafe presentation layer")
	else:
		for presentation_node in ["WorldEnvironment","Backdrop","LidInset"]:
			if cafe.get_node_or_null(presentation_node) == null:
				failures.append("RED: cafe presentation missing %s" % presentation_node)

	var cinematic := scene.get_node_or_null("CinematicHandPresentation")
	if cinematic == null or not cinematic.has_method("get_visible_realtime_shell_count"):
		failures.append("RED: missing realtime hand presentation authority")
	elif int(cinematic.call("get_visible_realtime_shell_count")) != 2:
		failures.append("both realtime hand shells must be visible")

	for hand_name in ["LeftHand","RightHand"]:
		var hand := scene.get_node_or_null(hand_name) as HandVisual
		if hand == null:
			continue
		if hand.get_finger_count() != 5:
			failures.append("%s must expose five fingers" % hand_name)
		if not hand.is_using_authored_asset():
			failures.append("%s must retain authored skeleton/animation authority" % hand_name)
		if not hand.is_using_realtime_shell():
			failures.append("%s must use realtime smooth shell for viewport rendering" % hand_name)
		elif hand.get_realtime_shell_vertex_count() < MIN_REALTIME_HAND_DETAIL:
			failures.append("%s realtime shell detail budget is too low" % hand_name)
		var authored := hand.get_node_or_null("AuthoredHand") as Node3D
		if authored == null:
			failures.append("%s missing authored pose-authority instance" % hand_name)
		elif _count_visible_meshes(authored) != 0:
			failures.append("%s low-poly authored mesh leaked into final viewport" % hand_name)
		var shell := hand.get_node_or_null("RealtimeHandShell") as Node3D
		if shell == null or not shell.visible:
			failures.append("%s realtime shell missing or hidden" % hand_name)
		for anchor in ["ThumbTip","IndexTip","PinchPoint"]:
			if hand.find_child(anchor,true,false) == null:
				failures.append("%s missing contact anchor %s" % [hand_name,anchor])

	var audio := scene.get_node_or_null("PeelAudio")
	if audio == null:
		failures.append("missing PeelAudio")
	else:
		for player_name in ["AdhesiveSlow","AdhesiveFast","PaperFlex","MicroRelease","FinalRelease"]:
			var player := audio.get_node_or_null(player_name) as AudioStreamPlayer
			if player == null or player.stream == null:
				failures.append("missing repository-local foley stream: %s" % player_name)

	for resource_path in [
		"res://assets/audio/peel/adhesive_slow.wav",
		"res://assets/audio/peel/adhesive_fast.wav",
		"res://assets/audio/peel/paper_flex.wav",
		"res://assets/audio/peel/micro_release.wav",
		"res://assets/audio/peel/final_release.wav",
		"res://assets/models/hands/hand_left.glb",
		"res://assets/models/hands/hand_right.glb"
	]:
		if not ResourceLoader.exists(resource_path):
			failures.append("missing repository-local tactile resource: %s" % resource_path)

	var lifecycle = scene.get("_lifecycle")
	if lifecycle == null or lifecycle.get_phase_name() != "ATTACHED":
		failures.append("fresh peel scene lifecycle must start ATTACHED")
	var session = scene.get("_session")
	if session == null:
		failures.append("complete playable scene must initialize SessionModel")
	else:
		var variant: Dictionary = session.current_variant()
		var label := scene.get_node_or_null("PeelLabel") as LabelVisual
		if label == null:
			failures.append("session integration missing PeelLabel")
		else:
			if absf(label.label_width-float(variant.get("label_width",-1.0))) > 0.001:
				failures.append("current variant must drive label width")
			if absf(label.label_height-float(variant.get("label_height",-1.0))) > 0.001:
				failures.append("current variant must drive label height")

	var hud := scene.get_node_or_null("HUD/Instructions") as Label
	if hud == null:
		failures.append("missing player-facing instruction HUD")
	else:
		for developer_word in ["ATTACHED","PEELING","DETACHING","HELD","IDLE","PINCHED"]:
			if hud.text.contains(developer_word):
				failures.append("player HUD must not expose developer state jargon: %s" % developer_word)
		if not hud.text.contains("Reset") or not hud.text.contains("Pause"):
			failures.append("player HUD must expose reset and pause affordances")

	if failures.is_empty():
		print("PASS: complete playable realtime peel scene with smooth hand viewport authority")
		scene.queue_free()
		await process_frame
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _count_visible_meshes(node: Node) -> int:
	if node == null:
		return 0
	var count := 0
	if node is MeshInstance3D and (node as MeshInstance3D).visible:
		count += 1
	for child in node.get_children():
		count += _count_visible_meshes(child)
	return count
