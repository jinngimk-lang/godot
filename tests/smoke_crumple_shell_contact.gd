extends SceneTree

const MAX_VISIBLE_CONTACT_GAP := 0.045

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("CRUMPLE_CONTACT_RED: PeelLab scene failed to load")
		quit(1)
		return

	var scene := packed.instantiate() as Node3D
	root.add_child(scene)
	await _settle_frames(4)

	var source := scene.get_node_or_null("CupCrumplePresentation") as CupCrumplePresentation
	var staging := scene.get_node_or_null("CrumpleHandStaging") as CrumpleHandStaging
	var support := scene.get_node_or_null("LeftHand") as HandVisual
	var peel := scene.get_node_or_null("RightHand") as HandVisual
	var label := scene.get_node_or_null("PeelLabel") as LabelVisual
	var lifecycle = scene.get("_lifecycle")
	var ritual = scene.get("_ritual")
	if source == null or staging == null or support == null or peel == null or label == null or lifecycle == null or ritual == null:
		push_error("CRUMPLE_CONTACT_RED: live Café scene is missing crumple presentation, lifecycle, ritual, or hand nodes")
		quit(1)
		return

	# Reproduce the capture/runtime post-detach ritual state rather than driving
	# CrumpleHandStaging in isolation. This keeps the contract bound to the real
	# scene tree, authored HandVisual anchors, and rendered CrumpledCup mesh.
	lifecycle.update(1.0,true,0.0)
	lifecycle.update(1.0,false,0.22)
	label.set_phase(String(lifecycle.get_phase_name()))
	label.set_detach_alpha(float(lifecycle.get_detach_alpha()))
	label.visible = false
	scene.call("_handle_detached_label")
	ritual.update(0.22)
	ritual.begin_crumple()
	staging._bind()
	var support_home := support.position
	var peel_home := peel.position
	source.set_crumple(0.55,-1,0.72)
	var shell := source.get_node_or_null("CrumpledCup") as MeshInstance3D
	if shell == null or not shell.visible or not (shell.mesh is ArrayMesh):
		push_error("CRUMPLE_CONTACT_RED: 55% Café crumple must expose the rendered CrumpledCup shell")
		quit(1)
		return
	_trace_gaps("signal",shell,support,peel)
	for frame_index in range(4):
		await process_frame
		_trace_gaps("frame%d" % (frame_index+1),shell,support,peel)

	var support_gap := _nearest_shell_vertex_gap(shell,support.get_pinch_world_position())
	var peel_gap := _nearest_shell_vertex_gap(shell,peel.get_pinch_world_position())
	print("CRUMPLE_CONTACT_GAPS support=%.4f peel=%.4f" % [support_gap,peel_gap])
	var failures: Array[String] = []
	if support_gap > MAX_VISIBLE_CONTACT_GAP:
		failures.append("CRUMPLE_CONTACT_RED: support pinch anchor must contact rendered shell (%.4f m > %.3f m)" % [support_gap,MAX_VISIBLE_CONTACT_GAP])
	if peel_gap > MAX_VISIBLE_CONTACT_GAP:
		failures.append("CRUMPLE_CONTACT_RED: released peel pinch anchor must contact rendered shell (%.4f m > %.3f m)" % [peel_gap,MAX_VISIBLE_CONTACT_GAP])

	staging.reset_staging()
	if not support.position.is_equal_approx(support_home):
		failures.append("CRUMPLE_CONTACT_RED: reset must restore support-hand root exactly")
	if not peel.position.is_equal_approx(peel_home):
		failures.append("CRUMPLE_CONTACT_RED: reset must restore peel-hand root exactly")

	if failures.is_empty():
		print("PASS: Café crumple visible pinch anchors contact the rendered shell and reset exactly")
		scene.queue_free()
		await process_frame
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	scene.queue_free()
	await process_frame
	quit(1)

func _trace_gaps(label: String,shell: MeshInstance3D,support: HandVisual,peel: HandVisual) -> void:
	print("CRUMPLE_CONTACT_TRACE %s support=%.4f peel=%.4f support_root=%s peel_root=%s" % [
		label,
		_nearest_shell_vertex_gap(shell,support.get_pinch_world_position()),
		_nearest_shell_vertex_gap(shell,peel.get_pinch_world_position()),
		str(support.position),
		str(peel.position)
	])

func _nearest_shell_vertex_gap(shell: MeshInstance3D,world_point: Vector3) -> float:
	var mesh := shell.mesh as ArrayMesh
	if mesh == null or mesh.get_surface_count() == 0:
		return INF
	var arrays := mesh.surface_get_arrays(0)
	var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	if vertices.is_empty():
		return INF
	var best := INF
	for vertex in vertices:
		best = minf(best,shell.to_global(vertex).distance_to(world_point))
	return best

func _settle_frames(count: int) -> void:
	for _i in range(count):
		await process_frame
