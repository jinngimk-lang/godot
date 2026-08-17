extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var visual_path := "res://scripts/peel/label_visual.gd"
	if not ResourceLoader.exists(visual_path):
		failures.append("CAFE_RECEIPT_READABILITY_RED: missing LabelVisual")
		return failures

	var visual = load(visual_path).new()
	if not visual.has_method("get_front_paper_bounce") or not visual.has_method("is_front_paper_bounce_texture_linked"):
		failures.append("CAFE_RECEIPT_READABILITY_RED: thermal receipt needs bounded texture-linked paper bounce")
		visual.free()
		return failures

	var thermal := {
		"substrate":"thermal_paper",
		"roughness":0.94,
		"thickness_scale":0.92,
		"fiber_scale":0.82,
		"paper_bounce":0.18
	}
	visual.apply_profile(thermal)
	var cafe_bounce := float(visual.get_front_paper_bounce())
	if cafe_bounce < 0.10 or cafe_bounce > 0.28:
		failures.append("CAFE_RECEIPT_READABILITY_RED: thermal receipt paper bounce must stay subtle and bounded; got %.3f" % cafe_bounce)
	if not bool(visual.is_front_paper_bounce_texture_linked()):
		failures.append("CAFE_RECEIPT_READABILITY_RED: paper bounce must follow the print texture so dark receipt text stays dark")

	var fibrous := {
		"substrate":"uncoated_fiber",
		"roughness":0.88,
		"thickness_scale":1.22,
		"fiber_scale":1.35
	}
	visual.apply_profile(fibrous)
	if float(visual.get_front_paper_bounce()) > 0.001:
		failures.append("CAFE_RECEIPT_READABILITY_RED: bar fibrous label must not inherit Café paper bounce")

	var coated := {
		"substrate":"coated_citrus",
		"roughness":0.66,
		"thickness_scale":0.72,
		"fiber_scale":0.58
	}
	visual.apply_profile(coated)
	if float(visual.get_front_paper_bounce()) > 0.001:
		failures.append("CAFE_RECEIPT_READABILITY_RED: market coated label must not inherit Café paper bounce")

	visual.free()
	return failures
