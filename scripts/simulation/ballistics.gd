class_name LabRocket
extends RefCounted

enum Result { FLYING, IMPACT, ESCAPED }

const GRAVITY := 4.0
const FLIGHT_LIMIT := 6.0
const FLIGHT_BOUNDS := Rect2(Vector2.ZERO, TerrainGrid.WORLD_SIZE + Vector2(0.0, 4.0))

var position: Vector2
var velocity: Vector2
var age := 0.0


func _init(muzzle: Vector2, launch_velocity: Vector2) -> void:
	position = muzzle
	velocity = launch_velocity


func step(delta: float, terrain: TerrainGrid) -> Result:
	velocity.y -= GRAVITY * delta
	var next_position := position + velocity * delta
	var impact := terrain.first_contact(position, next_position)
	if impact != Vector2.INF:
		position = impact
		return Result.IMPACT
	position = next_position
	age += delta
	if age >= FLIGHT_LIMIT or not FLIGHT_BOUNDS.has_point(position):
		return Result.ESCAPED
	return Result.FLYING
