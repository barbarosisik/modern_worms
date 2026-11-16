extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280,720)
	var settings_file := "user://interface_check_%d.cfg" % OS.get_process_id()
	var app := preload("res://scenes/main.tscn").instantiate()
	app.settings_path = settings_file
	app.campaign_checkpoint_path = "user://interface_campaign_%d.cfg" % OS.get_process_id()
	root.add_child(app)
	await process_frame
	await process_frame
	_check_home(app)
	_click(app.get_node("%HomeSettings"))
	await process_frame
	_expect(app.settings.visible, "The restyled settings button opens settings through real pointer input.")
	_check_visible_cards(app)
	app.volume.value = 37
	_click(app.fullscreen)
	var fullscreen_value: bool = app.fullscreen.button_pressed
	_click(app.get_node("%ApplyButton"))
	_click(app.get_node("%BackButton"))
	app.free()
	app = preload("res://scenes/main.tscn").instantiate()
	app.settings_path = settings_file
	app.campaign_checkpoint_path = "user://interface_campaign_%d.cfg" % OS.get_process_id()
	root.add_child(app)
	await process_frame
	_expect(app._volume == 37 and app._fullscreen == fullscreen_value, "Restyled settings save and reload their actual values.")
	# Showing Continue adds another row; it must not push controls off screen.
	app.campaign.begin(PackedInt32Array([0,1]))
	app.campaign.complete(0,0)
	app._return_home()
	await process_frame
	await process_frame
	_check_home(app)
	_click(app.get_node("%NewStory"))
	await process_frame
	_expect(app.campaign_panel.visible, "The wardrobe remains reachable after menu reparenting.")
	_check_visible_cards(app)
	app._close_campaign_panel()
	app._enter_shelter()
	_click(app.get_node("%StationAction"))
	await process_frame
	_expect(app.campaign_panel.visible and app.find_child("StartMission",true,false) != null, "The nearby shelter station opens the working mission map.")
	_check_visible_cards(app)
	app._close_campaign_panel()
	app._open_shelter_station(CampaignShelter.Station.ROSTER)
	await process_frame
	var tabs := app.find_child("RosterTabs",true,false) as TabBar
	tabs.current_tab = 2
	_expect(app.campaign_panel._models[2].visible and not app.campaign_panel._models[0].visible,
		"The selected rescued character has the correct upgrade portrait.")
	_check_visible_cards(app)
	app._close_campaign_panel()
	app._start_match()
	_click(app.get_node("%MatchPauseButton"))
	await process_frame
	_check_visible_cards(app)
	_click(app.get_node("%ResumeButton"))
	app._show_result(0)
	await process_frame
	_check_visible_cards(app)
	_click(app.get_node("%Rematch"))
	_expect(not paused and app.match_hud.visible, "The restyled result offers a working rematch.")
	app.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(settings_file))
	for failure in _failures: push_error(failure)
	if _failures.is_empty():
		print("PASS: menu layout, pointer navigation, saved settings, station map, selected roster portrait, pause and rematch")
	quit(0 if _failures.is_empty() else 1)


func _check_home(app: Node) -> void:
	var buttons: Array[Button] = []
	for name in ["ContinueStory","NewStory","SoloButton","MatchButton","StartButton","HomeSettings","QuitButton"]:
		var button := app.get_node("%"+name) as Button
		if not button.visible: continue
		_expect(root.get_visible_rect().encloses(button.get_global_rect()), "Visible home buttons stay inside the window: " + name)
		for other in buttons:
			_expect(not button.get_global_rect().intersects(other.get_global_rect()), "Home buttons never overlap.")
		buttons.append(button)
	_check_visible_cards(app)


func _check_visible_cards(app: Node) -> void:
	for card in app.find_children("Card","PanelContainer",true,false):
		if card.is_visible_in_tree():
			_expect(root.get_visible_rect().encloses(card.get_global_rect()), "The active menu card fits the 720p window: " + str(card.get_path()))


func _click(button: BaseButton) -> void:
	var point := button.get_global_rect().get_center()
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.global_position = point
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()


func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
