class_name Battlefield
extends Node3D

const NATURE := "res://assets/kenney/nature/"
# Model, world X, scale, footprint radius in X, and yaw in degrees.
# None of these props create walkable ground or block projectiles.
const LANDMARKS := [
	[["tent_detailedOpen", 10.4, 2.6, 0.84, 17.0], ["canoe", 16.5, 2.3, 1.08, 77.0],
		["fence_simple", 21.1, 1.7, 0.66, -9.0], ["canoe", 43.1, 2.1, 0.92, 83.0],
		["tent_detailedOpen", 56.1, 2.3, 0.75, -20.0]],
	[["rock_largeB", 12.0, 2.6, 0.71, 12.0], ["rock_largeA", 15.1, 2.2, 0.66, 33.0],
		["rock_largeB", 28.7, 3.0, 0.82, -24.0], ["tree_oak", 36.1, 2.2, 0.36, 16.0],
		["rock_largeB", 49.5, 2.4, 0.71, 16.0]],
	[["fence_simple", 13.4, 1.9, 0.72, -13.0], ["fence_simple", 29.8, 2.0, 0.79, -5.0],
		["fence_simple", 34.5, 2.4, 0.85, 9.0], ["rock_largeA", 37.2, 2.5, 0.75, 24.0],
		["canoe", 50.1, 2.2, 0.85, 74.0]],
	[["tent_detailedOpen", 10.0, 2.6, 0.86, 16.0], ["rock_largeA", 17.2, 1.6, 0.5, 13.0],
		["fence_simple", 22.5, 1.8, 0.65, 2.0], ["rock_largeB", 32.7, 2.1, 0.60, -18.0],
		["tree_oak", 51.3, 2.5, 0.38, 22.0]],
	[["canoe", 5.7, 2.9, 1.28, 81.0], ["canoe", 14.5, 2.4, 0.98, 67.0],
		["fence_simple", 17.2, 2.1, 0.89, -9.0], ["canoe", 38.4, 2.7, 1.14, 75.0],
		["fence_simple", 57.3, 2.2, 0.86, -10.0]],
]
const BEACONS := [
	[12.2, 41.1, 57.8],
	[14.4, 32.6],
	[16.1, 34.2, 45.4],
	[15.2, 21.6],
	[10.0, 24.0, 47.6],
]
const PENNANTS := [Color("#f2ad53"), Color("#bdcb8a"), Color("#ef996d"), Color("#f0c982"), Color("#ffd381")]

var _rounded_meshes: Dictionary[Mesh, ArrayMesh] = {}
var _dressing := Node3D.new()
var _anchors: Array[Dictionary] = []


func _ready() -> void:
	add_child(_dressing)
	_add_ridge(-72.0, Color("#769d9b"), 5.0, 0.3)
	_add_ridge(-49.0, Color("#628d8c"), 4.1, 1.7)

	# Open gaps between groves let the hills and river show through.
	var rng := RandomNumberGenerator.new()
	rng.seed = 417
	for layer in range(2):
		var tree_depth := -34.0 + layer * 10.0
		var bank_phase := 0.5 + layer * 1.8
		var bank_colors := [Color("#658f84"), Color("#547f72")]
		var colors := [Color("#557e79"), Color("#476f63")]
		_add_ridge(tree_depth - 1.0, bank_colors[layer], 0.45, bank_phase, 1.62)
		for grove in range(7):
			var center := -13.0 + grove * 15.0 + rng.randf_range(-2.0, 2.0)
			for i in range(3 if layer == 0 else 2):
				var x := center + i * 2.0 - layer * 4.0
				var shore := _ridge_height(x, 0.45, bank_phase, 1.62)
				var tree := add_asset("tree_oak",
					Vector3(x, shore - 0.13, tree_depth),
					Vector3(rng.randf_range(3.3, 5.7), rng.randf_range(3.8, 7.0), 4.0))
				_tint(tree, colors[layer].lightened(rng.randf_range(0.0, 0.05)))

	var water := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(TerrainGrid.WORLD_SIZE.x + 85.0, 200.0)
	water.mesh = plane
	water.position = Vector3(TerrainGrid.WORLD_SIZE.x * 0.5, MatchSimulation.WATER_LEVEL - 0.04, -24.0)
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := ShaderMaterial.new()
	material.shader = preload("res://scripts/presentation/water.gdshader")
	water.material_override = material
	add_child(water)


func _add_ridge(depth: float, color: Color, amplitude: float, offset: float, height: float = 4.8) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	surface.set_material(material)
	for x in range(-86, 152, 2):
		var next := x + 2.0
		var a := Vector3(x, _ridge_height(x, amplitude, offset, height), depth)
		var b := Vector3(next, _ridge_height(next, amplitude, offset, height), depth)
		var floor_a := Vector3(x, -6.0, depth)
		var floor_b := Vector3(next, -6.0, depth)
		for point in [a, b, floor_a, floor_a, b, floor_b]:
			surface.add_vertex(point)
	var ridge := MeshInstance3D.new()
	ridge.mesh = surface.commit()
	ridge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ridge)


func _ridge_height(x: float, amplitude: float, offset: float, height: float) -> float:
	return height + amplitude * (sin(x * 0.095 + offset) * 0.58 + sin(x * 0.041 + offset) * 0.45)


func dress(terrain: TerrainGrid, layout: int, units: Array[MatchUnit]) -> void:
	for child in _dressing.get_children():
		child.free()
	_anchors.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 900 + layout
	for column in range(19, TerrainGrid.SIZE.x - 14, 9):
		var varied := column + rng.randi_range(-2, 2)
		var x := (varied + 0.5) * TerrainGrid.CELL_SIZE
		var grass := "grass_large" if column % 4 else "flower_purpleA"
		_place_asset(terrain, grass, x, -0.94, rng.randf_range(0.60, 1.05), 0.0, rng.randf_range(-45.0, 45.0))
		if column % 45 == 19 and not units.any(func(unit: MatchUnit) -> bool: return absf(x - unit.feet.x) < 2.0):
			_place_asset(terrain, "tree_oak", x, -4.25, rng.randf_range(1.48, 2.20), 0.31, 0.0)

	var profile := clampi(layout, 0, LANDMARKS.size() - 1)
	for entry in LANDMARKS[profile]:
		_place_asset(terrain, entry[0], entry[1], -3.1, entry[2], entry[3], entry[4])
	var banner_material := StandardMaterial3D.new()
	banner_material.albedo_color = PENNANTS[profile]
	banner_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	banner_material.roughness = 1.0
	for x in BEACONS[profile]:
		var cells := _footprint(terrain, x, 0.0)
		if not cells.is_empty():
			_add_beacon(cells, x, banner_material)


func _place_asset(terrain: TerrainGrid, asset: String, x: float, z: float, size: float, radius: float, yaw: float) -> Node3D:
	var cells := _footprint(terrain, x, radius)
	if cells.is_empty():
		return null
	var y := (cells[0].y + 1) * TerrainGrid.CELL_SIZE
	# Seat wide props on the lowest of their feet on a shallow slope.
	for cell in cells:
		y = minf(y, (cell.y + 1) * TerrainGrid.CELL_SIZE)
	var prop := add_asset(asset, Vector3(x, y, z), Vector3.ONE * size, _dressing)
	prop.rotation_degrees.y = yaw
	if asset == "tree_oak":
		_tint(prop, Color("#507c62"))
	_anchors.append({"node": prop, "cells": cells})
	return prop


func _footprint(terrain: TerrainGrid, x: float, radius: float) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var low := TerrainGrid.SIZE.y
	var high := -1
	for offset in ([0.0] if radius == 0.0 else [-radius, 0.0, radius]):
		var column := floori((x + offset) / TerrainGrid.CELL_SIZE)
		var top := _surface(terrain, column)
		if top < 0:
			return []
		low = mini(low, top)
		high = maxi(high, top)
		cells.append(Vector2i(column, top))
	if high - low > 6:
		cells.clear()
	return cells


func _add_beacon(cells: Array[Vector2i], x: float, flag_material: StandardMaterial3D) -> void:
	var beacon := Node3D.new()
	beacon.name = "ShorePennant"
	_dressing.add_child(beacon, true)
	beacon.position = Vector3(x, (cells[0].y + 1) * TerrainGrid.CELL_SIZE, -2.85)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color("#855e42")
	wood.roughness = 1.0
	var pole := CylinderMesh.new()
	pole.top_radius = 0.036
	pole.bottom_radius = 0.072
	pole.height = 2.60
	pole.radial_segments = 6
	pole.material = wood
	var support := MeshInstance3D.new()
	support.mesh = pole
	support.position.y = 1.27
	support.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beacon.add_child(support)
	var flag := SurfaceTool.new()
	flag.begin(Mesh.PRIMITIVE_TRIANGLES)
	flag.set_material(flag_material)
	flag.set_normal(Vector3.BACK)
	for point in [Vector3(0.025, 2.48, 0.05), Vector3(0.99, 2.17, 0.10), Vector3(0.025, 1.87, 0.05)]:
		flag.add_vertex(point)
	var cloth := MeshInstance3D.new()
	cloth.mesh = flag.commit()
	cloth.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beacon.add_child(cloth)
	_anchors.append({"node": beacon, "cells": cells})


func update_support(terrain: TerrainGrid) -> void:
	for entry in _anchors:
		var node: Node3D = entry.node
		if not is_instance_valid(node) or not node.visible:
			continue
		for cell in entry.cells:
			if not terrain.is_solid(cell):
				node.hide()
				break


func _surface(terrain: TerrainGrid, column: int) -> int:
	for row in range(TerrainGrid.SIZE.y - 1, 6, -1):
		if terrain.is_solid(Vector2i(column, row)):
			return row
	return -1


func add_asset(asset: String, point: Vector3, dimensions: Vector3, parent: Node3D = null) -> Node3D:
	var model := (load(NATURE + asset + ".glb") as PackedScene).instantiate() as Node3D
	(self if parent == null else parent).add_child(model)
	for part in model.find_children("*", "MeshInstance3D", true, false):
		if asset == "tree_oak":
			part.mesh = _round_model(part.mesh)
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	model.position = point
	model.scale = dimensions
	return model


func _tint(node: Node3D, color: Color) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		mesh.material_override = material


# Derive a softer silhouette from the licensed source mesh, not just smooth lighting.
func _round_model(source: Mesh) -> ArrayMesh:
	if _rounded_meshes.has(source):
		return _rounded_meshes[source]
	var output := ArrayMesh.new()
	for surface in range(source.get_surface_count()):
		var arrays := source.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var points: Array[Vector3] = []
		var ids: Dictionary[Vector3, int] = {}
		var faces: Array[Vector3i] = []
		for i in range(0,indices.size(),3):
			var face := Vector3i()
			for j in range(3):
				var vertex := vertices[indices[i+j]].snapped(Vector3.ONE * 0.0001)
				if not ids.has(vertex):
					ids[vertex] = points.size()
					points.append(vertex)
				face[j] = ids[vertex]
			faces.append(face)
		for iteration in range(2):
			var edges: Dictionary[Vector2i, int] = {}
			var divided: Array[Vector3i] = []
			for face in faces:
				var mids := Vector3i()
				for j in range(3):
					var a := face[j]
					var b := face[(j+1)%3]
					var key := Vector2i(mini(a,b),maxi(a,b))
					if not edges.has(key):
						edges[key] = points.size()
						points.append((points[a]+points[b])*0.5)
					mids[j] = edges[key]
				divided.append_array([Vector3i(face.x,mids.x,mids.z),Vector3i(mids.x,face.y,mids.y),Vector3i(mids.z,mids.y,face.z),Vector3i(mids.x,mids.y,mids.z)])
			var neighbours: Array[Dictionary] = []
			for point in points: neighbours.append({})
			for face in divided:
				for j in range(3):
					neighbours[face[j]][face[(j+1)%3]] = true
					neighbours[face[j]][face[(j+2)%3]] = true
			var smoothed := points.duplicate()
			for i in range(points.size()):
				var sum := Vector3.ZERO
				for index in neighbours[i]: sum += points[index]
				if not neighbours[i].is_empty():
					# Retain the base and branch joints while softening the canopy.
					var softness := lerpf(0.13, 0.45, smoothstep(0.51, 0.93, points[i].y))
					smoothed[i] = points[i].lerp(sum / neighbours[i].size(), softness)
			points = smoothed
			faces = divided
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		tool.set_material(source.surface_get_material(surface))
		for face in faces:
			for i in range(3): tool.add_vertex(points[face[i]])
		tool.generate_normals()
		tool.commit(output)
	_rounded_meshes[source] = output
	return output
