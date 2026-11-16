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
	app.free()
	for failure in _failures:
		push_error(failure)
	if _failures.is_empty():
		print("PASS: camera drag, alternate controls, bounds, aiming/GUI isolation, CPU/resolving view controls and cancellation")
	quit(0 if _failures.is_empty() else 1)


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
