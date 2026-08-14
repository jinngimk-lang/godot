extends Node3D

var _camera: Camera3D
var _cup: MeshInstance3D
var _lid: MeshInstance3D
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
var _ritual: RitualFlow
var _crumple: CupCrumpleModel
var _crumple_presentation: CupCrumplePresentation
var _contents_presentation: CupContentsPresentation
var _venue: VenuePresentation
var _product: ProductPresentation
var _residue: ResidueVisual
var _inspection: InspectionController
var _release_count := 0
var _reset_timer := -1.0
var _completed_this_frame := false
var _pending_score := 0
var _advance_after_reset := false
var _detach_reward_recorded := false
var _paused := false

func _ready() -> void:
	_build_world()
	_crumple_presentation = get_node_or_null("CupCrumplePresentation") as CupCrumplePresentation
	_contents_presentation = get_node_or_null("CupContentsPresentation") as CupContentsPresentation
	_venue = get_node_or_null("VenuePresentation") as VenuePresentation
	_disable_legacy_cafe_stage()
	_session = SessionModel.new()
	_ritual = RitualFlow.new()
	_lifecycle = LabelLifecycle.new(0.16)
	_inspection = InspectionController.new({"sensitivity":0.006,"follow_rate":18.0})
	_apply_current_variant()
	_reset_session()

func _process(delta: float) -> void:
	if _paused:
		_audio.reset_feedback()
		_update_hud("",_lifecycle.get_phase_name(),_controller.get_progress())
		_pointer.clear_transients()
		return

	_update_inspection(delta)
	_ritual.update(delta)
	var ritual_phase := _ritual.get_phase_name()
	if _uses_crumple() and ritual_phase in ["CRUMPLE_READY","CRUMPLING","RITUAL_COMPLETE"]:
		var crumple_state: PointerState = _pointer.consume_frame()
		_process_crumple_pointer(crumple_state)
		_audio.quiet()
		_update_hud("",_lifecycle.get_phase_name(),_controller.get_progress())
		_pointer.clear_transients()
		return

	var progress := _controller.get_progress()
	var front_local := _label.get_front_position(progress)
	var front_world := _label.to_global(front_local)
	var edge_screen := _camera.unproject_position(front_world)
	_controller.set_edge_position(edge_screen)
	_controller.set_grab_region(_project_label_region())

	var state: PointerState = _pointer.consume_frame()
	var before := progress
	_completed_this_frame = false
	var result: Dictionary = _controller.process_pointer(state,delta)
	progress = float(result["progress"])
	var released_amount := maxf(progress-before,0.0)

	if state.released_this_frame and progress > 0.0 and not _controller.is_complete():
		_release_count += 1

	_lifecycle.update(progress,_completed_this_frame,delta)
	var phase_name := _lifecycle.get_phase_name()
	_label.set_phase(phase_name)
	_label.set_detach_alpha(_lifecycle.get_detach_alpha())
	var detached_now := _lifecycle.consume_detach_event()

	var hand_screen: Vector2 = result["hand_position"] as Vector2
	var desired_world := _screen_to_plane(hand_screen,front_world.z+0.28)
	var desired_local := _label.to_local(desired_world)
	var effective_local := _label.get_effective_grip(progress,desired_local)
	var effective_world := _label.to_global(effective_local)
	var state_name := String(result["state"])
	var pinching := state_name in ["EDGE_LIFT","PINCHED","PEELING","COMPLETE"] or phase_name in ["DETACHING","HELD"]
	_right_hand.set_pinch_amount(1.0 if pinching else 0.18)
	_right_hand.set_grip_target(effective_world)
	_right_hand.tick(delta)
	var pinch_world := _right_hand.get_pinch_world_position()
	_label.set_peel(progress,_label.to_local(pinch_world))

	# Legacy gold point is kept only as a hidden discoverability node. The label
	# surface owns peel input, so interaction never depends on this marker.
	_edge_marker.global_position = front_world
	_edge_marker.visible = false

	var integrity := float(result.get("integrity",1.0))
	var residue := float(result.get("residue",0.0))
	_residue.set_residue(progress,residue,integrity)

	var tension := hand_screen.distance_to(edge_screen)*0.65
	var speed := state.velocity.length()/100.0
	var active_peel := state_name == "PEELING" and phase_name == "PEELING"
	_audio.set_feedback(active_peel,speed,tension,released_amount,detached_now,delta)
	if detached_now:
		_handle_detached_label()
	_update_hud(state_name,phase_name,progress)
	_pointer.clear_transients()

func _process_crumple_pointer(state: PointerState) -> void:
	if _ritual == null or _crumple == null or not _uses_crumple():
		return
	var phase := _ritual.get_phase_name()
	if phase == "CRUMPLE_READY" and state.pressed:
		var cup_screen := _camera.unproject_position(_cup.global_position)
		if _ritual.begin_crumple():
			_crumple.begin_gesture(state.position.x,cup_screen.x)
			phase = _ritual.get_phase_name()
	elif phase == "CRUMPLING" and state.pressed and _crumple.get_gesture_side() == 0:
		var cup_screen := _camera.unproject_position(_cup.global_position)
		_crumple.begin_gesture(state.position.x,cup_screen.x)
	if phase != "CRUMPLING":
		return
	if state.released_this_frame or not state.pressed:
		_crumple.end_gesture()
		return
	var change: Dictionary = _crumple.apply_drag(state.relative.x)
	var pulse := float(change.get("event_strength",0.0))
	if _crumple_presentation != null:
		_crumple_presentation.set_crumple(_crumple.get_progress(),_crumple.get_gesture_side(),pulse)
	if _contents_presentation != null:
		_contents_presentation.set_crumple(_crumple.get_progress(),_crumple.get_gesture_side(),pulse)
	if pulse > 0.0:
		_audio.trigger_crumple(pulse)
	if _crumple.is_complete() and _ritual.mark_crumple_complete() and _ritual.consume_reward_event():
		_reward.text = "%s\nStay a moment • R Next" % _crumple_feedback_text()

func _build_world() -> void:
	_camera = Camera3D.new()
	_camera.name = "Camera"
	_camera.position = Vector3(0.0,0.84,3.54)
	_camera.fov = 38.0
	add_child(_camera)
	_camera.look_at(Vector3(0.0,0.20,0.0),Vector3.UP)
	_camera.current = true

	var key := DirectionalLight3D.new()
	key.name = "KeyLight"
	key.rotation_degrees = Vector3(-47,-34,0)
	key.light_energy = 0.92
	key.shadow_enabled = true
	add_child(key)

	var fill := OmniLight3D.new()
	fill.name = "FillLight"
	fill.position = Vector3(-1.8,1.7,2.2)
	fill.light_energy = 1.05
	fill.omni_range = 6.0
	add_child(fill)

	var rim := OmniLight3D.new()
	rim.name = "RimLight"
	rim.position = Vector3(1.65,1.40,-0.85)
	rim.light_energy = 0.70
	rim.omni_range = 4.0
	add_child(rim)

	var table := MeshInstance3D.new()
	table.name = "Table"
	var table_mesh := BoxMesh.new()
	table_mesh.size = Vector3(5.3,0.16,3.2)
	table.mesh = table_mesh
	table.position = Vector3(0,-0.72,0)
	table.material_override = _material(Color(0.22,0.115,0.055),0.54)
	add_child(table)

	_cup = MeshInstance3D.new()
	_cup.name = "Cup"
	var cup_mesh := CylinderMesh.new()
	cup_mesh.top_radius = 0.54
	cup_mesh.bottom_radius = 0.45
	cup_mesh.height = 1.48
	cup_mesh.radial_segments = 64
	_cup.mesh = cup_mesh
	_cup.position = Vector3(0,0.05,0)
	_cup.material_override = _material(Color(0.89,0.84,0.74),0.90)
	add_child(_cup)

	_lid = MeshInstance3D.new()
	_lid.name = "Lid"
	var lid_mesh := CylinderMesh.new()
	lid_mesh.top_radius = 0.57
	lid_mesh.bottom_radius = 0.56
	lid_mesh.height = 0.08
	lid_mesh.radial_segments = 64
	_lid.mesh = lid_mesh
	_lid.position = Vector3(0,0.83,0)
	_lid.material_override = _material(Color(0.035,0.032,0.030),0.22)
	add_child(_lid)

	_product = ProductPresentation.new()
	_product.name = "ProductPresentation"
	add_child(_product)

	_label = LabelVisual.new()
	_label.name = "PeelLabel"
	_label.label_y = 0.72
	_label.cup_radius = 0.53
	add_child(_label)

	_label_print = LabelPrint.new()
	_label_print.name = "LabelPrint"
	add_child(_label_print)
	_label.set_print_texture(_label_print.get_texture())

	_residue = ResidueVisual.new()
	_residue.name = "ResidueVisual"
	add_child(_residue)

	_edge_marker = MeshInstance3D.new()
	_edge_marker.name = "PeelEdge"
	var marker_mesh := SphereMesh.new()
	marker_mesh.radius = 0.014
	marker_mesh.height = 0.028
	_edge_marker.mesh = marker_mesh
	_edge_marker.material_override = _material(Color(0.98,0.72,0.20),0.42)
	add_child(_edge_marker)

	_left_hand = HandVisual.new()
	_left_hand.name = "LeftHand"
	add_child(_left_hand)
	_left_hand.setup(false)
	_left_hand.snap_to(Vector3(0.60,0.22,0.40))
	_left_hand.rotation_degrees = Vector3(14,42,45)
	_left_hand.set_pinch_amount(0.36)

	_right_hand = HandVisual.new()
	_right_hand.name = "RightHand"
	add_child(_right_hand)
	_right_hand.setup(true)
	_right_hand.snap_to(Vector3(-0.72,0.28,0.88))
	_right_hand.rotation_degrees = Vector3(18,-22,-8)

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
	_hud.position = Vector2(28,22)
	_hud.size = Vector2(1030,130)
	_hud.add_theme_font_size_override("font_size",18)
	_hud.add_theme_color_override("font_color",Color(0.96,0.95,0.91,0.95))
	layer.add_child(_hud)
	_reward = Label.new()
	_reward.name = "Reward"
	_reward.position = Vector2(365,584)
	_reward.size = Vector2(550,84)
	_reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reward.add_theme_font_size_override("font_size",24)
	_reward.add_theme_color_override("font_color",Color(0.98,0.92,0.76,0.98))
	layer.add_child(_reward)

func _update_hud(state_name: String, phase_name: String, progress: float) -> void:
	if _session == null:
		return
	var variant := _session.current_variant()
	var scene_id := String((variant.get("scene_profile",{}) as Dictionary).get("id","cafe_window"))
	var venue_name := {"cafe_window":"WINDOW CAFÉ","night_bar":"AMBER BAR","market_coldcase":"MARKET COOLER"}.get(scene_id,"WINDOW CAFÉ")
	var integrity := _controller.get_integrity() if _controller != null else 1.0
	var residue := _controller.get_residue() if _controller != null else 0.0
	var grade := _quality_grade(integrity,residue)
	var percent := int(round(progress*100.0))
	var post_action := String(variant.get("post_peel_action","crumple"))
	var hint := String(variant.get("hint","slow pull feels cleaner"))
	if _paused:
		_hud.text = "%s  •  PAUSED\nEsc Resume  •  R Reset  •  Q/E Scene  •  1/2/3" % venue_name
		return
	if phase_name == "DETACHING": hint = "last adhesive fibers releasing…"
	elif phase_name == "HELD": hint = "label released • RMB inspect the surface"
	elif state_name == "PEELING": hint = "steady pull • ease off if the paper starts to tear"
	elif state_name == "RELEASED": hint = "re-grab anywhere on the visible label"
	if _uses_crumple() and _ritual != null and _ritual.get_phase_name() in ["CRUMPLE_READY","CRUMPLING","RITUAL_COMPLETE"]:
		var crumple_percent := int(round((_crumple.get_progress() if _crumple != null else 0.0)*100.0))
		hint = "optional squeeze %d%% • or R Next" % crumple_percent
	elif post_action == "inspect" and phase_name == "HELD":
		hint = "RMB drag to inspect residue • Q/E changes scene"
	_hud.text = "%s  •  %s\nPeel %d%%  •  Quality %s  •  residue %d%%\n%s\nLMB Peel anywhere  •  RMB Inspect  •  Q/E Scene  •  1/2/3  •  Esc Pause  •  R Reset" % [
		venue_name,String(variant.get("name","Peel Calm")),percent,grade,int(round(residue*100.0)),hint
	]

func _quality_grade(integrity: float, residue: float) -> String:
	var quality := clampf(integrity-residue*0.55,0.0,1.0)
	if quality >= 0.90: return "A"
	if quality >= 0.72: return "B"
	if quality >= 0.52: return "C"
	return "D"

func _on_completed() -> void:
	_completed_this_frame = true
	var continuity := 1.0 if _release_count == 0 else maxf(0.55,1.0-float(_release_count)*0.1)
	_pending_score = ScoreModel.score(100.0,1.0,continuity)

func _handle_detached_label() -> void:
	if _detach_reward_recorded:
		return
	_detach_reward_recorded = true
	var progress_result := _session.record_ritual_complete()
	var grade := _quality_grade(_controller.get_integrity(),_controller.get_residue())
	var reward_text := "CLEAN RELEASE" if grade in ["A","B"] else "TEXTURED RELEASE"
	if bool(progress_result.get("unlocked_new",false)):
		reward_text += "\nnew tactile profile unlocked"
	elif _uses_crumple():
		reward_text += "\noptional squeeze • or R Next"
	else:
		reward_text += "\nRMB inspect • Q/E next scene"
	_reward.text = reward_text
	_reset_timer = -1.0
	_advance_after_reset = false
	if _uses_crumple():
		_ritual.on_label_detached()
	_pointer.quarantine_current_press()

func _unhandled_input(event: InputEvent) -> void:
	if _inspection == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed and not _paused:
			_inspection.begin()
		else:
			_inspection.end()
	elif event is InputEventMouseMotion and _inspection.is_active() and not _paused:
		_inspection.drag(event.relative.x,0.0)

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		if _paused:
			_paused = false
			_pointer.resume_gameplay_input()
		else:
			_pointer.suspend_gameplay_input()
			_paused = true
			if _inspection != null: _inspection.end()
		_audio.reset_feedback()
		_update_hud("",_lifecycle.get_phase_name(),_controller.get_progress())
		return
	if event.keycode == KEY_Q:
		_select_showcase_relative(-1)
		return
	if event.keycode == KEY_E:
		_select_showcase_relative(1)
		return
	if event.keycode in [KEY_1,KEY_2,KEY_3]:
		_select_showcase(int(event.keycode-KEY_1))
		return
	if event.keycode == KEY_R:
		_paused = false
		if event.shift_pressed:
			_session.restart_run()
			_apply_current_variant()
			_reset_session()
			return
		var ritual_phase := _ritual.get_phase_name() if _ritual != null else "PEEL"
		if _uses_crumple() and ritual_phase in ["PEEL_SETTLE","CRUMPLE_READY","CRUMPLING","RITUAL_COMPLETE"]:
			if _crumple != null: _crumple.end_gesture()
			if _ritual.request_next(): _consume_next_request()
			return
		_reset_session()

func _select_showcase_relative(direction: int) -> void:
	if _session == null: return
	_select_showcase(_session.get_variant_index()+direction)

func _select_showcase(index: int) -> void:
	_paused = false
	if _inspection != null: _inspection.reset()
	_session.select_variant(index)
	_apply_current_variant()
	_reset_session()

func debug_select_variant(index: int) -> void:
	_select_showcase(index)

func _consume_next_request() -> void:
	if _ritual != null and _ritual.consume_next_request():
		_advance_to_next_item()

func _advance_to_next_item() -> void:
	_session.advance_item()
	_apply_current_variant()
	_reset_session()

func _apply_current_variant() -> void:
	var variant := _session.current_variant()
	_controller = PeelController.new({
		"base_adhesion":float(variant.get("base_adhesion",11.0)),
		"release_increment":float(variant.get("release_increment",0.038)),
		"speed_gain":float(variant.get("speed_gain",0.018)),
		"angle_gain":float(variant.get("angle_gain",0.30)),
		"bond_response":float(variant.get("bond_response",10.0)),
		"bond_relaxation":float(variant.get("bond_relaxation",4.0)),
		"safe_pull_speed":float(variant.get("safe_pull_speed",5.0)),
		"tear_pull_speed":float(variant.get("tear_pull_speed",12.0)),
		"residue_gain":float(variant.get("residue_gain",0.18))
	})
	_controller.completed.connect(_on_completed)
	_label.label_width = float(variant.get("label_width",1.20))
	_label.label_height = float(variant.get("label_height",0.42))
	_label.label_y = float(variant.get("label_y",0.72))
	var cup_dims: Dictionary = variant.get("cup_dimensions",{})
	var cup_mesh := _cup.mesh as CylinderMesh
	if cup_mesh != null:
		cup_mesh.top_radius = maxf(float(cup_dims.get("top_radius",0.54)),0.10)
		cup_mesh.bottom_radius = maxf(float(cup_dims.get("bottom_radius",0.45)),0.10)
		cup_mesh.height = maxf(float(cup_dims.get("height",1.48)),0.40)
		_label.cup_radius = cup_mesh.top_radius-0.006
		if _lid != null and _lid.mesh is CylinderMesh:
			var lid_mesh := _lid.mesh as CylinderMesh
			lid_mesh.top_radius = cup_mesh.top_radius+0.03
			lid_mesh.bottom_radius = cup_mesh.top_radius+0.02
			_lid.position.y = _cup.position.y+cup_mesh.height*0.5+lid_mesh.height*0.5
		_residue.configure(cup_mesh.bottom_radius,cup_mesh.top_radius,cup_mesh.height,_cup.position.y,_label.label_width,_label.label_height,_label.label_y)
	var container_profile: Dictionary = variant.get("container_profile",{})
	_product.apply_profile(container_profile)
	_product.apply_to_base(_cup,_lid,container_profile)
	if _venue != null:
		_venue.apply_profile(variant.get("scene_profile",{}) as Dictionary)
	var crumple_profile: Dictionary = variant.get("crumple_profile",{})
	if _crumple == null:
		_crumple = CupCrumpleModel.new(crumple_profile)
	else:
		_crumple.configure(crumple_profile)
		_crumple.reset()
	if _crumple_presentation != null:
		_crumple_presentation.visible = _uses_crumple()
		_crumple_presentation.set_profile(variant)
		_crumple_presentation.reset_visual()
	if _contents_presentation != null:
		_contents_presentation.set_profile(variant)
		_contents_presentation.reset_visual()
	_apply_inspection_yaw(0.0)

func _reset_session() -> void:
	if _pointer != null:
		_pointer.resume_gameplay_input()
		_pointer.quarantine_current_press()
	if _controller != null: _controller.reset()
	if _lifecycle != null: _lifecycle.reset()
	if _ritual != null: _ritual.reset()
	if _crumple != null: _crumple.reset()
	if _crumple_presentation != null: _crumple_presentation.reset_visual()
	if _contents_presentation != null: _contents_presentation.reset_visual()
	if _inspection != null: _inspection.reset()
	_apply_inspection_yaw(0.0)
	_release_count = 0
	_pending_score = 0
	_completed_this_frame = false
	_reset_timer = -1.0
	_advance_after_reset = false
	_detach_reward_recorded = false
	if _reward != null: _reward.text = ""
	if _residue != null: _residue.set_residue(0.0,0.0,1.0)
	var fresh_grip_world := Vector3.ZERO
	var has_fresh_grip := false
	if _label != null:
		_label.set_phase("ATTACHED")
		_label.set_detach_alpha(0.0)
		var front := _label.get_front_position(0.0)
		_label.set_peel(0.0,front)
		fresh_grip_world = _label.to_global(front)
		has_fresh_grip = true
	if _label_print != null and _session != null:
		var variant := _session.current_variant()
		var order_code := "P%02d" % (_session.get_clean_peels()+1)
		_label_print.set_order(order_code,String(variant.get("drink","COCOA CLOUD")))
	if _right_hand != null:
		_right_hand.set_pinch_amount(0.18)
		_right_hand.tick(0.0)
		if has_fresh_grip:
			var current_pinch := _right_hand.get_pinch_world_position()
			_right_hand.position += fresh_grip_world-current_pinch
			_right_hand.set_grip_target(fresh_grip_world)
	if _audio != null: _audio.reset_feedback()
	_update_hud("","ATTACHED",0.0)

func _update_inspection(delta: float) -> void:
	if _inspection == null:
		return
	var yaw := _inspection.tick(delta)
	_apply_inspection_yaw(yaw)
	var support := Vector3(0.58+sin(yaw)*0.10,0.24,0.37+cos(yaw)*0.035)
	_left_hand.set_grip_target(support)
	_left_hand.tick(delta)

func _apply_inspection_yaw(yaw: float) -> void:
	if _cup != null: _cup.rotation.y = yaw
	if _lid != null: _lid.rotation.y = yaw
	if _label != null: _label.rotation.y = yaw
	if _product != null: _product.set_inspection_yaw(yaw)
	if _residue != null: _residue.set_inspection_yaw(yaw)
	if _contents_presentation != null: _contents_presentation.rotation.y = yaw

func _project_label_region() -> Rect2:
	if _camera == null or _label == null or _cup == null or not (_cup.mesh is CylinderMesh):
		return Rect2()
	var mesh := _cup.mesh as CylinderMesh
	var points: Array[Vector2] = []
	for u in [0.0,0.5,1.0]:
		for y in [_label.label_y-_label.label_height*0.5,_label.label_y+_label.label_height*0.5]:
			var local := CupSurface.attached_point_on_frustum(float(u),_label.label_width,float(y),mesh.bottom_radius,mesh.top_radius,mesh.height,_cup.position.y,0.016)
			points.append(_camera.unproject_position(_label.to_global(local)))
	if points.is_empty(): return Rect2()
	var min_p := points[0]
	var max_p := points[0]
	for p in points:
		min_p.x = minf(min_p.x,p.x)
		min_p.y = minf(min_p.y,p.y)
		max_p.x = maxf(max_p.x,p.x)
		max_p.y = maxf(max_p.y,p.y)
	return Rect2(min_p,max_p-min_p).grow(8.0)

func _uses_crumple() -> bool:
	if _session == null: return true
	return String(_session.current_variant().get("post_peel_action","crumple")) == "crumple"

func _disable_legacy_cafe_stage() -> void:
	var legacy := get_node_or_null("CafePresentation") as Node3D
	if legacy == null: return
	legacy.visible = false
	var old_world := legacy.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if old_world != null: old_world.environment = null

func _crumple_feedback_text() -> String:
	return "GENTLE CRUMPLE"

func _screen_to_plane(screen_position: Vector2, z_depth: float) -> Vector3:
	var origin := _camera.project_ray_origin(screen_position)
	var direction := _camera.project_ray_normal(screen_position)
	var plane := Plane(Vector3(0,0,1),z_depth)
	var hit = plane.intersects_ray(origin,direction)
	if hit == null:
		return _label.to_global(_label.get_front_position(_controller.get_progress())+Vector3(0,0,0.28))
	return hit

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material
