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
