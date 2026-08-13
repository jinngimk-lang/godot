extends Node3D

var _camera: Camera3D
var _label: LabelVisual
var _controller: PeelController
var _pointer: PointerAdapter
var _right_hand: HandVisual
var _left_hand: HandVisual
var _audio: PeelAudio
var _hud: Label
var _reward: Label
var _edge_marker: MeshInstance3D
var _print_text: Label3D
var _release_count := 0
var _reset_timer := -1.0

func _ready() -> void:
	_build_world()
	_controller = PeelController.new({
		"base_adhesion": 11.0,
		"release_increment": 0.038,
		"speed_gain": 0.018,
		"angle_gain": 0.3
	})
	_controller.completed.connect(_on_completed)
	_reset_session()

func _process(delta: float) -> void:
	if _reset_timer >= 0.0:
		_reset_timer -= delta
		if _reset_timer <= 0.0:
			_reset_session()

	var progress: float = _controller.get_progress()
	var front_world: Vector3 = _label.get_front_position(progress)
	_edge_marker.position = front_world
	var edge_screen: Vector2 = _camera.unproject_position(front_world)
	_controller.set_edge_position(edge_screen)

	var state: PointerState = _pointer.consume_frame()
	var before: float = progress
	var result: Dictionary = _controller.process_pointer(state, delta)
	progress = float(result["progress"])
	var released_amount: float = maxf(progress - before, 0.0)

	if state.released_this_frame and progress > 0.0 and not _controller.is_complete():
		_release_count += 1

	var hand_screen: Vector2 = result["hand_position"] as Vector2
	var grip_world: Vector3 = _screen_to_plane(hand_screen, _label.cup_radius + 0.44)
	_label.set_peel(progress, grip_world)
	_right_hand.set_target(grip_world + Vector3(0.0, -0.18, 0.18))
	_right_hand.tick(delta)
	_update_temporary_print(progress)

	var tension: float = hand_screen.distance_to(edge_screen) * 0.65
	var speed: float = state.velocity.length() / 100.0
	if String(result["state"]) == "PEELING":
		_audio.set_peel_feedback(speed, tension, released_amount)
		if released_amount > 0.025:
			_audio.trigger_release_tick()
	else:
		_audio.quiet()

	_update_hud(String(result["state"]), progress)
	_pointer.clear_transients()

func _build_world() -> void:
	_camera = Camera3D.new()
	_camera.name = "Camera"
	_camera.position = Vector3(0.0, 1.05, 4.25)
	_camera.fov = 42.0
	add_child(_camera)
	_camera.look_at(Vector3(0.0, 0.22, 0.0), Vector3.UP)
	_camera.current = true

	var key := DirectionalLight3D.new()
	key.name = "KeyLight"
	key.rotation_degrees = Vector3(-48, -28, 0)
	key.light_energy = 1.35
	key.shadow_enabled = true
	add_child(key)

	var fill := OmniLight3D.new()
	fill.name = "FillLight"
	fill.position = Vector3(-2.0, 1.8, 2.5)
	fill.light_energy = 3.0
	fill.omni_range = 7.0
	add_child(fill)

	var table := MeshInstance3D.new()
	table.name = "Table"
	var table_mesh := BoxMesh.new()
	table_mesh.size = Vector3(5.0, 0.16, 3.0)
	table.mesh = table_mesh
	table.position = Vector3(0, -0.72, 0)
	table.material_override = _material(Color(0.22, 0.16, 0.12), 0.82)
	add_child(table)

	var cup := MeshInstance3D.new()
	cup.name = "Cup"
	var cup_mesh := CylinderMesh.new()
	cup_mesh.top_radius = 0.54
	cup_mesh.bottom_radius = 0.45
	cup_mesh.height = 1.48
	cup.mesh = cup_mesh
	cup.position = Vector3(0, 0.05, 0)
	cup.material_override = _material(Color(0.83, 0.72, 0.56), 0.91)
	add_child(cup)

	var lid := MeshInstance3D.new()
	lid.name = "Lid"
	var lid_mesh := CylinderMesh.new()
	lid_mesh.top_radius = 0.57
	lid_mesh.bottom_radius = 0.56
	lid_mesh.height = 0.08
	lid.mesh = lid_mesh
	lid.position = Vector3(0, 0.83, 0)
	lid.material_override = _material(Color(0.12, 0.105, 0.095), 0.68)
	add_child(lid)

	_label = LabelVisual.new()
	_label.name = "PeelLabel"
	_label.label_y = 0.22
	_label.cup_radius = 0.53
	add_child(_label)

	_print_text = Label3D.new()
	_print_text.name = "OrderPrint"
	_print_text.text = "ORDER  A17\nOAT LATTE"
	_print_text.font_size = 42
	_print_text.pixel_size = 0.0036
	_print_text.modulate = Color(0.12, 0.11, 0.10, 1)
	_print_text.position = Vector3(0.12, 0.22, 0.553)
	add_child(_print_text)

	_edge_marker = MeshInstance3D.new()
	_edge_marker.name = "PeelEdge"
	var marker_mesh := SphereMesh.new()
	marker_mesh.radius = 0.035
	marker_mesh.height = 0.07
	_edge_marker.mesh = marker_mesh
	_edge_marker.material_override = _material(Color(0.96, 0.75, 0.28), 0.45)
	add_child(_edge_marker)

	_left_hand = HandVisual.new()
	_left_hand.name = "LeftHand"
	add_child(_left_hand)
	_left_hand.setup(false)
	_left_hand.snap_to(Vector3(-0.78, -0.05, 0.48))
	_left_hand.rotation_degrees = Vector3(12, -18, -24)

	_right_hand = HandVisual.new()
	_right_hand.name = "RightHand"
	add_child(_right_hand)
	_right_hand.setup(true)
	_right_hand.snap_to(Vector3(-0.78, 0.02, 0.95))
	_right_hand.rotation_degrees = Vector3(-10, 12, 18)

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
	_hud.position = Vector2(30, 26)
	_hud.size = Vector2(720, 100)
	_hud.text = "Move to the gold edge • Hold left mouse • Pull slowly"
	_hud.add_theme_font_size_override("font_size", 22)
	layer.add_child(_hud)

	_reward = Label.new()
	_reward.name = "Reward"
	_reward.position = Vector2(430, 575)
	_reward.size = Vector2(420, 90)
	_reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reward.add_theme_font_size_override("font_size", 34)
	layer.add_child(_reward)

func _update_hud(state_name: String, progress: float) -> void:
	var percent := int(round(progress * 100.0))
	_hud.text = "Peel %d%%   •   %s\nGold dot = current peel edge   •   R = reset" % [percent, state_name]

func _update_temporary_print(progress: float) -> void:
	if _print_text == null:
		return
	var color := _print_text.modulate
	color.a = clampf(1.0 - progress * 7.5, 0.0, 1.0)
	_print_text.modulate = color

func _on_completed() -> void:
	var continuity := 1.0 if _release_count == 0 else maxf(0.55, 1.0 - float(_release_count) * 0.1)
	var points := ScoreModel.score(100.0, 1.0, continuity)
	_reward.text = "CLEAN PEEL  +%d" % points
	_audio.trigger_completion()
	_reset_timer = 1.6

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		_reset_session()

func _reset_session() -> void:
	if _controller != null:
		_controller.reset()
	_release_count = 0
	_reset_timer = -1.0
	if _reward != null:
		_reward.text = ""
	if _label != null:
		var front := _label.get_front_position(0.0)
		_label.set_peel(0.0, front)
	if _print_text != null:
		_print_text.modulate = Color(0.12, 0.11, 0.10, 1)
	if _audio != null:
		_audio.quiet()

func _screen_to_plane(screen_position: Vector2, z_depth: float) -> Vector3:
	var origin := _camera.project_ray_origin(screen_position)
	var direction := _camera.project_ray_normal(screen_position)
	var plane := Plane(Vector3(0, 0, 1), z_depth)
	var hit = plane.intersects_ray(origin, direction)
	if hit == null:
		return _label.get_front_position(_controller.get_progress()) + Vector3(0, 0, 0.35)
	return hit

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material
