extends Node3D

var _camera: Camera3D
var _label: LabelVisual
var _label_print: LabelPrint
var _lifecycle: LabelLifecycle
var _controller: PeelController
var _pointer: PointerAdapter
var _right_hand: HandVisual
var _left_hand: HandVisual
var _audio: PeelAudio
var _hud: Label
var _reward: Label
var _edge_marker: MeshInstance3D
var _release_count := 0
var _reset_timer := -1.0
var _completed_this_frame := false
var _pending_score := 0

func _ready() -> void:
	_build_world()
	_controller = PeelController.new({
		"base_adhesion": 11.0,
		"release_increment": 0.038,
		"speed_gain": 0.018,
		"angle_gain": 0.3
	})
	_lifecycle = LabelLifecycle.new(0.16)
	_controller.completed.connect(_on_completed)
	_reset_session()

func _process(delta: float) -> void:
	if _reset_timer >= 0.0:
		_reset_timer -= delta
		if _reset_timer <= 0.0:
			_reset_session()

	var progress: float = _controller.get_progress()
	var front_world: Vector3 = _label.get_front_position(progress)
	var edge_screen: Vector2 = _camera.unproject_position(front_world)
	_controller.set_edge_position(edge_screen)

	var state: PointerState = _pointer.consume_frame()
	var before: float = progress
	_completed_this_frame = false
	var result: Dictionary = _controller.process_pointer(state, delta)
	progress = float(result["progress"])
	var released_amount: float = maxf(progress - before, 0.0)

	if state.released_this_frame and progress > 0.0 and not _controller.is_complete():
		_release_count += 1

	_lifecycle.update(progress, _completed_this_frame, delta)
	var phase_name := _lifecycle.get_phase_name()
	_label.set_phase(phase_name)
	_label.set_detach_alpha(_lifecycle.get_detach_alpha())
	var detached_now := _lifecycle.consume_detach_event()

	var hand_screen: Vector2 = result["hand_position"] as Vector2
	var desired_grip: Vector3 = _screen_to_plane(hand_screen, _label.cup_radius + 0.28)
	var effective_grip := _label.get_effective_grip(progress, desired_grip)
	var state_name := String(result["state"])
	var pinching := state_name in ["EDGE_LIFT", "PINCHED", "PEELING", "COMPLETE"] or phase_name in ["DETACHING", "HELD"]
	_right_hand.set_pinch_amount(1.0 if pinching else 0.18)
	_right_hand.set_grip_target(effective_grip)
	_right_hand.tick(delta)
	var pinch_world := _right_hand.get_pinch_world_position()
	_label.set_peel(progress, pinch_world)

	_edge_marker.position = front_world
	_edge_marker.visible = phase_name in ["ATTACHED", "PEELING"] and state_name != "COMPLETE"

	var tension: float = hand_screen.distance_to(edge_screen) * 0.65
	var speed: float = state.velocity.length() / 100.0
	var active_peel := state_name == "PEELING" and phase_name == "PEELING"
	_audio.set_feedback(active_peel, speed, tension, released_amount, detached_now, delta)

	if detached_now:
		_reward.text = "CLEAN PEEL  +%d" % _pending_score
		_reset_timer = 2.15

	_update_hud(state_name, phase_name, progress)
	_pointer.clear_transients()

func _build_world() -> void:
	_camera = Camera3D.new()
	_camera.name = "Camera"
	_camera.position = Vector3(0.0, 0.88, 3.62)
	_camera.fov = 39.0
	add_child(_camera)
	_camera.look_at(Vector3(0.0, 0.16, 0.0), Vector3.UP)
	_camera.current = true

	var key := DirectionalLight3D.new()
	key.name = "KeyLight"
	key.rotation_degrees = Vector3(-50, -32, 0)
	key.light_energy = 1.05
	key.shadow_enabled = true
	add_child(key)

	var fill := OmniLight3D.new()
	fill.name = "FillLight"
	fill.position = Vector3(-1.8, 1.6, 2.3)
	fill.light_energy = 2.2
	fill.omni_range = 6.0
	add_child(fill)

	var rim := OmniLight3D.new()
	rim.name = "RimLight"
	rim.position = Vector3(1.7, 1.25, -0.9)
	rim.light_energy = 1.15
	rim.omni_range = 4.0
	add_child(rim)

	var table := MeshInstance3D.new()
	table.name = "Table"
	var table_mesh := BoxMesh.new()
	table_mesh.size = Vector3(5.0, 0.16, 3.0)
	table.mesh = table_mesh
	table.position = Vector3(0, -0.72, 0)
	table.material_override = _material(Color(0.26, 0.20, 0.17), 0.88)
	add_child(table)

	var cup := MeshInstance3D.new()
	cup.name = "Cup"
	var cup_mesh := CylinderMesh.new()
	cup_mesh.top_radius = 0.54
	cup_mesh.bottom_radius = 0.45
	cup_mesh.height = 1.48
	cup.mesh = cup_mesh
	cup.position = Vector3(0, 0.05, 0)
	cup.material_override = _material(Color(0.89, 0.84, 0.74), 0.94)
	add_child(cup)

	var lid := MeshInstance3D.new()
	lid.name = "Lid"
	var lid_mesh := CylinderMesh.new()
	lid_mesh.top_radius = 0.57
	lid_mesh.bottom_radius = 0.56
	lid_mesh.height = 0.08
	lid.mesh = lid_mesh
	lid.position = Vector3(0, 0.83, 0)
	lid.material_override = _material(Color(0.14, 0.125, 0.115), 0.76)
	add_child(lid)

	_label = LabelVisual.new()
	_label.name = "PeelLabel"
	_label.label_y = 0.22
	_label.cup_radius = 0.53
	add_child(_label)

	_label_print = LabelPrint.new()
	_label_print.name = "LabelPrint"
	add_child(_label_print)
	_label_print.set_order("A17", "OAT LATTE")
	_label.set_print_texture(_label_print.get_texture())

	_edge_marker = MeshInstance3D.new()
	_edge_marker.name = "PeelEdge"
	var marker_mesh := SphereMesh.new()
	marker_mesh.radius = 0.022
	marker_mesh.height = 0.044
	_edge_marker.mesh = marker_mesh
	_edge_marker.material_override = _material(Color(0.98, 0.72, 0.20), 0.42)
	add_child(_edge_marker)

	_left_hand = HandVisual.new()
	_left_hand.name = "LeftHand"
	add_child(_left_hand)
	_left_hand.setup(false)
	_left_hand.snap_to(Vector3(-0.60, 0.30, 0.34))
	_left_hand.rotation_degrees = Vector3(18, -28, -48)
	_left_hand.set_pinch_amount(0.38)

	_right_hand = HandVisual.new()
	_right_hand.name = "RightHand"
	add_child(_right_hand)
	_right_hand.setup(true)
	_right_hand.snap_to(Vector3(-0.72, 0.28, 0.88))
	_right_hand.rotation_degrees = Vector3(-8, 8, 15)

	_pointer = PointerAdapter.new()
	_pointer.name = "PointerAdapter"
	add_child(_pointer)

	_audio = PeelAudio.new()
	_audio.name = "PeelAudio"
	add_child(_audio)

	_build_hud()

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)

	_hud = Label.new()
	_hud.name = "Instructions"
	_hud.position = Vector2(28, 24)
	_hud.size = Vector2(760, 100)
	_hud.add_theme_font_size_override("font_size", 19)
	_hud.add_theme_color_override("font_color", Color(0.93, 0.90, 0.84, 0.92))
	layer.add_child(_hud)

	_reward = Label.new()
	_reward.name = "Reward"
	_reward.position = Vector2(400, 576)
	_reward.size = Vector2(480, 90)
	_reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reward.add_theme_font_size_override("font_size", 34)
	_reward.add_theme_color_override("font_color", Color(0.98, 0.92, 0.76, 1.0))
	layer.add_child(_reward)

func _update_hud(state_name: String, phase_name: String, progress: float) -> void:
	var percent := int(round(progress * 100.0))
	var hint := "Find the warm dot • hold left mouse • pull slowly"
	if phase_name == "DETACHING":
		hint = "Final adhesive releasing…"
	elif phase_name == "HELD":
		hint = "Clean peel — label fully detached"
	_hud.text = "Peel %d%%   •   %s\n%s   •   R = reset" % [percent, phase_name, hint]

func _on_completed() -> void:
	_completed_this_frame = true
	var continuity := 1.0 if _release_count == 0 else maxf(0.55, 1.0 - float(_release_count) * 0.1)
	_pending_score = ScoreModel.score(100.0, 1.0, continuity)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		_reset_session()

func _reset_session() -> void:
	if _controller != null:
		_controller.reset()
	if _lifecycle != null:
		_lifecycle.reset()
	_release_count = 0
	_pending_score = 0
	_completed_this_frame = false
	_reset_timer = -1.0
	if _reward != null:
		_reward.text = ""
	if _label != null:
		_label.set_phase("ATTACHED")
		_label.set_detach_alpha(0.0)
		var front := _label.get_front_position(0.0)
		_label.set_peel(0.0, front)
	if _label_print != null:
		_label_print.set_order("A17", "OAT LATTE")
	if _right_hand != null:
		_right_hand.set_pinch_amount(0.18)
	if _audio != null:
		_audio.reset_feedback()

func _screen_to_plane(screen_position: Vector2, z_depth: float) -> Vector3:
	var origin := _camera.project_ray_origin(screen_position)
	var direction := _camera.project_ray_normal(screen_position)
	var plane := Plane(Vector3(0, 0, 1), z_depth)
	var hit = plane.intersects_ray(origin, direction)
	if hit == null:
		return _label.get_front_position(_controller.get_progress()) + Vector3(0, 0, 0.28)
	return hit

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material
