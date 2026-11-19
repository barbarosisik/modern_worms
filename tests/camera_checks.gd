extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var app := preload("res://scenes/main.tscn").instantiate()
	app.settings_path = "user://camera_check_%d.cfg" % OS.get_process_id()
	app.campaign_checkpoint_path = "user://camera_checkpoint_%d.cfg" % OS.get_process_id()
	root.add_child(app)
	app._start_match()
	await process_frame
	var arena: MatchArena = app.arena
	var camera := arena.camera
	var opening := camera.transform
	var anchor := Vector2(850, 300)
	var end := Vector2(300, 340)
	var grabbed := AimControls._point_on_plane(camera, anchor)
	var unit_feet := arena.simulation.units[0].feet
	_button(MOUSE_BUTTON_MIDDLE, anchor, true)
	_motion(end)
	_expect(AimControls._point_on_plane(camera, end).distance_to(grabbed) < 0.01,
		"Dragging follows the grabbed map point at the current zoom.")
	_expect(camera.position.x > opening.origin.x, "Dragging left reveals the right side of the map.")
	var enemy := arena.simulation.units[1]
	var enemy_screen := camera.unproject_position(Vector3(enemy.feet.x, enemy.feet.y + 0.5, 0))
	_expect(Rect2(0, 180, 1280, 400).has_point(enemy_screen), "Panning reveals the initially off-screen enemy.")
	_button(MOUSE_BUTTON_MIDDLE, Vector2(20, 20), false)
	var after_pan := camera.transform
	_motion(end + Vector2(100, 0))
	_expect(camera.transform == after_pan, "Releasing over the HUD ends camera dragging.")
	_expect(arena.simulation.shot == null and arena.simulation.units[0].feet == unit_feet
		and not arena._aim_controls.is_aiming(), "Camera dragging never fires or moves a character.")

	_home()
	_button(MOUSE_BUTTON_LEFT, anchor, true, true)
	_motion(end)
	_button(MOUSE_BUTTON_LEFT, end, false)
	_expect(camera.position.x > opening.origin.x and arena.simulation.shot == null
		and not arena._aim_controls.is_aiming(), "Shift-left drag pans even if Shift is released first.")
	_home()
	_expect(camera.transform == opening and camera.fov == MatchArena.START_CAMERA_FOV, "Home restores position and zoom.")
	for drag in range(4):
		_button(MOUSE_BUTTON_MIDDLE, Vector2(1100, 200), true)
		_motion(Vector2(100, 550))
		_button(MOUSE_BUTTON_MIDDLE, end, false)
	var limit := AimControls._point_on_plane(camera, Vector2(640, 360))
	_expect(limit.distance_to(TerrainGrid.WORLD_SIZE) < 0.001, "The view centre stops at the far map bounds: %s." % limit)
	for drag in range(4):
		_button(MOUSE_BUTTON_MIDDLE, Vector2(100, 550), true)
		_motion(Vector2(1100, 200))
		_button(MOUSE_BUTTON_MIDDLE, end, false)
	limit = AimControls._point_on_plane(camera, Vector2(640, 360))
	_expect(limit.distance_to(Vector2.ZERO) < 0.001, "The view centre stops at the near map bounds: %s." % limit)
	_home()

	_button(MOUSE_BUTTON_LEFT, anchor, true)
	_button(MOUSE_BUTTON_MIDDLE, anchor, true)
	_motion(end)
	_button(MOUSE_BUTTON_MIDDLE, end, false)
	_expect(camera.transform == opening, "Camera dragging stays locked while aiming a mouse shot.")
	_button(MOUSE_BUTTON_RIGHT, end, true)
	_button(MOUSE_BUTTON_RIGHT, end, false)
	_button(MOUSE_BUTTON_LEFT, end, false)
	_button(MOUSE_BUTTON_MIDDLE, anchor, true)
	root.focus_exited.emit()
	_motion(end)
	_button(MOUSE_BUTTON_MIDDLE, end, false)
	_expect(camera.transform == opening, "Focus loss clears a held camera drag.")

	arena.computer_enabled = true
	arena.simulation.turn_index = 1
	_button(MOUSE_BUTTON_MIDDLE, anchor, true)
	_motion(end)
	_button(MOUSE_BUTTON_MIDDLE, end, false)
	_expect(camera.position.x > opening.origin.x, "Camera panning works during the CPU turn.")
	_button(MOUSE_BUTTON_WHEEL_DOWN, end, true)
	_expect(camera.fov > MatchArena.START_CAMERA_FOV, "Zoom works during the CPU turn.")
	_home()
	arena.simulation.phase = MatchSimulation.Phase.RESOLVING
	_button(MOUSE_BUTTON_MIDDLE, anchor, true)
	_motion(end)
	_expect(camera.position.x > opening.origin.x, "Camera panning works while a shot resolves.")
	app._pause_game()
	var paused_camera := camera.transform
	app._resume_game()
	_motion(anchor)
	_expect(camera.transform == paused_camera, "Pause clears camera dragging, including during CPU turns.")
	_button(MOUSE_BUTTON_MIDDLE, anchor, false)
	_home()
	_button(MOUSE_BUTTON_MIDDLE, anchor, true)
	app._start_match()
	_motion(end)
	_expect(camera.transform == opening, "A new match clears camera dragging and restores its opening view.")
	_button(MOUSE_BUTTON_MIDDLE, end, false)

	# Starting over a GUI button must stay owned by the interface.
	var button: Button = app._weapon_buttons[1]
	var button_point := button.get_global_rect().get_center()
	_button(MOUSE_BUTTON_LEFT, button_point, true, true)
	_button(MOUSE_BUTTON_LEFT, button_point, false)
	_motion(end)
	_expect(camera.transform == opening and arena._weapon == ArtilleryShot.Weapon.GRENADE,
		"Shift-clicking a weapon button selects it without starting a camera drag.")
	await _check_shot_follow(app)
	app.free()
	for failure in _failures:
		push_error(failure)
	if _failures.is_empty():
		print("PASS: camera pan, aiming lock, rocket and grenade follow, impact, turn framing, shotgun and manual takeover")
	quit(0 if _failures.is_empty() else 1)


func _check_shot_follow(app: Node) -> void:
	app._start_match()
	var arena: MatchArena = app.arena
	var game := arena.simulation
	var camera := arena.camera
	var opening := camera.transform
	_fire(arena, ArtilleryShot.Weapon.ROCKET, 43.0)
	var moved_in_flight := false
	var saw_blast := false
	for tick in range(285):
		await physics_frame
		if game.shot != null and game.shot.position.x > 29.0:
			moved_in_flight = moved_in_flight or camera.position.x > opening.origin.x + 2.0
			_expect(_in_view(camera, game.shot.position), "A long rocket stays visible during flight.")
		if game.last_blast != Vector2.INF:
			saw_blast = true
			_expect(_in_view(camera, game.last_blast), "The rocket's impact stays in view.")
		if game.turn_number > 1:
			break
	_expect(moved_in_flight and saw_blast and game.turn_number > 1,
		"The camera travels across the arena for a long rocket and reaches resolution.")
	for tick in range(70):
		await physics_frame
	var next_screen := camera.unproject_position(Vector3(game.active_unit().feet.x, game.active_unit().center().y, 0.0))
	_expect(Rect2(525, 284, 230, 148).has_point(next_screen),
		"The view eases toward the new unit after the shot settles.")
	_expect(camera.basis == opening.basis and camera.fov == MatchArena.START_CAMERA_FOV,
		"Following a shot keeps the same camera angle and zoom.")

	app._start_match()
	_fire(arena, ArtilleryShot.Weapon.GRENADE, 43.0)
	var bounced := false
	var falling := false
	var saw_fuse := false
	for tick in range(155):
		await physics_frame
		if game.shot != null:
			falling = falling or game.shot.velocity.y < -0.1
			if falling and game.shot.velocity.y >= 0.0:
				bounced = true
				_expect(_in_view(camera, game.shot.position), "The grenade remains visible after bouncing.")
		if game.last_blast != Vector2.INF:
			saw_fuse = true
			_expect(_in_view(camera, game.last_blast), "The grenade fuse ends in view.")
			break
	_expect(bounced and saw_fuse, "The grenade test includes a real bounce and a timed impact.")

	app._start_match()
	_fire(arena, ArtilleryShot.Weapon.ROCKET, 43.0)
	for tick in range(30):
		await physics_frame
	app._pause_game()
	var paused := camera.transform
	var projectile_before := game.shot.position
	for tick in range(8):
		await physics_frame
	_expect(camera.transform == paused and game.shot.position == projectile_before,
		"Pausing freezes both the projectile and its camera.")
	app._resume_game()
	_button(MOUSE_BUTTON_MIDDLE, Vector2(850, 300), true)
	_motion(Vector2(450, 460))
	_button(MOUSE_BUTTON_MIDDLE, Vector2(450, 460), false)
	var manual := camera.transform
	for tick in range(320):
		await physics_frame
		if game.turn_number > 1:
			break
	_expect(game.turn_number > 1 and camera.transform == manual,
		"A pan takes over through the rest of the shot and its handoff.")
	_home()
	_button(MOUSE_BUTTON_MIDDLE, Vector2(180, 300), true)
	_motion(Vector2(1080, 300))
	_button(MOUSE_BUTTON_MIDDLE, Vector2(1080, 300), false)
	_button(MOUSE_BUTTON_WHEEL_DOWN, Vector2(900, 300), true)
	var far_view := camera.position
	var zoom := camera.fov
	_fire(arena, ArtilleryShot.Weapon.SHOTGUN, 0.0)
	for tick in range(12):
		await physics_frame
	_expect(game.shot == null and game.pellet_traces.size() == 10
		and camera.position.x > far_view.x + 0.5,
		"A new shotgun action reclaims the view using its pellet spread.")
	_expect(camera.fov == zoom, "Shot framing does not change the player's chosen zoom.")
	_home()
	var home := camera.transform
	for tick in range(65):
		await physics_frame
	_expect(camera.transform == home, "Home cancels follow instead of fighting the reset.")

	app._start_match()
	_fire(arena, ArtilleryShot.Weapon.SHOTGUN, 0.0)
	for tick in range(12):
		await physics_frame
	_expect(camera.transform == opening, "A nearby shot stays steady while its impact is already visible.")


func _fire(arena: MatchArena, weapon: ArtilleryShot.Weapon, angle: float) -> void:
	arena._weapon = weapon
	arena._angle = angle
	arena._power = 1.0
	arena._fire_current_shot()


func _in_view(camera: Camera3D, point: Vector2) -> bool:
	var screen := camera.unproject_position(Vector3(point.x, point.y, 0.0))
	return Rect2(14, 65, 1252, 523).has_point(screen)

func _button(button: MouseButton, point: Vector2, pressed: bool, shift: bool = false) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.position = point
	event.global_position = point
	event.pressed = pressed
	event.shift_pressed = shift
	_send(event)


func _motion(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	_send(event)


func _home() -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = KEY_HOME
		event.pressed = pressed
		_send(event)


func _send(event: InputEvent) -> void:
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
