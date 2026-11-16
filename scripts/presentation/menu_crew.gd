extends Node3D

var _actors: Array[CampaignActor] = []


func _ready() -> void:
	var camera := Camera3D.new()
	camera.position = Vector3(0,0.9,4.0)
	camera.fov = 28
	camera.environment = Environment.new()
	camera.environment.background_mode = Environment.BG_CLEAR_COLOR
	camera.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	camera.environment.ambient_light_color = Color("#d8e9d3")
	camera.environment.ambient_light_energy = 0.65
	camera.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(camera)
	camera.look_at(Vector3(0,0.75,0))
	for i in range(2):
		var actor := CampaignActor.new(CampaignRun.ROSTER[i],i)
		add_child(actor)
		actor.position.x = -0.85 if i == 0 else 0.85
		actor.scale = Vector3.ONE * 1.55
		actor.pose(1 if i == 0 else -1,0,0)
		_actors.append(actor)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-28,-25,0)
	key.light_color = Color("#ffe5af")
	key.light_energy = 1.1
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15,135,0)
	fill.light_color = Color("#86cfca")
	fill.light_energy = 0.5
	add_child(fill)
	var rug := ClubhouseDecor.prop(self,"rugRounded",Vector3(0,-0.03,0),0.02)
	rug.scale *= 0.75


func _process(delta: float) -> void:
	for i in range(_actors.size()):
		_actors[i].pose(1 if i == 0 else -1,0,delta)
