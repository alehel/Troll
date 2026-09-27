extends Node
## Automated playthrough used during development:
##   godot --path . -- --autotest [--shots]
## Plays through the whole story with simulated input and API calls, checks
## that every main task completes, and optionally saves screenshots to user://.

var main: Node
var world: World
var ui: UIRoot
var story: Story
var shots := false
var shot_n := 0
var failures: Array = []


func run(m: Node) -> void:
	main = m
	world = m.world
	ui = m.ui
	story = m.story
	shots = OS.get_cmdline_user_args().has("--shots")
	await _play()


func wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func shot(label: String) -> void:
	if not shots:
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	shot_n += 1
	var p := "user://auto_%02d_%s.png" % [shot_n, label]
	img.save_png(p)
	print("SHOT ", ProjectSettings.globalize_path(p))


func check(cond: bool, what: String) -> void:
	if cond:
		print("  ok: ", what)
	else:
		print("  FAIL: ", what)
		failures.append(what)


func press(action: String) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	Input.parse_input_event(e)
	await get_tree().process_frame
	var r := InputEventAction.new()
	r.action = action
	r.pressed = false
	Input.parse_input_event(r)
	await get_tree().process_frame


## Advance dialogue until the conversation ends. `choices` is a queue of option
## labels to pick; when empty the last option (Goodbye / Not yet) is chosen.
func run_dialogue(choices: Array = [], timeout := 60.0, snap := "") -> void:
	var t := 0.0
	var snapped := snap == ""
	await get_tree().process_frame
	while t < timeout:
		if ui.items.visible or ui.paper.visible or ui._card_wait:
			return
		if ui.dialogue.choosing:
			var opts: Array = []
			for b in ui.dialogue._buttons:
				opts.append((b as Button).text)
			var pick := opts.size() - 1
			if not choices.is_empty():
				var want: String = choices.pop_front()
				var idx := opts.find(want)
				if idx >= 0:
					pick = idx
				else:
					print("    (wanted choice '%s' not in %s)" % [want, opts])
			ui.dialogue._pick(pick)
		elif ui.dialogue.visible and ui.dialogue.waiting:
			if not snapped and not ui.dialogue._typing:
				snapped = true
				await shot(snap)
			await press("interact")
		elif not story.busy and not ui.dialogue.visible:
			return
		await wait(0.06)
		t += 0.06
	print("    dialogue timeout")


func near(id: String, dist := 2.2) -> NPC:
	var n: NPC = world.npcs[id]
	var p := n.global_position + n.face_dir * dist
	p.y = world.ground_height(p.x, p.z) + 0.2
	world.player.global_position = p
	world.player.velocity = Vector3.ZERO
	world.player.face_toward(n.global_position)
	world.rig.snap()
	await wait(0.2)
	return n


func talk(id: String, choices: Array = [], snap := "") -> void:
	var n := await near(id)
	if n.state == "hidden" or n.state == "flee":
		n.place_by_schedule()
		n = await near(id)
	story.talk(n)
	await run_dialogue(choices, 60.0, snap)
	await wait(0.2)


func teleport(x: float, z: float) -> void:
	world.player.global_position = Vector3(x, world.ground_height(x, z) + 0.3, z)
	world.player.velocity = Vector3.ZERO
	world.rig.snap()
	await wait(0.3)


func gather(kind: String, item: String, n: int) -> void:
	var guard := 0
	while Game.count(item) < n and guard < 40:
		guard += 1
		var picked_any := false
		for f in world.forage_spots:
			var fs := f as ForageSpot
			if fs.kind == kind and fs.available:
				await teleport(fs.global_position.x + 1.2, fs.global_position.z + 1.2)
				fs.interact(world.player)
				picked_any = true
				break
		if not picked_any:
			Game.add_item(item, n - Game.count(item))
		await wait(0.1)


func sleep_night(snap := "") -> void:
	story.sleep_prompt()
	await run_dialogue(["Sleep"])
	var t := 0.0
	while not ui.paper.visible and t < 20.0:
		await wait(0.1)
		t += 0.1
	await wait(0.6)
	if snap != "":
		await shot(snap)
	await press("interact")
	while story.busy and t < 40.0:
		await wait(0.1)
		t += 0.1
	await wait(0.3)


func _play() -> void:
	print("=== AUTOTEST START ===")
	main.show_title()
	await wait(2.5)
	await shot("title")
	main._start_new("Mose")
	await wait(1.5)
	await run_dialogue([], 30.0, "intro")
	await wait(0.8)
	await shot("home_morning")
	check(Game.is_active("m1_wake"), "m1 started")
	# --- chapter 1
	await talk("granny", [], "granny_talk")
	check(Game.quest_step("m1_wake") == 1, "m1 step 1 after talking to Granny")
	await gather("bush_blue", "blueberry", 3)
	check(Game.quest_step("m1_wake") == 2, "blueberries gathered")
	await talk("granny")
	check(Game.known_recipes.has("blueberry_jam"), "learned jam")
	await gather("bush_blue", "blueberry", 3)
	var cau: Vector2 = Layout.ANCHORS["cauldron"]
	await teleport(cau.x + 2.0, cau.y + 2.0)
	ui.open_craft()
	await wait(0.5)
	await shot("craft_menu")
	ui.craft._cook("blueberry_jam")
	await wait(0.2)
	ui.craft.close()
	await wait(0.3)
	check(Game.count("blueberry_jam") >= 1 and Game.quest_step("m1_wake") == 4, "cooked jam")
	await talk("granny")
	check(Game.is_done("m1_wake") and Game.is_active("m2_hello"), "m1 done, m2 active")
	# --- chapter 2: meet a human
	Game.minutes = 10.0 * 60.0
	for n in world.npcs.values():
		(n as NPC).place_by_schedule()
	var ing: NPC = world.npcs["ingrid"]
	await teleport(ing.global_position.x + 9.0, ing.global_position.z + 4.0)
	world.player.face_toward(ing.global_position)
	var t := 0.0
	while t < 3.0:
		Input.action_press("move_left")
		await wait(0.1)
		t += 0.1
		if Game.has_flag("first_flee"):
			break
	Input.action_release("move_left")
	await wait(0.6)
	await shot("human_flees")
	check(Game.has_flag("first_flee"), "a human fled")
	await wait(1.0)
	await shot("village_day")
	await talk("granny")
	check(Game.is_active("m3_secret"), "m3 active")
	# --- chapter 3: secret kindness
	var spot: GiftSpot = world.gift_spots["ingrid"]
	await teleport(spot.global_position.x + 1.5, spot.global_position.z + 1.5)
	story.leave_doorstep_gift(spot)
	await wait(0.4)
	await shot("gift_picker")
	ui.items.close("blueberry_jam")
	await wait(0.3)
	check(Game.doorstep.get("ingrid", "") == "blueberry_jam", "left doorstep gift")
	var cleaned := 0
	for l in world.litter_nodes.duplicate():
		if is_instance_valid(l) and cleaned < 3:
			await teleport(l.global_position.x + 1.0, l.global_position.z + 1.0)
			(l as Litter).interact(world.player)
			cleaned += 1
			await wait(0.2)
	check(Game.counter("litter") >= 3, "cleaned litter")
	ui.open_inventory()
	await wait(0.5)
	await shot("inventory")
	ui.items.close("")
	await wait(0.2)
	Game.minutes = 21.5 * 60.0
	var home: Vector2 = Layout.ANCHORS["home"]
	await teleport(home.x + 4, home.y + 5)
	await wait(1.0)
	check(not ui.hud.prompt_panel.visible, "no stale interaction prompt")
	await shot("night_home")
	await sleep_night("newspaper_day2")
	check(Game.day == 2, "day 2")
	check(Game.requests.size() >= 1, "a favour was requested")
	if Game.requests.size() >= 1:
		var r: Dictionary = Game.requests[0]
		Game.add_item(r["item"], int(r["n"]))
		var label := "Deliver " + ItemDB.count_name(r["item"], int(r["n"]))
		var before := Game.inventory.duplicate()
		await talk(r["npc"], [label])
		check(r["done"], "favour delivered to " + String(r["npc"]))
	check(Game.is_done("m3_secret") and Game.is_active("m4_strength"), "m3 done, m4 active")
	# --- side: Lyng
	await talk("lyng")
	check(Game.is_active("s_lyng"), "lyng quest offered")
	Game.add_item("chanterelle", 2)
	Game.add_item("heather", 2)
	await talk("lyng")
	check(Game.known_recipes.has("bouquet"), "learned bouquet")
	# --- chapter 4: troll strength
	await talk("stein")
	await gather("crystal", "crystal", 2)
	await talk("stein")
	check(Game.has_flag("troll_lift"), "troll lift learned")
	for b in world.boulders.duplicate():
		if is_instance_valid(b):
			await teleport(b.global_position.x - 2.5, b.global_position.z)
			(b as Boulder).interact(world.player)
			await wait(3.0)
	await shot("boulders_cleared")
	check(Game.is_done("m4_strength"), "rockslide cleared")
	# --- chapter 5: Astrid's kite
	Game.add_trust("astrid", 14.0)
	await wait(0.2)
	check(Game.is_active("m5_kite"), "m5 active")
	Game.minutes = 10.0 * 60.0
	for n in world.npcs.values():
		(n as NPC).place_by_schedule()
	await talk("astrid", [], "astrid_talk")
	var kt: Vector2 = Layout.ANCHORS["kite_tree"]
	await teleport(kt.x + 2.5, kt.y + 2.5)
	world._shake_kite_tree(world.player)
	await wait(2.5)
	for p in world.pickups:
		if (p as ItemPickup).item == "kite" and p.visible:
			(p as ItemPickup).interact(world.player)
	check(Game.count("kite") == 1, "got kite")
	await talk("astrid")
	check(Game.is_done("m5_kite"), "kite returned")
	# --- chapter 6: the lost goat
	await wait(0.2)
	check(Game.is_active("m6_goat"), "m6 active")
	await talk("astrid")
	await talk("gubben", [], "gubben_talk")
	var g := world.bukken
	await teleport(g.global_position.x + 2, g.global_position.z + 2)
	g.interact(world.player)
	check(Game.has_flag("goat_found"), "goat found")
	await teleport(-44.0, 44.0)
	await wait(1.5)
	g.global_position = Vector3(-50, world.ground_height(-50, 52), 52)
	await wait(0.5)
	check(Game.has_flag("goat_home"), "goat home")
	await talk("lars")
	check(Game.is_done("m6_goat"), "goat quest done")
	# --- chapter 7: meeting
	for id in NpcDB.humans():
		Game.add_trust(id, 40.0)
	await wait(0.2)
	check(Game.is_active("m7_meeting"), "m7 active")
	var nb: Vector2 = Layout.ANCHORS["notice_board"]
	await teleport(nb.x + 1.0, nb.y + 1.0)
	story.read_notice_board()
	await run_dialogue()
	check(Game.has_flag("read_meeting_notice"), "read notice")
	await talk("margit", [], "margit_talk")
	check(Game.is_active("m8_festival"), "m8 active")
	# friendly villagers
	await talk("ingrid", ["Chat"], "ingrid_friendly")
	# --- chapter 8: festival prep
	for id in ["granny", "stein", "tussa", "lyng", "gubben"]:
		await talk(id, ["Invite to the festival"])
	check(Game.counter("invited") >= 5 and Game.quest_step("m8_festival") >= 1, "all trolls invited")
	Game.add_item("cloudberry", 3)
	await talk("ingrid")
	Game.add_item("driftwood", 4)
	await talk("ole")
	Game.add_item("bouquet", 1)
	await talk("solveig")
	await talk("margit")
	check(Game.has_flag("festival_ready"), "festival ready")
	await ui.journal.open(0)
	await wait(0.4)
	await shot("journal")
	ui.journal._set_tab(1)
	await wait(0.3)
	await shot("journal_friends")
	ui.journal.close()
	Game.minutes = 20.2 * 60.0
	var bf: Vector2 = Layout.ANCHORS["bonfire"]
	await teleport(bf.x + 6.0, bf.y - 6.0)
	var tt := 0.0
	while not story._festival_running and tt < 5.0:
		await wait(0.1)
		tt += 0.1
	check(story._festival_running, "festival started")
	await wait(3.0)
	await run_dialogue([], 120.0, "festival_talk")
	await wait(4.0)
	await shot("festival_dance")
	tt = 0.0
	while not ui._card_wait and tt < 30.0:
		await wait(0.2)
		tt += 0.2
	await shot("the_end")
	await press("interact")
	await wait(2.0)
	check(Game.has_flag("game_complete"), "GAME COMPLETE")
	# save / load round trip
	Game.save_game()
	var before := Game.to_dict()
	Game.load_game()
	check(JSON.stringify(Game.to_dict()) == JSON.stringify(before), "save/load round trip")
	print("=== AUTOTEST END: %d failures ===" % failures.size())
	for f in failures:
		print("  - ", f)
	get_tree().quit(1 if failures.size() > 0 else 0)
