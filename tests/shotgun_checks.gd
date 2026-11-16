extends SceneTree

func fixture() -> MatchSimulation:
	var game := MatchSimulation.new()
	game.terrain = TerrainGrid.new()
	game.terrain.fill_rect(Rect2i(0,0,256,16))
	game.units = [MatchUnit.new(0,1,Vector2(4,2)),MatchUnit.new(1,1,Vector2(7,2))]
	return game

func _initialize() -> void:
	var game := fixture()
	assert(game.fire(0,1,ArtilleryShot.Weapon.SHOTGUN))
	assert(game.units[1].health < 100 and game.units[1].health > 30)
	assert(game.units[0].health == 100 and game.pellet_traces.size() == 10)
	assert(not game.fire(0,1,ArtilleryShot.Weapon.SHOTGUN))
	var near_damage := 100-game.units[1].health
	game = fixture()
	game.units[1].feet.x = 11
	game.fire(0,1,ArtilleryShot.Weapon.SHOTGUN)
	assert(100-game.units[1].health < near_damage)
	game = fixture()
	game.terrain.fill_rect(Rect2i(44,16,1,40))
	game.fire(0,1,ArtilleryShot.Weapon.SHOTGUN)
	assert(game.units[1].health == 100, "A thin wall blocks pellets")
	assert(game.terrain.is_solid(Vector2i(44,18)), "Shotgun does not carve terrain")
	game = fixture()
	game.units[1].feet.x = 15
	game.fire(0,1,ArtilleryShot.Weapon.SHOTGUN)
	assert(game.units[1].health == 100, "Pellets stop at nine metres")
	game = fixture()
	game.units.insert(1,MatchUnit.new(0,2,Vector2(5.5,2)))
	game.fire(0,1,ArtilleryShot.Weapon.SHOTGUN)
	assert(game.units[1].health < 100 and game.units[2].health == 100, "Friendly units intercept pellets")
	game = fixture()
	var cpu := ComputerOpponent.new()
	cpu.rng.seed = 4
	cpu.begin(game)
	while not cpu.advance():
		pass
	assert(cpu.chosen_plan != null)
	assert(game.units[1].health == 100, "CPU forecasting cannot damage the live match")
	print("PASS: shotgun spread, damage falloff, cover, range, friendly fire, turn ownership and isolated CPU planning")
	quit()
