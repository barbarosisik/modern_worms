extends SceneTree

const APP := preload("res://scenes/main.tscn")
const STEP := 1.0 / 60.0

var _failures: Array[String] = []
var _checkpoint := "user://campaign_check_%d.cfg" % OS.get_process_id()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 720)
	_check_rescue_order_and_roster()
	await _check_campaign_flow()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_checkpoint))
	for failure in _failures:
		push_error(failure)
	if _failures.is_empty():
		print("PASS: both campaign missions, rescue order, playable recruit, shelter upgrades, checkpoint, retry, and new story")
	quit(0 if _failures.is_empty() else 1)


func _check_rescue_order_and_roster() -> void:
	var run := CampaignRun.new()
	run.begin(PackedInt32Array([0, 1]))
	var game := MatchSimulation.new()
	game.reset(CampaignMission.new(0, run))
	game.units[2].health = 0
	_pass(game)
	_expect(game.phase == MatchSimulation.Phase.ACTIVE and game.active_unit().display_name == "Eli",
		"The lookout can be cleared first and the player still gets a rescue turn.")
	for frame in range(90):
		game.step(STEP, 1.0)
	_expect(game.rescued and game.winner == 0, "Walking to Scout after clearing the lookout wins the mission.")

	game.reset(CampaignMission.new(0, run))
	game.terrain.cut_disc(Vector2(9.0, 2.38), 2.1)
	for frame in range(100):
		game.step(STEP)
	_expect(not game.rescued and game.winner == 1 and not game.rescue_target.alive(),
		"Scout can fall when the bank collapses, and that fails the rescue.")

	run.complete(0, 0)
	game.reset(CampaignMission.new(1, run))
	var order := [game.active_unit().display_name]
	for turn in range(4):
		_pass(game)
		order.append(game.active_unit().display_name)
	_expect(order == ["Mara", "Rigger", "Eli", "Foreman", "Scout"], "Scout takes the third player turn.")
	game.units[0].health = 0
	_pass(game)
	_pass(game)
	_expect(game.active_unit().display_name == "Eli", "The expanded roster skips an eliminated lead.")


func _check_campaign_flow() -> void:
	var app := _open_app()
	await process_frame
	_press(app, "NewStory")
	var wardrobe := app.find_child("MaraOutfit", true, false) as OptionButton
	wardrobe.select(2)
	wardrobe.item_selected.emit(2)
	_press(app, "BeginStory")
	_press(app, "StartMission")
	var arena := app.get_node("MatchArena") as MatchArena
	var game := arena.simulation
	var run: CampaignRun = app.campaign
	_expect(arena.computer_enabled and game.active_unit().outfit == 2 and game.rescue_target != null,
		"The new-story flow applies the outfit and starts the rescue against the computer.")
	_expect(game.supply_position.distance_to(game.rescue_target.center()) >= SupplyPickup.UNIT_CLEARANCE,
		"The supply marker leaves Scout's rescue area clear.")
	await _hold(KEY_D, 90)
	await _frames(12)
	_expect(game.rescued and game.phase == MatchSimulation.Phase.ACTIVE, "Moving through the marker rescues Scout.")
	await _hold(KEY_D, 22)
	await _frames(9)
	_drag_shot(arena, 1.0, 72.0, 0.32, ArtilleryShot.Weapon.GRENADE)
	await _wait_for_result(app, 540)
	_expect(game.winner == 0 and run.cleared == 1 and run.supplies >= CampaignRun.CLEAR_REWARD,
		"A real grenade clears the lookout and banks the first mission reward.")
	if run.cleared != 1:
		app.free()
		return

	_press(app, "Rematch")
	var shelter := app.get_node("CampaignShelter") as CampaignShelter
	_expect(shelter.visible and shelter.camera.current, "The result opens the walkable shelter.")
	await _hold(KEY_D, 83)
	_tap(KEY_E)
	_expect(paused and app.find_child("BuyKits", true, false) != null, "E at the bench opens team upgrades.")
	var wallet := run.supplies
	_press(app, "BuyKits")
	_press(app, "BuyKits")
	_expect(run.field_kits and run.supplies == wallet - 1, "A field kit can be bought once.")
	_tap(KEY_ESCAPE)
	await _hold(KEY_D, 73)
	_tap(KEY_E)
	var tabs := app.find_child("RosterTabs", true, false) as TabBar
	if tabs == null:
		_expect(false, "E at the roster board opens character upgrades.")
		app.free()
		return
	_expect(tabs.tab_count == 3 and tabs.get_tab_title(2) == "Scout", "The roster includes the rescued dog.")
	tabs.current_tab = 1
	_press(app, "BuyGuide")
	_expect(run.guide_tiers == PackedInt32Array([0, 1, 0]) and run.supplies == wallet - 2,
		"Training Eli spends one supply and changes only Eli's guide.")

	app.free()
	app = _open_app()
	await process_frame
	run = app.campaign
	_expect(run.cleared == 1 and run.field_kits and run.guide_tiers[1] == 1 and run.outfits[0] == 2,
		"Reopening the game restores the checkpoint, purchases, and outfit.")
	_press(app, "ContinueStory")
	_tap(KEY_E)
	_press(app, "StartMission")
	arena = app.get_node("MatchArena") as MatchArena
	game = arena.simulation
	_expect(game.units.size() == 5 and game.team_health(0) == 345 and game.units[1].guide_tier == 1,
		"The ferry starts with Scout and both purchases applied to the correct units.")
	_expect("Scout" in (app.get_node("%PlayerQueue") as Label).text, "The mission HUD lists Scout in the queue.")
	wallet = run.supplies
	game.supplies[0] = 4
	game.units[1].health = 0
	game.units[2].health = 0
	game.active_unit().feet = Vector2(0.0, 0.81)
	await _wait_for_result(app, 90)
	_expect(game.winner == 1 and run.cleared == 1 and run.supplies == wallet,
		"A failed attempt keeps the checkpoint and awards no battle supplies.")
	_press(app, "Rematch")
	_expect(game.turn_number == 1 and game.team_health(0) == 345 and game.supplies[0] == 0
		and game.units[1].guide_tier == 1, "Retry restores the ferry and the saved loadout.")

	await _play_ferry(arena)
	_expect(game.winner == 0 and run.finished(), "The ferry fight reaches the chapter result.")
	_press(app, "Rematch")
	_tap(KEY_E)
	_expect(app.find_child("StartMission", true, false) == null, "The cleared chapter shows its map without a replay button.")
	_tap(KEY_ESCAPE)
	_tap(KEY_ESCAPE)
	_press(app, "ReturnHome")
	_press(app, "NewStory")
	_press(app, "BeginStory")
	_expect(run.cleared == 0 and run.supplies == 0 and not run.field_kits
		and run.guide_tiers == PackedInt32Array([0, 0, 0]) and run.outfits[0] == 2,
		"New story resets progress and skills while keeping the chosen look.")
	app.free()


func _play_ferry(arena: MatchArena) -> void:
	arena._computer.rng.seed = 1
	var driver := ComputerOpponent.new()
	driver.rng.seed = 3
	driver.error_scale = 0.0
	var game := arena.simulation
	for turn in range(16):
		if game.phase == MatchSimulation.Phase.FINISHED:
			return
		if game.phase == MatchSimulation.Phase.ACTIVE and not arena.is_computer_turn():
			driver.begin(game)
			while not driver.advance():
				pass
			var plan := driver.chosen_plan
			if plan == null:
				_tap(KEY_P)
			else:
				var axis := plan.position.move_axis
				if not is_zero_approx(axis):
					await _hold(KEY_D if axis > 0.0 else KEY_A, ComputerOpponent.WALK_TICKS)
					await _frames(ComputerOpponent.STOP_TICKS)
				_drag_shot(arena, plan.facing, plan.release_angle, plan.release_power, plan.weapon)
		var previous := game.turn_number
		for frame in range(600):
			if game.turn_number != previous or game.phase == MatchSimulation.Phase.FINISHED:
				break
			await physics_frame


func _drag_shot(arena: MatchArena, facing: float, angle: float, power: float, weapon: ArtilleryShot.Weapon) -> void:
	_tap(KEY_1 if weapon == ArtilleryShot.Weapon.ROCKET else KEY_2)
	var target := Vector3(12.5, 8.5, 0.0)
	var radians := deg_to_rad(angle)
	var direction := Vector3(cos(radians) * facing, sin(radians), 0.0)
	var start := arena.camera.unproject_position(target)
	var pull := arena.camera.unproject_position(target - direction) - start
	var size := root.get_visible_rect().size
	var maximum := minf(size.x, size.y) * AimControls.FULL_PULL_FRACTION
	var length := lerpf(maximum * AimControls.DEAD_ZONE_FRACTION, maximum, power)
	_pointer(start, true)
	_pointer(start + pull.normalized() * length, false)


func _open_app() -> Node:
	var app := APP.instantiate()
	app.set("settings_path", "user://campaign_settings_%d.cfg" % OS.get_process_id())
	app.set("campaign_checkpoint_path", _checkpoint)
	root.add_child(app)
	return app


func _wait_for_result(app: Node, limit: int) -> void:
	for frame in range(limit):
		if (app.get_node("%ResultScreen") as Control).visible:
			return
		await physics_frame
	_expect(false, "The mission reaches a result.")


func _pass(game: MatchSimulation) -> void:
	game.pass_turn()
	for frame in range(120):
		if game.phase != MatchSimulation.Phase.RESOLVING:
			return
		game.step(STEP)


func _press(app: Node, button: String) -> void:
	var control := app.find_child(button, true, false) as Button
	if control == null:
		_expect(false, "Expected button " + button)
		return
	control.pressed.emit()


func _frames(count: int) -> void:
	for frame in range(count):
		await physics_frame


func _hold(key: Key, count: int) -> void:
	_key(key, true)
	await _frames(count)
	_key(key, false)


func _tap(key: Key) -> void:
	_key(key, true)
	_key(key, false)


func _key(key: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _pointer(position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = position
	event.global_position = position
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _expect(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
