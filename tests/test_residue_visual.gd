extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var path := "res://scripts/presentation/residue_visual.gd"
	if not ResourceLoader.exists(path):
		failures.append("RED: missing ResidueVisual")
		return failures
	var residue = load(path).new()
	if not residue.has_method("apply_profile") or not residue.has_method("has_adhesive_trace") or not residue.has_method("get_adhesive_trace_amount"):
		failures.append("ADHESIVE_RED: residue presentation needs profile-driven clean adhesive trace semantics")
		residue.free()
		return failures

	var bar_profile := {
		"substrate":"uncoated_fiber",
		"adhesive_trace":0.22,
		"adhesive_tint":Color(0.82,0.70,0.48),
		"fiber_tint":Color(0.90,0.82,0.68),
		"fiber_gain":1.25
	}
	residue.apply_profile(bar_profile)
	residue.configure(0.45, 0.54, 1.45, 0.05, 1.15, 0.40)

	residue.set_residue(0.52, 0.0, 1.0)
	if not residue.has_adhesive_trace():
		failures.append("ADHESIVE_RED: clean partial peel must expose a visible adhesive/contact trace")
	if float(residue.get_adhesive_trace_amount()) < 0.06:
		failures.append("ADHESIVE_RED: clean adhesive trace is too weak to be perceptible")
	if float(residue.get_fiber_strength()) > 0.02:
		failures.append("ADHESIVE_RED: clean peel must not invent torn backing fibers")
	if residue.mesh == null or residue.mesh.get_surface_count() != 1:
		failures.append("ADHESIVE_RED: clean peel should build exactly one translucent glue-film surface")
	else:
		var clean_adhesive := residue.mesh.surface_get_material(0) as StandardMaterial3D
		if clean_adhesive == null or clean_adhesive.transparency != BaseMaterial3D.TRANSPARENCY_ALPHA:
			failures.append("ADHESIVE_RED: clean adhesive trace must be translucent")
		elif clean_adhesive.albedo_color.a < 0.10:
			failures.append("ADHESIVE_RED: clean glue film needs readable but restrained opacity")

	residue.set_residue(0.62, 0.34, 0.72)
	if residue.get_residue_amount() < 0.33:
		failures.append("residue visual should retain deterministic residue amount")
	if residue.mesh == null or residue.mesh.get_surface_count() < 2:
		failures.append("RED: damaged peel must separate translucent adhesive film from opaque fibrous backing")
	else:
		var adhesive := residue.mesh.surface_get_material(0) as StandardMaterial3D
		var fibers := residue.mesh.surface_get_material(1) as StandardMaterial3D
		if adhesive == null or adhesive.transparency != BaseMaterial3D.TRANSPARENCY_ALPHA:
			failures.append("RED: residue adhesive layer must be a translucent StandardMaterial3D")
		elif adhesive.albedo_color.a < 0.10 or adhesive.albedo_color.a > 0.58:
			failures.append("RED: residue adhesive film needs bounded translucent alpha; got %.3f" % adhesive.albedo_color.a)
		if fibers == null:
			failures.append("RED: residue fiber layer must expose its own StandardMaterial3D")
		else:
			if fibers.roughness < 0.82:
				failures.append("RED: torn backing fibers should stay dry/matte; roughness=%.3f" % fibers.roughness)
			if fibers.albedo_color.a < adhesive.albedo_color.a + 0.18:
				failures.append("RED: fibrous backing should read more opaque than the glue film")
	if not residue.has_layered_residue():
		failures.append("RED: damaged residue state should report layered adhesive + fiber presentation")

	if not residue.has_method("get_fiber_island_spans"):
		failures.append("RESIDUE_SHAPE_RED: damaged residue needs deterministic broad fiber-island spans")
	else:
		var islands: PackedVector2Array = residue.get_fiber_island_spans(0.62)
		if islands.size() < 3 or islands.size() > 5:
			failures.append("RESIDUE_SHAPE_RED: torn backing should use 3..5 broad islands, got %d" % islands.size())
		for island in islands:
			var width := island.y-island.x
			if island.x < -0.0001 or island.y > 0.6201 or width < 0.085:
				failures.append("RESIDUE_SHAPE_RED: fiber island must stay inside peeled span and be visibly broad, got [%.3f, %.3f]" % [island.x,island.y])
				break

	var low_damage_fiber: float = float(residue.get_fiber_strength())
	residue.set_residue(0.62, 0.34, 0.32)
	var high_damage_fiber: float = float(residue.get_fiber_strength())
	if high_damage_fiber <= low_damage_fiber + 0.08:
		failures.append("RED: lower label integrity should visibly increase fibrous backing strength")

	var bar_trace: float = float(residue.get_adhesive_trace_amount())
	residue.apply_profile({"substrate":"coated_citrus","adhesive_trace":0.11,"adhesive_tint":Color(0.78,0.86,0.66),"fiber_tint":Color(0.90,0.92,0.82),"fiber_gain":0.65})
	residue.set_residue(0.62, 0.0, 1.0)
	var market_trace: float = float(residue.get_adhesive_trace_amount())
	if market_trace >= bar_trace - 0.04:
		failures.append("ADHESIVE_RED: bar and market adhesive profiles must produce visibly different clean tack traces")

	# The coated Yuzu label leaves a thin commercial adhesive haze on glass. At
	# the normal resolved capture damage level it must not fabricate opaque paper
	# islands that read as a shattered bottle or torn curtain over the liquid.
	residue.set_residue(1.0, 0.08, 0.94)
	if float(residue.get_fiber_strength()) > 0.02 or residue.has_layered_residue():
		failures.append("YUZU_RESIDUE_RED: coated citrus residue must stay adhesive-only at normal peel damage")
	if residue.mesh == null or residue.mesh.get_surface_count() != 1:
		failures.append("YUZU_RESIDUE_RED: resolved Yuzu should render one thin glue-trace surface, not fiber islands")
	else:
		var yuzu_glue := residue.mesh.surface_get_material(0) as StandardMaterial3D
		if yuzu_glue == null or yuzu_glue.albedo_color.a > 0.34:
			failures.append("YUZU_RESIDUE_RED: glass adhesive haze is too opaque")

	residue.set_residue(0.0, 0.0, 1.0)
	if residue.get_residue_amount() != 0.0 or float(residue.get_adhesive_trace_amount()) != 0.0:
		failures.append("reset should clear damage residue and clean adhesive trace")
	if residue.mesh != null and residue.mesh.get_surface_count() != 0:
		failures.append("reset should remove every adhesive/fiber residue surface")
	residue.free()
	return failures
