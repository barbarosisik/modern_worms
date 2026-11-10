class_name CampaignActor
extends Node3D

const CHARACTER := preload("res://assets/kenney/characters/characterMedium.fbx")
const DOG := preload("res://assets/quaternius/dog.fbx")
const ROCKET := preload("res://assets/kenney/weapons/blaster-o.glb")
const GRENADE := preload("res://assets/kenney/weapons/grenade-a.glb")
const CLIPS := {
	"idle": preload("res://assets/kenney/characters/idle.fbx"),
	"run": preload("res://assets/kenney/characters/run.fbx"),
	"jump": preload("res://assets/kenney/characters/jump.fbx"),
	"shoot": preload("res://assets/kenney/characters/shoot.fbx"),
}
var _model: Node3D
var _animation: AnimationPlayer
var _material := StandardMaterial3D.new()
var _is_dog := false
var _character := ""
var _weapon_pivot := Node3D.new()
var _launcher: Node3D
var _grenade: Node3D
var _shot_time := 0.0


func _init(character: String, outfit: int = 0) -> void:
	_character = character
	_is_dog = character == "Scout"
	_model = (DOG if _is_dog else CHARACTER).instantiate()
	add_child(_model)
	var bounds := _model_bounds(_model, Transform3D.IDENTITY)
	var height := 0.68 if _is_dog else 0.95
	var ratio := height / bounds.size.y
	_model.scale = Vector3.ONE * ratio
	_model.position = Vector3(-bounds.get_center().x, -bounds.position.y, -bounds.get_center().z) * ratio
	if _is_dog:
		_animation = _model.find_child("AnimationPlayer", true, false)
	else:
		_material.roughness = 0.85
		set_outfit(outfit)
		for mesh in _model.find_children("*", "MeshInstance3D", true, false):
			mesh.material_override = _material
		_animation = AnimationPlayer.new()
		_model.add_child(_animation)
		var library := AnimationLibrary.new()
		for clip_name in CLIPS:
			var source: Node = CLIPS[clip_name].instantiate()
			var player := source.find_child("AnimationPlayer", true, false) as AnimationPlayer
			for source_name in player.get_animation_list():
				if "Targeting" in source_name:
					continue
				var clip := player.get_animation(source_name).duplicate() as Animation
				clip.loop_mode = Animation.LOOP_LINEAR if clip_name in ["idle", "run"] else Animation.LOOP_NONE
				library.add_animation(clip_name, clip)
			source.free()
		_animation.add_animation_library("", library)
	add_child(_weapon_pivot)
	_weapon_pivot.position = Vector3(0.0, 0.55 if not _is_dog else 0.38, 0.12)
	_launcher = ROCKET.instantiate()
	_launcher.rotation.y = -PI / 2.0
	_launcher.scale = Vector3.ONE * 1.1
	_launcher.position.x = 0.22
	_weapon_pivot.add_child(_launcher)
	_grenade = GRENADE.instantiate()
	_grenade.scale = Vector3.ONE * 0.65
	_grenade.position.x = 0.22
	_weapon_pivot.add_child(_grenade)
	_weapon_pivot.hide()
	pose(1.0, 0.0, 0.0)


static func _model_bounds(node: Node, parent_transform: Transform3D) -> AABB:
	var transform := parent_transform
	if node is Node3D:
		transform = parent_transform * node.transform
	var result := AABB()
	if node is MeshInstance3D:
		result = transform * node.get_aabb()
	for child in node.get_children():
		var child_bounds := _model_bounds(child, transform)
		if child_bounds.has_volume():
			result = child_bounds if not result.has_volume() else result.merge(child_bounds)
	return result


func set_outfit(outfit: int) -> void:
	if _is_dog:
		return
	var skin := "survivorFemale" if _character == "Mara" else "survivorMale"
	if _character not in ["Mara", "Eli"]:
		skin = "militaryMale"
	var variant := "B" if outfit == 1 and _character in ["Mara", "Eli"] else "A"
	_material.albedo_texture = load("res://assets/kenney/characters/" + skin + variant + ".png")
	_material.albedo_color = Color("#ffb79e") if outfit == 2 else Color.WHITE


func pose(facing: float, speed: float, delta: float, grounded: bool = true) -> void:
	rotation.y = facing * 1.05
	_shot_time = maxf(0.0, _shot_time - delta)
	var clip := "idle"
	if _is_dog:
		clip = "DogArmature|Walking" if absf(speed) > 0.1 else "DogArmature|Idle"
		_animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	elif _shot_time > 0.0:
		clip = "shoot"
	elif not grounded:
		clip = "jump"
	elif absf(speed) > 0.1:
		clip = "run"
	if _animation.current_animation != clip:
		_animation.play(clip, 0.12)


func aim(facing: float, angle: float, weapon: ArtilleryShot.Weapon, active: bool) -> void:
	_weapon_pivot.visible = active
	_launcher.visible = weapon == ArtilleryShot.Weapon.ROCKET
	_grenade.visible = not _launcher.visible
	_weapon_pivot.basis = Basis(Vector3.UP, -rotation.y) * Basis(Vector3.BACK, deg_to_rad(angle if facing > 0.0 else 180.0 - angle))


func fire_animation() -> void:
	_shot_time = 0.5
