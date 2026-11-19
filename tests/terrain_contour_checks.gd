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
	_check_landmark_support()
	print("PASS: rounded silhouettes, open craters, seam-safe rebuilds and landmark support")
	quit()


func _check_landmark_support() -> void:
	var game := MatchSimulation.new()
	var scenery := Battlefield.new()
	root.add_child(scenery)
	scenery.dress(game.terrain, BattleMaps.Layout.RIVER_OUTPOSTS, game.units)
	var camp: Dictionary = {}
	for landmark in scenery._anchors:
		var model: Node3D = landmark.node
		if is_equal_approx(model.position.x, 10.4):
			camp = landmark
			break
	assert(not camp.is_empty(), "River Outposts has a visible camp on its opening bank")
	var supports: Array[Vector2i] = camp.cells
	var tent: Node3D = camp.node
	var blast := (Vector2(supports[0]) + Vector2.ONE * 0.5) * TerrainGrid.CELL_SIZE
	game.terrain.cut_disc(blast, 0.18)
	assert(game.terrain.is_solid(supports[1]), "The blast takes out only the outside support")
	scenery.update_support(game.terrain)
	assert(not tent.visible, "A wide prop cannot overhang a missing outside support")
	scenery.free()
