class_name CampaignShelter
extends Node3D

signal station_changed(station: int)
signal station_opened(station: int)

enum Station { NONE = -1, MAP, TEAM, ROSTER }
const STATION_NAMES := ["Map table", "Supply bench", "Crew corner"]
const STATION_PURPOSES := ["Choose the next expedition", "Equip the whole team", "Train each crew member"]
const WALK_SPEED := 3.7
const INTERACT_RADIUS := 1.25

@onready var camera: Camera3D = $Camera3D
@onready var crew: Node3D = $Crew
@onready var anchors: Array[Node3D] = [$Stations/MapTable, $Stations/SupplyBench, $Stations/CrewCorner]

var station: int = Station.NONE
var walker: CampaignActor
var _facing := 1.0
var _markers: Array[Sprite3D] = []
var _crew_cards: Array[Label3D] = []
var _route_status: Label3D
var _kit_status: Label3D
var _time := 0.0
var _plant: Node3D


func _ready() -> void:
	camera.look_at(Vector3(0.0, 2.15, 0.0))
	_build_room()


func enter(run: CampaignRun) -> void:
	for actor in crew.get_children():
		crew.remove_child(actor)
		actor.queue_free()
	walker = _add_actor(CampaignRun.ROSTER[0], run.outfits[0], Vector3(-5.15, 0.0, 1.0))
	var nova := _add_actor(CampaignRun.ROSTER[1], run.outfits[1], Vector3(5.35, 0.0, 0.15))
	nova.pose(-1.0, 0.0, 0.55)
	if run.roster_size() == 3:
		var scout := _add_actor(CampaignRun.ROSTER[2], 0, Vector3(3.15, 0.0, -0.1))
		scout.pose(1.0, 0.0, 1.1)
	_facing = 1.0
	refresh_progress(run)
	_update_station()
	station_changed.emit(station)


func refresh_progress(run: CampaignRun) -> void:
	_route_status.text = "The valley needs you" if run.cleared == 0 else (
		"First Signal  ✓\nNext: Ferry Landing" if not run.finished() else "First Signal  ✓\nFerry Landing  ✓"
	)
	_kit_status.text = "FIELD KITS\n" + ("Equipped for everyone" if run.field_kits else "Prepare your crew")
	for i in range(_crew_cards.size()):
		_crew_cards[i].text = CampaignRun.ROSTER[i] if i < run.roster_size() else "Scout\nMissing"
		_crew_cards[i].modulate = InterfaceSkin.INK if i < run.roster_size() else Color("#8d7e65")
	anchors[Station.ROSTER].get_node("ScoutMat").visible = run.roster_size() == 3


func interact() -> void:
	if station != Station.NONE and can_process() and visible:
		station_opened.emit(station)


static func key_hint(action: String) -> String:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var code: Key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
			return OS.get_keycode_string(code)
	return action.capitalize()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo():
		interact()
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(walker):
		return
	var axis := Input.get_axis("unit_left", "unit_right")
	var before := walker.position.x
	walker.position.x = clampf(before + axis * WALK_SPEED * delta, -6.3, 6.3)
	if not is_zero_approx(axis):
		_facing = signf(axis)
	walker.pose(_facing, (walker.position.x - before) / delta, delta)
	for actor in crew.get_children():
		if actor != walker:
			actor.pose(-1.0 if actor == crew.get_child(1) else 1.0, 0.0, delta)
	_time += delta
	_plant.rotation.z = sin(_time * 0.7) * 0.018
	if _update_station():
		station_changed.emit(station)


func _update_station() -> bool:
	var next: int = Station.NONE
	for i in range(anchors.size()):
		if absf(walker.position.x - anchors[i].position.x) <= INTERACT_RADIUS:
			next = i
			break
	if next == station:
		return false
	station = next
	for i in range(_markers.size()):
		_markers[i].modulate = Color("#ffd693") if i == station else Color("#b8c9bc")
		_markers[i].scale = _markers[i].get_meta("rest_scale") * (1.06 if i == station else 1.0)
	return true


func _add_actor(character: String, outfit: int, point: Vector3) -> CampaignActor:
	var actor := CampaignActor.new(character, outfit)
	crew.add_child(actor)
	actor.position = point
	actor.scale = Vector3.ONE * 1.7
	return actor


func _build_room() -> void:
	ClubhouseDecor.room(self, anchors)
	_plant = anchors[Station.ROSTER].find_child("plantSmall1", true, false)
	for i in range(anchors.size()):
		var anchor := anchors[i]
		var marker := _paper(anchor, Vector3(0, 4.03, -1.4), Vector2(3.1, 0.66))
		marker.set_meta("rest_scale", marker.scale)
		_markers.append(marker)
		var icon := Sprite3D.new()
		icon.texture = load("res://assets/ui/shelter/" + ["map", "kit", "crew"][i] + ".svg")
		icon.pixel_size = 0.0064
		icon.position = Vector3(-1.12, 4.03, -1.35)
		anchor.add_child(icon)
		_label(anchor, STATION_NAMES[i], Vector3(0.25, 4.03, -1.34), 0.006, 38)
	_route_status = _label(anchors[0], "", Vector3(0, 1.58, -1.48), 0.006, 30)
	_paper(anchors[1], Vector3(0, 2.55, -1.64), Vector2(2.6, 1.25))
	_kit_status = _label(anchors[1], "", Vector3(0, 2.55, -1.6), 0.006, 32)
	for i in range(3):
		var x := -1.05 + i * 1.05
		_paper(anchors[2], Vector3(x, 2.7, -1.62), Vector2(0.94, 1.25))
		var icon := Sprite3D.new()
		icon.texture = load("res://assets/ui/shelter/crew.svg")
		icon.pixel_size = 0.007
		icon.position = Vector3(x, 2.92, -1.57)
		anchors[2].add_child(icon)
		_crew_cards.append(_label(anchors[2], "", Vector3(x, 2.43, -1.56), 0.0055, 34))


func _paper(parent: Node3D, point: Vector3, size: Vector2) -> Sprite3D:
	var paper := Sprite3D.new()
	paper.texture = load("res://assets/kenney/ui_adventure/panel_brown.png")
	paper.pixel_size = 0.01
	paper.scale = Vector3(size.x / (paper.texture.get_width() * 0.01), size.y / (paper.texture.get_height() * 0.01), 1.0)
	paper.position = point
	parent.add_child(paper)
	return paper


func _label(parent: Node3D, caption: String, point: Vector3, pixels: float, font_size: int) -> Label3D:
	var label := Label3D.new()
	label.text = caption
	label.font = InterfaceSkin.face(600)
	label.font_size = font_size
	label.outline_size = 0
	label.no_depth_test = true
	label.render_priority = 2
	label.pixel_size = pixels
	label.modulate = InterfaceSkin.INK
	label.position = point
	parent.add_child(label)
	return label
