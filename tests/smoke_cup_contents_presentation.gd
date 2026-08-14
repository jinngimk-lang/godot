extends SceneTree

const TEST_CUBE_SIZE := 0.145

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: Array[String] = []
	var required := "res://scripts/presentation/cup_contents_presentation.gd"
	if not ResourceLoader.exists(required):
		push_error("CONTENTS_PRESENTATION_RED: missing bounded cup contents presentation")
		quit(1)
		return

	var root := Node3D.new()
	root.name = "Fixture"
	get_root().add_child(root)

	var cup := MeshInstance3D.new()
	cup.name = "Cup"
	var cup_mesh := CylinderMesh.new()
	cup_mesh.top_radius = 0.58
	cup_mesh.bottom_radius = 0.47
	cup_mesh.height = 1.38
	cup.mesh = cup_mesh
	cup.position = Vector3(0.0, 0.05, 0.0)
	root.add_child(cup)

	var presentation = load(required).new()
	presentation.name = "CupContentsPresentation"
	root.add_child(presentation)
	await process_frame

	var baseline_profile := {
		"cup_dimensions": {"top_radius": 0.54, "bottom_radius": 0.45, "height": 1.48},
		"contents_profile": {"type": "none"}
	}
	presentation.set_profile(baseline_profile)
	if int(presentation.get_content_count()) != 0:
		failures.append("warm/baseline cup must expose zero content meshes")

	var ice_profile := {
		"cup_dimensions": {"top_radius": 0.58, "bottom_radius": 0.47, "height": 1.38},
		"contents_profile": {"type": "ice", "count": 3, "cube_size": TEST_CUBE_SIZE, "motion_gain": 0.55}
	}
	presentation.set_profile(ice_profile)
	if int(presentation.get_content_count()) != 3:
		failures.append("ice profile should create exactly 3 deterministic cubes")

	var container: Node = presentation.get_node_or_null("IceContents")
	if container == null:
		failures.append("ice profile should expose IceContents container")
	else:
		if _has_physics_descendant(container):
			failures.append("contained ice must stay presentation-only without RigidBody3D/SoftBody3D")
		var base_transforms: Array[Transform3D] = []
		var dims: Dictionary = ice_profile.get("cup_dimensions", {})
		var surface_floor := float(dims.get("height", 0.0)) * 0.5 - TEST_CUBE_SIZE * 0.25
		var back_half_count := 0
		for child in container.get_children():
			if not (child is MeshInstance3D):
				failures.append("ice contents should contain only mesh presentation children")
				continue
			var cube := child as MeshInstance3D
			base_transforms.append(cube.transform)
			if not _inside_bounded_surface_band(cube.position, TEST_CUBE_SIZE, dims):
				failures.append("ice base position escaped bounded cup surface band: %s" % cube.position)
			if cube.position.y < surface_floor:
				failures.append("RED: ice reward must stage at the rim surface for fixed-camera readability; y=%.3f floor=%.3f" % [cube.position.y, surface_floor])
			if cube.position.z < -TEST_CUBE_SIZE * 0.05:
				back_half_count += 1
		if back_half_count < 2:
			failures.append("RED: at least two ice cubes must stage in the camera-readable back half of the open cup; got %d" % back_half_count)

		presentation.set_crumple(1.0, -1, 1.0)
		for child in container.get_children():
			if child is MeshInstance3D:
				var cube := child as MeshInstance3D
				if not _is_finite_vec3(cube.position):
					failures.append("max crumple pulse produced non-finite ice position")
				if not _inside_bounded_surface_band(cube.position, TEST_CUBE_SIZE, dims):
					failures.append("max crumple pulse pushed ice outside bounded cup surface band: %s" % cube.position)

		presentation.set_crumple(0.72, 1, 0.9)
		presentation.reset_visual()
		for i in range(mini(base_transforms.size(), container.get_child_count())):
			var child = container.get_child(i)
			if child is MeshInstance3D and not (child as MeshInstance3D).transform.is_equal_approx(base_transforms[i]):
				failures.append("reset_visual should restore deterministic base ice transform for cube %d" % i)

	root.queue_free()
	await process_frame

	if failures.is_empty():
		print("PASS: contained ice is deterministic, rim-readable, bounded, finite and physics-free")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _inside_bounded_surface_band(position: Vector3, cube_size: float, dims: Dictionary) -> bool:
	var inner_radius := maxf(minf(float(dims.get("top_radius", 0.0)), float(dims.get("bottom_radius", 0.0))) - cube_size * 0.60, 0.01)
	var bottom_limit := -float(dims.get("height", 0.0)) * 0.5 + cube_size * 0.75
	# A filled cup may let the ice top peek slightly above the paper rim, but the
	# cube center remains near/below the rim and cannot fly free vertically.
	var top_limit := float(dims.get("height", 0.0)) * 0.5 - cube_size * 0.10
	var radial := Vector2(position.x, position.z).length()
	return radial <= inner_radius + 0.0001 and position.y >= bottom_limit - 0.0001 and position.y <= top_limit + 0.0001

func _has_physics_descendant(node: Node) -> bool:
	for child in node.get_children():
		if child is RigidBody3D or child is SoftBody3D:
			return true
		if _has_physics_descendant(child):
			return true
	return false

func _is_finite_vec3(value: Vector3) -> bool:
	return is_finite(value.x) and is_finite(value.y) and is_finite(value.z)
