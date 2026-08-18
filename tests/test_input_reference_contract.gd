extends RefCounted

const LAB_SCRIPT := "res://scripts/peel_lab.gd"

func run() -> Array[String]:
	var failures: Array[String] = []
	var script = load(LAB_SCRIPT)
	if script == null:
		return ["INPUT_RED: PeelLab script failed to load"]
	var methods: Array[String] = []
	for method in script.get_script_method_list():
		methods.append(String(method.get("name","")))
	if not methods.has("get_control_contract"):
		return ["INPUT_RED: PeelLab must expose the player control contract"]
	var lab = script.new()
	var contract: Dictionary = lab.call("get_control_contract")
	var expected := {
		"peel":"LMB",
		"rotate":"RMB",
		"zoom":"Wheel",
		"reset":"R",
		"scenes":"1/2/3/4/5",
		"pause":"Esc"
	}
	for key in expected.keys():
		if String(contract.get(key,"")) != String(expected[key]):
			failures.append("INPUT_RED: %s must map to %s" % [key,expected[key]])
	if contract.has("inspect"):
		failures.append("INPUT_RED: object-only design should inspect via RMB rotate + Wheel zoom, not a separate inspect key")
	lab.free()
	return failures
