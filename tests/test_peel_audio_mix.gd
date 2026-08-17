extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var path := "res://scripts/audio/peel_audio.gd"
	if not ResourceLoader.exists(path):
		failures.append("AUDIO_MIX_RED: missing PeelAudio")
		return failures
	var audio = load(path).new()
	audio._ready()

	var paper := audio.get("_paper") as AudioStreamPlayer
	var micro := audio.get("_micro") as AudioStreamPlayer
	var final := audio.get("_final") as AudioStreamPlayer
	if paper == null or micro == null or final == null:
		failures.append("AUDIO_MIX_RED: tactile one-shot players must remain present")
		audio.free()
		return failures
	if paper.volume_db > -20.0 or micro.volume_db > -14.0 or final.volume_db > -8.0:
		failures.append("AUDIO_MIX_RED: tactile transient defaults should remain restrained, not globally amplified")

	# Worst-case high tension at slow speed used to lift the continuous loop to
	# roughly -8 dB, which can read like a persistent music bed. Continuous
	# friction should remain audible but clearly subordinate to release events.
	audio.set_feedback(true,0.0,80.0,0.0,false,0.016)
	var slow_peak := float(audio.get("_slow_target_db"))
	var fast_at_slow := float(audio.get("_fast_target_db"))
	if slow_peak > -22.0:
		failures.append("AUDIO_MIX_RED: slow adhesive loop may not exceed -22 dB under worst-case tension; got %.1f dB" % slow_peak)
	if slow_peak <= -55.0:
		failures.append("AUDIO_MIX_RED: slow adhesive friction should remain quietly audible during active peel")
	if fast_at_slow > slow_peak - 6.0:
		failures.append("AUDIO_MIX_RED: fast layer should stay well below slow layer during a slow peel")

	# At fast speed the fast loop may take over, but it still must not compete
	# with the -17 dB micro-release and -10 dB final-release transient hierarchy.
	audio.set_feedback(true,9.0,80.0,0.0,false,0.016)
	var fast_peak := float(audio.get("_fast_target_db"))
	var slow_at_fast := float(audio.get("_slow_target_db"))
	if fast_peak > -21.0:
		failures.append("AUDIO_MIX_RED: fast adhesive loop may not exceed -21 dB under worst-case tension; got %.1f dB" % fast_peak)
	if fast_peak <= -55.0:
		failures.append("AUDIO_MIX_RED: fast adhesive friction should remain quietly audible during a fast peel")
	if slow_at_fast > fast_peak - 6.0:
		failures.append("AUDIO_MIX_RED: slow layer should stay well below fast layer during a fast peel")

	# Mid-speed crossfade must not create two near-foreground continuous layers.
	audio.set_feedback(true,4.5,80.0,0.0,false,0.016)
	var slow_mid := float(audio.get("_slow_target_db"))
	var fast_mid := float(audio.get("_fast_target_db"))
	if maxf(slow_mid,fast_mid) > -25.0:
		failures.append("AUDIO_MIX_RED: mid-speed adhesive crossfade should keep both continuous layers <= -25 dB; got %.1f / %.1f" % [slow_mid,fast_mid])

	audio.set_feedback(false,0.0,0.0,0.0,false,0.016)
	if float(audio.get("_slow_target_db")) != -80.0 or float(audio.get("_fast_target_db")) != -80.0:
		failures.append("AUDIO_MIX_RED: inactive peel must fully quiet continuous adhesive loops")

	audio.free()
	return failures
