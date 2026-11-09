extends SceneTree

const APP := preload("res://scenes/main.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_check_charge()
	_check_path()
	await _check_controls()
	for failure in _failures:
		push_error(failure)
	if _failures.is_empty():
		print("PASS: drag aiming and power, keyboard charge, GUI and turn ownership, and fading guide tiers")
	quit(0 if _failures.is_empty() else 1)


func _check_charge() -> void:
	var aim := AimControls.new()
	aim.begin_keyboard()
	for tick in range(1, 402):
		aim.tick()
		var expected := 100 - absi(100 - tick % 200)
		_expect(aim.charge == expected, "The power meter advances one point at tick %d." % tick)
	aim.cancel()
	aim.tick()
	_expect(aim.power() == 0.0, "Cancelled charge stays at zero.")


func _check_path() -> void:
	var terrain := TerrainGrid.new()
	terrain.fill_rect(Rect2i(40, 0, 1, 96))
	var shot := ArtilleryShot.new(Vector2(4.0, 7.0), Vector2(10.0, 0.0))
	var points := TrajectoryGuide.sample(shot, terrain, PackedVector2Array(), 18)
	_expect(points.size() == 1 and shot.position.x == 5.0 and points[0].x < shot.position.x,
		"The guide stops at the same thin wall as the projectile.")
	var open := TerrainGrid.new()
	shot = ArtilleryShot.new(Vector2(4.0, 7.0), Vector2(10.0, 0.0))
	points = TrajectoryGuide.sample(shot, open, PackedVector2Array([Vector2(6.0, 7.0)]), 18)
	_expect(points.size() < 6 and shot.position.x < 6.0, "The rocket guide stops at an actor.")
	open.fill_rect(Rect2i(0, 0, TerrainGrid.SIZE.x, 30))
	shot = ArtilleryShot.new(Vector2(4.0, 4.7), Vector2(10.0, -4.0), ArtilleryShot.Weapon.GRENADE)
	points = TrajectoryGuide.sample(shot, open, PackedVector2Array(), 18)
	_expect(points.size() == 18 and points[9].y > points[5].y,
		"The extended grenade guide follows a bounce.")


func _check_controls() -> void:
	root.size = Vector2i(1280, 720)
	var app := APP.instantiate()
	app.set("settings_path", "user://aim_check_%d.cfg" % OS.get_process_id())
	root.add_child(app)
	await process_frame
	_click(app.get_node("%MatchButton"))
	await physics_frame
	var arena := app.get_node("MatchArena") as MatchArena
	var game := arena.simulation
	var guide := arena.trajectory_guide
	var power := app.get_node("%MatchPower") as ProgressBar
	_expect(not paused and game.shot == null, "The click starting a match does not fire a shot.")
	var point := Vector2(620.0, 280.0)
	var strong_pull := point + Vector2(205.0, 115.0)
	var medium_pull := point + Vector2(130.0, 78.0)
	_mouse_button(point, true)
	_mouse_button(point + Vector2.ONE, false)
	_expect(game.shot == null, "A stationary click inside the dead zone does not fire.")

	_mouse_button(point, true)
	_mouse_motion(strong_pull)
	await physics_frame
	await physics_frame
	_expect(power.value == 1.0, "Pulling far enough reaches full power.")
	_expect(_visible_dots(guide) == 12, "Blue starts with up to twelve unobstructed dots.")
	var near_dot := guide.get_child(0) as MeshInstance3D
	var far_dot := guide.get_child(11) as MeshInstance3D
	_expect(near_dot.material_override.albedo_color.a > far_dot.material_override.albedo_color.a,
		"The last dot fades relative to the first.")
	_mouse_motion(medium_pull)
	await physics_frame
	await physics_frame
	var released_power := power.value
	_expect(released_power > 0.75 and released_power < 0.9, "Moving closer to the anchor lowers power.")
	for tick in range(25):
		await physics_frame
	_expect(power.value == released_power and game.shot == null, "Holding still preserves the selected power.")
	_mouse_button(medium_pull, false)
	_expect(game.shot != null and game.shot.velocity.x < 0.0 and game.shot.velocity.y > 0.0
		and is_equal_approx(game.shot.velocity.length(), lerpf(6.0, 18.0, released_power)),
		"Release fires opposite the pull at the displayed power.")
	for tick in range(460):
		if game.turn_number == 2:
			break
		await physics_frame
	await physics_frame
	_expect(game.turn_number == 2 and _visible_dots(guide) == 0, "Local Orange can aim without guide dots.")

	_mouse_button(point, true)
	_mouse_motion(strong_pull)
	await physics_frame
	_tap(KEY_ESCAPE)
	_mouse_button(strong_pull, false)
	_expect(paused and game.shot == null, "Pausing mid-charge cancels the shot.")
	await process_frame
	_click(app.get_node("%ResumeButton"))
	await physics_frame
	await physics_frame
	_expect(not paused and game.shot == null and power.value == 0.0, "A resume click leaves power at zero.")
	_mouse_button(point, true)
	_mouse_motion(strong_pull)
	await physics_frame
	root.focus_exited.emit()
	_mouse_button(strong_pull, false)
	_expect(game.shot == null, "Losing focus cancels the held shot.")
	_mouse_button(point, true)
	_mouse_motion(strong_pull)
	game.remaining = 0.001
	for tick in range(40):
		await physics_frame
	_mouse_button(strong_pull, false)
	_expect(game.turn_number == 3 and game.shot == null, "A held shot expires with its original turn.")
	_click(app.get_node("%MatchPauseButton"))
	_expect(paused and game.shot == null, "Clicking the HUD Pause button never fires.")
	_click(app.get_node("%ReturnHome"))
	_click(app.get_node("%StartButton"))
	var lab := app.get_node("TerrainLab") as TerrainLab
	for tier in range(1, TrajectoryGuide.DOT_COUNTS.size()):
		_tap(KEY_G)
	await physics_frame
	await physics_frame
	_expect(_visible_dots(lab.trajectory_guide) == 20, "The terrain lab previews the 20-dot tier.")
	app.free()


func _visible_dots(guide: TrajectoryGuide) -> int:
	var count := 0
	for dot in guide.get_children():
		if dot.is_visible_in_tree():
			count += 1
	return count


func _click(button: Button) -> void:
	var position := button.get_global_rect().get_center()
	_mouse_button(position, true)
	_mouse_button(position, false)


func _mouse_button(position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = position
	event.global_position = position
	event.pressed = pressed
	_send(event)


func _mouse_motion(position: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = position
	event.global_position = position
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	_send(event)


func _tap(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = pressed
		_send(event)


func _send(event: InputEvent) -> void:
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _expect(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
