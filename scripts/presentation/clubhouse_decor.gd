class_name ClubhouseDecor
extends RefCounted

const SOURCE := "res://assets/kenney/furniture/"
const WOOD := Color("#ac7851")
const TEAL := Color("#426e6b")
const CREAM := Color("#dacbb1")


static func prop(parent: Node3D, asset: String, point: Vector3, height: float, angle: float = 0.0) -> Node3D:
	var mesh := load(SOURCE + asset + ".obj") as Mesh
	var bounds := mesh.get_aabb()
	var root := Node3D.new()
	root.name = asset
	parent.add_child(root)
	root.position = point
	root.rotation.y = angle
	root.scale = Vector3.ONE * height / maxf(bounds.size.y, 0.01)
	var view := MeshInstance3D.new()
	view.mesh = mesh
	view.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
	root.add_child(view)
	for i in range(mesh.get_surface_count()):
		var source := mesh.surface_get_material(i) as StandardMaterial3D
		if source == null:
			continue
		var material := source.duplicate() as StandardMaterial3D
		material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		material.roughness = 1.0
		# Keep the shared loader's source colors; shelter recoloring is explicit.
		view.set_surface_override_material(i, material)
	return root


static func color_prop(root: Node3D, color: Color, surface_name: String = "") -> void:
	var view := root.get_child(0) as MeshInstance3D
	for i in range(view.mesh.get_surface_count()):
		var material := view.get_surface_override_material(i) as StandardMaterial3D
		if material != null and (surface_name.is_empty() or material.resource_name == surface_name):
			material.albedo_color = color


static func fit(root: Node3D, size: Vector3) -> void:
	var view := root.get_child(0) as MeshInstance3D
	root.scale = size / view.mesh.get_aabb().size


static func furnished(parent: Node3D, asset: String, point: Vector3, height: float, angle: float = 0.0) -> Node3D:
	var root := prop(parent, asset, point, height, angle)
	color_prop(root, WOOD, "wood")
	return root


static func room(parent: Node3D, anchors: Array[Node3D]) -> void:
	var shell := Node3D.new()
	shell.name = "RoomShell"
	parent.add_child(shell)
	# Original modular meshes provide the architecture, bevels and furniture.
	for i in range(6):
		var x := -6.0 + i * 2.4
		var wall := prop(shell, "wall", Vector3(x, 0, -2.1), 4.7)
		fit(wall, Vector3(2.41, 4.7, 0.12))
		wall.rotation.y = PI
		color_prop(wall, CREAM, "wood")
		color_prop(wall, Color("#708f91"), "glass")
		var panel := prop(shell, "paneling", Vector3(x, 0, -1.91), 1.32)
		fit(panel, Vector3(2.4, 1.32, 0.08))
		color_prop(panel, TEAL)
	for x in [-2.2, 2.2]:
		var window := prop(shell, "wallWindow", Vector3(x, 2.0, -1.79), 1.55, PI)
		fit(window, Vector3(0.75, 1.55, 0.14))
		color_prop(window, WOOD, "wood")
		color_prop(window, Color("#708f91"), "glass")
	for x in [-7.22, 7.22]:
		var beam := prop(shell, "floorFull", Vector3(x, 0, -1.82), 4.85)
		fit(beam, Vector3(0.15, 4.85, 0.23))
		color_prop(beam, Color("#77533e"))
	for height in [1.34, 4.7]:
		var trim := prop(shell, "floorFull", Vector3(0, height, -1.79), 0.12)
		fit(trim, Vector3(14.65, 0.12, 0.25))
		color_prop(trim, Color("#956644"))
	# Individual imported planks have intentional seams and varied wood tones.
	for row in range(6):
		for column in range(5):
			var tile := prop(shell, "floorFull", Vector3(-5.8 + column * 2.9, -0.16, -1.55 + row * 0.65), 0.16)
			fit(tile, Vector3(2.885, 0.16, 0.635))
			color_prop(tile, WOOD.lightened(0.035 * ((row + column * 2) % 4)))
	var lip := prop(shell, "floorFull", Vector3(0, -0.3, 2.05), 0.18)
	fit(lip, Vector3(14.6, 0.18, 0.22))
	color_prop(lip, Color("#644935"))
	for x in [-6.85, 6.85]:
		furnished(parent, "pottedPlant", Vector3(x, 0, -1.0), 1.5)
	var rug := prop(parent, "rugRounded", Vector3(0, 0.015, 0.65), 0.018)
	fit(rug, Vector3(5.4, 0.018, 1.15))
	color_prop(rug, Color("#b9604e"))
	_map_corner(anchors[0])
	_supply_corner(anchors[1])
	_crew_corner(anchors[2])


static func _map_corner(anchor: Node3D) -> void:
	furnished(anchor, "table", Vector3(0, 0, -0.8), 1.15)
	furnished(anchor, "chairRounded", Vector3(-1.25, 0, -0.75), 1.25, 0.4)
	furnished(anchor, "lampRoundTable", Vector3(-0.9, 1.15, -0.95), 0.6)
	furnished(anchor, "books", Vector3(0.8, 1.15, -0.8), 0.23)
	var route := Sprite3D.new()
	route.name = "ValleyRoute"
	route.texture = load("res://assets/ui/shelter/valley_route.svg")
	route.pixel_size = 0.0056
	route.position = Vector3(0, 2.65, -1.65)
	anchor.add_child(route)
	var paper := Sprite3D.new()
	paper.texture = route.texture
	paper.pixel_size = 0.003
	paper.position = Vector3(0.0, 1.16, -0.55)
	paper.rotation.x = -PI / 2.0
	anchor.add_child(paper)


static func _supply_corner(anchor: Node3D) -> void:
	furnished(anchor, "desk", Vector3(0, 0, -0.8), 1.15)
	furnished(anchor, "radio", Vector3(-0.55, 1.15, -0.9), 0.4)
	furnished(anchor, "books", Vector3(0.75, 1.15, -0.9), 0.23)
	var kit := furnished(anchor, "cardboardBoxClosed", Vector3(0.2, 1.15, -0.65), 0.5)
	color_prop(kit, Color("#678e80"))
	var cross := Label3D.new()
	cross.text = "+"
	cross.font = InterfaceSkin.face(650)
	cross.font_size = 62
	cross.pixel_size = 0.008
	cross.modulate = InterfaceSkin.PAPER
	cross.outline_size = 0
	cross.position = Vector3(0.2, 1.42, -0.44)
	anchor.add_child(cross)
	furnished(anchor, "cardboardBoxClosed", Vector3(-1.55, 0, -0.7), 0.64)
	furnished(anchor, "cardboardBoxClosed", Vector3(-1.55, 0.64, -0.7), 0.45, 0.15)
	furnished(anchor, "lampSquareCeiling", Vector3(0.0, 3.65, -0.65), 0.6)


static func _crew_corner(anchor: Node3D) -> void:
	var bench := furnished(anchor, "benchCushion", Vector3(0, 0, -0.85), 1.28)
	fit(bench, Vector3(2.65, 1.28, 0.85))
	color_prop(bench, Color("#b46452"), "carpet")
	for i in range(2):
		var cushion := prop(anchor, "pillow", Vector3(-0.65 + i * 1.3, 0.64, -0.94), 0.5, -0.12 + i * 0.24)
		color_prop(cushion, Color("#d1ab68") if i == 0 else Color("#7faaa0"))
	furnished(anchor, "sideTable", Vector3(1.55, 0, -1.12), 1.0)
	furnished(anchor, "plantSmall1", Vector3(1.55, 1.0, -1.12), 0.5)
	var mat := prop(anchor, "rugRounded", Vector3(-1.25, 0.015, -0.1), 0.018)
	fit(mat, Vector3(1.1, 0.018, 0.72))
	color_prop(mat, Color("#78a498"))
	mat.name = "ScoutMat"
