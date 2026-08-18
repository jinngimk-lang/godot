extends Node3D
class_name HandVisual

const RIGHT_ASSET_PATH := "res://assets/models/hands/hand_right.glb"
const LEFT_ASSET_PATH := "res://assets/models/hands/hand_left.glb"
const FINGER_NAMES := ["Thumb", "Index", "Middle", "Ring", "Little"]
const AUTHORED_PRESENTATION_SCALE := 2.25
const FINGER_RINGS := 72
const FINGER_SIDES := 40
const BODY_SEGMENTS := 36
const BODY_RINGS := 18

var follow_rate := 11.0
var pinch_follow_rate := 16.0

var _target := Vector3.ZERO
var _dynamic := false
var _mirror_sign := 1.0
var _pinch_target := 0.0
var _pinch_amount := 0.0
var _built := false
var _using_authored_asset := false
var _using_realtime_shell := false
var _last_authored_pose := ""
var _realtime_shell_vertex_budget := 0

var _authored_root: Node3D
var _animation_player: AnimationPlayer
var _skeleton: Skeleton3D
var _realtime_shell: Node3D

var _skin: StandardMaterial3D
var _nail: StandardMaterial3D
var _sleeve_fabric: StandardMaterial3D
var _sleeve_rib: StandardMaterial3D
var _thumb_tip: Node3D
var _index_tip: Node3D
var _pinch_point: Node3D

func setup(dynamic_hand: bool) -> void:
	_dynamic = dynamic_hand
	_mirror_sign = 1.0 if dynamic_hand else -1.0
	_ensure_anchors()
	if not _built:
		_using_authored_asset = _try_build_authored_hand()
		_build_realtime_hand_shell()
		if not _using_realtime_shell and not _using_authored_asset:
			_build_fallback_hand()
		_built = true
	_pinch_target = 0.18 if dynamic_hand else 0.42
	_pinch_amount = _pinch_target
	_apply_pose()
	_refresh_pinch_anchors()

func is_using_authored_asset() -> bool:
	return _using_authored_asset

func is_using_realtime_shell() -> bool:
	return _using_realtime_shell and _realtime_shell != null

func get_realtime_shell_vertex_count() -> int:
	return _realtime_shell_vertex_budget

func set_grip_target(target: Vector3) -> void:
	_target = target

func set_target(target: Vector3) -> void:
	set_grip_target(target)

func set_pinch_amount(amount: float) -> void:
	_pinch_target = clampf(amount if is_finite(amount) else 0.0,0.0,1.0)

func get_finger_count() -> int:
	return FINGER_NAMES.size()

func get_pinch_world_position() -> Vector3:
	if _pinch_point == null:
		return global_position
	return to_global(_pinch_point.position)

func snap_to(target: Vector3) -> void:
	position = target
	_refresh_pinch_anchors()
	_target = to_global(_pinch_point.position) if _pinch_point != null else target

func tick(delta: float) -> void:
	var safe_delta := clampf(delta if is_finite(delta) else 0.0,0.0,0.1)
	var pinch_weight := 1.0-exp(-pinch_follow_rate*safe_delta)
	_pinch_amount = lerpf(_pinch_amount,_pinch_target,pinch_weight)
	_apply_pose()
	_refresh_pinch_anchors()
	if _dynamic:
		var desired_root := _target
		if _pinch_point != null:
			desired_root = _target-basis*_pinch_point.position
		var weight := 1.0-exp(-follow_rate*safe_delta)
		position = position.lerp(desired_root,weight)

func _ensure_anchors() -> void:
	if _thumb_tip == null:
		_thumb_tip = Node3D.new()
		_thumb_tip.name = "ThumbTip"
		add_child(_thumb_tip)
	if _index_tip == null:
		_index_tip = Node3D.new()
		_index_tip.name = "IndexTip"
		add_child(_index_tip)
	if _pinch_point == null:
		_pinch_point = Node3D.new()
		_pinch_point.name = "PinchPoint"
		add_child(_pinch_point)

func _try_build_authored_hand() -> bool:
	var asset_path := RIGHT_ASSET_PATH if _dynamic else LEFT_ASSET_PATH
	if not ResourceLoader.exists(asset_path):
		return false
	var packed = load(asset_path)
	if packed == null or not (packed is PackedScene):
		return false
	var instance = packed.instantiate()
	if instance == null or not (instance is Node3D):
		if instance != null:
			instance.free()
		return false
	_authored_root = instance as Node3D
	_authored_root.name = "AuthoredHand"
	add_child(_authored_root)
	_animation_player = _find_animation_player(_authored_root)
	_skeleton = _find_skeleton(_authored_root)
	if _animation_player == null or _skeleton == null:
		remove_child(_authored_root)
		_authored_root.free()
		_authored_root = null
		_animation_player = null
		_skeleton = null
		return false
	var required_pose := "Pinch Up" if _dynamic else "Cup"
	if not _animation_player.has_animation(required_pose):
		remove_child(_authored_root)
		_authored_root.free()
		_authored_root = null
		_animation_player = null
		_skeleton = null
		return false
	_authored_root.position = Vector3.ZERO
	_authored_root.rotation = Vector3.ZERO
	_authored_root.scale = Vector3.ONE*AUTHORED_PRESENTATION_SCALE
	_build_authored_wrist_cover()
	_apply_authored_pose(required_pose)
	return true

func _build_authored_wrist_cover() -> void:
	if _authored_root == null:
		return
	_sleeve_fabric = StandardMaterial3D.new()
	_sleeve_fabric.resource_name = "SleeveFabric"
	_sleeve_fabric.albedo_color = Color(0.18,0.13,0.11,1.0)
	_sleeve_fabric.roughness = 0.98
	_sleeve_rib = StandardMaterial3D.new()
	_sleeve_rib.resource_name = "SleeveRib"
	_sleeve_rib.albedo_color = Color(0.32,0.25,0.21,1.0)
	_sleeve_rib.roughness = 0.97
	var sleeve := MeshInstance3D.new()
	sleeve.name = "WristSleeve"
	var sleeve_mesh := CylinderMesh.new()
	sleeve_mesh.bottom_radius = 0.034
	sleeve_mesh.top_radius = 0.048
	sleeve_mesh.height = 0.34
	sleeve_mesh.radial_segments = 28
	sleeve.mesh = sleeve_mesh
	sleeve.material_override = _sleeve_fabric
	sleeve.position = Vector3(0.0,0.0,0.19)
	sleeve.rotation_degrees = Vector3(90.0,0.0,0.0)
	sleeve.scale = Vector3(0.82,1.0,0.68)
	_authored_root.add_child(sleeve)
	var cuff := MeshInstance3D.new()
	cuff.name = "WristCuff"
	var cuff_mesh := CylinderMesh.new()
	cuff_mesh.top_radius = 0.037
	cuff_mesh.bottom_radius = 0.037
	cuff_mesh.height = 0.012
	cuff_mesh.radial_segments = 28
	cuff.mesh = cuff_mesh
	cuff.material_override = _sleeve_rib
	cuff.position = Vector3(0.0,0.0,0.028)
	cuff.rotation_degrees = Vector3(90.0,0.0,0.0)
	cuff.scale = Vector3(0.86,1.0,0.72)
	_authored_root.add_child(cuff)

func _build_realtime_hand_shell() -> void:
	_skin = StandardMaterial3D.new()
	_skin.resource_name = "RealtimeHandSkin"
	_skin.albedo_color = Color(0.72,0.50,0.38,1.0)
	_skin.roughness = 0.52
	_skin.metallic = 0.0
	_skin.metallic_specular = 0.34
	_nail = StandardMaterial3D.new()
	_nail.resource_name = "RealtimeHandNail"
	_nail.albedo_color = Color(0.86,0.67,0.59,1.0)
	_nail.roughness = 0.40
	_nail.metallic_specular = 0.40

	_realtime_shell = Node3D.new()
	_realtime_shell.name = "RealtimeHandShell"
	add_child(_realtime_shell)
	_realtime_shell_vertex_budget = 0

	# The final viewport hand is assembled from normal MeshInstance3D geometry,
	# never runtime boolean CSG. This keeps startup and every interaction frame
	# deterministic while retaining a dense smooth silhouette.
	_add_ellipsoid(_realtime_shell,Vector3(0.0,-0.090,0.0),Vector3(0.090,0.112,0.042),"Palm")
	_add_ellipsoid(_realtime_shell,_mirror(Vector3(0.047,-0.105,-0.003)),Vector3(0.052,0.071,0.043),"Thenar")
	_add_ellipsoid(_realtime_shell,_mirror(Vector3(-0.050,-0.108,0.004)),Vector3(0.045,0.070,0.039),"Hypothenar")
	_add_ellipsoid(_realtime_shell,Vector3(0.0,0.042,0.004),Vector3(0.046,0.080,0.037),"Wrist")

	var pose := _pinch_pose_points() if _dynamic else _support_pose_points()
	for finger_name in ["Index","Middle","Ring","Little","Thumb"]:
		var points: Array = pose[finger_name]
		var base_radius := _realtime_finger_radius(finger_name)
		_add_swept_finger(_realtime_shell,points,base_radius,base_radius*0.76,finger_name)
		_add_ellipsoid(_realtime_shell,points[points.size()-1],Vector3.ONE*base_radius*0.80,"%sTip" % finger_name)

	_build_nail("Index",pose["Index"][pose["Index"].size()-1],pose["Index"][pose["Index"].size()-2],_realtime_finger_radius("Index"))
	_build_nail("Thumb",pose["Thumb"][pose["Thumb"].size()-1],pose["Thumb"][pose["Thumb"].size()-2],_realtime_finger_radius("Thumb"))
	_using_realtime_shell = true
	_set_render_mesh_visibility(_authored_root,false)

func _add_ellipsoid(parent: Node, center: Vector3, extents: Vector3, node_name: String) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = BODY_SEGMENTS
	sphere.rings = BODY_RINGS
	mesh_instance.mesh = sphere
	mesh_instance.material_override = _skin
	mesh_instance.position = center
	mesh_instance.scale = extents
	parent.add_child(mesh_instance)
	_realtime_shell_vertex_budget += BODY_SEGMENTS*BODY_RINGS

func _add_swept_finger(parent: Node, points: Array, base_radius: float, tip_radius: float, node_name: String) -> void:
	if points.size() < 4:
		return
	var p0: Vector3 = points[0]
	var p1: Vector3 = points[1]
	var p2: Vector3 = points[2]
	var p3: Vector3 = points[3]
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for ring_index in range(FINGER_RINGS):
		var t := float(ring_index)/float(FINGER_RINGS-1)
		var point := _cubic_point(p0,p1,p2,p3,t)
		var tangent := _cubic_tangent(p0,p1,p2,p3,t).normalized()
		if tangent.length_squared() <= 0.000001:
			tangent = Vector3.DOWN
		var helper := Vector3.FORWARD
		if absf(tangent.dot(helper)) > 0.92:
			helper = Vector3.RIGHT
		var ring_x := helper.cross(tangent).normalized()
		var ring_y := tangent.cross(ring_x).normalized()
		var radius := lerpf(base_radius,tip_radius,smoothstep(0.0,1.0,t))
		# Slight oval section and subtle knuckle modulation keep the silhouette
		# anatomical without introducing segmented bead joints.
		var knuckle := 1.0+0.055*sin(PI*t)*sin(3.0*PI*t)
		for side_index in range(FINGER_SIDES):
			var u := float(side_index)/float(FINGER_SIDES)
			var angle := TAU*u
			var radial := ring_x*(cos(angle)*radius*knuckle)+ring_y*(sin(angle)*radius*0.90*knuckle)
			vertices.append(point+radial)
			normals.append(radial.normalized())
			uvs.append(Vector2(u,t))
	for ring_index in range(FINGER_RINGS-1):
		var current := ring_index*FINGER_SIDES
		var next := (ring_index+1)*FINGER_SIDES
		for side_index in range(FINGER_SIDES):
			var side_next := (side_index+1)%FINGER_SIDES
			var a := current+side_index
			var b := next+side_index
			var c := next+side_next
			var d := current+side_next
			indices.append(a); indices.append(b); indices.append(c)
			indices.append(a); indices.append(c); indices.append(d)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var instance := MeshInstance3D.new()
	instance.name = "%sContinuous" % node_name
	instance.mesh = mesh
	instance.material_override = _skin
	parent.add_child(instance)
	_realtime_shell_vertex_budget += vertices.size()

func _build_nail(node_name: String, tip: Vector3, previous: Vector3, radius: float) -> void:
	var nail := MeshInstance3D.new()
	nail.name = "%sNail" % node_name
	var mesh := SphereMesh.new()
	mesh.radius = radius*0.72
	mesh.height = radius*1.44
	mesh.radial_segments = 28
	mesh.rings = 14
	nail.mesh = mesh
	nail.material_override = _nail
	var direction := (tip-previous).normalized()
	nail.position = tip+Vector3(0.0,0.0,-radius*0.60)-direction*radius*0.12
	nail.scale = Vector3(0.72,0.92,0.16)
	add_child(nail)
	_realtime_shell_vertex_budget += 28*14

func _pinch_pose_points() -> Dictionary:
	return {
		"Index":[Vector3(0.046,-0.174,0.000),Vector3(0.050,-0.230,-0.028),Vector3(0.047,-0.260,-0.076),Vector3(0.048,-0.244,-0.108)],
		"Middle":[Vector3(0.012,-0.180,0.006),Vector3(0.014,-0.238,-0.010),Vector3(0.010,-0.266,-0.052),Vector3(0.002,-0.236,-0.090)],
		"Ring":[Vector3(-0.022,-0.176,0.010),Vector3(-0.026,-0.232,-0.004),Vector3(-0.032,-0.252,-0.044),Vector3(-0.036,-0.222,-0.078)],
		"Little":[Vector3(-0.055,-0.164,0.012),Vector3(-0.061,-0.212,-0.004),Vector3(-0.069,-0.230,-0.038),Vector3(-0.073,-0.206,-0.066)],
		"Thumb":[Vector3(0.070,-0.080,-0.004),Vector3(0.111,-0.130,-0.028),Vector3(0.102,-0.181,-0.070),Vector3(0.062,-0.224,-0.108)]
	}

func _support_pose_points() -> Dictionary:
	var source := {
		"Index":[Vector3(0.046,-0.174,0.002),Vector3(0.052,-0.234,-0.008),Vector3(0.050,-0.284,-0.034),Vector3(0.043,-0.303,-0.074)],
		"Middle":[Vector3(0.012,-0.180,0.007),Vector3(0.014,-0.246,-0.004),Vector3(0.010,-0.298,-0.032),Vector3(0.002,-0.314,-0.073)],
		"Ring":[Vector3(-0.022,-0.176,0.010),Vector3(-0.026,-0.238,-0.002),Vector3(-0.032,-0.288,-0.028),Vector3(-0.040,-0.302,-0.066)],
		"Little":[Vector3(-0.055,-0.164,0.012),Vector3(-0.061,-0.218,-0.002),Vector3(-0.070,-0.259,-0.026),Vector3(-0.078,-0.270,-0.058)],
		"Thumb":[Vector3(0.070,-0.080,-0.004),Vector3(0.116,-0.130,-0.010),Vector3(0.124,-0.176,-0.036),Vector3(0.110,-0.206,-0.070)]
	}
	var mirrored := {}
	for key in source.keys():
		var output: Array[Vector3] = []
		for point in source[key]:
			output.append(_mirror(point))
		mirrored[key] = output
	return mirrored

func _realtime_finger_radius(finger_name: String) -> float:
	match finger_name:
		"Thumb": return 0.024
		"Index": return 0.020
		"Middle": return 0.0215
		"Ring": return 0.0205
		_: return 0.0175

func _apply_pose() -> void:
	if _using_authored_asset:
		var pose_name := "Cup" if not _dynamic else ("Pinch Tight" if _pinch_amount >= 0.42 else "Pinch Up")
		if _animation_player != null and not _animation_player.has_animation(pose_name):
			pose_name = "Pinch Up" if _dynamic else "Default pose"
		_apply_authored_pose(pose_name)

func _apply_authored_pose(pose_name: String) -> void:
	if _animation_player == null or not _animation_player.has_animation(pose_name):
		return
	if _last_authored_pose == pose_name:
		return
	_animation_player.play(pose_name)
	_animation_player.seek(0.0,true)
	_animation_player.pause()
	_last_authored_pose = pose_name

func _refresh_pinch_anchors() -> void:
	if _using_realtime_shell:
		_refresh_realtime_anchors()
	elif _using_authored_asset:
		_refresh_authored_anchors()

func _refresh_realtime_anchors() -> void:
	if _dynamic:
		_index_tip.position = Vector3(0.048,-0.244,-0.108)
		_thumb_tip.position = Vector3(0.062,-0.224,-0.108)
	else:
		_index_tip.position = Vector3(-0.043,-0.303,-0.074)
		_thumb_tip.position = Vector3(-0.110,-0.206,-0.070)
	_pinch_point.position = (_index_tip.position+_thumb_tip.position)*0.5

func _refresh_authored_anchors() -> void:
	if _skeleton == null:
		return
	var suffix := "R" if _dynamic else "L"
	var thumb_local = _estimate_bone_tip("Thumb_Proximal_%s" % suffix,"Thumb_Distal_%s" % suffix,0.020)
	var index_local = _estimate_bone_tip("Index_Intermediate_%s" % suffix,"Index_Distal_%s" % suffix,0.020)
	if thumb_local != null:
		_thumb_tip.position = thumb_local as Vector3
	if index_local != null:
		_index_tip.position = index_local as Vector3
	if thumb_local != null and index_local != null:
		_pinch_point.position = ((thumb_local as Vector3)+(index_local as Vector3))*0.5

func _estimate_bone_tip(previous_name: String, distal_name: String, extension: float):
	if _skeleton == null:
		return null
	var previous_id := _skeleton.find_bone(previous_name)
	var distal_id := _skeleton.find_bone(distal_name)
	if previous_id < 0 or distal_id < 0:
		return null
	var previous_pose := _skeleton.get_bone_global_pose(previous_id)
	var distal_pose := _skeleton.get_bone_global_pose(distal_id)
	var direction := distal_pose.origin-previous_pose.origin
	if direction.length_squared() <= 0.000001:
		return null
	return _descendant_point_to_local(_skeleton,distal_pose.origin+direction.normalized()*extension)

func _descendant_point_to_local(descendant: Node3D, point: Vector3):
	var current := descendant
	var converted := point
	while current != self:
		if current.is_set_as_top_level():
			return null
		converted = current.transform*converted
		var parent := current.get_parent()
		if not (parent is Node3D):
			return null
		current = parent as Node3D
	return converted

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null

func _set_render_mesh_visibility(node: Node, visible: bool) -> void:
	if node == null:
		return
	if node is MeshInstance3D:
		(node as MeshInstance3D).visible = visible
	for child in node.get_children():
		_set_render_mesh_visibility(child,visible)

func _build_fallback_hand() -> void:
	var fallback := MeshInstance3D.new()
	fallback.name = "FallbackPalm"
	var mesh := SphereMesh.new()
	mesh.radius = 0.10
	mesh.height = 0.22
	mesh.radial_segments = 28
	mesh.rings = 14
	fallback.mesh = mesh
	fallback.material_override = _skin
	fallback.scale = Vector3(0.90,1.15,0.42)
	fallback.position = Vector3(0.0,-0.09,0.0)
	add_child(fallback)

func _cubic_point(a: Vector3,b: Vector3,c: Vector3,d: Vector3,t: float) -> Vector3:
	var inv := 1.0-t
	return a*inv*inv*inv+b*3.0*inv*inv*t+c*3.0*inv*t*t+d*t*t*t

func _cubic_tangent(a: Vector3,b: Vector3,c: Vector3,d: Vector3,t: float) -> Vector3:
	var inv := 1.0-t
	return (b-a)*3.0*inv*inv+(c-b)*6.0*inv*t+(d-c)*3.0*t*t

func _mirror(point: Vector3) -> Vector3:
	return Vector3(point.x*_mirror_sign,point.y,point.z)
