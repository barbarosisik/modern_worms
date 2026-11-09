class_name CampaignActor
extends Node3D

const BOOTS := Color("#213038")
const STRAP := Color("#e0bb68")
const SCOUT_FUR := Color("#b6783e")
const SCOUT_DARK := Color("#71452f")

var _jacket: StandardMaterial3D
var _is_dog := false
var _stride := 0.0
var _legs: Array[MeshInstance3D] = []


func _init(character: String, outfit: int = 0) -> void:
	_is_dog = character == "Scout"
	if _is_dog:
		_build_dog()
	else:
		_build_person(character, outfit)


func set_outfit(outfit: int) -> void:
	_jacket.albedo_color = CampaignRun.OUTFIT_COLORS[outfit]


func pose(facing: float, speed: float, delta: float) -> void:
	if _is_dog:
		rotation.y = PI if facing < 0.0 else 0.0
	else:
		rotation.y = facing * 0.42
	if absf(speed) > 0.1:
		_stride += absf(speed) * delta * 7.0
		for i in range(_legs.size()):
			_legs[i].rotation.x = sin(_stride + PI * (i % 2)) * 0.28
	else:
		_stride = 0.0
		for leg in _legs:
			leg.rotation.x = 0.0


func _build_person(character: String, outfit: int) -> void:
	var is_mara := character == "Mara"
	var is_rescuer := is_mara or character == "Eli"
	var skin := Color("#ae745b") if is_mara else Color("#d1a080")
	var hair := Color("#362627") if is_mara else Color("#654737")
	_jacket = _material(Color("#ac6644"))
	if is_rescuer:
		set_outfit(outfit)
	for side in [-1.0, 1.0]:
		var x: float = side * 0.075
		_legs.append(_box(Vector3(x, 0.16, 0.0), Vector3(0.10, 0.25, 0.12), _material(BOOTS)))
		_box(Vector3(x, 0.047, 0.026), Vector3(0.12, 0.09, 0.165), _material(BOOTS.darkened(0.2)))
		var arm := _box(Vector3(side * 0.17, 0.43, 0.0), Vector3(0.087, 0.26, 0.13), _jacket)
		arm.rotation.z = side * 0.14
		_ellipsoid(Vector3(side * 0.184, 0.292, 0.004), Vector3(0.076, 0.083, 0.08), skin)
	_box(Vector3(0.0, 0.445, 0.0), Vector3(0.28, 0.30, 0.18), _jacket)
	_box(Vector3(0.0, 0.41, 0.092), Vector3(0.284, 0.038, 0.014), _material(STRAP))
	_ellipsoid(Vector3(0.0, 0.716, 0.012), Vector3(0.223, 0.239, 0.223), skin)
	if is_mara:
		_ellipsoid(Vector3(0.0, 0.792, -0.018), Vector3(0.233, 0.139, 0.221), hair)
		_ellipsoid(Vector3(-0.079, 0.678, -0.093), Vector3(0.105, 0.217, 0.105), hair)
	elif is_rescuer:
		_ellipsoid(Vector3(0.0, 0.809, 0.0), Vector3(0.24, 0.153, 0.229), _jacket.albedo_color.darkened(0.24))
		_ellipsoid(Vector3(0.0, 0.657, 0.086), Vector3(0.146, 0.091, 0.067), hair)
	else:
		_ellipsoid(Vector3(0.0, 0.811, 0.0), Vector3(0.263, 0.159, 0.239), BOOTS)
		_box(Vector3(0.0, 0.775, 0.067), Vector3(0.25, 0.029, 0.169), _material(BOOTS))
	for side in [-1.0, 1.0]:
		_ellipsoid(Vector3(side * 0.044, 0.727, 0.116), Vector3(0.021, 0.022, 0.019), BOOTS)


func _build_dog() -> void:
	_ellipsoid(Vector3(-0.035, 0.34, 0.0), Vector3(0.39, 0.255, 0.23), SCOUT_FUR)
	_ellipsoid(Vector3(0.15, 0.478, 0.0), Vector3(0.23, 0.23, 0.203), SCOUT_FUR)
	_ellipsoid(Vector3(0.252, 0.426, 0.009), Vector3(0.17, 0.116, 0.151), Color("#e9b87b"))
	_ellipsoid(Vector3(0.324, 0.45, 0.012), Vector3(0.061, 0.061, 0.10), BOOTS)
	_ellipsoid(Vector3(0.179, 0.515, 0.094), Vector3(0.03, 0.028, 0.019), BOOTS)
	var ear := _box(Vector3(0.103, 0.597, 0.068), Vector3(0.078, 0.141, 0.061), _material(SCOUT_DARK))
	ear.rotation.z = 0.26
	var far_ear := _box(Vector3(0.18, 0.6, -0.055), Vector3(0.071, 0.122, 0.057), _material(SCOUT_DARK))
	far_ear.rotation.z = -0.16
	_box(Vector3(0.102, 0.378, 0.0), Vector3(0.056, 0.17, 0.202), _material(Color("#2f90a7")))
	var tail := _box(Vector3(-0.258, 0.413, 0.0), Vector3(0.172, 0.055, 0.065), _material(SCOUT_DARK))
	tail.rotation.z = -0.47
	for depth in [-0.073, 0.073]:
		for x in [-0.16, 0.082]:
			_legs.append(_box(Vector3(x, 0.158, depth), Vector3(0.077, 0.26, 0.079), _material(SCOUT_DARK)))


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	return material


func _box(center: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = center
	add_child(instance)
	return instance


func _ellipsoid(center: Vector3, size: Vector3, color: Color) -> void:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 12
	mesh.rings = 6
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = _material(color)
	instance.position = center
	instance.scale = size
	add_child(instance)
