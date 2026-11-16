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
const FLASH_DURATION := 0.24
const COMPUTER_WAIT_TICKS := 12
const START_CAMERA_FOV := 23.0

@onready var terrain_mesh: TerrainMesh = $TerrainMesh
@onready var camera: Camera3D = $Camera3D
@onready var trajectory_guide: TrajectoryGuide = $TrajectoryGuide
@onready var projectile: MeshInstance3D = $Projectile
@onready var flash: MeshInstance3D = $Impact
@onready var supply_view: Node3D = $SupplyPickup
@onready var launch_sound: AudioStreamPlayer = $LaunchSound
@onready var impact_sound: AudioStreamPlayer = $ImpactSound
@onready var supply_sound: AudioStreamPlayer = $SupplySound
@onready var _shot_material := projectile.mesh.surface_get_material(0) as StandardMaterial3D

var _trail := MeshInstance3D.new()
var _trail_points: Array[Vector3] = []
var _tracer := MeshInstance3D.new()
var _tracer_time := 0.0
var _damage_labels: Array[Label3D] = []
var _previous_health: Array[int] = []
var _rocket_view: Node3D
var _grenade_view: Node3D
var battlefield := Battlefield.new()
var _home_camera := Transform3D.IDENTITY
var _pan_button := MOUSE_BUTTON_NONE
var _pan_anchor := Vector2.ZERO
var simulation := MatchSimulation.new()
var computer_enabled := false
var skirmish_map := 0
var _unit_views: Array[Node3D] = []
var _unit_labels: Array[Label3D] = []
var _rescue_view: CampaignActor
var _angle := START_ANGLE
var _power := 0.0
var _weapon := ArtilleryShot.Weapon.ROCKET
var _aim_controls := AimControls.new()
var _jump_requested := false
var _flash_time := 0.0
var _supply_notice_time := 0.0
var _supply_notice_team := -1
var _computer := ComputerOpponent.new()
var _computer_phase := ComputerPhase.WAITING
var _computer_ticks := 0


func _ready() -> void:
	add_child(battlefield)
	add_child(_tracer)
	add_child(_trail)
	var tracer_material := StandardMaterial3D.new()
	tracer_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tracer_material.albedo_color = Color("#ffdc82")
	_tracer.material_override = tracer_material
	_trail.material_override = tracer_material
	var feedback_layer := CanvasLayer.new()
	add_child(feedback_layer)
	var feedback := preload("res://scripts/presentation/drag_feedback.gd").new()
	feedback.arena = self
	feedback_layer.add_child(feedback)
	projectile.mesh = null
	_rocket_view = preload("res://assets/kenney/weapons/bullet-foam-tip.glb").instantiate()
	projectile.add_child(_rocket_view)
	_rocket_view.scale = Vector3.ONE * 0.8
	_grenade_view = preload("res://assets/kenney/weapons/grenade-a.glb").instantiate()
	projectile.add_child(_grenade_view)
	_grenade_view.scale = Vector3.ONE * 0.7
	var crate := preload("res://assets/kenney/weapons/crate-small.glb").instantiate() as Node3D
	supply_view.get_node("Crate").hide()
	supply_view.add_child(crate)
	crate.scale = Vector3.ONE * 0.7
	crate.position.y = -0.2
	camera.look_at(Vector3(15.5, 5.5, 0.0))
	get_window().focus_exited.connect(_cancel_human_input)
	launch_sound.stream = ArtilleryAudio.tone(0.17, 330.0, 150.0)
	impact_sound.stream = ArtilleryAudio.tone(0.28, 108.0, 32.0)
	supply_sound.stream = ArtilleryAudio.tone(0.20, 440.0, 880.0)
	_rescue_view = CampaignActor.new(CampaignRun.ROSTER[2])
	add_child(_rescue_view)
	_rescue_view.hide()
	var marker := _create_label(Color("#ffda83"))
	marker.text = "RESCUE SCOUT"
	marker.position = Vector3(0.0, 1.08, 0.58)
	_rescue_view.add_child(marker)


func reset_match(against_computer: bool = false, mission: CampaignMission = null) -> void:
	cancel_camera_pan()
	computer_enabled = against_computer
	simulation.reset(mission, skirmish_map)
	_computer.error_scale = mission.cpu_error_scale if mission != null else 1.0
	var camera_focus := Vector3(15.5, 5.5, 0.0)
	if mission != null and mission.index == 0:
		camera.position = Vector3(14.4, 8.6, 32.5)
		camera_focus = Vector3(12.5, 4.4, 0.0)
	else:
		camera.position = Vector3(18.5, 11.0, 44.0)
	# Keep the opening team in the left third of a slightly closer view.
	var team_center := 0.0
	var team_count := 0
	for unit in simulation.units:
		if unit.team == 0:
			team_center += unit.feet.x
			team_count += 1
	if team_count > 0:
		var shift := team_center / team_count + 4.0 - camera_focus.x
		camera.position.x += shift
		camera_focus.x += shift
	camera.look_at(camera_focus)
	camera.fov = START_CAMERA_FOV
	_home_camera = camera.transform
	battlefield.dress(simulation.terrain, mission.index + 3 if mission != null else skirmish_map, simulation.units)
	terrain_mesh.rebuild_all(simulation.terrain)
	_rebuild_unit_views()
	_previous_health.clear()
	for unit in simulation.units:
		_previous_health.append(unit.health)
	_tracer.hide()
	_trail.hide()
	_trail_points.clear()
	for label in _damage_labels:
		label.queue_free()
	_damage_labels.clear()
	_reset_aim()
	_flash_time = 0.0
	flash.hide()
	launch_sound.stop()
	impact_sound.stop()
	supply_sound.stop()
	_supply_notice_time = 0.0
	_refresh_view()


func cancel_input() -> void:
	_power = 0.0
	_aim_controls.cancel()
	_jump_requested = false


func _cancel_human_input() -> void:
	cancel_camera_pan()
	if not is_computer_turn():
		cancel_input()


func _input(event: InputEvent) -> void:
	# Capture a camera drag through HUD crossings and modifier-key releases.
	if _pan_button != MOUSE_BUTTON_NONE:
		if event is InputEventMouseMotion:
			_pan_camera(_pan_anchor, event.position)
			_pan_anchor = event.position
			get_viewport().set_input_as_handled()
			return
		if event is InputEventMouseButton:
			if event.button_index == _pan_button and not event.pressed:
				cancel_camera_pan()
			get_viewport().set_input_as_handled()
			return
	if simulation.phase != MatchSimulation.Phase.ACTIVE or is_computer_turn():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		cancel_input()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and _aim_controls.is_dragging():
		_aim_controls.update_drag(camera, event.position)
	elif _aim_controls.owns_release(event):
		if event is InputEventMouseButton:
			_aim_controls.update_drag(camera, event.position)
			_power = _aim_controls.power()
			_apply_drag_direction()
		if not _aim_controls.is_dragging() or _power > 0.0:
			_fire_current_shot()
		else:
			cancel_input()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if _handle_camera_input(event) or _pan_button != MOUSE_BUTTON_NONE:
		return
	if simulation.phase != MatchSimulation.Phase.ACTIVE or is_computer_turn():
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_3:
		select_weapon(ArtilleryShot.Weapon.SHOTGUN)
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
	elif event.is_action_pressed("pointer_fire") and event is InputEventMouseButton:
		_aim_controls.begin_drag(event.position)
	elif event.is_action_pressed("fire"):
		_aim_controls.begin_keyboard()


func cancel_camera_pan() -> void:
	_pan_button = MOUSE_BUTTON_NONE


func _handle_camera_input(event: InputEvent) -> bool:
	# View controls remain available during CPU turns and flying shots.
	if _aim_controls.is_aiming():
		return false
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_MIDDLE or (event.button_index == MOUSE_BUTTON_LEFT and event.shift_pressed):
			_pan_button = event.button_index
			_pan_anchor = event.position
		elif event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			camera.fov = clampf(camera.fov + (-2.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 2.0), 18.0, 40.0)
		else:
			return false
	elif event is InputEventKey and event.pressed and event.keycode == KEY_HOME:
		cancel_camera_pan()
		camera.transform = _home_camera
		camera.fov = START_CAMERA_FOV
	else:
		return false
	get_viewport().set_input_as_handled()
	return true


func _pan_camera(from: Vector2, to: Vector2) -> void:
	var start := AimControls._point_on_plane(camera, from)
	var end := AimControls._point_on_plane(camera, to)
	if start == Vector2.INF or end == Vector2.INF:
		return
	# Bound the view's centre to the playable map, rather than letting it get lost.
	var center := AimControls._point_on_plane(camera, get_viewport().get_visible_rect().size * 0.5)
	var map_size := Vector2(TerrainGrid.SIZE) * TerrainGrid.CELL_SIZE
	var bounded := (center + start - end).clamp(Vector2.ZERO, map_size)
	camera.position += Vector3(bounded.x - center.x, bounded.y - center.y, 0.0)


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


func supply_notice() -> String:
	if _supply_notice_time <= 0.0:
		return ""
	return "%s collected a supply." % MatchSimulation.TEAM_NAMES[_supply_notice_team]


func _physics_process(delta: float) -> void:
	_tracer_time = maxf(0.0,_tracer_time-delta)
	_tracer.visible = _tracer_time > 0.0
	for label in _damage_labels.duplicate():
		label.position.y += delta * 0.7
		label.modulate.a -= delta * 0.75
		if label.modulate.a <= 0.0:
			_damage_labels.erase(label)
			label.queue_free()
	var previous_turn := simulation.turn_number
	var previous_phase := simulation.phase
	var movement := 0.0
	if previous_phase == MatchSimulation.Phase.ACTIVE:
		if is_computer_turn():
			movement = _computer_movement(delta)
		else:
			var aim := Input.get_axis("aim_down", "aim_up")
			if not _aim_controls.is_dragging() and not is_zero_approx(aim):
				_angle = clampf(_angle + aim * AimControls.AIM_SPEED * delta,
					AimControls.MIN_ANGLE, AimControls.MAX_ANGLE)
			_aim_controls.tick()
			_power = _aim_controls.power()
			movement = Input.get_axis("unit_left", "unit_right")
	simulation.step(delta, movement, _jump_requested)
	_supply_notice_time = maxf(0.0, _supply_notice_time - delta)
	if simulation.collected_supply_team >= 0:
		_supply_notice_team = simulation.collected_supply_team
		_supply_notice_time = 1.6
		supply_sound.play()
	_jump_requested = false
	if simulation.turn_number != previous_turn:
		_reset_aim()
	elif simulation.phase != MatchSimulation.Phase.ACTIVE:
		cancel_input()
	if simulation.phase == MatchSimulation.Phase.ACTIVE and not is_computer_turn():
		_apply_drag_direction()
	if simulation.last_blast != Vector2.INF:
		_present_blast()
	_flash_time = maxf(0.0, _flash_time - delta)
	flash.visible = _flash_time > 0.0
	if flash.visible:
		flash.scale = Vector3.ONE * lerpf(2.45, 0.62, _flash_time / FLASH_DURATION)
	_refresh_view(delta)
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
		(_unit_views[simulation.turn_index] as CampaignActor).fire_animation()
		launch_sound.play()
		if _weapon == ArtilleryShot.Weapon.SHOTGUN:
			var lines := ImmediateMesh.new()
			lines.surface_begin(Mesh.PRIMITIVE_LINES)
			for point in simulation.pellet_traces:
				lines.surface_add_vertex(Vector3(point.x,point.y,0.7))
			lines.surface_end()
			_tracer.mesh = lines
			_tracer.show()
			_tracer_time = 0.22
			if simulation.collected_supply_team >= 0:
				_supply_notice_team = simulation.collected_supply_team
				_supply_notice_time = 1.6
				supply_sound.play()
	cancel_input()


func _apply_drag_direction() -> void:
	var active := simulation.active_unit()
	var direction := _aim_controls.drag_direction
	if direction == Vector2.ZERO:
		return
	if not is_zero_approx(direction.x):
		active.facing = signf(direction.x)
	_angle = AimControls.elevation(direction)


func _computer_movement(delta: float) -> float:
	_computer_ticks += 1
	match _computer_phase:
		ComputerPhase.WAITING:
			if _computer_ticks >= COMPUTER_WAIT_TICKS:
				_computer.begin(simulation)
				_computer_phase = ComputerPhase.SEARCHING
		ComputerPhase.SEARCHING:
			if _computer.advance():
				var plan := _computer.chosen_plan
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
				return _computer.chosen_plan.position.move_axis
			elif _computer_ticks >= ComputerOpponent.WALK_TICKS + ComputerOpponent.STOP_TICKS:
				_begin_computer_aim()
		ComputerPhase.AIMING:
			var plan := _computer.chosen_plan
			_angle = move_toward(_angle, plan.release_angle, 76.0 * delta)
			_power = move_toward(_power, plan.release_power, delta * 0.87)
			if _computer_ticks >= 18 and _angle == plan.release_angle and _power == plan.release_power:
				_fire_current_shot()
	return 0.0


func _begin_computer_aim() -> void:
	var plan := _computer.chosen_plan
	simulation.active_unit().facing = plan.facing
	_weapon = plan.weapon
	_computer_ticks = 0
	_computer_phase = ComputerPhase.AIMING


func _present_blast() -> void:
	terrain_mesh.rebuild_dirty(simulation.terrain, simulation.dirty_chunks)
	battlefield.update_support(simulation.terrain)
	flash.position = _in_world(simulation.last_blast)
	_flash_time = FLASH_DURATION
	impact_sound.play()


func _rebuild_unit_views() -> void:
	for view in _unit_views:
		remove_child(view)
		view.queue_free()
	for label in _unit_labels:
		remove_child(label)
		label.queue_free()
	_unit_views.clear()
	_unit_labels.clear()
	for unit in simulation.units:
		var team_color := BLUE if unit.team == 0 else ORANGE
		var identity := unit.display_name if not unit.display_name.is_empty() else (("Miska" if unit.number == 1 else "Nova") if unit.team == 0 else "Raider")
		var body := CampaignActor.new(identity, unit.outfit)
		add_child(body)
		_unit_views.append(body)
		var label := _create_label(team_color.lightened(0.24))
		add_child(label)
		_unit_labels.append(label)


func _create_capsule(team_color: Color) -> Node3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = team_color
	material.roughness = 0.85
	var capsule := CapsuleMesh.new()
	capsule.radius = MatchUnit.HALF_WIDTH
	capsule.height = MatchUnit.HEIGHT
	capsule.material = material
	var mesh := MeshInstance3D.new()
	mesh.mesh = capsule
	return mesh


func _create_label(tint: Color) -> Label3D:
	var label := Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 46
	label.outline_size = 8
	label.pixel_size = 0.0078
	label.modulate = tint
	return label


func _refresh_view(delta: float = 0.0) -> void:
	var active := simulation.active_unit()
	var can_aim := simulation.phase == MatchSimulation.Phase.ACTIVE and active.alive()
	for i in range(simulation.units.size()):
		var unit := simulation.units[i]
		if i < _previous_health.size() and unit.health < _previous_health[i]:
			(_unit_views[i] as CampaignActor).hurt_animation()
			var damage := _create_label(Color("#ffcf75"))
			damage.text = "-%d" % (_previous_health[i]-unit.health)
			damage.position = _in_world(unit.feet) + Vector3(0,1.7,0.8)
			add_child(damage)
			_damage_labels.append(damage)
			_previous_health[i] = unit.health
		var body := _unit_views[i]
		var label := _unit_labels[i]
		body.visible = unit.alive()
		label.visible = unit.alive()
		if body.visible:
			if body is CampaignActor:
				body.position = _in_world(unit.feet)
				body.pose(unit.facing, unit.velocity.x, delta, unit.grounded)
				body.aim(unit.facing, _angle, _weapon, can_aim and unit == active)
			else:
				body.position = _in_world(unit.center())
			label.position = Vector3(unit.feet.x, unit.feet.y + 1.24, 0.58)
			var call_sign := unit.display_name
			if call_sign.is_empty():
				call_sign = "%s%d" % ["B" if unit.team == 0 else "O", unit.number]
			label.text = "%s  ·  %d" % [call_sign, unit.health]
			if can_aim and unit == active:
				label.text = "▼\n" + label.text
				label.position.y += 0.22
	var target := simulation.rescue_target
	_rescue_view.visible = target != null and target.alive() and not simulation.rescued
	if _rescue_view.visible:
		_rescue_view.position = _in_world(target.feet)
	if can_aim and active.team == 0:
		var preview := simulation.build_shot(_angle, _power, _weapon, active.facing)
		trajectory_guide.preview(preview, simulation.terrain, simulation.living_centers(), active.guide_tier)
	else:
		trajectory_guide.hide()
	supply_view.visible = simulation.supply_position != Vector2.INF
	if supply_view.visible:
		supply_view.position = _in_world(simulation.supply_position)
	projectile.visible = simulation.shot != null
	_trail.visible = projectile.visible
	if projectile.visible:
		_trail_points.append(_in_world(simulation.shot.position) + Vector3(0,0,0.7))
		if _trail_points.size() > 18:
			_trail_points.pop_front()
		if _trail_points.size() > 1:
			var trail_mesh := ImmediateMesh.new()
			trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
			for point in _trail_points:
				trail_mesh.surface_add_vertex(point)
			trail_mesh.surface_end()
			_trail.mesh = trail_mesh
	else:
		_trail_points.clear()
	if simulation.shot != null:
		projectile.position = _in_world(simulation.shot.position)
		_rocket_view.visible = simulation.shot.weapon == ArtilleryShot.Weapon.ROCKET
		_grenade_view.visible = not _rocket_view.visible
		projectile.rotation.z = simulation.shot.velocity.angle()
		_grenade_view.rotation.z = simulation.shot.age * 5.0
	hud_changed.emit(simulation, _power, _angle, _weapon)


func _in_world(point: Vector2) -> Vector3:
	return Vector3(point.x, point.y, 0.0)


func select_weapon(weapon: ArtilleryShot.Weapon) -> void:
	if simulation.phase == MatchSimulation.Phase.ACTIVE and not is_computer_turn():
		cancel_input()
		_weapon = weapon
