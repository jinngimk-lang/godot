extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("CAFE_RED: peel lab scene failed to load")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	for _i in range(5): await process_frame

	var failures: Array[String] = []
	if scene.get_node_or_null("CafePresentation") != null:
		failures.append("CAFE_RED: hidden legacy CafePresentation must be deleted, not carried beside the real hero")
	var product := scene.get_node_or_null("ProductPresentation") as ProductPresentation
	if product == null or product.get_active_kind() != "paper_cup":
		failures.append("CAFE_RED: Coffee Shop must be owned by live ProductPresentation paper_cup")
	else:
		for detail in ["CupPaperDetails","CupLidSnapRing","CupLidCrown","CupLidTopBead","CafeLidMoldedDetail"]:
			if product.get_node_or_null(detail) == null:
				failures.append("CAFE_RED: live coffee hero missing %s" % detail)
		var molded := product.get_node_or_null("CafeLidMoldedDetail") as Node3D
		if molded != null:
			for detail in ["LidSipTab","LidVentDimple"]:
				var node := molded.get_node_or_null(detail) as MeshInstance3D
				if node == null or node.mesh == null or node.material_override == null or not node.visible:
					failures.append("CAFE_RED: live molded lid missing visible %s" % detail)

	var backdrop := scene.get_node_or_null("ReferenceBackdrop") as Sprite3D
	if backdrop == null or backdrop.texture == null or not backdrop.visible:
		failures.append("CAFE_RED: Coffee Shop needs the real reference backdrop")
	elif backdrop.TARGET_WORLD_WIDTH < 8.0:
		failures.append("CAFE_RED: Coffee Shop backdrop needs viewport overscan")

	var label_print := scene.get_node_or_null("LabelPrint") as SubViewport
	if label_print == null:
		failures.append("CAFE_RED: missing LabelPrint")
	else:
		var print_aspect := float(label_print.size.x)/maxf(float(label_print.size.y),1.0)
		if print_aspect>1.35:
			failures.append("CAFE_RED: Coffee Shop order sticker must remain near-square")
		var print_root := label_print.get_node_or_null("PrintRoot") as Control
		if print_root == null:
			failures.append("CAFE_RED: missing receipt PrintRoot")
		else:
			var order_label := print_root.get_node_or_null("OrderLabel") as Label
			var drink_label := print_root.get_node_or_null("DrinkLabel") as Label
			var note := print_root.get_node_or_null("Note") as Label
			if order_label == null or not order_label.text.contains("COCOA CLOUD"):
				failures.append("CAFE_RED: order sticker needs COCOA CLOUD")
			if drink_label == null or not drink_label.text.contains("MOCHA LATTE"):
				failures.append("CAFE_RED: order sticker needs MOCHA LATTE")
			if note == null or not note.text.contains("OAT"):
				failures.append("CAFE_RED: order sticker needs OAT order detail")

	var key := scene.get_node_or_null("KeyLight") as DirectionalLight3D
	if key == null or key.shadow_enabled:
		failures.append("CAFE_RED: close-up hero lighting should avoid hard directional shadows")
	var rail := scene.get_node_or_null("HUD/JourneyRail") as Control
	if rail == null or not rail.visible:
		failures.append("CAFE_RED: approved persistent scene rail must be visible")

	if failures.is_empty():
		print("PASS: live Coffee Shop paper hero + order label + backdrop + object-only HUD")
		scene.queue_free()
		await process_frame
		quit(0)
		return
	for failure in failures: push_error(failure)
	quit(1)
