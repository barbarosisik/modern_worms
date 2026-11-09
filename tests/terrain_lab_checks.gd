extends SceneTree

const STEP := 1.0 / 60.0
const APP := preload("res://scenes/main.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_check_fixture()
	await _check_menus()
	if _failures.is_empty():
		print("PASS: two-shot fixture, sweep, reset, menu navigation, pause, and saved settings")
	else:
		for failure in _failures:
			push_error(failure)
	quit(0 if _failures.is_empty() else 1)


func _check_fixture() -> void:
	var simulation := TerrainSimulation.new()
	var first_run: Array[Vector2] = []
	for attempt in range(2):
		_expect(simulation.terrain.is_solid(Vector2i(104, 52)), "Reset restores the ledge.")
		_expect(simulation.target_feet == TerrainSimulation.TARGET_START, "Reset restores target.")
		simulation.fire(TerrainSimulation.PRESET_VELOCITY)
		_expect(not simulation.fire(Vector2.ZERO), "Only one rocket can be active.")
		_finish_rocket(simulation)
		var first := simulation.last_impact
		_expect(is_equal_approx(first.x, 12.0), "First shot strikes the front of the ledge.")
		_expect(not simulation.terrain.is_solid(Vector2i(104, 52)), "Cut clears target support.")
		_expect(Vector2i(3, 1) in simulation.dirty_chunks, "The ledge chunk is rebuilt.")
		_expect(Vector2i(2, 1) in simulation.dirty_chunks, "The adjacent seam chunk is rebuilt.")
		for tick in range(90):
			simulation.step(STEP)
		_expect(is_equal_approx(simulation.target_feet.y, 2.0), "Target falls and settles.")
		simulation.fire(TerrainSimulation.PRESET_VELOCITY)
		_finish_rocket(simulation)
		var second := simulation.last_impact
		_expect(is_equal_approx(second.x, 24.0), "Same shot reaches rear wall through the cut.")
		_expect(simulation.terrain.is_solid(Vector2i(16, 14)), "Distant floor remains solid.")
		var result: Array[Vector2] = [first, second, simulation.target_feet]
		if attempt == 0:
			first_run = result
		else:
			_expect(result == first_run, "Reset reproduces both impacts and the final target.")
		simulation.reset()

	simulation.fire(Vector2(0.0, 40.0))
	_finish_rocket(simulation)
	_expect(simulation.last_result == ArtilleryShot.Result.ESCAPED, "An escaped rocket releases input.")
	simulation.fire(TerrainSimulation.PRESET_VELOCITY)
	simulation.step(STEP)
	simulation.reset()
	_expect(simulation.rocket == null and simulation.last_impact == Vector2.INF, "Reset cancels flight.")

	var grid := TerrainGrid.new()
	grid.fill_rect(Rect2i(61, 7, 1, 12))
	var hit := grid.first_contact(Vector2(5.0, 1.5), Vector2(10.0, 1.5))
	_expect(hit.is_equal_approx(Vector2(61 * TerrainGrid.CELL_SIZE, 1.5)), "Sweep hits one-cell wall.")
	var corner_grid := TerrainGrid.new()
	corner_grid.fill_rect(Rect2i(1, 0, 1, 1))
	var corner := corner_grid.first_contact(Vector2(0.0625, 0.0625), Vector2(0.25, 0.25))
	_expect(corner.is_equal_approx(Vector2(0.125, 0.125)), "A solid corner blocks the ray.")


func _finish_rocket(simulation: TerrainSimulation) -> void:
	for tick in range(420):
		if simulation.rocket == null:
			return
		simulation.step(STEP)
	_expect(false, "Rocket resolves before the test's time limit.")


func _check_menus() -> void:
	var config_path := "user://settings_verification_%d.cfg" % OS.get_process_id()
	var app := APP.instantiate()
	app.set("settings_path", config_path)
	root.add_child(app)
	_expect(paused and _visible(app, "%Home"), "Starts on the main menu.")
	_press(app, "%HomeSettings")
	_expect(_visible(app, "%Settings"), "Settings open from the main menu.")
	var slider := app.get_node("%Volume") as HSlider
	slider.value = 23.0
	_press(app, "%ApplyButton")
	var master := AudioServer.get_bus_index("Master")
	_expect(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(master)), 0.23),
		"Apply changes the actual master bus volume.")
	var config := ConfigFile.new()
	_expect(config.load(config_path) == OK and config.get_value("options", "volume", -1) == 23,
		"Apply writes settings to disk.")
	_press(app, "%BackButton")
	_expect(_visible(app, "%Home"), "Back returns to the main menu.")

	_press(app, "%StartButton")
	var lab := app.get_node("TerrainLab") as TerrainLab
	_expect(not paused and _visible(app, "%Hud"), "Start opens the lab and unpauses it.")
	_key(KEY_F)
	await physics_frame
	await physics_frame
	_expect(lab.simulation.rocket != null, "The F key launches the fixture rocket.")
	_key(KEY_ESCAPE)
	_expect(paused and _visible(app, "%PauseScreen"), "Escape opens the pause menu.")
	if lab.simulation.rocket != null:
		var position := lab.simulation.rocket.position
		for tick in range(4):
			await physics_frame
		_expect(lab.simulation.rocket.position == position, "A paused rocket stays frozen.")
	_press(app, "%PauseSettings")
	_expect(paused and _visible(app, "%Settings"), "Settings opened from pause keep the lab paused.")
	slider.value = 100.0
	_press(app, "%BackButton")
	_expect(_visible(app, "%PauseScreen"), "Settings return to pause when opened from pause.")
	_press(app, "%ResumeButton")
	_expect(not paused and _visible(app, "%Hud"), "Resume continues the lab.")
	for tick in range(100):
		await physics_frame
	_expect(is_equal_approx(lab.simulation.last_impact.x, 12.0), "Resumed shot hits the ledge.")
	_key(KEY_R)
	_expect(lab.simulation.target_feet == TerrainSimulation.TARGET_START, "R resets the fixture.")
	_key(KEY_F1)
	var outline := lab.get_node("CollisionOutline") as MeshInstance3D
	_expect(outline.visible and outline.mesh != null, "F1 shows the terrain collision outline.")
	_send_key(KEY_UP, true)
	_send_key(KEY_SPACE, true)
	for tick in range(15):
		await physics_frame
	_send_key(KEY_UP, false)
	var power := app.get_node("%Power") as ProgressBar
	_expect(power.value > 0.0, "Holding Space charges the manual shot.")
	_send_key(KEY_SPACE, false)
	_expect(lab.simulation.rocket != null and lab.simulation.rocket.velocity.y > 0.0,
		"Releasing Space launches a rocket at the selected upward angle.")
	_key(KEY_R)
	_expect(lab.simulation.rocket == null and not outline.visible, "Reset clears flight and overlay.")
	_key(KEY_ESCAPE)
	_press(app, "%ReturnHome")
	_expect(_visible(app, "%Home"), "Pause menu can return to the main menu.")
	app.free()

	var reopened := APP.instantiate()
	reopened.set("settings_path", config_path)
	root.add_child(reopened)
	_press(reopened, "%HomeSettings")
	var restored := reopened.get_node("%Volume") as HSlider
	_expect(restored.value == 23.0, "A new session restores the saved value, not the unsaved edit.")
	reopened.free()
	if FileAccess.file_exists(config_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(config_path))


func _key(code: Key) -> void:
	_send_key(code, true)
	_send_key(code, false)


func _send_key(code: Key, pressed: bool) -> void:
	var key := InputEventKey.new()
	key.physical_keycode = code
	key.keycode = code
	key.pressed = pressed
	Input.parse_input_event(key)
	Input.flush_buffered_events()


func _press(app: Node, node_path: NodePath) -> void:
	(app.get_node(node_path) as Button).pressed.emit()


func _visible(app: Node, node_path: NodePath) -> bool:
	return (app.get_node(node_path) as Control).visible


func _expect(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
