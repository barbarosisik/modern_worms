class_name MatchArena
extends Node3D

signal hud_changed(state: MatchSimulation, power: float, angle: float, weapon: ArtilleryShot.Weapon)
signal match_finished(winner: int)

enum ComputerPhase { WAITING, SEARCHING, MOVING, AIMING }

const BLUE := Color(0.30, 0.76, 1.0)
const ORANGE := Color(1.0, 0.54, 0.32)
const ROCKET_COLOR := Color(1.0, 0.86, 0.48)
const GRENADE_COLOR := Color(0.65, 0.95, 0.46)
const START_ANGLE := 26.0
const CHARGE_SECONDS := 1.15
const FLASH_DURATION := 0.24
const COMPUTER_WAIT_TICKS := 12

@onready var terrain_mesh: TerrainMesh = $TerrainMesh
@onready var camera: Camera3D = $Camera3D
@onready var aim_line: MeshInstance3D = $AimLine
@onready var projectile: MeshInstance3D = $Projectile
@onready var flash: MeshInstance3D = $Impact
@onready var launch_sound: AudioStreamPlayer = $LaunchSound
@onready var impact_sound: AudioStreamPlayer = $ImpactSound
@onready var _shot_material := projectile.mesh.surface_get_material(0) as StandardMaterial3D

var simulation := MatchSimulation.new()
var computer_enabled := false
var _unit_views: Array[MeshInstance3D] = []
var _unit_labels: Array[Label3D] = []
var _angle := START_ANGLE
var _power := 0.0
var _weapon := ArtilleryShot.Weapon.ROCKET
var _charging := false
var _jump_requested := false
var _flash_time := 0.0
var _computer := ComputerOpponent.new()
var _computer_phase := ComputerPhase.WAITING
var _computer_ticks := 0


func _ready() -> void:
	camera.look_at(Vector3(15.5, 5.5, 0.0))
	launch_sound.stream = ArtilleryAudio.tone(0.17, 330.0, 150.0)
	impact_sound.stream = ArtilleryAudio.tone(0.28, 108.0, 32.0)
	for unit in simulation.units:
		_create_unit_view(unit)


func reset_match(against_computer: bool = false) -> void:
	computer_enabled = against_computer
	simulation.reset()
	terrain_mesh.rebuild_all(simulation.terrain)
	_reset_aim()
	_flash_time = 0.0
	flash.hide()
	launch_sound.stop()
	impact_sound.stop()
	_refresh_view()


func cancel_input() -> void:
	_power = 0.0
	_charging = false
	_jump_requested = false


func _unhandled_input(event: InputEvent) -> void:
	if simulation.phase != MatchSimulation.Phase.ACTIVE or is_computer_turn():
		return
	if event.is_action_pressed("unit_jump"):
		_jump_requested = true
	elif event.is_action_pressed("flip_facing"):
		simulation.active_unit().facing *= -1.0
	elif event.is_action_pressed("select_rocket"):
		_weapon = ArtilleryShot.Weapon.ROCKET
	elif event.is_action_pressed("select_grenade"):
		_weapon = ArtilleryShot.Weapon.GRENADE
	elif event.is_action_pressed("pass_turn"):
		simulation.pass_turn()
		cancel_input()
	elif event.is_action_pressed("fire"):
		_charging = true
	elif event.is_action_released("fire") and _charging:
		_fire_current_shot()


func is_computer_turn() -> bool:
	return computer_enabled and simulation.active_unit().team == 1


func computer_status() -> String:
	if not is_computer_turn() or simulation.phase != MatchSimulation.Phase.ACTIVE:
		return ""
	match _computer_phase:
		ComputerPhase.MOVING:
			return "Computer is moving."
		ComputerPhase.AIMING:
			return "Computer is aiming."
		_:
			return "Computer is choosing a shot."


func _physics_process(delta: float) -> void:
	var previous_turn := simulation.turn_number
	var previous_phase := simulation.phase
	var movement := 0.0
	if previous_phase == MatchSimulation.Phase.ACTIVE:
		if is_computer_turn():
			movement = _computer_movement(delta)
		else:
			var aim := Input.get_axis("aim_down", "aim_up")
			_angle = clampf(_angle + aim * 48.0 * delta, -35.0, 80.0)
			if _charging:
				_power = minf(_power + delta / CHARGE_SECONDS, 1.0)
			movement = Input.get_axis("unit_left", "unit_right")
	simulation.step(delta, movement, _jump_requested)
	_jump_requested = false
	if simulation.turn_number != previous_turn:
		_reset_aim()
	elif simulation.phase != MatchSimulation.Phase.ACTIVE:
		cancel_input()
	if simulation.last_blast != Vector2.INF:
		_present_blast()
	_flash_time = maxf(0.0, _flash_time - delta)
	flash.visible = _flash_time > 0.0
	if flash.visible:
		flash.scale = Vector3.ONE * lerpf(2.45, 0.62, _flash_time / FLASH_DURATION)
	_refresh_view()
	if previous_phase != MatchSimulation.Phase.FINISHED and simulation.phase == MatchSimulation.Phase.FINISHED:
		match_finished.emit(simulation.winner)


func _reset_aim() -> void:
	_angle = START_ANGLE
	_weapon = ArtilleryShot.Weapon.ROCKET
	cancel_input()
	_computer.reset()
	_computer_phase = ComputerPhase.WAITING
	_computer_ticks = 0


func _fire_current_shot() -> void:
	if simulation.fire(_angle, _power, _weapon):
		launch_sound.play()
	cancel_input()


func _computer_movement(delta: float) -> float:
	_computer_ticks += 1
	match _computer_phase:
		ComputerPhase.WAITING:
			if _computer_ticks >= COMPUTER_WAIT_TICKS:
				_computer.begin(simulation)
				_computer_phase = ComputerPhase.SEARCHING
		ComputerPhase.SEARCHING:
			if _computer.advance():
				var plan := _computer.best_plan
				if plan == null:
					simulation.pass_turn()
				elif is_zero_approx(plan.position.move_axis):
					_begin_computer_aim()
				else:
					_computer_ticks = 0
					_computer_phase = ComputerPhase.MOVING
		ComputerPhase.MOVING:
			if not simulation.active_unit().grounded:
				simulation.pass_turn()
			elif _computer_ticks <= ComputerOpponent.WALK_TICKS:
				return _computer.best_plan.position.move_axis
			elif _computer_ticks >= ComputerOpponent.WALK_TICKS + ComputerOpponent.STOP_TICKS:
				_begin_computer_aim()
		ComputerPhase.AIMING:
			var plan := _computer.best_plan
			_angle = move_toward(_angle, plan.angle, 76.0 * delta)
			_power = move_toward(_power, plan.power, delta / CHARGE_SECONDS)
			if _computer_ticks >= 18 and is_equal_approx(_angle, plan.angle) and is_equal_approx(_power, plan.power):
				_fire_current_shot()
	return 0.0


func _begin_computer_aim() -> void:
	var plan := _computer.best_plan
	simulation.active_unit().facing = plan.facing
	_weapon = plan.weapon
	_computer_ticks = 0
	_computer_phase = ComputerPhase.AIMING


func _present_blast() -> void:
	for chunk in simulation.dirty_chunks:
		terrain_mesh.rebuild_chunk(simulation.terrain, chunk)
	flash.position = _in_world(simulation.last_blast)
	_flash_time = FLASH_DURATION
	impact_sound.play()


func _create_unit_view(unit: MatchUnit) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = BLUE if unit.team == 0 else ORANGE
	material.roughness = 0.85
	var capsule := CapsuleMesh.new()
	capsule.radius = MatchUnit.HALF_WIDTH
	capsule.height = MatchUnit.HEIGHT
	capsule.material = material
	var body := MeshInstance3D.new()
	body.mesh = capsule
	add_child(body)
	_unit_views.append(body)
	var label := Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 46
	label.outline_size = 8
	label.pixel_size = 0.0078
	label.modulate = material.albedo_color.lightened(0.24)
	add_child(label)
	_unit_labels.append(label)


func _refresh_view() -> void:
	var active := simulation.active_unit()
	var can_aim := simulation.phase == MatchSimulation.Phase.ACTIVE and active.alive()
	for i in range(simulation.units.size()):
		var unit := simulation.units[i]
		var body := _unit_views[i]
		var label := _unit_labels[i]
		body.visible = unit.alive()
		label.visible = unit.alive()
		if body.visible:
			body.position = _in_world(unit.center())
			label.position = Vector3(unit.feet.x, unit.feet.y + 1.24, 0.58)
			label.text = "%s%d  ·  %d" % ["B" if unit.team == 0 else "O", unit.number, unit.health]
			if can_aim and unit == active:
				label.text = "▼\n" + label.text
				label.position.y += 0.22
	aim_line.visible = can_aim
	if can_aim:
		var aim := Vector2.from_angle(deg_to_rad(_angle))
		aim.x *= active.facing
		aim_line.rotation.z = aim.angle()
		aim_line.position = _in_world(active.center() + aim * 1.14)
	projectile.visible = simulation.shot != null
	if simulation.shot != null:
		projectile.position = _in_world(simulation.shot.position)
		_shot_material.albedo_color = ROCKET_COLOR if simulation.shot.weapon == ArtilleryShot.Weapon.ROCKET else GRENADE_COLOR
	hud_changed.emit(simulation, _power, _angle, _weapon)


func _in_world(point: Vector2) -> Vector3:
	return Vector3(point.x, point.y, 0.0)
