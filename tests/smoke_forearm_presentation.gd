extends SceneTree

const MIN_FOREARM_LENGTH := 3.20
const MAX_FOREARM_LENGTH := 6.80
const MAX_FOREARM_RADIUS := 0.21
const MIN_AUTHORED_HAND_SCALE := 4.00
const MIN_FOREARM_TANGENT_DEFLECTION_DEGREES := 24.0
const MIN_WRIST_OVERLAP_AUTHORED := 0.009
const MAX_IDLE_PEEL_EDGE_GAP := 0.10
const EXPECTED_OPEN_WRIST_INDEX_COUNT := 6816
const MIN_CINEMATIC_SHELL_PIECES := 24
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
	await process_frame
	await process_frame
	await process_frame
	await process_frame
	await process_frame

	var presentation := scene.get_node_or_null("ForearmPresentation") as Node3D
	if presentation == null:
		_fail("missing ForearmPresentation runtime layer",scene)
		return

	var cinematic := scene.get_node_or_null("CinematicHandPresentation") as Node
	if cinematic == null:
		_fail("missing CinematicHandPresentation runtime layer",scene)
		return
	if int(cinematic.call("get_shell_ready_count")) != 2:
		_fail("cinematic hand rebuild must bind both live hands",scene)
		return
	if int(cinematic.call("get_visible_legacy_hand_mesh_count")) != 0:
		_fail("faceted authored XR render meshes must be hidden behind the cinematic shell",scene)
		return
	for hand_name in ["RightHand","LeftHand"]:
		var shell := scene.get_node_or_null("%s/CinematicShell" % hand_name) as Node3D
		if shell == null:
			_fail("%s missing CinematicShell" % hand_name,scene)
			return
		if int(cinematic.call("get_shell_piece_count",hand_name)) < MIN_CINEMATIC_SHELL_PIECES:
			_fail("%s cinematic shell does not contain enough smooth anatomy pieces" % hand_name,scene)
			return
		for finger_name in ["Thumb","Index","Middle","Ring","Little"]:
			var tip := shell.get_node_or_null("%sTip" % finger_name) as MeshInstance3D
			if tip == null or not tip.visible:
				_fail("%s %s cinematic fingertip must resolve from the authored skeleton" % [hand_name,finger_name],scene)
				return
		var cinematic_forearm := scene.get_node_or_null("%s/CinematicForearm" % hand_name) as MeshInstance3D
		if cinematic_forearm == null or not cinematic_forearm.visible:
			_fail("%s must use the new cinematic diagonal forearm" % hand_name,scene)
			return
		var span := float(cinematic.call("get_cinematic_forearm_span",hand_name))
		if span < MIN_CINEMATIC_FOREARM_SPAN or span > MAX_CINEMATIC_FOREARM_SPAN:
			_fail("%s cinematic forearm span %.3f outside reference-framing bounds" % [hand_name,span],scene)
			return
		var old_forearm := scene.get_node_or_null("%s/ForearmNatural" % hand_name) as MeshInstance3D
		if old_forearm == null or old_forearm.visible:
			_fail("%s legacy tube forearm must remain present for compatibility but hidden from the viewport" % hand_name,scene)
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
			_fail("%s must retain one smooth ForearmNatural compatibility mesh" % hand_name,scene)
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
			_fail("café compatibility forearm should start with soft SleeveFabric",scene)
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
			_fail("bar %s compatibility forearm must switch to HandSkin" % hand_name,scene)
			return
		var cinematic_forearm := scene.get_node("%s/CinematicForearm" % hand_name) as MeshInstance3D
		if cinematic_forearm.material_override == null or cinematic_forearm.material_override.resource_name != "CinematicHandSkin":
			_fail("bar %s cinematic forearm must switch to skin" % hand_name,scene)
			return

	# HandChoreographyPresentation already owns the untouched peel-hand rest.
	# That rest must be grounded on the real attached label edge rather than a
	# venue-specific floating XYZ target. Measure the visible pinch anchor after
	# deterministic settle so screenshots cannot show an OK-sign pinching air.
	var choreography := scene.get_node_or_null("HandChoreographyPresentation") as Node
	if choreography == null:
		_fail("missing HandChoreographyPresentation support owner",scene)
		return
	for _step in range(12):
		choreography.call("_process",0.1)
	var right := scene.get_node("RightHand") as HandVisual
	var label := scene.get_node("PeelLabel") as LabelVisual
	var edge_world := label.to_global(label.get_front_position(0.0))
	var idle_gap := right.get_pinch_world_position().distance_to(edge_world)
	if idle_gap > MAX_IDLE_PEEL_EDGE_GAP:
		_fail("idle peel pinch must rest at real label edge, gap %.3f > %.3f" % [idle_gap,MAX_IDLE_PEEL_EDGE_GAP],scene)
		return

	# Support-root choreography has one owner. ForearmPresentation owns geometry
	# and venue material only; HandChoreographyPresentation owns glass grip root
	# placement and inspection-follow. Two writers caused small reset drift and
	# would become visible jitter once higher-fidelity arms are introduced.
	if presentation.has_method("_update_support_hand"):
		_fail("ForearmPresentation must not retain glass support-root ownership",scene)
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
			_fail("market %s compatibility forearm must stay natural HandSkin" % hand_name,scene)
			return
		var cinematic_forearm := scene.get_node("%s/CinematicForearm" % hand_name) as MeshInstance3D
		if cinematic_forearm.material_override == null or cinematic_forearm.material_override.resource_name != "CinematicHandSkin":
			_fail("market %s cinematic forearm must stay natural skin" % hand_name,scene)
			return

	print("PASS: reference-scale hands, cinematic smooth shells, diagonal forearms, edge-grounded peel rest and single-owner grip choreography stay coherent")
	scene.queue_free()
	await process_frame
	quit(0)

func _fail(message: String, scene: Node = null) -> void:
	push_error("FOREARM_RED: %s" % message)
	if scene != null:
		scene.queue_free()
	await process_frame
	quit(1)
