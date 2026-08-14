extends SceneTree

const MAX_FOREARM_LENGTH := 0.82
const MAX_FOREARM_VERTICAL_THICKNESS := 0.18

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
		var forearm := hand.get_node_or_null("ForearmNatural") as MeshInstance3D
		if forearm == null or not (forearm.mesh is ArrayMesh):
			_fail("%s must use one smooth ForearmNatural mesh" % hand_name,scene)
			return
		var aabb := (forearm.mesh as ArrayMesh).get_aabb()
		if aabb.size.length() > MAX_FOREARM_LENGTH:
			_fail("%s forearm remains too long/hose-like: %.3f" % [hand_name,aabb.size.length()],scene)
			return
		# The curve intentionally travels in X/Z toward the frame edge, so Y is
		# the stable cross-section axis for rejecting the old giant cone silhouette.
		if aabb.size.y > MAX_FOREARM_VERTICAL_THICKNESS:
			_fail("%s forearm remains too thick/geometric: %s" % [hand_name,str(aabb.size)],scene)
			return
		if forearm.material_override == null or forearm.material_override.resource_name != "SleeveFabric":
			_fail("café forearm should start with soft SleeveFabric",scene)
			return
		var legacy := hand.get_node_or_null("AuthoredHand/WristSleeve") as MeshInstance3D
		if legacy == null or legacy.visible:
			_fail("%s must hide the duplicate long authored sleeve" % hand_name,scene)
			return

	# Bar and market references use natural bare forearms rather than dark tubes.
	scene.call("debug_select_variant",1)
	await process_frame
	await process_frame
	for hand_name in ["RightHand","LeftHand"]:
		var forearm := scene.get_node("%s/ForearmNatural" % hand_name) as MeshInstance3D
		if forearm.material_override == null or forearm.material_override.resource_name != "HandSkin":
			_fail("bar %s forearm must switch to HandSkin" % hand_name,scene)
			return

	scene.call("debug_select_variant",2)
	await process_frame
	for hand_name in ["RightHand","LeftHand"]:
		var forearm := scene.get_node("%s/ForearmNatural" % hand_name) as MeshInstance3D
		if forearm.material_override == null or forearm.material_override.resource_name != "HandSkin":
			_fail("market %s forearm must stay natural HandSkin" % hand_name,scene)
			return

	print("PASS: compact smooth forearms use café cloth and natural bar/market skin")
	scene.queue_free()
	await process_frame
	quit(0)

func _fail(message: String, scene: Node = null) -> void:
	push_error("FOREARM_RED: %s" % message)
	if scene != null:
		scene.queue_free()
	await process_frame
	quit(1)
