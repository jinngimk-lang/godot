extends RefCounted

const RIGHT_PATH := "res://assets/models/hands/hand_right.glb"
const LEFT_PATH := "res://assets/models/hands/hand_left.glb"

func run() -> Array[String]:
	var failures: Array[String] = []
	for path in [LEFT_PATH, RIGHT_PATH]:
		if not ResourceLoader.exists(path):
			failures.append("authored hand GLB missing: %s" % path)
			continue
		var packed = load(path)
		if packed == null or not (packed is PackedScene):
			failures.append("authored hand GLB did not import as PackedScene: %s" % path)
			continue
		var instance = packed.instantiate()
		if _find_first(instance, "Skeleton3D") == null:
			failures.append("authored hand must contain Skeleton3D: %s" % path)
		var animation_player = _find_first(instance, "AnimationPlayer")
		if animation_player == null:
			failures.append("authored hand must contain AnimationPlayer: %s" % path)
		else:
			var names: PackedStringArray = animation_player.get_animation_list()
			if not names.has("Pinch Tight"):
				failures.append("authored hand missing Pinch Tight animation: %s" % path)
			if not names.has("Cup"):
				failures.append("authored hand missing Cup animation: %s" % path)
		var vertex_count := _renderable_vertex_count(instance)
		if vertex_count <= 0:
			failures.append("authored hand must contain a non-empty renderable mesh: %s" % path)
		var material_names := _material_names(instance)
		if not material_names.has("HandSkin"):
			failures.append("authored hand missing semantic skin material HandSkin: %s" % path)
		if not material_names.has("HandNail"):
			failures.append("authored hand missing semantic nail material HandNail: %s" % path)
		_print_skin_surface_diagnostics(path, instance)
		instance.free()

	var hand_script = load("res://scripts/hands/hand_visual.gd")
	if hand_script == null:
		failures.append("HandVisual script did not load")
		return failures
	var methods: Array[String] = []
	for method in hand_script.get_script_method_list():
		methods.append(String(method.get("name", "")))
	if not methods.has("is_using_authored_asset"):
		failures.append("RED: HandVisual does not expose authored-hand runtime contract")
		return failures

	var hand = hand_script.new()
	hand.setup(true)
	if not hand.is_using_authored_asset():
		failures.append("HandVisual should prefer repository-local authored GLB")
	hand.free()
	return failures

func _print_skin_surface_diagnostics(path: String, node: Node) -> void:
	var totals := {
		"surfaces":0,
		"vertices":0,
		"triangles":0,
		"flat_triangles":0,
		"duplicate_groups":0,
		"hard_duplicate_groups":0,
	}
	var material_lines: Array[String] = []
	_collect_skin_diagnostics(node, totals, material_lines)
	var flat_ratio := 0.0
	if int(totals.triangles) > 0:
		flat_ratio = float(totals.flat_triangles)/float(totals.triangles)
	var hard_ratio := 0.0
	if int(totals.duplicate_groups) > 0:
		hard_ratio = float(totals.hard_duplicate_groups)/float(totals.duplicate_groups)
	print("HAND_SURFACE_DIAG path=%s skin_surfaces=%d vertices=%d triangles=%d face_aligned_triangles=%d flat_ratio=%.4f duplicate_position_groups=%d hard_normal_groups=%d hard_group_ratio=%.4f materials=[%s]" % [
		path,
		int(totals.surfaces),
		int(totals.vertices),
		int(totals.triangles),
		int(totals.flat_triangles),
		flat_ratio,
		int(totals.duplicate_groups),
		int(totals.hard_duplicate_groups),
		hard_ratio,
		"; ".join(material_lines),
	])

func _collect_skin_diagnostics(node: Node, totals: Dictionary, material_lines: Array[String]) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		var mesh: Mesh = mesh_instance.mesh
		if mesh != null:
			for surface_index in range(mesh.get_surface_count()):
				var material := mesh.surface_get_material(surface_index)
				if material == null or material.resource_name != "HandSkin":
					continue
				totals.surfaces = int(totals.surfaces)+1
				if material is BaseMaterial3D:
					var base := material as BaseMaterial3D
					material_lines.append("%s rough=%.3f metallic=%.3f specular=%.3f" % [mesh_instance.name,base.roughness,base.metallic,base.metallic_specular])
				else:
					material_lines.append("%s class=%s" % [mesh_instance.name,material.get_class()])
				_accumulate_surface(mesh, surface_index, totals)
	for child in node.get_children():
		_collect_skin_diagnostics(child, totals, material_lines)

func _accumulate_surface(mesh: Mesh, surface_index: int, totals: Dictionary) -> void:
	var arrays: Array = mesh.surface_get_arrays(surface_index)
	if arrays.size() <= Mesh.ARRAY_NORMAL:
		return
	var vertex_variant: Variant = arrays[Mesh.ARRAY_VERTEX]
	var normal_variant: Variant = arrays[Mesh.ARRAY_NORMAL]
	if not (vertex_variant is PackedVector3Array) or not (normal_variant is PackedVector3Array):
		return
	var vertices := vertex_variant as PackedVector3Array
	var normals := normal_variant as PackedVector3Array
	if vertices.is_empty() or normals.size() != vertices.size():
		return
	totals.vertices = int(totals.vertices)+vertices.size()

	var index_variant: Variant = arrays[Mesh.ARRAY_INDEX] if arrays.size() > Mesh.ARRAY_INDEX else null
	var indices := PackedInt32Array()
	if index_variant is PackedInt32Array:
		indices = index_variant as PackedInt32Array
	var index_count := indices.size() if not indices.is_empty() else vertices.size()
	var triangle_count := index_count/3
	totals.triangles = int(totals.triangles)+triangle_count
	for triangle_index in range(triangle_count):
		var i0 := indices[triangle_index*3] if not indices.is_empty() else triangle_index*3
		var i1 := indices[triangle_index*3+1] if not indices.is_empty() else triangle_index*3+1
		var i2 := indices[triangle_index*3+2] if not indices.is_empty() else triangle_index*3+2
		if i0 < 0 or i1 < 0 or i2 < 0 or i0 >= vertices.size() or i1 >= vertices.size() or i2 >= vertices.size():
			continue
		var face := (vertices[i1]-vertices[i0]).cross(vertices[i2]-vertices[i0])
		if face.length_squared() <= 0.0000000001:
			continue
		face = face.normalized()
		var d0 := absf(face.dot(normals[i0].normalized()))
		var d1 := absf(face.dot(normals[i1].normalized()))
		var d2 := absf(face.dot(normals[i2].normalized()))
		if minf(d0,minf(d1,d2)) >= 0.997:
			totals.flat_triangles = int(totals.flat_triangles)+1

	var normal_groups: Dictionary = {}
	for i in range(vertices.size()):
		var v := vertices[i]
		var key := "%d,%d,%d" % [roundi(v.x*100000.0),roundi(v.y*100000.0),roundi(v.z*100000.0)]
		if not normal_groups.has(key):
			normal_groups[key] = []
		(normal_groups[key] as Array).append(normals[i].normalized())
	for key in normal_groups.keys():
		var group := normal_groups[key] as Array
		if group.size() < 2:
			continue
		totals.duplicate_groups = int(totals.duplicate_groups)+1
		var hard := false
		for a in range(group.size()):
			for b in range(a+1,group.size()):
				if (group[a] as Vector3).dot(group[b] as Vector3) < 0.94:
					hard = true
					break
			if hard:
				break
		if hard:
			totals.hard_duplicate_groups = int(totals.hard_duplicate_groups)+1

func _renderable_vertex_count(node: Node) -> int:
	var count := 0
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		var mesh: Mesh = mesh_instance.mesh
		if mesh != null:
			for surface_index in range(mesh.get_surface_count()):
				var arrays: Array = mesh.surface_get_arrays(surface_index)
				if arrays.size() <= Mesh.ARRAY_VERTEX:
					continue
				var vertices: Variant = arrays[Mesh.ARRAY_VERTEX]
				if vertices is PackedVector3Array:
					count += (vertices as PackedVector3Array).size()
	for child in node.get_children():
		count += _renderable_vertex_count(child)
	return count

func _material_names(node: Node) -> Array[String]:
	var names: Array[String] = []
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		var mesh: Mesh = mesh_instance.mesh
		if mesh != null:
			for surface_index in range(mesh.get_surface_count()):
				var material := mesh.surface_get_material(surface_index)
				if material != null and not material.resource_name.is_empty() and not names.has(material.resource_name):
					names.append(material.resource_name)
	for child in node.get_children():
		for material_name in _material_names(child):
			if not names.has(material_name):
				names.append(material_name)
	return names

func _find_first(node: Node, class_name_text: String) -> Node:
	if node.get_class() == class_name_text:
		return node
	for child in node.get_children():
		var found := _find_first(child, class_name_text)
		if found != null:
			return found
	return null
