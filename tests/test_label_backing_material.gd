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
	# This focused unit fixture is not mounted into SceneTree, so initialize the
	# MeshInstance3D exactly once before asserting runtime mesh surfaces. The
	# product path reaches the same code via SceneTree _ready().
	visual._ready()
	for method in ["get_backing_material", "get_backing_signature", "has_distinct_peeled_backing", "get_peel_roll_angle"]:
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

	# The loose flap must physically roll back toward its grip so the pale glue
	# side can face the product camera. The roll is a deterministic paper rule:
	# strongest at the free end, tapering continuously to zero at the adhesive
	# peel front, with no roll on still-attached stock.
	var p := 0.52
	var free_roll: float = absf(float(visual.get_peel_roll_angle(0.0,p)))
	var mid_roll: float = absf(float(visual.get_peel_roll_angle(p*0.45,p)))
	var front_roll: float = absf(float(visual.get_peel_roll_angle(p,p)))
	var attached_roll: float = absf(float(visual.get_peel_roll_angle(minf(p+0.18,1.0),p)))
	if free_roll < deg_to_rad(105.0):
		failures.append("LABEL_BACKING_RED: free peel edge must fold back >105° so backing can face camera; got %.1f°" % rad_to_deg(free_roll))
	if mid_roll <= deg_to_rad(24.0) or mid_roll >= free_roll:
		failures.append("LABEL_BACKING_RED: flap roll should decay through the loose span instead of behaving like a rigid plate")
	if front_roll > deg_to_rad(1.0) or attached_roll > deg_to_rad(1.0):
		failures.append("LABEL_BACKING_RED: peel-front/attached stock must remain tangent to the vessel without artificial roll")
	if not is_equal_approx(float(visual.get_peel_roll_angle(0.0,p)),float(visual.get_peel_roll_angle(0.0,p))):
		failures.append("LABEL_BACKING_RED: peel roll must be deterministic for identical state")

	visual.apply_profile(profiles[1])
	visual.set_peel(p,visual.get_front_position(p)+Vector3(-0.70,0.08,0.48))
	if not bool(visual.has_distinct_peeled_backing()):
		failures.append("LABEL_BACKING_RED: a partially peeled label must build a separate visible underside surface")
	var surface_count: int = visual.mesh.get_surface_count() if visual.mesh != null else 0
	if surface_count < 4:
		failures.append("LABEL_BACKING_RED: partial peel needs front + distinct backing + glue-side/physical paper edge surfaces; got %d" % surface_count)

	visual.free()
	return failures
