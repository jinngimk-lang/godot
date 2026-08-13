extends SceneTree

const MAX_ALLOWED_PENETRATION := 0.005

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("FOREARM_CLEARANCE: peel lab scene failed to load")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame

	var cup := scene.get_node_or_null("Cup") as MeshInstance3D
	var label := scene.get_node_or_null("PeelLabel") as LabelVisual
	var right_hand := scene.get_node_or_null("RightHand") as HandVisual
	if cup == null or label == null or right_hand == null or not (cup.mesh is CylinderMesh):
		push_error("FOREARM_CLEARANCE: production Cup/PeelLabel/RightHand contract missing")
		quit(1)
		return

	var fresh_penetration := _max_forearm_penetration(scene, cup)
	if fresh_penetration > MAX_ALLOWED_PENETRATION:
		push_error("FOREARM_RED: fresh forearm enters cup volume by %.5f m" % fresh_penetration)
		quit(1)
		return

	# Freeze PeelLab gameplay updates so this verifier can drive the real dynamic
	# HandVisual through a deliberately extreme desired pull. The label's public
	# grip resolver limits that request to the physically represented free length.
	scene.set_process(false)
	var progress := 0.78
	var front := label.get_front_position(progress)
	var desired := front + Vector3(-1.8, 0.65, 1.45)
	var effective := label.get_effective_grip(progress, desired)
	if effective.distance_to(desired) < 0.25:
		push_error("FOREARM_CLEARANCE: verifier did not exercise bounded strong-pull grip")
		quit(1)
		return
	right_hand.set_pinch_amount(1.0)
	right_hand.set_grip_target(label.to_global(effective))
	for i in range(24):
		right_hand.tick(0.1)

	var pulled_penetration := _max_forearm_penetration(scene, cup)
	if pulled_penetration > MAX_ALLOWED_PENETRATION:
		push_error("FOREARM_RED: bounded strong-pull pose drives forearm into cup volume by %.5f m" % pulled_penetration)
		quit(1)
		return

	var forearm := right_hand.get_node_or_null("ForearmSleeve") as MeshInstance3D
	if forearm == null or forearm.mesh == null:
		push_error("FOREARM_CLEARANCE: dynamic ForearmSleeve missing after pull")
		quit(1)
		return
	var extent := forearm.mesh.get_aabb().size.length()
	if extent > 1.90:
		push_error("FOREARM_RED: dynamic forearm local mesh stretched under hand motion: %.5f m" % extent)
		quit(1)
		return

	print("PASS: curved forearms clear cup in fresh and bounded strong-pull poses; penetration=%.6f/%.6f extent=%.6f" % [fresh_penetration, pulled_penetration, extent])
	scene.queue_free()
	await process_frame
	quit(0)

func _max_forearm_penetration(scene: Node, cup: MeshInstance3D) -> float:
	var cup_mesh := cup.mesh as CylinderMesh
	var height := maxf(cup_mesh.height, 0.001)
	var max_penetration := 0.0
	for hand_name in ["RightHand", "LeftHand"]:
		var hand := scene.get_node_or_null(hand_name) as Node3D
		if hand == null:
			continue
		var forearm := hand.get_node_or_null("ForearmSleeve") as MeshInstance3D
		if forearm == null or not (forearm.mesh is ArrayMesh):
			continue
		var mesh := forearm.mesh as ArrayMesh
		if mesh.get_surface_count() == 0:
			continue
		var arrays := mesh.surface_get_arrays(0)
		if arrays.size() <= Mesh.ARRAY_VERTEX or not (arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array):
			continue
		var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
		for vertex in vertices:
			var cup_local := cup.to_local(forearm.to_global(vertex))
			if cup_local.y < -height * 0.5 or cup_local.y > height * 0.5:
				continue
			var t := clampf((cup_local.y + height * 0.5) / height, 0.0, 1.0)
			var radius := lerpf(cup_mesh.bottom_radius, cup_mesh.top_radius, t)
			var radial := Vector2(cup_local.x, cup_local.z).length()
			max_penetration = maxf(max_penetration, radius - radial)
	return max_penetration
