class_name CampaignPanel
extends CenterContainer

signal close_requested
signal story_requested(outfits: PackedInt32Array)
signal mission_requested
signal checkpoint_changed

@onready var _kicker: Label = %Kicker
@onready var _heading: Label = %Heading
@onready var _body: Label = %Body
@onready var _wallet: Label = %Wallet
@onready var _warning: Label = %Warning
@onready var _preview: SubViewportContainer = %Preview
@onready var _preview_world: Node3D = %PreviewWorld
@onready var _content: VBoxContainer = %Content
@onready var _back: Button = %Close

var _run: CampaignRun
var _selected := PackedInt32Array()
var _models: Array[CampaignActor] = []
var _purchase: Button
var _roster_index := 0


func _ready() -> void:
	_back.pressed.connect(func() -> void: close_requested.emit())
	(%PreviewCamera as Camera3D).look_at(Vector3(0.0, 0.53, 0.0))
	for i in range(3):
		var model := CampaignActor.new(CampaignRun.ROSTER[i], i)
		_preview_world.add_child(model)
		model.position.x = -1.44 + 2.88 * i
		model.visible = i < 2
		model.scale = Vector3.ONE * 1.2
		model.pose(1.0 if i == 0 else -1.0, 0.0, 0.0)
		_models.append(model)


func open_wardrobe(run: CampaignRun) -> void:
	_prepare("SIGNAL FIRES  /  NEW STORY", "Meet the rescuers")
	_body.text = "Miska and Nova return to their flooded valley together. Miska and Nova are two cats. Choose their coat styles before the first mission. A new story starts with fresh progress and skills."
	_preview.show()
	for i in range(_models.size()):
		_models[i].visible = i < 2
		_models[i].position.x = -1.44 + 2.88 * i
	_selected = run.outfits.duplicate()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	_content.add_child(row)
	for i in range(2):
		_models[i].set_outfit(_selected[i])
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(column)
		var name_label := Label.new()
		name_label.text = CampaignRun.ROSTER[i]
		column.add_child(name_label)
		var options := OptionButton.new()
		options.name = CampaignRun.ROSTER[i] + "Outfit"
		options.custom_minimum_size.y = 39.0
		for outfit in CampaignRun.OUTFITS:
			options.add_item(outfit)
		options.select(_selected[i])
		column.add_child(options)
		options.item_selected.connect(_select_outfit.bind(i))
	_button("Begin story", "BeginStory", func() -> void: story_requested.emit(_selected)).grab_focus()


func open_map(run: CampaignRun) -> void:
	var heading: String = "Both available missions cleared" if run.finished() else CampaignRun.MISSIONS[run.cleared]
	_prepare("SIGNAL FIRES  /  MAP TABLE", heading)
	for i in range(CampaignRun.MISSIONS.size()):
		var status := "Cleared" if i < run.cleared else ("Ready" if i == run.cleared else "Ahead")
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel",InterfaceSkin.texture("panel_brown.png",16,18,14))
		_content.add_child(card)
		var row := HBoxContainer.new()
		card.add_child(row)
		var number := Label.new()
		number.text = "%02d" % (i+1)
		number.add_theme_font_size_override("font_size",28)
		number.add_theme_font_override("font",InterfaceSkin.face(650))
		row.add_child(number)
		var name_label := Label.new()
		name_label.text = CampaignRun.MISSIONS[i]
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		var badge := Label.new()
		badge.text = status.to_upper()
		badge.add_theme_color_override("font_color",InterfaceSkin.TEAL)
		row.add_child(badge)
	if run.finished():
		_body.text = "The ferry is secure. Both existing missions are complete. Try the larger skirmish maps, or return to your crew in the shelter."
		_back.grab_focus()
		return
	_body.text = CampaignRun.BRIEFINGS[run.cleared]
	_wallet.text = CampaignRun.OBJECTIVES[run.cleared]
	_wallet.show()
	_button("Start mission", "StartMission", func() -> void: mission_requested.emit()).grab_focus()


func open_team(run: CampaignRun) -> void:
	_prepare("RANGER SHELTER  /  SUPPLY BENCH", "Team upgrades")
	_run = run
	_purchase = _button("Buy field kits", "BuyKits", _buy_kits)
	_refresh_team()
	_focus_purchase()


func open_roster(run: CampaignRun) -> void:
	_prepare("RANGER SHELTER  /  ROSTER BOARD", "Character upgrades")
	_run = run
	_roster_index = 0
	var tabs := TabBar.new()
	tabs.name = "RosterTabs"
	for i in range(run.roster_size()):
		tabs.add_tab(CampaignRun.ROSTER[i])
	_content.add_child(tabs)
	tabs.tab_changed.connect(_select_rescuer)
	_purchase = _button("Train aim", "BuyGuide", _buy_guide)
	_refresh_roster()
	tabs.grab_focus()


func show_save_warning(show_warning: bool) -> void:
	_warning.visible = show_warning


func _prepare(kicker: String, heading: String) -> void:
	_kicker.text = kicker
	_heading.text = heading
	_preview.hide()
	_wallet.hide()
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()


func _button(caption: String, node_name: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = caption
	button.theme_type_variation = "PrimaryButton"
	button.custom_minimum_size.y = 42.0
	button.pressed.connect(action)
	_content.add_child(button)
	return button


func _select_outfit(outfit: int, character: int) -> void:
	_selected[character] = outfit
	_models[character].set_outfit(outfit)


func _select_rescuer(character: int) -> void:
	_roster_index = character
	_refresh_roster()


func _buy_kits() -> void:
	if _run.buy_kits():
		checkpoint_changed.emit()
		_refresh_team()
		_focus_purchase()


func _buy_guide() -> void:
	if _run.train(_roster_index):
		checkpoint_changed.emit()
		_refresh_roster()
		_focus_purchase()


func _refresh_team() -> void:
	_show_wallet()
	_body.text = "Field kits give every rescuer +%d starting HP in each mission." % CampaignRun.KIT_BONUS
	_purchase.text = "Field kits equipped" if _run.field_kits else "Buy field kits  ·  %d supply" % CampaignRun.UPGRADE_COST
	_purchase.disabled = not _run.can_buy_kits()


func _refresh_roster() -> void:
	_show_wallet()
	_preview.show()
	for i in range(_models.size()):
		_models[i].visible = i == _roster_index
		_models[i].position.x = 0.0
	_preview.show()
	for i in range(_models.size()):
		_models[i].visible = i == _roster_index
		if i == _roster_index: _models[i].position.x = 0
	var tier := _run.guide_tiers[_roster_index]
	var dots := TrajectoryGuide.DOT_COUNTS
	_body.text = "%s can currently see up to %d dots when aiming." % [CampaignRun.ROSTER[_roster_index], dots[tier]]
	_purchase.text = "Aim fully trained"
	if tier < dots.size() - 1:
		_purchase.text = "Train aim to %d dots  ·  %d supply" % [dots[tier + 1], CampaignRun.UPGRADE_COST]
	_purchase.disabled = not _run.can_train(_roster_index)


func _show_wallet() -> void:
	_wallet.text = "AVAILABLE SUPPLIES   %d" % _run.supplies
	_wallet.show()


func _focus_purchase() -> void:
	if _purchase.disabled:
		_back.grab_focus()
	else:
		_purchase.grab_focus()
