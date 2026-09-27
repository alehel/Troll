class_name Hud
extends Control
## Clock, current task, village mood, interaction prompt, notifications and
## floating speech bubbles.

var world: World
var sub_viewport: SubViewport
var clock_label: Label
var day_label: Label
var time_icon: TextureRect
var quest_panel: PanelContainer
var quest_label: Label
var mood_face: TextureRect
var mood_bar: ProgressBar
var mood_label: Label
var prompt_panel: PanelContainer
var prompt_label: Label
var notif_box: VBoxContainer
var bark_layer: Control
var marker: Label
var hint_panel: PanelContainer
var _barks: Array = [] # [{target, panel, time}]
var _focus: Interactable
var _t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	bark_layer = Control.new()
	bark_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bark_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bark_layer)
	marker = UiTheme.label("v", 16, Color(1.0, 0.95, 0.6), true)
	marker.add_theme_color_override("font_outline_color", UiTheme.BORDER)
	marker.add_theme_constant_override("outline_size", 4)
	marker.visible = false
	add_child(marker)
	# clock
	var clock := UiTheme.panel()
	clock.position = Vector2(6, 6)
	add_child(clock)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 4)
	clock.add_child(hb)
	time_icon = UiTheme.icon("sun", 16)
	hb.add_child(time_icon)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", -2)
	hb.add_child(vb)
	day_label = UiTheme.label("Day 1", 9, UiTheme.INK_SOFT)
	vb.add_child(day_label)
	clock_label = UiTheme.label("07:00", 13, UiTheme.INK, true)
	vb.add_child(clock_label)
	# tracked task
	quest_panel = UiTheme.panel(Color(0.98, 0.94, 0.85, 0.92))
	quest_panel.position = Vector2(6, 44)
	quest_panel.custom_minimum_size = Vector2(0, 0)
	add_child(quest_panel)
	var qh := HBoxContainer.new()
	qh.add_theme_constant_override("separation", 4)
	quest_panel.add_child(qh)
	qh.add_child(UiTheme.icon("book", 12))
	quest_label = UiTheme.label("", 9)
	quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_label.custom_minimum_size = Vector2(170, 0)
	qh.add_child(quest_label)
	# village mood
	var mood := UiTheme.panel()
	mood.anchor_left = 1.0
	mood.anchor_right = 1.0
	mood.offset_left = -124
	mood.offset_right = -6
	mood.offset_top = 6
	add_child(mood)
	var mh := HBoxContainer.new()
	mh.add_theme_constant_override("separation", 4)
	mood.add_child(mh)
	mood_face = UiTheme.icon("face_terrified", 16)
	mh.add_child(mood_face)
	var mv := VBoxContainer.new()
	mv.add_theme_constant_override("separation", 1)
	mv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mh.add_child(mv)
	mood_label = UiTheme.label("Lillevik: Panicked", 9, UiTheme.INK)
	mv.add_child(mood_label)
	mood_bar = ProgressBar.new()
	mood_bar.show_percentage = false
	mood_bar.custom_minimum_size = Vector2(80, 6)
	mood_bar.max_value = 100
	mv.add_child(mood_bar)
	# prompt
	prompt_panel = UiTheme.panel(Color(0.98, 0.94, 0.85, 0.95))
	prompt_panel.anchor_left = 0.5
	prompt_panel.anchor_right = 0.5
	prompt_panel.anchor_top = 1.0
	prompt_panel.anchor_bottom = 1.0
	prompt_panel.offset_top = -36
	prompt_panel.offset_bottom = -14
	prompt_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(prompt_panel)
	prompt_label = UiTheme.label("", 11)
	prompt_panel.add_child(prompt_label)
	prompt_panel.visible = false
	# notifications
	notif_box = VBoxContainer.new()
	notif_box.anchor_top = 1.0
	notif_box.anchor_bottom = 1.0
	notif_box.offset_left = 6
	notif_box.offset_bottom = -44
	notif_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	notif_box.add_theme_constant_override("separation", 3)
	notif_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(notif_box)
	# controls hint
	hint_panel = UiTheme.panel(Color(0.13, 0.12, 0.16, 0.85), Color(0.05, 0.04, 0.05))
	hint_panel.anchor_left = 1.0
	hint_panel.anchor_right = 1.0
	hint_panel.offset_left = -170
	hint_panel.offset_right = -6
	hint_panel.offset_top = 44
	hint_panel.offset_bottom = 120
	add_child(hint_panel)
	var hl := UiTheme.label("Move: WASD / Arrows / Stick\nRun: Shift   Interact: E / Space\nCamera: Z / C or right-drag\nZoom: mouse wheel\nBag: Tab    Journal: J\nPause: Esc", 9, Color(0.95, 0.92, 0.85))
	hint_panel.add_child(hl)
	hint_panel.visible = false
	Game.notify.connect(add_notification)
	refresh()


func show_controls_hint(seconds := 22.0) -> void:
	hint_panel.visible = true
	hint_panel.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(seconds)
	tw.tween_property(hint_panel, "modulate:a", 0.0, 1.5)
	tw.tween_callback(func(): hint_panel.visible = false)


func refresh() -> void:
	var v := Game.village_trust()
	mood_bar.value = v
	mood_label.text = "Lillevik: " + Game.village_mood_name()
	var idx := clampi(int(v / 17.0), 0, 5)
	mood_face.texture = Icons.get_texture(Game.STAGE_ICONS[idx])
	var obj := Game.tracked_objective()
	quest_panel.visible = obj != ""
	quest_label.text = obj
	quest_panel.reset_size()


func set_focus(f: Interactable) -> void:
	_focus = f
	if f == null:
		prompt_panel.visible = false
		marker.visible = false
		return
	prompt_label.text = "[E]  " + f.get_prompt()
	prompt_panel.visible = true
	prompt_panel.reset_size()
	prompt_panel.offset_left = -prompt_panel.size.x * 0.5
	prompt_panel.offset_right = prompt_panel.size.x * 0.5


func add_notification(text: String, icon_id: String) -> void:
	var p := UiTheme.panel(Color(0.98, 0.94, 0.85, 0.95))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	p.add_child(h)
	if Icons.has_icon(icon_id):
		h.add_child(UiTheme.icon(icon_id, 16))
	var l := UiTheme.label(text, 10)
	h.add_child(l)
	notif_box.add_child(p)
	p.modulate.a = 0.0
	var tw := p.create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.2)
	tw.tween_interval(3.2)
	tw.tween_property(p, "modulate:a", 0.0, 0.6)
	tw.tween_callback(p.queue_free)
	while notif_box.get_child_count() > 5:
		notif_box.get_child(0).queue_free()
		break
	refresh()


func add_bark(target: Node3D, text: String, seconds: float) -> void:
	for b in _barks:
		if b["target"] == target:
			(b["panel"] as Control).queue_free()
			_barks.erase(b)
			break
	var p := UiTheme.panel(Color(1.0, 0.99, 0.95, 0.97))
	var sb: StyleBoxFlat = UiTheme.box(Color(1.0, 0.99, 0.95, 0.97), UiTheme.BORDER, 2, 6, true, 4)
	p.add_theme_stylebox_override("panel", sb)
	var l := UiTheme.label(text, 10)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var font := l.get_theme_font("font")
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	l.custom_minimum_size = Vector2(minf(w + 4, 150), 0)
	p.add_child(l)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bark_layer.add_child(p)
	_barks.append({"target": target, "panel": p, "time": seconds})


func _project(p: Vector3) -> Variant:
	if world == null or world.rig == null or sub_viewport == null:
		return null
	var cam := world.rig.cam
	if cam.is_position_behind(p):
		return null
	var sp := cam.unproject_position(p)
	var sv := Vector2(sub_viewport.size)
	var cs := get_viewport_rect().size
	return sp * (cs / sv)


func _process(delta: float) -> void:
	_t += delta
	clock_label.text = Game.clock_text()
	day_label.text = "Day %d  %s" % [Game.day, Game.weekday_name().substr(0, 3)]
	time_icon.texture = Icons.get_texture("moon" if Game.is_night() else "sun")
	# barks
	for b in _barks.duplicate():
		b["time"] -= delta
		var panel: Control = b["panel"]
		var target: Node3D = b["target"]
		if b["time"] <= 0.0 or not is_instance_valid(target) or not target.is_visible_in_tree():
			panel.queue_free()
			_barks.erase(b)
			continue
		var h := 2.4
		if target is NPC:
			h = (target as NPC).model.height + 0.5
		elif target is Player:
			h = 3.0
		elif target is Animal:
			h = 1.6
		var sp: Variant = _project(target.global_position + Vector3(0, h, 0))
		if sp == null:
			panel.visible = false
			continue
		panel.visible = true
		panel.reset_size()
		var pos: Vector2 = sp
		panel.position = (pos - Vector2(panel.size.x * 0.5, panel.size.y + 2)).round()
		panel.modulate.a = clampf(b["time"] * 3.0, 0.0, 1.0)
	# focus marker
	if _focus != null and is_instance_valid(_focus):
		var fp: Variant = _project(_focus.focus_point() + Vector3(0, 0.6, 0))
		if fp != null:
			marker.visible = true
			var q: Vector2 = fp
			marker.position = (q - Vector2(4, 14 + (2.0 if fmod(_t, 0.8) < 0.4 else 0.0))).round()
		else:
			marker.visible = false
	else:
		marker.visible = false
