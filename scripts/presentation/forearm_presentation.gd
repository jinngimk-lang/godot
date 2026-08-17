extends Node3D
class_name ForearmPresentation

const CURVE_RINGS := 36
const RING_SIDES := 32
const AUTHORED_HAND_SCALE := 4.15
const AUTHORED_WRIST_END_Z := 0.026
const WRIST_OVERLAP_AUTHORED := 0.012
const SLEEVE_FABRIC_SHADER := """shader_type spatial;
render_mode cull_back;
uniform vec4 cloth_color : source_color = vec4(0.145, 0.142, 0.138, 1.0);
uniform float weave_strength = 0.014;

void fragment() {
	float warp = sin(UV.x * 92.0 * 6.2831853);
	float weft = sin(UV.y * 128.0 * 6.2831853);
	float weave = warp * weft;
	float long_fold = sin(UV.y * 13.0 + sin(UV.x * 6.2831853) * 0.45);
	ALBEDO = clamp(cloth_color.rgb + vec3(long_fold * 0.003), vec3(0.0), vec3(1.0));
	ROUGHNESS = clamp(0.955 + abs(weave) * weave_strength, 0.94, 0.99);
	SPECULAR = 0.09;
}
"""

var _applied := false
var _forearms: Dictionary = {}
var _cloth_materials: Dictionary = {}
var _skin_materials: Dictionary = {}
var _last_venue := ""
var _cup: MeshInstance3D

func _ready() -> void:
	call_deferred("_apply")

func _process(_delta: float) -> void:
	if not _applied:
		return
	var venue_id := _active_venue_id()
	if venue_id != _last_venue:
		_last_venue = venue_id
		_apply_venue_materials(venue_id)

func _apply() -> void:
	if _applied:
		return
	var parent := get_parent()
	if parent == null:
		return
	_cup = parent.get_node_or_null("Cup") as MeshInstance3D
	_scale_hand_preserve_pinch(parent.get_node_or_null("RightHand") as HandVisual)
	_scale_hand_preserve_pinch(parent.get_node_or_null("LeftHand") as HandVisual)
	_build_for_hand("RightHand",true)
	_build_for_hand("LeftHand",false)
	_applied = true
	_last_venue = ""

func _scale_hand_preserve_pinch(hand: HandVisual) -> void:
	if hand == null:
		return
	var authored := hand.get_node_or_null("AuthoredHand") as Node3D
	if authored == null:
		return
	var old_pinch := hand.get_pinch_world_position()
	authored.scale = Vector3.ONE*AUTHORED_HAND_SCALE
	hand.snap_to(hand.position)
	var new_pinch := hand.get_pinch_world_position()
	hand.position += old_pinch-new_pinch
	hand.set_grip_target(old_pinch)

func _build_for_hand(hand_name: String, dynamic_hand: bool) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var hand := parent.get_node_or_null(hand_name) as Node3D
	if hand == null:
		return
	var authored := hand.get_node_or_null("AuthoredHand") as Node3D
	if authored == null:
		return
	var legacy_sleeve := authored.find_child("WristSleeve",true,false) as MeshInstance3D
	var legacy_cuff := authored.find_child("WristCuff",true,false) as MeshInstance3D
	if legacy_sleeve == null:
		return
	legacy_sleeve.visible = false
	if legacy_cuff != null:
		legacy_cuff.visible = false

	var cloth := _make_cafe_cloth()
	var skin: Material = _find_material(authored,"HandSkin") as Material
	if skin == null:
		var fallback_skin := StandardMaterial3D.new()
		fallback_skin.resource_name = "HandSkin"
		fallback_skin.albedo_color = Color(0.64,0.41,0.30,1.0)
		fallback_skin.roughness = 0.80
		skin = fallback_skin
	elif skin is StandardMaterial3D:
		# Re-use the actual imported hand material so the forearm/hand join stays
		# continuous, but calibrate the XR asset away from the prototype pink read.
		var skin_mat := skin as StandardMaterial3D
		skin_mat.albedo_color = Color(0.66,0.43,0.31,1.0)
		skin_mat.roughness = 0.78
		skin_mat.metallic = 0.0
		skin_mat.metallic_specular = 0.46

	# The imported XR hand ends around authored local +Z=0.026. Start the bridge
	# deliberately inside that surface rather than butt-joining at the boundary;
	# the overlap plus an open wrist end prevents a visible circular cap/seam.
	var wrist_start_z := AUTHORED_WRIST_END_Z-WRIST_OVERLAP_AUTHORED
	var start: Vector3 = _descendant_point_to_ancestor(authored,hand,Vector3(0.0,0.0,wrist_start_z))
	if not _finite_vector(start):
		return
	var start_world := hand.to_global(start)
	var cup_world := _cup.global_position if _cup != null else Vector3.ZERO
	var outward_sign := -1.0 if start_world.x<cup_world.x else 1.0
	if absf(start_world.x-cup_world.x)<0.05:
		outward_sign = -1.0 if dynamic_hand else 1.0

	# Use a cubic path with two deliberate anatomical phases: a short wrist-to-
	# forearm tangent that drops toward the table, then a broader elbow/exit arc.
	# The old single-control quadratic only changed tangent by ~12 degrees and
	# still read as a straight beam after the radius was fixed.
	var offsets := _path_offsets(outward_sign)
	var control_a_world := start_world+(offsets[0] as Vector3)
	var control_b_world := start_world+(offsets[1] as Vector3)
	var end_world := start_world+(offsets[2] as Vector3)
	var control_a := hand.to_local(control_a_world)
	var control_b := hand.to_local(control_b_world)
	var end := hand.to_local(end_world)

	var forearm := MeshInstance3D.new()
	forearm.name = "ForearmNatural"
	forearm.mesh = _build_curve_mesh(start,control_a,control_b,end)
	forearm.material_override = cloth
	forearm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	hand.add_child(forearm)
	_forearms[hand_name] = forearm
	_cloth_materials[hand_name] = cloth
	_skin_materials[hand_name] = skin

func _wrist_overlap_authored() -> float:
	return WRIST_OVERLAP_AUTHORED

func _path_offsets(outward_sign: float) -> Array[Vector3]:
	var sign_value := -1.0 if outward_sign < 0.0 else 1.0
	return [
		Vector3(sign_value*0.55,-0.50,0.20),
		Vector3(sign_value*2.20,-1.08,0.48),
		Vector3(sign_value*4.90,-1.28,0.66),
	]

func _path_tangent_deflection_degrees(outward_sign: float) -> float:
	var offsets := _path_offsets(outward_sign)
	var start_tangent := offsets[0] as Vector3
	var end_tangent := (offsets[2] as Vector3)-(offsets[1] as Vector3)
	if start_tangent.length_squared()<=0.000001 or end_tangent.length_squared()<=0.000001:
		return 0.0
	var cosine := clampf(start_tangent.normalized().dot(end_tangent.normalized()),-1.0,1.0)
	return rad_to_deg(acos(cosine))

func _make_cafe_cloth() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = SLEEVE_FABRIC_SHADER
	var material := ShaderMaterial.new()
	material.resource_name = "SleeveFabric"
	material.shader = shader
	material.set_shader_parameter("cloth_color",Color(0.145,0.142,0.138,1.0))
	material.set_shader_parameter("weave_strength",0.014)
	return material

func _build_curve_mesh(start: Vector3, control_a: Vector3, control_b: Vector3, end: Vector3) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for ring_index in range(CURVE_RINGS):
		var t := float(ring_index)/float(CURVE_RINGS-1)
		var point := _cubic_point(start,control_a,control_b,end,t)
		var tangent := _cubic_tangent(start,control_a,control_b,end,t).normalized()
		if tangent.length_squared()<=0.000001:
			tangent = Vector3.FORWARD
		var helper := Vector3.UP
		if absf(tangent.dot(helper))>0.94:
			helper = Vector3.RIGHT
		var ring_x := helper.cross(tangent).normalized()
		var ring_y := tangent.cross(ring_x).normalized()
		for side_index in range(RING_SIDES):
			var angle := TAU*float(side_index)/float(RING_SIDES)
			var cross_section := _sleeve_cross_section(t,angle)
			var radial := ring_x*cross_section.x+ring_y*cross_section.y
			vertices.append(point+radial)
			var delta_angle := TAU/float(RING_SIDES)*0.35
			var before := _sleeve_cross_section(t,angle-delta_angle)
			var after := _sleeve_cross_section(t,angle+delta_angle)
			var cross_tangent := ring_x*(after.x-before.x)+ring_y*(after.y-before.y)
			var normal := cross_tangent.cross(tangent).normalized()
			if normal.dot(radial)<0.0:
				normal = -normal
			normals.append(normal)
			uvs.append(Vector2(float(side_index)/float(RING_SIDES),t))
	for ring_index in range(CURVE_RINGS-1):
		var current := ring_index*RING_SIDES
		var next := (ring_index+1)*RING_SIDES
		for side_index in range(RING_SIDES):
			var side_next := (side_index+1)%RING_SIDES
			var a := current+side_index
			var b := next+side_index
			var c := next+side_next
			var d := current+side_next
			indices.append(a); indices.append(b); indices.append(c)
			indices.append(a); indices.append(c); indices.append(d)
	# Leave the wrist end open because it is embedded under the authored hand.
	# Only the far/off-frame end is capped, avoiding a dark butt-cap at the seam.
	var end_center := vertices.size()
	vertices.append(end)
	normals.append(_cubic_tangent(start,control_a,control_b,end,1.0).normalized())
	uvs.append(Vector2(0.5,1.0))
	var end_ring := (CURVE_RINGS-1)*RING_SIDES
	for side_index in range(RING_SIDES):
		var side_next := (side_index+1)%RING_SIDES
		indices.append(end_center); indices.append(end_ring+side_index); indices.append(end_ring+side_next)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh

func _sleeve_cross_section(t: float, angle: float) -> Vector2:
	var p := clampf(t,0.0,1.0)
	var radius := _radius_profile(p)
	var vertical_ratio := lerpf(0.58,0.66,p)
	# A restrained deterministic multi-lobe modulation breaks the hose-like
	# extrusion without making a visible star edge at the 720p acceptance scale.
	var fold := 1.0+0.030*sin(angle*3.0+p*1.7)+0.018*cos(angle*5.0-p*1.15)
	var vertical_fold := 1.0+0.015*sin(angle*2.0-p*2.2)
	return Vector2(cos(angle)*radius*fold,sin(angle)*radius*vertical_ratio*fold*vertical_fold)

func _radius_profile(t: float) -> float:
	# The reference sleeve stays subordinate to hand/paper contact. Broaden only
	# toward the crop edge; a slimmer 0.112→0.168 bridge reduces the old tube band.
	var p := clampf(t,0.0,1.0)
	var base := lerpf(0.112,0.168,smoothstep(0.0,1.0,p))
	return base*(1.0+0.025*sin(p*PI))

func _active_venue_id() -> String:
	var parent := get_parent()
	if parent == null:
		return "cafe_window"
	var venue := parent.get_node_or_null("VenuePresentation")
	if venue != null and venue.has_method("get_active_profile_id"):
		return String(venue.call("get_active_profile_id"))
	return "cafe_window"

func _apply_venue_materials(venue_id: String) -> void:
	var use_cloth := venue_id=="cafe_window"
	for hand_name in _forearms.keys():
		var forearm := _forearms[hand_name] as MeshInstance3D
		if forearm == null:
			continue
		forearm.material_override = (_cloth_materials.get(hand_name) as Material) if use_cloth else (_skin_materials.get(hand_name) as Material)

func _find_material(node: Node, wanted_name: String):
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.material_override != null and mesh_instance.material_override.resource_name==wanted_name:
			return mesh_instance.material_override
		var mesh := mesh_instance.mesh
		if mesh != null:
			for surface_index in range(mesh.get_surface_count()):
				var material := mesh.surface_get_material(surface_index)
				if material != null and material.resource_name==wanted_name:
					return material
	for child in node.get_children():
		var found = _find_material(child,wanted_name)
		if found != null:
			return found
	return null

func _cubic_point(start: Vector3, control_a: Vector3, control_b: Vector3, end: Vector3, t: float) -> Vector3:
	var one_minus := 1.0-t
	return start*one_minus*one_minus*one_minus+control_a*3.0*one_minus*one_minus*t+control_b*3.0*one_minus*t*t+end*t*t*t

func _cubic_tangent(start: Vector3, control_a: Vector3, control_b: Vector3, end: Vector3, t: float) -> Vector3:
	var one_minus := 1.0-t
	return (control_a-start)*(3.0*one_minus*one_minus)+(control_b-control_a)*(6.0*one_minus*t)+(end-control_b)*(3.0*t*t)

func _descendant_point_to_ancestor(descendant: Node3D, ancestor: Node3D, point: Vector3) -> Vector3:
	var current := descendant
	var converted := point
	while current!=ancestor:
		if current.is_set_as_top_level():
			return Vector3(INF,INF,INF)
		converted = current.transform*converted
		var parent := current.get_parent()
		if not (parent is Node3D):
			return Vector3(INF,INF,INF)
		current = parent as Node3D
	return converted

func _finite_vector(value: Vector3) -> bool:
	return is_finite(value.x) and is_finite(value.y) and is_finite(value.z)