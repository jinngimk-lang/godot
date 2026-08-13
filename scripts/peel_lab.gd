extends Node3D

var _camera: Camera3D
var _cup: MeshInstance3D
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
var _session: SessionModel
var _release_count := 0
var _reset_timer := -1.0
var _completed_this_frame := false
var _pending_score := 0
var _advance_after_reset := false
var _paused := false

func _ready() -> void:
	_build_world()
	_session = SessionModel.new()
	_lifecycle = LabelLifecycle.new(0.16)
	_apply_current_variant()
	_reset_session()

func _process(delta: float) -> void:
	if _paused:
		_audio.reset_feedback()
		_update_hud("", _lifecycle.get_phase_name(), _controller.get_progress())
		_pointer.clear_transients()
		return

	if _reset_timer >= 0.0:
		_reset_timer -= delta
		if _reset_timer <= 0.0:
			if _advance_after_reset:
				_session.advance_item()
				_apply_current_variant()
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
		_handle_detached_label()

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

	_cup = MeshInstance3D.new()
	_cup.name = "Cup"
	var cup_mesh := CylinderMesh.new()
	cup_mesh.top_radius = 0.54
	cup_mesh.bottom_radius = 0.45
	cup_mesh.height = 1.48
	_cup.mesh = cup_mesh
	_cup.position = Vector3(0, 0.05, 0)
	_cup.material_override = _material(Color(0.89, 0.84, 0.74), 0.94)
	add_child(_cup)

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
	_hud.size = Vector2(900, 120)
	_hud.add_theme_font_size_override("font_size", 19)
	_hud.add_theme_color_override("font_color", Color(0.93, 0.90, 0.84, 0.92))
	layer.add_child(_hud)

	_reward = Label.new()
	_reward.name = "Reward"
	_reward.position = Vector2(370, 555)
	_reward.size = Vector2(540, 120)
	_reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reward.add_theme_font_size_override("font_size", 30)
	_reward.add_theme_color_override("font_color", Color(0.98, 0.92, 0.76, 1.0))
	layer.add_child(_reward)

func _update_hud(state_name: String, phase_name: String, progress: float) -> void:
	if _session == null:
		return
	var variant := _session.current_variant()
	if _paused:
		_hud.text = "PAUSED\nEsc Resume   •   R Reset Label   •   Shift+R Restart Run"
		return

	var percent := int(round(progress * 100.0))
	var hint := "Touch the gold edge • hold left mouse • pull gently"
	if state_name == "EDGE_HOVER":
		hint = "Hold left mouse, then pull away from the cup"
	elif state_name in ["EDGE_LIFT", "PINCHED"]:
		hint = "Keep holding • begin a slow steady pull"
	elif state_name == "PEELING":
		hint = "Steady pull • listen for each adhesive release"
	elif state_name == "RELEASED":
		hint = "Re-grab the gold edge to continue"
	if phase_name == "DETACHING":
		hint = "Last bit of adhesive…"
	elif phase_name == "HELD":
		hint = "Clean peel — nice."

	_hud.text = "%s   •   Peel %d%%\n%s\nStamps %d   •   Score %d   •   Feels %d/3   •   Esc Pause   •   R Reset   •   Shift+R Restart Run" % [
		String(variant.get("name", "Peel Calm")),
		percent,
		hint,
		_session.get_clean_peels(),
		_session.get_total_score(),
		_session.get_unlocked_count()
	]

func _on_completed() -> void:
	_completed_this_frame = true
	var continuity := 1.0 if _release_count == 0 else maxf(0.55, 1.0 - float(_release_count) * 0.1)
	_pending_score = ScoreModel.score(100.0, 1.0, continuity)

func _handle_detached_label() -> void:
	var progress_result: Dictionary = _session.record_clean_peel(_pending_score)
	var reward_text := "CLEAN PEEL  +%d" % _pending_score
	if bool(progress_result.get("unlocked_new", false)):
		reward_text += "\nNEW FEEL UNLOCKED"
	_reward.text = reward_text
	_advance_after_reset = true
	_reset_timer = 2.15

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		_paused = not _paused
		_audio.reset_feedback()
		_update_hud("", _lifecycle.get_phase_name(), _controller.get_progress())
		return
	if event.keycode == KEY_R:
		_paused = false
		if event.shift_pressed:
			_session.restart_run()
			_apply_current_variant()
		_reset_session()

func _apply_current_variant() -> void:
	var variant := _session.current_variant()
	_controller = PeelController.new({
		"base_adhesion": float(variant.get("base_adhesion", 11.0)),
		"release_increment": float(variant.get("release_increment", 0.038)),
		"speed_gain": float(variant.get("speed_gain", 0.018)),
		"angle_gain": float(variant.get("angle_gain", 0.30))
	})
	_controller.completed.connect(_on_completed)
	_label.label_width = float(variant.get("label_width", 1.20))
	_label.label_height = float(variant.get("label_height", 0.42))
	var cup_color: Color = variant.get("cup_color", Color(0.89, 0.84, 0.74))
	_cup.material_override = _material(cup_color, 0.94)

func _reset_session() -> void:
	if _controller != null:
		_controller.reset()
	if _lifecycle != null:
		_lifecycle.reset()
	_release_count = 0
	_pending_score = 0
	_completed_this_frame = false
	_reset_timer = -1.0
	_advance_after_reset = false
	if _reward != null:
		_reward.text = ""
	var fresh_grip_world := Vector3.ZERO
	var has_fresh_grip := false
	if _label != null:
		_label.set_phase("ATTACHED")
		_label.set_detach_alpha(0.0)
		var front := _label.get_front_position(0.0)
		_label.set_peel(0.0, front)
		fresh_grip_world = _label.to_global(front)
		has_fresh_grip = true
	if _label_print != null and _session != null:
		var variant := _session.current_variant()
		var order_code := "P%02d" % (_session.get_clean_peels() + 1)
		_label_print.set_order(order_code, String(variant.get("drink", "OAT LATTE")))
	if _right_hand != null:
		_right_hand.set_pinch_amount(0.18)
		_right_hand.tick(0.0)
		if has_fresh_grip:
			var current_pinch := _right_hand.get_pinch_world_position()
			_right_hand.position += fresh_grip_world - current_pinch
			_right_hand.set_grip_target(fresh_grip_world)
	if _audio != null:
		_audio.reset_feedback()
	_update_hud("", "ATTACHED", 0.0)

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
