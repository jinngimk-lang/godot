extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var residue = load("res://scripts/presentation/residue_visual.gd").new()
	if not residue.has_method("get_trace_mode"):
		residue.free()
		return ["RESOLVED_TRACE_RED: residue renderer needs an explicit completion trace mode"]

	var paper_profile := {
		"substrate":"thermal_paper",
		"adhesive_trace":0.16,
		"adhesive_tint":Color(0.84,0.78,0.62),
		"fiber_tint":Color(0.92,0.88,0.78),
		"fiber_gain":0.86
	}
	residue.apply_profile(paper_profile)
	residue.configure(0.415,0.49,1.40,0.05,0.76,0.60,0.16)
	residue.set_residue(0.52,0.0,1.0)
	if String(residue.call("get_trace_mode")) != "peel_contact":
		failures.append("RESOLVED_TRACE_RED: mid-peel should retain continuous contact-film cues")

	residue.set_residue(1.0,0.08,0.94)
	if String(residue.call("get_trace_mode")) != "completion_streaks":
		failures.append("RESOLVED_TRACE_RED: normal paper completion must collapse to sparse tack streaks")
	if residue.mesh == null or residue.mesh.get_surface_count() != 1:
		failures.append("RESOLVED_TRACE_RED: normal completion should use one sparse adhesive surface")

	residue.set_residue(1.0,0.34,0.72)
	if String(residue.call("get_trace_mode")) != "damaged_fibers":
		failures.append("RESOLVED_TRACE_RED: genuinely damaged completion must preserve fibrous evidence")

	residue.apply_profile({
		"substrate":"coated_citrus",
		"adhesive_trace":0.11,
		"adhesive_tint":Color(0.78,0.86,0.66),
		"fiber_tint":Color(0.90,0.92,0.82),
		"fiber_gain":0.65
	})
	residue.set_residue(1.0,0.05,0.98)
	if String(residue.call("get_trace_mode")) != "completion_haze":
		failures.append("RESOLVED_TRACE_RED: coated Yuzu completion should be a thin adhesive haze")
	residue.free()
	return failures
