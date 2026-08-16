extends SceneTree

const OUTPUT_DIR := "res://artifacts/v88_product_camera"
const CANDIDATE_PATH := "res://assets/models/hands/staging/support_limb_v88.glb"
const BASE_YAW_DEG := -40.0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	var candidate := _load_runtime_glb(CANDIDATE_PATH)
	if packed == null or candidate == null:
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

	candidate.name = "V88SupportCandidate"
	scene.add_child(candidate)
	candidate.visible = false
	# The exported candidate report defines the GLB root as the proxy vessel
	# center. Align that root directly with the real product origin. The previous
	# +0.24 m Y staging offset was not part of the authored pose and pushed the
	# palm above the bottle, contaminating the first product-camera verdict.
	candidate.position = Vector3.ZERO
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

# The v88 GLB is created during this CI job, after the checked-out project has
# already been scanned by Godot. Loading it through ResourceLoader therefore
# depends on editor import-cache timing. GLTFDocument is the runtime glTF API:
# read the just-generated source file directly, then generate a Godot scene.
# This also avoids a global editor import pass trying to import unrelated .blend
# authoring evidence in headless CI.
func _load_runtime_glb(path: String) -> Node3D:
	if not FileAccess.file_exists(path):
		push_error("V88_PRODUCT_CAMERA_RED: generated GLB source missing: %s" % path)
		return null
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var absolute_path := ProjectSettings.globalize_path(path)
	var error := document.append_from_file(absolute_path,state,0,absolute_path.get_base_dir())
	if error != OK:
		push_error("V88_PRODUCT_CAMERA_RED: GLTFDocument append failed (%d): %s" % [error,path])
		return null
	var generated := document.generate_scene(state)
	if not (generated is Node3D):
		if generated != null:
			generated.free()
		push_error("V88_PRODUCT_CAMERA_RED: GLTFDocument did not generate Node3D")
		return null
	return generated as Node3D

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
