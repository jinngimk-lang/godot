extends RefCounted

const MAX_CONTACT_GAP := 0.045

func run() -> Array[String]:
	var failures: Array[String] = []
	var root := Node3D.new()

	var cup := MeshInstance3D.new()
	cup.name = "Cup"
	var cup_mesh := CylinderMesh.new()
	cup_mesh.top_radius = 0.54
	cup_mesh.bottom_radius = 0.45
	cup_mesh.height = 1.48
	cup.mesh = cup_mesh
	cup.position = Vector3(0.0, 0.05, 0.0)
	root.add_child(cup)

	var lid := MeshInstance3D.new()
	lid.name = "Lid"
	var lid_mesh := CylinderMesh.new()
	lid_mesh.top_radius = 0.57
	lid_mesh.bottom_radius = 0.56
	lid_mesh.height = 0.08
	lid.mesh = lid_mesh
	lid.position = Vector3(0.0, 0.83, 0.0)
	root.add_child(lid)

	var support := HandVisual.new()
	support.name = "LeftHand"
	root.add_child(support)
	support.setup(false)
	support.snap_to(Vector3(0.60, 0.22, 0.40))
	support.rotation_degrees = Vector3(14.0, 42.0, 45.0)

	var peel := HandVisual.new()
	peel.name = "RightHand"
	root.add_child(peel)
	peel.setup(true)
	peel.snap_to(Vector3(-0.72, 0.28, 0.88))
	peel.rotation_degrees = Vector3(18.0, -22.0, -8.0)
	peel.set_pinch_amount(1.0)
	peel.set("_pinch_amount", 1.0)
	peel.call("_apply_pose")
	peel.call("_refresh_pinch_anchors")

	var source := CupCrumplePresentation.new()
	source.name = "CupCrumplePresentation"
	root.add_child(source)
	source.set_profile({
		"post_peel_action": "crumple",
		"cup_shell": "paper",
		"cup_dimensions": {"top_radius": 0.54, "bottom_radius": 0.45, "height": 1.48},
		"crumple_profile": {"max_compression": 0.22}
	})

	var staging := CrumpleHandStaging.new()
	staging.name = "CrumpleHandStaging"
	root.add_child(staging)

	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		root.free()
		return ["RED: crumple hand contact test requires the live SceneTree transform path"]
	tree.root.add_child(root)
	source.call("_bind_cup")
	staging.call("_bind")
	source.set_crumple(0.0, -1, 0.0)

	var support_home := support.position
	var peel_home := peel.position
	source.set_crumple(0.60, -1, 0.70)
	var shell := source.get_node_or_null("CrumpledCup") as MeshInstance3D
	if shell == null or not (shell.mesh is ArrayMesh):
		failures.append("RED: crumple hand contact needs the real deformed cup shell")
	else:
		var support_gap := _surface_gap(shell, support.get_pinch_world_position())
		var peel_gap := _surface_gap(shell, peel.get_pinch_world_position())
		if support_gap > MAX_CONTACT_GAP:
			failures.append("RED: support hand must stay in visible contact with the crumpled cup; gap=%.3f" % support_gap)
		if peel_gap > MAX_CONTACT_GAP:
			failures.append("RED: released peel hand must join the squeeze instead of hovering beside the crumpled cup; gap=%.3f" % peel_gap)

	source.reset_visual()
	if not support.position.is_equal_approx(support_home):
		failures.append("RED: crumple reset must restore the exact support-hand root")
	if not peel.position.is_equal_approx(peel_home):
		failures.append("RED: crumple reset must restore the exact peel-hand root")

	root.free()
	return failures

func _surface_gap(shell: MeshInstance3D, world_point: Vector3) -> float:
	if shell == null or shell.mesh == null or shell.mesh.get_surface_count() == 0:
		return INF
	var arrays := shell.mesh.surface_get_arrays(0)
	var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	if vertices.is_empty():
		return INF
	var best := INF
	for vertex in vertices:
		best = minf(best, world_point.distance_to(shell.to_global(vertex)))
	return best