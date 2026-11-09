class_name TerrainMesh
extends Node3D

const HALF_DEPTH := 0.5
const FACE_COLOR := Color(0.26, 0.48, 0.48)
const EDGE_COLOR := Color(0.48, 0.72, 0.61)

var _chunks: Dictionary[Vector2i, MeshInstance3D] = {}
var _material := StandardMaterial3D.new()


func _ready() -> void:
	_material.vertex_color_use_as_albedo = true
	_material.roughness = 0.91


func rebuild_all(terrain: TerrainGrid) -> void:
	var counts := Vector2i(ceil(Vector2(TerrainGrid.SIZE) / float(TerrainGrid.CHUNK_SIZE)))
	for y in range(counts.y):
		for x in range(counts.x):
			rebuild_chunk(terrain, Vector2i(x, y))


func rebuild_chunk(terrain: TerrainGrid, key: Vector2i) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var has_solid := false
	var rect := Rect2i(key * TerrainGrid.CHUNK_SIZE, Vector2i.ONE * TerrainGrid.CHUNK_SIZE)
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var cell := Vector2i(x, y)
			if terrain.is_solid(cell):
				has_solid = true
				_add_cell(surface, terrain, cell)
	if not _chunks.has(key):
		var instance := MeshInstance3D.new()
		instance.name = "Chunk_%d_%d" % [key.x, key.y]
		instance.material_override = _material
		add_child(instance)
		_chunks[key] = instance
	_chunks[key].mesh = surface.commit() if has_solid else null


func _add_cell(surface: SurfaceTool, terrain: TerrainGrid, cell: Vector2i) -> void:
	var lower := Vector2(cell) * TerrainGrid.CELL_SIZE
	var upper := lower + Vector2.ONE * TerrainGrid.CELL_SIZE
	var front_bl := Vector3(lower.x, lower.y, HALF_DEPTH)
	var front_br := Vector3(upper.x, lower.y, HALF_DEPTH)
	var front_tl := Vector3(lower.x, upper.y, HALF_DEPTH)
	var front_tr := Vector3(upper.x, upper.y, HALF_DEPTH)
	var depth := Vector3(0.0, 0.0, HALF_DEPTH * 2.0)
	var back_bl := front_bl - depth
	var back_br := front_br - depth
	var back_tl := front_tl - depth
	var back_tr := front_tr - depth

	_quad(surface, front_bl, front_tl, front_tr, front_br, Vector3.BACK, FACE_COLOR)
	_quad(surface, back_br, back_tr, back_tl, back_bl, Vector3.FORWARD, FACE_COLOR)
	if not terrain.is_solid(cell + Vector2i.LEFT):
		_quad(surface, back_bl, back_tl, front_tl, front_bl, Vector3.LEFT, EDGE_COLOR)
	if not terrain.is_solid(cell + Vector2i.RIGHT):
		_quad(surface, front_br, front_tr, back_tr, back_br, Vector3.RIGHT, EDGE_COLOR)
	if not terrain.is_solid(cell + Vector2i.DOWN):
		_quad(surface, front_tl, back_tl, back_tr, front_tr, Vector3.UP, EDGE_COLOR)
	if not terrain.is_solid(cell + Vector2i.UP):
		_quad(surface, back_bl, front_bl, front_br, back_br, Vector3.DOWN, EDGE_COLOR)


func _quad(
	surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
	normal: Vector3, color: Color
) -> void:
	surface.set_normal(normal)
	surface.set_color(color)
	for vertex in [a, b, c, a, c, d]:
		surface.add_vertex(vertex)
