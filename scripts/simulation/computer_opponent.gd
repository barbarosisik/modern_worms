class_name ComputerOpponent
extends RefCounted

const STEP := 1.0 / 60.0
const WALK_TICKS := 22
const STOP_TICKS := 9
const MAX_FORECAST_SLICES := 105
const MAX_FORECASTS_PER_TICK := 12
const FORECAST_SLICE_USEC := 2300
const FINALIST_COUNT := 6
const MAX_FLIGHT_TICKS := 365
const MAX_RESOLUTION_TICKS := 480
const ANGLES := [26.0, 36.0, 16.0, 46.0, 6.0, 56.0, -8.0, 68.0, -22.0, 78.0]
const POWERS := [0.86, 0.70, 1.0, 0.55, 0.95, 0.40, 0.25, 0.12]


class FiringPosition:
	var state: MatchSimulation
	var move_axis: float
	var centers: PackedVector2Array
	var directions: Array[float] = []

	func _init(preview: MatchSimulation, axis: float) -> void:
		state = preview
		move_axis = axis
		centers = preview.living_centers()
		var active := preview.active_unit()
		for unit in preview.units:
			if not unit.alive() or unit.team == active.team:
				continue
			var direction := signf(unit.feet.x - active.feet.x)
			if is_zero_approx(direction):
				direction = active.facing
			if direction not in directions:
				directions.append(direction)


class Plan:
	var position: FiringPosition
	var facing: float
	var angle: float
	var power: float
	var weapon: ArtilleryShot.Weapon
	var impact := Vector2.INF
	var estimate := -INF

	func _init(
		site: FiringPosition, direction: float, elevation: float, charge: float, kind: ArtilleryShot.Weapon
	) -> void:
		position = site
		facing = direction
		angle = elevation
		power = charge
		weapon = kind


var best_plan: Plan
var _best_score := 0.0
var _candidates: Array[Plan] = []
var _finalists: Array[Plan] = []
var _cursor := 0
var _slices := 0
var _final_cursor := 0


func reset() -> void:
	best_plan = null
	_best_score = 0.0
	_candidates.clear()
	_finalists.clear()
	_cursor = 0
	_slices = 0
	_final_cursor = 0


func begin(state: MatchSimulation) -> void:
	reset()
	var positions: Array[FiringPosition] = []
	for axis in [0.0, -1.0, 1.0]:
		var site := _project_position(state, axis)
		if site != null:
			positions.append(site)
	# Interleave sites and weapons so each gets considered under a short search budget.
	for angle in ANGLES:
		for power in POWERS:
			for site in positions:
				for direction in site.directions:
					_candidates.append(Plan.new(site, direction, angle, power, ArtilleryShot.Weapon.ROCKET))
					_candidates.append(Plan.new(site, direction, angle, power, ArtilleryShot.Weapon.GRENADE))


func advance() -> bool:
	if _cursor < _candidates.size() and _slices < MAX_FORECAST_SLICES:
		_slices += 1
		var deadline := Time.get_ticks_usec() + FORECAST_SLICE_USEC
		for sample in range(MAX_FORECASTS_PER_TICK):
			var candidate := _candidates[_cursor]
			_cursor += 1
			_estimate(candidate)
			if candidate.impact != Vector2.INF:
				_keep_finalist(candidate)
			if _cursor == _candidates.size() or Time.get_ticks_usec() >= deadline:
				break
		return false
	if _final_cursor < _finalists.size():
		var candidate := _finalists[_final_cursor]
		_final_cursor += 1
		var score := _resolve_candidate(candidate)
		if score > _best_score:
			_best_score = score
			best_plan = candidate
		return false
	_candidates.clear()
	_finalists.clear()
	return true


func _project_position(state: MatchSimulation, axis: float) -> FiringPosition:
	var copy := state.snapshot_active_turn()
	var active := copy.active_unit()
	if not active.grounded:
		return null
	if not is_zero_approx(axis):
		var start_x := active.feet.x
		for tick in range(WALK_TICKS + STOP_TICKS):
			copy.step(STEP, axis if tick < WALK_TICKS else 0.0)
			if not active.grounded or copy.phase != MatchSimulation.Phase.ACTIVE:
				return null
		if absf(active.feet.x - start_x) < 0.18 or not active.settled():
			return null
	return FiringPosition.new(copy, axis)


func _estimate(candidate: Plan) -> void:
	var site := candidate.position
	var shot := site.state.build_shot(candidate.angle, candidate.power, candidate.weapon, candidate.facing)
	for tick in range(MAX_FLIGHT_TICKS):
		var result := shot.step(STEP, site.state.terrain, site.centers)
		if result == ArtilleryShot.Result.IMPACT:
			candidate.impact = shot.position
			break
		if result == ArtilleryShot.Result.ESCAPED:
			return
	if candidate.impact == Vector2.INF:
		return

	var team := site.state.active_unit().team
	var score := 0.0
	for unit in site.state.units:
		if not unit.alive():
			continue
		var strength := MatchSimulation.blast_strength(unit.center().distance_to(candidate.impact), candidate.weapon)
		var value := float(mini(unit.health, MatchSimulation.blast_damage(strength, candidate.weapon)))
		# A blast beneath a unit can matter even when its center takes little damage.
		if unit.feet.distance_to(candidate.impact) < MatchSimulation.crater_radius(candidate.weapon):
			value += 12.0
		score += value if unit.team != team else -1.5 * value
	candidate.estimate = score


func _keep_finalist(candidate: Plan) -> void:
	for i in range(_finalists.size()):
		var previous := _finalists[i]
		if previous.position == candidate.position and previous.weapon == candidate.weapon and (
			previous.impact.distance_squared_to(candidate.impact) < 0.16
		):
			if candidate.estimate <= previous.estimate:
				return
			_finalists.remove_at(i)
			break
	_finalists.append(candidate)
	_finalists.sort_custom(func(a: Plan, b: Plan) -> bool: return a.estimate > b.estimate)
	if _finalists.size() > FINALIST_COUNT:
		_finalists.pop_back()


func _resolve_candidate(candidate: Plan) -> float:
	var original := candidate.position.state
	var preview := original.snapshot_active_turn()
	var team := preview.active_unit().team
	preview.active_unit().facing = candidate.facing
	if not preview.fire(candidate.angle, candidate.power, candidate.weapon):
		return -INF
	for tick in range(MAX_RESOLUTION_TICKS):
		preview.step(STEP)
		if preview.phase != MatchSimulation.Phase.RESOLVING:
			break
	if preview.phase == MatchSimulation.Phase.RESOLVING:
		return -INF
	if preview.phase == MatchSimulation.Phase.FINISHED:
		return 200.0 if preview.winner == team else -200.0

	var score := -2.0 if not is_zero_approx(candidate.position.move_axis) else 0.0
	for i in range(original.units.size()):
		var before := original.units[i]
		if not before.alive():
			continue
		var after := preview.units[i]
		var value := float(before.health - after.health)
		value += clampf(before.feet.y - after.feet.y, 0.0, 4.0) * 2.0
		if not after.alive():
			value += 22.0
		score += value if before.team != team else -1.5 * value
	return score
