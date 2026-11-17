class_name InterfaceSkin
extends RefCounted

const ART := "res://assets/kenney/ui_adventure/"
const INK := Color("#49362b")
const TEAL := Color("#315e60")
const PAPER := Color("#fff0c9")
const FONT := preload("res://assets/fonts/Fredoka.ttf")


static func install(app: Node) -> void:
	var interface: Control = app.get_node("Interface")
	var theme := Theme.new()
	theme.default_font = face(500)
	theme.default_font_size = 18
	theme.set_stylebox("panel","PanelContainer",panel())
	for type in ["Button","OptionButton"]:
		for state in ["normal","hover","pressed","disabled","focus"]:
			var style := texture("button_brown.png",12,18,7)
			if state == "hover": style.modulate_color = Color(1.25,1.15,1.0)
			if state == "pressed": style = texture("button_red.png",12,18,7)
			if state == "disabled": style.modulate_color = Color(0.7,0.7,0.7,0.7)
			if state == "focus":
				var focus := StyleBoxFlat.new()
				focus.bg_color = Color.TRANSPARENT
				focus.border_color = Color("#eab75b")
				focus.set_border_width_all(3)
				focus.set_corner_radius_all(8)
				theme.set_stylebox(state,type,focus)
			else:
				theme.set_stylebox(state,type,style)
		for state in ["font_color","font_hover_color","font_focus_color"]:
			theme.set_color(state,type,INK)
		theme.set_color("font_pressed_color",type,PAPER)
		theme.set_font("font",type,face(600))
		theme.set_color("font_disabled_color",type,Color("#715b44"))
		theme.set_color("font_outline_color",type,Color("#5a3928"))
		theme.set_constant("outline_size",type,0)
	theme.set_type_variation("PrimaryButton","Button")
	theme.set_stylebox("normal","PrimaryButton",texture("button_red.png",12,18,7))
	theme.set_stylebox("hover","PrimaryButton",texture("button_red.png",12,18,7,Color(1.15,1.1,1)))
	theme.set_color("font_color","PrimaryButton",PAPER)
	theme.set_color("font_hover_color","PrimaryButton",PAPER)
	theme.set_color("font_focus_color","PrimaryButton",PAPER)
	theme.set_color("font_color","Label",INK)
	theme.set_constant("separation","VBoxContainer",8)
	theme.set_constant("separation","HBoxContainer",12)
	theme.set_stylebox("background","ProgressBar",texture("progress_transparent.png",8,0,0))
	theme.set_stylebox("fill","ProgressBar",texture("progress_blue.png",8,0,0))
	theme.set_color("font_color","ProgressBar",INK)
	theme.set_font_size("font_size","ProgressBar",15)
	var track := StyleBoxFlat.new()
	track.bg_color = Color("#ac956d")
	track.set_corner_radius_all(4)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	theme.set_stylebox("slider","HSlider",track)
	var filled := track.duplicate() as StyleBoxFlat
	filled.bg_color = TEAL
	theme.set_stylebox("grabber_area","HSlider",filled)
	theme.set_icon("grabber","HSlider",icon("round_brown.png",24))
	theme.set_icon("grabber_highlight","HSlider",icon("round_brown.png",28))
	theme.set_color("font_color","CheckButton",INK)
	theme.set_color("font_hover_color","CheckButton",TEAL)
	theme.set_icon("checked","CheckButton",icon("checkbox_beige_checked.png",32))
	theme.set_icon("unchecked","CheckButton",icon("checkbox_beige_empty.png",32))
	theme.set_stylebox("tab_selected","TabBar",texture("panel_brown.png",12,18,10))
	theme.set_stylebox("tab_unselected","TabBar",texture("button_brown.png",12,18,10))
	theme.set_color("font_selected_color","TabBar",INK)
	theme.set_color("font_unselected_color","TabBar",INK)
	theme.set_icon("arrow","OptionButton",icon("minimap_arrow_b.png",16))
	theme.set_color("icon_normal_color","OptionButton",TEAL)
	theme.set_stylebox("panel","PopupMenu",panel())
	theme.set_stylebox("hover","PopupMenu",texture("button_red.png",12,12,6))
	theme.set_color("font_color","PopupMenu",INK)
	theme.set_color("font_hover_color","PopupMenu",PAPER)
	theme.set_icon("checked","PopupMenu",icon("checkbox_beige_checked.png",24))
	theme.set_stylebox("panel","TooltipPanel",panel())
	theme.set_color("font_color","TooltipLabel",INK)
	interface.theme = theme
	for label in interface.find_children("*","Label",true,false):
		var path := str(label.get_path())
		var on_paper := not ("MatchHud" in path or "/Hud/" in path or "ShelterHud" in path)
		if on_paper or "Readout/" in path or "StationCard/" in path:
			label.add_theme_color_override("font_color",TEAL if label.name in ["Kicker","WeaponStatus","Controls"] else INK)
		elif not label.has_theme_color_override("font_color"):
			label.add_theme_color_override("font_color",PAPER)
		if label.name in ["Title","Heading"]:
			label.add_theme_font_override("font",face(650))
	for button_name in ["SoloButton","ContinueStory","ApplyButton","Rematch","StationAction"]:
		var button := app.get_node("%" + button_name) as Button
		button.theme_type_variation = "PrimaryButton"
		button.remove_theme_stylebox_override("normal")
	_build_home(app)
	_build_shelter(app)
	var backdrop := app.get_node("ArenaBackdrop/CartoonBackdrop") as ColorRect
	backdrop.color = Color("#263e45")
	var pattern := TextureRect.new()
	pattern.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pattern.texture = load(ART + "pattern_grid_blueprint.png")
	pattern.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	pattern.stretch_mode = TextureRect.STRETCH_TILE
	pattern.modulate = Color(0.7,0.8,0.7,0.06)
	backdrop.add_child(pattern)
	pattern.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


static func _build_shelter(app: Node) -> void:
	var hud := app.get_node("%ShelterHud") as Control
	hud.get_node("Heading").text = "OUR CLUBHOUSE"
	var text := hud.get_node("StationCard/Row/Text") as VBoxContainer
	var title := Label.new()
	title.name = "StationTitle"
	title.add_theme_font_override("font", face(650))
	title.add_theme_font_size_override("font_size", 23)
	text.add_child(title)
	text.move_child(title, 0)
	var story := app.get_node("%ShelterStory") as Label
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story.add_theme_font_size_override("font_size", 16)
	hud.get_node("StationCard").offset_top = -132
	hud.get_node("StationCard/Row").add_theme_constant_override("separation", 20)
	var action := app.get_node("%StationAction") as Button
	action.custom_minimum_size = Vector2(260, 52)
	var shortcut := hud.get_node("MapShortcut") as Button
	shortcut.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	shortcut.offset_left = -334
	shortcut.offset_right = -160
	shortcut.offset_top = 16
	shortcut.offset_bottom = 54
	shortcut.custom_minimum_size = Vector2(0, 38)
	shortcut.tooltip_text = "Open the expedition map from anywhere in the clubhouse."


static func _build_home(app: Node) -> void:
	var card := app.get_node("Interface/Home/Card") as PanelContainer
	var menu := card.get_node("Content") as VBoxContainer
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation",32)
	card.add_child(columns)
	menu.reparent(columns)
	menu.custom_minimum_size.x = 430
	menu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	menu.add_theme_constant_override("separation",8)
	card.custom_minimum_size.x = 1120
	menu.get_node("Title").add_theme_font_size_override("font_size",54)
	menu.get_node("Kicker").text = "THE RANGER CLUB"
	menu.get_node("Description").text = "Round up your crew. Shape the battlefield. Bring everyone home."
	var practice := HBoxContainer.new()
	practice.name = "PracticeRow"
	menu.add_child(practice)
	for name in ["MatchButton","StartButton"]:
		var button := app.get_node("%" + name) as Button
		button.reparent(practice)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	app.get_node("%MatchButton").text = "Local match"
	app.get_node("%StartButton").text = "Practice range"
	var utilities := HBoxContainer.new()
	utilities.name = "UtilityRow"
	menu.add_child(utilities)
	for name in ["HomeSettings","QuitButton"]:
		var button := app.get_node("%" + name) as Button
		button.reparent(utilities)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu.move_child(practice,menu.get_child_count()-2)
	var hero := PanelContainer.new()
	hero.name = "CrewShowcase"
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero.custom_minimum_size.x = 550
	hero.add_theme_stylebox_override("panel",texture("panel_grey_dark.png",16,22,22,Color(0.55,0.8,0.7)))
	columns.add_child(hero)
	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.add_child(stack)
	var title := Label.new()
	title.text = "A LITTLE CREW. A BIG ADVENTURE."
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",19)
	title.add_theme_color_override("font_color",PAPER)
	stack.add_child(title)
	var preview := SubViewportContainer.new()
	preview.name = "CrewPreview"
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.custom_minimum_size = Vector2(0,330)
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview.stretch = true
	stack.add_child(preview)
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.size = Vector2i(500,330)
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	preview.add_child(viewport)
	viewport.add_child(preload("res://scripts/presentation/menu_crew.gd").new())
	var names := Label.new()
	names.text = "MISKA  &  NOVA"
	names.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	names.add_theme_font_size_override("font_size",30)
	names.add_theme_color_override("font_color",PAPER)
	stack.add_child(names)
	var caption := Label.new()
	caption.text = "Side by side. One turn at a time."
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_color_override("font_color",Color("#b9d2bc"))
	stack.add_child(caption)


static func panel() -> StyleBoxTexture:
	return texture("panel_brown.png",16,28,22)


static func face(weight: float) -> FontVariation:
	var font := FontVariation.new()
	font.base_font = FONT
	var server := TextServerManager.get_primary_interface()
	font.variation_opentype = {server.name_to_tag("wght"):weight,server.name_to_tag("wdth"):100.0}
	return font


static func texture(file: String, border: float, margin_x: float, margin_y: float, tint: Color = Color.WHITE) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load(ART + file)
	style.texture_margin_left = border
	style.texture_margin_right = border
	style.texture_margin_top = border
	style.texture_margin_bottom = border
	style.content_margin_left = margin_x
	style.content_margin_right = margin_x
	style.content_margin_top = margin_y
	style.content_margin_bottom = margin_y
	style.modulate_color = tint
	return style


static func icon(file: String, pixels: int) -> Texture2D:
	var picture := (load(ART + file) as Texture2D).get_image()
	picture.resize(pixels,pixels,Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(picture)
