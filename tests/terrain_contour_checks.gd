extends SceneTree
func _initialize() -> void:
	check.call_deferred()
func check() -> void:
	var grid := TerrainGrid.new()
	grid.fill_rounded_rect(Rect2i(8,8,90,60))
	grid.fill_rounded_rect(Rect2i(430,8,72,60))
	assert(not grid.is_solid(Vector2i(8,8)) and grid.is_solid(Vector2i(20,20)))
	var view := TerrainMesh.new()
	root.add_child(view)
	view.rebuild_all(grid)
	var dirty := grid.cut_disc(Vector2(4.0,4.0),1.15)
	dirty.append_array(grid.cut_disc(Vector2(58,4),1.15))
	assert(dirty.any(func(key: Vector2i) -> bool: return key.x > 8), "Destruction reaches chunks beyond the old map width")
	view.rebuild_dirty(grid,dirty)
	var rebuilt := TerrainMesh.new()
	root.add_child(rebuilt)
	rebuilt.rebuild_all(grid)
	for key in view._chunks:
		var first: Mesh = view._chunks[key].mesh
		var second: Mesh = rebuilt._chunks[key].mesh
		assert((first == null) == (second == null))
		if first == null: continue
		assert(first.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] == second.surface_get_arrays(0)[Mesh.ARRAY_VERTEX], "Chunk refresh must match a full contour rebuild")
		var vertices: PackedVector3Array = first.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for i in range(0,vertices.size(),3):
			if not is_equal_approx(vertices[i].z,TerrainMesh.HALF_DEPTH): continue
			if not is_equal_approx(vertices[i+1].z,TerrainMesh.HALF_DEPTH): continue
			if not is_equal_approx(vertices[i+2].z,TerrainMesh.HALF_DEPTH): continue
			var triangle := PackedVector2Array([Vector2(vertices[i].x,vertices[i].y),Vector2(vertices[i+1].x,vertices[i+1].y),Vector2(vertices[i+2].x,vertices[i+2].y)])
			assert(not Geometry2D.is_point_in_polygon(Vector2(4,4),triangle), "Crater holes must remain open")
	view.free()
	rebuilt.free()
	print("PASS: rounded silhouettes, open crater holes and seam-safe dirty contour rebuilds")
	quit()
