extends Node
class_name PostPeelObjectPlayPresentation

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
		else:
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
		"hands":false
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
	var shake := _model.get_shake_angle() if resolved else 0.0
	var tilt := _model.get_liquid_tilt() if resolved else 0.0
	for node in [_cup,_lid,_product,_residue,_hero_detail,_bottle_polish]:
		if node == null:
			continue
		node.scale = scale
		node.rotation.z = shake
		node.rotation.x = shake*0.22
	_apply_liquid_lag(tilt)

func _apply_liquid_lag(tilt: float) -> void:
	if _product == null:
		return
	for name in ["BottleLiquid","JarContents"]:
		var liquid := _product.get_node_or_null(name) as Node3D
		if liquid != null:
			liquid.rotation.z = tilt
	if _hero_detail != null:
		for child in _hero_detail.get_children():
			if child is Node3D and (String(child.name).contains("Sauce") or String(child.name).contains("Liquid")):
				(child as Node3D).rotation.z = tilt

func _ensure_prompt() -> void:
	if _prompt != null or _lab == null:
		return
	var hud := _lab.get_node_or_null("HUD") as CanvasLayer
	if hud == null:
		return
	_prompt = Label.new()
	_prompt.name = "PostPeelObjectPlayHint"
	_prompt.position = Vector2(350,520)
	_prompt.size = Vector2(580,54)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size",16)
	_prompt.add_theme_color_override("font_color",Color(0.97,0.94,0.86,0.96))
	_prompt.add_theme_color_override("font_shadow_color",Color(0,0,0,0.72))
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
	_prompt.text = "%s  •  LMB drag: squeeze / shake  •  RMB: inspect  •  Continue" % _model.get_feedback_text()

func _exit_tree() -> void:
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
