extends Node
class_name CafeReceiptReadabilityPresentation

const THERMAL_PAPER_BOUNCE := 0.18

var _label: LabelVisual
var _last_signature := ""

func _process(_delta: float) -> void:
	if _label == null or not is_instance_valid(_label):
		_label = get_parent().get_node_or_null("PeelLabel") as LabelVisual
		if _label == null:
			return
	var signature := _label.get_substrate_signature()
	var material: StandardMaterial3D = _label.get("_material") as StandardMaterial3D
	if material == null:
		return
	var texture_changed: bool = material.emission_texture != material.albedo_texture
	if signature == _last_signature and not texture_changed:
		return
	_last_signature = signature
	configure_front_material(material, signature)

func configure_front_material(material: StandardMaterial3D, substrate_signature: String) -> void:
	if material == null:
		return
	var thermal := substrate_signature.begins_with("thermal_paper")
	var bounce := THERMAL_PAPER_BOUNCE if thermal else 0.0
	material.emission_enabled = bounce > 0.0
	material.emission = Color.WHITE
	material.emission_energy_multiplier = bounce
	material.emission_texture = material.albedo_texture if thermal else null

func get_front_paper_bounce(substrate_signature: String) -> float:
	return THERMAL_PAPER_BOUNCE if substrate_signature.begins_with("thermal_paper") else 0.0

func is_front_paper_bounce_texture_linked(material: StandardMaterial3D) -> bool:
	return material != null and material.emission_enabled and material.albedo_texture != null and material.emission_texture == material.albedo_texture
