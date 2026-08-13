extends RefCounted
class_name CupSurface

static func attached_point(
	u: float,
	label_width: float,
	cup_radius: float,
	label_y: float,
	surface_offset: float = 0.018
) -> Vector3:
	var safe_u := clampf(u, 0.0, 1.0)
	var radius := maxf(cup_radius + surface_offset, 0.001)
	var safe_width := maxf(label_width, 0.0)
	var arc_length := lerpf(-safe_width * 0.5, safe_width * 0.5, safe_u)
	var angle := arc_length / radius
	return Vector3(sin(angle) * radius, label_y, cos(angle) * radius)

static func attached_normal(
	u: float,
	label_width: float,
	cup_radius: float,
	surface_offset: float = 0.018
) -> Vector3:
	var point := attached_point(u, label_width, cup_radius, 0.0, surface_offset)
	return Vector3(point.x, 0.0, point.z).normalized()
