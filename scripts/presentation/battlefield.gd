class_name Battlefield
extends Node3D

const NATURE := "res://assets/kenney/nature/"
var _dressing := Node3D.new()
var _anchors: Array[Dictionary] = []


func _ready() -> void:
	add_child(_dressing)
	var rng := RandomNumberGenerator.new()
	rng.seed = 417
	for i in range(10):
		var rock := add_asset("rock_largeA", Vector3(-22.0 + i * 9.0, -3.0, -35.0), Vector3(12.0, rng.randf_range(13.0, 23.0), 9.0))
		_tint(rock, Color("#729caa"))
	for layer in range(2):
		for i in range(25):
			var tree := add_asset("tree_pineTallA" if i % 2 == 0 else "tree_pineRoundA",
				Vector3(-14.0 + i * 2.6, -2.0, -17.0 + layer * 7.0), Vector3.ONE * rng.randf_range(2.3, 4.0))
			_tint(tree, Color("#547c78") if layer == 0 else Color("#386d60"))
	var water := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(110.0, 85.0)
	water.mesh = plane
	water.position = Vector3(16.0, 0.76, -24.0)
	var material := ShaderMaterial.new()
	material.shader = load("res://scripts/presentation/water.gdshader")
	water.material_override = material
	add_child(water)


func dress(terrain: TerrainGrid, mission_index: int) -> void:
	for child in _dressing.get_children():
		child.free()
	_anchors.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 900 + mission_index
	for column in range(12, 249, 5):
		var top := _surface(terrain, column)
		if top < 0:
			continue
		var x := (column + 0.5) * TerrainGrid.CELL_SIZE
		var y := (top + 1) * TerrainGrid.CELL_SIZE
		var prop_name := "grass_large" if column % 3 else "flower_purpleA"
		var prop := add_asset(prop_name, Vector3(x, y, -0.27), Vector3.ONE * rng.randf_range(0.38, 0.65), _dressing)
		_anchors.append({"node": prop, "cell": Vector2i(column, top)})
		if column % 20 == 12:
			var tree := add_asset("tree_pineRoundA", Vector3(x, y, -1.8), Vector3.ONE * rng.randf_range(0.8, 1.25), _dressing)
			_anchors.append({"node": tree, "cell": Vector2i(column, top)})
	var camp_column := 48 if mission_index == 0 else 185
	var camp_y := _surface(terrain, camp_column)
	if camp_y >= 0:
		var prop := add_asset("tent_detailedOpen" if mission_index == 0 else "canoe",
			Vector3(camp_column * TerrainGrid.CELL_SIZE, (camp_y + 1) * TerrainGrid.CELL_SIZE, -1.1), Vector3.ONE * 0.7, _dressing)
		_anchors.append({"node": prop, "cell": Vector2i(camp_column, camp_y)})


func update_support(terrain: TerrainGrid) -> void:
	for entry in _anchors:
		var node: Node3D = entry.node
		if is_instance_valid(node) and not terrain.is_solid(entry.cell):
			node.hide()


func _surface(terrain: TerrainGrid, column: int) -> int:
	for row in range(TerrainGrid.SIZE.y - 1, 6, -1):
		if terrain.is_solid(Vector2i(column, row)):
			return row
	return -1


func add_asset(asset: String, point: Vector3, dimensions: Vector3, parent: Node3D = null) -> Node3D:
	var model := (load(NATURE + asset + ".glb") as PackedScene).instantiate() as Node3D
	(self if parent == null else parent).add_child(model)
	model.position = point
	model.scale = dimensions
	return model


func _tint(node: Node3D, color: Color) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		mesh.material_override = material
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
