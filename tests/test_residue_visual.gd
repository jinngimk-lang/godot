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
	residue.set_residue(0.0, 0.0, 1.0)
	if residue.get_residue_amount() != 0.0:
		failures.append("residue visual should clear at reset")
	residue.free()
	return failures
