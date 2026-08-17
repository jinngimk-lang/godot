extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var path := "res://scripts/peel/label_visual.gd"
	if not ResourceLoader.exists(path):
		failures.append("LABEL_BACKING_RED: missing LabelVisual")
		return failures
	var visual = load(path).new()
	visual.label_width = 1.0
	visual.label_height = 0.36
	visual.segments = 24
	for method in ["get_backing_material", "get_backing_signature", "has_distinct_peeled_backing"]:
		if not visual.has_method(method):
			failures.append("LABEL_BACKING_RED: LabelVisual missing %s" % method)
	if not failures.is_empty():
		visual.free()
		return failures

	var profiles := [
		{
			"substrate":"thermal_paper",
			"roughness":0.94,
			"thickness_scale":0.92,
			"fiber_scale":0.82,
			"edge_tint":Color(0.78,0.74,0.64),
			"backing_tint":Color(0.94,0.91,0.83),
			"backing_roughness":0.96,
			"adhesive_tint":Color(0.84,0.78,0.62)
		},
		{
			"substrate":"uncoated_fiber",
			"roughness":0.88,
			"thickness_scale":1.22,
			"fiber_scale":1.35,
			"edge_tint":Color(0.62,0.48,0.32),
			"backing_tint":Color(0.91,0.82,0.66),
			"backing_roughness":0.99,
			"adhesive_tint":Color(0.88,0.72,0.48)
		},
		{
			"substrate":"coated_citrus",
			"roughness":0.66,
			"thickness_scale":0.72,
			"fiber_scale":0.58,
			"edge_tint":Color(0.82,0.86,0.72),
			"backing_tint":Color(0.95,0.96,0.88),
			"backing_roughness":0.90,
			"adhesive_tint":Color(0.78,0.86,0.66)
		}
	]
	var signatures: Array[String] = []
	for profile in profiles:
		visual.apply_profile(profile)
		var backing = visual.get_backing_material() as StandardMaterial3D
		if backing == null:
			failures.append("LABEL_BACKING_RED: profile must create a real StandardMaterial3D backing")
			continue
		if backing.albedo_texture != null:
			failures.append("LABEL_BACKING_RED: peeled underside must not reuse the printed front texture")
		if backing.roughness < 0.86:
			failures.append("LABEL_BACKING_RED: peeled paper backing must remain visibly fibrous/matte")
		signatures.append(String(visual.get_backing_signature()))
	if signatures.size() == 3 and (signatures[0] == signatures[1] or signatures[1] == signatures[2] or signatures[0] == signatures[2]):
		failures.append("LABEL_BACKING_RED: café/bar/market peeled backing signatures must differ")

	visual.apply_profile(profiles[1])
	visual.set_peel(0.52,visual.get_front_position(0.52)+Vector3(-0.70,0.08,0.48))
	if not bool(visual.has_distinct_peeled_backing()):
		failures.append("LABEL_BACKING_RED: a partially peeled label must build a separate visible underside surface")
	if visual.mesh == null or visual.mesh.get_surface_count() < 4:
		failures.append("LABEL_BACKING_RED: partial peel needs front + distinct backing + physical paper edge surfaces")

	visual.free()
	return failures
