extends Control

var arena: MatchArena

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if arena == null or not arena.visible or not arena._aim_controls.is_dragging():
		return
	var anchor := arena._aim_controls.drag_anchor()
	var cursor := get_viewport().get_mouse_position()
	var tint := Color("#ffdc85")
	draw_line(anchor, cursor, tint, 3.0, true)
	draw_arc(anchor, 9.0, 0.0, TAU, 24, tint, 2.0, true)
	draw_circle(cursor, 5.0, tint)
	draw_string(ThemeDB.fallback_font, cursor + Vector2(14, -16), "%d%%  |  Right-click cancels" % arena._aim_controls.charge, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, tint)
