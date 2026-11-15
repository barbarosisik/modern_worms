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
		var cpu := ComputerOpponent.new()
		cpu.rng.seed = 3
		cpu.begin(game)
		while not cpu.advance():
			pass
		assert(cpu.chosen_plan != null, "Every map offers a CPU shot")
	print("PASS: three skirmish maps, supported spawns, supplies and CPU plans")
	quit()
