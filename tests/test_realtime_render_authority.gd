extends RefCounted

const SCENE_PATH := "res://scenes/peel_lab/peel_lab.tscn"

func run() -> Array[String]:
	var failures: Array[String] = []
	var scene := load(SCENE_PATH) as PackedScene
	if scene == null:
		return ["RED: peel_lab scene failed to load"]
	var root := scene.instantiate()
	if root.get_node_or_null("ReferencePeelPlayback") != null:
		failures.append("RED: full-screen reference playback is still present")
	for child in root.get_children():
		if child is CanvasLayer and String(child.name) == "ReferencePeelPlayback":
			failures.append("RED: reference playback CanvasLayer still owns the viewport")
	root.free()
	return failures
