class_name MatchUnit
extends RefCounted

const MAX_HEALTH := 100
const HALF_WIDTH := 0.26
const HEIGHT := 0.9
const GRAVITY := 17.0
const WALK_SPEED := 3.5
const JUMP_SPEED := 7.1
const EDGE := 0.003
const STEP_HEIGHT := TerrainGrid.CELL_SIZE * 2.0

var team: int
var number: int
var feet: Vector2
var velocity := Vector2.ZERO
var facing: float
var health := MAX_HEALTH
var grounded := true
var guide_tier := 0
var display_name := ""
var outfit := 0


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
	copy.guide_tier = guide_tier
	copy.display_name = display_name
	copy.outfit = outfit
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
	var walking := controlled and not is_zero_approx(move_axis) and grounded and velocity.y <= 0.0 and not jump
	_move_horizontal(terrain, velocity.x * delta, walking)
	if walking:
		_snap_small_descent(terrain)
	velocity.y -= GRAVITY * delta
	_move_vertical(terrain, velocity.y * delta)


func _move_horizontal(terrain: TerrainGrid, offset: float, allow_step: bool = false) -> void:
	if is_zero_approx(offset):
		return
	var distance := _horizontal_distance(terrain, feet, offset)
	if distance < absf(offset):
		if allow_step and _try_step_up(terrain, offset):
			return
		velocity.x = 0.0
	feet.x += distance * signf(offset)


func _horizontal_distance(terrain: TerrainGrid, point: Vector2, offset: float) -> float:
	var direction := signf(offset)
	var lead_x := point.x + direction * HALF_WIDTH
	var distance := absf(offset)
	# Probe every occupied body row, including thin terrain between the old three probes.
	for row in range(floori((point.y + EDGE) / TerrainGrid.CELL_SIZE), floori((point.y + HEIGHT - EDGE) / TerrainGrid.CELL_SIZE) + 1):
		var y := clampf((row + 0.5) * TerrainGrid.CELL_SIZE, point.y + EDGE, point.y + HEIGHT - EDGE)
		var probe := Vector2(lead_x, y)
		var hit := terrain.first_contact(probe, probe + Vector2(offset, 0.0))
		if hit != Vector2.INF:
			distance = minf(distance, maxf(0.0, absf(hit.x - lead_x) - EDGE))
	return distance


func _try_step_up(terrain: TerrainGrid, offset: float) -> bool:
	if _floor_below(terrain, feet, 0.06) == INF:
		return false
	for cells in range(1, 3):
		var lifted := feet + Vector2(0.0, cells * TerrainGrid.CELL_SIZE)
		var landing := lifted + Vector2(offset, 0.0)
		if not _body_clear(terrain, lifted) or not _body_clear(terrain, landing):
			continue
		if _horizontal_distance(terrain, lifted, offset) < absf(offset) or _floor_below(terrain, landing, 0.06) == INF:
			continue
		feet = landing
		velocity.y = 0.0
		return true
	return false


func _body_clear(terrain: TerrainGrid, point: Vector2) -> bool:
	var low := Vector2i(((point + Vector2(-HALF_WIDTH + EDGE, EDGE)) / TerrainGrid.CELL_SIZE).floor())
	var high := Vector2i(((point + Vector2(HALF_WIDTH - EDGE, HEIGHT - EDGE)) / TerrainGrid.CELL_SIZE).floor())
	for y in range(low.y, high.y + 1):
		for x in range(low.x, high.x + 1):
			if terrain.is_solid(Vector2i(x, y)):
				return false
	return true


func _floor_below(terrain: TerrainGrid, point: Vector2, distance: float) -> float:
	var highest := -INF
	for side in [-HALF_WIDTH + EDGE, 0.0, HALF_WIDTH - EDGE]:
		var start := point + Vector2(side, EDGE)
		var hit := terrain.first_contact(start, start - Vector2(0.0, distance + EDGE))
		if hit != Vector2.INF:
			highest = maxf(highest, hit.y)
	return INF if highest == -INF else highest


func _snap_small_descent(terrain: TerrainGrid) -> void:
	var floor_y := _floor_below(terrain, feet, STEP_HEIGHT)
	if floor_y != INF and floor_y <= feet.y:
		feet.y = floor_y


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
