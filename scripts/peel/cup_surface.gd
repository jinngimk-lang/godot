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

static func frustum_radius_at_y(
	y: float,
	bottom_radius: float,
	top_radius: float,
	cup_height: float,
	cup_center_y: float = 0.0
) -> float:
	var height := maxf(absf(cup_height), 0.001)
	var bottom := maxf(bottom_radius, 0.001)
	var top := maxf(top_radius, 0.001)
	var bottom_y := cup_center_y - height * 0.5
	var t := clampf((y - bottom_y) / height, 0.0, 1.0)
	return lerpf(bottom, top, t)

static func attached_point_on_frustum(
	u: float,
	label_width: float,
	y: float,
	bottom_radius: float,
	top_radius: float,
	cup_height: float,
	cup_center_y: float,
	surface_offset: float = 0.018
) -> Vector3:
	var safe_u := clampf(u, 0.0, 1.0)
	var radius := maxf(
		frustum_radius_at_y(y, bottom_radius, top_radius, cup_height, cup_center_y) + surface_offset,
		0.001
	)
	var safe_width := maxf(label_width, 0.0)
	var arc_length := lerpf(-safe_width * 0.5, safe_width * 0.5, safe_u)
	var angle := arc_length / radius
	return Vector3(sin(angle) * radius, y, cos(angle) * radius)

static func frustum_surface_normal(
	point: Vector3,
	bottom_radius: float,
	top_radius: float,
	cup_height: float
) -> Vector3:
	var radial := Vector3(point.x, 0.0, point.z)
	if radial.length_squared() <= 0.000001:
		return Vector3.FORWARD
	var height := maxf(absf(cup_height), 0.001)
	var bottom := maxf(bottom_radius, 0.001)
	var top := maxf(top_radius, 0.001)
	var slope := (top - bottom) / height
	radial = radial.normalized()
	return Vector3(radial.x, -slope, radial.z).normalized()
