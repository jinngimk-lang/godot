extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("support-target diagnostic could not load peel_lab")
		quit(1)
		return
	var scene := packed.instantiate() as Node3D
	if scene == null:
		push_error("support-target diagnostic could not instantiate peel_lab")
		quit(1)
		return
	root.add_child(scene)
	# PeelLab builds the world in _ready() and presentation binders defer once.
	for _i in range(5):
		await process_frame

	var left := scene.get_node_or_null("LeftHand") as Node3D
	var cup := scene.get_node_or_null("Cup") as Node3D
	if left == null or cup == null:
		push_error("support-target diagnostic missing LeftHand or Cup")
		quit(1)
		return
	var authored := left.get_node_or_null("AuthoredHand") as Node3D
	if authored == null:
		push_error("support-target diagnostic missing authored hand root")
		quit(1)
		return
	var skeleton := _find_skeleton(authored)
	if skeleton == null:
		push_error("support-target diagnostic missing Skeleton3D")
		quit(1)
		return
	var wrist_id := skeleton.find_bone("Wrist_L")
	if wrist_id < 0:
		push_error("support-target diagnostic missing Wrist_L")
		quit(1)
		return

	var center_authored := authored.to_local(cup.global_position)
	var axis_world := cup.global_basis.y.normalized()
	var axis_authored := (authored.global_basis.inverse() * axis_world).normalized()
	var wrist_skeleton := skeleton.get_bone_global_pose(wrist_id).origin
	var wrist_world := skeleton.to_global(wrist_skeleton)
	var wrist_authored := authored.to_local(wrist_world)
	var radial := center_authored - wrist_authored
	radial -= axis_authored * radial.dot(axis_authored)
	if radial.length_squared() <= 0.000001:
		push_error("support-target diagnostic produced degenerate radial direction")
		quit(1)
		return
	radial = radial.normalized()

	var report := {
		"left_position": [left.position.x, left.position.y, left.position.z],
		"left_rotation": [left.rotation.x, left.rotation.y, left.rotation.z],
		"authored_scale": [authored.scale.x, authored.scale.y, authored.scale.z],
		"cup_center_authored": [center_authored.x, center_authored.y, center_authored.z],
		"cup_axis_authored": [axis_authored.x, axis_authored.y, axis_authored.z],
		"wrist_authored": [wrist_authored.x, wrist_authored.y, wrist_authored.z],
		"cup_radial_from_wrist_authored": [radial.x, radial.y, radial.z]
	}
	print("SUPPORT_TARGET_JSON=", JSON.stringify(report))
	quit(0)

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null
