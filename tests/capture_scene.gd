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
		var aabb := mesh_instance.mesh.get_aabb()
		var world_center := mesh_instance.to_global(aabb.get_center())
		print("MESH_AABB %s node=%s local_pos=%s local_size=%s world_center=%s" % [hand_name, mesh_instance.name, str(aabb.position), str(aabb.size), str(world_center)])
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
		hand_name, str(authored), str(hand.global_position), str(hand.rotation_degrees), str(hand.scale), meshes.size(), total_vertices, max_local_extent, str(pinch), str(screen), str(behind)
	])
	var authored_root := hand.get_node_or_null("AuthoredHand") as Node3D
	if authored_root != null and camera != null:
		var origin_world := authored_root.to_global(Vector3.ZERO)
		var origin_screen := camera.unproject_position(origin_world)
		for axis_info in [
			["X", Vector3(0.16, 0.0, 0.0)],
			["Y", Vector3(0.0, 0.16, 0.0)],
			["Z", Vector3(0.0, 0.0, 0.16)]
		]:
			var axis_name := String(axis_info[0])
			var axis_point := axis_info[1] as Vector3
			var axis_world := authored_root.to_global(axis_point)
			var axis_screen := camera.unproject_position(axis_world)
			print("AXIS_DIAG %s %s origin=%s end=%s delta=%s world_delta=%s" % [
				hand_name, axis_name, str(origin_screen), str(axis_screen), str(axis_screen - origin_screen), str(axis_world - origin_world)
			])
	var skeleton := _find_skeleton(hand)
	if skeleton != null:
		for bone_id in range(skeleton.get_bone_count()):
			var bone_name := skeleton.get_bone_name(bone_id)
			var lower := bone_name.to_lower()
			if lower.contains("wrist") or lower.contains("hand") or lower.contains("forearm") or lower.contains("arm"):
				var pose := skeleton.get_bone_global_pose(bone_id)
				var world_origin := skeleton.to_global(pose.origin)
				print("BONE_DIAG %s id=%d name=%s parent=%d local=%s world=%s" % [hand_name, bone_id, bone_name, skeleton.get_bone_parent(bone_id), str(pose.origin), str(world_origin)])

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null

func _collect_meshes(node: Node, output: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		output.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_meshes(child, output)
