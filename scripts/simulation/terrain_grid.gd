class_name TerrainGrid
extends RefCounted

const SIZE := Vector2i(256, 128)
const CELL_SIZE := 0.125
const CHUNK_SIZE := 32
const WORLD_SIZE := Vector2(SIZE) * CELL_SIZE

var _cells := PackedByteArray()


func _init() -> void:
	_cells.resize(SIZE.x * SIZE.y)


func is_solid(cell: Vector2i) -> bool:
	return _contains(cell) and _cells[cell.y * SIZE.x + cell.x] != 0


func fill_rect(rect: Rect2i) -> void:
	var clipped := rect.intersection(Rect2i(Vector2i.ZERO, SIZE))
	for y in range(clipped.position.y, clipped.end.y):
		for x in range(clipped.position.x, clipped.end.x):
			_cells[y * SIZE.x + x] = 1


func cut_disc(center: Vector2, radius: float) -> Array[Vector2i]:
	var extent := Vector2.ONE * radius
	var min_cell := _world_cell(center - extent).max(Vector2i.ZERO)
	var max_cell := _world_cell(center + extent).min(SIZE - Vector2i.ONE)
	var changed: Dictionary[Vector2i, bool] = {}
	for y in range(min_cell.y, max_cell.y + 1):
		for x in range(min_cell.x, max_cell.x + 1):
			var cell := Vector2i(x, y)
			var midpoint := (Vector2(cell) + Vector2(0.5, 0.5)) * CELL_SIZE
			if is_solid(cell) and midpoint.distance_squared_to(center) <= radius * radius:
				_cells[y * SIZE.x + x] = 0
				_mark_chunk(changed, cell)
				if x % CHUNK_SIZE == 0:
					_mark_chunk(changed, cell + Vector2i.LEFT)
				if x % CHUNK_SIZE == CHUNK_SIZE - 1:
					_mark_chunk(changed, cell + Vector2i.RIGHT)
				if y % CHUNK_SIZE == 0:
					_mark_chunk(changed, cell + Vector2i.UP)
				if y % CHUNK_SIZE == CHUNK_SIZE - 1:
					_mark_chunk(changed, cell + Vector2i.DOWN)
	return changed.keys()


func first_contact(start: Vector2, end: Vector2) -> Vector2:
	var cell := _world_cell(start)
	if is_solid(cell):
		return start
	var delta := end - start
	var step_x := int(signf(delta.x))
	var step_y := int(signf(delta.y))
	var stride_x := INF
	var stride_y := INF
	var next_x := INF
	var next_y := INF
	if step_x != 0:
		stride_x = CELL_SIZE / absf(delta.x)
		next_x = (float(cell.x + int(step_x > 0)) * CELL_SIZE - start.x) / delta.x
	if step_y != 0:
		stride_y = CELL_SIZE / absf(delta.y)
		next_y = (float(cell.y + int(step_y > 0)) * CELL_SIZE - start.y) / delta.y

	while minf(next_x, next_y) <= 1.0:
		var time := minf(next_x, next_y)
		if is_equal_approx(next_x, next_y):
			# Check both side cells at a corner so a fast shot cannot slip between them.
			if is_solid(cell + Vector2i(step_x, 0)) or is_solid(cell + Vector2i(0, step_y)):
				return start + delta * time
			cell += Vector2i(step_x, step_y)
			next_x += stride_x
			next_y += stride_y
		elif next_x < next_y:
			cell.x += step_x
			next_x += stride_x
		else:
			cell.y += step_y
			next_y += stride_y
		if is_solid(cell):
			return start + delta * time
	return Vector2.INF


func _world_cell(position: Vector2) -> Vector2i:
	return Vector2i((position / CELL_SIZE).floor())


func _contains(cell: Vector2i) -> bool:
	return Rect2i(Vector2i.ZERO, SIZE).has_point(cell)


func _mark_chunk(changed: Dictionary[Vector2i, bool], cell: Vector2i) -> void:
	if _contains(cell):
		changed[Vector2i(floori(float(cell.x) / CHUNK_SIZE), floori(float(cell.y) / CHUNK_SIZE))] = true
