extends SceneTree

const TRANSFORM_TOLERANCE := 0.0005
const PALETTE_TOLERANCE := 0.0005
const MIN_LABEL_CLEARANCE := 0.010

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: Array[String] = []
	var packed := load("res://scenes/peel_lab/peel_lab.tscn") as PackedScene
	if packed == null:
		push_error("PAPER_CUP_VERIFY: production peel scene failed to load")
		quit(1)
		return

	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame

	var presentation := scene.get_node_or_null("CafePresentation") as CafePresentation
	var cup := scene.get_node_or_null("Cup") as MeshInstance3D
	var label := scene.get_node_or_null("PeelLabel") as LabelVisual
	var session = scene.get("_session")
	if presentation == null or cup == null or label == null or session == null or not (cup.mesh is CylinderMesh):
		push_error("PAPER_CUP_VERIFY: production presentation/Cup/PeelLabel/session contract missing")
		quit(1)
		return

	var seam := presentation.get_node_or_null("CupPaperSeam") as MeshInstance3D
	var fold := presentation.get_node_or_null("CupBaseFold") as MeshInstance3D
	var lip := presentation.get_node_or_null("CupLipShadow") as MeshInstance3D
	if seam == null or fold == null or lip == null:
		push_error("PAPER_CUP_RED: production paper-cup details missing")
		quit(1)
		return

	# Exercise the real production progression path instead of hand-editing Cup colors.
	var seen_ids: Array[String] = []
	var seen_colors: Array[Color] = []
	_check_current_variant_palette(scene, cup, seam, fold, lip, session, seen_ids, seen_colors, failures)

	# Two clean peels unlock Silky Long; production advance applies its label/Cup palette.
	session.record_clean_peel(100)
	session.record_clean_peel(100)
	scene.call("_advance_to_next_item")
	await process_frame
	_check_current_variant_palette(scene, cup, seam, fold, lip, session, seen_ids, seen_colors, failures)

	# Five total clean peels unlock Crisp Seal; advance from Silky to Crisp.
	session.record_clean_peel(100)
	session.record_clean_peel(100)
	session.record_clean_peel(100)
	scene.call("_advance_to_next_item")
	await process_frame
	_check_current_variant_palette(scene, cup, seam, fold, lip, session, seen_ids, seen_colors, failures)

	if seen_ids != ["warm_paper", "silky_long", "crisp_seal"]:
		failures.append("PAPER_CUP_RED: verifier did not exercise all production tactile variants in order: %s" % str(seen_ids))
	if seen_colors.size() == 3 and (seen_colors[0].is_equal_approx(seen_colors[1]) or seen_colors[1].is_equal_approx(seen_colors[2]) or seen_colors[0].is_equal_approx(seen_colors[2])):
		failures.append("PAPER_CUP_RED: production variants must exercise distinct Cup palettes")

	# Details must follow an arbitrary Cup translation+rotation without changing their Cup-local transforms.
	var seam_relative_before := cup.global_transform.affine_inverse() * seam.global_transform
	var fold_relative_before := cup.global_transform.affine_inverse() * fold.global_transform
	var lip_relative_before := cup.global_transform.affine_inverse() * lip.global_transform
	var seam_global_before := seam.global_transform
	cup.position += Vector3(0.22, 0.08, -0.12)
	cup.rotate_y(0.37)
	await process_frame
	await process_frame
	var seam_relative_after := cup.global_transform.affine_inverse() * seam.global_transform
	var fold_relative_after := cup.global_transform.affine_inverse() * fold.global_transform
	var lip_relative_after := cup.global_transform.affine_inverse() * lip.global_transform
	if _transform_error(seam_relative_before, seam_relative_after) > TRANSFORM_TOLERANCE:
		failures.append("PAPER_CUP_RED: CupPaperSeam drifts from Cup-local transform after Cup motion")
	if _transform_error(fold_relative_before, fold_relative_after) > TRANSFORM_TOLERANCE:
		failures.append("PAPER_CUP_RED: CupBaseFold drifts from Cup-local transform after Cup motion")
	if _transform_error(lip_relative_before, lip_relative_after) > TRANSFORM_TOLERANCE:
		failures.append("PAPER_CUP_RED: CupLipShadow drifts from Cup-local transform after Cup motion")
	if _transform_error(seam_global_before, seam.global_transform) < 0.05:
		failures.append("PAPER_CUP_RED: structural details did not actually follow moved/rotated Cup")

	# Seam may sit behind the widest label angular span, but it must stay radially behind
	# the label surface by a meaningful margin so it cannot z-fight/occlude the peel face.
	var cup_mesh := cup.mesh as CylinderMesh
	if not (seam.mesh is ArrayMesh):
		failures.append("PAPER_CUP_RED: CupPaperSeam lost ArrayMesh contract")
	else:
		var arrays := (seam.mesh as ArrayMesh).surface_get_arrays(0)
		var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array if arrays.size() > Mesh.ARRAY_VERTEX else PackedVector3Array()
		if vertices.is_empty():
			failures.append("PAPER_CUP_RED: CupPaperSeam has no vertices")
		else:
			var max_seam_offset := -INF
			for vertex in vertices:
				var cup_local := cup.to_local(seam.to_global(vertex))
				var expected_radius := _cup_radius_at_y(cup_mesh, cup_local.y)
				var actual_radius := Vector2(cup_local.x, cup_local.z).length()
				max_seam_offset = maxf(max_seam_offset, actual_radius - expected_radius)
			var clearance := label.surface_offset - max_seam_offset
			if clearance < MIN_LABEL_CLEARANCE:
				failures.append("PAPER_CUP_RED: paper seam sits too close/in front of label surface; clearance=%.6f" % clearance)

	# Base fold and lip shadow must remain vertically outside every production label band.
	var label_min_y := label.label_y - label.label_height * 0.5 - cup.global_position.y
	var label_max_y := label.label_y + label.label_height * 0.5 - cup.global_position.y
	for detail in [fold, lip]:
		var bounds := _cup_local_y_bounds(cup, detail)
		if _ranges_overlap(float(bounds.x), float(bounds.y), label_min_y, label_max_y):
			failures.append("PAPER_CUP_RED: %s vertically overlaps active label band %.3f..%.3f with %.3f..%.3f" % [detail.name, label_min_y, label_max_y, bounds.x, bounds.y])

	# Release the production scene before isolated fallback checks to avoid multiple
	# WorldEnvironment nodes producing unrelated warnings in one SceneTree.
	scene.queue_free()
	await process_frame
	await process_frame

	await _check_missing_or_wrong_cup_fallback(false, failures)
	await _check_missing_or_wrong_cup_fallback(true, failures)

	if failures.is_empty():
		print("PASS: paper-cup structure follows all variant palettes/Cup transforms, stays behind label, and degrades safely without a tapered Cup; variants=%s" % str(seen_ids))
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_current_variant_palette(
	scene: Node,
	cup: MeshInstance3D,
	seam: MeshInstance3D,
	fold: MeshInstance3D,
	lip: MeshInstance3D,
	session,
	seen_ids: Array[String],
	seen_colors: Array[Color],
	failures: Array[String]
) -> void:
	var variant: Dictionary = session.current_variant()
	var variant_id := String(variant.get("id", ""))
	var cup_material := cup.material_override as StandardMaterial3D
	if cup_material == null:
		failures.append("PAPER_CUP_RED: production Cup lost StandardMaterial3D for %s" % variant_id)
		return
	var cup_color := cup_material.albedo_color
	seen_ids.append(variant_id)
	seen_colors.append(cup_color)
	var expectations := [
		[seam, 0.78, "CupPaperSeam"],
		[fold, 0.74, "CupBaseFold"],
		[lip, 0.55, "CupLipShadow"],
	]
	for expectation in expectations:
		var detail := expectation[0] as MeshInstance3D
		var scale := float(expectation[1])
		var detail_name := String(expectation[2])
		if detail.material_override == null or not (detail.material_override is StandardMaterial3D):
			failures.append("PAPER_CUP_RED: %s missing StandardMaterial3D for %s" % [detail_name, variant_id])
			continue
		var actual := (detail.material_override as StandardMaterial3D).albedo_color
		var expected := Color(cup_color.r * scale, cup_color.g * scale, cup_color.b * scale, cup_color.a)
		if _color_error(actual, expected) > PALETTE_TOLERANCE:
			failures.append("PAPER_CUP_RED: %s palette failed to track %s; actual=%s expected=%s" % [detail_name, variant_id, str(actual), str(expected)])

func _check_missing_or_wrong_cup_fallback(with_box_cup: bool, failures: Array[String]) -> void:
	var parent := Node3D.new()
	parent.name = "FallbackParent"
	root.add_child(parent)
	if with_box_cup:
		var cup := MeshInstance3D.new()
		cup.name = "Cup"
		cup.mesh = BoxMesh.new()
		parent.add_child(cup)
	var presentation := CafePresentation.new()
	presentation.name = "CafePresentation"
	parent.add_child(presentation)
	await process_frame
	await process_frame
	await process_frame
	for detail_name in ["CupPaperSeam", "CupBaseFold", "CupLipShadow"]:
		if presentation.get_node_or_null(detail_name) != null:
			failures.append("PAPER_CUP_RED: %s fallback must not build %s" % ["non-Cylinder Cup" if with_box_cup else "missing Cup", detail_name])
	parent.queue_free()
	await process_frame

func _cup_radius_at_y(cup_mesh: CylinderMesh, y: float) -> float:
	var height := maxf(cup_mesh.height, 0.001)
	var t := clampf((y + height * 0.5) / height, 0.0, 1.0)
	return lerpf(cup_mesh.bottom_radius, cup_mesh.top_radius, t)

func _cup_local_y_bounds(cup: MeshInstance3D, detail: MeshInstance3D) -> Vector2:
	if detail.mesh == null:
		return Vector2(INF, -INF)
	var aabb := detail.mesh.get_aabb()
	var min_y := INF
	var max_y := -INF
	for x in [aabb.position.x, aabb.end.x]:
		for y in [aabb.position.y, aabb.end.y]:
			for z in [aabb.position.z, aabb.end.z]:
				var cup_local := cup.to_local(detail.to_global(Vector3(x, y, z)))
				min_y = minf(min_y, cup_local.y)
				max_y = maxf(max_y, cup_local.y)
	return Vector2(min_y, max_y)

func _ranges_overlap(a_min: float, a_max: float, b_min: float, b_max: float) -> bool:
	return maxf(a_min, b_min) <= minf(a_max, b_max)

func _color_error(a: Color, b: Color) -> float:
	return maxf(absf(a.r - b.r), maxf(absf(a.g - b.g), maxf(absf(a.b - b.b), absf(a.a - b.a))))

func _transform_error(a: Transform3D, b: Transform3D) -> float:
	var origin_error := a.origin.distance_to(b.origin)
	var basis_error := maxf(
		a.basis.x.distance_to(b.basis.x),
		maxf(a.basis.y.distance_to(b.basis.y), a.basis.z.distance_to(b.basis.z))
	)
	return maxf(origin_error, basis_error)
