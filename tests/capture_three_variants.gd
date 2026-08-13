extends SceneTree

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("VARIANT_CAPTURE: peel scene failed to load")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	for _frame in range(24):
		await process_frame

	var session = scene.get("_session")
	if session == null:
		push_error("VARIANT_CAPTURE: SessionModel missing")
		quit(1)
		return

	await _capture_current(scene, session, "01_warm_paper.png")

	session.record_clean_peel(100)
	session.record_clean_peel(100)
	scene.call("_advance_to_next_item")
	for _frame in range(10):
		await process_frame
	await _capture_current(scene, session, "02_silky_long.png")

	session.record_clean_peel(100)
	session.record_clean_peel(100)
	session.record_clean_peel(100)
	scene.call("_advance_to_next_item")
	for _frame in range(10):
		await process_frame
	await _capture_current(scene, session, "03_crisp_seal.png")

	scene.queue_free()
	await process_frame
	quit(0)

func _capture_current(scene: Node, session, filename: String) -> void:
	var variant: Dictionary = session.current_variant()
	var label := scene.get_node_or_null("PeelLabel") as LabelVisual
	var hud := scene.get_node_or_null("HUD/Instructions") as Label
	var cup := scene.get_node_or_null("Cup") as MeshInstance3D
	if label == null or hud == null or cup == null:
		push_error("VARIANT_CAPTURE: runtime label/HUD/Cup missing")
		return
	var texture := root.get_texture()
	if texture == null:
		push_error("VARIANT_CAPTURE: root viewport texture missing")
		return
	var image := texture.get_image()
	if image == null or image.is_empty():
		push_error("VARIANT_CAPTURE: viewport image empty")
		return
	var workspace := OS.get_environment("GITHUB_WORKSPACE")
	var output_dir := workspace.path_join("artifacts") if not workspace.is_empty() else ProjectSettings.globalize_path("user://variant-visual-artifacts")
	var mkdir_error := DirAccess.make_dir_recursive_absolute(output_dir)
	if mkdir_error != OK:
		push_error("VARIANT_CAPTURE: cannot create output dir: %s" % error_string(mkdir_error))
		return
	var output_path := output_dir.path_join(filename)
	var save_error := image.save_png(output_path)
	if save_error != OK:
		push_error("VARIANT_CAPTURE: failed to save %s: %s" % [filename, error_string(save_error)])
		return
	var cup_color := Color.WHITE
	if cup.material_override is StandardMaterial3D:
		cup_color = (cup.material_override as StandardMaterial3D).albedo_color
	print("VARIANT_CAPTURE_OK id=%s name=%s drink=%s label=%.3fx%.3f cup=%s hud_min=%s file=%s size=%dx%d" % [
		String(variant.get("id", "")),
		String(variant.get("name", "")),
		String(variant.get("drink", "")),
		label.label_width,
		label.label_height,
		str(cup_color),
		str(hud.get_minimum_size()),
		output_path,
		image.get_width(),
		image.get_height()
	])
