class_name AimControls
extends RefCounted

const AIM_SPEED := 48.0
const MIN_ANGLE := -35.0
const MAX_ANGLE := 80.0
const MAX_CHARGE := 100
const PLAY_PLANE := Plane(Vector3.BACK, 0.0)

var cursor := Vector2.INF
var charge := 0
var _source: StringName = &""
var _charge_step := 1


func begin(action: StringName) -> void:
	if _source == &"":
		_source = action


func owns_release(event: InputEvent) -> bool:
	return _source != &"" and event.is_action_released(_source)


func tick() -> void:
	if _source == &"":
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


func cursor_direction(camera: Camera3D, center: Vector2) -> Vector2:
	if cursor == Vector2.INF:
		return Vector2.ZERO
	var point: Variant = PLAY_PLANE.intersects_ray(camera.project_ray_origin(cursor), camera.project_ray_normal(cursor))
	if point == null:
		return Vector2.ZERO
	var offset := Vector2(point.x, point.y) - center
	return offset if offset.length_squared() >= 0.0025 else Vector2.ZERO


static func elevation(direction: Vector2) -> float:
	return clampf(rad_to_deg(atan2(direction.y, absf(direction.x))), MIN_ANGLE, MAX_ANGLE)
