class_name UIRoot
extends CanvasLayer
## Owns every UI screen and offers an awaitable API to the story.

var root: Control
var hud: Hud
var dialogue: DialogueBox
var items: ItemMenu
var journal: Journal
var craft: CraftMenu
var paper: Newspaper
var pause: PauseMenu
var title: TitleScreen
var fade: ColorRect
var card: Control
var card_title: Label
var card_sub: Label
var loading: Label
var world: World
var _card_wait := false

signal card_closed


func _ready() -> void:
	layer = 10
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiTheme.get_theme()
	add_child(root)
	hud = Hud.new()
	root.add_child(hud)
	dialogue = DialogueBox.new()
	root.add_child(dialogue)
	items = ItemMenu.new()
	root.add_child(items)
	journal = Journal.new()
	root.add_child(journal)
	craft = CraftMenu.new()
	root.add_child(craft)
	paper = Newspaper.new()
	root.add_child(paper)
	title = TitleScreen.new()
	root.add_child(title)
	title.visible = false
	pause = PauseMenu.new()
	root.add_child(pause)
	card = Control.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(card)
	fade = ColorRect.new()
	fade.color = Color(0.03, 0.03, 0.05, 1.0)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fade)
	var cv := VBoxContainer.new()
	cv.set_anchors_preset(Control.PRESET_CENTER)
	cv.anchor_left = 0.0
	cv.anchor_right = 1.0
	cv.anchor_top = 0.5
	cv.anchor_bottom = 0.5
	cv.offset_top = -50
	cv.add_theme_constant_override("separation", 8)
	card.add_child(cv)
	card_title = UiTheme.label("", 40, Color(0.98, 0.94, 0.82), true)
	card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_title.add_theme_color_override("font_outline_color", Color(0.2, 0.14, 0.1))
	card_title.add_theme_constant_override("outline_size", 8)
	cv.add_child(card_title)
	card_sub = UiTheme.label("", 13, Color(0.98, 0.94, 0.82))
	card_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_sub.add_theme_color_override("font_outline_color", Color(0.2, 0.14, 0.1))
	card_sub.add_theme_constant_override("outline_size", 5)
	cv.add_child(card_sub)
	card.visible = false
	# draw order: fades cover the world and menus, but the dialogue box and
	# the morning paper appear on top of a black screen
	fade.move_to_front()
	dialogue.move_to_front()
	paper.move_to_front()
	card.move_to_front()
	loading = UiTheme.label("Waking up the mountain...", 13, Color(0.95, 0.92, 0.85))
	loading.set_anchors_preset(Control.PRESET_CENTER)
	loading.anchor_left = 0.0
	loading.anchor_right = 1.0
	loading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(loading)
	hud.visible = false


func bind_world(w: World, sub_viewport: SubViewport) -> void:
	world = w
	hud.world = w
	hud.sub_viewport = sub_viewport
	w.bark_requested.connect(hud.add_bark)
	w.player.focus_changed.connect(hud.set_focus)
	Game.quest_changed.connect(func(_id): hud.refresh())
	Game.trust_changed.connect(func(_a, _b, _c): hud.refresh())
	Game.day_started.connect(func(_d): hud.refresh())


func hide_loading() -> void:
	loading.visible = false


# --------------------------------------------------------------------------
# awaitable helpers used by the story
# --------------------------------------------------------------------------
func say(speaker: String, text: String, voice: float, node: Node) -> void:
	await dialogue.say(speaker, text, voice, node)


func choose(options: Array) -> int:
	var r: int = await dialogue.choose(options)
	return r


func close_dialogue() -> void:
	dialogue.close()


func is_speaking(n: Node) -> bool:
	return dialogue.visible and dialogue.speaker_node == n and dialogue.speaker_node != null


func pick_item(title_text: String, filter: Callable) -> String:
	var was_dialogue := dialogue.visible
	dialogue.visible = false
	items.open(title_text, "pick", filter)
	var r: String = await items.picked
	if was_dialogue:
		dialogue.visible = true
	return r


func show_paper(p: Dictionary) -> void:
	await paper.show_paper(p)


func fade_out(t := 0.8) -> void:
	fade.visible = true
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, t)
	await tw.finished


func fade_in(t := 0.8) -> void:
	fade.visible = true
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 0.0, t)
	await tw.finished
	fade.visible = false


func title_card(t: String, sub: String) -> void:
	card_title.text = t
	card_sub.text = sub + "\n\n(press E)"
	card.visible = true
	card.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(card, "modulate:a", 1.0, 1.2)
	await tw.finished
	_card_wait = true
	await card_closed
	var tw2 := create_tween()
	tw2.tween_property(card, "modulate:a", 0.0, 0.8)
	await tw2.finished
	card.visible = false


func show_controls_hint() -> void:
	hud.show_controls_hint()


func open_craft() -> void:
	if world == null:
		return
	world.player.busy = true
	Game.time_running = false
	craft.open()
	await craft.closed
	world.player.busy = false
	Game.time_running = true


func open_inventory() -> void:
	world.player.busy = true
	Game.time_running = false
	items.open("Bag", "view")
	await items.picked
	world.player.busy = false
	Game.time_running = true


func open_journal(tab := 0) -> void:
	world.player.busy = true
	Game.time_running = false
	journal.open(tab)
	await journal.closed
	world.player.busy = false
	Game.time_running = true


func any_menu_open() -> bool:
	return items.visible or journal.visible or craft.visible or paper.visible or pause.visible or title.visible or dialogue.visible or card.visible


func _input(event: InputEvent) -> void:
	if _card_wait and (event.is_action_pressed("interact") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		_card_wait = false
		emit_signal("card_closed")
