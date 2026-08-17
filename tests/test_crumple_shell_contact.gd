extends RefCounted

const MAX_VISIBLE_CONTACT_GAP := 0.045

func run(tree: SceneTree) -> Array[String]:
	var failures: Array[String] = []
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if tree == null or packed == null:
		failures.append("RED: crumple contact test requires the live PeelLab scene tree")
		return failures

	var scene := packed.instantiate() as Node3D
	tree.root.add_child(scene)

	var source := scene.get_node_or_null("CupCrumplePresentation") as CupCrumplePresentation
	var staging := scene.get_node_or_null("CrumpleHandStaging") as CrumpleHandStaging
	var support := scene.get_node_or_null("LeftHand") as HandVisual
	var peel := scene.get_node_or_null("RightHand") as HandVisual
	if source == null or staging == null or support == null or peel == null:
		failures.append("RED: live Café crumple contact test is missing presentation or hand nodes")
		_cleanup(tree, scene)
		return failures

	# Bind after the production PeelLab has built and positioned both authored
	# hands. This keeps world transforms valid and tests the same presentation
	# ownership used by the runtime scene rather than an off-tree fixture.
	staging._bind()
	var support_home := support.position
	var peel_home := peel.position
	source.set_crumple(0.55, -1, 0.45)

	var shell := source.get_node_or_null("CrumpledCup") as MeshInstance3D
	if shell == null or not shell.visible or not (shell.mesh is ArrayMesh):
		failures.append("RED: 55% Café crumple must expose the rendered CrumpledCup shell")
	else:
		var support_gap := _nearest_shell_vertex_gap(shell, support.get_pinch_world_position())
		var peel_gap := _nearest_shell_vertex_gap(shell, peel.get_pinch_world_position())
		if support_gap > MAX_VISIBLE_CONTACT_GAP:
			failures.append("RED: support pinch anchor must contact rendered crumpled shell (%.4f m > %.3f m)" % [support_gap, MAX_VISIBLE_CONTACT_GAP])
		if peel_gap > MAX_VISIBLE_CONTACT_GAP:
			failures.append("RED: released peel pinch anchor must contact rendered crumpled shell (%.4f m > %.3f m)" % [peel_gap, MAX_VISIBLE_CONTACT_GAP])

	staging.reset_staging()
	if not support.position.is_equal_approx(support_home):
		failures.append("crumple shell contact reset must restore support-hand root exactly")
	if not peel.position.is_equal_approx(peel_home):
		failures.append("crumple shell contact reset must restore peel-hand root exactly")

	_cleanup(tree, scene)
	return failures

func _nearest_shell_vertex_gap(shell: MeshInstance3D, world_point: Vector3) -> float:
	var mesh := shell.mesh as ArrayMesh
	if mesh == null or mesh.get_surface_count() == 0:
		return INF
	var arrays := mesh.surface_get_arrays(0)
	var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	if vertices.is_empty():
		return INF
	var best := INF
	for vertex in vertices:
		best = minf(best, shell.to_global(vertex).distance_to(world_point))
	return best

func _cleanup(tree: SceneTree, scene: Node3D) -> void:
	if scene.get_parent() == tree.root:
		tree.root.remove_child(scene)
	scene.free()
