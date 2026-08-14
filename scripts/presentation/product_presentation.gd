extends Node3D
class_name ProductPresentation

var _active_kind := "paper_cup"

func get_active_kind() -> String:
	return _active_kind

func apply_profile(profile: Dictionary) -> void:
	var requested := String(profile.get("kind","paper_cup"))
	if requested not in ["paper_cup","amber_bottle","clear_bottle"]:
		requested = "paper_cup"
	_active_kind = requested
	for child in get_children():
		child.free()
	if requested == "amber_bottle":
		_build_bottle(profile,true)
	elif requested == "clear_bottle":
		_build_bottle(profile,false)
	else:
		_build_paper(profile)

func apply_to_base(body: MeshInstance3D, lid: MeshInstance3D, profile: Dictionary) -> void:
	if body == null:
		return
	var kind := String(profile.get("kind","paper_cup"))
	if kind in ["amber_bottle","clear_bottle"]:
		body.material_override = _glass_mat(
			Color(profile.get("body_color",Color(0.32,0.10,0.025) if kind=="amber_bottle" else Color(0.88,0.97,0.96))),
			float(profile.get("glass_alpha",0.58 if kind=="amber_bottle" else 0.22)),
			float(profile.get("roughness",0.07))
		)
	else:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(profile.get("body_color",Color(0.89,0.84,0.74)))
		mat.roughness = float(profile.get("roughness",0.90))
		mat.metallic = 0.0
		body.material_override = mat
	if lid != null:
		lid.visible = kind == "paper_cup"
		if lid.visible:
			var lid_mat := StandardMaterial3D.new()
			lid_mat.albedo_color = Color(profile.get("lid_color",Color(0.025,0.024,0.022)))
			lid_mat.roughness = 0.16
			lid_mat.metallic = 0.02
			lid.material_override = lid_mat

func set_inspection_yaw(yaw: float) -> void:
	rotation.y = yaw if is_finite(yaw) else 0.0

func _build_paper(profile: Dictionary) -> void:
	var root := Node3D.new()
	root.name = "CupPaperDetails"
	add_child(root)
	var body_color := Color(profile.get("body_color",Color(0.89,0.84,0.74)))
	_add_ring(root,"PaperBaseFold",Vector3(0,-0.655,0),0.457,0.020,body_color.darkened(0.055),0.93)
	_add_ring(root,"PaperLip",Vector3(0,0.735,0),0.556,0.025,body_color.lightened(0.025),0.74)
	var seam := MeshInstance3D.new()
	seam.name = "PaperSeam"
	var seam_mesh := BoxMesh.new()
	seam_mesh.size = Vector3(0.012,1.15,0.008)
	seam.mesh = seam_mesh
	seam.position = Vector3(0.0,0.02,-0.548)
	seam.material_override = _mat(body_color.darkened(0.055),0.96)
	root.add_child(seam)

func _build_bottle(profile: Dictionary, amber: bool) -> void:
	var body_color := Color(profile.get("body_color",Color(0.32,0.10,0.025) if amber else Color(0.88,0.97,0.96)))
	var neck_radius := float(profile.get("neck_radius",0.19))
	var glass_alpha := float(profile.get("glass_alpha",0.58 if amber else 0.22))
	var roughness := float(profile.get("roughness",0.07))

	var shoulder := MeshInstance3D.new()
	shoulder.name = "BottleShoulder"
	var shoulder_mesh := CylinderMesh.new()
	shoulder_mesh.bottom_radius = 0.43
	shoulder_mesh.top_radius = neck_radius
	shoulder_mesh.height = 0.38
	shoulder_mesh.radial_segments = 72
	shoulder.mesh = shoulder_mesh
	shoulder.position = Vector3(0,0.85,0)
	shoulder.material_override = _glass_mat(body_color,glass_alpha,roughness)
	add_child(shoulder)

	var neck := MeshInstance3D.new()
	neck.name = "BottleNeck"
	var neck_mesh := CylinderMesh.new()
	neck_mesh.top_radius = neck_radius
	neck_mesh.bottom_radius = neck_radius
	neck_mesh.height = 0.46
	neck_mesh.radial_segments = 64
	neck.mesh = neck_mesh
	neck.position = Vector3(0,1.27,0)
	neck.material_override = _glass_mat(body_color,glass_alpha,maxf(roughness-0.01,0.03))
	add_child(neck)

	_add_ring(self,"BottleLip",Vector3(0,1.515,0),neck_radius+0.028,0.052,body_color.lightened(0.05),0.06,glass_alpha+0.08)
	_add_ring(self,"BottleNeckRing",Vector3(0,1.445,0),neck_radius+0.016,0.024,body_color.lightened(0.03),0.07,glass_alpha+0.05)
	_add_ring(self,"BottleBaseRing",Vector3(0,-0.66,0),0.405,0.024,body_color.darkened(0.03),0.08,glass_alpha+0.08)

	# A second, slightly inset transparent layer creates believable optical depth
	# without the old rectangular guide stripes that looked like debug geometry.
	var inner_shell := MeshInstance3D.new()
	inner_shell.name = "BottleInnerGlass"
	var inner_mesh := CylinderMesh.new()
	inner_mesh.top_radius = 0.385
	inner_mesh.bottom_radius = 0.355
	inner_mesh.height = 1.22
	inner_mesh.radial_segments = 64
	inner_mesh.cap_top = false
	inner_shell.mesh = inner_mesh
	inner_shell.position = Vector3(0,-0.04,0)
	inner_shell.material_override = _glass_mat(body_color.lightened(0.06),glass_alpha*0.24,0.035)
	add_child(inner_shell)

	var liquid := MeshInstance3D.new()
	liquid.name = "BottleLiquid"
	var liquid_mesh := CylinderMesh.new()
	liquid_mesh.top_radius = 0.365
	liquid_mesh.bottom_radius = 0.345
	liquid_mesh.height = 1.02 if amber else 1.06
	liquid_mesh.radial_segments = 64
	liquid.mesh = liquid_mesh
	liquid.position = Vector3(0,-0.09 if amber else -0.07,0)
	var liquid_mat := StandardMaterial3D.new()
	liquid_mat.albedo_color = Color(0.50,0.17,0.025,0.62) if amber else Color(profile.get("liquid_color",Color(0.88,0.91,0.60,0.64)))
	liquid_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	liquid_mat.roughness = 0.12
	liquid_mat.metallic_specular = 0.62
	liquid.material_override = liquid_mat
	add_child(liquid)

	if not amber:
		for i in range(18):
			var angle := TAU*float((i*7)%18)/18.0
			var y := -0.44+float((i*11)%18)/18.0*1.27
			var bead := MeshInstance3D.new()
			bead.name = "Condensation"
			var sm := SphereMesh.new()
			sm.radius = 0.008+0.002*float(i%3)
			sm.height = sm.radius*2.0
			sm.radial_segments = 10
			sm.rings = 5
			bead.mesh = sm
			bead.position = Vector3(sin(angle)*0.414,y,cos(angle)*0.414)
			bead.material_override = _glass_mat(Color(0.94,0.99,1.0),0.30,0.025)
			add_child(bead)

func _add_ring(root: Node3D, node_name: String, at: Vector3, radius: float, height: float, color: Color, roughness: float, alpha := 1.0) -> void:
	var ring := MeshInstance3D.new()
	ring.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 72
	ring.mesh = mesh
	ring.position = at
	var mat := _mat(color,roughness)
	if alpha < 0.999:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = clampf(alpha,0.08,0.96)
		mat.rim_enabled = true
		mat.rim = 0.45
		mat.rim_tint = 0.30
	ring.material_override = mat
	root.add_child(ring)

func _mat(color: Color, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	return mat

func _glass_mat(color: Color, alpha: float, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.albedo_color.a = clampf(alpha,0.08,0.88)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = clampf(roughness,0.02,0.35)
	mat.metallic = 0.0
	mat.metallic_specular = 0.78
	mat.rim_enabled = true
	mat.rim = 0.58
	mat.rim_tint = 0.26
	mat.clearcoat_enabled = true
	mat.clearcoat = 0.62
	mat.clearcoat_roughness = 0.10
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat
