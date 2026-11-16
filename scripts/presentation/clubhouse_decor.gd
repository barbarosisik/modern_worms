class_name ClubhouseDecor
extends RefCounted

const SOURCE := "res://assets/kenney/furniture/"


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
	view.position = -Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)
	root.add_child(view)
	for i in range(mesh.get_surface_count()):
		var source := mesh.surface_get_material(i) as StandardMaterial3D
		if source == null: continue
		var material := source.duplicate() as StandardMaterial3D
		material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		material.roughness = 1.0
		if asset in ["wall","wallWindow"]:
			material.albedo_color = material.albedo_color.lerp(Color("#b59d7e"),0.3)
		view.set_surface_override_material(i,material)
	return root


static func room(parent: Node3D) -> void:
	# Use the supplied architectural meshes for the shell as well as the furniture.
	for x in range(-6,7,2):
		var wall := prop(parent,"wallWindow" if x in [-4,4] else "wall",Vector3(x,0,-2.0),4.0)
		wall.scale.x *= 0.645
	var floor_mesh := prop(parent,"floorFull",Vector3(0,-0.12,0),0.12)
	floor_mesh.scale.x *= 6.0
	floor_mesh.scale.z *= 2.0
	prop(parent,"table",Vector3(-4.6,0,-0.7),1.05)
	prop(parent,"chairRounded",Vector3(-5.9,0,-0.9),1.25,0.4)
	prop(parent,"lampRoundTable",Vector3(-5.35,1.05,-0.9),0.65)
	prop(parent,"desk",Vector3(0,0,-0.8),1.1)
	prop(parent,"radio",Vector3(-0.55,1.1,-0.9),0.5)
	prop(parent,"books",Vector3(0.65,1.1,-0.8),0.28)
	prop(parent,"bookcaseOpen",Vector3(4.9,0,-1.5),2.25)
	prop(parent,"books",Vector3(4.8,0.7,-1.1),0.35)
	prop(parent,"benchCushion",Vector3(2.25,0,-1.1),1.1)
	prop(parent,"pottedPlant",Vector3(-6.25,0,-1.25),1.65)
	prop(parent,"pottedPlant",Vector3(6.2,0,-1.3),1.45)
	prop(parent,"coatRackStanding",Vector3(3.2,0,-1.5),1.9)
	prop(parent,"lampRoundFloor",Vector3(-2.45,0,-1.4),2.15)
	var rug := prop(parent,"rugRounded",Vector3(0,0.01,0.5),0.015)
	rug.scale.x *= 2.8
	rug.scale.z *= 0.8
