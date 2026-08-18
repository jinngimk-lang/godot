extends SceneTree

const MAX_SURFACE_ERROR := 0.004
const MIN_SURFACE_NORMAL_DOT := 0.999
const PROFILE_NAMES := ["coffee_shop","sauce_jar","tin_can","yuzu_bottle","lemon_can"]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("LABEL_SURFACE_SMOKE: peel_lab scene failed to load")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await _settle_frames(3)

	var cup := scene.get_node_or_null("Cup") as MeshInstance3D
	var label := scene.get_node_or_null("PeelLabel") as LabelVisual
	var session = scene.get("_session")
	if cup == null or label == null or session == null:
		push_error("LABEL_SURFACE_SMOKE: Cup, PeelLabel or SessionModel missing")
		quit(1)
		return

	# Every hero object keeps the same hidden tapered interaction-cylinder
	# contract so the real LabelVisual can be reused without any hand proxy.
	for i in range(PROFILE_NAMES.size()):
		scene.call("debug_select_variant",i)
		await _settle_frames(2)
		var failure := _surface_failure(cup,label,PROFILE_NAMES[i])
		if not failure.is_empty():
			push_error(failure)
			quit(1)
			return

	print("PASS: attached label follows all five object interaction silhouettes within %.3f m" % MAX_SURFACE_ERROR)
	scene.queue_free()
	await process_frame
	quit(0)

func _surface_failure(cup: MeshInstance3D, label: LabelVisual, profile_name: String) -> String:
	if not (cup.mesh is CylinderMesh):
		return "LABEL_SURFACE_SMOKE: Cup must expose CylinderMesh taper contract"
	if label.mesh == null or label.mesh.get_surface_count() == 0:
		return "LABEL_SURFACE_SMOKE: %s PeelLabel has no renderable surface" % profile_name
	var cup_mesh := cup.mesh as CylinderMesh
	var arrays := label.mesh.surface_get_arrays(0)
	if arrays.size() <= Mesh.ARRAY_VERTEX or not (arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array):
		return "LABEL_SURFACE_SMOKE: %s PeelLabel surface has no vertex array" % profile_name
	if arrays.size() <= Mesh.ARRAY_NORMAL or not (arrays[Mesh.ARRAY_NORMAL] is PackedVector3Array):
		return "LABEL_SURFACE_SMOKE: %s PeelLabel surface has no normal array" % profile_name
	var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var normals := arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array
	if vertices.is_empty() or normals.size()!=vertices.size():
		return "LABEL_SURFACE_SMOKE: %s invalid label vertex/normal arrays" % profile_name
	var max_error := 0.0
	var min_normal_dot := 1.0
	var height := maxf(cup_mesh.height,0.001)
	var taper_slope := (cup_mesh.top_radius-cup_mesh.bottom_radius)/height
	for i in range(vertices.size()):
		var cup_local := cup.to_local(label.to_global(vertices[i]))
		var t := clampf((cup_local.y+height*0.5)/height,0.0,1.0)
		var expected_radius := lerpf(cup_mesh.bottom_radius,cup_mesh.top_radius,t)+label.surface_offset
		var actual_radius := Vector2(cup_local.x,cup_local.z).length()
		max_error = maxf(max_error,absf(actual_radius-expected_radius))
		var radial := Vector3(cup_local.x,0.0,cup_local.z).normalized()
		if radial.length_squared()<=0.000001:
			return "LABEL_SURFACE_SMOKE: %s label vertex cannot define a radial normal" % profile_name
		var expected_normal := Vector3(radial.x,-taper_slope,radial.z).normalized()
		var world_normal := (label.global_transform.basis*normals[i]).normalized()
		var cup_local_normal := (cup.global_transform.basis.inverse()*world_normal).normalized()
		min_normal_dot = minf(min_normal_dot,clampf(cup_local_normal.dot(expected_normal),-1.0,1.0))
	if max_error>MAX_SURFACE_ERROR:
		return "LABEL_SURFACE_SMOKE: %s label radial error %.5f exceeds %.5f" % [profile_name,max_error,MAX_SURFACE_ERROR]
	if min_normal_dot<MIN_SURFACE_NORMAL_DOT:
		return "LABEL_SURFACE_SMOKE: %s taper-aware normal dot %.6f below %.6f" % [profile_name,min_normal_dot,MIN_SURFACE_NORMAL_DOT]
	return ""

func _settle_frames(count: int) -> void:
	for _i in range(count): await process_frame
