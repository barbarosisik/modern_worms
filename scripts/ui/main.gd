extends Node

enum Screen { HOME, LAB, MATCH, PAUSE, SETTINGS, RESULT }

const DEFAULT_VOLUME := 80
const CONFIG_SECTION := "options"

@export var settings_path := "user://settings.cfg"

@onready var lab: TerrainLab = $TerrainLab
@onready var arena: MatchArena = $MatchArena
@onready var home: Control = %Home
@onready var hud: Control = %Hud
@onready var match_hud: Control = %MatchHud
@onready var result_screen: Control = %ResultScreen
@onready var pause_screen: Control = %PauseScreen
@onready var settings: Control = %Settings
@onready var shade: ColorRect = %Shade
@onready var start_button: Button = %StartButton
@onready var match_button: Button = %MatchButton
@onready var solo_button: Button = %SoloButton
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


func _ready() -> void:
	start_button.pressed.connect(_start_lab)
	match_button.pressed.connect(_start_match)
	solo_button.pressed.connect(_start_solo)
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
	_apply_settings()
	_show_screen(Screen.HOME)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	match _screen:
		Screen.LAB, Screen.MATCH:
			_pause_game()
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
	lab.reset_lab()
	_show_screen(Screen.LAB)


func _start_match() -> void:
	arena.reset_match()
	_show_screen(Screen.MATCH)


func _start_solo() -> void:
	arena.reset_match(true)
	_show_screen(Screen.MATCH)


func _rematch() -> void:
	arena.reset_match(arena.computer_enabled)
	_show_screen(Screen.MATCH)


func _pause_game() -> void:
	lab.cancel_charge()
	if not arena.is_computer_turn():
		arena.cancel_input()
	_show_screen(Screen.PAUSE)


func _resume_game() -> void:
	_show_screen(_active_game)


func _return_home() -> void:
	_show_screen(Screen.HOME)


func _show_result(winner: int) -> void:
	%ResultTitle.text = "Draw" if winner == -1 else MatchSimulation.TEAM_NAMES[winner] + " wins"
	%ResultKicker.text = "SOLO MATCH  /  RESULT" if arena.computer_enabled else "LOCAL MATCH  /  RESULT"
	_show_screen(Screen.RESULT)


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
	var playing := next == Screen.LAB or next == Screen.MATCH
	if playing:
		_active_game = next
	var showing_match := _active_game == Screen.MATCH
	arena.visible = showing_match
	arena.process_mode = Node.PROCESS_MODE_PAUSABLE if showing_match else Node.PROCESS_MODE_DISABLED
	lab.visible = not showing_match
	lab.process_mode = Node.PROCESS_MODE_DISABLED if showing_match else Node.PROCESS_MODE_PAUSABLE
	if showing_match:
		arena.camera.make_current()
	else:
		lab.camera.make_current()
	home.visible = next == Screen.HOME
	hud.visible = next == Screen.LAB
	match_hud.visible = next == Screen.MATCH
	result_screen.visible = next == Screen.RESULT
	pause_screen.visible = next == Screen.PAUSE
	settings.visible = next == Screen.SETTINGS
	shade.visible = not playing
	get_tree().paused = not playing
	match next:
		Screen.HOME:
			solo_button.grab_focus()
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


func _update_hud(status: String, power: float, angle: float) -> void:
	%Status.text = status
	%Power.value = power
	%Angle.text = "AIM  %+.0f°" % angle


func _update_match_hud(
	state: MatchSimulation, power: float, angle: float, weapon: ArtilleryShot.Weapon
) -> void:
	var unit := state.active_unit()
	var label := "%s %d" % [MatchSimulation.TEAM_NAMES[unit.team], unit.number]
	if arena.is_computer_turn():
		label += " (CPU)"
	var phase := "%02ds" % ceili(state.remaining) if state.phase == MatchSimulation.Phase.ACTIVE else "Resolving"
	%TurnTitle.text = "TURN %d  ·  %s  ·  %s" % [state.turn_number, label, phase]
	%BlueHealth.text = "BLUE  %d HP" % state.team_health(0)
	%OrangeHealth.text = "ORANGE  %d HP" % state.team_health(1)
	var wind := "Calm" if is_zero_approx(state.wind) else ("%s %.1f" % [
		"→" if state.wind > 0.0 else "←", absf(state.wind)
	])
	var weapon_name := "Rocket" if weapon == ArtilleryShot.Weapon.ROCKET else "Grenade"
	%WeaponStatus.text = "%s  ·  Wind %s  ·  Aim %+.0f°" % [weapon_name, wind, angle]
	var computer_status := arena.computer_status()
	%MatchStatus.text = computer_status if not computer_status.is_empty() else state.message
	%MatchPower.value = power
