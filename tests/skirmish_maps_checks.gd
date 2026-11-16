extends SceneTree

func _initialize() -> void:
	for layout in range(3):
		var game := MatchSimulation.new()
		game.reset(null, layout)
		for i in range(30):
			game.step(1.0 / 60.0)
		for unit in game.units:
			assert(unit.alive() and unit.grounded, "Every map starts all four units on supported ground")
		assert(game.supply_position != Vector2.INF, "Every map has a valid supply placement")
		for shooter in [0,1,3]:
			game.turn_index = shooter
			var cpu := ComputerOpponent.new()
			cpu.rng.seed = 3
			cpu.begin(game)
			while not cpu.advance(): pass
			assert(cpu.chosen_plan != null, "Each side has reachable opponents on every larger map")
	for layout in range(5):
		var terrain := TerrainGrid.new()
		BattleMaps.build(terrain, layout)
		var heights: Dictionary[int,bool] = {}
		var asymmetry := 0
		var occupied := 0
		var first := TerrainGrid.SIZE.x
		var last := 0
		for x in range(TerrainGrid.SIZE.x):
			for y in range(TerrainGrid.SIZE.y):
				if terrain.is_solid(Vector2i(x,y)):
					occupied += 1
					first = mini(first,x)
					last = maxi(last,x)
					if not terrain.is_solid(Vector2i(TerrainGrid.SIZE.x-1-x,y)):
						asymmetry += 1
			var height := BattleMaps.surface_y(terrain, (x+0.5) * TerrainGrid.CELL_SIZE)
			if is_finite(height): heights[roundi(height / TerrainGrid.CELL_SIZE)] = true
		assert((last-first) * TerrainGrid.CELL_SIZE > 60, "All five existing battlefields use the expanded width")
		assert(heights.size() > 25 and float(asymmetry) / occupied > 0.12, "Natural profiles vary in height and are not mirrored")
		var cave := Vector2(30,4.3) if layout in [0,1] else Vector2(35,4.2)
		if layout == 2: cave = Vector2(39,3.5)
		assert(not terrain.is_solid(Vector2i(cave / TerrainGrid.CELL_SIZE)), "Cave passages stay open")
		assert(terrain.is_solid(Vector2i(Vector2(cave.x,2) / TerrainGrid.CELL_SIZE)), "Cave routes retain supporting floors above water")
		assert(terrain.is_solid(Vector2i(Vector2(cave.x,6) / TerrainGrid.CELL_SIZE)), "Cave cover is real destructible terrain")
	print("PASS: five expanded asymmetric maps, height variety, covered passages, supported spawns, supplies and both CPU positions")
	quit()
