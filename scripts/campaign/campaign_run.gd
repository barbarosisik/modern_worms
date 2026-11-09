class_name CampaignRun
extends RefCounted

const MISSIONS := ["First Signal", "Ferry Landing"]
const OBJECTIVES := [
	"Reach Scout on foot and defeat the lookout.",
	"Defeat both members of the salvage crew and secure the ferry.",
]
const BRIEFINGS := [
	"Mara finds Eli at the flooded ranger post. Before either can speak, a familiar bark comes from the far end of the bank. A salvage lookout has taken the road.\n\nMara: “I thought the river took you.”\nEli: “You know I always come back. Let's get Scout.”",
	"Scout leads Mara and Eli to the old ferry landing. The salvage crew has cut the crossing. If the three can clear the dock, the stranded families will have a way out.\n\nEli: “Remember the summer we swam across?”\nMara: “I remember you promising we'd take the ferry next time.”",
]
const ROSTER := ["Mara", "Eli", "Scout"]
const OUTFITS := ["Harbor blue", "Pine green", "Signal red"]
const OUTFIT_COLORS := [Color("#267fa3"), Color("#42785e"), Color("#bf513f")]
const CLEAR_REWARD := 2
const UPGRADE_COST := 1
const KIT_BONUS := 15
const SAVE_VERSION := 1

var started := false
var cleared := 0
var supplies := 0
var field_kits := false
var guide_tiers := PackedInt32Array([0, 0, 0])
var outfits := PackedInt32Array([0, 1])


func begin(selected_outfits: PackedInt32Array) -> void:
	started = true
	cleared = 0
	supplies = 0
	field_kits = false
	guide_tiers.fill(0)
	outfits = selected_outfits.duplicate()


func finished() -> bool:
	return cleared == MISSIONS.size()


func roster_size() -> int:
	return 3 if cleared >= 1 else 2


func complete(mission_index: int, collected: int) -> bool:
	if not started or finished() or mission_index != cleared:
		return false
	cleared += 1
	supplies += CLEAR_REWARD + collected
	return true


func can_buy_kits() -> bool:
	return cleared > 0 and not finished() and not field_kits and supplies >= UPGRADE_COST


func buy_kits() -> bool:
	if not can_buy_kits():
		return false
	supplies -= UPGRADE_COST
	field_kits = true
	return true


func can_train(index: int) -> bool:
	return cleared > 0 and not finished() and index >= 0 and index < roster_size() and (
		supplies >= UPGRADE_COST and guide_tiers[index] < TrajectoryGuide.DOT_COUNTS.size() - 1
	)


func train(index: int) -> bool:
	if not can_train(index):
		return false
	supplies -= UPGRADE_COST
	guide_tiers[index] += 1
	return true


func load_checkpoint(path: String) -> void:
	var config := ConfigFile.new()
	if config.load(path) != OK or config.get_value("run", "version", 0) != SAVE_VERSION:
		return
	var saved_outfits: Variant = config.get_value("appearance", "outfits", outfits)
	if saved_outfits is PackedInt32Array and saved_outfits.size() == outfits.size():
		for i in range(outfits.size()):
			outfits[i] = clampi(saved_outfits[i], 0, OUTFITS.size() - 1)
	started = bool(config.get_value("run", "started", false))
	if not started:
		return
	cleared = clampi(int(config.get_value("run", "cleared", 0)), 0, MISSIONS.size())
	if cleared == 0:
		return
	supplies = maxi(0, int(config.get_value("run", "supplies", 0)))
	field_kits = bool(config.get_value("run", "field_kits", false))
	var saved_tiers: Variant = config.get_value("run", "guide_tiers", guide_tiers)
	if saved_tiers is PackedInt32Array and saved_tiers.size() == guide_tiers.size():
		for i in range(guide_tiers.size()):
			guide_tiers[i] = clampi(saved_tiers[i], 0, TrajectoryGuide.DOT_COUNTS.size() - 1)


func save_checkpoint(path: String) -> Error:
	var config := ConfigFile.new()
	config.set_value("run", "version", SAVE_VERSION)
	config.set_value("run", "started", started)
	config.set_value("run", "cleared", cleared)
	config.set_value("run", "supplies", supplies)
	config.set_value("run", "field_kits", field_kits)
	config.set_value("run", "guide_tiers", guide_tiers)
	config.set_value("appearance", "outfits", outfits)
	var pending := path + ".pending"
	var result := config.save(pending)
	if result != OK:
		return result
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(pending), ProjectSettings.globalize_path(path))
