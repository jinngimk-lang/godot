extends Node3D
class_name CupContentsPresentation

const MAX_CONTENT_COUNT := 5
const MIN_CUBE_SIZE := 0.07
const MAX_CUBE_SIZE := 0.16

var _cup: MeshInstance3D
var _container: Node3D
var _profile: Dictionary = {}
var _base_transforms: Array[Transform3D] = []
var _cube_size := 0.115
var _motion_gain := 0.0
var _progress := 0.0
var _side := -1
var _pulse := 0.0

func _ready() -> void:
	_bind_cup()
	_ensure_container()

func set_profile(profile: Dictionary) -> void:
	_profile = profile.duplicate(true)
	_bind_cup()
	_ensure_container()
	_progress = 0.0
	_pulse = 0.0
	_rebuild_contents()

func set_crumple(progress: float, side: int, pulse: float) -> void:
	_progress = clampf(progress if is_finite(progress) else 0.0, 0.0, 1.0)
	_side = -1 if side < 0 else 1
	_pulse = clampf(pulse if is_finite(pulse) else 0.0, 0.0, 1.0)
	_apply_motion()

func reset_visual() -> void:
	_progress = 0.0
	_pulse = 0.0
	_restore_base_transforms()

func get_content_count() -> int:
	return _container.get_child_count() if _container != null else 0

func _bind_cup() -> void:
	if _cup != null and is_instance_valid(_cup):
		return
	var parent := get_parent()
	if parent == null:
		return
	_cup = parent.get_node_or_null("Cup") as MeshInstance3D
	if _cup == null or not (_cup.mesh is CylinderMesh):
		_cup = null

func _ensure_container() -> void:
	if _container == null:
		_container = get_node_or_null("IceContents") as Node3D
	if _container == null:
		_container = Node3D.new()
		_container.name = "IceContents"
		add_child(_container)
	_sync_container_to_cup()

func _sync_container_to_cup() -> void:
	if _container == null:
		return
	if _cup == null:
		_bind_cup()
	if _cup != null:
		_container.global_transform = _cup.global_transform

func _rebuild_contents() -> void:
	_clear_contents()
	if _container == null:
		return
	_sync_container_to_cup()

	var contents: Dictionary = _profile.get("contents_profile", {})
	var content_type := String(contents.get("type", "none"))
	_sync_open_top_for_contents(content_type == "ice")
	if content_type != "ice":
		return

	var count := clampi(int(contents.get("count", 0)), 0, MAX_CONTENT_COUNT)
	_cube_size = clampf(float(contents.get("cube_size", 0.115)), MIN_CUBE_SIZE, MAX_CUBE_SIZE)
	_motion_gain = clampf(float(contents.get("motion_gain", 0.0)), 0.0, 1.0)
	if count <= 0:
		return

	for index in range(count):
		var cube := MeshInstance3D.new()
		cube.name = "Ice%02d" % (index + 1)
		var mesh := BoxMesh.new()
		mesh.size = Vector3.ONE * _cube_size
		cube.mesh = mesh
		cube.material_override = _ice_material(index)
		cube.transform = _base_transform_for(index, count)
		_container.add_child(cube)
		_base_transforms.append(cube.transform)

func _clear_contents() -> void:
	_base_transforms.clear()
	if _container == null:
		return
	for child in _container.get_children():
		_container.remove_child(child)
		child.queue_free()

func _sync_open_top_for_contents(has_ice: bool) -> void:
	if _cup == null:
		_bind_cup()
	var paper_shell := String(_profile.get("cup_shell", "paper")) == "paper"
	if _cup != null and _cup.mesh is CylinderMesh:
		# Paper cups own a real top cap only while closed. Bottle profiles continue
		# into a procedural shoulder/neck, so a cylinder cap would create a false
		# internal disk visible through glass.
		(_cup.mesh as CylinderMesh).cap_top = paper_shell and not has_ice
	var parent := get_parent()
	if parent == null:
		return
	var show_paper_lid := paper_shell and not has_ice
	var lid := parent.get_node_or_null("Lid") as MeshInstance3D
	if lid != null:
		lid.visible = show_paper_lid
	var cafe := parent.get_node_or_null("CafePresentation") as Node3D
	if cafe != null:
		for node_name in ["LidInset", "LidCenter"]:
			var detail := cafe.get_node_or_null(node_name) as MeshInstance3D
			if detail != null:
				detail.visible = show_paper_lid

func _base_transform_for(index: int, count: int) -> Transform3D:
	var dims := _dimensions()
	if _is_glass_cluster():
		return _glass_cluster_transform(index, count, dims)

	var inner_radius := _inner_radius(dims)
	var denominator := maxf(float(count - 1) * 0.5, 1.0)
	var spread := (float(index) - float(count - 1) * 0.5) / denominator
	# Paper-cup reward ice remains biased into the camera-readable back half and
	# close to the rim. Glass bottles use a different body-cluster layout below.
	var x := spread * inner_radius * 0.48
	var z := -inner_radius * (0.20 + 0.08 * float(index % 2))
	var top_limit := _content_top_limit(dims)
	var y := top_limit - _cube_size * 0.04 * float(index % 2)
	var position := _clamp_position(Vector3(x, y, z), dims)
	var rotation := Vector3(
		0.10 + 0.08 * float(index),
		-0.18 * spread,
		0.08 * spread
	)
	return Transform3D(Basis.from_euler(rotation), position)

func _glass_cluster_transform(index: int, count: int, dims: Vector3) -> Transform3D:
	var inner_radius := _inner_radius(dims)
	var top_limit := _content_top_limit(dims)
	# Three deliberately staggered chunks form a small triangular cluster in the
	# bottle body. Screen-space X/Y separation matters more than packing density:
	# the previous near-coplanar row collapsed into one cyan rectangle through
	# the transparent bottle shell.
	var presets := [
		Vector3(-0.50, -0.78, -0.12),
		Vector3(0.00, -0.12, -0.40),
		Vector3(0.50, -0.62, 0.12)
	]
	var rotations := [
		Vector3(0.34, -0.28, -0.20),
		Vector3(-0.22, 0.38, 0.26),
		Vector3(0.27, 0.18, -0.34)
	]
	if index < presets.size():
		var preset: Vector3 = presets[index]
		var position := Vector3(
			preset.x * inner_radius,
			top_limit + preset.y * _cube_size,
			preset.z * inner_radius
		)
		return Transform3D(Basis.from_euler(rotations[index]), _clamp_position(position, dims))

	# Defensive fallback if a future profile asks for more than the current three
	# authored bottle chunks: keep extra pieces distributed in a lower helix.
	var denominator := maxf(float(count - 1), 1.0)
	var t := float(index) / denominator
	var angle := TAU * (t + 0.13)
	var position := Vector3(
		cos(angle) * inner_radius * 0.48,
		top_limit - _cube_size * (0.30 + 0.62 * t),
		sin(angle) * inner_radius * 0.42
	)
	return Transform3D(Basis.from_euler(Vector3(0.24 + 0.11 * t, angle * 0.35, -0.20 + 0.18 * t)), _clamp_position(position, dims))

func _apply_motion() -> void:
	if _container == null or _base_transforms.is_empty():
		return
	var dims := _dimensions()
	var amplitude := _cube_size * 0.25 * _motion_gain * (0.35 * _progress + 0.65 * _pulse)
	for index in range(mini(_base_transforms.size(), _container.get_child_count())):
		var child := _container.get_child(index) as MeshInstance3D
		if child == null:
			continue
		var base := _base_transforms[index]
		var phase := float(index + 1) * 1.71 + _progress * 2.2
		var offset := Vector3(
			float(_side) * cos(phase) * amplitude,
			sin(phase * 1.37) * amplitude * 0.45,
			sin(phase) * amplitude * 0.72
		)
		var position := _clamp_position(base.origin + offset, dims)
		var extra_rotation := Vector3(
			amplitude * 2.1 * sin(phase),
			amplitude * 1.6 * float(_side),
			amplitude * 2.0 * cos(phase)
		)
		child.transform = Transform3D(base.basis * Basis.from_euler(extra_rotation), position)

func _restore_base_transforms() -> void:
	if _container == null:
		return
	for index in range(mini(_base_transforms.size(), _container.get_child_count())):
		var child := _container.get_child(index) as MeshInstance3D
		if child != null:
			child.transform = _base_transforms[index]

func _dimensions() -> Vector3:
	var configured: Dictionary = _profile.get("cup_dimensions", {})
	var bottom := maxf(float(configured.get("bottom_radius", 0.45)), 0.05)
	var top := maxf(float(configured.get("top_radius", 0.54)), bottom)
	var height := maxf(float(configured.get("height", 1.48)), 0.20)
	if _cup != null and _cup.mesh is CylinderMesh and configured.is_empty():
		var cup_mesh := _cup.mesh as CylinderMesh
		bottom = maxf(cup_mesh.bottom_radius, 0.05)
		top = maxf(cup_mesh.top_radius, bottom)
		height = maxf(cup_mesh.height, 0.20)
	return Vector3(bottom, top, height)

func _inner_radius(dims: Vector3) -> float:
	return maxf(minf(dims.x, dims.y) - _cube_size * 0.60, 0.01)

func _content_top_limit(dims: Vector3) -> float:
	var bottom_limit := -dims.z * 0.5 + _cube_size * 0.75
	var default_top := dims.z * 0.5 - _cube_size * 0.10
	var contents: Dictionary = _profile.get("contents_profile", {})
	var configured := float(contents.get("max_center_y", default_top))
	if not is_finite(configured):
		return default_top
	return clampf(configured, bottom_limit, default_top)

func _clamp_position(position: Vector3, dims: Vector3) -> Vector3:
	var inner_radius := _inner_radius(dims)
	var radial := Vector2(position.x, position.z)
	if radial.length() > inner_radius:
		radial = radial.normalized() * inner_radius
	var bottom_limit := -dims.z * 0.5 + _cube_size * 0.75
	var top_limit := _content_top_limit(dims)
	return Vector3(radial.x, clampf(position.y, bottom_limit, top_limit), radial.y)

func _is_glass_cluster() -> bool:
	var contents: Dictionary = _profile.get("contents_profile", {})
	return String(contents.get("layout", "")) == "glass_cluster"

func _ice_material(index: int) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	if _is_glass_cluster():
		# Near-neutral translucent ice survives the nested transparent bottle better
		# than the old saturated opaque blue while still keeping readable edges.
		var lift := 0.012 * float(index % 3)
		material.albedo_color = Color(0.87 + lift, 0.93 + lift * 0.45, 0.97, 0.52)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.roughness = 0.13
		material.metallic = 0.0
		material.metallic_specular = 0.72
		material.rim_enabled = true
		material.rim = 0.48
		material.rim_tint = 0.34
		material.clearcoat_enabled = true
		material.clearcoat = 0.62
		material.clearcoat_roughness = 0.08
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		return material

	var lift := 0.025 * float(index % 3)
	material.albedo_color = Color(0.76 + lift, 0.90 + lift * 0.5, 0.96, 1.0)
	material.roughness = 0.28
	return material
