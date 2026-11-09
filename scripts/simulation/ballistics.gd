class_name ArtilleryShot
extends RefCounted

enum Result { FLYING, IMPACT, ESCAPED }
enum Weapon { ROCKET, GRENADE }

const GRAVITY := 4.0
const FLIGHT_LIMIT := 6.0
const FLIGHT_BOUNDS := Rect2(Vector2.ZERO, TerrainGrid.WORLD_SIZE + Vector2(0.0, 4.0))
const FUSE_SECONDS := 2.35
const UNIT_HIT_RADIUS := 0.42
const SURFACE_OFFSET := 0.005

var position: Vector2
var velocity: Vector2
var weapon: Weapon
var gravity := GRAVITY
var wind := 0.0
var bounds := FLIGHT_BOUNDS
var age := 0.0
var launch_offset := Vector2.ZERO
var ignore_center := Vector2.INF
var _resting := false


func _init(muzzle: Vector2, launch_velocity: Vector2, kind: Weapon = Weapon.ROCKET) -> void:
	position = muzzle
	velocity = launch_velocity
	weapon = kind


func step(delta: float, terrain: TerrainGrid, targets := PackedVector2Array()) -> Result:
	age += delta
	if not _resting:
		velocity += Vector2(wind, -gravity) * delta
		var next_position := position + velocity * delta + launch_offset
		var contact := terrain.sweep(position, next_position)
		if weapon == Weapon.ROCKET:
			var actor_hit := _first_actor_hit(next_position, targets)
			if actor_hit != Vector2.INF and (
				contact == null or position.distance_squared_to(actor_hit) < position.distance_squared_to(contact.point)
			):
				position = actor_hit
				return Result.IMPACT
			if contact != null:
				position = contact.point
				return Result.IMPACT
		if contact != null:
			_bounce(contact)
		else:
			position = next_position
		launch_offset = Vector2.ZERO
		ignore_center = Vector2.INF
	if not bounds.has_point(position) or age >= FLIGHT_LIMIT:
		return Result.ESCAPED
	if weapon == Weapon.GRENADE and age >= FUSE_SECONDS:
		return Result.IMPACT
	return Result.FLYING


func _first_actor_hit(end: Vector2, targets: PackedVector2Array) -> Vector2:
	var nearest := INF
	for center in targets:
		if center == ignore_center:
			continue
		var time := Geometry2D.segment_intersects_circle(position, end, center, UNIT_HIT_RADIUS)
		if position.distance_squared_to(center) <= UNIT_HIT_RADIUS * UNIT_HIT_RADIUS:
			time = 0.0
		if time >= 0.0:
			nearest = minf(nearest, time)
	return position.lerp(end, nearest) if nearest != INF else Vector2.INF


func _bounce(contact: TerrainGrid.Contact) -> void:
	var normal := contact.normal
	position = contact.point + normal * SURFACE_OFFSET
	var normal_speed := minf(0.0, velocity.dot(normal))
	var tangent := velocity - normal * normal_speed
	velocity = tangent * 0.72 - normal * normal_speed * 0.48
	if normal.y > 0.7 and velocity.length_squared() < 1.25:
		velocity = Vector2.ZERO
		_resting = true
