extends Node

enum Screen { HOME, LAB, PAUSE, SETTINGS }

const DEFAULT_VOLUME := 80
const CONFIG_SECTION := "options"

@export var settings_path := "user://settings.cfg"

@onready var lab: TerrainLab = $TerrainLab
@onready var home: Control = %Home
@onready var hud: Control = %Hud
@onready var pause_screen: Control = %PauseScreen
@onready var settings: Control = %Settings
@onready var shade: ColorRect = %Shade
@onready var start_button: Button = %StartButton
@onready var resume_button: Button = %ResumeButton
@onready var volume: HSlider = %Volume
@onready var volume_label: Label = %VolumeValue
@onready var fullscreen: CheckButton = %Fullscreen
@onready var save_status: Label = %SaveStatus

var _screen := Screen.HOME
var _return_screen := Screen.HOME
var _volume := DEFAULT_VOLUME
var _fullscreen := false


func _ready() -> void:
	start_button.pressed.connect(_start_lab)
	%HomeSettings.pressed.connect(_open_settings)
	%QuitButton.pressed.connect(get_tree().quit)
	%PauseButton.pressed.connect(_pause_lab)
	resume_button.pressed.connect(_resume_lab)
	%PauseSettings.pressed.connect(_open_settings)
	%ReturnHome.pressed.connect(_return_home)
	%ApplyButton.pressed.connect(_save_settings)
	%BackButton.pressed.connect(_close_settings)
	volume.value_changed.connect(_update_volume_label)
	lab.hud_changed.connect(_update_hud)
	_load_settings()
	_apply_settings()
	_show_screen(Screen.HOME)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	match _screen:
		Screen.LAB:
			_pause_lab()
		Screen.PAUSE:
			_resume_lab()
		Screen.SETTINGS:
			_close_settings()
		_:
			return
	get_viewport().set_input_as_handled()


func _start_lab() -> void:
	lab.reset_lab()
	_show_screen(Screen.LAB)


func _pause_lab() -> void:
	lab.cancel_charge()
	_show_screen(Screen.PAUSE)


func _resume_lab() -> void:
	_show_screen(Screen.LAB)


func _return_home() -> void:
	lab.reset_lab()
	_show_screen(Screen.HOME)


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
	home.visible = next == Screen.HOME
	hud.visible = next == Screen.LAB
	pause_screen.visible = next == Screen.PAUSE
	settings.visible = next == Screen.SETTINGS
	shade.visible = next != Screen.LAB
	get_tree().paused = next != Screen.LAB
	match next:
		Screen.HOME:
			start_button.grab_focus()
		Screen.PAUSE:
			resume_button.grab_focus()
		Screen.SETTINGS:
			volume.grab_focus()


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
