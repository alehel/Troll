class_name SettingsPanel
extends PanelContainer
## Volume, pixel size, dithering, text speed and fullscreen options.

signal closed

var _first: Control


func _ready() -> void:
	add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PAPER, UiTheme.BORDER, 2, 3, true, 10))
	custom_minimum_size = Vector2(280, 0)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	add_child(vb)
	vb.add_child(UiTheme.label("Settings", UiTheme.BIG, UiTheme.INK, true))
	_first = _slider(vb, "Music volume", "music")
	_slider(vb, "Sound volume", "sfx")
	_option(vb, "Pixel size", "render_scale", [["Chunky", 0.5], ["Cosy", 0.75], ["Fine", 1.0]])
	_option(vb, "Text speed", "text_speed", [["Slow", 0.6], ["Normal", 1.0], ["Fast", 1.8]])
	_toggle(vb, "Retro dithering", "dither")
	_toggle(vb, "Fullscreen (F11)", "fullscreen")
	var back := UiTheme.button("Back")
	back.pressed.connect(_close)
	vb.add_child(back)


func focus_first() -> void:
	if _first:
		_first.grab_focus()


func _row(vb: VBoxContainer, text: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	var l := UiTheme.label(text, 10)
	l.custom_minimum_size = Vector2(110, 0)
	h.add_child(l)
	vb.add_child(h)
	return h


func _slider(vb: VBoxContainer, text: String, key: String) -> HSlider:
	var h := _row(vb, text)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = float(Game.settings[key])
	s.custom_minimum_size = Vector2(140, 12)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.focus_mode = Control.FOCUS_ALL
	s.value_changed.connect(func(v: float):
		Game.settings[key] = v
		Game.apply_settings()
		Game.save_settings())
	h.add_child(s)
	return s


func _option(vb: VBoxContainer, text: String, key: String, opts: Array) -> void:
	var h := _row(vb, text)
	var group := ButtonGroup.new()
	for o in opts:
		var b := UiTheme.button(o[0])
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = absf(float(Game.settings[key]) - float(o[1])) < 0.01
		var val: float = o[1]
		b.pressed.connect(func():
			Game.settings[key] = val
			Game.apply_settings()
			Game.save_settings())
		h.add_child(b)


func _toggle(vb: VBoxContainer, text: String, key: String) -> void:
	var c := CheckButton.new()
	c.text = text
	c.button_pressed = bool(Game.settings[key])
	c.focus_mode = Control.FOCUS_ALL
	c.toggled.connect(func(on: bool):
		Game.settings[key] = on
		Game.apply_settings()
		Game.save_settings())
	vb.add_child(c)


func _close() -> void:
	Sound.sfx("ui_close")
	emit_signal("closed")
