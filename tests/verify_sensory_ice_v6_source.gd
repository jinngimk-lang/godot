extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: Array[String] = []
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("ICE_VERIFY_RED: production scene failed to load")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var session = scene.get("_session")
	var contents = scene.get("_contents_presentation")
	var cup := scene.get_node_or_null("Cup") as MeshInstance3D
	var lid := scene.get_node_or_null("Lid") as MeshInstance3D
	if session == null or contents == null or cup == null or lid == null or not (cup.mesh is CylinderMesh):
		failures.append("ICE_VERIFY_RED: production session/contents/cup/lid contract missing")
		_finish(scene, failures)
		return

	if int(contents.get_content_count()) != 0:
		failures.append("ICE_VERIFY_RED: fresh warm profile must start with zero contents")
	if not (cup.mesh as CylinderMesh).cap_top or not lid.visible:
		failures.append("ICE_VERIFY_RED: non-ice baseline must remain capped and lidded")

	# Unlock all profiles, then move to the final crisp/ice profile through the
	# real SessionModel rotation contract.
	for _i in range(5):
		session.record_ritual_complete()
	session.advance_item()
	session.advance_item()
	scene.call("_apply_current_variant")
	await process_frame

	var profile: Dictionary = session.current_variant()
	if String(profile.get("id", "")) != "crisp_seal":
		failures.append("ICE_VERIFY_RED: fixture failed to reach final crisp profile")
	if int(contents.get_content_count()) != 3:
		failures.append("ICE_VERIFY_RED: final profile must create exactly three contained ice pieces")
	if (cup.mesh as CylinderMesh).cap_top or lid.visible:
		failures.append("ICE_VERIFY_RED: ice profile must expose an open cup top rather than hide ice below an opaque lid")

	var ice_root := contents.get_node_or_null("IceContents") as Node3D
	if ice_root == null:
		failures.append("ICE_VERIFY_RED: IceContents container missing")
	else:
		for child in ice_root.get_children():
			if child is RigidBody3D or child is SoftBody3D:
				failures.append("ICE_VERIFY_RED: contained ice must remain presentation-only without physics bodies")

	# Extreme deterministic presentation input must stay finite and bounded on
	# both squeeze sides. Inspect local positions against the configured inner
	# cup bounds rather than trusting the presentation helper itself.
	var dims: Dictionary = profile.get("cup_dimensions", {})
	var cube_size := float(profile.get("contents_profile", {}).get("cube_size", 0.115))
	var inner_radius := maxf(minf(float(dims.get("bottom_radius", 0.47)), float(dims.get("top_radius", 0.58))) - cube_size * 0.65, 0.01)
	var half_height := maxf(float(dims.get("height", 1.38)) * 0.5 - cube_size * 0.75, 0.01)
	for side in [-1, 1]:
		contents.set_crumple(1.0, side, 1.0)
		if ice_root != null:
			for child in ice_root.get_children():
				var node := child as Node3D
				if node == null:
					continue
				var p := node.position
				if not (is_finite(p.x) and is_finite(p.y) and is_finite(p.z)):
					failures.append("ICE_VERIFY_RED: extreme crumple produced non-finite ice transform")
				var radial := Vector2(p.x, p.z).length()
				if radial > inner_radius + 0.0001 or absf(p.y) > half_height + 0.0001:
					failures.append("ICE_VERIFY_RED: extreme crumple moved ice outside configured cup bounds")

	# Restart must clear ice and restore the quiet lidded baseline. Re-unlocking
	# and re-entering crisp must recreate exactly three, never append duplicates.
	session.restart_run()
	scene.call("_apply_current_variant")
	await process_frame
	if int(contents.get_content_count()) != 0 or not (cup.mesh as CylinderMesh).cap_top or not lid.visible:
		failures.append("ICE_VERIFY_RED: restart must clear contents and restore capped/lidded baseline")
	for _i in range(5):
		session.record_ritual_complete()
	session.advance_item()
	session.advance_item()
	scene.call("_apply_current_variant")
	await process_frame
	if int(contents.get_content_count()) != 3:
		failures.append("ICE_VERIFY_RED: re-entering ice profile must rebuild exactly three contents without duplication")

	_finish(scene, failures)

func _finish(scene: Node, failures: Array[String]) -> void:
	if failures.is_empty():
		print("PASS: V6 source ice — open top, bounded extremes, reset/no duplication, no physics")
		scene.queue_free()
		await process_frame
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
