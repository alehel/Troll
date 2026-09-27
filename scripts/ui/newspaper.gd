class_name Newspaper
extends Control
## "Lillevik Tidende" - the village paper, shown every morning.

signal closed

var panel: PanelContainer
var body: VBoxContainer
var _open := false
var _ready_to_close := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	panel = PanelContainer.new()
	var sb: StyleBoxFlat = UiTheme.box(Color(0.95, 0.92, 0.84), Color(0.3, 0.26, 0.22), 2, 1, true, 14)
	panel.add_theme_stylebox_override("panel", sb)
	panel.rotation = -0.012
	center.add_child(panel)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 4)
	panel.add_child(body)
	visible = false


func _rule() -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0.3, 0.26, 0.22)
	r.custom_minimum_size = Vector2(0, 2)
	return r


func _wrap(text: String, size: int, color: Color, bold := false, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := UiTheme.label(text, size, color, bold)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = align
	l.custom_minimum_size = Vector2(390, 0)
	return l


func show_paper(p: Dictionary) -> void:
	for c in body.get_children():
		c.queue_free()
	var ink := Color(0.16, 0.13, 0.11)
	var soft := Color(0.36, 0.31, 0.27)
	body.add_child(_wrap(p.get("title", "LILLEVIK TIDENDE"), 24, ink, true, HORIZONTAL_ALIGNMENT_CENTER))
	var info := HBoxContainer.new()
	info.add_child(UiTheme.label(p.get("date", ""), 9, soft))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(sp)
	info.add_child(UiTheme.label("Price: one smile", 9, soft))
	body.add_child(info)
	body.add_child(_rule())
	body.add_child(_wrap(p.get("headline", ""), 16, ink, true, HORIZONTAL_ALIGNMENT_CENTER))
	if p.get("sub", "") != "":
		body.add_child(_wrap(p["sub"], 10, soft, false, HORIZONTAL_ALIGNMENT_CENTER))
	body.add_child(_rule())
	for s in p.get("stories", []):
		body.add_child(_wrap("- " + String(s), 10, ink))
	body.add_child(_rule())
	var myth := PanelContainer.new()
	myth.add_theme_stylebox_override("panel", UiTheme.box(Color(0.88, 0.84, 0.74), Color(0.5, 0.45, 0.4), 1, 1, false, 5))
	var ml := _wrap(p.get("myth", ""), 9, ink)
	ml.custom_minimum_size = Vector2(378, 0)
	myth.add_child(ml)
	body.add_child(myth)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 6)
	var wl := UiTheme.label("Weather: " + p.get("weather", ""), 9, soft)
	wl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	wl.custom_minimum_size = Vector2(240, 0)
	bottom.add_child(wl)
	var sp2 := Control.new()
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(sp2)
	bottom.add_child(UiTheme.icon(Game.STAGE_ICONS[clampi(int(float(p.get("mood_value", 0.0)) / 17.0), 0, 5)], 16))
	bottom.add_child(UiTheme.label("Mood: " + p.get("mood", ""), 9, soft, true))
	body.add_child(bottom)
	var hint := UiTheme.label("Press E to continue", 9, UiTheme.ACCENT, true)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	body.add_child(hint)
	visible = true
	_open = true
	_ready_to_close = false
	panel.scale = Vector2(0.9, 0.9)
	await get_tree().process_frame
	panel.pivot_offset = panel.size * 0.5
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.35)
	tw.parallel().tween_property(panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): _ready_to_close = true)
	Sound.sfx("paper")
	await closed


func _close() -> void:
	_open = false
	Sound.sfx("paper", 1.2)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func():
		visible = false
		emit_signal("closed"))


func _input(event: InputEvent) -> void:
	if not _open or not _ready_to_close:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("cancel") or event.is_action_pressed("pause") or (event is InputEventMouseButton and event.pressed):
		get_viewport().set_input_as_handled()
		_close()
