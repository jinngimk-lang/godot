extends Node
class_name SubstratePeelFeelBinding

var _last_variant_index := -1
var _last_controller: PeelController

func _process(_delta: float) -> void:
	var root := get_parent()
	if root == null:
		return
	var session_value = root.get("_session")
	var controller_value = root.get("_controller")
	var corner := root.get_node_or_null("CornerPeelPresentation") as CornerPeelPresentation
	if session_value == null or controller_value == null or corner == null:
		return
	var session: SessionModel = session_value as SessionModel
	var controller: PeelController = controller_value as PeelController
	if session == null or controller == null:
		return
	var variant_index := session.get_variant_index()
	if variant_index == _last_variant_index and controller == _last_controller:
		return
	_last_variant_index = variant_index
	_last_controller = controller
	var variant: Dictionary = session.current_variant()
	var feel_value = variant.get("peel_feel",{})
	var feel: Dictionary = feel_value if feel_value is Dictionary else {}
	controller.configure_peel_feel(feel)
	corner.set_paper_profile(feel)
