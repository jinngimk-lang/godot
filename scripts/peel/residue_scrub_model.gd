extends RefCounted
class_name ResidueScrubModel

var _required_travel := 340.0
var _reversal_bonus := 0.45
var _grid_columns := 12
var _grid_rows := 6
var _brush_radius := 0.18
var _progress := 0.0
var _effort_progress := 0.0
var _coverage_progress := 0.0
var _last_direction := Vector2.ZERO
var _rub_intensity := 0.0
var _completed_event_pending := false
var _cleanup_field := PackedFloat32Array()

func _init(config: Dictionary = {}) -> void:
	_required_travel = clampf(float(config.get("required_travel",340.0)),120.0,900.0)
	_reversal_bonus = clampf(float(config.get("reversal_bonus",0.45)),0.0,1.0)
	_grid_columns = clampi(int(config.get("grid_columns",12)),8,24)
	_grid_rows = clampi(int(config.get("grid_rows",6)),4,16)
	_brush_radius = clampf(float(config.get("brush_radius",0.18)),0.08,0.35)
	_reset_cleanup_field()

func reset() -> void:
	_progress = 0.0
	_effort_progress = 0.0
	_coverage_progress = 0.0
	_last_direction = Vector2.ZERO
	_rub_intensity = 0.0
	_completed_event_pending = false
	_reset_cleanup_field()

func update(pressed: bool, position: Vector2, relative: Vector2, region: Rect2, delta: float) -> Dictionary:
	var safe_delta := clampf(delta if is_finite(delta) else 0.0,0.0,0.10)
	_rub_intensity = move_toward(_rub_intensity,0.0,safe_delta*7.0)
	if _progress >= 1.0 or not pressed or region.size.x <= 1.0 or region.size.y <= 1.0 or not region.has_point(position):
		if not pressed:
			_last_direction = Vector2.ZERO
		return _snapshot(false,0.0)
	var travel := minf(relative.length(),24.0)
	if travel < 2.0:
		return _snapshot(false,0.0)
	var direction := relative.normalized()
	var reversed := _last_direction.length_squared() > 0.5 and direction.dot(_last_direction) < -0.30
	var stroke_weight := 1.0+_reversal_bonus if reversed else 0.62
	var gained := minf(travel/_required_travel*stroke_weight,0.085)
	_effort_progress = minf(_effort_progress+gained,1.0)
	_last_direction = direction
	_rub_intensity = clampf(travel/18.0,0.25,1.0)

	var uv := Vector2(
		clampf((position.x-region.position.x)/region.size.x,0.0,1.0),
		clampf((position.y-region.position.y)/region.size.y,0.0,1.0)
	)
	_apply_brush(uv,travel,reversed)
	_recompute_coverage()
	# Completion needs deliberate physical effort AND broad spatial coverage.
	# Repeatedly polishing one point can max effort but cannot clean untouched cells.
	_progress = minf(_effort_progress,clampf(_coverage_progress/0.92,0.0,1.0))
	if _effort_progress >= 0.999 and _coverage_progress >= 0.92:
		_progress = 1.0
		_fill_cleanup_field(1.0)
		_coverage_progress = 1.0
		if not _completed_event_pending:
			_completed_event_pending = true
	return _snapshot(true,gained)

func get_progress() -> float:
	return _progress

func get_coverage_progress() -> float:
	return _coverage_progress

func get_rub_intensity() -> float:
	return _rub_intensity

func get_cleanup_grid_size() -> Vector2i:
	return Vector2i(_grid_columns,_grid_rows)

func get_cleanup_field() -> PackedFloat32Array:
	return _cleanup_field.duplicate()

func get_local_cleanliness(position: Vector2, region: Rect2) -> float:
	if region.size.x <= 1.0 or region.size.y <= 1.0:
		return 0.0
	var uv := Vector2(
		clampf((position.x-region.position.x)/region.size.x,0.0,1.0),
		clampf((position.y-region.position.y)/region.size.y,0.0,1.0)
	)
	return _sample_cleanup_uv(uv)

func is_complete() -> bool:
	return _progress >= 0.999

func consume_completed_event() -> bool:
	if not _completed_event_pending:
		return false
	_completed_event_pending = false
	return true

func _reset_cleanup_field() -> void:
	_cleanup_field = PackedFloat32Array()
	_cleanup_field.resize(_grid_columns*_grid_rows)
	_fill_cleanup_field(0.0)

func _fill_cleanup_field(value: float) -> void:
	var safe := clampf(value,0.0,1.0)
	for i in range(_cleanup_field.size()):
		_cleanup_field[i] = safe

func _apply_brush(uv: Vector2, travel: float, reversed: bool) -> void:
	if _cleanup_field.is_empty():
		return
	# A reversal gives the short tack-release "bite" users expect from rubbing.
	# Four deliberate strokes centered on a cell are enough to clean that local
	# patch, but the normalized radius remains small enough to preserve locality.
	var base_gain := clampf((travel/18.0)*(0.27 if not reversed else 0.40),0.14,0.44)
	for row in range(_grid_rows):
		for column in range(_grid_columns):
			var center := Vector2(
				(float(column)+0.5)/float(_grid_columns),
				(float(row)+0.5)/float(_grid_rows)
			)
			var delta := center-uv
			# Compensate for the non-square grid so the brush reads roughly circular
			# in the former-label footprint instead of sweeping full rows at once.
			var distance := Vector2(delta.x,delta.y*0.82).length()
			if distance > _brush_radius:
				continue
			var falloff := 1.0-clampf(distance/_brush_radius,0.0,1.0)
			var weight := 0.22+0.78*pow(falloff,0.72)
			var index := row*_grid_columns+column
			_cleanup_field[index] = clampf(_cleanup_field[index]+base_gain*weight,0.0,1.0)

func _recompute_coverage() -> void:
	if _cleanup_field.is_empty():
		_coverage_progress = 0.0
		return
	var total := 0.0
	for value in _cleanup_field:
		# Slightly reward cells that are substantially clean while still requiring
		# the user to reach the whole footprint rather than just touching each cell.
		total += smoothstep(0.08,0.92,float(value))
	_coverage_progress = clampf(total/float(_cleanup_field.size()),0.0,1.0)

func _sample_cleanup_uv(uv: Vector2) -> float:
	if _cleanup_field.is_empty() or _grid_columns <= 0 or _grid_rows <= 0:
		return 0.0
	var x := clampf(uv.x,0.0,1.0)*float(_grid_columns)-0.5
	var y := clampf(uv.y,0.0,1.0)*float(_grid_rows)-0.5
	var x0 := clampi(int(floor(x)),0,_grid_columns-1)
	var y0 := clampi(int(floor(y)),0,_grid_rows-1)
	var x1 := clampi(x0+1,0,_grid_columns-1)
	var y1 := clampi(y0+1,0,_grid_rows-1)
	var tx := clampf(x-float(x0),0.0,1.0)
	var ty := clampf(y-float(y0),0.0,1.0)
	var a := lerpf(_cleanup_field[y0*_grid_columns+x0],_cleanup_field[y0*_grid_columns+x1],tx)
	var b := lerpf(_cleanup_field[y1*_grid_columns+x0],_cleanup_field[y1*_grid_columns+x1],tx)
	return clampf(lerpf(a,b,ty),0.0,1.0)

func _snapshot(active: bool, gained: float) -> Dictionary:
	return {
		"active":active,
		"gained":gained,
		"progress":_progress,
		"coverage":_coverage_progress,
		"intensity":_rub_intensity,
		"complete":is_complete()
	}
