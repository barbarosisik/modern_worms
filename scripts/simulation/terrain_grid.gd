class_name TerrainGrid
extends RefCounted

class Contact:
	var point: Vector2
	var normal: Vector2

	func _init(hit_point: Vector2, hit_normal: Vector2) -> void:
		point = hit_point
		normal = hit_normal

const SIZE := Vector2i(512, 192)
const CELL_SIZE := 0.125
const CHUNK_SIZE := 32
const WORLD_SIZE := Vector2(SIZE) * CELL_SIZE
const CHUNK_COUNT := SIZE / CHUNK_SIZE

var _cells := PackedByteArray()


func _init() -> void:
	_cells.resize(SIZE.x * SIZE.y)


func snapshot() -> TerrainGrid:
	var copy := TerrainGrid.new()
	copy._cells = _cells.duplicate()
	return copy


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
	var contact := sweep(start, end)
	return contact.point if contact != null else Vector2.INF


func sweep(start: Vector2, end: Vector2) -> Contact:
	var cell := _world_cell(start)
	var delta := end - start
	if is_solid(cell):
		return Contact.new(start, -delta.normalized())
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
		var normal: Vector2
		if is_equal_approx(next_x, next_y):
			# Check both side cells at a corner so a fast shot cannot slip between them.
			if is_solid(cell + Vector2i(step_x, 0)):
				return Contact.new(start + delta * time, Vector2(-step_x, 0))
			if is_solid(cell + Vector2i(0, step_y)):
				return Contact.new(start + delta * time, Vector2(0, -step_y))
			cell += Vector2i(step_x, step_y)
			next_x += stride_x
			next_y += stride_y
			normal = Vector2(-step_x, -step_y).normalized()
		elif next_x < next_y:
			cell.x += step_x
			next_x += stride_x
			normal = Vector2(-step_x, 0)
		else:
			cell.y += step_y
			next_y += stride_y
			normal = Vector2(0, -step_y)
		if is_solid(cell):
			return Contact.new(start + delta * time, normal)
	return null


func _world_cell(position: Vector2) -> Vector2i:
	return Vector2i((position / CELL_SIZE).floor())


func _contains(cell: Vector2i) -> bool:
	return Rect2i(Vector2i.ZERO, SIZE).has_point(cell)


func _mark_chunk(changed: Dictionary[Vector2i, bool], cell: Vector2i) -> void:
	if _contains(cell):
		changed[Vector2i(floori(float(cell.x) / CHUNK_SIZE), floori(float(cell.y) / CHUNK_SIZE))] = true


func fill_rounded_rect(rect: Rect2i, radius: int = 7) -> void:
	var r := mini(radius, mini(rect.size.x,rect.size.y) / 2)
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var centre := Vector2(clampf(x + 0.5, rect.position.x + r, rect.end.x - r), clampf(y + 0.5, rect.position.y + r, rect.end.y - r))
			if Vector2(x + 0.5,y + 0.5).distance_to(centre) <= r:
				fill_rect(Rect2i(x,y,1,1))


# Map construction uses smooth authored silhouettes; runtime destruction stays cell based.
func fill_landmass(profile: PackedVector2Array, phase: float = 0.0) -> void:
	var segment := 0
	for column in range(maxi(0, floori(profile[0].x / CELL_SIZE)), mini(SIZE.x, ceili(profile[-1].x / CELL_SIZE))):
		var x := (column + 0.5) * CELL_SIZE
		while segment < profile.size() - 2 and x > profile[segment + 1].x:
			segment += 1
		var a := profile[segment]
		var b := profile[segment + 1]
		var t := clampf(inverse_lerp(a.x, b.x, x), 0, 1)
		var top := lerpf(a.y, b.y, smoothstep(0, 1, t)) + sin(x * 1.4 + phase) * 0.06
		var bottom := 1.2 + 0.25 * sin(x * 0.55 + phase) + 0.16 * sin(x * 1.1)
		fill_rect(Rect2i(column, floori(bottom / CELL_SIZE), 1, maxi(0, roundi(top / CELL_SIZE) - floori(bottom / CELL_SIZE))))


func carve_ellipse(center: Vector2, radii: Vector2) -> void:
	var start := _world_cell(center - radii).max(Vector2i.ZERO)
	var end := _world_cell(center + radii).min(SIZE - Vector2i.ONE)
	for y in range(start.y, end.y + 1):
		for x in range(start.x, end.x + 1):
			var scaled := (((Vector2(x,y) + Vector2.ONE * 0.5) * CELL_SIZE) - center) / radii
			if scaled.length_squared() <= 1.0:
				_cells[y * SIZE.x + x] = 0
