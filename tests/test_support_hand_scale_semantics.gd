extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var presentation := ForearmPresentation.new()
	if not presentation.has_method("_scale_support_hand_keep_root"):
		failures.append("SUPPORT_SCALE_RED: support-hand authored scaling needs a root-preserving path distinct from peel-hand pinch preservation")
		presentation.free()
		return failures

	var hand := HandVisual.new()
	hand.setup(false)
	var staged_root := Vector3(0.60,0.22,0.40)
	hand.snap_to(staged_root)
	presentation.call("_scale_support_hand_keep_root",hand)
	if hand.position.distance_to(staged_root) > 0.000001:
		failures.append("SUPPORT_SCALE_RED: support-hand scaling moved the staged HandVisual root by %.6f" % hand.position.distance_to(staged_root))
	var authored := hand.get_node_or_null("AuthoredHand") as Node3D
	if authored == null:
		failures.append("support-hand scaling probe lost authored hand root")
	elif authored.scale.x < 4.0:
		failures.append("support-hand root-preserving path must still apply reference-scale authored hand, got %.3f" % authored.scale.x)
	hand.free()
	presentation.free()
	return failures
