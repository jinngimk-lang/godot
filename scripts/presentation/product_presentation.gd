extends Node3D
class_name ProductPresentation

var _active_kind := "paper_cup"

func get_active_kind() -> String:
	return _active_kind

func apply_profile(profile: Dictionary) -> void:
	var requested := String(profile.get("kind", "paper_cup"))
	if requested not in ["paper_cup","amber_bottle","clear_bottle"]:
		requested = "paper_cup"
	_active_kind = requested
	for child in get_children():
		child.free()
	if requested == "amber_bottle":
		_build_bottle(profile, true)
	elif requested == "clear_bottle":
		_build_bottle(profile, false)
	else:
		_build_paper(profile)

func apply_to_base(body: MeshInstance3D, lid: MeshInstance3D, profile: Dictionary) -> void:
	if body == null:
		return
	var kind := String(profile.get("kind", "paper_cup"))
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(profile.get("body_color", Color(0.89,0.84,0.74)))
	mat.roughness = float(profile.get("roughness", 0.86))
	if kind in ["amber_bottle","clear_bottle"]:
		mat.metallic = 0.02
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = float(profile.get("glass_alpha", 0.72 if kind == "amber_bottle" else 0.38))
		mat.roughness = float(profile.get("roughness", 0.14))
	body.material_override = mat
	if lid != null:
		lid.visible = kind == "paper_cup"
		if lid.visible:
			var lid_mat := StandardMaterial3D.new()
			lid_mat.albedo_color = Color(profile.get("lid_color", Color(0.035,0.032,0.030)))
			lid_mat.roughness = 0.22
			lid.material_override = lid_mat

func set_inspection_yaw(yaw: float) -> void:
	rotation.y = yaw if is_finite(yaw) else 0.0

func _build_paper(profile: Dictionary) -> void:
	var root := Node3D.new()
	root.name = "CupPaperDetails"
	add_child(root)
	var body_color := Color(profile.get("body_color", Color(0.89,0.84,0.74)))
	_add_ring(root,"PaperBaseFold",Vector3(0,-0.655,0),0.455,0.438,0.022,body_color.darkened(0.08),0.92)
	_add_ring(root,"PaperLip",Vector3(0,0.735,0),0.555,0.535,0.030,body_color.lightened(0.035),0.78)
	var seam := MeshInstance3D.new()
	seam.name = "PaperSeam"
	var seam_mesh := BoxMesh.new()
	seam_mesh.size = Vector3(0.016,1.18,0.010)
	seam.mesh = seam_mesh
	seam.position = Vector3(0.0,0.02,0.548)
	seam.material_override = _mat(body_color.darkened(0.10),0.94)
	root.add_child(seam)
	# Fine horizontal bands catch warm grazing light without texture assets.
	for i in range(7):
		_add_ring(root,"PaperFiberBand",Vector3(0,-0.46+i*0.16,0),0.505+i*0.010,0.500+i*0.010,0.003,body_color.lightened(0.012 if i%2==0 else 0.0),0.96)

func _build_bottle(profile: Dictionary, amber: bool) -> void:
	var body_color := Color(profile.get("body_color", Color(0.20,0.065,0.018) if amber else Color(0.86,0.95,0.94)))
	var neck_radius := float(profile.get("neck_radius", 0.21))
	var glass_alpha := float(profile.get("glass_alpha", 0.72 if amber else 0.36))
	var shoulder := MeshInstance3D.new()
	shoulder.name = "BottleShoulder"
	var shoulder_mesh := CylinderMesh.new()
	shoulder_mesh.bottom_radius = 0.43
	shoulder_mesh.top_radius = neck_radius
	shoulder_mesh.height = 0.36
	shoulder_mesh.radial_segments = 48
	shoulder.mesh = shoulder_mesh
	shoulder.position = Vector3(0,0.84,0)
	shoulder.material_override = _glass_mat(body_color,glass_alpha,float(profile.get("roughness",0.14)))
	add_child(shoulder)

	var neck := MeshInstance3D.new()
	neck.name = "BottleNeck"
	var neck_mesh := CylinderMesh.new()
	neck_mesh.top_radius = neck_radius
	neck_mesh.bottom_radius = neck_radius
	neck_mesh.height = 0.48
	neck_mesh.radial_segments = 40
	neck.mesh = neck_mesh
	neck.position = Vector3(0,1.22,0)
	neck.material_override = _glass_mat(body_color,glass_alpha,float(profile.get("roughness",0.12)))
	add_child(neck)

	_add_ring(self,"BottleLip",Vector3(0,1.475,0),neck_radius+0.025,neck_radius-0.006,0.065,body_color,0.12,glass_alpha)
	_add_ring(self,"BottleBaseRing",Vector3(0,-0.66,0),0.435,0.418,0.025,body_color.darkened(0.08 if amber else 0.02),0.13,glass_alpha)

	# A narrow front highlight creates readable glass shape even in GL compatibility.
	var highlight := MeshInstance3D.new()
	highlight.name = "BottleHighlight"
	var hmesh := BoxMesh.new()
	hmesh.size = Vector3(0.035,1.18,0.010)
	highlight.mesh = hmesh
	highlight.position = Vector3(-0.22,0.02,0.414)
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(1,0.86,0.62,0.22) if amber else Color(0.92,0.98,1.0,0.30)
	hmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hmat.roughness = 0.05
	highlight.material_override = hmat
	add_child(highlight)

	if not amber:
		var liquid := MeshInstance3D.new()
		liquid.name = "BottleLiquid"
		var liquid_mesh := CylinderMesh.new()
		liquid_mesh.top_radius = 0.382
		liquid_mesh.bottom_radius = 0.382
		liquid_mesh.height = 1.12
		liquid_mesh.radial_segments = 40
		liquid.mesh = liquid_mesh
		liquid.position = Vector3(0,-0.04,0)
		var liquid_mat := StandardMaterial3D.new()
		liquid_mat.albedo_color = Color(profile.get("liquid_color", Color(0.91,0.91,0.66,0.78)))
		liquid_mat.albedo_color.a = 0.78
		liquid_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		liquid_mat.roughness = 0.18
		liquid.material_override = liquid_mat
		add_child(liquid)
		# Condensation beads: sparse, large enough to read, cheap enough for runtime.
		for i in range(18):
			var angle := TAU * float((i*7)%18) / 18.0
			var y := -0.48 + float((i*11)%18) / 18.0 * 1.38
			var bead := MeshInstance3D.new()
			bead.name = "Condensation"
			var sm := SphereMesh.new()
			sm.radius = 0.010 + 0.003*float(i%3)
			sm.height = sm.radius*2.0
			sm.radial_segments = 8
			sm.rings = 4
			bead.mesh = sm
			bead.position = Vector3(sin(angle)*0.423,y,cos(angle)*0.423)
			bead.material_override = _glass_mat(Color(0.90,0.97,1.0),0.42,0.04)
			add_child(bead)

func _add_ring(root: Node3D, node_name: String, at: Vector3, outer_radius: float, inner_radius: float, height: float, color: Color, roughness: float, alpha := 1.0) -> void:
	var ring := MeshInstance3D.new()
	ring.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = outer_radius
	mesh.bottom_radius = outer_radius
	mesh.height = height
	mesh.radial_segments = 48
	ring.mesh = mesh
	ring.position = at
	var mat := _mat(color,roughness)
	if alpha < 0.999:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = alpha
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
	mat.albedo_color.a = clampf(alpha,0.15,0.92)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = clampf(roughness,0.02,0.5)
	mat.metallic = 0.02
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat
