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
	await process_frame

	var required := [
		"Camera", "Cup", "PeelLabel", "LabelPrint", "LeftHand", "RightHand",
		"PointerAdapter", "PeelAudio", "HUD"
	]
	var failures: Array[String] = []
	for child_name in required:
		if not scene.has_node(child_name):
			failures.append("missing runtime node: %s" % child_name)

	for hand_name in ["LeftHand", "RightHand"]:
		if not scene.has_node(hand_name):
			continue
		var hand = scene.get_node(hand_name)
		if hand.get_finger_count() != 5:
			failures.append("%s must expose five fingers" % hand_name)
		if not hand.is_using_authored_asset():
			failures.append("%s must use repository-local authored GLB in normal runtime" % hand_name)
		var authored_root := hand.get_node_or_null("AuthoredHand") as Node3D
		if authored_root == null:
			failures.append("%s missing authored hand scene instance" % hand_name)
		else:
			# Keep the original authored-hand size/material gate focused on the GLB
			# itself. Presentation accessories such as sleeves have their own bounded
			# contract below and must not inflate this hand-mesh metric.
			var presentation := _hand_presentation(authored_root)
			var vertices := int(presentation["vertices"])
			var max_extent := float(presentation["max_extent"])
			var materials: Array[String] = presentation["materials"] as Array[String]
			if vertices <= 0:
				failures.append("%s authored hand has no renderable vertices" % hand_name)
			if max_extent < 0.35:
				failures.append("%s authored hand presentation is too small to read beside the cup: extent=%.3f" % [hand_name, max_extent])
			if max_extent > 1.40:
				failures.append("%s authored hand presentation is implausibly oversized: extent=%.3f" % [hand_name, max_extent])
			if not materials.has("HandSkin") or not materials.has("HandNail"):
				failures.append("%s authored hand missing HandSkin/HandNail materials: %s" % [hand_name, str(materials)])

			var sleeve := authored_root.find_child("WristSleeve", true, false) as MeshInstance3D
			var cuff := authored_root.find_child("WristCuff", true, false) as MeshInstance3D
			if sleeve == null or not (sleeve.mesh is CylinderMesh):
				failures.append("%s authored hand must include bounded WristSleeve geometry" % hand_name)
			else:
				var sleeve_mesh := sleeve.mesh as CylinderMesh
				if sleeve_mesh.height < 0.35 or sleeve_mesh.height > 0.80:
					failures.append("%s WristSleeve length outside presentation bounds: %.3f" % [hand_name, sleeve_mesh.height])
				if sleeve_mesh.bottom_radius > 0.045 or sleeve_mesh.top_radius > 0.065:
					failures.append("%s WristSleeve is too bulky at wrist/forearm: %.3f/%.3f" % [hand_name, sleeve_mesh.bottom_radius, sleeve_mesh.top_radius])
				if sleeve.material_override == null or sleeve.material_override.resource_name != "SleeveFabric":
					failures.append("%s WristSleeve must use SleeveFabric" % hand_name)
			if cuff == null or not (cuff.mesh is CylinderMesh):
				failures.append("%s authored hand must include bounded WristCuff geometry" % hand_name)
			else:
				var cuff_mesh := cuff.mesh as CylinderMesh
				if cuff_mesh.height > 0.025 or cuff_mesh.top_radius > 0.045:
					failures.append("%s WristCuff must remain a thin wrist band" % hand_name)
				if cuff.material_override == null or cuff.material_override.resource_name != "SleeveRib":
					failures.append("%s WristCuff must use SleeveRib" % hand_name)
		for anchor in ["ThumbTip", "IndexTip", "PinchPoint"]:
			if hand.find_child(anchor, true, false) == null:
				failures.append("%s missing pinch anchor: %s" % [hand_name, anchor])

	if scene.has_node("PeelAudio"):
		var audio = scene.get_node("PeelAudio")
		for player_name in ["AdhesiveSlow", "AdhesiveFast", "PaperFlex", "MicroRelease", "FinalRelease"]:
			var player = audio.get_node_or_null(player_name)
			if player == null:
				failures.append("missing foley player: %s" % player_name)
			elif player.stream == null:
				failures.append("foley player has no repository-local stream: %s" % player_name)

	for resource_path in [
		"res://assets/audio/peel/adhesive_slow.wav",
		"res://assets/audio/peel/adhesive_fast.wav",
		"res://assets/audio/peel/paper_flex.wav",
		"res://assets/audio/peel/micro_release.wav",
		"res://assets/audio/peel/final_release.wav",
		"res://assets/models/hands/hand_left.glb",
		"res://assets/models/hands/hand_right.glb"
	]:
		if not ResourceLoader.exists(resource_path):
			failures.append("missing repository-local tactile resource: %s" % resource_path)

	var lifecycle = scene.get("_lifecycle")
	if lifecycle == null:
		failures.append("peel scene did not initialize LabelLifecycle")
	elif lifecycle.get_phase_name() != "ATTACHED":
		failures.append("fresh peel scene lifecycle should start ATTACHED")

	# Complete-playable session contract: tactile variants must drive the actual
	# scene/controller, not exist only as disconnected progression data.
	var session = scene.get("_session")
	if session == null:
		failures.append("complete playable scene must initialize SessionModel")
	else:
		var variant: Dictionary = session.current_variant()
		var label := scene.get_node_or_null("PeelLabel") as LabelVisual
		if label == null:
			failures.append("session integration missing PeelLabel")
		else:
			if absf(label.label_width - float(variant.get("label_width", -1.0))) > 0.001:
				failures.append("current tactile variant must drive label width")
			if absf(label.label_height - float(variant.get("label_height", -1.0))) > 0.001:
				failures.append("current tactile variant must drive label height")

		var controller = scene.get("_controller")
		if controller == null or not controller.has_method("get_model_config"):
			failures.append("playable controller must expose applied tactile config for verification")
		else:
			var config: Dictionary = controller.get_model_config()
			if absf(float(config.get("base_adhesion", -1.0)) - float(variant.get("base_adhesion", -2.0))) > 0.001:
				failures.append("current tactile variant must drive actual adhesion")

	var hud := scene.get_node_or_null("HUD/Instructions") as Label
	if hud == null:
		failures.append("missing player-facing instruction HUD")
	else:
		for developer_word in ["ATTACHED", "PEELING", "DETACHING", "HELD", "IDLE", "PINCHED"]:
			if hud.text.contains(developer_word):
				failures.append("player HUD must not expose developer state jargon: %s" % developer_word)
		if not hud.text.contains("Reset") or not hud.text.contains("Pause"):
			failures.append("player HUD must expose reset and pause affordances")

	if failures.is_empty():
		print("PASS: complete-playable tactile peel scene smoke with renderable authored hands")
		scene.queue_free()
		await process_frame
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _hand_presentation(node: Node) -> Dictionary:
	var vertices := 0
	var max_extent := 0.0
	var materials: Array[String] = []
	# Wrist presentation accessories are validated separately. This helper is
	# deliberately limited to the authored GLB hand mesh/material contract.
	if node.name in ["WristSleeve", "WristCuff"]:
		return {"vertices": 0, "max_extent": 0.0, "materials": materials}
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		var mesh := mesh_instance.mesh
		if mesh != null:
			var size := mesh.get_aabb().size * mesh_instance.global_transform.basis.get_scale().abs()
			max_extent = maxf(size.x, maxf(size.y, size.z))
			for surface_index in range(mesh.get_surface_count()):
				var arrays := mesh.surface_get_arrays(surface_index)
				if arrays.size() > Mesh.ARRAY_VERTEX and arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array:
					vertices += (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
				var material := mesh.surface_get_material(surface_index)
				if material != null and not material.resource_name.is_empty() and not materials.has(material.resource_name):
					materials.append(material.resource_name)
	for child in node.get_children():
		var child_data := _hand_presentation(child)
		vertices += int(child_data["vertices"])
		max_extent = maxf(max_extent, float(child_data["max_extent"]))
		for material_name in child_data["materials"] as Array[String]:
			if not materials.has(material_name):
				materials.append(material_name)
	return {"vertices": vertices, "max_extent": max_extent, "materials": materials}
