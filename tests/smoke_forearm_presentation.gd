extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("FOREARM_RED: peel lab scene failed to load")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame

	var failures: Array[String] = []
	var presentation := scene.get_node_or_null("ForearmPresentation") as Node3D
	if presentation == null:
		failures.append("FOREARM_RED: missing ForearmPresentation runtime layer")

	for hand_name in ["RightHand", "LeftHand"]:
		var hand := scene.get_node_or_null(hand_name) as Node3D
		if hand == null:
			failures.append("FOREARM_RED: missing %s" % hand_name)
			continue

		# The first real two-segment render proved that separate cylinders plus a
		# sphere elbow read as a mechanical/puppet joint. The accepted runtime
		# contract is now one continuous curved ArrayMesh tube with no visible
		# ForearmNear/SleeveElbow seam geometry.
		if hand.get_node_or_null("ForearmNear") != null:
			failures.append("FOREARM_RED: %s must not use a separate rigid ForearmNear segment" % hand_name)
		if hand.get_node_or_null("SleeveElbow") != null:
			failures.append("FOREARM_RED: %s must not use a separate spherical SleeveElbow joint" % hand_name)

		var forearm := hand.get_node_or_null("ForearmSleeve") as MeshInstance3D
		var exit_marker := hand.get_node_or_null("ForearmExit") as Node3D
		if forearm == null or not (forearm.mesh is ArrayMesh):
			failures.append("FOREARM_RED: %s must use one continuous ArrayMesh ForearmSleeve" % hand_name)
		else:
			if forearm.material_override == null or forearm.material_override.resource_name != "SleeveFabric":
				failures.append("%s ForearmSleeve must reuse SleeveFabric" % hand_name)
			var mesh := forearm.mesh as ArrayMesh
			if mesh.get_surface_count() != 1:
				failures.append("%s continuous forearm should have one connected render surface" % hand_name)
			else:
				var arrays := mesh.surface_get_arrays(0)
				var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
				if vertices.size() < 120:
					failures.append("FOREARM_RED: %s continuous forearm needs enough curve rings to avoid a faceted rod" % hand_name)
		if exit_marker == null:
			failures.append("FOREARM_RED: %s missing ForearmExit curve endpoint" % hand_name)
		else:
			if hand_name == "RightHand" and exit_marker.position.x >= -0.30:
				failures.append("FOREARM_RED: dynamic right forearm curve must exit toward screen-left")
			if hand_name == "LeftHand" and exit_marker.position.x <= 0.30:
				failures.append("FOREARM_RED: support left forearm curve must exit toward screen-right")
			if exit_marker.position.length() < 1.20 or exit_marker.position.length() > 2.20:
				failures.append("%s ForearmExit must remain in a bounded offscreen presentation range" % hand_name)

	if failures.is_empty():
		print("PASS: continuous curved authored forearms exit outward without rigid elbow seams")
		scene.queue_free()
		await process_frame
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
