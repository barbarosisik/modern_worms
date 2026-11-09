class_name AimControls
extends RefCounted

const AIM_SPEED := 48.0
const MIN_ANGLE := -35.0
const MAX_ANGLE := 80.0
const MAX_CHARGE := 100
const PLAY_PLANE := Plane(Vector3.BACK, 0.0)
const FULL_PULL_FRACTION := 0.24
const DEAD_ZONE_FRACTION := 0.05

var drag_direction := Vector2.ZERO
var charge := 0
var _source: StringName = &""
var _charge_step := 1
var _drag_start := Vector2.ZERO


func begin_keyboard() -> void:
	if _source == &"":
		_source = &"fire"


func begin_drag(position: Vector2) -> void:
	if _source == &"":
		_source = &"pointer_fire"
		_drag_start = position


func is_dragging() -> bool:
	return _source == &"pointer_fire"


func update_drag(camera: Camera3D, position: Vector2) -> void:
	if not is_dragging():
		return
	var viewport := camera.get_viewport().get_visible_rect().size
	var full_pull := minf(viewport.x, viewport.y) * FULL_PULL_FRACTION
	var dead_zone := full_pull * DEAD_ZONE_FRACTION
	var distance := position.distance_to(_drag_start)
	charge = roundi(clampf(inverse_lerp(dead_zone, full_pull, distance), 0.0, 1.0) * MAX_CHARGE)
	var start := _point_on_plane(camera, _drag_start)
	var end := _point_on_plane(camera, position)
	if start == Vector2.INF or end == Vector2.INF:
		charge = 0
	drag_direction = start - end if charge > 0 else Vector2.ZERO


func owns_release(event: InputEvent) -> bool:
	return _source != &"" and event.is_action_released(_source)


func tick() -> void:
	if _source != &"fire":
		return
	charge += _charge_step
	if charge == 0 or charge == MAX_CHARGE:
		_charge_step *= -1


func power() -> float:
	return float(charge) / MAX_CHARGE


func cancel() -> void:
	_source = &""
	charge = 0
	_charge_step = 1
	drag_direction = Vector2.ZERO


static func _point_on_plane(camera: Camera3D, screen_point: Vector2) -> Vector2:
	var point: Variant = PLAY_PLANE.intersects_ray(
		camera.project_ray_origin(screen_point), camera.project_ray_normal(screen_point)
	)
	return Vector2.INF if point == null else Vector2(point.x, point.y)


static func elevation(direction: Vector2) -> float:
	return clampf(rad_to_deg(atan2(direction.y, absf(direction.x))), MIN_ANGLE, MAX_ANGLE)
