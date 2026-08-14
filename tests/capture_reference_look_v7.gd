extends SceneTree

const OUT_DIR := "artifacts/reference-v7"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://%s" % OUT_DIR))
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("REFERENCE_V7_CAPTURE: failed to load peel lab")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await _settle_frames(10)

	var session = scene.get("_session")
	var contents: Node = scene.get_node_or_null("CupContentsPresentation")
	if session == null or contents == null:
		push_error("REFERENCE_V7_CAPTURE: missing session/contents runtime contract")
		quit(1)
		return

	await _capture("01_warm_actual_ui.png")
	_log_scene(scene, "warm")

	# Also capture the same real scene with HUD hidden so visual review can
	# distinguish scene-quality gaps from interface hierarchy gaps.
	var hud := scene.get_node_or_null("HUD") as CanvasLayer
	if hud != null:
		hud.visible = false
	await _settle_frames(2)
	await _capture("02_warm_clean_scene.png")
	if hud != null:
		hud.visible = true

	# Unlock and rotate through the real SessionModel to the iced tactile set.
	session.record_ritual_complete()
	session.record_ritual_complete()
	session.advance_item()
	session.record_ritual_complete()
	session.record_ritual_complete()
	session.record_ritual_complete()
	session.advance_item()
	scene.call("_apply_current_variant")
	scene.call("_reset_session")
	await _settle_frames(8)
	if String(session.current_variant().get("id", "")) != "crisp_seal":
		push_error("REFERENCE_V7_CAPTURE: failed to reach crisp_seal")
		quit(1)
		return
	if int(contents.call("get_content_count")) != 3:
		push_error("REFERENCE_V7_CAPTURE: crisp_seal should expose three ice cubes")
		quit(1)
		return
	await _capture("03_crisp_ice_actual_ui.png")
	_log_scene(scene, "crisp")
	if hud != null:
		hud.visible = false
	await _settle_frames(2)
	await _capture("04_crisp_ice_clean_scene.png")

	print("REFERENCE_V7_CAPTURE: done")
	scene.queue_free()
	await process_frame
	quit(0)

func _log_scene(scene: Node, label: String) -> void:
	var camera := scene.get_node_or_null("Camera") as Camera3D
	var cup := scene.get_node_or_null("Cup") as MeshInstance3D
	var cafe := scene.get_node_or_null("CafePresentation") as Node3D
	var session = scene.get("_session")
	var variant: Dictionary = session.current_variant() if session != null else {}
	var backdrop := cafe.get_node_or_null("Backdrop") as MeshInstance3D if cafe != null else null
	var table := scene.get_node_or_null("Table") as MeshInstance3D
	print("REFERENCE_V7_CAPTURE: %s id=%s camera=%s fov=%.2f cup=%s backdrop=%s table=%s" % [
		label,
		String(variant.get("id", "")),
		str(camera.global_position if camera != null else Vector3.ZERO),
		camera.fov if camera != null else 0.0,
		str(cup.global_position if cup != null else Vector3.ZERO),
		str(_material_color(backdrop)),
		str(_material_color(table))
	])

func _material_color(node: MeshInstance3D) -> Color:
	if node != null and node.material_override is StandardMaterial3D:
		return (node.material_override as StandardMaterial3D).albedo_color
	return Color.BLACK

func _settle_frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := "res://%s/%s" % [OUT_DIR, filename]
	var err := image.save_png(path)
	if err != OK:
		push_error("REFERENCE_V7_CAPTURE: failed to save %s: %s" % [path, err])
		quit(1)
		return
	print("REFERENCE_V7_CAPTURE: saved %s" % ProjectSettings.globalize_path(path))
