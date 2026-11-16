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
	BattleMaps.build(terrain, BattleMaps.Layout.FIRST_SIGNAL)
	_add_rescuers(run)
	var lookout := MatchUnit.new(1, 1, Vector2(38.0, BattleMaps.surface_y(terrain, 38.0)))
	lookout.display_name = "Lookout"
	lookout.health = 62
	units.append(lookout)
	rescue_target = MatchUnit.new(0, 3, Vector2(20.0, BattleMaps.surface_y(terrain, 20.0)))
	rescue_target.display_name = CampaignRun.ROSTER[2]


func _ferry_landing(run: CampaignRun) -> void:
	wind_scale = 1.0
	cpu_error_scale = 0.82
	BattleMaps.build(terrain, BattleMaps.Layout.FERRY_LANDING)
	_add_rescuers(run)
	var rigger := MatchUnit.new(1, 1, Vector2(35.0, BattleMaps.surface_y(terrain, 35.0)))
	rigger.display_name = "Rigger"
	rigger.health = 74
	var foreman := MatchUnit.new(1, 2, Vector2(53.0, BattleMaps.surface_y(terrain, 53.0)))
	foreman.display_name = "Foreman"
	foreman.health = 82
	units.append(rigger)
	units.append(foreman)


func _add_rescuers(run: CampaignRun) -> void:
	var spawns := [8.0, 12.5, 22.0]
	for i in range(run.roster_size()):
		var unit := MatchUnit.new(0, i + 1, Vector2(spawns[i], BattleMaps.surface_y(terrain, spawns[i])))
		unit.display_name = CampaignRun.ROSTER[i]
		unit.outfit = run.outfits[i] if i < run.outfits.size() else 0
		unit.guide_tier = run.guide_tiers[i]
		if run.field_kits:
			unit.health += CampaignRun.KIT_BONUS
		units.append(unit)
