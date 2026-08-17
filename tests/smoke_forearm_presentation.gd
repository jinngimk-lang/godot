extends SceneTree

const MIN_FOREARM_LENGTH := 3.20
const MAX_FOREARM_LENGTH := 6.80
const MAX_FOREARM_RADIUS := 0.21
const MIN_AUTHORED_HAND_SCALE := 4.00
const MIN_FOREARM_TANGENT_DEFLECTION_DEGREES := 24.0
const MIN_WRIST_OVERLAP_AUTHORED := 0.009
const EXPECTED_OPEN_WRIST_INDEX_COUNT := 6816
const CAP_EXIT_MARGIN_PX := 4.0
const FOREARM_RING_SIDES := 32

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

	for sample in [0.0,0.25,0.5,0.75,1.0]:
		var radius := float(presentation.call("_radius_profile",sample))
		if radius <= 0.0 or radius > MAX_FOREARM_RADIUS:
			_fail("forearm radius out of anatomical bound at %.2f: %.3f" % [sample,radius],scene)
			return

	if not presentation.has_method("_path_tangent_deflection_degrees"):
		_fail("forearm path must expose an anatomical tangent-deflection contract",scene)
		return
	for outward_sign in [-1.0,1.0]:
		var deflection := float(presentation.call("_path_tangent_deflection_degrees",outward_sign))
		if deflection < MIN_FOREARM_TANGENT_DEFLECTION_DEGREES:
			_fail("forearm path stays too beam-like; tangent deflection %.2f° < %.2f°" % [deflection,MIN_FOREARM_TANGENT_DEFLECTION_DEGREES],scene)
			return

	if not presentation.has_method("_wrist_overlap_authored"):
		_fail("forearm presentation must expose wrist-overlap depth so the join cannot regress to a visible butt seam",scene)
		return
	var wrist_overlap := float(presentation.call("_wrist_overlap_authored"))
	if wrist_overlap < MIN_WRIST_OVERLAP_AUTHORED:
		_fail("forearm must overlap the authored wrist by at least %.3f authored units, got %.3f" % [MIN_WRIST_OVERLAP_AUTHORED,wrist_overlap],scene)
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
		var forearm_mesh := forearm.mesh as ArrayMesh
		var reach := forearm_mesh.get_aabb().size.length()
		if reach < MIN_FOREARM_LENGTH or reach > MAX_FOREARM_LENGTH:
			_fail("%s forearm must continue beyond the frame without runaway geometry: %.3f" % [hand_name,reach],scene)
			return
		var arrays := forearm_mesh.surface_get_arrays(0)
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if indices.size() != EXPECTED_OPEN_WRIST_INDEX_COUNT:
			_fail("%s forearm wrist end must stay open/embedded instead of exposing a dark cap; index count %d != %d" % [hand_name,indices.size(),EXPECTED_OPEN_WRIST_INDEX_COUNT],scene)
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
		if not _forearm_terminal_ring_is_offscreen(scene,forearm):
			_fail("bar %s bare forearm terminal ring must be fully outside the viewport instead of forming a visible pointed stump" % hand_name,scene)
			return

	# Support-root choreography has one owner. ForearmPresentation owns geometry
	# and venue material only; HandChoreographyPresentation owns glass grip root
	# placement and inspection-follow. Two writers caused small reset drift and
	# would become visible jitter once higher-fidelity arms are introduced.
	if presentation.has_method("_update_support_hand"):
		_fail("ForearmPresentation must not retain glass support-root ownership",scene)
		return
	var choreography := scene.get_node_or_null("HandChoreographyPresentation") as Node
	if choreography == null:
		_fail("missing HandChoreographyPresentation support owner",scene)
		return
	var left := scene.get_node("LeftHand") as HandVisual
	var cup := scene.get_node("Cup") as MeshInstance3D
	var before_support := left.position
	cup.rotation.y = 0.55
	choreography.call("_process",0.1)
	if left.position.distance_to(before_support) < 0.025:
		_fail("glass-scene support owner must move with inspected vessel yaw",scene)
		return

	scene.call("debug_select_variant",2)
	await process_frame
	for hand_name in ["RightHand","LeftHand"]:
		var forearm := scene.get_node("%s/ForearmNatural" % hand_name) as MeshInstance3D
		if forearm.material_override == null or forearm.material_override.resource_name != "HandSkin":
			_fail("market %s forearm must stay natural HandSkin" % hand_name,scene)
			return
		if not _forearm_terminal_ring_is_offscreen(scene,forearm):
			_fail("market %s bare forearm terminal ring must be fully outside the viewport instead of forming a visible pointed stump" % hand_name,scene)
			return

	print("PASS: reference-scale hands, seamless curved forearms and single-owner grip choreography stay coherent")
	scene.queue_free()
	await process_frame
	quit(0)

func _forearm_terminal_ring_is_offscreen(scene: Node,forearm: MeshInstance3D) -> bool:
	var camera := scene.get_node_or_null("Camera") as Camera3D
	if camera == null or forearm == null or not (forearm.mesh is ArrayMesh):
		return false
	var arrays := (forearm.mesh as ArrayMesh).surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	if vertices.size() < FOREARM_RING_SIDES+1:
		return false
	var viewport_size := camera.get_viewport().get_visible_rect().size
	var terminal_ring_start := vertices.size()-1-FOREARM_RING_SIDES
	for vertex_index in range(terminal_ring_start,vertices.size()):
		var world := forearm.to_global(vertices[vertex_index])
		if camera.is_position_behind(world):
			continue
		var screen := camera.unproject_position(world)
		var outside := screen.x <= -CAP_EXIT_MARGIN_PX or screen.x >= viewport_size.x+CAP_EXIT_MARGIN_PX or screen.y <= -CAP_EXIT_MARGIN_PX or screen.y >= viewport_size.y+CAP_EXIT_MARGIN_PX
		if not outside:
			return false
	return true

func _fail(message: String, scene: Node = null) -> void:
	push_error("FOREARM_RED: %s" % message)
	if scene != null:
		scene.queue_free()
	await process_frame
	quit(1)
