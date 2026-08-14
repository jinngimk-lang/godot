extends SceneTree

const TEST_SEGMENTS := 16
const TEST_MID_RING := 3

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("CRUMPLE_PRESENTATION_RED: peel lab scene failed to load")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame

	var failures: Array[String] = []
	var cup := scene.get_node_or_null("Cup") as MeshInstance3D
	var presentation := scene.get_node_or_null("CupCrumplePresentation") as Node3D
	if cup == null or not (cup.mesh is CylinderMesh):
		failures.append("CRUMPLE_PRESENTATION_RED: production Cup must remain tapered CylinderMesh authority before crumple")
	if presentation == null:
		failures.append("CRUMPLE_PRESENTATION_RED: missing CupCrumplePresentation")
	else:
		if not presentation.has_method("set_profile") or not presentation.has_method("set_crumple") or not presentation.has_method("reset_visual"):
			failures.append("CRUMPLE_PRESENTATION_RED: crumple presentation missing stable runtime interface")
		else:
			var profile := {
				"cup_dimensions": {"top_radius": 0.54, "bottom_radius": 0.45, "height": 1.48},
				"crumple_profile": {"max_compression": 0.22}
			}
			presentation.set_profile(profile)
			presentation.set_crumple(0.0, -1, 0.0)
			await process_frame
			var shell := presentation.get_node_or_null("CrumpledCup") as MeshInstance3D
			if shell == null or not (shell.mesh is ArrayMesh):
				failures.append("CRUMPLE_PRESENTATION_RED: presentation must generate one continuous ArrayMesh cup shell")
			else:
				if shell.visible:
					failures.append("CRUMPLE_PRESENTATION_RED: zero-progress overlay should stay hidden behind production Cup")
				if cup != null and not cup.visible:
					failures.append("CRUMPLE_PRESENTATION_RED: zero-progress state must keep production Cup visible")
				var baseline := shell.mesh.get_aabb()
				var baseline_mid_span := _mid_ring_x_span(shell.mesh as ArrayMesh)
				presentation.set_crumple(0.60, -1, 0.7)
				await process_frame
				var deformed := shell.mesh.get_aabb()
				var deformed_mid_span := _mid_ring_x_span(shell.mesh as ArrayMesh)
				if not shell.visible or (cup != null and cup.visible):
					failures.append("CRUMPLE_PRESENTATION_RED: positive crumple should swap visible shell without changing peel authority node")
				# The paper rim/base may intentionally keep their original diameter. Measure
				# the actual waist ring rather than whole-mesh AABB so a real mid-wall dent
				# cannot be hidden by undeformed end rings.
				if baseline_mid_span <= 0.0 or deformed_mid_span >= baseline_mid_span * 0.97:
					failures.append("CRUMPLE_PRESENTATION_RED: mid crumple must visibly compress the cup waist")
				if deformed.size.x <= baseline.size.x * 0.55 or deformed.size.y <= baseline.size.y * 0.70:
					failures.append("CRUMPLE_PRESENTATION_RED: bounded crumple must not numerically collapse/invert cup shell")
				if not is_finite(deformed.size.x) or not is_finite(deformed.size.y) or not is_finite(deformed.size.z):
					failures.append("CRUMPLE_PRESENTATION_RED: deformed cup bounds must stay finite")
				presentation.set_crumple(1.0, 1, 1.0)
				await process_frame
				var full := shell.mesh.get_aabb()
				if full.size.x <= 0.20 or full.size.y <= 0.70:
					failures.append("CRUMPLE_PRESENTATION_RED: full crumple must remain a bounded cup-like shell")
				presentation.reset_visual()
				await process_frame
				if shell.visible or (cup != null and not cup.visible):
					failures.append("CRUMPLE_PRESENTATION_RED: reset must restore production Cup visibility")

	if failures.is_empty():
		print("PASS: cup crumple presentation is bounded, resettable and presentation-only")
		scene.queue_free()
		await process_frame
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _mid_ring_x_span(mesh: ArrayMesh) -> float:
	if mesh == null or mesh.get_surface_count() == 0:
		return 0.0
	var arrays := mesh.surface_get_arrays(0)
	var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var start := TEST_MID_RING * TEST_SEGMENTS
	if vertices.size() < start + TEST_SEGMENTS:
		return 0.0
	var min_x := INF
	var max_x := -INF
	for i in range(start, start + TEST_SEGMENTS):
		min_x = minf(min_x, vertices[i].x)
		max_x = maxf(max_x, vertices[i].x)
	return max_x - min_x
