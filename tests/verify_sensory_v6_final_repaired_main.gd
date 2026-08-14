extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: Array[String] = []
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("ICE_FINAL_RED: production scene failed to load")
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
		failures.append("ICE_FINAL_RED: session/contents/cup/lid contract missing")
		_finish(scene, failures)
		return

	if int(contents.get_content_count()) != 0 or not (cup.mesh as CylinderMesh).cap_top or not lid.visible:
		failures.append("ICE_FINAL_RED: warm baseline must start empty, capped and lidded")

	for _i in range(5):
		session.record_ritual_complete()
	session.advance_item()
	session.advance_item()
	scene.call("_apply_current_variant")
	await process_frame

	var profile: Dictionary = session.current_variant()
	if String(profile.get("id", "")) != "crisp_seal":
		failures.append("ICE_FINAL_RED: fixture failed to reach crisp profile")
	if int(contents.get_content_count()) != 3:
		failures.append("ICE_FINAL_RED: crisp profile must create exactly three ice meshes")
	if (cup.mesh as CylinderMesh).cap_top or lid.visible:
		failures.append("ICE_FINAL_RED: crisp ice profile must expose open top and hide opaque lid")

	var dims: Dictionary = profile.get("cup_dimensions", {})
	var content_profile: Dictionary = profile.get("contents_profile", {})
	var cube_size := float(content_profile.get("cube_size", 0.0))
	var inner_radius := maxf(minf(float(dims.get("top_radius", 0.0)), float(dims.get("bottom_radius", 0.0))) - cube_size * 0.60, 0.01)
	var bottom_limit := -float(dims.get("height", 0.0)) * 0.5 + cube_size * 0.75
	var top_limit := float(dims.get("height", 0.0)) * 0.5 - cube_size * 0.10
	var surface_floor := float(dims.get("height", 0.0)) * 0.5 - cube_size * 0.25
	var ice_root := contents.get_node_or_null("IceContents") as Node3D
	var back_half_count := 0
	if ice_root == null:
		failures.append("ICE_FINAL_RED: IceContents container missing")
	else:
		for child in ice_root.get_children():
			if child is RigidBody3D or child is SoftBody3D:
				failures.append("ICE_FINAL_RED: final ice must remain presentation-only without physics bodies")
			var node := child as Node3D
			if node == null:
				continue
			var p := node.position
			if not _finite_vec3(p):
				failures.append("ICE_FINAL_RED: base ice transform is non-finite")
			if Vector2(p.x, p.z).length() > inner_radius + 0.0001 or p.y < bottom_limit - 0.0001 or p.y > top_limit + 0.0001:
				failures.append("ICE_FINAL_RED: base ice center escaped final bounded surface band")
			if p.y < surface_floor - 0.0001:
				failures.append("ICE_FINAL_RED: base ice is too low for fixed-camera rim readability")
			if p.z < -cube_size * 0.05:
				back_half_count += 1
	if back_half_count < 2:
		failures.append("ICE_FINAL_RED: at least two ice centers must stage in camera-readable back half")

	for side in [-1, 1]:
		contents.set_crumple(1.0, side, 1.0)
		if ice_root != null:
			for child in ice_root.get_children():
				var node := child as Node3D
				if node == null:
					continue
				var p := node.position
				if not _finite_vec3(p):
					failures.append("ICE_FINAL_RED: extreme pulse produced non-finite ice transform")
				if Vector2(p.x, p.z).length() > inner_radius + 0.0001 or p.y < bottom_limit - 0.0001 or p.y > top_limit + 0.0001:
					failures.append("ICE_FINAL_RED: extreme pulse escaped final bounded surface band")

	# Restart must clear contents and restore the quiet warm presentation; the
	# same unlock path must later rebuild exactly three instead of appending.
	session.restart_run()
	scene.call("_apply_current_variant")
	await process_frame
	if int(contents.get_content_count()) != 0 or not (cup.mesh as CylinderMesh).cap_top or not lid.visible:
		failures.append("ICE_FINAL_RED: restart must clear ice and restore closed warm cup")
	for _i in range(5):
		session.record_ritual_complete()
	session.advance_item()
	session.advance_item()
	scene.call("_apply_current_variant")
	await process_frame
	if int(contents.get_content_count()) != 3:
		failures.append("ICE_FINAL_RED: re-entering crisp profile must rebuild exactly three cubes without duplication")

	_finish(scene, failures)

func _finite_vec3(value: Vector3) -> bool:
	return is_finite(value.x) and is_finite(value.y) and is_finite(value.z)

func _finish(scene: Node, failures: Array[String]) -> void:
	if failures.is_empty():
		print("PASS: final repaired-main V6 ice — rim-readable, back-staged, bounded, resettable, physics-free")
		scene.queue_free()
		await process_frame
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
