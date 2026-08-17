extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var path := "res://scripts/audio/peel_audio.gd"
	if not ResourceLoader.exists(path):
		failures.append("AUDIO_MIX_RED: missing PeelAudio")
		return failures
	var audio = load(path).new()
	if not audio.has_method("get_continuous_mix_targets"):
		failures.append("AUDIO_MIX_RED: PeelAudio needs a deterministic continuous-loop mix contract")
		audio.free()
		return failures

	# Vector2.x = slow adhesive dB target, Vector2.y = fast adhesive dB target.
	var slow_state: Vector2 = audio.get_continuous_mix_targets(true,0.0,80.0)
	if slow_state.x > -22.0:
		failures.append("AUDIO_MIX_RED: slow adhesive loop may not exceed -22 dB under worst-case tension; got %.1f dB" % slow_state.x)
	if slow_state.x <= -55.0:
		failures.append("AUDIO_MIX_RED: slow adhesive friction should remain quietly audible during active peel")
	if slow_state.y > slow_state.x - 6.0:
		failures.append("AUDIO_MIX_RED: fast layer should stay well below slow layer during a slow peel")

	var fast_state: Vector2 = audio.get_continuous_mix_targets(true,9.0,80.0)
	if fast_state.y > -21.0:
		failures.append("AUDIO_MIX_RED: fast adhesive loop may not exceed -21 dB under worst-case tension; got %.1f dB" % fast_state.y)
	if fast_state.y <= -55.0:
		failures.append("AUDIO_MIX_RED: fast adhesive friction should remain quietly audible during a fast peel")
	if fast_state.x > fast_state.y - 6.0:
		failures.append("AUDIO_MIX_RED: slow layer should stay well below fast layer during a fast peel")

	var mid_state: Vector2 = audio.get_continuous_mix_targets(true,4.5,80.0)
	if maxf(mid_state.x,mid_state.y) > -25.0:
		failures.append("AUDIO_MIX_RED: mid-speed crossfade should keep both continuous layers <= -25 dB; got %.1f / %.1f" % [mid_state.x,mid_state.y])

	var quiet_state: Vector2 = audio.get_continuous_mix_targets(false,9.0,80.0)
	if quiet_state != Vector2(-80.0,-80.0):
		failures.append("AUDIO_MIX_RED: inactive peel must fully quiet continuous adhesive loops")

	# The change is intentionally mix-only: tactile release routing remains a
	# separate Foley contract and is not folded into the continuous-loop helper.
	var source := FileAccess.get_file_as_string(path)
	for event_name in ["paper_flex", "micro_release", "final_release"]:
		if not source.contains('"%s"' % event_name):
			failures.append("AUDIO_MIX_RED: mix rebalance must preserve tactile event route %s" % event_name)

	audio.free()
	return failures
