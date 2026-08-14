extends RefCounted

const MIN_AUTHORED_SCALE := 2.55
const MAX_AUTHORED_SCALE := 2.90
const MIN_SKIN_VALUE := 0.46
const MAX_SKIN_VALUE := 0.78
const MAX_SKIN_RED_GREEN_GAP := 0.20
const MIN_NAIL_VALUE := 0.62

func run() -> Array[String]:
	var failures: Array[String] = []
	var hand_path := "res://scripts/hands/hand_visual.gd"
	var hand_script = load(hand_path)
	if hand_script == null:
		failures.append("HandVisual script did not load")
		return failures

	var method_names: Array[String] = []
	for method in hand_script.get_script_method_list():
		method_names.append(String(method.get("name", "")))
	for required in ["set_grip_target", "set_pinch_amount", "get_finger_count", "snap_to", "tick"]:
		if not method_names.has(required):
			failures.append("RED: HandVisual missing semi-realistic contract method %s" % required)
	if not failures.is_empty():
		return failures

	var hand = hand_script.new()
	hand.setup(true)
	if hand.get_finger_count() != 5:
		failures.append("HandVisual must expose five fingers")
	for required_node in ["ThumbTip", "IndexTip", "PinchPoint"]:
		if hand.find_child(required_node, true, false) == null:
			failures.append("HandVisual missing pinch anchor %s" % required_node)

	var authored := hand.get_node_or_null("AuthoredHand") as Node3D
	if authored == null:
		failures.append("RED: normal runtime must instantiate AuthoredHand")
	else:
		var authored_scale: float = authored.scale.x
		if authored_scale < MIN_AUTHORED_SCALE or authored_scale > MAX_AUTHORED_SCALE:
			failures.append("REFERENCE_RED: authored hand remains too small beside cup/forearm; scale=%.3f target=%.2f..%.2f" % [authored_scale, MIN_AUTHORED_SCALE, MAX_AUTHORED_SCALE])
		var semantic: Dictionary = _collect_semantic_materials(authored)
		if not semantic.has("HandSkin"):
			failures.append("REFERENCE_RED: authored hand missing semantic HandSkin material")
		else:
			var skin := semantic["HandSkin"] as StandardMaterial3D
			var skin_value: float = _perceived_value(skin.albedo_color)
			if skin_value < MIN_SKIN_VALUE or skin_value > MAX_SKIN_VALUE:
				failures.append("REFERENCE_RED: authored HandSkin value %.3f outside semi-realistic close-up range %.2f..%.2f color=%s" % [skin_value, MIN_SKIN_VALUE, MAX_SKIN_VALUE, str(skin.albedo_color)])
			if skin.albedo_color.r - skin.albedo_color.g > MAX_SKIN_RED_GREEN_GAP:
				failures.append("REFERENCE_RED: authored HandSkin is too orange/red under warm cafe lighting; color=%s" % str(skin.albedo_color))
			if skin.roughness < 0.55 or skin.roughness > 0.86:
				failures.append("REFERENCE_RED: authored HandSkin roughness %.3f should stay soft-matte, not plastic" % skin.roughness)
		if not semantic.has("HandNail"):
			failures.append("REFERENCE_RED: authored hand missing semantic HandNail material")
		else:
			var nail := semantic["HandNail"] as StandardMaterial3D
			if _perceived_value(nail.albedo_color) < MIN_NAIL_VALUE:
				failures.append("REFERENCE_RED: authored HandNail is too dark for clean natural nails; color=%s" % str(nail.albedo_color))
			if nail.roughness < 0.38 or nail.roughness > 0.68:
				failures.append("REFERENCE_RED: authored HandNail roughness %.3f should read as natural satin" % nail.roughness)

	var relaxed_pose := String(hand.get("_last_authored_pose"))
	if relaxed_pose != "Pinch Up":
		failures.append("RED: relaxed dynamic authored hand must use Pinch Up, got %s" % relaxed_pose)

	var sleeve := hand.find_child("WristSleeve", true, false) as MeshInstance3D
	var cuff := hand.find_child("WristCuff", true, false) as MeshInstance3D
	if sleeve == null:
		failures.append("RED: authored hand must cover the open wrist with WristSleeve")
	elif sleeve.mesh == null or sleeve.material_override == null:
		failures.append("WristSleeve must have visible mesh and fabric material")
	elif sleeve.material_override.resource_name != "SleeveFabric":
		failures.append("WristSleeve must use semantic SleeveFabric material")
	if cuff == null:
		failures.append("RED: authored hand must finish the wrist cover with WristCuff")
	elif cuff.mesh == null or cuff.material_override == null:
		failures.append("WristCuff must have visible mesh and cuff material")
	elif cuff.material_override.resource_name != "SleeveRib":
		failures.append("WristCuff must use semantic SleeveRib material")

	hand.set_pinch_amount(1.0)
	var target := Vector3(1.0, 0.5, 0.8)
	hand.set_grip_target(target)
	for _i in range(8):
		hand.tick(0.1)
	var pinch_position: Vector3 = hand.get_pinch_world_position() as Vector3
	var pinch_error: float = pinch_position.distance_to(target)
	if pinch_error > 0.002:
		failures.append("REFERENCE_RED: presentation scaling must preserve pinch-point authority; error=%.6f" % pinch_error)
	var active_pose := String(hand.get("_last_authored_pose"))
	if active_pose != "Pinch Tight":
		failures.append("active authored hand must close to Pinch Tight, got %s" % active_pose)
	hand.free()

	var support = hand_script.new()
	support.setup(false)
	var support_pose := String(support.get("_last_authored_pose"))
	if support_pose != "Default pose":
		failures.append("RED: authored support hand must use neutral Default pose, got %s" % support_pose)
	support.free()
	return failures

func _collect_semantic_materials(node: Node) -> Dictionary:
	var result := {}
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.material_override is StandardMaterial3D:
			var override := mesh_instance.material_override as StandardMaterial3D
			if not override.resource_name.is_empty():
				result[override.resource_name] = override
		if mesh_instance.mesh != null:
			for surface_index in range(mesh_instance.mesh.get_surface_count()):
				var material := mesh_instance.mesh.surface_get_material(surface_index)
				if material is StandardMaterial3D and not material.resource_name.is_empty():
					result[material.resource_name] = material as StandardMaterial3D
	for child in node.get_children():
		var child_materials: Dictionary = _collect_semantic_materials(child)
		for key in child_materials.keys():
			result[key] = child_materials[key]
	return result

func _perceived_value(color: Color) -> float:
	return color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
