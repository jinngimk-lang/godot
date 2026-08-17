extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var path := "res://scripts/presentation/residue_visual.gd"
	if not ResourceLoader.exists(path):
		failures.append("RED: missing ResidueVisual")
		return failures
	var residue = load(path).new()
	residue.configure(0.45, 0.54, 1.45, 0.05, 1.15, 0.40)
	residue.set_residue(0.62, 0.34, 0.72)
	if residue.get_residue_amount() < 0.33:
		failures.append("residue visual should retain deterministic residue amount")
	if residue.mesh == null or residue.mesh.get_surface_count() <= 0:
		failures.append("positive residue should build visible torn-paper geometry")
	else:
		if residue.mesh.get_surface_count() < 2:
			failures.append("RED: residue must separate translucent adhesive film from opaque fibrous backing instead of one flat paper sheet")
		else:
			var adhesive := residue.mesh.surface_get_material(0) as StandardMaterial3D
			var fibers := residue.mesh.surface_get_material(1) as StandardMaterial3D
			if adhesive == null or adhesive.transparency != BaseMaterial3D.TRANSPARENCY_ALPHA:
				failures.append("RED: residue adhesive layer must be a translucent StandardMaterial3D")
			elif adhesive.albedo_color.a < 0.10 or adhesive.albedo_color.a > 0.52:
				failures.append("RED: residue adhesive film needs bounded translucent alpha; got %.3f" % adhesive.albedo_color.a)
			if fibers == null:
				failures.append("RED: residue fiber layer must expose its own StandardMaterial3D")
			else:
				if fibers.roughness < 0.82:
					failures.append("RED: torn backing fibers should stay dry/matte; roughness=%.3f" % fibers.roughness)
				if fibers.albedo_color.a < adhesive.albedo_color.a + 0.18:
					failures.append("RED: fibrous backing should read more opaque than the glue film")
	if not residue.has_layered_residue():
		failures.append("RED: semantic residue state should report layered adhesive + fiber presentation")
	var low_damage_fiber: float = float(residue.get_fiber_strength())
	residue.set_residue(0.62, 0.34, 0.32)
	var high_damage_fiber: float = float(residue.get_fiber_strength())
	if high_damage_fiber <= low_damage_fiber + 0.08:
		failures.append("RED: lower label integrity should visibly increase fibrous backing strength")
	residue.set_residue(0.0, 0.0, 1.0)
	if residue.get_residue_amount() != 0.0:
		failures.append("residue visual should clear at reset")
	if residue.mesh != null and residue.mesh.get_surface_count() != 0:
		failures.append("reset should remove every adhesive/fiber residue surface")
	residue.free()
	return failures
