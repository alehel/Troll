class_name CraftMenu
extends Control
## Cooking at the cauldron in the troll's hollow.

signal closed

var panel: PanelContainer
var list: VBoxContainer
var info_label: Label
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
	panel.offset_left = -190
	panel.offset_right = 190
	panel.offset_top = -130
	panel.offset_bottom = 130
	add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	panel.add_child(vb)
	var th := HBoxContainer.new()
	th.add_theme_constant_override("separation", 6)
	vb.add_child(th)
	th.add_child(UiTheme.icon("mushroom_soup", 16))
	th.add_child(UiTheme.label("The Cauldron", UiTheme.BIG, UiTheme.INK, true))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 3)
	scroll.add_child(list)
	info_label = UiTheme.label("", 9, UiTheme.INK_SOFT)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(info_label)
	vb.add_child(UiTheme.label("E / Click: cook     Esc: close", 9, UiTheme.INK_SOFT))
	visible = false


func open() -> void:
	_open = true
	visible = true
	Sound.sfx("ui_open")
	_rebuild()


func close() -> void:
	if not _open:
		return
	_open = false
	visible = false
	Sound.sfx("ui_close")
	emit_signal("closed")


func _rebuild(focus_id := "") -> void:
	for c in list.get_children():
		c.queue_free()
	var first: Button = null
	var focus_btn: Button = null
	for rid in ItemDB.RECIPE_ORDER:
		if not Game.known_recipes.has(rid):
			continue
		var needs: Dictionary = ItemDB.RECIPES[rid]["needs"]
		var can := Game.has_items(needs)
		var b := Button.new()
		b.focus_mode = Control.FOCUS_ALL
		b.custom_minimum_size = Vector2(350, 26)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.icon = Icons.get_texture(rid)
		b.add_theme_constant_override("icon_max_width", 16)
		var parts: Array = []
		for k in needs.keys():
			parts.append("%s %d/%d" % [ItemDB.name_of(k), Game.count(k), int(needs[k])])
		b.text = "%s   (%s)" % [ItemDB.name_of(rid), ",  ".join(parts)]
		if not can:
			b.add_theme_color_override("font_color", Color(0.6, 0.5, 0.45))
			b.add_theme_color_override("font_focus_color", Color(0.6, 0.35, 0.3))
		b.pressed.connect(_cook.bind(rid))
		b.mouse_entered.connect(b.grab_focus)
		list.add_child(b)
		if first == null:
			first = b
		if rid == focus_id:
			focus_btn = b
	var unknown := ItemDB.RECIPE_ORDER.size() - Game.known_recipes.size()
	if Game.known_recipes.is_empty():
		info_label.text = "You don't know any recipes yet. Maybe Granny Ur can teach you something."
	elif unknown > 0:
		info_label.text = "%d more recipes to discover. Your troll friends know a few secrets..." % unknown
	else:
		info_label.text = "You know every recipe on the mountain. What a chef!"
	var f := focus_btn if focus_btn != null else first
	if f != null:
		f.call_deferred("grab_focus")


func _cook(rid: String) -> void:
	var needs: Dictionary = ItemDB.RECIPES[rid]["needs"]
	if not Game.has_items(needs):
		Sound.sfx("error")
		info_label.text = "You need more ingredients for %s." % ItemDB.name_of(rid)
		return
	Game.take_items(needs)
	Game.add_item(rid, 1, true)
	Game.emit_signal("notify", "Cooked " + ItemDB.name_of(rid) + "!", rid)
	Game.set_flag("crafted_" + rid)
	Game.inc("crafted")
	Sound.sfx("cook")
	_rebuild(rid)


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("cancel") or event.is_action_pressed("pause") or event.is_action_pressed("inventory"):
		get_viewport().set_input_as_handled()
		close()
	elif event is InputEventKey and event.is_action_pressed("interact") and not event.is_action_pressed("ui_accept"):
		var f := get_viewport().gui_get_focus_owner()
		if f is Button and list.is_ancestor_of(f):
			get_viewport().set_input_as_handled()
			(f as Button).emit_signal("pressed")
