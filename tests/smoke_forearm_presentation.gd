extends SceneTree

const MIN_FOREARM_LENGTH := 3.20
const MAX_FOREARM_LENGTH := 6.80
const MAX_FOREARM_RADIUS := 0.31
const MIN_AUTHORED_HAND_SCALE := 4.00
const MIN_INTEGRATED_LOCAL_LENGTH := 0.55

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
			_fail("fallback forearm radius out of anatomical bound at %.2f: %.3f" % [sample,radius],scene)
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
		var integrated := authored.find_child("IntegratedForearmMesh",true,false) as MeshInstance3D
		var integrated_sleeve := authored.find_child("IntegratedSleeveMesh",true,false) as MeshInstance3D
		var fallback := hand.get_node_or_null("ForearmNatural") as MeshInstance3D
		if integrated != null:
			if fallback != null and fallback.visible:
				_fail("%s must not stack procedural forearm over integrated limb" % hand_name,scene)
				return
			if integrated_sleeve == null:
				_fail("%s integrated limb needs café sleeve companion" % hand_name,scene)
				return
			var integrated_length := integrated.mesh.get_aabb().size.length() if integrated.mesh != null else 0.0
			if integrated_length < MIN_INTEGRATED_LOCAL_LENGTH:
				_fail("%s integrated forearm is too short: %.3f" % [hand_name,integrated_length],scene)
				return
			if integrated.visible or not integrated_sleeve.visible:
				_fail("café must show integrated sleeve and hide bare integrated forearm",scene)
				return
		else:
			if fallback == null or not (fallback.mesh is ArrayMesh):
				_fail("%s must use one smooth fallback ForearmNatural mesh" % hand_name,scene)
				return
			var reach := (fallback.mesh as ArrayMesh).get_aabb().size.length()
			if reach < MIN_FOREARM_LENGTH or reach > MAX_FOREARM_LENGTH:
				_fail("%s fallback forearm must continue beyond frame without runaway geometry: %.3f" % [hand_name,reach],scene)
				return
			if fallback.material_override == null or fallback.material_override.resource_name != "SleeveFabric":
				_fail("café fallback forearm should start with soft SleeveFabric",scene)
				return
		var legacy := hand.get_node_or_null("AuthoredHand/WristSleeve") as MeshInstance3D
		var legacy_cuff := hand.get_node_or_null("AuthoredHand/WristCuff") as MeshInstance3D
		if legacy != null and legacy.visible:
			_fail("%s must hide duplicate long authored sleeve" % hand_name,scene)
			return
		if legacy_cuff != null and legacy_cuff.visible:
			_fail("%s must hide old dark wrist ring" % hand_name,scene)
			return

	scene.call("debug_select_variant",1)
	await process_frame
	await process_frame
	for hand_name in ["RightHand","LeftHand"]:
		var hand := scene.get_node(hand_name) as Node3D
		var authored := hand.get_node("AuthoredHand") as Node3D
		var integrated := authored.find_child("IntegratedForearmMesh",true,false) as MeshInstance3D
		var integrated_sleeve := authored.find_child("IntegratedSleeveMesh",true,false) as MeshInstance3D
		if integrated != null:
			if not integrated.visible or (integrated_sleeve != null and integrated_sleeve.visible):
				_fail("bar must show bare integrated forearm and hide café sleeve",scene)
				return
			var material := integrated.mesh.surface_get_material(0) if integrated.mesh != null and integrated.mesh.get_surface_count()>0 else null
			if material == null or material.resource_name != "HandSkin":
				_fail("bar integrated forearm must preserve HandSkin",scene)
				return
		else:
			var fallback := hand.get_node("ForearmNatural") as MeshInstance3D
			if fallback.material_override == null or fallback.material_override.resource_name != "HandSkin":
				_fail("bar fallback %s forearm must switch to HandSkin" % hand_name,scene)
				return

	# Support-root choreography has one owner. ForearmPresentation owns geometry
	# and venue material only; HandChoreographyPresentation owns glass grip root.
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
		var hand := scene.get_node(hand_name) as Node3D
		var authored := hand.get_node("AuthoredHand") as Node3D
		var integrated := authored.find_child("IntegratedForearmMesh",true,false) as MeshInstance3D
		if integrated != null:
			if not integrated.visible:
				_fail("market integrated forearm must remain bare/visible",scene)
				return
		else:
			var fallback := hand.get_node("ForearmNatural") as MeshInstance3D
			if fallback.material_override == null or fallback.material_override.resource_name != "HandSkin":
				_fail("market fallback %s forearm must stay HandSkin" % hand_name,scene)
				return

	print("PASS: single-owner grip choreography and authored/fallback forearms stay coherent")
	scene.queue_free()
	await process_frame
	quit(0)

func _fail(message: String, scene: Node = null) -> void:
	push_error("FOREARM_RED: %s" % message)
	if scene != null:
		scene.queue_free()
	await process_frame
	quit(1)
