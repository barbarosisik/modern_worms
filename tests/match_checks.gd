extends SceneTree

const STEP := 1.0 / 60.0
const APP := preload("res://scenes/main.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_check_rotation_and_movement()
	_check_weapons_and_results()
	await _check_game_entry()
	for failure in _failures:
		push_error(failure)
	if _failures.is_empty():
		print("PASS: movement, turns, rockets, grenades, elimination, pause, result, and rematch")
	quit(0 if _failures.is_empty() else 1)


func _check_rotation_and_movement() -> void:
	var game := MatchSimulation.new()
	var active := game.active_unit()
	var initial_feet := active.feet
	var enemy_feet := game.units[1].feet
	for tick in range(20):
		game.step(STEP, 1.0, tick == 9)
	_expect(active.feet.x > initial_feet.x and active.feet.y > initial_feet.y, "Active unit walks and jumps.")
	_expect(game.units[1].feet == enemy_feet, "Movement leaves the other team in place.")
	game.pass_turn()
	_expect(game.phase == MatchSimulation.Phase.RESOLVING, "Pass waits for the jumping unit.")
	_advance_until_settled(game)
	_expect(game.turn_index == 1 and game.turn_number == 2, "Blue 1 hands off to Orange 1.")
	game.remaining = STEP / 2.0
	game.step(STEP)
	_expect(game.phase == MatchSimulation.Phase.RESOLVING, "The turn clock expires.")
	_advance_until_settled(game)
	_expect(game.turn_index == 2, "Timeout hands off to Blue 2.")
	game.units[3].health = 0
	game.pass_turn()
	_advance_until_settled(game)
	_expect(game.turn_index == 1, "Rotation skips the eliminated Orange 2.")
	game.pass_turn()
	_advance_until_settled(game)
	_expect(game.turn_index == 0, "Blue rotates back to Blue 1.")


func _check_weapons_and_results() -> void:
	var game := MatchSimulation.new()
	game.fire(26.0, 0.86, ArtilleryShot.Weapon.ROCKET)
	_advance_until_settled(game)
	_expect(game.team_health(1) < 200, "An opening shot can reach Orange across the actual map.")
	game.reset()
	var enemy := game.units[1]
	enemy.feet = Vector2(6.0, 4.0)
	var original := enemy.feet
	_expect(game.fire(0.0, 0.0, ArtilleryShot.Weapon.ROCKET), "The first rocket launches.")
	_expect(not game.fire(0.0, 0.0, ArtilleryShot.Weapon.ROCKET), "Cannot fire twice in one turn.")
	_advance_until_settled(game)
	_expect(enemy.health < MatchUnit.MAX_HEALTH, "The rocket damages an opposing unit.")
	_expect(enemy.feet != original, "Damage also causes knockback.")
	_expect(not game.terrain.is_solid(Vector2i(45, 30)), "The blast removes terrain.")
	_expect(game.turn_number == 2, "The next turn starts after the impact settles.")

	var grenade := ArtilleryShot.new(Vector2(5.0, 5.0), Vector2(0.8, -2.0), ArtilleryShot.Weapon.GRENADE)
	grenade.gravity = 13.0
	var terrain := TerrainGrid.new()
	terrain.fill_rect(Rect2i(0, 0, TerrainGrid.SIZE.x, 32))
	var bounced := false
	var result := ArtilleryShot.Result.FLYING
	for tick in range(180):
		result = grenade.step(STEP, terrain)
		bounced = bounced or grenade.velocity.y > 0.1
		if result != ArtilleryShot.Result.FLYING:
			break
	_expect(bounced, "A grenade rebounds from terrain.")
	_expect(result == ArtilleryShot.Result.IMPACT and grenade.age >= ArtilleryShot.FUSE_SECONDS,
		"The grenade detonates after the fuse, including when it comes to rest.")

	game.reset()
	game.units[1].feet = Vector2(6.0, 4.0)
	game.units[1].health = 1
	game.units[3].health = 0
	game.fire(0.0, 0.0, ArtilleryShot.Weapon.ROCKET)
	_advance_until_settled(game)
	_expect(game.phase == MatchSimulation.Phase.FINISHED and game.winner == 0,
		"A lethal hit on the last Orange unit produces a Blue win.")
	game.reset()
	game.units[2].health = 0
	game.units[0].feet = Vector2(10.8, 0.83)
	for tick in range(12):
		game.step(STEP)
	_advance_until_settled(game)
	_expect(game.phase == MatchSimulation.Phase.FINISHED and game.winner == 1,
		"Water eliminates the last Blue unit and awards the match to Orange.")

	game.reset()
	_walk_off_outer_edge(game)
	_expect(game.turn_index == 1 and game.team_health(0) == 100, "Walking off the island costs a unit.")
	game.pass_turn()
	_advance_until_settled(game)
	_walk_off_outer_edge(game)
	_expect(game.phase == MatchSimulation.Phase.FINISHED and game.winner == 1,
		"A match can reach its result from a fresh arena using only legal inputs.")


func _walk_off_outer_edge(game: MatchSimulation) -> void:
	for tick in range(230):
		game.step(STEP, -1.0)
		if game.phase != MatchSimulation.Phase.ACTIVE:
			break
	_advance_until_settled(game)


func _check_game_entry() -> void:
	var app := APP.instantiate()
	app.set("settings_path", "user://match_check_%d.cfg" % OS.get_process_id())
	root.add_child(app)
	_button(app, "%MatchButton")
	var arena := app.get_node("MatchArena") as MatchArena
	var lab := app.get_node("TerrainLab") as TerrainLab
	var game := arena.simulation
	_expect(_visible(app, "%MatchHud") and not paused, "Main menu starts the local match.")
	_expect(arena.camera.current and not lab.visible, "The match takes over the camera.")
	var initial := game.active_unit().feet
	_key(KEY_D, true)
	for tick in range(12):
		await physics_frame
	_key(KEY_D, false)
	_expect(game.active_unit().feet.x > initial.x, "The D key moves the active unit.")
	_tap(KEY_2)
	await physics_frame
	await physics_frame
	_expect("Grenade" in (app.get_node("%WeaponStatus") as Label).text, "The 2 key selects the grenade.")
	_key(KEY_SPACE, true)
	for tick in range(20):
		await physics_frame
	_key(KEY_SPACE, false)
	_expect(game.shot != null and game.shot.weapon == ArtilleryShot.Weapon.GRENADE,
		"Charging and releasing Space fires the selected weapon.")
	_tap(KEY_ESCAPE)
	_expect(paused and _visible(app, "%PauseScreen"), "Escape pauses the match.")
	if game.shot != null:
		var position := game.shot.position
		for tick in range(4):
			await physics_frame
		_expect(game.shot.position == position, "Pause freezes the projectile.")
	_button(app, "%ResumeButton")
	_expect(_visible(app, "%MatchHud") and not paused, "Resume returns to the match HUD.")
	for tick in range(520):
		await physics_frame
		if game.phase != MatchSimulation.Phase.RESOLVING:
			break
	_expect(game.turn_number == 2, "The grenade resolves and hands off the turn.")

	_tap(KEY_ESCAPE)
	_button(app, "%ReturnHome")
	_button(app, "%MatchButton")
	game.units[1].feet = Vector2(6.0, 4.0)
	game.units[1].health = 1
	game.units[3].health = 0
	game.fire(0.0, 0.0, ArtilleryShot.Weapon.ROCKET)
	for tick in range(400):
		await physics_frame
		if paused:
			break
	_expect(_visible(app, "%ResultScreen") and paused, "The match shows its result screen.")
	_expect((app.get_node("%ResultTitle") as Label).text == "Blue wins", "The result names the winner.")
	_button(app, "%Rematch")
	_expect(not paused and game.turn_number == 1 and game.team_health(1) == 200,
		"Rematch resets turns and restores all units.")
	app.free()


func _advance_until_settled(game: MatchSimulation) -> void:
	for tick in range(600):
		if game.phase != MatchSimulation.Phase.RESOLVING:
			return
		game.step(STEP)
	_expect(false, "The turn resolves within the test limit.")


func _tap(key: Key) -> void:
	_key(key, true)
	_key(key, false)


func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _button(app: Node, path: NodePath) -> void:
	(app.get_node(path) as Button).pressed.emit()


func _visible(app: Node, path: NodePath) -> bool:
	return (app.get_node(path) as Control).visible


func _expect(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
