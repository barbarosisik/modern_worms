extends Node

enum Screen { HOME, LAB, MATCH, SHELTER, CAMPAIGN_PANEL, PAUSE, SETTINGS, RESULT }

const DEFAULT_VOLUME := 80
const CONFIG_SECTION := "options"

@export var settings_path := "user://settings.cfg"
@export var campaign_checkpoint_path := "user://signal_fires.cfg"

@onready var lab: TerrainLab = $TerrainLab
@onready var arena: MatchArena = $MatchArena
@onready var shelter: CampaignShelter = $CampaignShelter
@onready var campaign_panel: CampaignPanel = %CampaignPanel
@onready var home: Control = %Home
@onready var hud: Control = %Hud
@onready var match_hud: Control = %MatchHud
@onready var shelter_hud: Control = %ShelterHud
@onready var result_screen: Control = %ResultScreen
@onready var pause_screen: Control = %PauseScreen
@onready var settings: Control = %Settings
@onready var shade: ColorRect = %Shade
@onready var start_button: Button = %StartButton
@onready var match_button: Button = %MatchButton
@onready var solo_button: Button = %SoloButton
@onready var new_story_button: Button = %NewStory
@onready var continue_story_button: Button = %ContinueStory
@onready var resume_button: Button = %ResumeButton
@onready var volume: HSlider = %Volume
@onready var volume_label: Label = %VolumeValue
@onready var fullscreen: CheckButton = %Fullscreen
@onready var save_status: Label = %SaveStatus

var _screen := Screen.HOME
var _active_game := Screen.LAB
var _return_screen := Screen.HOME
var _volume := DEFAULT_VOLUME
var _fullscreen := false
var campaign := CampaignRun.new()
var _campaign_panel_return := Screen.HOME
var _mission_index := -1
var _mission_won := false
var _checkpoint_failed := false


func _ready() -> void:
	get_window().title = "Signal Fires"
	start_button.pressed.connect(_start_lab)
	match_button.pressed.connect(_start_match)
	solo_button.pressed.connect(_start_solo)
	new_story_button.pressed.connect(_open_wardrobe)
	continue_story_button.pressed.connect(_continue_story)
	campaign_panel.close_requested.connect(_close_campaign_panel)
	campaign_panel.story_requested.connect(_begin_story)
	campaign_panel.mission_requested.connect(_launch_mission)
	campaign_panel.checkpoint_changed.connect(_save_campaign_checkpoint)
	shelter.station_changed.connect(_refresh_shelter_hud)
	shelter.station_opened.connect(_open_shelter_station)
	%StationAction.pressed.connect(shelter.interact)
	%ShelterPause.pressed.connect(_pause_game)
	%HomeSettings.pressed.connect(_open_settings)
	%QuitButton.pressed.connect(get_tree().quit)
	%PauseButton.pressed.connect(_pause_game)
	%MatchPauseButton.pressed.connect(_pause_game)
	resume_button.pressed.connect(_resume_game)
	%PauseSettings.pressed.connect(_open_settings)
	%ReturnHome.pressed.connect(_return_home)
	%ApplyButton.pressed.connect(_save_settings)
	%BackButton.pressed.connect(_close_settings)
	%Rematch.pressed.connect(_rematch)
	%ResultHome.pressed.connect(_return_home)
	volume.value_changed.connect(_update_volume_label)
	lab.hud_changed.connect(_update_hud)
	arena.hud_changed.connect(_update_match_hud)
	arena.match_finished.connect(_show_result)
	_load_settings()
	campaign.load_checkpoint(campaign_checkpoint_path)
	_apply_settings()
	_show_screen(Screen.HOME)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	match _screen:
		Screen.LAB, Screen.MATCH, Screen.SHELTER:
			_pause_game()
		Screen.CAMPAIGN_PANEL:
			_close_campaign_panel()
		Screen.PAUSE:
			_resume_game()
		Screen.SETTINGS:
			_close_settings()
		Screen.RESULT:
			_return_home()
		_:
			return
	get_viewport().set_input_as_handled()


func _start_lab() -> void:
	_mission_index = -1
	lab.reset_lab()
	_show_screen(Screen.LAB)


func _start_match() -> void:
	_mission_index = -1
	arena.reset_match()
	_show_screen(Screen.MATCH)


func _start_solo() -> void:
	_mission_index = -1
	arena.reset_match(true)
	_show_screen(Screen.MATCH)


func _rematch() -> void:
	if _mission_index >= 0:
		if _mission_won:
			_enter_shelter()
		else:
			_launch_mission()
		return
	arena.reset_match(arena.computer_enabled)
	_show_screen(Screen.MATCH)


func _open_wardrobe() -> void:
	_open_campaign_panel(Screen.HOME)
	campaign_panel.open_wardrobe(campaign)


func _begin_story(outfits: PackedInt32Array) -> void:
	campaign.begin(outfits)
	_save_campaign_checkpoint()
	campaign_panel.open_map(campaign)


func _continue_story() -> void:
	if campaign.cleared == 0:
		_open_campaign_panel(Screen.HOME)
		campaign_panel.open_map(campaign)
	else:
		_enter_shelter()


func _launch_mission() -> void:
	if not campaign.started or campaign.finished():
		return
	_mission_index = campaign.cleared
	_mission_won = false
	arena.reset_match(true, CampaignMission.new(_mission_index, campaign))
	_show_screen(Screen.MATCH)


func _enter_shelter() -> void:
	_mission_index = -1
	shelter.enter(campaign)
	_show_screen(Screen.SHELTER)


func _open_shelter_station(station: int) -> void:
	_open_campaign_panel(Screen.SHELTER)
	match station:
		CampaignShelter.Station.MAP:
			campaign_panel.open_map(campaign)
		CampaignShelter.Station.TEAM:
			campaign_panel.open_team(campaign)
		CampaignShelter.Station.ROSTER:
			campaign_panel.open_roster(campaign)


func _open_campaign_panel(return_to: Screen) -> void:
	_campaign_panel_return = return_to
	_show_screen(Screen.CAMPAIGN_PANEL)


func _close_campaign_panel() -> void:
	_show_screen(_campaign_panel_return)


func _save_campaign_checkpoint() -> void:
	_checkpoint_failed = campaign.save_checkpoint(campaign_checkpoint_path) != OK
	campaign_panel.show_save_warning(_checkpoint_failed)
	_refresh_shelter_hud(shelter.station)


func _refresh_shelter_hud(station: int) -> void:
	%ShelterProgress.text = "%d/%d MISSIONS CLEARED   ·   %d SUPPLIES" % [
		campaign.cleared, CampaignRun.MISSIONS.size(), campaign.supplies
	]
	%ShelterStory.text = (
		"Mara: The ferry's ours. Tomorrow we follow the relay into the pines." if campaign.finished()
		else "Eli: Scout's safe. Let's get our gear before we take the ferry."
	)
	var action := %StationAction as Button
	action.disabled = station == CampaignShelter.Station.NONE
	action.text = "Walk to a station" if action.disabled else "E   ·   Open " + CampaignShelter.STATION_NAMES[station]


func _pause_game() -> void:
	lab.cancel_charge()
	if not arena.is_computer_turn():
		arena.cancel_input()
	_show_screen(Screen.PAUSE)


func _resume_game() -> void:
	_show_screen(_active_game)


func _return_home() -> void:
	_mission_index = -1
	_show_screen(Screen.HOME)


func _show_result(winner: int) -> void:
	var detail := %ResultDetail as Label
	var next := %Rematch as Button
	detail.visible = _mission_index >= 0
	if _mission_index >= 0:
		_show_mission_result(winner, detail, next)
	else:
		%ResultTitle.text = "Draw" if winner == -1 else MatchSimulation.TEAM_NAMES[winner] + " wins"
		%ResultKicker.text = "SOLO MATCH  /  RESULT" if arena.computer_enabled else "LOCAL MATCH  /  RESULT"
		next.text = "Rematch"
	_show_screen(Screen.RESULT)


func _show_mission_result(winner: int, detail: Label, next: Button) -> void:
	%ResultKicker.text = "SIGNAL FIRES  /  " + CampaignRun.MISSIONS[_mission_index].to_upper()
	_mission_won = winner == 0
	if not _mission_won:
		%ResultTitle.text = "Mission failed"
		var target := arena.simulation.rescue_target
		detail.text = "Scout was swept away. Reach him before the bank gives way." if (
			target != null and not arena.simulation.rescued and not target.alive()
		) else "The crew lost the fight. Retry from the last shelter checkpoint."
		next.text = "Retry mission"
		return
	var collected := arena.simulation.supplies[0]
	if campaign.complete(_mission_index, collected):
		_save_campaign_checkpoint()
	%ResultTitle.text = "Scout is safe" if _mission_index == 0 else "Chapter cleared"
	detail.text = "Scout joins Mara and Eli in the turn queue." if _mission_index == 0 else (
		"The ferry is secure. The valley has a route out, and the crew can follow the relay into the pines."
	)
	detail.text += "\n\nSupplies banked   +%d" % (CampaignRun.CLEAR_REWARD + collected)
	if _checkpoint_failed:
		detail.text += "\nThe checkpoint could not be saved."
	next.text = "Return to shelter"


func _open_settings() -> void:
	_return_screen = _screen
	volume.value = _volume
	_update_volume_label(volume.value)
	fullscreen.button_pressed = _fullscreen
	save_status.text = ""
	_show_screen(Screen.SETTINGS)


func _close_settings() -> void:
	_show_screen(_return_screen)


func _show_screen(next: Screen) -> void:
	_screen = next
	var playing := next == Screen.LAB or next == Screen.MATCH or next == Screen.SHELTER
	if playing:
		_active_game = next
	var showing_match := _active_game == Screen.MATCH
	var showing_shelter := _active_game == Screen.SHELTER
	var showing_lab := _active_game == Screen.LAB
	var title_backdrop := next == Screen.HOME or (
		next == Screen.CAMPAIGN_PANEL and _campaign_panel_return == Screen.HOME
	) or (next == Screen.SETTINGS and _return_screen == Screen.HOME)
	arena.visible = showing_match and not title_backdrop
	arena.process_mode = Node.PROCESS_MODE_PAUSABLE if showing_match else Node.PROCESS_MODE_DISABLED
	lab.visible = showing_lab and not title_backdrop
	lab.process_mode = Node.PROCESS_MODE_PAUSABLE if showing_lab else Node.PROCESS_MODE_DISABLED
	shelter.visible = showing_shelter and not title_backdrop
	shelter.process_mode = Node.PROCESS_MODE_PAUSABLE if showing_shelter else Node.PROCESS_MODE_DISABLED
	if showing_match:
		arena.camera.make_current()
	elif showing_shelter:
		shelter.camera.make_current()
	else:
		lab.camera.make_current()
	home.visible = next == Screen.HOME
	hud.visible = next == Screen.LAB
	match_hud.visible = next == Screen.MATCH
	shelter_hud.visible = next == Screen.SHELTER
	campaign_panel.visible = next == Screen.CAMPAIGN_PANEL
	result_screen.visible = next == Screen.RESULT
	pause_screen.visible = next == Screen.PAUSE
	settings.visible = next == Screen.SETTINGS
	shade.visible = not playing
	get_tree().paused = not playing
	match next:
		Screen.HOME:
			continue_story_button.visible = campaign.started
			var first := continue_story_button if campaign.started else new_story_button
			first.grab_focus()
		Screen.PAUSE:
			resume_button.grab_focus()
		Screen.SETTINGS:
			volume.grab_focus()
		Screen.RESULT:
			%Rematch.grab_focus()


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(settings_path) == OK:
		_volume = clampi(int(config.get_value(CONFIG_SECTION, "volume", DEFAULT_VOLUME)), 0, 100)
		_fullscreen = bool(config.get_value(CONFIG_SECTION, "fullscreen", false))


func _save_settings() -> void:
	var config := ConfigFile.new()
	var selected_volume := roundi(volume.value)
	var selected_fullscreen := fullscreen.button_pressed
	config.set_value(CONFIG_SECTION, "volume", selected_volume)
	config.set_value(CONFIG_SECTION, "fullscreen", selected_fullscreen)
	var result := config.save(settings_path)
	if result != OK:
		save_status.text = "Couldn't save settings. " + error_string(result)
		return
	_volume = selected_volume
	_fullscreen = selected_fullscreen
	_apply_settings()
	save_status.text = "Settings saved."


func _apply_settings() -> void:
	var gain := maxf(float(_volume) / 100.0, 0.001)
	var master := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master, linear_to_db(gain))
	AudioServer.set_bus_mute(master, _volume == 0)
	if DisplayServer.get_name() != "headless":
		get_window().mode = Window.MODE_FULLSCREEN if _fullscreen else Window.MODE_WINDOWED


func _update_volume_label(value: float) -> void:
	volume_label.text = "%d%%" % roundi(value)


func _update_hud(status: String, power: float, angle: float, guide_dots: int) -> void:
	%Status.text = status
	%Power.value = power
	%Angle.text = "AIM  %+.0f°" % angle
	%LabGuide.text = "GUIDE  %d" % guide_dots


func _update_match_hud(
	state: MatchSimulation, power: float, angle: float, weapon: ArtilleryShot.Weapon
) -> void:
	var unit := state.active_unit()
	var label := unit.display_name
	if label.is_empty():
		label = "%s %d" % [MatchSimulation.TEAM_NAMES[unit.team], unit.number]
	if arena.is_computer_turn():
		label += " (CPU)"
	var phase := "%02ds" % ceili(state.remaining) if state.phase == MatchSimulation.Phase.ACTIVE else "Resolving"
	%TurnTitle.text = "TURN %d  ·  %s  ·  %s" % [state.turn_number, label, phase]
	%BlueHealth.text = "%s  %d HP  ·  %d SUP" % [
		"RESCUERS" if _mission_index >= 0 else "BLUE", state.team_health(0), state.supplies[0]
	]
	%OrangeHealth.text = "%s  %d HP  ·  %d SUP" % [
		"SALVAGE" if _mission_index >= 0 else "ORANGE", state.team_health(1), state.supplies[1]
	]
	_update_mission_hud(state)
	var wind := "Calm" if is_zero_approx(state.wind) else ("%s %.1f" % [
		"→" if state.wind > 0.0 else "←", absf(state.wind)
	])
	var weapon_name := "Rocket" if weapon == ArtilleryShot.Weapon.ROCKET else "Grenade"
	%WeaponStatus.text = "%s  ·  Wind %s  ·  Aim %+.0f°" % [weapon_name, wind, angle]
	var computer_status := arena.computer_status()
	%MatchStatus.text = computer_status if not computer_status.is_empty() else state.message
	var pickup := arena.supply_notice()
	if not pickup.is_empty():
		%MatchStatus.text = pickup
	%MatchPower.value = power


func _update_mission_hud(state: MatchSimulation) -> void:
	%MissionObjective.visible = _mission_index >= 0
	%PlayerQueue.visible = _mission_index >= 0
	if _mission_index < 0:
		return
	var objective: String = CampaignRun.OBJECTIVES[_mission_index]
	if _mission_index == 0:
		if state.rescued:
			objective = "Scout is safe. Clear the lookout."
		elif state.team_health(1) == 0:
			objective = "The lookout is down. Reach Scout on foot."
	%MissionObjective.text = "%s   ·   %s" % [CampaignRun.MISSIONS[_mission_index].to_upper(), objective]
	var names := PackedStringArray()
	for unit in state.units:
		if unit.team == 0 and unit.alive():
			names.append("[%s]" % unit.display_name if unit == state.active_unit() else unit.display_name)
	%PlayerQueue.text = "TURN ORDER   " + "  ›  ".join(names)
