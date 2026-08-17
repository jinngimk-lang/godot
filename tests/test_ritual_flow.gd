extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var required := "res://scripts/ritual/ritual_flow.gd"
	if not ResourceLoader.exists(required):
		failures.append("RED: missing pressure-free ritual flow contract")
		return failures

	var flow = load(required).new()
	if flow.get_phase_name() != "PEEL":
		failures.append("ritual flow should start in PEEL")

	if not flow.on_label_detached():
		failures.append("first detached-label event should enter ritual settle")
	if flow.on_label_detached():
		failures.append("duplicate detached-label event must be ignored")
	if flow.get_phase_name() != "PEEL_SETTLE":
		failures.append("detached label should enter PEEL_SETTLE")

	flow.update(0.44)
	if flow.get_phase_name() != "PEEL_SETTLE":
		failures.append("settle phase must not finish before its calm beat")
	flow.update(0.02)
	if flow.get_phase_name() != "CRUMPLE_READY":
		failures.append("settle phase should become CRUMPLE_READY after the calm beat")

	for _i in range(100):
		flow.update(0.1)
	if flow.get_phase_name() != "CRUMPLE_READY":
		failures.append("CRUMPLE_READY must not auto-advance on a timer")

	if not flow.begin_crumple():
		failures.append("fresh crumple intent should enter CRUMPLING")
	if flow.get_phase_name() != "CRUMPLING":
		failures.append("begin_crumple should expose CRUMPLING phase")
	if not flow.mark_crumple_complete():
		failures.append("first crumple completion should be accepted")
	if flow.get_phase_name() != "RITUAL_COMPLETE":
		failures.append("completed crumple should enter RITUAL_COMPLETE")
	if flow.mark_crumple_complete():
		failures.append("duplicate crumple completion must be ignored")
	if not flow.consume_reward_event():
		failures.append("ritual completion should emit one reward event")
	if flow.consume_reward_event():
		failures.append("ritual reward event must be exact-once")

	if not flow.request_next():
		failures.append("completed ritual should accept next-item request")
	if not flow.consume_next_request():
		failures.append("next-item request should be consumable exactly once")
	if flow.consume_next_request():
		failures.append("next-item request must not duplicate")

	flow.reset()
	if flow.get_phase_name() != "PEEL":
		failures.append("reset should return ritual flow to PEEL")
	if flow.consume_reward_event() or flow.consume_next_request():
		failures.append("reset should clear pending ritual events")

	var settle_skip = load(required).new()
	settle_skip.on_label_detached()
	if not settle_skip.request_next():
		failures.append("RED: PEEL_SETTLE must allow an immediate pressure-free next request")
	if not settle_skip.consume_next_request():
		failures.append("settle skip request should emit one-shot next intent")
	if settle_skip.consume_reward_event():
		failures.append("settle skip must not fabricate a crumple reward event")

	var early_squeeze = load(required).new()
	early_squeeze.on_label_detached()
	early_squeeze.update(0.22)
	if not early_squeeze.begin_crumple():
		failures.append("RED: explicit squeeze intent during PEEL_SETTLE must enter optional crumple without a timer lockout")
	if early_squeeze.get_phase_name() != "CRUMPLING":
		failures.append("early explicit squeeze must expose CRUMPLING immediately")

	var skip_flow = load(required).new()
	skip_flow.on_label_detached()
	skip_flow.update(1.0)
	if not skip_flow.request_next():
		failures.append("CRUMPLE_READY should allow pressure-free skip to next item")
	if not skip_flow.consume_next_request():
		failures.append("skip request should emit the same one-shot next intent")
	if skip_flow.consume_reward_event():
		failures.append("skipping crumple should not fabricate a crumple reward event")

	# Independent CHALLENGER counterexample: a next request during an active
	# squeeze cancels optional crumple-bonus eligibility. A stale completion
	# callback from the outgoing cup must not award that bonus afterward.
	var mid_skip = load(required).new()
	mid_skip.on_label_detached()
	mid_skip.update(1.0)
	if not mid_skip.begin_crumple():
		failures.append("mid-crumple skip fixture must enter CRUMPLING")
	if not mid_skip.request_next():
		failures.append("CRUMPLING should allow pressure-free next request")
	if mid_skip.mark_crumple_complete() and mid_skip.consume_reward_event():
		failures.append("RED: next requested during CRUMPLING must cancel optional crumple reward eligibility")

	# Consuming the one-shot next event is transport bookkeeping, not permission
	# to resurrect the outgoing cup's optional reward. The cancellation must
	# remain latched until reset/new-item state begins.
	var consumed_skip = load(required).new()
	consumed_skip.on_label_detached()
	consumed_skip.update(1.0)
	if not consumed_skip.begin_crumple():
		failures.append("consumed-skip fixture must enter CRUMPLING")
	if not consumed_skip.request_next():
		failures.append("consumed-skip fixture must accept next request")
	if not consumed_skip.consume_next_request():
		failures.append("consumed-skip fixture must consume next request once")
	if consumed_skip.mark_crumple_complete():
		failures.append("RED: consumed next request must keep outgoing ritual crumple completion ineligible")
	if consumed_skip.consume_reward_event():
		failures.append("RED: consumed next request must keep outgoing ritual reward-ineligible until reset")

	var safe_flow = load(required).new()
	safe_flow.on_label_detached()
	safe_flow.update(NAN)
	if safe_flow.get_phase_name() != "PEEL_SETTLE":
		failures.append("non-finite delta must not advance ritual timing")

	return failures
