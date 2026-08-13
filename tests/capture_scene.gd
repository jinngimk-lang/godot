extends SceneTree

const OUTPUT_NAME := "peel_scene.png"

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("CAPTURE: peel_lab scene failed to load")
		quit(1)
		return

	var scene := packed.instantiate()
	root.add_child(scene)

	# Let imported GLBs, SubViewport label print, lighting and the first rendered
	# frames settle before reading the viewport texture.
	for _frame in range(24):
		await process_frame

	_print_hand_diagnostics(scene, "LeftHand")
	_print_hand_diagnostics(scene, "RightHand")

	var texture := root.get_texture()
	if texture == null:
		push_error("CAPTURE: root viewport has no texture")
		quit(1)
		return
	var image := texture.get_image()
	if image == null or image.is_empty():
		push_error("CAPTURE: viewport image is empty")
		quit(1)
		return

	var workspace := OS.get_environment("GITHUB_WORKSPACE")
	var output_dir := workspace.path_join("artifacts") if not workspace.is_empty() else ProjectSettings.globalize_path("user://visual-artifacts")
	var mkdir_error := DirAccess.make_dir_recursive_absolute(output_dir)
	if mkdir_error != OK:
		push_error("CAPTURE: cannot create output directory: %s" % error_string(mkdir_error))
		quit(1)
		return
	var output_path := output_dir.path_join(OUTPUT_NAME)
	var save_error := image.save_png(output_path)
	if save_error != OK:
		push_error("CAPTURE: failed to save PNG: %s" % error_string(save_error))
		quit(1)
		return

	print("CAPTURE_OK: %s %dx%d" % [output_path, image.get_width(), image.get_height()])
	scene.queue_free()
	await process_frame
	quit(0)

func _print_hand_diagnostics(scene: Node, hand_name: String) -> void:
	var hand := scene.get_node_or_null(hand_name) as Node3D
	if hand == null:
		print("HAND_DIAG %s missing" % hand_name)
		return
	var camera := scene.get_node_or_null("Camera") as Camera3D
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(hand, meshes)
	var total_vertices := 0
	var max_local_extent := 0.0
	for mesh_instance in meshes:
		if mesh_instance.mesh == null:
			continue
		for surface_index in range(mesh_instance.mesh.get_surface_count()):
			var arrays := mesh_instance.mesh.surface_get_arrays(surface_index)
			if arrays.size() > Mesh.ARRAY_VERTEX:
				var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
				total_vertices += vertices.size()
		var local_size: Vector3 = mesh_instance.mesh.get_aabb().size * mesh_instance.global_transform.basis.get_scale().abs()
		max_local_extent = maxf(max_local_extent, maxf(local_size.x, maxf(local_size.y, local_size.z)))
	var pinch: Vector3 = hand.global_position
	if hand.has_method("get_pinch_world_position"):
		pinch = hand.call("get_pinch_world_position") as Vector3
	var authored := false
	if hand.has_method("is_using_authored_asset"):
		authored = bool(hand.call("is_using_authored_asset"))
	var screen := Vector2.ZERO
	var behind := false
	if camera != null:
		screen = camera.unproject_position(pinch)
		behind = camera.is_position_behind(pinch)
	print("HAND_DIAG %s authored=%s root=%s rot=%s scale=%s meshes=%d vertices=%d max_extent=%.5f pinch=%s screen=%s behind=%s" % [
		hand_name,
		str(authored),
		str(hand.global_position),
		str(hand.rotation_degrees),
		str(hand.scale),
		meshes.size(),
		total_vertices,
		max_local_extent,
		str(pinch),
		str(screen),
		str(behind)
	])

func _collect_meshes(node: Node, output: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		output.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_meshes(child, output)
