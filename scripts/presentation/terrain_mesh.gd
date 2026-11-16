class_name TerrainMesh
extends Node3D

const HALF_DEPTH := 0.6
# Marching squares samples cell centres. Ambiguous diagonals stay disconnected.
const POLYGONS := [[], [[0,4,7]], [[1,5,4]], [[0,1,5,7]], [[2,6,5]], [[0,4,7],[2,6,5]], [[1,2,6,4]], [[0,1,2,6,7]], [[3,7,6]], [[0,4,6,3]], [[1,5,4],[3,7,6]], [[0,1,5,6,3]], [[3,7,5,2]], [[0,4,5,2,3]], [[4,1,2,3,7]], [[0,1,2,3]]]
var _chunks: Dictionary[Vector2i, MeshInstance3D] = {}
var _material := ShaderMaterial.new()

func _ready() -> void:
	_material.shader = preload("res://scripts/presentation/earth.gdshader")

func rebuild_all(terrain: TerrainGrid) -> void:
	for y in range(4):
		for x in range(8):
			rebuild_chunk(terrain, Vector2i(x,y))

func rebuild_chunk(terrain: TerrainGrid, key: Vector2i) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var populated := false
	var start := key * TerrainGrid.CHUNK_SIZE
	for y in range(start.y - 1, start.y + TerrainGrid.CHUNK_SIZE - 1):
		for x in range(start.x - 1, start.x + TerrainGrid.CHUNK_SIZE - 1):
			var cell := Vector2i(x,y)
			var mask := 0
			for i in range(4):
				if terrain.is_solid(cell + [Vector2i.ZERO, Vector2i.RIGHT, Vector2i(1,1), Vector2i(0,1)][i]):
					mask |= 1 << i
			if mask == 0:
				continue
			populated = true
			var origin := (Vector2(cell) + Vector2.ONE * 0.5) * TerrainGrid.CELL_SIZE
			var offsets := [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1),Vector2(0.5,0),Vector2(1,0.5),Vector2(0.5,1),Vector2(0,0.5)]
			var grass := 1.0 if not terrain.is_solid(cell + Vector2i(0,3)) else 0.0
			for polygon in POLYGONS[mask]:
				var points: Array[Vector2] = []
				for index in polygon:
					points.append(origin + offsets[index] * TerrainGrid.CELL_SIZE)
				for i in range(1, points.size()-1):
					_triangle(surface, points[0], points[i+1], points[i], HALF_DEPTH, Vector3.BACK, grass)
					_triangle(surface, points[0], points[i], points[i+1], -HALF_DEPTH, Vector3.FORWARD, 0.0)
				for i in range(points.size()):
					var j := (i+1) % points.size()
					if polygon[i] < 4 or polygon[j] < 4:
						continue
					var a := points[i]
					var b := points[j]
					var outward := Vector3(b.y-a.y, a.x-b.x, 0).normalized()
					surface.set_normal(outward)
					surface.set_color(Color(0, 1 if outward.y > 0.4 else 0, 0))
					for vertex in [Vector3(a.x,a.y,HALF_DEPTH),Vector3(b.x,b.y,HALF_DEPTH),Vector3(b.x,b.y,-HALF_DEPTH),Vector3(a.x,a.y,HALF_DEPTH),Vector3(b.x,b.y,-HALF_DEPTH),Vector3(a.x,a.y,-HALF_DEPTH)]:
						surface.add_vertex(vertex)
	if not _chunks.has(key):
		var instance := MeshInstance3D.new()
		instance.name = "Chunk_%d_%d" % [key.x,key.y]
		instance.material_override = _material
		add_child(instance)
		_chunks[key] = instance
	_chunks[key].mesh = surface.commit() if populated else null

func _triangle(surface: SurfaceTool, a: Vector2, b: Vector2, c: Vector2, z: float, normal: Vector3, grass: float) -> void:
	surface.set_normal(normal)
	surface.set_color(Color(0,grass,0))
	for point in [a,b,c]:
		surface.add_vertex(Vector3(point.x,point.y,z))


func rebuild_dirty(terrain: TerrainGrid, dirty: Array[Vector2i]) -> void:
	var affected: Dictionary[Vector2i, bool] = {}
	for key in dirty:
		for dy in range(-1,2):
			for dx in range(-1,2):
				var neighbour := key + Vector2i(dx,dy)
				if neighbour.x >= 0 and neighbour.y >= 0 and neighbour.x < 8 and neighbour.y < 4:
					affected[neighbour] = true
	for key in affected:
		rebuild_chunk(terrain,key)
