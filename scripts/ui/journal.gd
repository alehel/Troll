class_name Journal
extends Control
## Tasks, friendships, village mood and recipes.

signal closed

const TABS := ["Tasks", "Friends", "Village", "Recipes"]

var panel: PanelContainer
var tab_buttons: Array = []
var content: VBoxContainer
var scroll: ScrollContainer
var tab := 0
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
	panel.offset_left = -230
	panel.offset_right = 230
	panel.offset_top = -150
	panel.offset_bottom = 150
	add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	panel.add_child(vb)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 4)
	vb.add_child(top)
	top.add_child(UiTheme.icon("book", 16))
	top.add_child(UiTheme.label("Journal", UiTheme.BIG, UiTheme.INK, true))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	for i in range(TABS.size()):
		var b := UiTheme.button(TABS[i])
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_set_tab.bind(i))
		top.add_child(b)
		tab_buttons.append(b)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 5)
	scroll.add_child(content)
	vb.add_child(UiTheme.label("Q / E: switch page     Up / Down: scroll     J / Esc: close", 9, UiTheme.INK_SOFT))
	visible = false


func open(start_tab := 0) -> void:
	_open = true
	visible = true
	Sound.sfx("ui_open")
	_set_tab(start_tab)


func close() -> void:
	if not _open:
		return
	_open = false
	visible = false
	Sound.sfx("ui_close")
	emit_signal("closed")


func _set_tab(i: int) -> void:
	tab = wrapi(i, 0, TABS.size())
	for k in range(tab_buttons.size()):
		(tab_buttons[k] as Button).button_pressed = k == tab
	for c in content.get_children():
		c.queue_free()
	scroll.scroll_vertical = 0
	match tab:
		0:
			_build_tasks()
		1:
			_build_friends()
		2:
			_build_village()
		3:
			_build_recipes()


func _section(text: String) -> void:
	var l := UiTheme.label(text, 11, UiTheme.ACCENT.darkened(0.2), true)
	content.add_child(l)


func _wrap(text: String, size := 10, color := UiTheme.INK) -> Label:
	var l := UiTheme.label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(420, 0)
	content.add_child(l)
	return l


func _build_tasks() -> void:
	var active := Game.active_quests()
	if active.is_empty():
		_wrap("No tasks right now. Talk to your friends, or simply enjoy the mountain air.", 10, UiTheme.INK_SOFT)
	for qid in active:
		var q := QuestDB.get_quest(qid)
		var star := "* " if q.get("main", false) else "- "
		content.add_child(UiTheme.label(star + q.get("title", qid), 11, UiTheme.INK, true))
		_wrap("    " + Game.current_step(qid).get("text", ""), 10)
		_wrap("    " + q.get("desc", ""), 9, UiTheme.INK_SOFT)
	var open_req: Array = []
	for r in Game.requests:
		if not r["done"]:
			open_req.append(r)
	if not open_req.is_empty():
		_section("Today's favours")
		for r in open_req:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 4)
			content.add_child(row)
			row.add_child(UiTheme.icon(r["item"], 12))
			row.add_child(UiTheme.label("%s  (you have %d)" % [Game.request_text(r), Game.count(r["item"])], 10))
	var done: Array = []
	for qid in QuestDB.ORDER:
		if Game.is_done(qid):
			done.append(QuestDB.get_quest(qid).get("title", qid))
	if not done.is_empty():
		_section("Completed")
		_wrap(", ".join(done), 9, UiTheme.INK_SOFT)


func _hearts_row(n: int) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 0)
	for i in range(10):
		h.add_child(UiTheme.icon("heart" if i < n else "heart_empty", 10))
	return h


func _build_friends() -> void:
	_section("Trolls of Trollfjell")
	for id in NpcDB.trolls():
		_friend_row(id)
	_section("People of Lillevik")
	for id in NpcDB.humans():
		_friend_row(id)


func _friend_row(id: String) -> void:
	var n := NpcDB.get_npc(id)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	content.add_child(row)
	var human := NpcDB.is_human(id)
	var st := Game.trust_stage(id) if human else -1
	row.add_child(UiTheme.icon(Game.STAGE_ICONS[st] if human else "heart", 16))
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 0)
	info.custom_minimum_size = Vector2(170, 0)
	row.add_child(info)
	info.add_child(UiTheme.label(n.get("name", id), 10, UiTheme.INK, true))
	info.add_child(UiTheme.label(n.get("title", ""), 8, UiTheme.INK_SOFT))
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 1)
	row.add_child(right)
	right.add_child(_hearts_row(Game.hearts(id)))
	var extra := ""
	if human:
		extra = "Feels: " + Game.STAGE_NAMES[st]
	if Game.hearts(id) >= 3:
		var loves: Array = n.get("loves", [])
		var names: Array = []
		for it in loves:
			names.append(ItemDB.name_of(it))
		extra += ("   " if extra != "" else "") + "Loves: " + ", ".join(names)
	else:
		extra += ("   " if extra != "" else "") + "Loves: ???"
	var el := UiTheme.label(extra, 8, UiTheme.INK_SOFT)
	el.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	el.custom_minimum_size = Vector2(240, 0)
	right.add_child(el)


func _build_village() -> void:
	var v := Game.village_trust()
	_section("Lillevik's feelings about trolls")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	content.add_child(row)
	row.add_child(UiTheme.icon(Game.STAGE_ICONS[clampi(int(v / 17.0), 0, 5)], 24))
	var pb := ProgressBar.new()
	pb.max_value = 100
	pb.value = v
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(200, 10)
	pb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(pb)
	row.add_child(UiTheme.label(Game.village_mood_name(), 11, UiTheme.INK, true))
	_wrap("The humans of Lillevik are frightened of trolls. You have no idea why. You're lovely!", 10)
	_section("Ways to show you're friendly")
	_wrap("- Leave gifts in the baskets by the villagers' doors. They find them in the morning.", 10)
	_wrap("- Tidy up litter around the village. Someone always notices.", 10)
	_wrap("- Once a villager stops running away, give gifts in person and have a chat each day.", 10)
	_wrap("- Everyone has favourite things. Watch their reactions and remember what they love.", 10)
	_wrap("- Help with problems only a big, strong troll could solve.", 10)
	_section("How the villagers feel")
	for i in range(Game.STAGE_NAMES.size()):
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 4)
		content.add_child(h)
		h.add_child(UiTheme.icon(Game.STAGE_ICONS[i], 12))
		var desc: String = ["runs away screaming", "keeps their distance, trembling", "will talk, nervously", "is curious about you", "is happy to see you", "is a true friend"][i]
		h.add_child(UiTheme.label("%s - %s" % [Game.STAGE_NAMES[i], desc], 9))


func _build_recipes() -> void:
	_section("Recipes for your cauldron")
	if Game.known_recipes.is_empty():
		_wrap("You don't know any recipes yet. Granny Ur knows a thing or two about jam...", 10, UiTheme.INK_SOFT)
	for rid in ItemDB.RECIPE_ORDER:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		content.add_child(row)
		if Game.known_recipes.has(rid):
			row.add_child(UiTheme.icon(rid, 16))
			row.add_child(UiTheme.label(ItemDB.name_of(rid), 10, UiTheme.INK, true))
			var parts: Array = []
			var needs: Dictionary = ItemDB.RECIPES[rid]["needs"]
			for k in needs.keys():
				parts.append("%d %s" % [needs[k], ItemDB.plural_of(k) if int(needs[k]) > 1 else ItemDB.name_of(k)])
			row.add_child(UiTheme.label("= " + " + ".join(parts), 9, UiTheme.INK_SOFT))
		else:
			row.add_child(UiTheme.icon("heart_empty", 16))
			row.add_child(UiTheme.label("??? (learn this from a friend)", 9, UiTheme.INK_SOFT))


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("ui_tab_next") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_set_tab(tab + 1)
	elif event.is_action_pressed("ui_tab_prev"):
		get_viewport().set_input_as_handled()
		_set_tab(tab - 1)
	elif event.is_action_pressed("cancel") or event.is_action_pressed("pause") or event.is_action_pressed("journal"):
		get_viewport().set_input_as_handled()
		close()
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_back"):
		scroll.scroll_vertical += 30
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("move_forward"):
		scroll.scroll_vertical -= 30
