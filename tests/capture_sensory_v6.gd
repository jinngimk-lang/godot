extends SceneTree

const OUT_DIR := "artifacts/sensory-v6"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://%s" % OUT_DIR))
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("CAPTURE_V6: failed to load peel lab")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await _settle_frames(8)

	var session = scene.get("_session")
	var contents: Node = scene.get_node_or_null("CupContentsPresentation")
	if session == null or contents == null:
		push_error("CAPTURE_V6: missing session/contents runtime contract")
		quit(1)
		return

	await _capture("01_warm_paper.png")
	_log_variant(scene, "warm")

	session.record_ritual_complete()
	session.record_ritual_complete()
	session.advance_item()
	scene.call("_apply_current_variant")
	scene.call("_reset_session")
	await _settle_frames(6)
	await _capture("02_silky_long.png")
	_log_variant(scene, "silky")

	session.record_ritual_complete()
	session.record_ritual_complete()
	session.record_ritual_complete()
	session.advance_item()
	scene.call("_apply_current_variant")
	scene.call("_reset_session")
	await _settle_frames(6)
	if String(session.current_variant().get("id", "")) != "crisp_seal":
		push_error("CAPTURE_V6: failed to reach crisp_seal")
		quit(1)
		return
	if int(contents.call("get_content_count")) != 3:
		push_error("CAPTURE_V6: crisp_seal must have three contained ice cubes")
		quit(1)
		return
	await _capture("03_crisp_seal_ice.png")
	_log_variant(scene, "crisp")

	var label := scene.get_node("PeelLabel") as LabelVisual
	var right_hand := scene.get_node("RightHand") as HandVisual
	var marker := scene.get_node("PeelEdge") as MeshInstance3D
	label.set_phase("HELD")
	label.set_detach_alpha(1.0)
	label.set_peel(1.0, right_hand.get_pinch_world_position())
	marker.visible = false
	scene.call("_handle_detached_label")
	var ritual = scene.get("_ritual")
	ritual.update(0.46)
	var press := PointerState.new()
	press.set_frame(true, Vector2(420, 360), Vector2.ZERO, Vector2.ZERO, false)
	scene.call("_process_crumple_pointer", press)
	var drag := PointerState.new()
	drag.set_frame(true, Vector2(470, 360), Vector2(50, 0), Vector2(120, 0), false)
	for _i in range(2):
		scene.call("_process_crumple_pointer", drag)
	scene.call("_update_hud", "", "HELD", 1.0)
	await _settle_frames(4)
	await _capture("04_crisp_mid_crumple.png")
	_log_variant(scene, "crisp-mid")

	print("CAPTURE_V6: done")
	scene.queue_free()
	await process_frame
	quit(0)

func _log_variant(scene: Node, label: String) -> void:
	var session = scene.get("_session")
	var variant: Dictionary = session.current_variant()
	var cup := scene.get_node("Cup") as MeshInstance3D
	var cup_mesh := cup.mesh as CylinderMesh
	var lid := scene.get_node("Lid") as MeshInstance3D
	var contents: Node = scene.get_node("CupContentsPresentation")
	var ice_y: Array[String] = []
	var container: Node = contents.get_node_or_null("IceContents")
	if container != null:
		for child in container.get_children():
			if child is MeshInstance3D:
				ice_y.append("%.3f" % (child as MeshInstance3D).global_position.y)
	print("CAPTURE_V6: %s id=%s dims=%.3f/%.3f/%.3f lid_visible=%s cap_top=%s contents=%d ice_global_y=%s" % [
		label,
		String(variant.get("id", "")),
		cup_mesh.top_radius,
		cup_mesh.bottom_radius,
		cup_mesh.height,
		str(lid.visible),
		str(cup_mesh.cap_top),
		int(contents.call("get_content_count")),
		str(ice_y)
	])

func _settle_frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := "res://%s/%s" % [OUT_DIR, filename]
	var err := image.save_png(path)
	if err != OK:
		push_error("CAPTURE_V6: failed to save %s: %s" % [path, err])
		quit(1)
		return
	print("CAPTURE_V6: saved %s" % ProjectSettings.globalize_path(path))
