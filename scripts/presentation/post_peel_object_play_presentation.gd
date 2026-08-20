extends Node
class_name PostPeelObjectPlayPresentation

const PAPER_SQUEEZE_SHADER := "res://art/shaders/post_peel_paper_cup.gdshader"

var _model: PostPeelObjectPlay
var _lab: Node3D
var _product: ProductPresentation
var _cup: MeshInstance3D
var _lid: MeshInstance3D
var _residue: ResidueVisual
var _hero_detail: Node3D
var _bottle_polish: Node3D
var _prompt: Label
var _lmb_playing := false
var _was_resolved := false
var _cup_original_material: Material
var _paper_play_material: ShaderMaterial
var _paper_material_active := false

func _ready() -> void:
	_model = PostPeelObjectPlay.new()
	_model.name = "PostPeelObjectPlayModel"
	add_child(_model)
	call_deferred("_bind")

func _process(delta: float) -> void:
	if _lab == null or _product == null:
		_bind()
	if _model == null:
		return
	var resolved := _is_resolved()
	if resolved != _was_resolved:
		_was_resolved = resolved
		_lmb_playing = false
		_model.set_active(false)
		if resolved:
			_model.configure_kind(_active_kind())
			if _active_kind() == "paper_cup":
				_activate_paper_cup_material()
		else:
			_restore_paper_cup_material()
			_model.reset()
	_model.tick(delta)
	_apply_visuals(resolved)
	_update_prompt(resolved)

func _unhandled_input(event: InputEvent) -> void:
	if _model == null or not _is_resolved() or _is_paused():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_lmb_playing = event.pressed
		_model.set_active(_lmb_playing)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _lmb_playing:
		_model.feed_drag(event.relative,maxf(get_process_delta_time(),0.001))
		get_viewport().set_input_as_handled()

func get_runtime_contract() -> Dictionary:
	return {
		"activation":"label_resolved",
		"primary":"LMB drag",
		"slow_drag":"squeeze",
		"fast_alternating_drag":"shake",
		"inspect":"RMB drag",
		"finish":"Continue",
		"hands":false,
		"paper_squeeze":"localized_vertex_band",
		"visible_liquid_lag":true
	}

func debug_stage_resolved(kind: String) -> void:
	if _model == null:
		_model = PostPeelObjectPlay.new()
		_model.name = "PostPeelObjectPlayModel"
		add_child(_model)
	if _lab == null or _product == null:
		_bind()
	_model.configure_kind(kind)
	_model.set_active(true)
	_was_resolved = true
	if kind == "paper_cup":
		_activate_paper_cup_material()
	else:
		_restore_paper_cup_material()
	_apply_visuals(true)
	_update_prompt(true)

func debug_feed_drag(relative: Vector2, delta: float) -> void:
	if _model == null:
		return
	_model.set_active(true)
	_model.feed_drag(relative,maxf(delta,0.001))
	_model.tick(maxf(delta,0.001))
	_apply_visuals(true)
	_update_prompt(true)

func debug_release_play(delta: float = 0.016) -> void:
	if _model == null:
		return
	_model.set_active(false)
	_model.tick(maxf(delta,0.001))
	_apply_visuals(true)
	_update_prompt(true)

func get_model() -> PostPeelObjectPlay:
	return _model

func _bind() -> void:
	_lab = get_parent() as Node3D
	if _lab == null:
		return
	_product = _lab.get_node_or_null("ProductPresentation") as ProductPresentation
	_cup = _lab.get_node_or_null("Cup") as MeshInstance3D
	_lid = _lab.get_node_or_null("Lid") as MeshInstance3D
	_residue = _lab.get_node_or_null("ResidueVisual") as ResidueVisual
	_hero_detail = _lab.get_node_or_null("HeroProductDetailPresentation") as Node3D
	_bottle_polish = _lab.get_node_or_null("BottleHeroPolish") as Node3D
	_ensure_prompt()

func _is_resolved() -> bool:
	if _lab == null:
		return false
	var lifecycle = _lab.get("_lifecycle")
	return lifecycle != null and lifecycle.has_method("is_resolved") and bool(lifecycle.call("is_resolved"))

func _is_paused() -> bool:
	return bool(_lab.get("_paused")) if _lab != null else false

func _active_kind() -> String:
	return _product.get_active_kind() if _product != null else "paper_cup"

func _apply_visuals(resolved: bool) -> void:
	var scale := _model.get_squeeze_scale() if resolved else Vector3.ONE
	var squeeze_amount := _model.get_squeeze_amount() if resolved and _model.has_method("get_squeeze_amount") else 0.0
	var shake := _model.get_shake_angle() if resolved else 0.0
	var tilt := _model.get_liquid_tilt() if resolved else 0.0
	var kind := _active_kind()
	if kind == "paper_cup" and resolved:
		_activate_paper_cup_material()
		if _paper_play_material != null:
			_paper_play_material.set_shader_parameter("squeeze_amount",squeeze_amount)
		for node in [_cup,_lid,_product,_hero_detail,_bottle_polish]:
			if node != null:
				node.scale = Vector3.ONE
		if _residue != null:
			_residue.scale = Vector3(1.0-squeeze_amount*0.45,1.0,1.0+squeeze_amount*0.12)
	else:
		for node in [_cup,_lid,_product,_residue,_hero_detail,_bottle_polish]:
			if node != null:
				node.scale = scale
	for node in [_cup,_lid,_product,_residue,_hero_detail,_bottle_polish]:
		if node == null:
			continue
		node.rotation.z = shake
		node.rotation.x = shake*0.22
	_apply_liquid_lag(tilt)

func _activate_paper_cup_material() -> void:
	if _cup == null or _paper_material_active:
		return
	var shader := load(PAPER_SQUEEZE_SHADER) as Shader
	if shader == null:
		return
	_cup_original_material = _cup.material_override
	_paper_play_material = ShaderMaterial.new()
	_paper_play_material.shader = shader
	_paper_play_material.set_shader_parameter("paper_color",Color(0.95,0.935,0.895,1.0))
	_paper_play_material.set_shader_parameter("fiber_strength",0.022)
	_paper_play_material.set_shader_parameter("squeeze_amount",0.0)
	_cup.material_override = _paper_play_material
	_paper_material_active = true

func _restore_paper_cup_material() -> void:
	if not _paper_material_active:
		return
	if _cup != null:
		_cup.material_override = _cup_original_material
	_cup_original_material = null
	_paper_play_material = null
	_paper_material_active = false

func _apply_liquid_lag(tilt: float) -> void:
	if _product == null:
		return
	var jar_contents := _product.get_node_or_null("JarContents") as Node3D
	if jar_contents != null:
		jar_contents.rotation.z = tilt
	if _hero_detail != null:
		_apply_liquid_lag_recursive(_hero_detail,tilt)
	# Yuzu has its own physically safer presentation: the closed liquid body is
	# stable while only the free surface counter-tilts and the mass lags slightly.
	if _bottle_polish != null and _bottle_polish.has_method("set_liquid_inertia"):
		_bottle_polish.call("set_liquid_inertia",tilt)

func _apply_liquid_lag_recursive(node: Node, tilt: float) -> void:
	for child in node.get_children():
		if child is Node3D and (String(child.name).contains("Sauce") or String(child.name).contains("Liquid")):
			(child as Node3D).rotation.z = tilt
		_apply_liquid_lag_recursive(child,tilt)

func _ensure_prompt() -> void:
	if _prompt != null or _lab == null:
		return
	var hud := _lab.get_node_or_null("HUD") as CanvasLayer
	if hud == null:
		return
	_prompt = Label.new()
	_prompt.name = "PostPeelObjectPlayHint"
	_prompt.position = Vector2(405,552)
	_prompt.size = Vector2(470,34)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size",13)
	_prompt.add_theme_color_override("font_color",Color(1.0,0.82,0.40,0.96))
	_prompt.add_theme_color_override("font_shadow_color",Color(0,0,0,0.82))
	_prompt.add_theme_constant_override("shadow_offset_x",2)
	_prompt.add_theme_constant_override("shadow_offset_y",2)
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.visible = false
	hud.add_child(_prompt)

func _update_prompt(resolved: bool) -> void:
	if _prompt == null:
		_ensure_prompt()
	if _prompt == null:
		return
	_prompt.visible = resolved and not _is_paused()
	if not _prompt.visible:
		return
	var state := _model.get_feedback_text()
	var verb := "PLAY"
	if state.begins_with("SHAKING"):
		verb = "SHAKE"
	elif state.begins_with("SQUEEZE"):
		verb = "SQUEEZE"
	_prompt.text = "%s  •  LMB drag   RMB inspect   Continue" % verb

func _exit_tree() -> void:
	_restore_paper_cup_material()
	if _model != null:
		_model.reset()
	_model = null
	_lab = null
	_product = null
	_cup = null
	_lid = null
	_residue = null
	_hero_detail = null
	_bottle_polish = null
	_prompt = null
