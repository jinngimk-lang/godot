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

	# Complete-playable session contract: tactile variants must drive the actual
	# scene/controller, not exist only as disconnected progression data.
	var session = scene.get("_session")
	if session == null:
		failures.append("complete playable scene must initialize SessionModel")
	else:
		var variant: Dictionary = session.current_variant()
		var label := scene.get_node_or_null("PeelLabel") as LabelVisual
		if label == null:
			failures.append("session integration missing PeelLabel")
		else:
			if absf(label.label_width - float(variant.get("label_width", -1.0))) > 0.001:
				failures.append("current tactile variant must drive label width")
			if absf(label.label_height - float(variant.get("label_height", -1.0))) > 0.001:
				failures.append("current tactile variant must drive label height")

		var controller = scene.get("_controller")
		if controller == null or not controller.has_method("get_model_config"):
			failures.append("playable controller must expose applied tactile config for verification")
		else:
			var config: Dictionary = controller.get_model_config()
			if absf(float(config.get("base_adhesion", -1.0)) - float(variant.get("base_adhesion", -2.0))) > 0.001:
				failures.append("current tactile variant must drive actual adhesion")

	var hud := scene.get_node_or_null("HUD/Instructions") as Label
	if hud == null:
		failures.append("missing player-facing instruction HUD")
	else:
		for developer_word in ["ATTACHED", "PEELING", "DETACHING", "HELD", "IDLE", "PINCHED"]:
			if hud.text.contains(developer_word):
				failures.append("player HUD must not expose developer state jargon: %s" % developer_word)
		if not hud.text.contains("Reset") or not hud.text.contains("Pause"):
			failures.append("player HUD must expose reset and pause affordances")

	if failures.is_empty():
		print("PASS: complete-playable tactile peel scene smoke")
		scene.queue_free()
		await process_frame
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
