extends SceneTree

var _failures: Array[String] = []
const STEP := 1.0 / 60.0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var app := preload("res://scenes/main.tscn").instantiate()
	app.settings_path = "user://shelter_test_settings_%d.cfg" % OS.get_process_id()
	app.campaign_checkpoint_path = "user://shelter_test_campaign_%d.cfg" % OS.get_process_id()
	root.add_child(app)
	await process_frame
	app.campaign.begin(PackedInt32Array([0, 1]))
	app._enter_shelter()
	var room: CampaignShelter = app.shelter
	await _frames(2)
	_expect(room.crew.get_child_count() == 2, "A fresh shelter contains only the two cat leads.")
	_expect(not room.anchors[2].get_node("ScoutMat").visible, "Scout's place is not occupied before rescue.")
	_expect(room.station == CampaignShelter.Station.MAP, "The initial walker is near the map table.")
	for i in range(3):
		if i > 0:
			await _walk_to(room, room.anchors[i].position.x)
		_expect(room.station == i, "Walking discovers the correct station %d." % i)
		var point := room.walker.position
		if i == 1:
			_click(app.get_node("%StationAction"))
		else:
			_key(KEY_E, true)
			_key(KEY_E, false)
		await _frames(2)
		_expect(paused and app.campaign_panel.visible, "Keyboard and pointer interaction open a modal.")
		var card := app.campaign_panel.get_node("Card") as Control
		_expect(root.get_visible_rect().encloses(card.get_global_rect()), "Station content fits the 720p window, including locked upgrade explanations.")
		_key(KEY_D, true)
		await _frames(12)
		_key(KEY_D, false)
		_expect(room.walker.position == point, "A station modal stops shelter walking.")
		# Key echo must not cause another interaction or close the panel.
		_key(KEY_E, true, true)
		_key(KEY_E, false)
		_expect(app.campaign_panel.visible, "Held interaction does not double-activate a modal.")
		_key(KEY_ESCAPE, true)
		_key(KEY_ESCAPE, false)
		await _frames(2)
		_expect(not paused and room.walker.position == point, "Closing the station restores the same walker position.")
		_expect(app.shelter_hud.visible, "Closing a station restores its action prompt.")
	await _walk_to(room, 1.9)
	_expect(room.station == CampaignShelter.Station.NONE and app.get_node("%StationAction").disabled,
		"Between stations the action is disabled.")
	# Bindings displayed by the prompt must follow InputMap, not hardcoded E.
	var old_events := InputMap.action_get_events("interact")
	InputMap.action_erase_events("interact")
	var binding := InputEventKey.new()
	binding.physical_keycode = KEY_F
	InputMap.action_add_event("interact", binding)
	await _walk_to(room, 0.0)
	_expect("F" in app.get_node("%StationAction").text, "The prompt displays the current interaction binding.")
	_key(KEY_F, true)
	_key(KEY_F, false)
	_expect(app.campaign_panel.visible, "The displayed rebound key opens its station.")
	_expect("Clear First Signal" in app.campaign_panel._body.text, "Locked upgrades explain the unlock condition.")
	app._close_campaign_panel()
	InputMap.action_erase_events("interact")
	for event in old_events:
		InputMap.action_add_event("interact", event)
	# Rescue/progress changes survive reopening the real checkpoint.
	app.campaign.complete(0, 1)
	app.campaign.buy_kits()
	app._save_campaign_checkpoint()
	var checkpoint: String = app.campaign_checkpoint_path
	var restored := CampaignRun.new()
	restored.load_checkpoint(checkpoint)
	room.enter(restored)
	_expect(room.crew.get_child_count() == 3 and room.anchors[2].get_node("ScoutMat").visible,
		"Saved rescue state adds Scout and his place.")
	_expect("Equipped" in room._kit_status.text and "Ferry Landing" in room._route_status.text,
		"Room displays derive from saved equipment and mission progress.")
	var phase_before: float = room.crew.get_child(1)._pose_time
	await _frames(10)
	_expect(room.crew.get_child(1)._pose_time > phase_before, "Stationary crew poses continue to advance.")
	app.campaign.complete(1, 0)
	room.refresh_progress(app.campaign)
	app._open_shelter_station(0)
	_expect(app.find_child("StartMission", true, false) == null, "The completed route does not invent a third mission.")
	var skirmish := app.find_child("ShelterSkirmish", true, false) as Button
	_expect(skirmish != null, "The completed map provides a working skirmish exit.")
	_click(skirmish)
	await process_frame
	_expect(app.match_hud.visible and not paused and app._mission_index == -1,
		"The completed shelter opens an actual solo skirmish.")
	app.arena.cancel_input()
	app._enter_shelter()
	await _frames(2)
	for direction in [KEY_A, KEY_D]:
		_key(direction, true)
		await _frames(260)
		_key(direction, false)
		_expect(absf(room.walker.position.x) <= 6.301, "The walkable lane has working end bounds.")
	# Every station anchor remains inside the visible room at both sizes.
	for screen in [Vector2i(1280,720), Vector2i(1920,1080)]:
		root.size = screen
		await _frames(2)
		for anchor in room.anchors:
			var point := room.camera.unproject_position(anchor.global_position + Vector3(0, 2, 0))
			_expect(root.get_visible_rect().has_point(point), "Stations remain framed at each supported resolution.")
	var settings: String = app.settings_path
	app.free()
	for path in [settings, checkpoint, checkpoint + ".pending"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for failure in _failures:
		push_error(failure)
	if _failures.is_empty():
		print("PASS: shelter walking, all stations, modal input, bindings, saved crew/equipment, framing and completed-route skirmish")
	quit(0 if _failures.is_empty() else 1)


func _walk_to(room: CampaignShelter, target: float) -> void:
	var key := KEY_D if target > room.walker.position.x else KEY_A
	_key(key, true)
	var count := ceili(absf(target - room.walker.position.x) / (CampaignShelter.WALK_SPEED * STEP))
	await _frames(count)
	_key(key, false)
	await _frames(2)


func _frames(count: int) -> void:
	for i in range(count):
		await physics_frame


func _key(key: Key, pressed: bool, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = pressed
	event.echo = echo
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _click(button: Button) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = button.get_global_rect().get_center()
		event.global_position = event.position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
