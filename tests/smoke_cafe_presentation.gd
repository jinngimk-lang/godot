extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("CAFE_RED: peel lab scene failed to load")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame

	var failures: Array[String] = []
	var presentation := scene.get_node_or_null("CafePresentation") as Node3D
	if presentation == null:
		failures.append("CAFE_RED: missing CafePresentation")
	else:
		var backdrop := presentation.get_node_or_null("Backdrop") as MeshInstance3D
		if backdrop == null or not (backdrop.mesh is BoxMesh):
			failures.append("CAFE_RED: missing BoxMesh backdrop")
		else:
			var wall := backdrop.mesh as BoxMesh
			if wall.size.x < 7.5:
				failures.append("CAFE_RED: backdrop must cover wide viewport without black side gutters")
		var ground_shadow := presentation.get_node_or_null("GroundShadow") as MeshInstance3D
		if ground_shadow == null or ground_shadow.mesh == null or ground_shadow.material_override == null:
			failures.append("CAFE_RED: missing soft cup GroundShadow")

	var key := scene.get_node_or_null("KeyLight") as DirectionalLight3D
	if key == null:
		failures.append("CAFE_RED: missing KeyLight")
	elif key.shadow_enabled:
		failures.append("CAFE_RED: hard directional shadows should be disabled in calm close-up presentation")

	if failures.is_empty():
		print("PASS: cafe backdrop coverage, soft grounding and shadow policy")
		scene.queue_free()
		await process_frame
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
