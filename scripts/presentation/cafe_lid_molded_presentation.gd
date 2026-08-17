extends Node
class_name CafeLidMoldedPresentation

const DETAIL_ROOT := "CafeLidMoldedDetail"

func _ready() -> void:
	call_deferred("_sync_live_detail")

func _process(_delta: float) -> void:
	_sync_live_detail()

func _sync_live_detail() -> void:
	var root := get_parent()
	if root == null:
		return
	var product := root.get_node_or_null("ProductPresentation") as ProductPresentation
	if product == null:
		return
	var existing := product.get_node_or_null(DETAIL_ROOT) as Node3D
	if product.get_active_kind() != "paper_cup":
		if existing != null:
			existing.free()
		return
	if existing != null:
		return
	_build_detail(product)

func _build_detail(product: ProductPresentation) -> void:
	# ProductPresentation owns the live cup silhouette. Anchor these tiny molded
	# cues to its actual top bead so they survive profile dimensions without
	# relying on the intentionally hidden legacy CafePresentation tree.
	var bead := product.get_node_or_null("CupLidTopBead") as MeshInstance3D
	if bead == null or not (bead.mesh is CylinderMesh):
		return
	var bead_mesh := bead.mesh as CylinderMesh
	var bead_top := bead.position.y + bead_mesh.height * 0.5
	var front_radius := maxf(bead_mesh.top_radius, bead_mesh.bottom_radius)

	var detail := Node3D.new()
	detail.name = DETAIL_ROOT
	product.add_child(detail)

	var sip_tab := MeshInstance3D.new()
	sip_tab.name = "LidSipTab"
	var sip_mesh := CylinderMesh.new()
	sip_mesh.top_radius = 0.074
	sip_mesh.bottom_radius = 0.080
	sip_mesh.height = 0.018
	sip_mesh.radial_segments = 48
	sip_tab.mesh = sip_mesh
	sip_tab.position = Vector3(0.0, bead_top + 0.006, front_radius * 0.48)
	sip_tab.scale = Vector3(1.0, 1.0, 0.52)
	sip_tab.material_override = _molded_material(Color(0.120, 0.112, 0.106, 1.0), 0.34)
	detail.add_child(sip_tab)

	var vent := MeshInstance3D.new()
	vent.name = "LidVentDimple"
	var vent_mesh := CylinderMesh.new()
	vent_mesh.top_radius = 0.025
	vent_mesh.bottom_radius = 0.028
	vent_mesh.height = 0.009
	vent_mesh.radial_segments = 32
	vent.mesh = vent_mesh
	vent.position = Vector3(-front_radius * 0.22, bead_top + 0.004, -front_radius * 0.10)
	vent.material_override = _molded_material(Color(0.045, 0.041, 0.039, 1.0), 0.52)
	detail.add_child(vent)

func _molded_material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = 0.0
	material.metallic_specular = 0.50
	return material