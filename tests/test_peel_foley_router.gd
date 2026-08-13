extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var router_path := "res://scripts/audio/peel_foley_router.gd"
	if not ResourceLoader.exists(router_path):
		failures.append("RED: missing physical peel foley router")
		return failures

	var router_script = load(router_path)
	if router_script == null:
		failures.append("PeelFoleyRouter script did not load")
		return failures

	var router = router_script.new()
	router.reset()

	var events: Array[String] = router.update(false, 0.0, 0.0, 0.0, false, 0.016)
	if events.has("slow") or events.has("fast") or events.has("paper_flex"):
		failures.append("idle foley router must remain quiet")

	events = router.update(true, 1.2, 12.0, 0.0, false, 0.016)
	if not events.has("slow"):
		failures.append("low-speed active peel should select slow foley")
	if events.has("fast"):
		failures.append("low-speed active peel must not select fast foley")

	events = router.update(true, 10.0, 18.0, 0.0, false, 0.016)
	if not events.has("fast"):
		failures.append("high-speed active peel should select fast foley")

	# Paper flex is motion feedback, not a metronome for held tension. Once the
	# cooldown has expired, a stationary held peel must stay quiet until either
	# the pointer moves again or the label actually releases more material.
	router.reset()
	events = router.update(true, 0.0, 18.0, 0.0, false, 0.20)
	if events.has("paper_flex"):
		failures.append("RED: stationary sustained peel tension must not retrigger paper_flex")

	events = router.update(true, 0.7, 18.0, 0.0, false, 0.20)
	if not events.has("paper_flex"):
		failures.append("slow real pointer motion under tension should allow paper_flex")

	events = router.update(true, 0.0, 18.0, 0.01, false, 0.20)
	if not events.has("paper_flex"):
		failures.append("incremental label release should allow paper_flex even at near-zero pointer speed")

	events = router.update(true, 3.0, 18.0, 0.05, false, 0.20)
	if not events.has("micro_release"):
		failures.append("meaningful incremental release should emit micro_release")
	events = router.update(true, 3.0, 18.0, 0.05, false, 0.01)
	if events.has("micro_release"):
		failures.append("micro_release must be cooldown limited")

	events = router.update(false, 0.0, 0.0, 0.0, true, 0.016)
	if not events.has("final_release"):
		failures.append("detach transition should emit final_release")
	events = router.update(false, 0.0, 0.0, 0.0, true, 0.016)
	if events.has("final_release"):
		failures.append("final_release must emit once until reset")

	router.reset()
	events = router.update(false, 0.0, 0.0, 0.0, true, 0.016)
	if not events.has("final_release"):
		failures.append("reset should re-arm final_release")

	return failures
