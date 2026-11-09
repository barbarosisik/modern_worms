class_name TrajectoryGuide
extends Node3D

const DOT_COUNTS := [6, 9, 12, 15, 18]
const MAX_DOTS := 18
const FIRST_DOT := 0.86
const DOT_SPACING := 0.42

var _dots: Array[MeshInstance3D] = []
var _shown_tier := -1


func _ready() -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.072
	mesh.height = mesh.radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 5
	for i in range(MAX_DOTS):
		var dot := MeshInstance3D.new()
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		dot.material_override = material
		dot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		dot.mesh = mesh
		dot.hide()
		add_child(dot)
		_dots.append(dot)


func preview(shot: ArtilleryShot, terrain: TerrainGrid, targets: PackedVector2Array, tier: int) -> void:
	tier = clampi(tier, 0, DOT_COUNTS.size() - 1)
	var limit: int = DOT_COUNTS[tier]
	var points := sample(shot, terrain, targets, limit)
	for i in range(_dots.size()):
		var dot := _dots[i]
		if _shown_tier != tier and i < limit:
			var fraction := float(i) / (limit - 1)
			var material := dot.material_override as StandardMaterial3D
			material.albedo_color = Color(0.62, 0.93, 1.0, lerpf(0.98, 0.16, fraction))
		dot.visible = i < points.size()
		if dot.visible:
			dot.position = Vector3(points[i].x, points[i].y, 0.04)
	_shown_tier = tier
	show()


static func sample(
	shot: ArtilleryShot, terrain: TerrainGrid, targets: PackedVector2Array, limit: int
) -> PackedVector2Array:
	var points := PackedVector2Array()
	var until_dot := FIRST_DOT
	var delta := 1.0 / Engine.physics_ticks_per_second
	while points.size() < limit:
		var start := shot.position
		var result := shot.step(delta, terrain, targets)
		var length := start.distance_to(shot.position)
		while until_dot < length and points.size() < limit:
			points.append(start.lerp(shot.position, until_dot / length))
			until_dot += DOT_SPACING
		until_dot -= length
		if result != ArtilleryShot.Result.FLYING:
			break
	return points
