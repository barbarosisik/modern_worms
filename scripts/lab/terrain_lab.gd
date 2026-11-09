class_name TerrainLab
extends Node3D

signal hud_changed(status: String, power: float, angle: float)

const MIN_ANGLE := -35.0
const MAX_ANGLE := 75.0
const AIM_SPEED := 48.0
const CHARGE_TIME := 1.25
const FLASH_DURATION := 0.23

@onready var terrain_mesh: TerrainMesh = $TerrainMesh
@onready var camera: Camera3D = $Camera3D
@onready var target: MeshInstance3D = $Target
@onready var aim_line: MeshInstance3D = $AimLine
@onready var rocket_view: MeshInstance3D = $Rocket
@onready var flash: MeshInstance3D = $Impact
@onready var overlay: MeshInstance3D = $CollisionOutline
@onready var launch_sound: AudioStreamPlayer = $LaunchSound
@onready var impact_sound: AudioStreamPlayer = $ImpactSound

var simulation := TerrainSimulation.new()
var _angle := 0.0
var _power := 0.0
var _charging := false
var _flash_time := 0.0
var _status := "Ready. Press F for the first fixture shot."


func _ready() -> void:
	camera.look_at(Vector3(15.5, 6.8, 0.0))
	launch_sound.stream = ArtilleryAudio.tone(0.17, 330.0, 150.0)
	impact_sound.stream = ArtilleryAudio.tone(0.28, 108.0, 32.0)
	reset_lab()


func reset_lab() -> void:
	simulation.reset()
	_angle = 0.0
	cancel_charge()
	_flash_time = 0.0
	launch_sound.stop()
	impact_sound.stop()
	flash.hide()
	overlay.hide()
	_status = "Ready. Press F for the first fixture shot."
	terrain_mesh.rebuild_all(simulation.terrain)
	_refresh_view()


func cancel_charge() -> void:
	_charging = false
	_power = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_lab"):
		reset_lab()
	elif event.is_action_pressed("toggle_collision_overlay"):
		overlay.visible = not overlay.visible
		_refresh_overlay()
	elif event.is_action_pressed("fixture_shot"):
		_fire(TerrainSimulation.PRESET_VELOCITY)
	elif event.is_action_pressed("fire") and simulation.rocket == null:
		_charging = true
	elif event.is_action_released("fire") and _charging:
		var direction := Vector2.from_angle(deg_to_rad(_angle))
		_fire(direction * lerpf(9.0, 26.0, _power))


func _physics_process(delta: float) -> void:
	var rocket_active := simulation.rocket != null
	if not rocket_active:
		var aim := Input.get_axis("aim_down", "aim_up")
		_angle = clampf(_angle + aim * AIM_SPEED * delta, MIN_ANGLE, MAX_ANGLE)
	if _charging:
		_power = minf(_power + delta / CHARGE_TIME, 1.0)
	simulation.step(delta)
	if rocket_active and simulation.rocket == null:
		_finish_shot()
	_flash_time = maxf(0.0, _flash_time - delta)
	if _flash_time > 0.0:
		flash.scale = Vector3.ONE * lerpf(2.15, 0.65, _flash_time / FLASH_DURATION)
	else:
		flash.hide()
	_refresh_view()


func _fire(velocity: Vector2) -> void:
	if simulation.fire(velocity):
		cancel_charge()
		_status = "Rocket in flight."
		launch_sound.play()


func _finish_shot() -> void:
	if simulation.last_result == ArtilleryShot.Result.ESCAPED:
		_status = "Rocket left the arena."
		return
	for chunk in simulation.dirty_chunks:
		terrain_mesh.rebuild_chunk(simulation.terrain, chunk)
	var impact := simulation.last_impact
	_status = "Impact at (%.2f, %.2f)  ·  %d chunks rebuilt" % [
		impact.x, impact.y, simulation.dirty_chunks.size()
	]
	flash.position = Vector3(impact.x, impact.y, 0.0)
	_flash_time = FLASH_DURATION
	flash.show()
	impact_sound.play()
	_refresh_overlay()


func _refresh_view() -> void:
	target.position = Vector3(simulation.target_feet.x, simulation.target_feet.y + 0.37, 0.0)
	aim_line.rotation.z = deg_to_rad(_angle)
	aim_line.position = Vector3(TerrainSimulation.MUZZLE.x, TerrainSimulation.MUZZLE.y, 0.0)
	aim_line.position += Vector3(cos(aim_line.rotation.z), sin(aim_line.rotation.z), 0.0) * 0.85
	aim_line.visible = simulation.rocket == null
	rocket_view.visible = simulation.rocket != null
	if simulation.rocket != null:
		var point := simulation.rocket.position
		rocket_view.position = Vector3(point.x, point.y, 0.0)
	hud_changed.emit(_status, _power, _angle)


func _refresh_overlay() -> void:
	if not overlay.visible:
		return
	var outline := ImmediateMesh.new()
	outline.surface_begin(Mesh.PRIMITIVE_LINES)
	var grid := simulation.terrain
	for y in range(TerrainGrid.SIZE.y):
		for x in range(TerrainGrid.SIZE.x):
			var cell := Vector2i(x, y)
			if not grid.is_solid(cell):
				continue
			var lower := Vector2(cell) * TerrainGrid.CELL_SIZE
			var upper := lower + Vector2.ONE * TerrainGrid.CELL_SIZE
			if not grid.is_solid(cell + Vector2i.LEFT):
				_outline_edge(outline, lower, Vector2(lower.x, upper.y))
			if not grid.is_solid(cell + Vector2i.RIGHT):
				_outline_edge(outline, Vector2(upper.x, lower.y), upper)
			if not grid.is_solid(cell + Vector2i.UP):
				_outline_edge(outline, lower, Vector2(upper.x, lower.y))
			if not grid.is_solid(cell + Vector2i.DOWN):
				_outline_edge(outline, Vector2(lower.x, upper.y), upper)
	outline.surface_end()
	overlay.mesh = outline


func _outline_edge(outline: ImmediateMesh, a: Vector2, b: Vector2) -> void:
	# Draw the grid silhouette in front of the mesh so it stays visible in the side view.
	var depth := TerrainMesh.HALF_DEPTH + 0.04
	outline.surface_add_vertex(Vector3(a.x, a.y, depth))
	outline.surface_add_vertex(Vector3(b.x, b.y, depth))
