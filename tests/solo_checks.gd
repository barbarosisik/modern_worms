extends SceneTree

const STEP := 1.0 / 60.0
const APP := preload("res://scenes/main.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_check_snapshot()
	_check_planner()
	await _check_solo_flow()
	for failure in _failures:
		push_error(failure)
	if _failures.is_empty():
		print("PASS: isolated previews, seeded CPU hits and misses, boxed-in pass, pause, timeout, result and rematch")
	quit(0 if _failures.is_empty() else 1)


func _check_snapshot() -> void:
	var game := MatchSimulation.new()
	var preview := game.snapshot_active_turn()
	preview.fire(26.0, 0.86, ArtilleryShot.Weapon.ROCKET)
	_resolve_turn(preview)
	_expect(preview.team_health(1) < 200, "A simulated shot damages the preview team.")
	_expect(game.team_health(1) == 200 and game.shot == null, "Preview damage leaves the live match alone.")
	preview.terrain.cut_disc(Vector2(28.0, 3.75), 0.3)
	_expect(game.terrain.is_solid(Vector2i(224, 30)), "Preview craters leave the live terrain alone.")


func _check_planner() -> void:
	var game := MatchSimulation.new()
	game.pass_turn()
	_resolve_turn(game)
	var planner := ComputerOpponent.new()
	planner.rng.seed = 1
	planner.begin(game)
	_finish_search(planner)
	var plan := planner.chosen_plan
	_expect(plan != null, "The computer finds an opening shot on the normal arena.")
	if plan != null:
		var preview := _resolve_release(plan)
		_expect(preview.team_health(0) < 200 and preview.team_health(0) > 100,
			"A seeded opening can damage Blue without taking half the team health.")
		_expect(preview.team_health(1) == 200, "That opening shot spares Orange.")
		var angle := plan.release_angle
		var power := plan.release_power
		_expect(planner.advance() and plan.release_angle == angle and plan.release_power == power,
			"Advancing again cannot reroll the committed shot.")
	_expect(game.team_health(0) == 200 and game.team_health(1) == 200,
		"Planning a shot does not change either team.")

	planner.rng.seed = 2
	planner.begin(game)
	_finish_search(planner)
	plan = planner.chosen_plan
	_expect(plan != null and _resolve_release(plan).team_health(0) == 200,
		"A planned attack can miss after the release error.")

	_seal_orange_unit(game)
	planner.begin(game)
	_finish_search(planner)
	_expect(planner.chosen_plan == null, "A boxed-in unit has no beneficial shot.")


func _resolve_release(plan: ComputerOpponent.Plan) -> MatchSimulation:
	var preview := plan.position.state.snapshot_active_turn()
	preview.active_unit().facing = plan.facing
	preview.fire(plan.release_angle, plan.release_power, plan.weapon)
	_resolve_turn(preview)
	return preview


func _check_solo_flow() -> void:
	var app := APP.instantiate()
	app.set("settings_path", "user://solo_check_%d.cfg" % OS.get_process_id())
	root.add_child(app)
	_button(app, "%SoloButton")
	var arena := app.get_node("MatchArena") as MatchArena
	arena._computer.rng.seed = 1
	var game := arena.simulation
	_expect(arena.computer_enabled and _visible(app, "%MatchHud"), "The solo button starts player vs CPU.")
	_tap(KEY_P)
	await _wait_for_turn(game, 2, 60)
	_expect(arena.is_computer_turn(), "Orange belongs to the computer.")
	var start := game.active_unit().feet
	var facing := game.active_unit().facing
	_tap(KEY_Q)
	_tap(KEY_P)
	_tap(KEY_SPACE)
	_key(KEY_D, true)
	for tick in range(6):
		await physics_frame
	_key(KEY_D, false)
	_expect(game.phase == MatchSimulation.Phase.ACTIVE and game.active_unit().facing == facing
		and game.active_unit().feet == start, "Keyboard combat controls leave the computer's turn alone.")

	var power := app.get_node("%MatchPower") as ProgressBar
	for tick in range(250):
		await physics_frame
		if power.value > 0.0:
			break
	_expect(power.value > 0.0 and "(CPU)" in (app.get_node("%TurnTitle") as Label).text,
		"The computer's aim and charge are visible.")
	_expect(not arena.trajectory_guide.visible, "The CPU has no dotted guide while aiming.")
	_tap(KEY_ESCAPE)
	var saved_time := game.remaining
	var saved_power := power.value
	for tick in range(10):
		await physics_frame
	_expect(paused and game.remaining == saved_time and power.value == saved_power,
		"Pause freezes the computer's turn and charge.")
	_button(app, "%ResumeButton")
	await _wait_for_turn(game, 3, 570)
	_expect(game.team_health(0) < 200, "The computer fires and hands control back to Blue.")

	_tap(KEY_P)
	await _wait_for_turn(game, 4, 60)
	game.remaining = STEP / 2.0
	await _wait_for_turn(game, 5, 60)
	_expect(game.turn_number == 5 and game.shot == null, "A CPU timeout hands off without a late shot.")

	# A boxed-in CPU must use its normal pass fallback rather than wait out the clock.
	_tap(KEY_ESCAPE)
	_button(app, "%ReturnHome")
	_button(app, "%SoloButton")
	_seal_orange_unit(game)
	_tap(KEY_P)
	await _wait_for_turn(game, 3, 240)
	_expect(game.turn_number == 3 and game.message == "Turn passed.", "A blocked CPU passes promptly.")

	_tap(KEY_ESCAPE)
	_button(app, "%ReturnHome")
	_button(app, "%SoloButton")
	game.units[0].health = 1
	game.units[0].feet = Vector2(25.0, 4.0)
	game.units[2].health = 0
	game.units[3].health = 0
	arena._computer.rng.seed = 1
	_tap(KEY_P)
	for tick in range(630):
		await physics_frame
		if _visible(app, "%ResultScreen"):
			break
	_expect(_visible(app, "%ResultScreen") and game.winner == 1, "A CPU elimination reaches the result.")
	_button(app, "%Rematch")
	_expect(arena.computer_enabled and game.turn_number == 1 and game.team_health(0) == 200
		and game.team_health(1) == 200, "Rematch restores the arena and keeps the solo mode.")
	app.free()


func _seal_orange_unit(game: MatchSimulation) -> void:
	game.terrain.fill_rect(Rect2i(220, 32, 1, 9))
	game.terrain.fill_rect(Rect2i(227, 32, 1, 9))
	game.terrain.fill_rect(Rect2i(220, 40, 8, 1))


func _finish_search(planner: ComputerOpponent) -> void:
	for tick in range(115):
		if planner.advance():
			return
	_expect(false, "The opponent completes its search within the fixed budget.")


func _resolve_turn(game: MatchSimulation) -> void:
	for tick in range(480):
		if game.phase != MatchSimulation.Phase.RESOLVING:
			return
		game.step(STEP)
	_expect(false, "The simulated turn resolves within the test limit.")


func _wait_for_turn(game: MatchSimulation, turn: int, limit: int) -> void:
	for tick in range(limit):
		if game.turn_number >= turn or game.phase == MatchSimulation.Phase.FINISHED:
			return
		await physics_frame
	_expect(false, "Turn %d begins within the test limit." % turn)


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
