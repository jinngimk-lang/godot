extends SceneTree

const MIN_FOREARM_LENGTH := 1.35
const MAX_FOREARM_LENGTH := 3.20
const MAX_FOREARM_VERTICAL_THICKNESS := 0.36
const MIN_AUTHORED_HAND_SCALE := 3.45

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		_fail("peel lab scene failed to load")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame

	var presentation := scene.get_node_or_null("ForearmPresentation") as Node3D
	if presentation == null:
		_fail("missing ForearmPresentation runtime layer",scene)
		return

	for hand_name in ["RightHand","LeftHand"]:
		var hand := scene.get_node_or_null(hand_name) as Node3D
		if hand == null:
			_fail("missing %s" % hand_name,scene)
			return
		var authored := hand.get_node_or_null("AuthoredHand") as Node3D
		if authored == null or authored.scale.x < MIN_AUTHORED_HAND_SCALE:
			_fail("%s authored hand is still too visually small beside the hero vessel" % hand_name,scene)
			return
		var forearm := hand.get_node_or_null("ForearmNatural") as MeshInstance3D
		if forearm == null or not (forearm.mesh is ArrayMesh):
			_fail("%s must use one smooth ForearmNatural mesh" % hand_name,scene)
			return
		var aabb := (forearm.mesh as ArrayMesh).get_aabb()
		var reach := aabb.size.length()
		if reach < MIN_FOREARM_LENGTH or reach > MAX_FOREARM_LENGTH:
			_fail("%s forearm must reach toward the frame edge without runaway geometry: %.3f" % [hand_name,reach],scene)
			return
		if aabb.size.y > MAX_FOREARM_VERTICAL_THICKNESS:
			_fail("%s forearm cross-section is still too tube-like: %s" % [hand_name,str(aabb.size)],scene)
			return
		if forearm.material_override == null or forearm.material_override.resource_name != "SleeveFabric":
			_fail("café forearm should start with soft SleeveFabric",scene)
			return
		var legacy := hand.get_node_or_null("AuthoredHand/WristSleeve") as MeshInstance3D
		var legacy_cuff := hand.get_node_or_null("AuthoredHand/WristCuff") as MeshInstance3D
		if legacy == null or legacy.visible:
			_fail("%s must hide the duplicate long authored sleeve" % hand_name,scene)
			return
		if legacy_cuff != null and legacy_cuff.visible:
			_fail("%s must hide the old dark wrist ring" % hand_name,scene)
			return

	scene.call("debug_select_variant",1)
	await process_frame
	await process_frame
	for hand_name in ["RightHand","LeftHand"]:
		var forearm := scene.get_node("%s/ForearmNatural" % hand_name) as MeshInstance3D
		if forearm.material_override == null or forearm.material_override.resource_name != "HandSkin":
			_fail("bar %s forearm must switch to HandSkin" % hand_name,scene)
			return

	var left := scene.get_node("LeftHand") as HandVisual
	var cup := scene.get_node("Cup") as MeshInstance3D
	var before_support := left.position
	cup.rotation.y = 0.55
	presentation.call("_update_support_hand",0.1)
	if left.position.distance_to(before_support) < 0.025:
		_fail("glass-scene support hand must move with inspected vessel yaw",scene)
		return

	scene.call("debug_select_variant",2)
	await process_frame
	for hand_name in ["RightHand","LeftHand"]:
		var forearm := scene.get_node("%s/ForearmNatural" % hand_name) as MeshInstance3D
		if forearm.material_override == null or forearm.material_override.resource_name != "HandSkin":
			_fail("market %s forearm must stay natural HandSkin" % hand_name,scene)
			return

	print("PASS: reference-scale hands and sealed frame-edge forearms stay coherent")
	scene.queue_free()
	await process_frame
	quit(0)

func _fail(message: String, scene: Node = null) -> void:
	push_error("FOREARM_RED: %s" % message)
	if scene != null:
		scene.queue_free()
	await process_frame
	quit(1)
