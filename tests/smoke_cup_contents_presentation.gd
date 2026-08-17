extends SceneTree

const TEST_CUBE_SIZE := 0.145
const GLASS_ICE_MAX_CENTER_Y := 0.34
const GLASS_MIN_VERTICAL_SPAN := TEST_CUBE_SIZE * 0.40
const GLASS_MIN_PAIR_DISTANCE := TEST_CUBE_SIZE * 0.82

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

	# Glass bottles use a body cluster rather than the paper-cup rim layout. The
	# cubes must remain individually readable from the product camera instead of
	# merging into one opaque cyan slab.
	var glass_ice_profile := {
		"cup_shell": "clear_glass",
		"cup_dimensions": {"top_radius": 0.335, "bottom_radius": 0.315, "height": 1.52},
		"contents_profile": {
			"type": "ice",
			"count": 3,
			"cube_size": TEST_CUBE_SIZE,
			"motion_gain": 0.55,
			"max_center_y": GLASS_ICE_MAX_CENTER_Y,
			"layout": "glass_cluster"
		}
	}
	presentation.set_profile(glass_ice_profile)
	var glass_container: Node = presentation.get_node_or_null("IceContents")
	if glass_container == null or glass_container.get_child_count() != 3:
		failures.append("glass ice profile should preserve all three deterministic cubes")
	else:
		var glass_positions: Array[Vector3] = []
		var min_y := INF
		var max_y := -INF
		for child in glass_container.get_children():
			if child is MeshInstance3D:
				var cube := child as MeshInstance3D
				glass_positions.append(cube.position)
				min_y = minf(min_y, cube.position.y)
				max_y = maxf(max_y, cube.position.y)
				if cube.position.y > GLASS_ICE_MAX_CENTER_Y + 0.0001:
					failures.append("RED: glass ice must stay below the bottle shoulder; y=%.3f max=%.3f" % [cube.position.y, GLASS_ICE_MAX_CENTER_Y])
				var mat := cube.material_override as StandardMaterial3D
				if mat == null:
					failures.append("RED: glass ice must expose a dedicated StandardMaterial3D")
				else:
					if mat.transparency != BaseMaterial3D.TRANSPARENCY_ALPHA:
						failures.append("RED: glass ice must use alpha transparency instead of an opaque cyan block")
					if mat.albedo_color.a < 0.28 or mat.albedo_color.a > 0.62:
						failures.append("RED: glass ice alpha should preserve readable edges without becoming opaque; got %.3f" % mat.albedo_color.a)
					if mat.albedo_color.b - mat.albedo_color.r > 0.14:
						failures.append("RED: glass ice should stay near-neutral rather than saturated blue")
					if mat.roughness > 0.20:
						failures.append("RED: glass ice should read as wet/glassy rather than chalky; roughness=%.3f" % mat.roughness)
		if max_y - min_y < GLASS_MIN_VERTICAL_SPAN:
			failures.append("RED: glass ice needs vertical staggering so three cubes do not merge into one slab; span=%.3f min=%.3f" % [max_y - min_y, GLASS_MIN_VERTICAL_SPAN])
		for a in range(glass_positions.size()):
			for b in range(a + 1, glass_positions.size()):
				var distance := glass_positions[a].distance_to(glass_positions[b])
				if distance < GLASS_MIN_PAIR_DISTANCE:
					failures.append("RED: glass ice cubes need enough 3D separation to remain individually readable; pair=%d/%d distance=%.3f min=%.3f" % [a, b, distance, GLASS_MIN_PAIR_DISTANCE])
		presentation.set_crumple(1.0, 1, 1.0)
		for child in glass_container.get_children():
			if child is MeshInstance3D and (child as MeshInstance3D).position.y > GLASS_ICE_MAX_CENTER_Y + 0.0001:
				failures.append("RED: glass ice motion must remain below the bottle shoulder")

	root.queue_free()
	await process_frame

	if failures.is_empty():
		print("PASS: contained ice is deterministic, shell-aware, bounded, separated, translucent, finite and physics-free")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _inside_bounded_surface_band(position: Vector3, cube_size: float, dims: Dictionary) -> bool:
	var inner_radius := maxf(minf(float(dims.get("top_radius", 0.0)), float(dims.get("bottom_radius", 0.0))) - cube_size * 0.60, 0.01)
	var bottom_limit := -float(dims.get("height", 0.0)) * 0.5 + cube_size * 0.75
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
