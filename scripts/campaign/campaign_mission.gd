class_name CampaignMission
extends RefCounted

var index: int
var terrain := TerrainGrid.new()
var units: Array[MatchUnit] = []
var rescue_target: MatchUnit
var wind_scale: float
var cpu_error_scale: float


func _init(mission_index: int, run: CampaignRun) -> void:
	index = mission_index
	if index == 0:
		_first_signal(run)
	else:
		_ferry_landing(run)


func _first_signal(run: CampaignRun) -> void:
	wind_scale = 0.5
	cpu_error_scale = 1.45
	terrain.fill_rect(Rect2i(16, 9, 86, 21))
	terrain.fill_rect(Rect2i(102, 9, 12, 9))
	terrain.fill_rect(Rect2i(114, 9, 70, 19))
	_add_rescuers(run, 3.75)
	var lookout := MatchUnit.new(1, 1, Vector2(17.25, 3.5))
	lookout.display_name = "Lookout"
	lookout.health = 62
	units.append(lookout)
	rescue_target = MatchUnit.new(0, 3, Vector2(9.0, 3.75))
	rescue_target.display_name = CampaignRun.ROSTER[2]


func _ferry_landing(run: CampaignRun) -> void:
	wind_scale = 1.0
	cpu_error_scale = 0.82
	terrain.fill_rect(Rect2i(8, 10, 78, 22))
	terrain.fill_rect(Rect2i(94, 10, 66, 14))
	terrain.fill_rect(Rect2i(165, 10, 83, 24))
	terrain.fill_rect(Rect2i(118, 24, 10, 9))
	_add_rescuers(run, 4.0)
	var rigger := MatchUnit.new(1, 1, Vector2(23.2, 4.25))
	rigger.display_name = "Rigger"
	rigger.health = 74
	var foreman := MatchUnit.new(1, 2, Vector2(28.0, 4.25))
	foreman.display_name = "Foreman"
	foreman.health = 82
	units.append(rigger)
	units.append(foreman)


func _add_rescuers(run: CampaignRun, floor_height: float) -> void:
	var spawns := [4.25, 6.55, 8.95]
	for i in range(run.roster_size()):
		var unit := MatchUnit.new(0, i + 1, Vector2(spawns[i], floor_height))
		unit.display_name = CampaignRun.ROSTER[i]
		unit.outfit = run.outfits[i] if i < run.outfits.size() else 0
		unit.guide_tier = run.guide_tiers[i]
		if run.field_kits:
			unit.health += CampaignRun.KIT_BONUS
		units.append(unit)
