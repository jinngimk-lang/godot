extends SceneTree

const OUTPUT_DIR := "res://artifacts/reference_frames"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("CAPTURE_RED: peel lab scene did not load")
		quit(1)
		return
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	await _settle_frames(10)

	var names: Array[String] = ["cafe","bar","market"]
	for i: int in range(3):
		scene.call("debug_select_variant",i)
		await _settle_frames(8)
		await RenderingServer.frame_post_draw
		var image: Image = root.get_texture().get_image()
		if image == null or image.is_empty():
			push_error("CAPTURE_RED: viewport image empty for %s" % names[i])
			scene.queue_free()
			await process_frame
			quit(1)
			return
		var path := "%s/%s.png" % [OUTPUT_DIR,names[i]]
		var error := image.save_png(path)
		if error != OK:
			push_error("CAPTURE_RED: failed to save %s (%s)" % [path,error_string(error)])
			scene.queue_free()
			await process_frame
			quit(1)
			return
		print("CAPTURE: %s" % path)

	scene.queue_free()
	await process_frame
	print("PASS: captured café/bar/market viewport frames")
	quit(0)

func _settle_frames(count: int) -> void:
	for _i: int in range(count):
		await process_frame
