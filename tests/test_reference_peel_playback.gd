extends RefCounted

const SCRIPT_PATH := "res://scripts/presentation/reference_peel_playback.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	if not ResourceLoader.exists(SCRIPT_PATH):
		failures.append("RED: missing reference peel playback presentation layer")
		return failures
	var script = load(SCRIPT_PATH)
	if script == null:
		failures.append("RED: reference peel playback script did not load")
		return failures
	var player = script.new()
	if player == null:
		failures.append("RED: reference peel playback did not instantiate")
		return failures
	for required_method in ["frame_index_for_progress","frame_path_for_progress","get_reference_frame_count","get_reference_frame_size"]:
		if not player.has_method(required_method):
			failures.append("RED: reference peel playback missing %s" % required_method)
	if not failures.is_empty():
		player.free()
		return failures
	if int(player.call("get_reference_frame_count")) != 3:
		failures.append("RED: target playback must expose the three validated reference states")
	if player.call("get_reference_frame_size") != Vector2i(368,200):
		failures.append("RED: embedded target frames must preserve the supplied source aspect at 368x200")
	if int(player.call("frame_index_for_progress",0.0)) != 0:
		failures.append("RED: zero peel progress must map to the first target frame")
	if int(player.call("frame_index_for_progress",1.0)) != 2:
		failures.append("RED: completed peel must map to the final target frame")
	if int(player.call("frame_index_for_progress",0.5)) != 1:
		failures.append("RED: half peel progress must map to the middle target state")
	if String(player.call("frame_path_for_progress",0.0)) != "res://art/reference_motion/chunks/frame_00_0.gd":
		failures.append("RED: first target-frame chunk mapping is incorrect")
	if String(player.call("frame_path_for_progress",0.5)) != "res://art/reference_motion/chunks/frame_05_0.gd":
		failures.append("RED: middle target-frame chunk mapping is incorrect")
	if String(player.call("frame_path_for_progress",1.0)) != "res://art/reference_motion/chunks/frame_12_0.gd":
		failures.append("RED: final target-frame chunk mapping is incorrect")
	player.free()
	return failures
