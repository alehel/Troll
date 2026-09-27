class_name PauseMenu
extends Control
## Pause screen: resume, journal, settings, save and return to title.

signal resume_requested
signal journal_requested
signal quit_requested

var menu: PanelContainer
var settings: SettingsPanel
var status: Label
var _buttons: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.04, 0.08, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	center.add_child(hb)
	menu = UiTheme.panel()
	hb.add_child(menu)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	vb.custom_minimum_size = Vector2(150, 0)
	menu.add_child(vb)
	vb.add_child(UiTheme.label("Paused", UiTheme.BIG, UiTheme.INK, true))
	for pair in [["Resume", _resume], ["Journal", _journal], ["Settings", _settings], ["Save game", _save], ["Save & quit to title", _quit]]:
		var b := UiTheme.button(pair[0])
		b.pressed.connect(pair[1])
		b.mouse_entered.connect(b.grab_focus)
		vb.add_child(b)
		_buttons.append(b)
	status = UiTheme.label("", 9, UiTheme.INK_SOFT)
	vb.add_child(status)
	settings = SettingsPanel.new()
	settings.visible = false
	settings.closed.connect(func():
		settings.visible = false
		(_buttons[2] as Button).grab_focus())
	hb.add_child(settings)
	visible = false


func open() -> void:
	visible = true
	settings.visible = false
	status.text = "Day %d, %s" % [Game.day, Game.clock_text()]
	Sound.sfx("ui_open")
	(_buttons[0] as Button).call_deferred("grab_focus")


func close() -> void:
	visible = false


func _resume() -> void:
	emit_signal("resume_requested")


func _journal() -> void:
	emit_signal("journal_requested")


func _settings() -> void:
	settings.visible = true
	settings.focus_first()


func _save() -> void:
	if Game.save_game():
		status.text = "Saved!"
		Sound.sfx("ui_select")


func _quit() -> void:
	emit_signal("quit_requested")


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		if settings.visible:
			settings.visible = false
			(_buttons[2] as Button).grab_focus()
		else:
			_resume()
