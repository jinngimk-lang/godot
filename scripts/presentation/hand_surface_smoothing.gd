extends Node
class_name HandSurfaceSmoothing

const HAND_NAMES := ["RightHand", "LeftHand"]
const POSITION_QUANTIZATION := 100000.0

var _smoothed_mesh_count := 0

func _ready() -> void:
	call_deferred("_apply")

func get_smoothed_mesh_count() -> int:
	return _smoothed_mesh_count

func _apply() -> void:
	var root := get_parent()
	if root == null:
		return
	_smoothed_mesh_count = 0
	for hand_name in HAND_NAMES:
		var authored := root.get_node_or_null("%s/AuthoredHand" % hand_name) as Node3D
		if authored != null:
			_smooth_descendants(authored)

func _smooth_descendants(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.visible and mesh_instance.mesh != null and not mesh_instance.has_meta("peel_calm_smoothed_normals"):
			var replacement := smooth_mesh(mesh_instance.mesh)
			if replacement != null and replacement != mesh_instance.mesh:
				mesh_instance.mesh = replacement
				mesh_instance.set_meta("peel_calm_smoothed_normals",true)
				_smoothed_mesh_count += 1
	for child in node.get_children():
		_smooth_descendants(child)

func smooth_mesh(source: Mesh) -> Mesh:
	if source == null or source.get_surface_count() <= 0:
		return source
	# The authored XR hands use skeletal skinning and no morph targets. If a
	# future replacement adds blend shapes, keep that asset untouched instead
	# of silently dropping its deformation data.
	if source.get_blend_shape_count() > 0:
		return source
	var result := ArrayMesh.new()
	for surface_index in range(source.get_surface_count()):
		var arrays: Array = source.surface_get_arrays(surface_index)
		if arrays.size() != Mesh.ARRAY_MAX:
			return source
		var primitive := source.surface_get_primitive_type(surface_index)
		if primitive == Mesh.PRIMITIVE_TRIANGLES:
			arrays[Mesh.ARRAY_NORMAL] = _build_smooth_normals(arrays)
		result.add_surface_from_arrays(primitive,arrays)
		var material := source.surface_get_material(surface_index)
		if material != null:
			result.surface_set_material(surface_index,material)
		result.surface_set_name(surface_index,source.surface_get_name(surface_index))
	result.resource_name = "%s Smooth" % source.resource_name
	return result

func _build_smooth_normals(arrays: Array) -> PackedVector3Array:
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	if vertices.is_empty():
		return normals
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var group_accum: Dictionary = {}
	if not indices.is_empty():
		var triangle_count := indices.size() / 3
		for triangle_index in range(triangle_count):
			var ia := indices[triangle_index*3]
			var ib := indices[triangle_index*3+1]
			var ic := indices[triangle_index*3+2]
			if ia < 0 or ib < 0 or ic < 0 or ia >= vertices.size() or ib >= vertices.size() or ic >= vertices.size():
				continue
			var face := (vertices[ib]-vertices[ia]).cross(vertices[ic]-vertices[ia])
			if face.length_squared() <= 0.0000000001:
				continue
			_accumulate_group(group_accum,_position_key(vertices[ia]),face)
			_accumulate_group(group_accum,_position_key(vertices[ib]),face)
			_accumulate_group(group_accum,_position_key(vertices[ic]),face)
	else:
		var triangle_count := vertices.size() / 3
		for triangle_index in range(triangle_count):
			var ia := triangle_index*3
			var ib := ia+1
			var ic := ia+2
			var face := (vertices[ib]-vertices[ia]).cross(vertices[ic]-vertices[ia])
			if face.length_squared() <= 0.0000000001:
				continue
			_accumulate_group(group_accum,_position_key(vertices[ia]),face)
			_accumulate_group(group_accum,_position_key(vertices[ib]),face)
			_accumulate_group(group_accum,_position_key(vertices[ic]),face)
	var source_normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	for i in range(vertices.size()):
		var key := _position_key(vertices[i])
		var accumulated: Vector3 = group_accum.get(key,Vector3.ZERO)
		if accumulated.length_squared() > 0.0000000001:
			normals[i] = accumulated.normalized()
		elif i < source_normals.size():
			normals[i] = source_normals[i].normalized()
		else:
			normals[i] = Vector3.UP
	return normals

func _accumulate_group(groups: Dictionary, key: Vector3i, face: Vector3) -> void:
	var current: Vector3 = groups.get(key,Vector3.ZERO)
	groups[key] = current + face

func _position_key(point: Vector3) -> Vector3i:
	return Vector3i(
		int(round(point.x*POSITION_QUANTIZATION)),
		int(round(point.y*POSITION_QUANTIZATION)),
		int(round(point.z*POSITION_QUANTIZATION))
	)
