extends Node
## Entry point. Renders the 3D world into a low resolution SubViewport that is
## scaled up with nearest filtering for a crisp pixel-art look, and runs the
## title screen / game flow.

const POST := preload("res://shaders/post.gdshader")

var display: TextureRect
var sub: SubViewport
var world: World
var ui: UIRoot
var story: Story
var state := "loading"
var _orbit := 0.0
var _post_mat: ShaderMaterial


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	sub = SubViewport.new()
	sub.name = "WorldViewport"
	sub.size = Vector2i(480, 270)
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sub.msaa_3d = Viewport.MSAA_DISABLED
	sub.audio_listener_enable_3d = true
	add_child(sub)
	display = TextureRect.new()
	display.name = "Display"
	display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_SCALE
	display.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	display.texture = sub.get_texture()
	_post_mat = ShaderMaterial.new()
	_post_mat.shader = POST
	display.material = _post_mat
	add_child(display)
	ui = UIRoot.new()
	ui.name = "UI"
	add_child(ui)
	get_tree().root.size_changed.connect(_update_viewport_size)
	Game.settings_changed.connect(_on_settings_changed)
	_update_viewport_size()
	await get_tree().process_frame
	await get_tree().process_frame
	_build_world()


func _build_world() -> void:
	var t0 := Time.get_ticks_msec()
	world = World.new()
	world.name = "World"
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	sub.add_child(world)
	world.build()
	story = Story.new()
	story.name = "Story"
	world.add_child(story)
	story.setup(world, ui)
	world.story = story
	world.ui = ui
	ui.bind_world(world, sub)
	ui.title.new_game_requested.connect(_start_new)
	ui.title.continue_requested.connect(_continue)
	ui.pause.resume_requested.connect(_resume)
	ui.pause.journal_requested.connect(_pause_journal)
	ui.pause.quit_requested.connect(_quit_to_title)
	Game.quest_completed.connect(_on_quest_completed)
	print("World built in %d ms" % (Time.get_ticks_msec() - t0))
	_on_settings_changed()
	ui.hide_loading()
	for test in ["autotest", "walktest", "tour", "trailer"]:
		if OS.get_cmdline_user_args().has("--" + test):
			var scr: GDScript = load("res://tests/%s.gd" % test)
			if scr == null or not scr.can_instantiate():
				push_error("Could not load test " + test)
				get_tree().quit(2)
				return
			var t: Node = scr.new()
			add_child(t)
			t.run(self)
			return
	show_title()


func _update_viewport_size() -> void:
	var win := Vector2(get_window().size)
	if win.x < 2 or win.y < 2:
		return
	var target: float = {0.5: 180.0, 0.75: 270.0, 1.0: 360.0}.get(snappedf(float(Game.settings.get("render_scale", 0.75)), 0.25), 270.0)
	var factor := maxf(1.0, round(win.y / target))
	var s := (win / factor).floor()
	sub.size = Vector2i(maxi(int(s.x), 64), maxi(int(s.y), 36))


func _on_settings_changed() -> void:
	_update_viewport_size()
	if _post_mat:
		_post_mat.set_shader_parameter("dither", bool(Game.settings.get("dither", true)))
	Sound.apply_volumes()


# --------------------------------------------------------------------------
# flow
# --------------------------------------------------------------------------
func show_title() -> void:
	state = "title"
	get_tree().paused = false
	Game.playing = false
	Game.time_running = false
	Game.new_game()
	Game.minutes = 18.2 * 60.0
	world.start_day()
	world.place_player_at_home()
	ui.hud.visible = false
	ui.dialogue.close()
	ui.title.open()
	Sound.play_music("title")
	ui.fade.color.a = 1.0
	ui.fade_in(1.5)


func _process(delta: float) -> void:
	if state == "title" and world:
		_orbit += delta * 0.03
		var c := Vector3(-5, 12, 10)
		var pos := c + Vector3(sin(_orbit) * 95.0, 38.0, cos(_orbit) * 95.0)
		world.rig.override_pose = [pos, c]
		world.rig.cam.global_position = pos
		world.rig.cam.look_at(c)


func _start_new(pname: String) -> void:
	if state != "title":
		return
	state = "starting"
	await ui.fade_out(1.0)
	ui.title.visible = false
	Game.new_game()
	Game.player_name = pname
	Game.playing = true
	world.start_day()
	world.place_player_at_home()
	world.rig.override_pose = []
	world.rig.snap()
	ui.hud.visible = true
	ui.hud.refresh()
	Sound.update_music()
	state = "playing"
	story.intro()


func _continue() -> void:
	if state != "title":
		return
	state = "starting"
	await ui.fade_out(1.0)
	ui.title.visible = false
	if not Game.load_game():
		Game.new_game()
	Game.playing = true
	world.start_day()
	if Game.has_player_pos:
		world.player.global_position = Game.player_pos
		world.player.facing = Vector3(sin(Game.player_yaw), 0, cos(Game.player_yaw))
		world.player.model.rotation.y = Game.player_yaw
		world.rig.yaw_target = Game.player_yaw + PI
	else:
		world.place_player_at_home()
	world.rig.override_pose = []
	world.rig.snap()
	ui.hud.visible = true
	ui.hud.refresh()
	Game.check_quests()
	Sound.update_music()
	state = "playing"
	Game.time_running = true
	await ui.fade_in(1.0)
	world.show_bark(world.player, "Back on the mountain!", 2.5)


func _store_player() -> void:
	Game.player_pos = world.player.global_position
	Game.player_yaw = world.player.model.rotation.y
	Game.has_player_pos = true


func _pause() -> void:
	state = "paused"
	Game.time_running = false
	_store_player()
	get_tree().paused = true
	ui.pause.open()


func _resume() -> void:
	ui.pause.close()
	get_tree().paused = false
	state = "playing"
	Game.time_running = true


func _pause_journal() -> void:
	ui.pause.close()
	ui.journal.open()
	await ui.journal.closed
	ui.pause.open()


func _quit_to_title() -> void:
	_store_player()
	Game.save_game()
	ui.pause.close()
	get_tree().paused = false
	await ui.fade_out(0.8)
	show_title()


func _on_quest_completed(_id: String) -> void:
	ui.hud.refresh()


func _unhandled_input(event: InputEvent) -> void:
	if state == "playing" and world and not story.busy and not world.player.busy and not ui.any_menu_open():
		if event.is_action_pressed("pause"):
			get_viewport().set_input_as_handled()
			_pause()
			return
		if event.is_action_pressed("inventory"):
			get_viewport().set_input_as_handled()
			ui.open_inventory()
			return
		if event.is_action_pressed("journal"):
			get_viewport().set_input_as_handled()
			ui.open_journal()
			return
	# forward everything else to the 3D world (player interaction, camera)
	if sub and (state == "playing" or state == "title"):
		sub.push_input(event, true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and state == "playing" and world:
		_store_player()
		Game.save_game()
