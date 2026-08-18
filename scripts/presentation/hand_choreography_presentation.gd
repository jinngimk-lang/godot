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
		# PeelLab creates a fresh PeelController when the showcase variant changes.
		# Refresh this presentation reference so Q/E and 1/2/3 never leave hand
		# choreography following stale interaction state from the previous scene.
		_controller = _parent.get("_controller") as PeelController
	if _right_hand == null or _left_hand == null or _cup == null or _controller == null:
		return
	var safe_delta := clampf(delta if is_finite(delta) else 0.0,0.0,0.1)
	var venue_id := _venue_id()
	_stage_support_hand(venue_id,safe_delta)
	_stage_peel_hand_rest(venue_id,safe_delta)
	_stage_peel_hand_follow(venue_id,safe_delta)

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
	# Café paper-cup support staging is already owned by CrumpleHandStaging.
	# Do not let a second presentation layer move the same root or reset/next-item
	# can no longer return to an exact tactile baseline. This layer is reserved
	# for the non-crumpling glass scenes where a wrap pose must follow inspection.
	if venue_id == "cafe_window":
		return
	# The authored Cup pose supplies multi-finger flexion; this presentation layer
	# places and turns the palm so that flexion actually wraps the hero vessel
	# instead of reading as a detached claw beside it.
	var yaw := _cup.rotation.y
	var profile := _support_profile(venue_id)
	var base_position: Vector3 = profile["position"]
	var target := base_position + Vector3(sin(yaw)*0.11,0.0,(cos(yaw)-1.0)*0.065)
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
	# While the Café crumple presentation is visibly active, CrumpleHandStaging
	# is the sole owner of both hand roots. Yield before applying the untouched
	# peel-rest target so the released hand cannot be pulled away from the paper
	# shell on settle/capture frames.
	if _cafe_crumple_owns_peel_hand(venue_id):
		return
	var state := _controller.get_state_name()
	var progress := _controller.get_progress()
	# Once the player has lifted any paper, the gameplay hand target owns the
	# position. This layer only composes the untouched idle/hover frame.
	if progress > 0.001 or state not in ["IDLE","EDGE_HOVER","RELEASED"]:
		return
	var profile := _peel_rest_profile(venue_id)
	var target: Vector3 = profile["position"]
	if _label != null and _label.is_inside_tree() and _right_hand.is_inside_tree():
		# Ground the visible thumb/index pinch anchor on the actual attached paper
		# edge. This replaces the old venue-specific floating root position while
		# preserving the authored pinch pose and venue rotation. Recomputing from
		# the live anchor each frame naturally absorbs the small anchor shift while
		# the rest rotation is easing toward its target.
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

func _stage_peel_hand_follow(venue_id: String, delta: float) -> void:
	if _right_hand == null or _controller == null or _label == null:
		return
	if _cafe_crumple_owns_peel_hand(venue_id):
		return
	var state := _controller.get_state_name()
	var progress := _controller.get_progress()
	if progress <= 0.025 or progress >= 0.98 or state not in ["EDGE_LIFT","PINCHED","PEELING"]:
		return
	if not _label.is_inside_tree() or not _right_hand.is_inside_tree():
		return
	# Gameplay remains the sole owner of the active peel-hand position. This
	# presentation layer owns only root orientation, deriving it from the actual
	# free-paper centerline instead of freezing the whole hand at its idle pose.
	var grip_local := _label.to_local(_right_hand.get_pinch_world_position())
	var follow_yaw := _peel_follow_yaw_delta(progress,grip_local)
	var profile := _peel_rest_profile(venue_id)
	var base_rotation: Vector3 = profile["rotation"]
	var desired := Vector3(base_rotation.x,base_rotation.y+follow_yaw,base_rotation.z)
	var weight := 1.0-exp(-ROTATION_FOLLOW_RATE*delta)
	_right_hand.rotation.x = lerp_angle(_right_hand.rotation.x,desired.x,weight)
	_right_hand.rotation.y = lerp_angle(_right_hand.rotation.y,desired.y,weight)
	_right_hand.rotation.z = lerp_angle(_right_hand.rotation.z,desired.z,weight)

func _peel_follow_yaw_delta(progress: float, grip_local: Vector3) -> float:
	if _label == null:
		return 0.0
	var p := clampf(progress if is_finite(progress) else 0.0,0.0,1.0)
	if p <= 0.025 or p >= 0.98:
		return 0.0
	var points := _label.get_sample_points(p,grip_local)
	if points.size() < 2:
		return 0.0
	# The first centerline segment is the real visible free-tip tangent. Compare
	# it with the substrate tangent at the current attachment boundary. The signed
	# XZ angle is therefore a direct geometry delta, not a tuned pose angle.
	var free_tangent := points[1]-points[0]
	var attached_next := minf(p+0.04,1.0)
	var substrate_tangent := _label.get_front_position(attached_next)-_label.get_front_position(p)
	var free_xz := Vector2(free_tangent.x,free_tangent.z)
	var substrate_xz := Vector2(substrate_tangent.x,substrate_tangent.z)
	if free_xz.length_squared() <= 0.000001 or substrate_xz.length_squared() <= 0.000001:
		return 0.0
	var free_angle := atan2(free_xz.x,free_xz.y)
	var substrate_angle := atan2(substrate_xz.x,substrate_xz.y)
	return wrapf(free_angle-substrate_angle,-PI,PI)

func _cafe_crumple_owns_peel_hand(venue_id: String) -> bool:
	if venue_id != "cafe_window" or _parent == null:
		return false
	var crumple := _parent.get_node_or_null("CupCrumplePresentation") as CupCrumplePresentation
	return crumple != null and crumple.get_progress() > 0.001

func _support_profile(venue_id: String) -> Dictionary:
	match venue_id:
		"night_bar":
			return {
				"position":Vector3(0.53,0.13,0.30),
				"rotation":Vector3(deg_to_rad(8.0),deg_to_rad(54.0),deg_to_rad(50.0))
			}
		"market_coldcase":
			return {
				"position":Vector3(0.52,0.12,0.31),
				"rotation":Vector3(deg_to_rad(7.0),deg_to_rad(55.0),deg_to_rad(49.0))
			}
		_:
			return {
				"position":Vector3(0.61,0.18,0.34),
				"rotation":Vector3(deg_to_rad(12.0),deg_to_rad(48.0),deg_to_rad(47.0))
			}

func _peel_rest_profile(venue_id: String) -> Dictionary:
	match venue_id:
		"night_bar":
			return {
				"position":Vector3(-0.79,-0.03,0.70),
				"rotation":Vector3(deg_to_rad(22.0),deg_to_rad(-30.0),deg_to_rad(-19.0))
			}
		"market_coldcase":
			return {
				"position":Vector3(-0.78,-0.04,0.69),
				"rotation":Vector3(deg_to_rad(20.0),deg_to_rad(-28.0),deg_to_rad(-18.0))
			}
		_:
			return {
				"position":Vector3(-0.80,-0.02,0.72),
				"rotation":Vector3(deg_to_rad(24.0),deg_to_rad(-27.0),deg_to_rad(-20.0))
			}

func _venue_id() -> String:
	if _venue != null:
		return _venue.get_active_profile_id()
	return "cafe_window"
