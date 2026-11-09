class_name TerrainSimulation
extends RefCounted

const MUZZLE := Vector2(4.0, 7.0)
const TARGET_START := Vector2(13.0, 7.0)
const PRESET_VELOCITY := Vector2(20.0, 0.0)
const BLAST_RADIUS := 2.5
const TARGET_GRAVITY := 17.0
const TARGET_HALF_WIDTH := 0.2

var terrain: TerrainGrid
var rocket: ArtilleryShot
var target_feet: Vector2
var last_impact := Vector2.INF
var dirty_chunks: Array[Vector2i] = []
var last_result := ArtilleryShot.Result.FLYING
var _target_velocity := 0.0


func _init() -> void:
	reset()


func reset() -> void:
	terrain = TerrainGrid.new()
	terrain.fill_rect(Rect2i(0, 0, TerrainGrid.SIZE.x, 16))
	terrain.fill_rect(Rect2i(16, 44, 32, 6))
	terrain.fill_rect(Rect2i(96, 48, 16, 8))
	terrain.fill_rect(Rect2i(192, 16, 8, 64))
	rocket = null
	target_feet = TARGET_START
	last_impact = Vector2.INF
	dirty_chunks.clear()
	last_result = ArtilleryShot.Result.FLYING
	_target_velocity = 0.0


func fire(launch_velocity: Vector2) -> bool:
	if rocket != null:
		return false
	rocket = ArtilleryShot.new(MUZZLE, launch_velocity)
	last_result = ArtilleryShot.Result.FLYING
	return true


func step(delta: float) -> void:
	dirty_chunks.clear()
	if rocket != null:
		last_result = rocket.step(delta, terrain)
		if last_result == ArtilleryShot.Result.IMPACT:
			last_impact = rocket.position
			dirty_chunks = terrain.cut_disc(last_impact, BLAST_RADIUS)
		if last_result != ArtilleryShot.Result.FLYING:
			rocket = null
	_drop_target(delta)


func _drop_target(delta: float) -> void:
	_target_velocity -= TARGET_GRAVITY * delta
	var next_y := target_feet.y + _target_velocity * delta
	var support := -INF
	for offset in [-TARGET_HALF_WIDTH, 0.0, TARGET_HALF_WIDTH]:
		var probe_x: float = target_feet.x + offset
		var hit := terrain.first_contact(Vector2(probe_x, target_feet.y), Vector2(probe_x, next_y))
		if hit != Vector2.INF:
			support = maxf(support, hit.y)
	if support > -INF:
		target_feet.y = support
		_target_velocity = 0.0
	else:
		target_feet.y = next_y
