extends Node
class_name HandChoreographyPresentation

const REST_FOLLOW_RATE := 9.0
const SUPPORT_FOLLOW_RATE := 10.5
const ROTATION_FOLLOW_RATE := 10.0

var _parent: Node3D
var _right_hand: HandVisual
var _left_hand: HandVisual
var _cup: MeshInstance3D
var _label: LabelVisual
var _controller: PeelController
var _venue: VenuePresentation

func _ready() -> void:
	call_deferred("_bind")

func _process(delta: float) -> void:
	if _parent == null:
		_bind()
	if _parent != null:
		_controller = _parent.get("_controller") as PeelController
	if _right_hand == null or _left_hand == null or _cup == null or _controller == null:
		return
	var safe_delta := clampf(delta if is_finite(delta) else 0.0,0.0,0.1)
	var venue_id := _venue_id()
	_stage_support_hand(venue_id,safe_delta)
	_stage_peel_hand_rest(venue_id,safe_delta)

func _bind() -> void:
	_parent = get_parent() as Node3D
	if _parent == null:
		return
	_right_hand = _parent.get_node_or_null("RightHand") as HandVisual
	_left_hand = _parent.get_node_or_null("LeftHand") as HandVisual
	_cup = _parent.get_node_or_null("Cup") as MeshInstance3D
	_label = _parent.get_node_or_null("PeelLabel") as LabelVisual
	_venue = _parent.get_node_or_null("VenuePresentation") as VenuePresentation
	_controller = _parent.get("_controller") as PeelController

func _stage_support_hand(venue_id: String, delta: float) -> void:
	if _left_hand == null or _cup == null:
		return
	if venue_id == "cafe_window":
		return
	var yaw := _cup.rotation.y
	var profile := _support_profile(venue_id)
	var base_position: Vector3 = profile["position"]
	var target := base_position+Vector3(sin(yaw)*0.11,0.0,(cos(yaw)-1.0)*0.065)
	var weight := 1.0-exp(-SUPPORT_FOLLOW_RATE*delta)
	_left_hand.position = _left_hand.position.lerp(target,weight)
	var base_rotation: Vector3 = profile["rotation"]
	var desired := Vector3(base_rotation.x,base_rotation.y+yaw*0.42,base_rotation.z)
	_left_hand.rotation.x = lerp_angle(_left_hand.rotation.x,desired.x,weight)
	_left_hand.rotation.y = lerp_angle(_left_hand.rotation.y,desired.y,weight)
	_left_hand.rotation.z = lerp_angle(_left_hand.rotation.z,desired.z,weight)

func _stage_peel_hand_rest(venue_id: String, delta: float) -> void:
	if _right_hand == null or _controller == null:
		return
	if _cafe_crumple_owns_peel_hand(venue_id):
		return
	var state := _controller.get_state_name()
	var progress := _controller.get_progress()
	if progress > 0.001 or state not in ["IDLE","EDGE_HOVER","RELEASED"]:
		return
	var profile := _peel_rest_profile(venue_id)
	var target: Vector3 = profile["position"]
	if _label != null and _label.is_inside_tree() and _right_hand.is_inside_tree():
		var desired_pinch_world := _label.to_global(_label.get_front_position(0.0))
		var current_pinch_world := _right_hand.get_pinch_world_position()
		var desired_root_world := _right_hand.global_position+(desired_pinch_world-current_pinch_world)
		var root_parent := _right_hand.get_parent() as Node3D
		if root_parent != null:
			target = root_parent.to_local(desired_root_world)
	var position_weight := 1.0-exp(-REST_FOLLOW_RATE*delta)
	_right_hand.position = _right_hand.position.lerp(target,position_weight)
	var desired: Vector3 = profile["rotation"]
	var rotation_weight := 1.0-exp(-ROTATION_FOLLOW_RATE*delta)
	_right_hand.rotation.x = lerp_angle(_right_hand.rotation.x,desired.x,rotation_weight)
	_right_hand.rotation.y = lerp_angle(_right_hand.rotation.y,desired.y,rotation_weight)
	_right_hand.rotation.z = lerp_angle(_right_hand.rotation.z,desired.z,rotation_weight)

func _cafe_crumple_owns_peel_hand(venue_id: String) -> bool:
	if venue_id != "cafe_window" or _parent == null:
		return false
	var crumple := _parent.get_node_or_null("CupCrumplePresentation") as CupCrumplePresentation
	return crumple != null and crumple.get_progress()>0.001

func _support_profile(venue_id: String) -> Dictionary:
	# Place the stabilising palm on the product's right flank and roll it farther
	# inward. The fingers are authored behind the vessel, so this staging lets the
	# bottle/cup provide natural occlusion instead of displaying a fan of tubes
	# across the front label.
	match venue_id:
		"night_bar":
			return {
				"position":Vector3(0.71,0.10,0.12),
				"rotation":Vector3(deg_to_rad(5.0),deg_to_rad(18.0),deg_to_rad(-78.0))
			}
		"market_coldcase":
			return {
				"position":Vector3(0.70,0.09,0.13),
				"rotation":Vector3(deg_to_rad(5.0),deg_to_rad(17.0),deg_to_rad(-76.0))
			}
		_:
			return {
				"position":Vector3(0.69,0.14,0.16),
				"rotation":Vector3(deg_to_rad(7.0),deg_to_rad(20.0),deg_to_rad(-76.0))
			}

func _peel_rest_profile(venue_id: String) -> Dictionary:
	# Positive Z rotation makes the peel hand read as a horizontal first-person
	# pinch coming from the lower-left. Position remains derived from the live
	# label edge, so changing orientation never disconnects gameplay contact.
	match venue_id:
		"night_bar":
			return {
				"position":Vector3(-0.79,-0.03,0.70),
				"rotation":Vector3(deg_to_rad(16.0),deg_to_rad(-22.0),deg_to_rad(70.0))
			}
		"market_coldcase":
			return {
				"position":Vector3(-0.78,-0.04,0.69),
				"rotation":Vector3(deg_to_rad(15.0),deg_to_rad(-20.0),deg_to_rad(68.0))
			}
		_:
			return {
				"position":Vector3(-0.80,-0.02,0.72),
				"rotation":Vector3(deg_to_rad(14.0),deg_to_rad(-18.0),deg_to_rad(68.0))
			}

func _venue_id() -> String:
	if _venue != null:
		return _venue.get_active_profile_id()
	return "cafe_window"
