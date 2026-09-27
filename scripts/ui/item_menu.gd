class_name ItemMenu
extends Control
## The troll's bag. Used both for browsing and for choosing a gift.

signal picked(item: String)

var panel: PanelContainer
var title_label: Label
var grid: GridContainer
var detail_icon: TextureRect
var detail_name: Label
var detail_desc: Label
var detail_extra: Label
var hint_label: Label
var mode := "view"
var filter: Callable
var _selected := ""
var _open := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.04, 0.06, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	panel = UiTheme.panel()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -200
	panel.offset_right = 200
	panel.offset_top = -120
	panel.offset_bottom = 120
	add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	panel.add_child(vb)
	var th := HBoxContainer.new()
	th.add_theme_constant_override("separation", 6)
	vb.add_child(th)
	th.add_child(UiTheme.icon("bag", 16))
	title_label = UiTheme.label("Bag", UiTheme.BIG, UiTheme.INK, true)
	th.add_child(title_label)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(hb)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(222, 170)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hb.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
	scroll.add_child(grid)
	var detail := UiTheme.panel(UiTheme.PAPER_DARK)
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(detail)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 4)
	detail.add_child(dv)
	detail_icon = UiTheme.icon("bag", 32)
	detail_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dv.add_child(detail_icon)
	detail_name = UiTheme.label("", 11, UiTheme.INK, true)
	detail_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dv.add_child(detail_name)
	detail_desc = UiTheme.label("", 9, UiTheme.INK_SOFT)
	detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_desc.custom_minimum_size = Vector2(140, 0)
	dv.add_child(detail_desc)
	detail_extra = UiTheme.label("", 9, UiTheme.GREEN.darkened(0.2))
	detail_extra.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_extra.custom_minimum_size = Vector2(140, 0)
	dv.add_child(detail_extra)
	hint_label = UiTheme.label("", 9, UiTheme.INK_SOFT)
	vb.add_child(hint_label)
	visible = false


func open(title: String, m: String, f: Callable = Callable()) -> void:
	mode = m
	filter = f
	title_label.text = title
	hint_label.text = "E / Click: choose     Esc: never mind" if mode == "pick" else "Tab / Esc: close"
	_rebuild()
	visible = true
	_open = true
	Sound.sfx("ui_open")


func close(result := "") -> void:
	if not _open:
		return
	_open = false
	visible = false
	Sound.sfx("ui_close")
	emit_signal("picked", result)


func _rebuild() -> void:
	for c in grid.get_children():
		c.queue_free()
	var ids := Game.sorted_inventory()
	var first: Button = null
	for id in ids:
		var ok := true
		if mode == "pick" and filter.is_valid():
			ok = filter.call(id)
		var b := Button.new()
		b.custom_minimum_size = Vector2(34, 34)
		b.focus_mode = Control.FOCUS_ALL
		b.icon = Icons.get_texture(id)
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.disabled = not ok
		b.tooltip_text = ItemDB.name_of(id)
		b.add_theme_constant_override("icon_max_width", 24)
		var cnt := UiTheme.label(str(Game.count(id)), 9, UiTheme.INK, true)
		cnt.add_theme_color_override("font_outline_color", Color(1, 0.98, 0.92))
		cnt.add_theme_constant_override("outline_size", 3)
		cnt.anchor_left = 1.0
		cnt.anchor_right = 1.0
		cnt.anchor_top = 1.0
		cnt.anchor_bottom = 1.0
		cnt.offset_left = -12
		cnt.offset_top = -13
		b.add_child(cnt)
		b.focus_entered.connect(_show_detail.bind(id))
		b.mouse_entered.connect(b.grab_focus)
		b.pressed.connect(_on_pressed.bind(id))
		grid.add_child(b)
		if first == null and ok:
			first = b
	if ids.is_empty():
		_show_detail("")
		detail_name.text = "Empty"
		detail_desc.text = "Your bag is empty. Berries, flowers and treasures are waiting on the mountain!"
	elif first != null:
		first.call_deferred("grab_focus")
		_show_detail(Game.sorted_inventory()[0])


func _show_detail(id: String) -> void:
	_selected = id
	if id == "":
		detail_icon.texture = Icons.get_texture("bag")
		detail_name.text = ""
		detail_desc.text = ""
		detail_extra.text = ""
		return
	Sound.sfx("ui_move", 1.2, -12.0)
	detail_icon.texture = Icons.get_texture(id)
	detail_name.text = ItemDB.name_of(id)
	detail_desc.text = ItemDB.desc_of(id)
	var cat := ItemDB.category(id)
	detail_extra.text = {"forage": "Found in the wild", "crafted": "Homemade", "treat": "A gift from a friend", "quest": "Important item"}.get(cat, "")


func _on_pressed(id: String) -> void:
	if mode == "pick":
		close(id)


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("cancel") or event.is_action_pressed("pause") or (mode == "view" and event.is_action_pressed("inventory")):
		get_viewport().set_input_as_handled()
		close("")
	elif event.is_action_pressed("interact") and mode == "pick" and _selected != "":
		get_viewport().set_input_as_handled()
		if not filter.is_valid() or filter.call(_selected):
			close(_selected)
