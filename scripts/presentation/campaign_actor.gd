class_name CampaignActor
extends Node3D

const DOG := preload("res://assets/quaternius/dog.fbx")
const CAT := preload("res://assets/quaternius/cat.fbx")
const WOLF := preload("res://assets/quaternius/wolf.fbx")
const ROCKET := preload("res://assets/kenney/weapons/blaster-o.glb")
const GRENADE := preload("res://assets/kenney/weapons/grenade-a.glb")
const SHOTGUN := preload("res://assets/kenney/weapons/blaster-n.glb")
const OUTFIT_TINTS := [Color.WHITE, Color("#b8d5c0"), Color("#ecc0a4")]
const NOVA_COAT := Color("#a9accb")
const BLEND_TIME := 0.14
const RECOIL_TIME := 0.28
const LOCOMOTION := &"locomotion"

var _cartoon := false
var _model: Node3D
var _animation: AnimationPlayer
var _character: String
var _idle := &""
var _walk := &""
var _jump := &""
var _pain := &""
var _victory := &""
var _clip := &""

var _weapon_pivot := Node3D.new()
var _weapon_views: Array[Node3D] = []
var _left_paw: Node3D
var _right_paw: Node3D
var _equipped := false
var _aiming := false
var _angle := 0.0
var _weapon := ArtilleryShot.Weapon.ROCKET
var _hold_weight := 0.0
var _shot_angle := 0.0
var _shot_facing := 1.0
var _shot_weapon := ArtilleryShot.Weapon.ROCKET
var _shot_time := 0.0
var _hurt_time := 0.0
var _victory_time := 0.0
var _facing := 1.0
var _pose_time := 0.0
var _rest_scale := Vector3.ONE
var _rest_position := Vector3.ZERO


func _init(character: String, outfit: int = 0) -> void:
	_character = character
	var is_cat := character in ["Miska", "Nova"]
	var source := CAT if is_cat else (DOG if character == "Scout" else WOLF)
	var species := "maple-the-cat" if is_cat else ("ollie-the-terrier" if character == "Scout" else "ziggy-the-wolf")
	var path := "res://assets/local_plumberry/" + species + ".glb"
	_cartoon = ResourceLoader.exists(path)
	_model = (load(path) as PackedScene).instantiate() if _cartoon else source.instantiate()
	add_child(_model)
	set_outfit(outfit)


func _ready() -> void:
	set_process(false)
	_animation = _model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_setup_clips()
	_play_clip(_idle, 0.0, 0.0)
	for skeleton in _model.find_children("*", "Skeleton3D", true, false):
		skeleton.force_update_all_bone_transforms()
	# Fallback FBX bounds come from the rendered idle pose. Headless and
	# Forward+ use the same grounding and height normalization.
	var bounds := AABB(Vector3(-5.559528, -0.019996, -1.462579), Vector3(9.979425, 5.305872, 2.215549))
	if _character in ["Miska", "Nova"]:
		bounds = AABB(Vector3(-2.44106, -0.011576, -0.712004), Vector3(5.675112, 4.43445, 1.42404))
	elif _character == "Scout":
		bounds = AABB(Vector3(-3.206179, -0.0651, -1.493581), Vector3(6.904972, 4.383379, 2.334721))
	if _cartoon:
		bounds = _bounds(_model, Transform3D.IDENTITY)
		_left_paw = _model.find_child("socket_hand_l", true, false) as Node3D
		_right_paw = _model.find_child("socket_hand_r", true, false) as Node3D
		if _character == "Nova":
			var head := _model.find_child("head", true, false) as Node3D
			if head != null:
				_add_nova_bow(head)
	var ratio := (0.78 if _character == "Scout" else 1.05) / bounds.size.y
	_rest_scale = Vector3.ONE * ratio
	_rest_position = Vector3(-bounds.get_center().x, -bounds.position.y, -bounds.get_center().z) * ratio
	_model.scale = _rest_scale
	_model.position = _rest_position
	add_child(_weapon_pivot)
	# Align each grip to the pivot. The Kenney blasters face -Z in their
	# source scenes, while this pivot aims along +X.
	_add_weapon(ROCKET, 0.94, Vector3(0.0, -0.10, 0.103), -PI / 2.0)
	_add_weapon(GRENADE, 0.80, Vector3(-0.012, 0.067, -0.01), 0.0)
	_add_weapon(SHOTGUN, 0.87, Vector3(0.0, -0.102, 0.070), -PI / 2.0)
	_weapon_pivot.hide()


func _setup_clips() -> void:
	if _animation == null:
		return
	# Sample the clip before posing the arm sockets each frame.
	_animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var loops := AnimationLibrary.new()
	for clip in _animation.get_animation_list():
		# The FBX names include an armature prefix. The GLBs use bare names.
		match String(clip).rsplit("|", true, 1)[-1].to_lower():
			"idle", "walk", "walking":
				var idle := String(clip).to_lower().ends_with("idle")
				var key := &"idle" if idle else &"walk"
				var loop := _animation.get_animation(clip).duplicate() as Animation
				loop.loop_mode = Animation.LOOP_LINEAR
				loops.add_animation(key, loop)
				if idle:
					_idle = &"locomotion/idle"
				else:
					_walk = &"locomotion/walk"
			"jump":
				_jump = clip
			"pain":
				_pain = clip
			"celebrate":
				_victory = clip
	if loops.get_animation_list().size() > 0:
		_animation.add_animation_library(LOCOMOTION, loops)


func set_outfit(outfit: int) -> void:
	var tint: Color = OUTFIT_TINTS[clampi(outfit, 0, OUTFIT_TINTS.size() - 1)]
	if _character == "Nova":
		tint *= NOVA_COAT
	for mesh in _model.find_children("*", "MeshInstance3D", true, false):
		if mesh.get_parent().name == &"NovaBow":
			continue
		for i in range(mesh.mesh.get_surface_count()):
			var original: Material = mesh.mesh.surface_get_material(i)
			var material := original.duplicate() as StandardMaterial3D if original is StandardMaterial3D else StandardMaterial3D.new()
			material.albedo_color *= tint
			material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
			material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
			material.roughness = 1.0
			if mesh.name == &"head_geo" and material.albedo_texture != null:
				# A small texture-based fill keeps the eyes readable in scene shadow.
				material.emission_enabled = true
				material.emission = material.albedo_color
				material.emission_texture = material.albedo_texture
				material.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
				material.emission_energy_multiplier = 0.15
			mesh.set_surface_override_material(i, material)


func _add_nova_bow(head: Node3D) -> void:
	var bow := Node3D.new()
	bow.name = "NovaBow"
	head.add_child(bow)
	bow.position = Vector3(0.0, 0.285, 0.115)
	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = Color("#b54461")
	cloth.roughness = 1.0
	var loop := SphereMesh.new()
	loop.radius = 0.061
	loop.height = 0.122
	loop.radial_segments = 10
	loop.rings = 5
	loop.material = cloth
	for side in [-1.0, 1.0]:
		var lobe := MeshInstance3D.new()
		lobe.mesh = loop
		bow.add_child(lobe)
		lobe.position.x = side * 0.051
		lobe.rotation.z = side * -0.95
		lobe.scale = Vector3(0.60, 1.0, 0.36)
	var knot := MeshInstance3D.new()
	knot.mesh = loop
	bow.add_child(knot)
	knot.scale = Vector3(0.43, 0.45, 0.44)
	knot.position.z = 0.011


func pose(facing: float, speed: float, delta: float, grounded: bool = true) -> void:
	_facing = facing
	_pose_time += delta
	_hurt_time = maxf(0.0, _hurt_time - delta)
	_shot_time = maxf(0.0, _shot_time - delta)
	_victory_time = maxf(0.0, _victory_time - delta)
	var hurt := _hurt_time > 0.0
	var firing := _shot_time > 0.0 and not hurt
	var celebrating := _victory_time > BLEND_TIME
	var shown_facing := _shot_facing if firing else facing
	rotation.y = shown_facing * 0.9 if _cartoon else (0.0 if shown_facing > 0.0 else PI)
	var walking := grounded and absf(speed) > 0.1
	var clip := _idle
	if celebrating:
		clip = _victory if not _victory.is_empty() else _idle
	elif hurt:
		clip = _pain if not _pain.is_empty() else _idle
	elif not grounded:
		clip = _jump if not _jump.is_empty() else _idle
	elif walking and not firing and not _walk.is_empty():
		clip = _walk
	var rate := clampf(absf(speed) / 2.3, 0.75, 1.75) if walking and clip == _walk else 1.0
	_play_clip(clip, delta * rate)

	var recoil := pow(_shot_time / RECOIL_TIME, 2.0) if firing else 0.0
	var bounce := 0.0
	var lean := -0.10 * recoil
	if celebrating and _victory.is_empty():
		bounce = sin(clampf((_victory_time - BLEND_TIME) / 0.7, 0.0, 1.0) * PI) * 0.11
	elif hurt and _pain.is_empty():
		lean = sin(_hurt_time / 0.48 * PI) * -0.17
	elif not grounded and _jump.is_empty() and not firing:
		lean = 0.12
	var breath := sin(_pose_time * 3.0) * 0.014
	_model.scale = _rest_scale * Vector3(1.0 + 0.035 * recoil, 1.0 + breath, 1.0 + 0.035 * recoil)
	_model.position = _rest_position + basis.inverse() * Vector3(-shown_facing * 0.075 * recoil, bounce, 0.0)
	_model.rotation.z = lean * (shown_facing if _cartoon else 1.0)

	var hold := (_equipped or firing) and not hurt and not celebrating
	var weight := 1.0 if _aiming or firing else (0.82 if walking else 0.93)
	var target_weight := weight if hold else 0.0
	_hold_weight = target_weight if delta == 0.0 else move_toward(_hold_weight, target_weight, delta / BLEND_TIME)
	if firing:
		_present_weapon(shown_facing, _shot_angle, _shot_weapon)
	elif hold:
		_present_weapon(shown_facing, _angle, _weapon)
	else:
		if _hold_weight > 0.0 and not hurt and not celebrating:
			_pose_paw(shown_facing, _angle)
		_weapon_pivot.hide()


func _play_clip(clip: StringName, delta: float, blend: float = BLEND_TIME) -> void:
	if _animation == null or clip.is_empty():
		return
	if _clip != clip:
		_clip = clip
		_animation.play(clip, blend)
	_animation.advance(delta)


func equip(angle: float, weapon: ArtilleryShot.Weapon, armed: bool, aiming: bool) -> void:
	_angle = angle
	_weapon = weapon
	_equipped = armed
	_aiming = aiming


func _present_weapon(facing: float, angle: float, weapon: ArtilleryShot.Weapon) -> void:
	for i in range(_weapon_views.size()):
		_weapon_views[i].visible = i == weapon

	var paw := _pose_paw(facing, angle)
	if paw != null:
		_weapon_pivot.position = to_local(paw.global_position)
	else:
		# The older quadrupeds have no sockets for held props.
		_weapon_pivot.position = basis.inverse() * Vector3(facing * 0.22, 0.47, 0.25)

	var elevation := deg_to_rad(angle * 0.45 if weapon == ArtilleryShot.Weapon.GRENADE else angle)
	var direction := Vector3(cos(elevation) * facing, sin(elevation), 0.0)
	# Flip the depth axis too, so the grip stays upright when aiming left.
	var depth := Vector3.BACK * facing
	_weapon_pivot.basis = basis.inverse() * Basis(direction, depth.cross(direction), depth)
	_weapon_pivot.show()


func _pose_paw(facing: float, angle: float) -> Node3D:
	var paw := _right_paw if facing > 0.0 else _left_paw
	if paw == null:
		return null
	var arm := paw.get_parent_node_3d()
	var shoulder := arm.get_parent_node_3d()
	# Place the near forepaw in front of the cheek and lift it as aim rises.
	_point_joint(shoulder, arm.position, Vector3(facing * 0.74, -0.37, 0.64))
	var lift := sin(deg_to_rad(angle)) * 0.42 - 0.23
	_point_joint(arm, paw.position, Vector3(facing * 0.62, lift, 0.77))
	return paw


func _point_joint(joint: Node3D, offset: Vector3, direction: Vector3) -> void:
	var target := (joint.get_parent_node_3d().global_basis.inverse() * direction).normalized()
	var start := joint.quaternion
	var current := (start * offset).normalized()
	joint.quaternion = start.slerp(Quaternion(current, target) * start, _hold_weight)


func _add_weapon(source: PackedScene, size: float, grip: Vector3, yaw: float) -> void:
	var view := source.instantiate() as Node3D
	_weapon_pivot.add_child(view)
	view.rotation.y = yaw
	view.scale = Vector3.ONE * size
	view.position = -(view.basis * grip)
	_weapon_views.append(view)


func fire_animation(facing: float, angle: float, weapon: ArtilleryShot.Weapon) -> void:
	_shot_facing = facing
	_shot_angle = angle
	_shot_weapon = weapon
	_shot_time = RECOIL_TIME


func hurt_animation() -> void:
	_hurt_time = _animation.get_animation(_pain).length if not _pain.is_empty() else 0.48
	if not _pain.is_empty() and _clip == _pain:
		_animation.stop(true)
		_clip = &""


func celebrate() -> void:
	_hurt_time = 0.0
	_shot_time = 0.0
	_equipped = false
	var duration := _animation.get_animation(_victory).length if not _victory.is_empty() else 0.7
	_victory_time = duration + BLEND_TIME
	# The result panel pauses the match. Only this actor's cosmetic pose advances.
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)


func _process(delta: float) -> void:
	pose(_facing, 0.0, delta)
	if _victory_time <= 0.0:
		set_process(false)
		process_mode = Node.PROCESS_MODE_INHERIT


static func _bounds(node: Node, parent_transform: Transform3D) -> AABB:
	var transform := parent_transform
	if node is Node3D:
		transform *= node.transform
	var result := AABB()
	if node is MeshInstance3D:
		result = transform * node.get_aabb()
	for child in node.get_children():
		var box := _bounds(child, transform)
		if box.has_volume():
			result = result.merge(box) if result.has_volume() else box
	return result
