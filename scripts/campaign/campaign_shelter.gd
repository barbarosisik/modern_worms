class_name CampaignShelter
extends Node3D

signal station_changed(station: int)
signal station_opened(station: int)

enum Station { NONE = -1, MAP, TEAM, ROSTER }

const STATION_X := [-4.6, 0.0, 4.55]
const STATION_NAMES := ["Map table", "Supply bench", "Roster board"]
const WALK_SPEED := 3.7
const INTERACT_RADIUS := 1.25

@onready var camera: Camera3D = $Camera3D
@onready var crew: Node3D = $Crew

var station: int = Station.NONE
var walker: CampaignActor
var _facing := 1.0


func _ready() -> void:
	camera.look_at(Vector3(0.0, 1.8, 0.0))
	_build_room()


func enter(run: CampaignRun) -> void:
	for actor in crew.get_children():
		crew.remove_child(actor)
		actor.queue_free()
	walker = _add_actor(CampaignRun.ROSTER[0], run.outfits[0], Vector3(-5.15, 0.0, 1.0))
	var nova := _add_actor(CampaignRun.ROSTER[1], run.outfits[1], Vector3(1.9, 0.0, -0.35))
	nova.pose(-1.0, 0.0, 0.0)
	if run.roster_size() == 3:
		_add_actor(CampaignRun.ROSTER[2], 0, Vector3(2.8, 0.0, 0.2))
	_facing = 1.0
	_update_station()
	station_changed.emit(station)


func interact() -> void:
	if station != Station.NONE:
		station_opened.emit(station)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		interact()
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	var axis := Input.get_axis("unit_left", "unit_right")
	var before := walker.position.x
	walker.position.x = clampf(before + axis * WALK_SPEED * delta, -6.3, 6.3)
	if not is_zero_approx(axis):
		_facing = signf(axis)
	walker.pose(_facing, (walker.position.x - before) / delta, delta)
	if _update_station():
		station_changed.emit(station)


func _update_station() -> bool:
	var next: int = Station.NONE
	for i in range(STATION_X.size()):
		if absf(walker.position.x - STATION_X[i]) <= INTERACT_RADIUS:
			next = i
			break
	if next == station:
		return false
	station = next
	return true


func _add_actor(character: String, outfit: int, point: Vector3) -> CampaignActor:
	var actor := CampaignActor.new(character, outfit)
	crew.add_child(actor)
	actor.position = point
	actor.scale = Vector3.ONE * 1.85
	return actor


func _build_room() -> void:
	ClubhouseDecor.room(self)
	var map := Sprite3D.new()
	map.texture = load("res://assets/kenney/ui_adventure/panel_brown.png")
	map.pixel_size = 0.012
	map.position = Vector3(-4.6,1.07,-0.7)
	map.rotation.x = -PI * 0.5
	add_child(map)
	var board := Sprite3D.new()
	board.texture = load("res://assets/kenney/ui_adventure/panel_brown.png")
	board.pixel_size = 0.018
	board.position = Vector3(4.55,2.65,-1.4)
	board.scale.y = 0.6
	add_child(board)
	var crew_title := Label3D.new()
	crew_title.text = "THE CREW\nTRAIN TOGETHER"
	crew_title.font = InterfaceSkin.face(600)
	crew_title.font_size = 34
	crew_title.pixel_size = 0.007
	crew_title.modulate = Color("#49362b")
	crew_title.outline_size = 0
	crew_title.position = Vector3(4.55,2.65,-1.35)
	add_child(crew_title)
	for i in range(STATION_X.size()):
		_station_label(STATION_NAMES[i], STATION_X[i])


func _station_label(caption: String, x: float) -> void:
	var label := Label3D.new()
	label.text = caption.to_upper()
	label.font = InterfaceSkin.face(600)
	label.font_size = 44
	label.outline_size = 8
	label.pixel_size = 0.008
	label.modulate = Color("#ffe5a8")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(x,3.55,-0.23)
	add_child(label)
