class_name TitleScreen
extends Control
## Title screen with a slowly orbiting view of the valley behind it.

signal new_game_requested(player_name: String)
signal continue_requested

var menu_box: VBoxContainer
var name_panel: PanelContainer
var name_edit: LineEdit
var settings: SettingsPanel
var continue_btn: Button
var _buttons: Array = []
var _t := 0.0
var title_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var grad := TextureRect.new()
	var g := GradientTexture2D.new()
	var gr := Gradient.new()
	gr.set_color(0, Color(0.05, 0.05, 0.1, 0.0))
	gr.set_color(1, Color(0.05, 0.05, 0.1, 0.55))
	g.gradient = gr
	g.fill_from = Vector2(0.5, 0.2)
	g.fill_to = Vector2(0.5, 1.0)
	grad.texture = g
	grad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grad.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	grad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(grad)
	title_label = UiTheme.label("TROLL", 64, Color(0.98, 0.94, 0.82), true)
	title_label.add_theme_color_override("font_outline_color", Color(0.25, 0.17, 0.13))
	title_label.add_theme_constant_override("outline_size", 10)
	title_label.add_theme_color_override("font_shadow_color", Color(0.1, 0.06, 0.05, 0.6))
	title_label.add_theme_constant_override("shadow_offset_x", 3)
	title_label.add_theme_constant_override("shadow_offset_y", 4)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.anchor_left = 0.0
	title_label.anchor_right = 1.0
	title_label.offset_top = 36
	add_child(title_label)
	var sub := UiTheme.label("a cosy tale from the Norwegian mountains", 13, Color(0.98, 0.94, 0.82))
	sub.add_theme_color_override("font_outline_color", Color(0.25, 0.17, 0.13))
	sub.add_theme_constant_override("outline_size", 5)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.anchor_right = 1.0
	sub.offset_top = 112
	add_child(sub)
	var panel := UiTheme.panel(Color(0.98, 0.94, 0.85, 0.94))
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -80
	panel.offset_right = 80
	panel.offset_bottom = -30
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(panel)
	menu_box = VBoxContainer.new()
	menu_box.add_theme_constant_override("separation", 5)
	panel.add_child(menu_box)
	continue_btn = _add_button("Continue", func(): emit_signal("continue_requested"))
	_add_button("New game", _show_name)
	_add_button("Settings", _show_settings)
	_add_button("Quit", func(): get_tree().quit())
	# name entry
	name_panel = UiTheme.panel()
	name_panel.anchor_left = 0.5
	name_panel.anchor_right = 0.5
	name_panel.anchor_top = 0.5
	name_panel.anchor_bottom = 0.5
	name_panel.offset_left = -130
	name_panel.offset_right = 130
	name_panel.offset_top = -30
	name_panel.offset_bottom = 60
	add_child(name_panel)
	var nv := VBoxContainer.new()
	nv.add_theme_constant_override("separation", 6)
	name_panel.add_child(nv)
	nv.add_child(UiTheme.label("What is your troll's name?", 11, UiTheme.INK, true))
	name_edit = LineEdit.new()
	name_edit.text = "Mose"
	name_edit.max_length = 14
	name_edit.text_submitted.connect(func(_t): _start())
	nv.add_child(name_edit)
	var start := UiTheme.button("Wake up!")
	start.pressed.connect(_start)
	nv.add_child(start)
	var back := UiTheme.button("Back")
	back.pressed.connect(_hide_name)
	nv.add_child(back)
	name_panel.visible = false
	settings = SettingsPanel.new()
	settings.anchor_left = 0.5
	settings.anchor_right = 0.5
	settings.anchor_top = 0.5
	settings.anchor_bottom = 0.5
	settings.offset_left = -140
	settings.offset_top = -80
	settings.visible = false
	settings.closed.connect(func():
		settings.visible = false
		panel.visible = true
		(_buttons[2] as Button).grab_focus())
	add_child(settings)
	var credit := UiTheme.label("Made with Godot. Font: Pixelify Sans (OFL).", 8, Color(0.95, 0.92, 0.85, 0.8))
	credit.anchor_top = 1.0
	credit.anchor_bottom = 1.0
	credit.offset_left = 6
	credit.offset_top = -14
	add_child(credit)


func _add_button(text: String, fn: Callable) -> Button:
	var b := UiTheme.button(text)
	b.pressed.connect(fn)
	b.pressed.connect(func(): Sound.sfx("ui_select"))
	b.mouse_entered.connect(b.grab_focus)
	menu_box.add_child(b)
	_buttons.append(b)
	return b


func open() -> void:
	visible = true
	name_panel.visible = false
	settings.visible = false
	menu_box.get_parent().visible = true
	continue_btn.visible = Game.has_save()
	var f: Button = continue_btn if continue_btn.visible else _buttons[1]
	f.call_deferred("grab_focus")


func _show_name() -> void:
	menu_box.get_parent().visible = false
	name_panel.visible = true
	name_edit.call_deferred("grab_focus")
	name_edit.call_deferred("select_all")


func _hide_name() -> void:
	name_panel.visible = false
	menu_box.get_parent().visible = true
	(_buttons[1] as Button).grab_focus()


func _show_settings() -> void:
	menu_box.get_parent().visible = false
	settings.visible = true
	settings.focus_first()


func _start() -> void:
	var n := name_edit.text.strip_edges()
	if n == "":
		n = "Mose"
	emit_signal("new_game_requested", n)


func _process(delta: float) -> void:
	_t += delta
	if title_label:
		title_label.offset_top = 36 + round(sin(_t * 1.2) * 3.0)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause") or (event.is_action_pressed("cancel") and not name_edit.has_focus()):
		if name_panel.visible:
			get_viewport().set_input_as_handled()
			_hide_name()
		elif settings.visible:
			get_viewport().set_input_as_handled()
			settings.emit_signal("closed")
