extends Node
## Scripted gameplay trailer. Record it with Godot's Movie Maker mode:
##   godot --path . --write-movie trailer/frame.png --fixed-fps 30 \
##         --resolution 1280x720 -- --trailer
## then encode the frames + wav with ffmpeg (see tools/make_trailer.sh).

var main: Node
var world: World
var ui: UIRoot
var story: Story
var cap_layer: CanvasLayer
var cap_label: Label
var cap_sub: Label
var _orbit_center := Vector3.ZERO
var _orbit_radius := 0.0
var _orbit_height := 0.0
var _orbit_angle := 0.0
var _orbit_speed := 0.0
var _orbiting := false
var _pan_from := Vector3.ZERO
var _pan_to := Vector3.ZERO
var _pan_look := Vector3.ZERO
var _pan_t := -1.0
var _pan_len := 1.0


func run(m: Node) -> void:
	main = m
	world = m.world
	ui = m.ui
	story = m.story
	_build_captions()
	Game.settings["dither"] = false
	Game.apply_settings()
	await _film()


# --------------------------------------------------------------------------
# helpers
# --------------------------------------------------------------------------
func wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _build_captions() -> void:
	cap_layer = CanvasLayer.new()
	cap_layer.layer = 40
	add_child(cap_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiTheme.get_theme()
	cap_layer.add_child(root)
	var vb := VBoxContainer.new()
	vb.anchor_left = 0.0
	vb.anchor_right = 1.0
	vb.anchor_top = 0.15
	vb.anchor_bottom = 0.15
	vb.add_theme_constant_override("separation", 2)
	root.add_child(vb)
	cap_label = UiTheme.label("", 22, Color(1.0, 0.97, 0.88), true)
	cap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap_label.add_theme_color_override("font_outline_color", Color(0.18, 0.12, 0.09))
	cap_label.add_theme_constant_override("outline_size", 8)
	vb.add_child(cap_label)
	cap_sub = UiTheme.label("", 12, Color(1.0, 0.97, 0.88))
	cap_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap_sub.add_theme_color_override("font_outline_color", Color(0.18, 0.12, 0.09))
	cap_sub.add_theme_constant_override("outline_size", 5)
	vb.add_child(cap_sub)
	vb.modulate.a = 0.0


func caption(text: String, sub := "", secs := 3.0) -> void:
	var box: Control = cap_label.get_parent()
	cap_label.text = text
	cap_sub.text = sub
	var tw := create_tween()
	tw.tween_property(box, "modulate:a", 1.0, 0.5)
	tw.tween_interval(secs)
	tw.tween_property(box, "modulate:a", 0.0, 0.6)


func hud(on: bool) -> void:
	ui.hud.visible = on
	ui.hud.hint_panel.visible = false


func set_time(h: float) -> void:
	Game.minutes = h * 60.0
	for n in world.npcs.values():
		(n as NPC).place_by_schedule()


func put_player(x: float, z: float, face: Vector3, yaw: float) -> void:
	var p := world.player
	p.global_position = Vector3(x, world.ground_height(x, z) + 0.2, z)
	p.velocity = Vector3.ZERO
	p.face_toward(face)
	world.rig.override_pose = []
	world.rig.yaw_target = yaw
	world.rig.snap()


func orbit(center: Vector3, radius: float, height: float, start_angle: float, speed: float) -> void:
	_orbit_center = center
	_orbit_radius = radius
	_orbit_height = height
	_orbit_angle = start_angle
	_orbit_speed = speed
	_orbiting = true
	_pan_t = -1.0
	_apply_orbit(0.0, true)


func pan(from: Vector3, to: Vector3, look: Vector3, secs: float) -> void:
	_orbiting = false
	_pan_from = from
	_pan_to = to
	_pan_look = look
	_pan_t = 0.0
	_pan_len = secs
	world.rig.override_pose = [from, look]
	world.rig.cam.global_position = from
	world.rig.cam.look_at(look)


func stop_camera() -> void:
	_orbiting = false
	_pan_t = -1.0
	world.rig.override_pose = []


func _apply_orbit(delta: float, snap := false) -> void:
	_orbit_angle += _orbit_speed * delta
	var pos := _orbit_center + Vector3(sin(_orbit_angle) * _orbit_radius, _orbit_height, cos(_orbit_angle) * _orbit_radius)
	world.rig.override_pose = [pos, _orbit_center]
	if snap:
		world.rig.cam.global_position = pos
	world.rig.cam.global_position = pos
	world.rig.cam.look_at(_orbit_center)


func _process(delta: float) -> void:
	if world == null:
		return
	if _orbiting:
		_apply_orbit(delta)
	elif _pan_t >= 0.0:
		_pan_t = minf(_pan_t + delta / _pan_len, 1.0)
		var t := _pan_t * _pan_t * (3.0 - 2.0 * _pan_t)
		var pos := _pan_from.lerp(_pan_to, t)
		world.rig.override_pose = [pos, _pan_look]
		world.rig.cam.global_position = pos
		world.rig.cam.look_at(_pan_look)


func walk_to(tgt: Vector2, max_time := 6.0, run := false) -> void:
	var p := world.player
	var t := 0.0
	while t < max_time:
		var pos := Vector2(p.global_position.x, p.global_position.z)
		var d := tgt - pos
		if d.length() < 1.2:
			break
		var dir := d.normalized()
		var fwd := world.rig.flat_forward()
		var right := world.rig.flat_right()
		_axis(dir.dot(Vector2(right.x, right.z)), dir.dot(Vector2(fwd.x, fwd.z)))
		if run:
			Input.action_press("run")
		await get_tree().process_frame
		t += get_process_delta_time()
	_axis(0, 0)
	Input.action_release("run")


func _axis(x: float, y: float) -> void:
	for a in ["move_left", "move_right", "move_forward", "move_back"]:
		Input.action_release(a)
	if x > 0.05:
		Input.action_press("move_right", clampf(x, 0, 1))
	elif x < -0.05:
		Input.action_press("move_left", clampf(-x, 0, 1))
	if y > 0.05:
		Input.action_press("move_forward", clampf(y, 0, 1))
	elif y < -0.05:
		Input.action_press("move_back", clampf(-y, 0, 1))


## Show one line of dialogue for a while, then close it.
func line(npc_id: String, text: String, secs := 2.6) -> void:
	var speaker := Game.player_name
	var voice := Story.PLAYER_VOICE
	var node: Node = world.player
	if npc_id != "":
		var n: NPC = world.npcs[npc_id]
		speaker = n.display_name()
		voice = n.voice()
		node = n
		n.begin_talk(world.player)
		world.player.face_toward(n.global_position)
	world.player.busy = true
	ui.dialogue.say(speaker, text.replace("{name}", Game.player_name), voice, node)
	await wait(secs)
	ui.dialogue._finish_typing()
	ui.dialogue._advance()
	ui.close_dialogue()
	world.player.busy = false
	if npc_id != "":
		(world.npcs[npc_id] as NPC).end_talk()


func interact_with(it: Interactable) -> void:
	world.player.face_toward(it.global_position)
	it.interact(world.player)


func nearest_litter() -> Litter:
	var best: Litter = null
	var bd := 1e9
	for l in world.litter_nodes:
		if is_instance_valid(l):
			var d: float = (l as Node3D).global_position.distance_to(Vector3(0, 3, 44))
			if d < bd:
				bd = d
				best = l
	return best


# --------------------------------------------------------------------------
# the film
# --------------------------------------------------------------------------
func _film() -> void:
	# --- title -------------------------------------------------------------
	main.show_title()
	ui.title.menu_box.get_parent().visible = false
	await wait(6.5)
	await ui.fade_out(0.8)
	ui.title.visible = false
	# start a fresh game without the intro
	Game.new_game()
	Game.player_name = "Mose"
	Game.playing = true
	Game.time_running = false
	Game.minutes = 8.3 * 60.0
	# no task tracker during the trailer (scenes set up their own state)
	Game.quests["m1_wake"] = {"state": "done", "step": 5}
	world.start_day()
	main.state = "playing"
	Sound.update_music()
	# --- the hollow at dawn ----------------------------------------------------
	hud(false)
	var home: Vector2 = Layout.ANCHORS["home"]
	put_player(home.x + 3.5, home.y + 4.5, Vector3(-20, 28, -78), 0.75)
	orbit(world.player.global_position + Vector3(0, 1.5, 0), 11.0, 5.5, 0.4, 0.12)
	ui.fade_in(1.0)
	caption("High above the fjord lives a gentle troll...", "", 3.2)
	await wait(4.5)
	stop_camera()
	hud(true)
	caption("...who loves berries, moss and cooking.", "", 3.5)
	var bush: ForageSpot = null
	var bd := 1e9
	for f in world.forage_spots:
		if (f as ForageSpot).kind == "bush_blue":
			var d := (f as Node3D).global_position.distance_to(world.player.global_position)
			if d < bd:
				bd = d
				bush = f
	await walk_to(Vector2(bush.global_position.x + 1.2, bush.global_position.z + 1.2), 6.0)
	interact_with(bush)
	await wait(1.2)
	Game.add_item("blueberry", 3, true)
	Game.learn_recipe("blueberry_jam")
	var cau: Vector2 = Layout.ANCHORS["cauldron"]
	put_player(cau.x + 1.8, cau.y + 1.8, Vector3(cau.x, 28, cau.y), 0.9)
	await wait(0.4)
	ui.craft.open()
	await wait(1.4)
	ui.craft._cook("blueberry_jam")
	await wait(1.4)
	ui.craft.close()
	# --- the village flees ---------------------------------------------------
	await ui.fade_out(0.5)
	set_time(10.3)
	put_player(-8.0, 54.0, Vector3(0, 3, 44), 0.25)
	Sound.update_music()
	await ui.fade_in(0.5)
	caption("But the people of Lillevik are terrified of trolls.", "", 3.5)
	await walk_to(Vector2(-2, 45), 4.0)
	await wait(2.5)
	caption("You have no idea why.", "", 2.2)
	await wait(3.2)
	# --- secret kindness at night ------------------------------------------
	await ui.fade_out(0.6)
	set_time(22.4)
	world.spawn_litter()
	Game.add_item("blueberry_jam", 1, true)
	var lit := nearest_litter()
	put_player(lit.global_position.x + 1.4, lit.global_position.z + 1.4, lit.global_position, 2.6)
	Sound.update_music()
	await ui.fade_in(0.6)
	caption("So you help them in secret.", "Tidy the village. Leave gifts on doorsteps.", 1.9)
	await wait(1.0)
	interact_with(lit)
	await wait(1.6)
	var spot: GiftSpot = world.gift_spots["ingrid"]
	put_player(spot.global_position.x + 1.6, spot.global_position.z + 1.2, spot.global_position, 2.2)
	await wait(0.5)
	story.leave_doorstep_gift(spot)
	await wait(1.6)
	ui.items.close("blueberry_jam")
	await wait(1.4)
	# --- the morning paper ---------------------------------------------------
	await ui.fade_out(0.6)
	Game.day = 3
	Game.flags["first_flee"] = true
	Game.counters["litter_yesterday"] = 4
	var paper := story.compose_paper([{"type": "doorstep", "npc": "ingrid", "item": "blueberry_jam", "pref": "love"}])
	ui.paper.show_paper(paper)
	await wait(4.2)
	ui.paper._close()
	await wait(0.4)
	# --- troll strength --------------------------------------------------------
	set_time(11.0)
	Game.set_flag("troll_lift")
	var b: Boulder = world.boulders[0]
	put_player(b.global_position.x - 0.5, b.global_position.z - 3.0, b.global_position, 3.3)
	var pp := world.player.global_position
	pan(pp + Vector3(12.5, 3.0, 1.5), pp + Vector3(11.5, 3.5, 4.5), pp + Vector3(-3.0, 3.0, 5.5), 4.5)
	Sound.update_music()
	await ui.fade_in(0.6)
	caption("Lift what no human can.", "", 3.2)
	await wait(0.6)
	interact_with(b)
	await wait(3.4)
	await ui.fade_out(0.5)
	stop_camera()
	# --- troll friends ---------------------------------------------------------
	set_time(10.5)
	caption("Make friends on the mountain...", "", 6.5)
	var g: NPC = world.npcs["granny"]
	put_player(g.global_position.x + 2.5, g.global_position.z + 1.0, g.global_position, 0.4)
	await ui.fade_in(0.5)
	await line("granny", "Kindness is like moss, dear. It grows slowly, but one day it covers everything.", 3.4)
	var gub: NPC = world.npcs["gubben"]
	put_player(gub.global_position.x - 1.5, gub.global_position.z + 2.4, gub.global_position, 2.9)
	await line("gubben", "WHO'S THAT TRIP-TRAPPING OVER MY BRIDGE? ...Oh. It's you. Hello, {name}.", 3.2)
	Game.quests["s_tussa"] = {"state": "active", "step": 0}
	story.update_tussa()
	var tu: NPC = world.npcs["tussa"]
	put_player(tu.global_position.x + 2.2, tu.global_position.z + 2.2, tu.global_position, 0.8)
	await wait(1.0)
	story.found_tussa(tu)
	await wait(2.4)
	# --- win the village --------------------------------------------------------
	await ui.fade_out(0.5)
	for id in NpcDB.humans():
		Game.trust[id] = 80.0
	ui.hud.refresh()
	set_time(9.0)
	caption("...and slowly win the hearts of Lillevik.", "", 5.0)
	var ast: NPC = world.npcs["astrid"]
	ast.script_place(Vector3(4.5, 0, 46.5), Vector3(2.1, 0, 47.1))
	put_player(2.1, 47.1, ast.global_position, 0.0)
	await ui.fade_in(0.5)
	await line("astrid", "Everyone's being nicer about trolls now. I told them all about you!", 3.2)
	var ing: NPC = world.npcs["ingrid"]
	put_player(ing.global_position.x + 5.5, ing.global_position.z + 3.0, ing.global_position, 0.4)
	await walk_to(Vector2(ing.global_position.x + 2.5, ing.global_position.z + 1.5), 2.5)
	await wait(1.8)
	ui.journal.open(1)
	await wait(2.2)
	ui.journal.close()
	# Bukken follows the troll home over the bridge
	Game.quests["m6_goat"] = {"state": "active", "step": 3}
	Game.flags["goat_found"] = true
	world.bukken.refresh()
	# side-on and sun-lit, so Bukken isn't hidden behind the troll
	put_player(63.0, 41.2, Vector3(40, 3, 43), 0.0)
	world.bukken.global_position = Vector3(65.5, world.ground_height(65.5, 41.6), 41.6)
	await walk_to(Vector2(48.0, 42.4), 3.0)
	await walk_to(Vector2(35.0, 43.5), 3.0)
	await wait(0.3)
	# --- scenery ----------------------------------------------------------------
	hud(false)
	await ui.fade_out(0.5)
	set_time(8.6)
	world.bukken.global_position = Vector3(-50, world.ground_height(-50, 52), 52)
	Game.flags["goat_home"] = true
	world.bukken.refresh()
	caption("A valley to explore, from misty mornings...", "", 3.2)
	pan(Vector3(12, 30, -18), Vector3(22, 26, -24), Vector3(31, 22, -48), 5.0)
	await ui.fade_in(0.5)
	await wait(4.4)
	set_time(19.3)
	Sound.update_music()
	caption("...to golden fjord sunsets...", "", 3.0)
	pan(Vector3(-30, 14, 92), Vector3(-10, 12, 96), Vector3(10, 2, 70), 4.5)
	await wait(4.3)
	set_time(23.2)
	world.daynight.aurora_forced = true
	Sound.update_music()
	caption("...and northern lights.", "", 3.0)
	pan(Vector3(-14, 7, 72), Vector3(-8, 7.5, 72), Vector3(-2, 100, -80), 5.0)
	await wait(5.0)
	# --- the festival --------------------------------------------------------------
	await ui.fade_out(0.6)
	set_time(20.35)
	var bf: Vector3 = world.anchor_position("bonfire", "")
	story._make_bonfire(bf)
	story._sky_lanterns(bf)
	var order := ["margit", "granny", "ingrid", "stein", "astrid", "tussa", "ole", "lyng", "lars", "gubben", "solveig"]
	for i in range(order.size()):
		var a := TAU * float(i + 1) / (order.size() + 1)
		(world.npcs[order[i]] as NPC).script_place(bf + Vector3(sin(a), 0, cos(a)) * 6.5, bf, "dance")
	put_player(bf.x, bf.z + 6.5, bf, 0.0)
	world.player.play_mode("dance", 30.0)
	world.bukken.global_position = bf + Vector3(8.5, 0, 3)
	world.bukken.global_position.y = world.ground_height(world.bukken.global_position.x, world.bukken.global_position.z)
	Sound.play_music("festival")
	orbit(bf + Vector3(0, 1.5, 0), 15.0, 7.5, 0.3, 0.16)
	await ui.fade_in(0.8)
	caption("Can a troll and a village learn to be friends?", "", 4.2)
	await wait(6.5)
	# --- end card ---------------------------------------------------------------------
	await ui.fade_out(1.2)
	cap_label.add_theme_font_size_override("font_size", 64)
	var box: Control = cap_label.get_parent()
	box.anchor_top = 0.36
	box.anchor_bottom = 0.36
	caption("TROLL", "a cozy tale from the Norwegian mountains\n\nmade with Godot 4", 5.0)
	await wait(6.5)
	get_tree().quit()
