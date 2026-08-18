extends SceneTree

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
	for _frame in range(6):
		await process_frame

	var failures: Array[String] = []
	for child_name in ["Camera","Cup","PeelLabel","LabelPrint","PointerAdapter","PeelAudio","HUD","ProductPresentation","VenuePresentation","ReferenceBackdrop"]:
		if not scene.has_node(child_name):
			failures.append("OBJECT_ONLY_SMOKE_RED: missing runtime node %s" % child_name)

	for forbidden in ["LeftHand","RightHand","ForearmPresentation","CrumpleHandStaging","HandChoreographyPresentation","CinematicHandPresentation","HandSurfaceSmoothing","ReferencePeelPlayback"]:
		if scene.get_node_or_null(forbidden) != null:
			failures.append("OBJECT_ONLY_SMOKE_RED: obsolete presentation node leaked into runtime: %s" % forbidden)

	var contract: Dictionary = scene.call("get_visual_interaction_contract")
	if bool(contract.get("visible_hands",true)):
		failures.append("OBJECT_ONLY_SMOKE_RED: visual contract still exposes hands")
	if String(contract.get("pointer_grip","")) != "mouse_direct":
		failures.append("OBJECT_ONLY_SMOKE_RED: live label grip must be mouse-direct")

	var audio := scene.get_node_or_null("PeelAudio")
	if audio == null:
		failures.append("OBJECT_ONLY_SMOKE_RED: missing PeelAudio")
	else:
		for player_name in ["AdhesiveSlow","AdhesiveFast","PaperFlex","MicroRelease","FinalRelease"]:
			var player := audio.get_node_or_null(player_name) as AudioStreamPlayer
			if player == null or player.stream == null:
				failures.append("OBJECT_ONLY_SMOKE_RED: missing repository-local foley stream %s" % player_name)

	for resource_path in [
		"res://assets/audio/peel/adhesive_slow.wav",
		"res://assets/audio/peel/adhesive_fast.wav",
		"res://assets/audio/peel/paper_flex.wav",
		"res://assets/audio/peel/micro_release.wav",
		"res://assets/audio/peel/final_release.wav",
		"res://assets/ui/peel_cursor.svg"
	]:
		if not ResourceLoader.exists(resource_path):
			failures.append("OBJECT_ONLY_SMOKE_RED: missing runtime tactile/UI resource %s" % resource_path)

	var lifecycle = scene.get("_lifecycle")
	if lifecycle == null or lifecycle.get_phase_name() != "ATTACHED":
		failures.append("OBJECT_ONLY_SMOKE_RED: fresh peel scene lifecycle must start ATTACHED")
	var session = scene.get("_session")
	if session == null:
		failures.append("OBJECT_ONLY_SMOKE_RED: complete playable scene must initialize SessionModel")
	else:
		if session.VARIANTS.size() != 5 or session.get_unlocked_count() != 5:
			failures.append("OBJECT_ONLY_SMOKE_RED: five product scenes must be available immediately")
		var variant: Dictionary = session.current_variant()
		var label := scene.get_node_or_null("PeelLabel") as LabelVisual
		if label == null:
			failures.append("OBJECT_ONLY_SMOKE_RED: session integration missing PeelLabel")
		else:
			if absf(label.label_width-float(variant.get("label_width",-1.0)))>0.001:
				failures.append("OBJECT_ONLY_SMOKE_RED: current variant must drive label width")
			if absf(label.label_height-float(variant.get("label_height",-1.0)))>0.001:
				failures.append("OBJECT_ONLY_SMOKE_RED: current variant must drive label height")

	for hud_node in ["HUD/ProgressPanel","HUD/ControlsPanel","HUD/HowToPanel","HUD/JourneyRail"]:
		if scene.get_node_or_null(hud_node) == null:
			failures.append("OBJECT_ONLY_SMOKE_RED: approved HUD missing %s" % hud_node)

	var hud := scene.get_node_or_null("HUD/Instructions") as Label
	if hud == null:
		failures.append("OBJECT_ONLY_SMOKE_RED: missing internal status HUD authority")
	else:
		if not hud.text.contains("R Reset") or not hud.text.contains("Esc Pause") or not hud.text.contains("Wheel Zoom"):
			failures.append("OBJECT_ONLY_SMOKE_RED: runtime control contract is not reflected in status copy")

	if failures.is_empty():
		print("PASS: complete playable object-only mouse-direct peel scene")
		scene.queue_free()
		await process_frame
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
