extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var path := "res://scripts/peel/residue_scrub_model.gd"
	if not ResourceLoader.exists(path):
		failures.append("SCRUB_RED: missing post-peel residue scrub model")
		return failures
	var scrub = load(path).new({"required_travel":240.0,"reversal_bonus":0.45})
	var region := Rect2(400,220,280,230)

	# Hovering, holding still, or dragging elsewhere must never clean adhesive.
	scrub.update(false,Vector2(500,300),Vector2(48,0),region,1.0/60.0)
	scrub.update(true,Vector2(500,300),Vector2.ZERO,region,1.0/60.0)
	scrub.update(true,Vector2(760,300),Vector2(48,0),region,1.0/60.0)
	if scrub.get_progress() > 0.0001:
		failures.append("SCRUB_RED: cleanup needs pressed movement inside the visible residue region")

	# Repeated short direction changes model rubbing instead of accepting one fling.
	var position := Vector2(500,300)
	for i in range(48):
		var relative := Vector2(18 if i % 2 == 0 else -18,2 if i % 4 < 2 else -2)
		position += relative
		scrub.update(true,position,relative,region,1.0/60.0)
		if scrub.is_complete():
			break
	if not scrub.is_complete() or scrub.get_progress() < 0.999:
		failures.append("SCRUB_RED: deliberate back-and-forth residue rubbing must reach clean")
	if not scrub.consume_completed_event():
		failures.append("SCRUB_RED: completion must emit one clean-result event")
	if scrub.consume_completed_event():
		failures.append("SCRUB_RED: clean-result event must be exactly once")

	scrub.reset()
	if scrub.get_progress() != 0.0 or scrub.is_complete():
		failures.append("SCRUB_RED: reset must restore an untouched residue pass")
	return failures
