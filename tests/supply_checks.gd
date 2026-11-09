extends SceneTree

const STEP := 1.0 / 60.0
var _failures: Array[String] = []


func _initialize() -> void:
	_check_placement()
	_check_collection()
	for failure in _failures:
		push_error(failure)
	if _failures.is_empty():
		print("PASS: randomized supported placements, walking and projectile collection, cover, and round respawn")
	quit(0 if _failures.is_empty() else 1)


func _check_placement() -> void:
	var game := MatchSimulation.new()
	var seen: Array[Vector2] = []
	for seed in range(1, 13):
		game._supply_rng.seed = seed
		game.reset()
		var site := game.supply_position
		_expect(site.is_finite() and site.x >= 10.5 and site.x <= 21.5, "A supply spawns between opposing units.")
		if site not in seen:
			seen.append(site)
	_expect(seen.size() > 1, "Different seeds choose different valid sites.")
	var rng := RandomNumberGenerator.new()
	for i in range(game.units.size()):
		game.units[i].feet.x = 12.0 + float(i)
	_expect(SupplyPickup.choose_site(game.terrain, game.units, MatchSimulation.WATER_LEVEL, rng) == Vector2.INF,
		"Close teams do not spawn a pickup between them.")
	_expect(SupplyPickup.choose_site(TerrainGrid.new(), MatchSimulation.new().units, MatchSimulation.WATER_LEVEL,
		rng) == Vector2.INF, "Empty gaps over water have no valid site.")


func _check_collection() -> void:
	var game := MatchSimulation.new()
	game.supply_position = game.active_unit().center() + Vector2(0.75, 0.0)
	for tick in range(20):
		game.step(STEP, 1.0)
	_expect(game.supplies == PackedInt32Array([1, 0]) and game.supply_position == Vector2.INF,
		"Walking across the pickup awards it to Blue once.")
	_advance_turn(game)
	_expect(game.turn_number == 2 and game.supply_position == Vector2.INF, "A half round does not respawn it.")
	_advance_turn(game)
	_expect(game.turn_number == 3 and game.supply_position.is_finite(), "A new round can replace an empty pickup.")

	for weapon in [ArtilleryShot.Weapon.ROCKET, ArtilleryShot.Weapon.GRENADE]:
		game.reset()
		game.turn_index = 1
		game.supply_position = Vector2(10.5, 8.0)
		game.fire(0.0, 0.5, weapon)
		game.shot.position = Vector2(11.0, 8.0)
		game.shot.velocity = Vector2(-60.0, 0.0)
		game.shot.launch_offset = Vector2.ZERO
		game.step(STEP)
		_expect(game.supplies == PackedInt32Array([0, 1]) and game.shot != null and game.shot.position.x < 10.5,
			"The swept projectile credits Orange and keeps flying after collection.")
		_expect(game.snapshot_active_turn().supply_position == Vector2.INF, "A CPU forecast cannot consume a supply.")

	game.reset()
	game.terrain.fill_rect(Rect2i(88, 60, 1, 8))
	game.supply_position = Vector2(11.64, 8.0)
	game.fire(0.0, 0.5, ArtilleryShot.Weapon.ROCKET)
	game.shot.position = Vector2(10.5, 8.0)
	game.shot.velocity = Vector2(90.0, 0.0)
	game.shot.launch_offset = Vector2.ZERO
	game.step(STEP)
	_expect(game.supplies[0] == 0 and game.shot == null, "A solid wall blocks collection by projectile.")
	game.reset()
	_expect(game.supplies == PackedInt32Array([0, 0]), "A rematch clears the team supply counts.")


func _advance_turn(game: MatchSimulation) -> void:
	game.pass_turn()
	for tick in range(200):
		if game.phase != MatchSimulation.Phase.RESOLVING:
			return
		game.step(STEP)


func _expect(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
