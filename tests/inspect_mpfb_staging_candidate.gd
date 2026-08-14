extends SceneTree

const SUPPORT := "res://assets/generated_staging/mpfb-right-support-wrap-v31.glb"
const PINCH := "res://assets/generated_staging/mpfb-right-label-pinch-v31.glb"

func _initialize() -> void:
	var failures: Array[String] = []
	_check_candidate(SUPPORT, "SupportWrapV31", failures)
	_check_candidate(PINCH, "LabelPinchV31", failures)
	if failures.is_empty():
		print("MPFB_GODOT_STAGING_IMPORT_V31_SUCCESS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_candidate(path: String, expected_animation: String, failures: Array[String]) -> void:
	if not ResourceLoader.exists(path):
		failures.append("missing generated staging candidate: %s" % path)
		return
	var packed = load(path)
	if packed == null or not (packed is PackedScene):
		failures.append("candidate did not import as PackedScene: %s" % path)
		return
	var root = packed.instantiate()
	if root == null:
		failures.append("candidate could not instantiate: %s" % path)
		return
	var skeleton := _find_first(root, "Skeleton3D") as Skeleton3D
	if skeleton == null:
		failures.append("candidate missing Skeleton3D: %s" % path)
	elif skeleton.get_bone_count() < 20:
		failures.append("candidate skeleton unexpectedly small (%d bones): %s" % [skeleton.get_bone_count(), path])
	var player := _find_first(root, "AnimationPlayer") as AnimationPlayer
	if player == null:
		failures.append("candidate missing AnimationPlayer: %s" % path)
	elif not player.has_animation(expected_animation):
		failures.append("candidate missing baked pose animation %s: %s" % [expected_animation, path])
	var stats := _mesh_stats(root)
	if stats[0] <= 0 or stats[1] <= 0:
		failures.append("candidate has no renderable mesh vertices: %s" % path)
	if stats[0] > 120000:
		failures.append("candidate exceeds staging vertex budget (%d): %s" % [stats[0], path])
	print("MPFB_GODOT_CANDIDATE", path, " vertices=", stats[0], " meshes=", stats[1], " bones=", skeleton.get_bone_count() if skeleton != null else -1)
	root.free()

func _mesh_stats(node: Node) -> Array[int]:
	var vertices := 0
	var meshes := 0
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			meshes += 1
			for surface_index in range(mi.mesh.get_surface_count()):
				var arrays := mi.mesh.surface_get_arrays(surface_index)
				if arrays.size() > Mesh.ARRAY_VERTEX and arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array:
					vertices += (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	for child in node.get_children():
		var child_stats := _mesh_stats(child)
		vertices += child_stats[0]
		meshes += child_stats[1]
	return [vertices, meshes]

func _find_first(node: Node, class_name_text: String) -> Node:
	if node.get_class() == class_name_text:
		return node
	for child in node.get_children():
		var found := _find_first(child, class_name_text)
		if found != null:
			return found
	return null
