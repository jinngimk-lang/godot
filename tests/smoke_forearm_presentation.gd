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
		var near := hand.get_node_or_null("ForearmNear") as MeshInstance3D
		var elbow := hand.get_node_or_null("SleeveElbow") as MeshInstance3D
		var far := hand.get_node_or_null("ForearmSleeve") as MeshInstance3D
		if near == null or not (near.mesh is CylinderMesh):
			failures.append("FOREARM_RED: %s missing bounded ForearmNear" % hand_name)
		if elbow == null or elbow.mesh == null:
			failures.append("FOREARM_RED: %s missing SleeveElbow seam cover" % hand_name)
		if far == null or not (far.mesh is CylinderMesh):
			failures.append("FOREARM_RED: %s missing second ForearmSleeve segment" % hand_name)
		else:
			if far.material_override == null or far.material_override.resource_name != "SleeveFabric":
				failures.append("%s ForearmSleeve must reuse SleeveFabric" % hand_name)
			if hand_name == "RightHand" and far.position.x >= -0.05:
				failures.append("FOREARM_RED: dynamic right forearm must bend toward screen-left exit")
			if hand_name == "LeftHand" and far.position.x <= 0.05:
				failures.append("FOREARM_RED: support left forearm must bend toward screen-right exit")
			var far_mesh := far.mesh as CylinderMesh
			if far_mesh.height < 0.45 or far_mesh.height > 1.30:
				failures.append("%s far forearm segment length outside presentation bounds" % hand_name)
		if near != null and near.mesh is CylinderMesh:
			var near_mesh := near.mesh as CylinderMesh
			if near_mesh.height < 0.22 or near_mesh.height > 0.80:
				failures.append("%s near forearm segment length outside presentation bounds" % hand_name)

	if failures.is_empty():
		print("PASS: two-segment authored forearms bend outward with bounded geometry")
		scene.queue_free()
		await process_frame
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
