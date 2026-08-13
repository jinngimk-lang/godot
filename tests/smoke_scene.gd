extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed = load("res://scenes/peel_lab/peel_lab.tscn")
	if packed == null:
		push_error("SMOKE: main peel lab scene failed to load")
		quit(1)
		return
	var scene = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var required := ["Camera", "Cup", "PeelLabel", "LeftHand", "RightHand", "PointerAdapter", "PeelAudio", "HUD"]
	var failures: Array[String] = []
	for child_name in required:
		if not scene.has_node(child_name):
			failures.append("missing runtime node: %s" % child_name)
	if failures.is_empty():
		print("PASS: peel lab scene smoke")
		scene.queue_free()
		await process_frame
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
