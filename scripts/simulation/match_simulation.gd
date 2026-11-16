class_name MatchSimulation
extends RefCounted

enum Phase { ACTIVE, RESOLVING, FINISHED }

const TURN_SECONDS := 30.0
const WATER_LEVEL := 0.8
const QUIET_TIME := 0.35
const WIND_PATTERN := [0.0, -1.25, 1.4, -0.7, 0.85, 1.65]
const TEAM_NAMES := ["Blue", "Orange"]
const RESCUE_DISTANCE := 0.82

var terrain: TerrainGrid
var units: Array[MatchUnit] = []
var shot: ArtilleryShot
var pellet_traces: Array[Vector2] = []
var phase := Phase.ACTIVE
var turn_index := 0
var turn_number := 1
var remaining := TURN_SECONDS
var winner := -1
var wind := 0.0
var message := ""
var last_blast := Vector2.INF
var dirty_chunks: Array[Vector2i] = []
var supply_position := Vector2.INF
var supplies := PackedInt32Array([0, 0])
var collected_supply_team := -1
var rescue_target: MatchUnit
var rescued := false
var _supply_rng: RandomNumberGenerator
var _quiet_time := 0.0
var _wind_scale := 1.0
var _last_turn_on_team := PackedInt32Array([-1, -1])


func _init(build_arena: bool = true) -> void:
	if build_arena:
		_supply_rng = RandomNumberGenerator.new()
		reset()


func reset(mission: CampaignMission = null, map_index: int = 0) -> void:
	if mission == null:
		_set_up_skirmish(map_index)
		rescue_target = null
		_wind_scale = 1.0
	else:
		terrain = mission.terrain
		units = mission.units
		rescue_target = mission.rescue_target
		_wind_scale = mission.wind_scale
	shot = null
	pellet_traces.clear()
	phase = Phase.ACTIVE
	turn_index = 0
	turn_number = 1
	remaining = TURN_SECONDS
	winner = -1
	wind = 0.0
	message = "Walk or shoot through a supply to collect it."
	if mission != null:
		message = CampaignRun.OBJECTIVES[mission.index]
	last_blast = Vector2.INF
	dirty_chunks.clear()
	supplies.fill(0)
	supply_position = Vector2.INF
	collected_supply_team = -1
	rescued = false
	_last_turn_on_team.fill(-1)
	_spawn_supply()
	_quiet_time = 0.0


func _set_up_skirmish(map_index: int = 0) -> void:
	terrain = TerrainGrid.new()
	BattleMaps.build(terrain, clampi(map_index, 0, 2))
	units = [
		MatchUnit.new(0, 1, Vector2(8.0, BattleMaps.surface_y(terrain, 8.0))),
		MatchUnit.new(1, 1, Vector2(39.0, BattleMaps.surface_y(terrain, 39.0))),
		MatchUnit.new(0, 2, Vector2(19.0, BattleMaps.surface_y(terrain, 19.0))),
		MatchUnit.new(1, 2, Vector2(54.0, BattleMaps.surface_y(terrain, 54.0))),
	]


func active_unit() -> MatchUnit:
	return units[turn_index]


func snapshot_active_turn() -> MatchSimulation:
	var copy := MatchSimulation.new(false)
	copy.terrain = terrain.snapshot()
	for unit in units:
		copy.units.append(unit.snapshot())
	copy.turn_index = turn_index
	copy.turn_number = turn_number
	copy.remaining = remaining
	copy.wind = wind
	copy._wind_scale = _wind_scale
	copy._last_turn_on_team = _last_turn_on_team.duplicate()
	copy.rescued = rescued
	if rescue_target != null:
		copy.rescue_target = rescue_target.snapshot()
	return copy


func pass_turn() -> void:
	if phase == Phase.ACTIVE:
		_resolve("Turn passed.")


func fire(angle: float, power: float, weapon: ArtilleryShot.Weapon) -> bool:
	if phase != Phase.ACTIVE or not active_unit().alive():
		return false
	pellet_traces.clear()
	if weapon == ArtilleryShot.Weapon.SHOTGUN:
		_fire_shotgun(angle, power)
		return true
	shot = build_shot(angle, power, weapon, active_unit().facing)
	_resolve("Rocket in flight." if weapon == ArtilleryShot.Weapon.ROCKET else "Grenade in flight.")
	return true


func build_shot(angle: float, power: float, weapon: ArtilleryShot.Weapon, facing: float) -> ArtilleryShot:
	var unit := active_unit()
	var direction := Vector2.from_angle(deg_to_rad(angle))
	direction.x *= facing
	var speed := lerpf(6.0, 18.0, clampf(power, 0.0, 1.0))
	var projectile := ArtilleryShot.new(unit.center(), direction * speed, weapon)
	projectile.gravity = 9.0 if weapon == ArtilleryShot.Weapon.ROCKET else 13.0
	projectile.wind = wind if weapon == ArtilleryShot.Weapon.ROCKET else 0.0
	if weapon == ArtilleryShot.Weapon.SHOTGUN:
		projectile.velocity = direction * 60.0
		projectile.gravity = 0.0
		projectile.wind = 0.0
		projectile.travel_limit = 9.0
	projectile.bounds = Rect2(-1.0, WATER_LEVEL, TerrainGrid.WORLD_SIZE.x + 2.0, TerrainGrid.WORLD_SIZE.y + 8.0)
	# Check the muzzle segment on the first tick, even when the unit is pressed against cover.
	projectile.launch_offset = direction * 0.61
	projectile.ignore_center = unit.center()
	return projectile


func step(delta: float, move_axis: float = 0.0, jump: bool = false) -> void:
	dirty_chunks.clear()
	last_blast = Vector2.INF
	collected_supply_team = -1
	if phase == Phase.FINISHED:
		return
	if phase == Phase.ACTIVE:
		remaining = maxf(0.0, remaining - delta)
		if is_zero_approx(remaining):
			_resolve("Time is up.")
	if shot != null:
		_update_shot(delta)
	_step_rescue_target(delta)
	for unit in units:
		if not unit.alive():
			continue
		var controlled := phase == Phase.ACTIVE and unit == active_unit()
		var previous_center := unit.center()
		unit.step(terrain, delta, move_axis if controlled else 0.0, controlled and jump, controlled)
		if unit.feet.y <= WATER_LEVEL:
			unit.health = 0
			message = "%s %d fell into the water." % [TEAM_NAMES[unit.team], unit.number]
			if controlled:
				_resolve(message)
		elif controlled:
			_collect_supply(unit.team, previous_center, unit.center(), MatchUnit.HALF_WIDTH)
			_check_rescue(unit, previous_center)
	if phase == Phase.RESOLVING:
		_check_settlement(delta)


func team_health(team: int) -> int:
	var total := 0
	for unit in units:
		if unit.team == team:
			total += unit.health
	return total


func living_centers() -> PackedVector2Array:
	var centers := PackedVector2Array()
	for unit in units:
		if unit.alive():
			centers.append(unit.center())
	return centers


func _update_shot(delta: float) -> void:
	var start := shot.position
	var result := shot.step(delta, terrain, living_centers())
	_collect_supply(active_unit().team, start, shot.position)
	match result:
		ArtilleryShot.Result.IMPACT:
			_explode(shot.position, shot.weapon)
			shot = null
		ArtilleryShot.Result.ESCAPED:
			shot = null
			message = "The shot left the arena."


func _spawn_supply() -> void:
	if _supply_rng != null and supply_position == Vector2.INF:
		var keep_clear := rescue_target.center() if rescue_target != null and not rescued else Vector2.INF
		supply_position = SupplyPickup.choose_site(terrain, units, WATER_LEVEL, _supply_rng, keep_clear)


func _collect_supply(team: int, start: Vector2, end: Vector2, extra_radius: float = 0.0) -> void:
	if supply_position != Vector2.INF and SupplyPickup.touched(supply_position, start, end, extra_radius):
		supplies[team] += 1
		collected_supply_team = team
		supply_position = Vector2.INF


func _step_rescue_target(delta: float) -> void:
	if rescue_target == null or rescued or not rescue_target.alive():
		return
	rescue_target.step(terrain, delta, 0.0, false, false)
	if rescue_target.feet.y <= WATER_LEVEL:
		rescue_target.health = 0
		_resolve("Scout was swept away. Reach him before the bank gives way.")


func _check_rescue(unit: MatchUnit, start: Vector2) -> void:
	if unit.team != 0 or rescue_target == null or rescued or not rescue_target.alive():
		return
	var target := rescue_target.center()
	var closest := Geometry2D.get_closest_point_to_segment(target, start, unit.center())
	if closest.distance_squared_to(target) > RESCUE_DISTANCE * RESCUE_DISTANCE:
		return
	rescued = true
	message = "Scout is safe. Clear the bank to take him to shelter."
	if team_health(1) == 0:
		_resolve("Scout is safe.")


static func crater_radius(weapon: ArtilleryShot.Weapon) -> float:
	return 1.85 if weapon == ArtilleryShot.Weapon.GRENADE else 1.6


static func blast_strength(distance: float, weapon: ArtilleryShot.Weapon) -> float:
	return clampf(1.0 - distance / (crater_radius(weapon) + 0.55), 0.0, 1.0)


static func blast_damage(strength: float, weapon: ArtilleryShot.Weapon) -> int:
	var max_damage := 76.0 if weapon == ArtilleryShot.Weapon.GRENADE else 66.0
	return roundi(max_damage * strength)


func _explode(point: Vector2, weapon: ArtilleryShot.Weapon) -> void:
	var damage_dealt := 0
	for unit in units:
		if not unit.alive():
			continue
		var offset := unit.center() - point
		var strength := blast_strength(offset.length(), weapon)
		if strength <= 0.0:
			continue
		var damage := blast_damage(strength, weapon)
		damage_dealt += mini(unit.health, damage)
		unit.health = maxi(0, unit.health - damage)
		var direction := offset.normalized()
		unit.velocity += Vector2(direction.x * 9.5, maxf(0.3, direction.y) * 7.0 + 2.3) * strength
		unit.grounded = false
	dirty_chunks = terrain.cut_disc(point, crater_radius(weapon))
	if supply_position != Vector2.INF and supply_position.distance_to(point) <= crater_radius(weapon) + 1.0:
		supply_position = SupplyPickup.supported_position(terrain, supply_position, WATER_LEVEL)
	last_blast = point
	message = "%d damage dealt." % damage_dealt if damage_dealt > 0 else "Terrain hit."


func _resolve(reason: String) -> void:
	phase = Phase.RESOLVING
	_quiet_time = 0.0
	message = reason


func _check_settlement(delta: float) -> void:
	if shot != null:
		return
	for unit in units:
		if unit.alive() and not unit.settled():
			_quiet_time = 0.0
			return
	_quiet_time += delta
	if _quiet_time < QUIET_TIME:
		return
	var blue := team_health(0)
	var orange := team_health(1)
	if rescue_target != null and not rescued and not rescue_target.alive():
		winner = 1
		phase = Phase.FINISHED
		return
	if blue == 0 or (orange == 0 and (rescue_target == null or rescued)):
		winner = 0 if blue > 0 else (1 if orange > 0 else -1)
		phase = Phase.FINISHED
		return
	_last_turn_on_team[active_unit().team] = turn_index
	var next_team := 1 - active_unit().team if orange > 0 else 0
	turn_index = _next_unit_on_team(next_team)
	turn_number += 1
	wind = WIND_PATTERN[(turn_number - 1) % WIND_PATTERN.size()] * _wind_scale
	remaining = TURN_SECONDS
	phase = Phase.ACTIVE
	if turn_number % 2 == 1:
		_spawn_supply()


func _next_unit_on_team(team: int) -> int:
	for offset in range(1, units.size() + 1):
		var index := (_last_turn_on_team[team] + offset) % units.size()
		if units[index].team == team and units[index].alive():
			return index
	return turn_index


func _fire_shotgun(angle: float, power: float) -> void:
	var shooter := active_unit()
	var muzzle := shooter.center()
	var total := 0
	# Pull controls spread: a deliberate full pull narrows the five-pellet cone.
	var spread := lerpf(9.0, 4.0, clampf(power,0.0,1.0))
	for pellet in range(5):
		var direction := Vector2.from_angle(deg_to_rad(angle + (pellet-2) * spread * 0.5))
		direction.x *= shooter.facing
		var end := muzzle + direction * 9.0
		var contact := terrain.sweep(muzzle,end)
		if contact != null:
			end = contact.point
		var nearest: MatchUnit = null
		var hit_time := 1.0
		for unit in units:
			if unit == shooter or not unit.alive():
				continue
			var t := Geometry2D.segment_intersects_circle(muzzle,end,unit.center(),ArtilleryShot.UNIT_HIT_RADIUS)
			if t >= 0.0 and t < hit_time:
				hit_time = t
				nearest = unit
		if nearest != null:
			end = muzzle.lerp(end,hit_time)
			var damage := roundi(lerpf(14.0,4.0,clampf(muzzle.distance_to(end)/9.0,0.0,1.0)))
			total += mini(nearest.health,damage)
			nearest.health = maxi(0,nearest.health-damage)
			nearest.velocity += Vector2(direction.x * 0.7,0.3)
			nearest.grounded = false
		_collect_supply(shooter.team,muzzle,end)
		pellet_traces.append(muzzle)
		pellet_traces.append(end)
	_resolve("Shotgun: %d damage. Cover blocks pellets." % total)
