extends Node3D
class_name HandVisual

var follow_rate := 11.0
var _target := Vector3.ZERO
var _dynamic := false

func setup(dynamic_hand: bool) -> void:
	_dynamic = dynamic_hand
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.83, 0.62, 0.47, 1.0)
	skin.roughness = 0.72

	var palm := MeshInstance3D.new()
	palm.name = "Palm"
	var palm_mesh := BoxMesh.new()
	palm_mesh.size = Vector3(0.34, 0.17, 0.22)
	palm.mesh = palm_mesh
	palm.material_override = skin
	add_child(palm)

	for i in range(2):
		var finger := MeshInstance3D.new()
		finger.name = "Finger%d" % i
		var finger_mesh := CapsuleMesh.new()
		finger_mesh.radius = 0.055
		finger_mesh.height = 0.34
		finger.mesh = finger_mesh
		finger.material_override = skin
		finger.position = Vector3(0.10 if i == 0 else -0.10, -0.15, -0.02)
		finger.rotation_degrees = Vector3(0, 0, 12 if i == 0 else -12)
		add_child(finger)

func set_target(target: Vector3) -> void:
	_target = target

func snap_to(target: Vector3) -> void:
	_target = target
	position = target

func tick(delta: float) -> void:
	if not _dynamic:
		return
	var weight := 1.0 - exp(-follow_rate * clampf(delta, 0.0, 0.1))
	position = position.lerp(_target, weight)
