extends RefCounted
class_name LabelGeometry

const GRIP_CHORD_RATIO := 0.92

static func resolve_grip(
	progress: float,
	desired_grip: Vector3,
	label_width: float,
	cup_radius: float,
	label_y: float,
	surface_offset: float = 0.018
) -> Vector3:
	var p := clampf(progress if is_finite(progress) else 0.0, 0.0, 1.0)
	var width := maxf(label_width if is_finite(label_width) else 0.0, 0.0)
	var front := CupSurface.attached_point(p, width, cup_radius, label_y, surface_offset)
	var available := width * p
	if available <= 0.00001:
		return front
	var delta := desired_grip - front
	var distance := delta.length()
	var max_chord := available * GRIP_CHORD_RATIO
	if distance <= max_chord or distance <= 0.00001:
		return desired_grip
	return front + delta / distance * max_chord

static func peeling_points(
	progress: float,
	desired_grip: Vector3,
	label_width: float,
	cup_radius: float,
	label_y: float,
	surface_offset: float,
	segments: int
) -> PackedVector3Array:
	var points := PackedVector3Array()
	var safe_segments := maxi(segments, 2)
	var p := clampf(progress if is_finite(progress) else 0.0, 0.0, 1.0)
	var width := maxf(label_width if is_finite(label_width) else 0.0, 0.001)
	var front := CupSurface.attached_point(p, width, cup_radius, label_y, surface_offset)
	var grip := resolve_grip(p, desired_grip, width, cup_radius, label_y, surface_offset)
	var front_normal := CupSurface.attached_normal(p, width, cup_radius, surface_offset)
	var free_length := width * p
	# Keep the free flap visibly curved at the product's 38-48% evidence range.
	# The previous 0.08/0.07 profile produced a nearly straight chord that read
	# like a rigid triangular card once the peeled backing became visible.
	var curve_amp := minf(0.09, free_length * 0.11)

	for i in range(safe_segments + 1):
		var u := float(i) / float(safe_segments)
		if p <= 0.00001 or u > p:
			points.append(CupSurface.attached_point(u, width, cup_radius, label_y, surface_offset))
			continue
		var t := clampf(u / p, 0.0, 1.0)
		var lift := sin(t * PI)
		var center := grip.lerp(front, t)
		center += Vector3.UP * lift * curve_amp
		center += front_normal * lift * curve_amp * 0.65
		points.append(center)
	return points

static func held_points(
	grip: Vector3,
	direction: Vector3,
	label_width: float,
	segments: int
) -> PackedVector3Array:
	var points := PackedVector3Array()
	var safe_segments := maxi(segments, 2)
	var width := maxf(label_width if is_finite(label_width) else 0.0, 0.001)
	var forward := direction.normalized()
	if forward.length_squared() <= 0.000001:
		forward = Vector3.LEFT
	var side := forward.cross(Vector3.UP).normalized()
	if side.length_squared() <= 0.000001:
		side = Vector3.FORWARD

	for i in range(safe_segments + 1):
		var u := float(i) / float(safe_segments)
		var center := grip + forward * (width * u)
		center += Vector3.UP * sin(u * PI) * 0.045
		center += side * sin(u * PI * 2.0) * (1.0 - u) * 0.028
		points.append(center)
	return points
