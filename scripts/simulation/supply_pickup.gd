class_name SupplyPickup
extends RefCounted

const MIN_GAP := 7.0
const UNIT_CLEARANCE := 2.0
const RADIUS := 0.34
const SITE_CLEARANCE := 0.50
const FLOAT_HEIGHT := 0.53
const SITE_SAMPLES := 12


static func choose_site(
	terrain: TerrainGrid, units: Array[MatchUnit], water: float, rng: RandomNumberGenerator,
	keep_clear: Vector2 = Vector2.INF
) -> Vector2:
	var living := units.filter(func(unit: MatchUnit) -> bool: return unit.alive())
	living.sort_custom(func(a: MatchUnit, b: MatchUnit) -> bool: return a.feet.x < b.feet.x)
	var sites := PackedVector2Array()
	for i in range(1, living.size()):
		var left: MatchUnit = living[i - 1]
		var right: MatchUnit = living[i]
		if left.team == right.team or right.feet.x - left.feet.x < MIN_GAP:
			continue
		var ceiling := maxf(left.feet.y, right.feet.y) + 1.35
		for j in range(SITE_SAMPLES):
			var x := lerpf(left.feet.x + UNIT_CLEARANCE, right.feet.x - UNIT_CLEARANCE,
				float(j) / (SITE_SAMPLES - 1))
			var site := supported_position(terrain, Vector2(x, ceiling), water)
			if site != Vector2.INF and (keep_clear == Vector2.INF or site.distance_to(keep_clear) >= UNIT_CLEARANCE):
				sites.append(site)
	return Vector2.INF if sites.is_empty() else sites[rng.randi_range(0, sites.size() - 1)]


static func supported_position(terrain: TerrainGrid, start: Vector2, water: float) -> Vector2:
	var floor := terrain.first_contact(start, Vector2(start.x, water + 0.2))
	if floor == Vector2.INF or start.y - floor.y < TerrainGrid.CELL_SIZE:
		return Vector2.INF
	var center := floor + Vector2(0.0, FLOAT_HEIGHT)
	for offset in [-SITE_CLEARANCE, SITE_CLEARANCE]:
		var edge := Vector2(floor.x + offset, floor.y)
		if terrain.first_contact(edge + Vector2(0.0, 0.08), edge - Vector2(0.0, 0.14)) == Vector2.INF:
			return Vector2.INF
	for height in [FLOAT_HEIGHT - RADIUS, FLOAT_HEIGHT + RADIUS]:
		var row := floor + Vector2(0.0, height)
		var side := Vector2(SITE_CLEARANCE, 0.0)
		if terrain.first_contact(row - side, row + side) != Vector2.INF:
			return Vector2.INF
	return center


static func touched(center: Vector2, start: Vector2, end: Vector2, extra_radius: float = 0.0) -> bool:
	var nearest := Geometry2D.get_closest_point_to_segment(center, start, end)
	var radius := RADIUS + extra_radius
	return center.distance_squared_to(nearest) <= radius * radius
