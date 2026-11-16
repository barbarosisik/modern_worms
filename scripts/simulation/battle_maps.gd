class_name BattleMaps
extends RefCounted

enum Layout { RIVER_OUTPOSTS, SPLIT_RIDGELINE, BROKEN_CAUSEWAY, FIRST_SIGNAL, FERRY_LANDING }


static func build(terrain: TerrainGrid, layout: int) -> void:
	match layout:
		Layout.RIVER_OUTPOSTS:
			_land(terrain, [1,2, 4,4.5, 7,5, 10,5, 13,6.25, 16,5.25, 19,5.5, 21,5.5, 22.5,3])
			_land(terrain, [24,3, 27,8.5, 29,9, 32,6.5, 36,7, 40,7, 43,5, 45.5,2.5], 1)
			_land(terrain, [47,2.5, 50,5.25, 55,5.25, 58,7.5, 60,6.75, 63,2], 2)
			_tunnel(terrain, Vector2(24,4.2), Vector2(44,4.1), 1.05)
			terrain.carve_ellipse(Vector2(15,2.8), Vector2(3.2,0.95))
		Layout.SPLIT_RIDGELINE:
			_land(terrain, [1,2, 5,4, 8,5.5, 11,7, 14,9.25, 16,8, 19,7, 23,5.5, 26,7, 30,10.75, 33,10, 36,6.5, 39,6.5, 43,4.5, 46,6, 49,8.5, 53,6.75, 57,5.5, 60,4, 63,2], 2)
			_tunnel(terrain, Vector2(23,4.5), Vector2(41,4.2), 1.25)
			terrain.carve_ellipse(Vector2(43,2.1), Vector2(2.4,2.7))
			terrain.carve_ellipse(Vector2(12,3.6), Vector2(3.4,1.4))
		Layout.BROKEN_CAUSEWAY:
			_land(terrain, [1,2, 4,4.75, 9,4.75, 12,6.5, 15,5.5, 17,3.25])
			_land(terrain, [18.5,3.25, 20,5.5, 24,5.5, 27,8, 29,7.5, 31.5,5.5], 2)
			_land(terrain, [33,5.5, 36,7, 40,7, 44,6, 47.5,3.75], 1)
			_land(terrain, [49,3.75, 52,5.75, 55,5.75, 58,7.5, 60,5, 63,2], 3)
			# Thin destructible causeway above a lower passage; other gaps require a jump.
			terrain.fill_rounded_rect(Rect2i(246,41,24,4), 2)
			_tunnel(terrain, Vector2(34,3.2), Vector2(45,3.8), 1.1)
		Layout.FIRST_SIGNAL:
			_land(terrain, [1,2, 4,4.5, 8,5, 12,5, 15,6.5, 18,6.25, 21,6.25, 24,5, 26,3])
			_land(terrain, [27.5,3, 30,7.5, 33,8.25, 36,7.5, 40,7.5, 43,5.5, 45.5,3.5], 1)
			_land(terrain, [47,3.5, 50,6.5, 54,7.5, 57,5.25, 60,5.25, 63,2], 2)
			_tunnel(terrain, Vector2(27.5,4.2), Vector2(44.5,4.5), 1.0)
			terrain.carve_ellipse(Vector2(16,3.4), Vector2(3.5,1.1))
		Layout.FERRY_LANDING:
			_land(terrain, [1,2, 4,5, 9,5, 12,6.25, 16,5.5, 20,5.5, 23,7, 25,4.5])
			_land(terrain, [26.5,4.5, 29,7.75, 32,8.5, 34,7.25, 37,7.25, 40,5.75, 43.5,3], 1)
			_land(terrain, [45,3, 48,5.5, 51,6.5, 55,6.5, 58,8.5, 60,6.5, 63,2], 2)
			_tunnel(terrain, Vector2(27,4.1), Vector2(40,3.8), 1.1)
			terrain.carve_ellipse(Vector2(15,2.6), Vector2(3.5,0.95))


static func surface_y(terrain: TerrainGrid, x: float) -> float:
	var highest := -INF
	for side in [-MatchUnit.HALF_WIDTH, 0.0, MatchUnit.HALF_WIDTH]:
		var column := floori((x + side) / TerrainGrid.CELL_SIZE)
		for row in range(TerrainGrid.SIZE.y - 1, -1, -1):
			if terrain.is_solid(Vector2i(column, row)):
				highest = maxf(highest, (row + 1) * TerrainGrid.CELL_SIZE)
				break
	return highest


static func _land(terrain: TerrainGrid, coordinates: Array, phase: float = 0) -> void:
	var points := PackedVector2Array()
	for i in range(0, coordinates.size(), 2):
		points.append(Vector2(coordinates[i], coordinates[i+1]))
	terrain.fill_landmass(points, phase)


static func _tunnel(terrain: TerrainGrid, start: Vector2, end: Vector2, height: float) -> void:
	var count := ceili(start.distance_to(end) / 0.35)
	for i in range(count + 1):
		var point := start.lerp(end, float(i) / count)
		terrain.carve_ellipse(point, Vector2(1.0, height))
