extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var controller_script = load("res://scripts/peel/peel_controller.gd")
	var pointer_script = load("res://scripts/input/pointer_state.gd")
	if controller_script == null or pointer_script == null:
		failures.append("paper resistance dependencies did not load")
		return failures

	# RED: A loaded label must not keep peeling while the mouse is held still.
	# Progress must come from additional peel displacement/work, not elapsed time
	# under an already-large pull vector.
	var controller = controller_script.new({"base_adhesion":10.0,"release_increment":0.014,"bond_response":10.0})
	controller.set_edge_position(Vector2(100,100))
	controller.set_grab_region(Rect2(Vector2(70,70),Vector2(60,60)))
	var pointer = pointer_script.new()
	pointer.set_frame(true,Vector2(130,70),Vector2.ZERO,Vector2.ZERO,false)
	controller.process_pointer(pointer,0.016)
	for _i in range(7):
		pointer.set_frame(true,Vector2(144,60),Vector2(2,-1),Vector2(160,-80),false)
		controller.process_pointer(pointer,0.016)
	for i in range(12):
		var p: Vector2 = Vector2(148+i*3,58-i)
		pointer.set_frame(true,p,Vector2(3,-1),Vector2(420,-120),false)
		controller.process_pointer(pointer,0.016)
	var moving_progress: float = float(controller.get_progress())
	if moving_progress <= 0.0:
		failures.append("precondition: deliberate moving pull must begin peel")
	for _i in range(45):
		pointer.set_frame(true,pointer.position,Vector2.ZERO,Vector2.ZERO,false)
		controller.process_pointer(pointer,0.016)
	var held_progress: float = float(controller.get_progress())
	if held_progress-moving_progress > 0.006:
		failures.append("PAPER_RESISTANCE_RED: holding still must stall peel progress; advanced %.4f" % (held_progress-moving_progress))

	# Continued outward displacement must resume release.
	for i in range(16):
		var p2: Vector2 = pointer.position+Vector2(3.0+float(i)*1.2,-1.0)
		pointer.set_frame(true,p2,Vector2(3,-1),Vector2(460,-130),false)
		controller.process_pointer(pointer,0.016)
	if float(controller.get_progress()) <= held_progress+0.004:
		failures.append("paper peel must resume when the cursor does additional outward work")

	# RED: the visible corner implementation may compress mid-progress for a
	# readable hero label, but 100% gameplay progress must visually detach 100%
	# of the label instead of leaving a permanent attached patch.
	var corner_script = load("res://scripts/presentation/corner_peel_presentation.gd")
	if corner_script == null:
		failures.append("corner peel presentation did not load")
	else:
		var corner = corner_script.new()
		if not corner.has_method("visual_progress_for_gameplay"):
			failures.append("PAPER_COMPLETION_RED: corner peel needs visual_progress_for_gameplay completion mapping")
		else:
			var mid: float = float(corner.call("visual_progress_for_gameplay",0.38))
			var full: float = float(corner.call("visual_progress_for_gameplay",1.0))
			if mid >= 0.38:
				failures.append("mid peel should remain visually compressed enough to keep print readable")
			if full < 0.999:
				failures.append("PAPER_COMPLETION_RED: 100% gameplay progress must detach the full visible label")
		if not corner.has_method("paper_bend_band_ratio"):
			failures.append("PAPER_STIFFNESS_RED: corner peel needs a bounded bend-front band")
		else:
			var band: float = float(corner.call("paper_bend_band_ratio"))
			if band <= 0.02 or band > 0.22:
				failures.append("paper bend must be localized near peel front, got %.3f" % band)
		corner.free()

	# RED: five scenes need five distinct visual signatures. A signature may use
	# the same source photo only if crop/modulate/placement make the final plate
	# deterministically different.
	var backdrop_script = load("res://scripts/presentation/reference_backdrop.gd")
	if backdrop_script == null:
		failures.append("reference backdrop did not load")
	else:
		var backdrop = backdrop_script.new()
		if not backdrop.has_method("profile_visual_signature"):
			failures.append("SCENE_SEPARATION_RED: backdrop needs per-scene visual signatures")
		else:
			var signatures: Dictionary = {}
			for id in ["cafe_window","pantry_jar","pantry_tin","market_coldcase","market_can"]:
				var signature: String = String(backdrop.call("profile_visual_signature",id))
				if signature.is_empty():
					failures.append("scene %s has empty backdrop signature" % id)
				signatures[signature] = true
			if signatures.size() != 5:
				failures.append("SCENE_SEPARATION_RED: expected five distinct scene signatures, got %d" % signatures.size())
		backdrop.free()
	return failures
