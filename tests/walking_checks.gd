extends SceneTree

const STEP := 1.0 / 60.0

func _initialize() -> void:
	var stairs := TerrainGrid.new()
	stairs.fill_rect(Rect2i(0,0,140,32))
	for i in range(8):
		stairs.fill_rect(Rect2i(40 + i*6,32,100-i*6,(i+1)*2))
	var walker := MatchUnit.new(0,1,Vector2(4,4))
	for tick in range(150):
		walker.step(stairs,STEP,1,false,true)
		assert(walker.grounded, "Two-cell stairs stay grounded without jumping")
	assert(walker.feet.x > 11.5 and walker.feet.y == 6, "Walk smoothly up a whole staircase")
	for tick in range(150):
		walker.step(stairs,STEP,-1,false,true)
		assert(walker.grounded, "Small descending steps stay grounded")
	assert(walker.feet.x < 4.5 and walker.feet.y == 4, "Walk down in the opposite direction")
	# Reverse the ascent too, to catch direction-dependent wall probing.
	walker.feet = Vector2(12,6)
	var mirrored := TerrainGrid.new()
	for y in range(64):
		for x in range(140):
			if stairs.is_solid(Vector2i(x,y)):
				mirrored.fill_rect(Rect2i(140-x,y,1,1))
	walker.feet = Vector2(13.5,4)
	for tick in range(150): walker.step(mirrored,STEP,-1,false,true)
	assert(walker.feet.x < 6 and walker.feet.y > 5.5, "Automatic ascent works to the left")
	var wall := TerrainGrid.new()
	wall.fill_rect(Rect2i(0,0,120,32))
	wall.fill_rect(Rect2i(40,32,50,3))
	walker = MatchUnit.new(0,1,Vector2(4,4))
	for tick in range(70): walker.step(wall,STEP,1,false,true)
	assert(walker.feet.x < 4.75 and walker.feet.y == 4, "Larger obstacles still require jumping")
	wall = TerrainGrid.new()
	wall.fill_rect(Rect2i(0,0,120,32))
	wall.fill_rect(Rect2i(40,32,50,2))
	wall.fill_rect(Rect2i(32,40,35,1))
	walker = MatchUnit.new(0,1,Vector2(4,4))
	for tick in range(70): walker.step(wall,STEP,1,false,true)
	assert(walker.feet.x < 4.75 and walker.feet.y == 4, "Low ceilings prevent stepping through the roof")
	wall = TerrainGrid.new()
	wall.fill_rect(Rect2i(0,0,120,32))
	wall.fill_rect(Rect2i(40,32,50,2))
	walker = MatchUnit.new(0,1,Vector2(4.7,4))
	walker.velocity.x = 5
	for tick in range(12): walker.step(wall,STEP,0,false,false)
	assert(walker.feet.y == 4 and walker.feet.x < 4.75, "Knockback cannot auto-climb terrain")
	var cliff := TerrainGrid.new()
	cliff.fill_rect(Rect2i(0,0,40,32))
	walker = MatchUnit.new(0,1,Vector2(4.5,4))
	for tick in range(35): walker.step(cliff,STEP,1,false,true)
	assert(not walker.grounded and walker.feet.y < 3.5, "Real gaps still cause falling")
	var river := TerrainGrid.new()
	BattleMaps.build(river,BattleMaps.Layout.RIVER_OUTPOSTS)
	var floor := river.first_contact(Vector2(26,4.2),Vector2(26,1))
	walker = MatchUnit.new(0,1,floor)
	for tick in range(250): walker.step(river,STEP,1,false,true)
	assert(walker.feet.x > 40 and walker.feet.y < 4.2 and walker.grounded,
		"The actual river underpass is traversable beneath its destructible roof")
	print("PASS: small-step ascent both ways, grounded descent, walls, headroom, knockback, gaps and traversable river underpass")
	quit()
