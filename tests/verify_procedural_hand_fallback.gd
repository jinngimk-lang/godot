extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if ResourceLoader.exists("res://assets/models/hands/hand_right.glb"):
		push_error("FALLBACK_VERIFY: right authored asset must be absent on verifier branch")
		quit(1)
		return

	var hand := HandVisual.new()
	hand.name = "FallbackRightHand"
	root.add_child(hand)
	hand.setup(true)
	await process_frame

	if hand.is_using_authored_asset():
		push_error("FALLBACK_RED: missing authored GLB must select procedural fallback")
		quit(1)
		return
	if hand.get_finger_count() != 5:
		push_error("FALLBACK_RED: procedural fallback must preserve five-finger contract")
		quit(1)
		return
	for node_name in ["Wrist", "Palm", "Thenar", "ThumbTip", "IndexTip", "PinchPoint", "ThumbNail", "IndexNail"]:
		if hand.find_child(node_name, true, false) == null:
			push_error("FALLBACK_RED: procedural fallback missing %s" % node_name)
			quit(1)
			return

	var renderable_meshes := 0
	var segment_count := 0
	for child in hand.get_children():
		if child is MeshInstance3D:
			var mesh_instance := child as MeshInstance3D
			if mesh_instance.mesh != null and mesh_instance.material_override != null:
				renderable_meshes += 1
			if String(mesh_instance.name).contains("Segment"):
				segment_count += 1
	if segment_count != 15:
		push_error("FALLBACK_RED: procedural fallback must build 15 finger segments, got %d" % segment_count)
		quit(1)
		return
	if renderable_meshes < 22:
		push_error("FALLBACK_RED: procedural fallback must contain renderable wrist/palm/fingers/nails, got %d meshes" % renderable_meshes)
		quit(1)
		return

	hand.snap_to(Vector3(-0.7, 0.3, 0.8))
	hand.set_pinch_amount(1.0)
	var initial_pinch := hand.get_pinch_world_position()
	if not _finite_vector(initial_pinch):
		push_error("FALLBACK_RED: procedural pinch anchor must be finite")
		quit(1)
		return
	var target := initial_pinch + Vector3(-0.45, 0.18, 0.22)
	hand.set_grip_target(target)
	for i in range(30):
		hand.tick(0.05)
	var moved_pinch := hand.get_pinch_world_position()
	if not _finite_vector(moved_pinch):
		push_error("FALLBACK_RED: dynamic procedural pinch must remain finite")
		quit(1)
		return
	if moved_pinch.distance_to(target) > 0.035:
		push_error("FALLBACK_RED: dynamic procedural pinch failed to follow grip target; error=%.5f" % moved_pinch.distance_to(target))
		quit(1)
		return

	print("PASS: authored-right asset missing -> procedural fallback renders and follows grip; meshes=%d segments=%d target_error=%.6f" % [renderable_meshes, segment_count, moved_pinch.distance_to(target)])
	hand.queue_free()
	await process_frame
	quit(0)

func _finite_vector(value: Vector3) -> bool:
	return is_finite(value.x) and is_finite(value.y) and is_finite(value.z)
