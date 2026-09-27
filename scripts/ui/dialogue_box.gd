class_name DialogueBox
extends Control
## Animal Crossing style dialogue box with typewriter text, voice blips and
## a choice list.

signal advanced
signal chosen(index: int)

var panel: PanelContainer
var name_tag: PanelContainer
var name_label: Label
var text_label: RichTextLabel
var arrow: Label
var choices_panel: PanelContainer
var choices_box: VBoxContainer
var speaker_node: Node = null
var waiting := false
var choosing := false
var _typing := false
var _chars := 0.0
var _total := 0
var _voice := 1.0
var _last_blip := 0
var _t := 0.0
var _buttons: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel = UiTheme.panel()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -236
	panel.offset_right = 236
	panel.offset_top = -78
	panel.offset_bottom = -8
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb: StyleBoxFlat = UiTheme.box(UiTheme.PAPER, UiTheme.BORDER, 2, 6, true, 10)
	sb.content_margin_top = 12
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	panel.gui_input.connect(_on_panel_input)
	text_label = RichTextLabel.new()
	text_label.bbcode_enabled = false
	text_label.fit_content = false
	text_label.scroll_active = false
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_label.add_theme_font_size_override("normal_font_size", 11)
	panel.add_child(text_label)
	name_tag = UiTheme.panel(UiTheme.ACCENT, UiTheme.BORDER)
	var nsb: StyleBoxFlat = UiTheme.box(UiTheme.ACCENT, UiTheme.BORDER, 2, 4, true, 3)
	nsb.content_margin_left = 8
	nsb.content_margin_right = 8
	name_tag.add_theme_stylebox_override("panel", nsb)
	name_tag.anchor_left = 0.5
	name_tag.anchor_right = 0.5
	name_tag.anchor_top = 1.0
	name_tag.anchor_bottom = 1.0
	name_tag.offset_left = -226
	name_tag.offset_right = -226
	name_tag.offset_top = -90
	name_tag.offset_bottom = -72
	name_tag.grow_horizontal = Control.GROW_DIRECTION_END
	add_child(name_tag)
	name_label = UiTheme.label("", 11, Color(1, 0.97, 0.9), true)
	name_tag.add_child(name_label)
	arrow = UiTheme.label("v", 11, UiTheme.ACCENT, true)
	arrow.anchor_left = 0.5
	arrow.anchor_right = 0.5
	arrow.anchor_top = 1.0
	arrow.anchor_bottom = 1.0
	arrow.offset_left = 216
	arrow.offset_top = -26
	add_child(arrow)
	choices_panel = UiTheme.panel()
	choices_panel.anchor_left = 0.5
	choices_panel.anchor_right = 0.5
	choices_panel.anchor_top = 1.0
	choices_panel.anchor_bottom = 1.0
	choices_panel.offset_left = 110
	choices_panel.offset_right = 236
	choices_panel.offset_bottom = -86
	choices_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(choices_panel)
	choices_box = VBoxContainer.new()
	choices_box.add_theme_constant_override("separation", 3)
	choices_panel.add_child(choices_box)
	choices_panel.visible = false
	visible = false


func is_open() -> bool:
	return visible


func say(speaker: String, text: String, voice: float, node: Node) -> void:
	visible = true
	panel.visible = true
	choices_panel.visible = false
	name_tag.visible = speaker != ""
	name_label.text = speaker
	text_label.add_theme_color_override("default_color", UiTheme.INK if speaker != "" else UiTheme.INK_SOFT)
	text_label.text = text
	_total = text.length()
	_chars = 0.0
	_last_blip = 0
	text_label.visible_characters = 0
	_typing = true
	_voice = voice
	speaker_node = node if speaker != "" else null
	arrow.visible = false
	waiting = true
	await advanced


func _process(delta: float) -> void:
	_t += delta
	if not visible:
		return
	if _typing:
		var spd: float = 48.0 * float(Game.settings.get("text_speed", 1.0))
		_chars += delta * spd
		var c := int(_chars)
		text_label.visible_characters = c
		if c - _last_blip >= 2 and name_tag.visible:
			_last_blip = c
			var ch := text_label.text.substr(clampi(c - 1, 0, _total - 1), 1)
			if ch != " " and ch != "." and ch != ",":
				Sound.voice(_voice)
		if c >= _total:
			_finish_typing()
	elif waiting:
		arrow.visible = true
		arrow.offset_top = -26 + (2.0 if fmod(_t, 0.8) < 0.4 else 0.0)


func _finish_typing() -> void:
	_typing = false
	text_label.visible_characters = -1


func _advance() -> void:
	if _typing:
		_finish_typing()
		return
	if waiting:
		waiting = false
		arrow.visible = false
		speaker_node = null
		emit_signal("advanced")


func _on_panel_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if waiting and not choosing:
			_advance()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if choosing:
		if event.is_action_pressed("cancel") or event.is_action_pressed("pause"):
			get_viewport().set_input_as_handled()
			_pick(_buttons.size() - 1)
		elif event is InputEventKey and event.is_action_pressed("interact") and not event.is_action_pressed("ui_accept"):
			var f := get_viewport().gui_get_focus_owner()
			var i := _buttons.find(f)
			if i >= 0:
				get_viewport().set_input_as_handled()
				_pick(i)
		return
	if waiting and (event.is_action_pressed("interact") or event.is_action_pressed("cancel")):
		get_viewport().set_input_as_handled()
		_advance()


func choose(options: Array) -> int:
	visible = true
	for c in choices_box.get_children():
		c.queue_free()
	_buttons.clear()
	for i in range(options.size()):
		var b := UiTheme.button(String(options[i]))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_pick.bind(i))
		b.mouse_entered.connect(b.grab_focus)
		b.focus_entered.connect(func(): Sound.sfx("ui_move", 1.0, -10.0))
		choices_box.add_child(b)
		_buttons.append(b)
	choices_panel.visible = true
	choices_panel.reset_size()
	choosing = true
	await get_tree().process_frame
	if not _buttons.is_empty():
		(_buttons[0] as Button).grab_focus()
	var r: int = await chosen
	return r


func _pick(i: int) -> void:
	if not choosing:
		return
	choosing = false
	choices_panel.visible = false
	Sound.sfx("ui_select")
	emit_signal("chosen", i)


func close() -> void:
	visible = false
	waiting = false
	choosing = false
	speaker_node = null
