extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed = load("res://scenes/peel_lab/peel_lab.tscn")
	if packed == null:
		push_error("SMOKE: main peel lab scene failed to load")
		quit(1)
		return
	var scene = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame

	var required := [
		"Camera", "Cup", "PeelLabel", "LabelPrint", "LeftHand", "RightHand",
		"PointerAdapter", "PeelAudio", "HUD"
	]
	var failures: Array[String] = []
	for child_name in required:
		if not scene.has_node(child_name):
			failures.append("missing runtime node: %s" % child_name)

	for hand_name in ["LeftHand", "RightHand"]:
		if not scene.has_node(hand_name):
			continue
		var hand = scene.get_node(hand_name)
		if hand.get_finger_count() != 5:
			failures.append("%s must expose five fingers" % hand_name)
		if not hand.is_using_authored_asset():
			failures.append("%s must use repository-local authored GLB in normal runtime" % hand_name)
		if hand.get_node_or_null("AuthoredHand") == null:
			failures.append("%s missing authored hand scene instance" % hand_name)
		for anchor in ["ThumbTip", "IndexTip", "PinchPoint"]:
			if hand.find_child(anchor, true, false) == null:
				failures.append("%s missing pinch anchor: %s" % [hand_name, anchor])

	if scene.has_node("PeelAudio"):
		var audio = scene.get_node("PeelAudio")
		for player_name in ["AdhesiveSlow", "AdhesiveFast", "PaperFlex", "MicroRelease", "FinalRelease"]:
			var player = audio.get_node_or_null(player_name)
			if player == null:
				failures.append("missing foley player: %s" % player_name)
			elif player.stream == null:
				failures.append("foley player has no repository-local stream: %s" % player_name)

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
	if lifecycle == null:
		failures.append("peel scene did not initialize LabelLifecycle")
	elif lifecycle.get_phase_name() != "ATTACHED":
		failures.append("fresh peel scene lifecycle should start ATTACHED")

	if failures.is_empty():
		print("PASS: tactile v2 peel lab scene smoke")
		scene.queue_free()
		await process_frame
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
