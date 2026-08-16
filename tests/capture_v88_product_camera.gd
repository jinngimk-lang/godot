extends SceneTree

const OUTPUT_DIR := "res://artifacts/v88_product_camera"
const CANDIDATE_PATH := "res://assets/models/hands/staging/support_limb_v88.glb"
const BASE_YAW_DEG := -40.0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	var candidate_scene := load(CANDIDATE_PATH) as PackedScene
	if packed == null or candidate_scene == null:
		push_error("V88_PRODUCT_CAMERA_RED: scene or generated candidate GLB did not load")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	await _settle(12)

	var xr_hand := scene.get_node_or_null("LeftHand") as Node3D
	if xr_hand == null:
		push_error("V88_PRODUCT_CAMERA_RED: baseline LeftHand missing")
		quit(1)
		return

	var candidate := candidate_scene.instantiate() as Node3D
	if candidate == null:
		push_error("V88_PRODUCT_CAMERA_RED: candidate GLB did not instantiate as Node3D")
		quit(1)
		return
	candidate.name = "V88SupportCandidate"
	scene.add_child(candidate)
	candidate.visible = false
	candidate.position = Vector3(0.0,0.24,0.0)
	candidate.rotation_degrees = Vector3(0.0,BASE_YAW_DEG,0.0)

	# Same exact product camera: baseline first, then only swap support-hand presentation.
	scene.call("debug_select_variant",1)
	await _settle(8)
	if not await _capture("bar_xr"): return
	xr_hand.visible = false
	candidate.scale = Vector3.ONE*9.0 # 0.342 amber bottle radius / 0.038 proxy radius
	candidate.visible = true
	await _settle(8)
	if not await _capture("bar_v88"): return

	candidate.visible = false
	xr_hand.visible = true
	scene.call("debug_select_variant",2)
	await _settle(8)
	if not await _capture("market_xr"): return
	xr_hand.visible = false
	candidate.scale = Vector3.ONE*(0.330/0.038)
	candidate.visible = true
	await _settle(8)
	if not await _capture("market_v88"): return

	# Product-camera inspection proof: the candidate itself remains static staging geometry;
	# rotating the real product reveals whether the chosen enclosure survives a common state.
	scene.call("_apply_inspection_yaw",0.45)
	await _settle(8)
	if not await _capture("market_v88_inspect45"): return

	print("PASS: captured same-camera XR/V88 support-hand product staging")
	quit(0)

func _capture(name: String) -> bool:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("V88_PRODUCT_CAMERA_RED: empty viewport for %s" % name)
		quit(1)
		return false
	var path := "%s/%s.png" % [OUTPUT_DIR,name]
	var error := image.save_png(path)
	if error != OK:
		push_error("V88_PRODUCT_CAMERA_RED: failed to save %s" % path)
		quit(1)
		return false
	print("V88_CAPTURE: %s" % path)
	return true

func _settle(count: int) -> void:
	for _i in range(count):
		await process_frame
