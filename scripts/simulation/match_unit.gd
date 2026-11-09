class_name MatchUnit
extends RefCounted

const MAX_HEALTH := 100
const HALF_WIDTH := 0.26
const HEIGHT := 0.9
const GRAVITY := 17.0
const WALK_SPEED := 3.5
const JUMP_SPEED := 7.1
const EDGE := 0.003

var team: int
var number: int
var feet: Vector2
var velocity := Vector2.ZERO
var facing: float
var health := MAX_HEALTH
var grounded := true


func _init(side: int, unit_number: int, start: Vector2) -> void:
	team = side
	number = unit_number
	feet = start
	facing = 1.0 if side == 0 else -1.0


func alive() -> bool:
	return health > 0


func snapshot() -> MatchUnit:
	var copy := MatchUnit.new(team, number, feet)
	copy.velocity = velocity
	copy.facing = facing
	copy.health = health
	copy.grounded = grounded
	return copy


func center() -> Vector2:
	return feet + Vector2(0.0, HEIGHT * 0.5)


func settled() -> bool:
	return grounded and velocity.length_squared() < 0.01


func step(terrain: TerrainGrid, delta: float, move_axis: float, jump: bool, controlled: bool) -> void:
	if controlled and not is_zero_approx(move_axis):
		facing = signf(move_axis)
	var acceleration := 30.0 if grounded else 10.0
	if controlled:
		velocity.x = move_toward(velocity.x, move_axis * WALK_SPEED, acceleration * delta)
	elif grounded:
		velocity.x = move_toward(velocity.x, 0.0, 15.0 * delta)
	if jump and grounded:
		velocity.y = JUMP_SPEED
		grounded = false
	_move_horizontal(terrain, velocity.x * delta)
	velocity.y -= GRAVITY * delta
	_move_vertical(terrain, velocity.y * delta)


func _move_horizontal(terrain: TerrainGrid, offset: float) -> void:
	if is_zero_approx(offset):
		return
	var direction := signf(offset)
	var lead_x := feet.x + direction * HALF_WIDTH
	var distance := absf(offset)
	for height in [0.04, HEIGHT * 0.5, HEIGHT - 0.04]:
		var probe := Vector2(lead_x, feet.y + height)
		var hit := terrain.first_contact(probe, probe + Vector2(offset, 0.0))
		if hit != Vector2.INF:
			distance = minf(distance, maxf(0.0, absf(hit.x - lead_x) - EDGE))
	if distance < absf(offset):
		velocity.x = 0.0
	feet.x += distance * direction


func _move_vertical(terrain: TerrainGrid, offset: float) -> void:
	var rising := offset > 0.0
	var edge_y := feet.y + (HEIGHT if rising else 0.0)
	var distance := absf(offset)
	var blocked := false
	for side in [-HALF_WIDTH + EDGE, 0.0, HALF_WIDTH - EDGE]:
		var probe := Vector2(feet.x + side, edge_y)
		var hit := terrain.first_contact(probe, probe + Vector2(0.0, offset))
		if hit != Vector2.INF:
			distance = minf(distance, absf(hit.y - edge_y))
			blocked = true
	grounded = blocked and not rising
	if blocked:
		velocity.y = 0.0
	feet.y += distance * signf(offset)
