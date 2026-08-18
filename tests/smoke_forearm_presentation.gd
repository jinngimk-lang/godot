extends SceneTree

const MIN_FOREARM_LENGTH := 3.20
const MAX_FOREARM_LENGTH := 6.80
const MAX_FOREARM_RADIUS := 0.21
const MIN_AUTHORED_HAND_SCALE := 4.00
const MIN_FOREARM_TANGENT_DEFLECTION_DEGREES := 24.0
const MIN_WRIST_OVERLAP_AUTHORED := 0.009
const MAX_IDLE_PEEL_EDGE_GAP := 0.10
const EXPECTED_OPEN_WRIST_INDEX_COUNT := 6816
const MIN_VISIBLE_AUTHORED_MESHES := 2
const MIN_POLISHED_AUTHORED_MESHES := 2
const MIN_CINEMATIC_FOREARM_SPAN := 3.20
const MAX_CINEMATIC_FOREARM_SPAN := 5.20

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		_fail("peel lab scene failed to load")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	for _frame in range(6):
		await process_frame

	var presentation := scene.get_node_or_null("ForearmPresentation") as Node3D
	if presentation == null:
		_fail("missing ForearmPresentation runtime layer",scene)
		return
	var cinematic := scene.get_node_or_null("CinematicHandPresentation") as Node
	if cinematic == null:
		_fail("missing CinematicHandPresentation runtime layer",scene)
		return
	if int(cinematic.call("get_ready_hand_count")) != 2:
		_fail("cinematic presentation must bind both authored hands",scene)
		return
	if int(cinematic.call("get_visible_authored_hand_mesh_count")) < MIN_VISIBLE_AUTHORED_MESHES:
		_fail("continuous authored hand surfaces must remain visible",scene)
		return
	if int(cinematic.call("get_polished_authored_mesh_count")) < MIN_POLISHED_AUTHORED_MESHES:
		_fail("visible authored hand surfaces must receive cinematic polish",scene)
		return
	if int(cinematic.call("get_visible_primitive_shell_mesh_count")) != 0:
		_fail("failed bead/capsule anatomy shell must not remain visible",scene)
		return

	for hand_name in ["RightHand","LeftHand"]:
		var hand := scene.get_node_or_null(hand_name) as Node3D
		if hand == null:
			_fail("missing %s" % hand_name,scene)
			return
		var authored := hand.get_node_or_null("AuthoredHand") as Node3D
		if authored == null or authored.scale.x < MIN_AUTHORED_HAND_SCALE:
			_fail("%s authored hand is too small beside the hero vessel" % hand_name,scene)
			return
		var shell := hand.get_node_or_null("CinematicShell") as Node3D
		if shell != null and shell.visible:
			_fail("%s primitive CinematicShell must stay retired" % hand_name,scene)
			return
		var cinematic_forearm := hand.get_node_or_null("CinematicForearm") as MeshInstance3D
		if cinematic_forearm == null or not cinematic_forearm.visible:
			_fail("%s must use the shorter cinematic forearm" % hand_name,scene)
			return
		var span := float(cinematic.call("get_cinematic_forearm_span",hand_name))
		if span < MIN_CINEMATIC_FOREARM_SPAN or span > MAX_CINEMATIC_FOREARM_SPAN:
			_fail("%s cinematic forearm span %.3f outside reference-framing bounds" % [hand_name,span],scene)
			return
		var old_forearm := hand.get_node_or_null("ForearmNatural") as MeshInstance3D
		if old_forearm == null or old_forearm.visible:
			_fail("%s legacy tube forearm must stay hidden from the viewport" % hand_name,scene)
			return
		var old_cuff := hand.get_node_or_null("SleeveCuffNatural") as MeshInstance3D
		if old_cuff != null and old_cuff.visible:
			_fail("%s legacy cuff must stay hidden from the viewport" % hand_name,scene)
			return

		# Preserve compatibility geometry/invariants even though it is not visible.
		if not (old_forearm.mesh is ArrayMesh):
			_fail("%s compatibility forearm mesh missing" % hand_name,scene)
			return
		var old_mesh := old_forearm.mesh as ArrayMesh
		var reach := old_mesh.get_aabb().size.length()
		if reach < MIN_FOREARM_LENGTH or reach > MAX_FOREARM_LENGTH:
			_fail("%s compatibility forearm reach out of bounds: %.3f" % [hand_name,reach],scene)
			return
		var arrays := old_mesh.surface_get_arrays(0)
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if indices.size() != EXPECTED_OPEN_WRIST_INDEX_COUNT:
			_fail("%s compatibility wrist must stay open/embedded; index count %d" % [hand_name,indices.size()],scene)
			return

		var legacy_sleeve := hand.get_node_or_null("AuthoredHand/WristSleeve") as MeshInstance3D
		var legacy_cuff := hand.get_node_or_null("AuthoredHand/WristCuff") as MeshInstance3D
		if legacy_sleeve == null or legacy_sleeve.visible:
			_fail("%s duplicate authored wrist sleeve must stay hidden" % hand_name,scene)
			return
		if legacy_cuff != null and legacy_cuff.visible:
			_fail("%s duplicate authored wrist cuff must stay hidden" % hand_name,scene)
			return

	for sample in [0.0,0.25,0.5,0.75,1.0]:
		var radius := float(presentation.call("_radius_profile",sample))
		if radius <= 0.0 or radius > MAX_FOREARM_RADIUS:
			_fail("compatibility forearm radius out of anatomical bound at %.2f: %.3f" % [sample,radius],scene)
			return
	if not presentation.has_method("_path_tangent_deflection_degrees"):
		_fail("forearm presentation missing tangent-deflection contract",scene)
		return
	for outward_sign in [-1.0,1.0]:
		var deflection := float(presentation.call("_path_tangent_deflection_degrees",outward_sign))
		if deflection < MIN_FOREARM_TANGENT_DEFLECTION_DEGREES:
			_fail("compatibility forearm path too beam-like: %.2f°" % deflection,scene)
			return
	if not presentation.has_method("_wrist_overlap_authored"):
		_fail("forearm presentation missing wrist-overlap contract",scene)
		return
	if float(presentation.call("_wrist_overlap_authored")) < MIN_WRIST_OVERLAP_AUTHORED:
		_fail("compatibility forearm no longer overlaps authored wrist",scene)
		return

	# Glass scenes use skin forearms; café uses dark cloth. The cinematic hand
	# material itself remains stable across venues.
	scene.call("debug_select_variant",1)
	await process_frame
	await process_frame
	for hand_name in ["RightHand","LeftHand"]:
		var old_forearm := scene.get_node("%s/ForearmNatural" % hand_name) as MeshInstance3D
		if old_forearm.material_override == null or old_forearm.material_override.resource_name != "HandSkin":
			_fail("bar %s compatibility forearm must switch to HandSkin" % hand_name,scene)
			return
		var cinematic_forearm := scene.get_node("%s/CinematicForearm" % hand_name) as MeshInstance3D
		if cinematic_forearm.material_override == null or cinematic_forearm.material_override.resource_name != "CinematicHandSkin":
			_fail("bar %s cinematic forearm must switch to skin" % hand_name,scene)
			return

	var choreography := scene.get_node_or_null("HandChoreographyPresentation") as Node
	if choreography == null:
		_fail("missing HandChoreographyPresentation",scene)
		return
	for _step in range(12):
		choreography.call("_process",0.1)
	var right := scene.get_node("RightHand") as HandVisual
	var label := scene.get_node("PeelLabel") as LabelVisual
	var edge_world := label.to_global(label.get_front_position(0.0))
	var idle_gap := right.get_pinch_world_position().distance_to(edge_world)
	if idle_gap > MAX_IDLE_PEEL_EDGE_GAP:
		_fail("idle peel pinch must stay at real label edge, gap %.3f > %.3f" % [idle_gap,MAX_IDLE_PEEL_EDGE_GAP],scene)
		return

	if presentation.has_method("_update_support_hand"):
		_fail("ForearmPresentation must not own glass support-hand root",scene)
		return
	var left := scene.get_node("LeftHand") as HandVisual
	var cup := scene.get_node("Cup") as MeshInstance3D
	var before_support := left.position
	cup.rotation.y = 0.55
	choreography.call("_process",0.1)
	if left.position.distance_to(before_support) < 0.025:
		_fail("glass support hand must follow inspected vessel yaw",scene)
		return

	scene.call("debug_select_variant",2)
	await process_frame
	for hand_name in ["RightHand","LeftHand"]:
		var cinematic_forearm := scene.get_node("%s/CinematicForearm" % hand_name) as MeshInstance3D
		if cinematic_forearm.material_override == null or cinematic_forearm.material_override.resource_name != "CinematicHandSkin":
			_fail("market %s cinematic forearm must stay natural skin" % hand_name,scene)
			return

	print("PASS: authored continuous hands stay visible and polished, primitive shell stays retired, cinematic forearms and interaction anchors remain coherent")
	scene.queue_free()
	await process_frame
	quit(0)

func _fail(message: String, scene: Node = null) -> void:
	push_error("FOREARM_RED: %s" % message)
	if scene != null:
		scene.queue_free()
	await process_frame
	quit(1)
