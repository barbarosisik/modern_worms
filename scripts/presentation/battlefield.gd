class_name Battlefield
extends Node3D

const NATURE := "res://assets/kenney/nature/"
var _rounded_meshes: Dictionary[Mesh, ArrayMesh] = {}
var _dressing := Node3D.new()
var _anchors: Array[Dictionary] = []


func _ready() -> void:
	add_child(_dressing)
	var rng := RandomNumberGenerator.new()
	rng.seed = 417
	for layer in range(2):
		for i in range(ceili((TerrainGrid.WORLD_SIZE.x + 50.0) / 5.0)):
			var tree := add_asset("tree_oak",
				Vector3(-20.0 + i * 5.0, 0.0, -30.0 + layer * 9.0), Vector3.ONE * rng.randf_range(3.4, 5.2))
			_tint(tree, Color("#82b9aa") if layer == 0 else Color("#50a37a"))
	var water := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(TerrainGrid.WORLD_SIZE.x + 85.0, 200.0)
	water.mesh = plane
	water.position = Vector3(TerrainGrid.WORLD_SIZE.x * 0.5, 0.76, -24.0)
	var material := ShaderMaterial.new()
	material.shader = load("res://scripts/presentation/water.gdshader")
	water.material_override = material
	add_child(water)


func dress(terrain: TerrainGrid, mission_index: int, units: Array[MatchUnit]) -> void:
	for child in _dressing.get_children():
		child.free()
	_anchors.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 900 + mission_index
	for column in range(12, TerrainGrid.SIZE.x - 8, 7):
		var top := _surface(terrain, column)
		if top < 0:
			continue
		var x := (column + 0.5) * TerrainGrid.CELL_SIZE
		var y := (top + 1) * TerrainGrid.CELL_SIZE
		var prop_name := "grass_large" if column % 3 else "flower_purpleA"
		var prop := add_asset(prop_name, Vector3(x, y, -0.27), Vector3.ONE * rng.randf_range(0.38, 0.65), _dressing)
		_anchors.append({"node": prop, "cell": Vector2i(column, top)})
		var near_character := false
		for unit in units:
			near_character = near_character or absf(x - unit.feet.x) < 1.8
		if column % 20 == 12 and not near_character:
			var tree := add_asset("tree_oak", Vector3(x, y, -1.8), Vector3.ONE * rng.randf_range(0.8, 1.25), _dressing)
			_anchors.append({"node": tree, "cell": Vector2i(column, top)})
	var landmarks := [
		[["tent_detailedOpen",5.0], ["cliff_block_rock",13.0], ["canoe",43.0], ["rock_largeA",58.0]],
		[["rock_largeB",14.0], ["tent_detailedOpen",23.0], ["cliff_block_rock",30.0], ["rock_largeA",49.0]],
		[["fence_simple",12.0], ["rock_largeB",27.0], ["fence_simple",33.0], ["canoe",46.0]],
		[["tent_detailedOpen",5.0], ["rock_largeA",15.0], ["fence_simple",33.0], ["rock_largeB",54.0]],
		[["canoe",6.0], ["fence_simple",23.0], ["rock_largeA",32.0], ["tent_detailedOpen",57.5]],
	]
	for entry in landmarks[clampi(mission_index,0,4)]:
		var column := floori(float(entry[1]) / TerrainGrid.CELL_SIZE)
		var top := _surface(terrain,column)
		if top < 0: continue
		var prop := add_asset(entry[0], Vector3(entry[1],(top+1)*TerrainGrid.CELL_SIZE,-1.1),Vector3.ONE*0.7,_dressing)
		_anchors.append({"node":prop,"cell":Vector2i(column,top)})


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
	# Smooth the imported canopy normals while retaining the supplied topology.
	for part in model.find_children("*", "MeshInstance3D", true, false):
		if asset != "tree_oak":
			continue
		part.mesh = _round_model(part.mesh)
	model.position = point
	model.scale = dimensions
	return model


func _tint(node: Node3D, color: Color) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color.darkened(0.12)
	material.roughness = 1.0
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		mesh.material_override = material
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


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
					smoothed[i] = points[i].lerp(sum / neighbours[i].size(),0.45)
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
