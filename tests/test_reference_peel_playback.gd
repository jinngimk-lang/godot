extends RefCounted

const SCRIPT_PATH := "res://scripts/presentation/reference_peel_playback.gd"
const SHEET_PATH := "res://art/reference_motion/cafe_peel_reference_sheet.jpg"

func run() -> Array[String]:
	var failures: Array[String] = []
	if not ResourceLoader.exists(SCRIPT_PATH):
		failures.append("RED: missing reference peel playback presentation layer")
		return failures
	if not ResourceLoader.exists(SHEET_PATH):
		failures.append("RED: missing café target-video sprite sheet")
		return failures
	var script = load(SCRIPT_PATH)
	if script == null:
		failures.append("RED: reference peel playback script did not load")
		return failures
	var player = script.new()
	if player == null:
		failures.append("RED: reference peel playback did not instantiate")
		return failures
	for required_method in ["frame_index_for_progress","frame_region_for_progress","get_reference_frame_count","get_reference_frame_size"]:
		if not player.has_method(required_method):
			failures.append("RED: reference peel playback missing %s" % required_method)
	if not failures.is_empty():
		player.free()
		return failures
	if int(player.call("get_reference_frame_count")) != 73:
		failures.append("RED: target playback must expose all 73 sampled reference frames")
	if player.call("get_reference_frame_size") != Vector2i(736,400):
		failures.append("RED: target playback must preserve the supplied 736x400 source framing")
	if int(player.call("frame_index_for_progress",0.0)) != 0:
		failures.append("RED: zero peel progress must map to the first target frame")
	if int(player.call("frame_index_for_progress",1.0)) != 72:
		failures.append("RED: completed peel must map to the final target frame")
	var middle_index := int(player.call("frame_index_for_progress",0.5))
	if middle_index < 35 or middle_index > 37:
		failures.append("RED: half peel progress must map near the temporal midpoint, got %d" % middle_index)
	if player.call("frame_region_for_progress",0.0) != Rect2i(0,0,736,400):
		failures.append("RED: first reference frame atlas region is incorrect")
	if player.call("frame_region_for_progress",1.0) != Rect2i(0,3600,736,400):
		failures.append("RED: last reference frame atlas region is incorrect")
	player.free()
	return failures
