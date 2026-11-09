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
	var eli := _add_actor(CampaignRun.ROSTER[1], run.outfits[1], Vector3(1.9, 0.0, -0.35))
	eli.pose(-1.0, 0.0, 0.0)
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
	var wood := Color("#5f4438")
	var pine := Color("#997052")
	var trim := Color("#392a29")
	var paper := Color("#eadbb3")
	var teal := Color("#34545a")
	_box(Vector3(0.0, -0.19, 0.0), Vector3(14.0, 0.38, 3.6), wood)
	_box(Vector3(0.0, 4.05, -0.1), Vector3(14.1, 0.33, 3.5), trim)
	_box(Vector3(0.0, 0.64, -1.64), Vector3(13.9, 1.28, 0.18), pine)
	_box(Vector3(0.0, 3.57, -1.64), Vector3(13.9, 0.7, 0.18), pine)
	for x in [-6.79, -2.38, 2.33, 6.79]:
		_box(Vector3(x, 2.0, -1.60), Vector3(0.26, 4.0, 0.29), trim)
	for x in [-4.55, 0.0, 4.55]:
		_box(Vector3(x, 1.29, -1.56), Vector3(4.1, 0.10, 0.29), trim)
	for row in range(4):
		_box(Vector3(0.0, 0.16 + 0.30 * row, -1.53), Vector3(13.7, 0.025, 0.012), wood)
	_box(Vector3(-4.65, 0.49, -0.47), Vector3(2.5, 0.98, 0.9), wood)
	_box(Vector3(-4.65, 1.0, -0.46), Vector3(2.75, 0.19, 1.05), pine)
	_box(Vector3(-4.7, 1.11, -0.36), Vector3(1.41, 0.027, 0.64), paper)
	_box(Vector3(-4.70, 1.137, -0.38), Vector3(0.72, 0.014, 0.12), teal).rotation.y = -0.36
	_box(Vector3(0.0, 0.42, -0.54), Vector3(2.24, 0.84, 0.92), trim)
	_box(Vector3(0.0, 0.91, -0.52), Vector3(2.49, 0.19, 1.02), pine)
	_box(Vector3(-0.67, 1.18, -0.60), Vector3(0.60, 0.36, 0.46), teal)
	_box(Vector3(0.43, 1.14, -0.55), Vector3(0.69, 0.27, 0.55), Color("#bd7950"))
	_box(Vector3(4.55, 1.38, -1.32), Vector3(2.30, 1.57, 0.16), trim)
	_box(Vector3(4.55, 1.38, -1.22), Vector3(2.04, 1.30, 0.06), teal)
	for x in [3.98, 4.55, 5.12]:
		_box(Vector3(x, 1.42, -1.17), Vector3(0.37, 0.56, 0.035), paper)
	for i in range(STATION_X.size()):
		_station_label(STATION_NAMES[i], STATION_X[i])


func _station_label(caption: String, x: float) -> void:
	var label := Label3D.new()
	label.text = caption.to_upper()
	label.font_size = 48
	label.outline_size = 10
	label.pixel_size = 0.008
	label.modulate = Color("#f3d99e")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(x, 2.68, -0.23)
	add_child(label)


func _box(point: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.94
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = point
	add_child(instance)
	return instance
