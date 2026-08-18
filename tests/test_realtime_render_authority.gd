extends RefCounted

const SCENE_PATH := "res://scenes/peel_lab/peel_lab.tscn"
const LAB_SCRIPT := "res://scripts/peel_lab.gd"
const FORBIDDEN_NODES := [
	"ReferencePeelPlayback",
	"LeftHand",
	"RightHand",
	"ForearmPresentation",
	"CrumpleHandStaging",
	"HandChoreographyPresentation",
	"CinematicHandPresentation",
	"HandSurfaceSmoothing"
]

func run() -> Array[String]:
	var failures: Array[String] = []
	var scene := load(SCENE_PATH) as PackedScene
	if scene == null:
		return ["OBJECT_ONLY_RED: peel_lab scene failed to load"]
	var root := scene.instantiate()
	for node_name in FORBIDDEN_NODES:
		if root.get_node_or_null(node_name) != null:
			failures.append("OBJECT_ONLY_RED: runtime scene still contains obsolete %s" % node_name)
	for child in root.get_children():
		if child is CanvasLayer and String(child.name) == "ReferencePeelPlayback":
			failures.append("OBJECT_ONLY_RED: reference playback still owns the viewport")
	root.free()

	var script = load(LAB_SCRIPT)
	if script == null:
		failures.append("OBJECT_ONLY_RED: PeelLab script failed to load")
		return failures
	var methods: Array[String] = []
	for method in script.get_script_method_list():
		methods.append(String(method.get("name","")))
	if not methods.has("get_visual_interaction_contract"):
		failures.append("OBJECT_ONLY_RED: PeelLab must expose the visual interaction contract")
		return failures
	var lab = script.new()
	var contract: Dictionary = lab.call("get_visual_interaction_contract")
	if bool(contract.get("visible_hands",true)):
		failures.append("OBJECT_ONLY_RED: visible_hands must be false")
	if String(contract.get("pointer_grip","")) != "mouse_direct":
		failures.append("OBJECT_ONLY_RED: pointer grip must be mouse_direct")
	if String(contract.get("cursor","")) != "hand":
		failures.append("OBJECT_ONLY_RED: gameplay cursor must be the small hand cursor")
	lab.free()
	return failures
