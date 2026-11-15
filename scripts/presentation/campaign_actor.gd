class_name CampaignActor
extends Node3D

const DOG := preload("res://assets/quaternius/dog.fbx")
const CAT := preload("res://assets/quaternius/cat.fbx")
const WOLF := preload("res://assets/quaternius/wolf.fbx")
const ROCKET := preload("res://assets/kenney/weapons/blaster-o.glb")
const GRENADE := preload("res://assets/kenney/weapons/grenade-a.glb")
var _model: Node3D
var _animation: AnimationPlayer
var _character := ""
var _weapon_pivot := Node3D.new()
var _launcher: Node3D
var _grenade: Node3D
var _idle := ""
var _walk := ""
var _shot_time := 0.0

func _init(character: String, outfit: int = 0) -> void:
	_character = character
	var source := CAT if character == "Mara" else (DOG if character in ["Eli", "Scout"] else WOLF)
	_model = source.instantiate()
	add_child(_model)
	_animation = _model.find_child("AnimationPlayer", true, false)
	if _animation != null:
		for clip in _animation.get_animation_list():
			if "idle" in clip.to_lower():
				_idle = clip
			if "walk" in clip.to_lower() or "run" in clip.to_lower():
				_walk = clip
			_animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
		if not _idle.is_empty():
			_animation.play(_idle)
			_animation.advance(0.0)
	set_outfit(outfit)
	add_child(_weapon_pivot)
	_weapon_pivot.position = Vector3(0.0, 0.5, 0.22)
	_launcher = ROCKET.instantiate()
	_launcher.rotation.y = -PI / 2.0
	_launcher.scale = Vector3.ONE * 0.9
	_launcher.position.x = 0.22
	_weapon_pivot.add_child(_launcher)
	_grenade = GRENADE.instantiate()
	_grenade.scale = Vector3.ONE * 0.65
	_grenade.position.x = 0.22
	_weapon_pivot.add_child(_grenade)
	_weapon_pivot.hide()
	pose(1.0, 0.0, 0.0)

func _ready() -> void:
	if _animation != null and not _idle.is_empty():
		_animation.play(_idle)
		_animation.advance(0.0)
	for skeleton in _model.find_children("*", "Skeleton3D", true, false):
		skeleton.force_update_all_bone_transforms()
	# Measured from the imported idle poses in Forward+. Cached so headless
	# tests and rendered play use identical placement without GPU skin baking.
	var bounds := AABB(Vector3(-5.559528, -0.019996, -1.462579), Vector3(9.979425, 5.305872, 2.215549))
	if _character == "Mara":
		bounds = AABB(Vector3(-2.44106, -0.011576, -0.712004), Vector3(5.675112, 4.43445, 1.42404))
	elif _character in ["Eli", "Scout"]:
		bounds = AABB(Vector3(-3.206179, -0.0651, -1.493581), Vector3(6.904972, 4.383379, 2.334721))
	var ratio := (0.62 if _character == "Scout" else 0.85) / bounds.size.y
	_model.scale = Vector3.ONE * ratio
	_model.position = Vector3(-bounds.get_center().x, -bounds.position.y, -bounds.get_center().z) * ratio


func set_outfit(outfit: int) -> void:
	var tint := [Color.WHITE, Color("#b8d5c0"), Color("#ecc0a4")][clampi(outfit, 0, 2)] as Color
	for mesh in _model.find_children("*", "MeshInstance3D", true, false):
		for i in range(mesh.mesh.get_surface_count()):
			var original: Material = mesh.mesh.surface_get_material(i)
			var material := original.duplicate() as StandardMaterial3D if original is StandardMaterial3D else StandardMaterial3D.new()
			material.albedo_color *= tint
			mesh.set_surface_override_material(i, material)

func pose(facing: float, speed: float, delta: float, _grounded: bool = true) -> void:
	rotation.y = 0.0 if facing > 0.0 else PI
	_shot_time = maxf(0.0, _shot_time - delta)
	if _animation != null:
		var clip := _walk if absf(speed) > 0.1 and not _walk.is_empty() else _idle
		if not clip.is_empty() and _animation.current_animation != clip:
			_animation.play(clip, 0.15)

func aim(facing: float, angle: float, weapon: ArtilleryShot.Weapon, active: bool) -> void:
	_weapon_pivot.visible = active or _shot_time > 0.0
	_launcher.visible = weapon == ArtilleryShot.Weapon.ROCKET
	_grenade.visible = not _launcher.visible
	_weapon_pivot.basis = Basis(Vector3.UP, -rotation.y) * Basis(Vector3.BACK, deg_to_rad(angle if facing > 0.0 else 180.0 - angle))
	_launcher.position.x = 0.22 - _shot_time * 0.12

func fire_animation() -> void:
	_shot_time = 0.5
