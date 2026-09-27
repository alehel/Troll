class_name Story
extends Node
## Conversations, gifts, sleep, the morning paper and scripted events.

const PLAYER_VOICE := 0.82

const INVITES := {
	"granny": ["A festival? With humans? Oh, I haven't been to a party since the Viking age!", "I'll bring my knitting. And my dancing knees."],
	"stein": ["Hrm. Many people. Loud.", "...Will there be rocks? I'll bring a rock. For sitting."],
	"tussa": ["A PARTY?! WITH HUMANS?!", "I'm going to wear my fanciest scarf! And my other fanciest scarf!"],
	"lyng": ["How lovely. A harvest festival.", "I'll bring flowers for everyone's hair."],
	"gubben": ["Leave my bridge? For a party?", "...Oh, why not. It's not going anywhere. It never does."],
}

const MYTHS := [
	"MYTH: Trolls turn to stone in sunlight. Our correspondent watched one sunbathe for three hours. It remained soft.",
	"MYTH: Trolls eat goats. FACT: A troll was recently seen apologising to a goat.",
	"MYTH: Trolls steal bread. FACT: The bakery reports no missing bread. It does report extra jam.",
	"MYTH: Trolls cannot count. A troll was seen counting blueberries. It reached 'lots'.",
	"MYTH: A troll's sneeze can knock down a house. Unconfirmed. Please do not test this.",
	"MYTH: Trolls hate church bells. A troll was heard humming along on Sunday.",
	"MYTH: Trolls live for a thousand years. FACT: Some do. They are very good at knitting.",
	"MYTH: Trolls have tails. FACT: Yes, actually. They are quite fluffy.",
]

var world: World
var ui: Node
var busy := false
var _puzzle_cd := 0.0
var _festival_running := false


func setup(w: World, u: Node) -> void:
	world = w
	ui = u


func _process(delta: float) -> void:
	_puzzle_cd -= delta
	if not Game.playing or busy or world == null:
		return
	if Game.has_flag("passed_out") and not world.cutscene:
		_passed_out()
		return
	if Game.is_active("m8_festival") and Game.quest_step("m8_festival") == 5 and not _festival_running:
		var b: Vector3 = world.anchor_position("bonfire", "")
		if Game.minutes >= 20.0 * 60.0 and world.player.global_position.distance_to(b) < 16.0:
			festival()


# --------------------------------------------------------------------------
# dialogue helpers
# --------------------------------------------------------------------------
func _fmt(t: String) -> String:
	return t.replace("{name}", Game.player_name)


func say(npc: NPC, text: String) -> void:
	await ui.say(npc.display_name(), _fmt(text), npc.voice(), npc)


func say_player(text: String) -> void:
	await ui.say(Game.player_name, _fmt(text), PLAYER_VOICE, world.player)


func narrate(lines: Array) -> void:
	var was_busy := world.player.busy
	world.player.busy = true
	var was_time := Game.time_running
	Game.time_running = false
	for l in lines:
		await ui.say("", _fmt(String(l).trim_prefix("* ")), 1.0, null)
	ui.close_dialogue()
	world.player.busy = was_busy
	Game.time_running = was_time


func play_lines(lines: Array, npc: NPC) -> void:
	for raw in lines:
		var l: String = raw
		if l.begins_with("> "):
			await say_player(l.substr(2))
		elif l.begins_with("* "):
			await ui.say("", _fmt(l.substr(2)), 1.0, null)
		elif l.begins_with("@"):
			var sep := l.find(":")
			var who := l.substr(1, sep - 1)
			var other: NPC = world.npcs.get(who)
			if other:
				await say(other, l.substr(sep + 1).strip_edges())
		elif npc != null:
			await say(npc, l)
		else:
			await ui.say("", _fmt(l), 1.0, null)


# --------------------------------------------------------------------------
# talking
# --------------------------------------------------------------------------
func talk(npc: NPC) -> void:
	if busy:
		return
	busy = true
	var p := world.player
	p.busy = true
	Game.time_running = false
	npc.begin_talk(p)
	p.face_toward(npc.global_position)
	await _talk_flow(npc)
	ui.close_dialogue()
	if npc.state == "talk":
		npc.end_talk()
	p.busy = false
	Game.time_running = true
	busy = false


func _talk_flow(npc: NPC) -> void:
	var id := npc.id
	var human := npc.is_human
	var stage := Game.trust_stage(id) if human else 5
	var did := await _quest_talk(npc, stage)
	if human and stage == 0:
		if not did:
			npc.end_talk()
			npc.start_flee()
		return
	if not did:
		did = await _quest_offer(npc, stage)
	if not did:
		did = await _mention_request(npc, stage)
	if not did:
		if human:
			if stage == 1:
				await say(npc, NpcDB.pick(npc.data.get("scared", ["..."])))
			else:
				await say(npc, NpcDB.pick(npc.data["stage_lines"].get(stage, ["Hello."])))
		else:
			await say(npc, NpcDB.pick(npc.data.get("greet", ["Hello."])))
	stage = Game.trust_stage(id) if human else 5
	while true:
		var opts: Array = []
		if not (human and stage <= 1):
			opts.append("Chat")
		opts.append("Give a gift")
		var req := Game.request_for(id)
		if not req.is_empty() and Game.count(req["item"]) >= int(req["n"]) and not (human and stage <= 1):
			opts.push_front("Deliver " + ItemDB.count_name(req["item"], int(req["n"])))
		if not human and Game.is_active("m8_festival") and Game.quest_step("m8_festival") == 0 and not Game.has_flag("invited_" + id):
			opts.append("Invite to the festival")
		opts.append("Goodbye")
		var c: int = await ui.choose(opts)
		var pick: String = opts[c] if c >= 0 else "Goodbye"
		if pick.begins_with("Deliver "):
			await _deliver_request(npc)
			continue
		match pick:
			"Chat":
				await _chat(npc, stage)
			"Give a gift":
				var gave: bool = await _give_gift(npc, stage)
				if gave and human and stage <= 1:
					return
			"Invite to the festival":
				await play_lines(INVITES.get(id, ["I'll be there!"]), npc)
				Game.set_flag("invited_" + id)
				Game.inc("invited")
			_:
				if human and stage >= 2:
					await say(npc, NpcDB.pick(["Bye, then.", "See you around.", "Take care!", "Goodbye, {name}!"]) if stage >= 3 else NpcDB.pick(["Um. Bye.", "Goodbye, troll.", "Right. Bye."]))
				elif not human:
					await say(npc, NpcDB.pick(["Off you go, then.", "Mind the bogs!", "See you soon, {name}.", "Hrm. Bye."]))
				return


func _quest_talk(npc: NPC, stage: int) -> bool:
	var did := false
	for qid in Game.active_quests():
		var step := Game.current_step(qid)
		if step.is_empty():
			continue
		var scared_ok: bool = step.get("allow_scared", false)
		if npc.is_human and stage == 0 and not scared_ok:
			continue
		if step.get("talk", "") == npc.id:
			await play_lines(step.get("lines", []), npc)
			Game.advance_quest(qid)
			did = true
		elif step.has("turn_in") and step["turn_in"]["npc"] == npc.id:
			var take: Dictionary = step["turn_in"].get("take", {})
			if Game.has_items(take):
				Game.take_items(take)
				await play_lines(step.get("lines", []), npc)
				Game.advance_quest(qid)
				did = true
			elif step.has("remind"):
				await play_lines(step["remind"], npc)
				did = true
	return did


func _quest_offer(npc: NPC, stage: int) -> bool:
	if npc.is_human and stage < 2:
		return false
	for qid in QuestDB.ORDER:
		if Game.quests.has(qid):
			continue
		var q := QuestDB.get_quest(qid)
		if not q.has("offer"):
			continue
		var off: Dictionary = q["offer"]
		if off["npc"] != npc.id or not Game.cond_met(off.get("cond", {})):
			continue
		await play_lines(off.get("lines", []), npc)
		Game.start_quest(qid)
		if qid == "s_tussa":
			update_tussa()
		return true
	return false


const ASK_LINES := [
	"Oh, {name}! Could you bring me {items} today? I'd be ever so grateful.",
	"I've been dreaming of {items}. You wouldn't happen to find some, would you?",
	"If you come across {items}, would you bring them by? Only if it's no trouble!",
]
const THANK_LINES := [
	"Oh, wonderful! Thank you, {name}!",
	"Perfect! Just what I needed. You're a treasure.",
	"You remembered! Here, take this as a thank you.",
]


func _mention_request(npc: NPC, stage: int) -> bool:
	var req := Game.request_for(npc.id)
	if req.is_empty() or req["asked"] or (npc.is_human and stage < 3):
		return false
	req["asked"] = true
	var line: String = NpcDB.pick(ASK_LINES).replace("{items}", ItemDB.count_name(req["item"], int(req["n"])))
	await say(npc, line)
	Game.emit_signal("notify", "Favour: " + Game.request_text(req), req["item"])
	Game.emit_signal("quest_changed", "")
	return true


func _deliver_request(npc: NPC) -> void:
	var req := Game.request_for(npc.id)
	if req.is_empty() or not Game.remove_item(req["item"], int(req["n"])):
		return
	req["done"] = true
	Game.inc("favours")
	await say(npc, NpcDB.pick(THANK_LINES))
	var reward: String = npc.data.get("treat", Game.TROLL_REWARDS.get(npc.id, "pretty_stone"))
	Game.add_item(reward)
	if npc.is_human:
		Game.add_trust(npc.id, 7.0)
	else:
		Game.add_friendship(npc.id, 7.0)
	Sound.sfx("gift")
	world.spawn_puff(npc.global_position + Vector3(0, npc.model.height + 0.3, 0), Color(1.0, 0.45, 0.55))
	Game.emit_signal("quest_changed", "")


func _chat(npc: NPC, stage: int) -> void:
	var id := npc.id
	var line := ""
	if npc.is_human:
		line = NpcDB.pick(npc.data["stage_lines"].get(stage, ["..."]))
	else:
		var pool: Array = npc.data.get("chat", [])
		if Game.get_friendship(id) >= 60.0 and randf() < 0.5:
			pool = npc.data.get("chat_high", pool)
		line = NpcDB.pick(pool)
	await say(npc, line)
	if not Game.talked_today.has(id):
		Game.talked_today[id] = true
		if npc.is_human:
			Game.add_trust(id, 2.0)
			if stage >= 4 and randf() < 0.45 and npc.data.has("treat"):
				var treat: String = npc.data["treat"]
				await say(npc, NpcDB.pick(["Oh! Before I forget, take this.", "Here, I made too many. Take one!", "This is for you, {name}."]))
				Game.add_item(treat)
				Sound.sfx("gift")
		else:
			Game.add_friendship(id, 3.0)


func _give_gift(npc: NPC, stage: int) -> bool:
	var id := npc.id
	if Game.gifted_today.has(id):
		await ui.say("", "You've already given %s a gift today." % npc.display_name(), 1.0, null)
		return false
	if Game.inventory.is_empty():
		await ui.say("", "Your bag is empty. Go and gather something nice!", 1.0, null)
		return false
	var item: String = await ui.pick_item("Give a gift to " + npc.display_name(), func(i: String) -> bool: return ItemDB.is_giftable(i))
	if item == "":
		return false
	Game.remove_item(item)
	Game.gifted_today[id] = true
	var pref := NpcDB.preference(id, item)
	Sound.sfx("gift", 1.0 if pref != "dislike" else 0.8)
	if npc.is_human:
		var gain: float = {"love": 12.0, "like": 8.0, "neutral": 4.0, "dislike": 1.0}[pref]
		if stage <= 1:
			await ui.say("", "%s snatches the %s and backs away, trembling... but %s looks a little less scared." % [npc.display_name(), ItemDB.name_of(item), "she" if id in ["ingrid", "astrid", "solveig", "margit"] else "he"], 1.0, null)
			Game.add_trust(id, gain * 0.9)
		else:
			await say(npc, NpcDB.pick(npc.data["gift"][pref]))
			Game.add_trust(id, gain)
		Game.log_event({"type": "gift", "npc": id, "item": item, "pref": pref})
	else:
		var fgain: float = {"love": 12.0, "like": 7.0, "neutral": 3.0, "dislike": 0.0}[pref]
		await say(npc, NpcDB.pick(npc.data["gift"][pref]))
		Game.add_friendship(id, fgain)
	if pref == "love" or pref == "like":
		world.spawn_puff(npc.global_position + Vector3(0, npc.model.height + 0.3, 0), Color(1.0, 0.45, 0.55))
	return true


# --------------------------------------------------------------------------
# doorsteps, notice board, signs
# --------------------------------------------------------------------------
func leave_doorstep_gift(spot: GiftSpot) -> void:
	if busy:
		return
	var nm := NpcDB.name_of(spot.npc_id)
	if Game.doorstep.has(spot.npc_id):
		await narrate(["* There's already a %s waiting in the basket for %s." % [ItemDB.name_of(Game.doorstep[spot.npc_id]), nm]])
		return
	if Game.inventory.is_empty():
		await narrate(["* This little basket is for %s. You have nothing to leave in it... yet." % nm])
		return
	busy = true
	world.player.busy = true
	Game.time_running = false
	var item: String = await ui.pick_item("Leave a gift for " + nm, func(i: String) -> bool: return ItemDB.is_giftable(i))
	if item != "":
		Game.remove_item(item)
		Game.doorstep[spot.npc_id] = item
		spot.refresh()
		Sound.sfx("gift")
		Game.set_flag("doorstep_gift")
		Game.emit_signal("notify", "You left %s for %s." % [ItemDB.name_of(item), nm], item)
	world.player.busy = false
	Game.time_running = true
	busy = false


func read_notice_board() -> void:
	var lines: Array = ["* LILLEVIK NOTICE BOARD"]
	var mood := Game.village_trust()
	if Game.is_active("m7_meeting") and Game.quest_step("m7_meeting") == 0:
		lines.append("* \"VILLAGE MEETING about THE TROLL QUESTION. Is our troll a friend? Every villager must make up their own mind. - Mayor Margit\"")
		lines.append("> A meeting about me? I'd better make sure everyone knows I'm friendly!")
		await narrate(lines)
		Game.set_flag("read_meeting_notice")
		return
	if mood < 25.0:
		lines.append("* \"BEWARE OF TROLLS! Lock up your goats! - Lars\"")
		lines.append("> Oh no! There's a troll around? I'd better warn everyone! ...Wait.")
	elif mood < 55.0:
		lines.append("* \"BEWARE OF TROLLS\" has been crossed out. Someone has written underneath: \"be AWARE of trolls. they are nice. - Astrid\"")
	else:
		lines.append("* \"Welcome to Lillevik, home of the tidiest troll in Norway!\"")
	if not Game.is_done("s_ole_hat"):
		lines.append("* \"LOST: Yellow sou'wester. Sentimental value. Reward: a grudging thank you. - Ole\"")
	lines.append(NpcDB.pick([
		"* \"Fresh cinnamon buns every morning! - Ingrid's Bakery\"",
		"* \"The post is delayed until the road to the city is cleared. Sorry! - Solveig\"",
		"* \"Harvest Festival this autumn on the beach. Bring lanterns! - The Council\"",
		"* \"Found: one very small mitten. Ask at the shop.\"",
	]))
	for r in Game.requests:
		if not r["done"]:
			lines.append("* A note: \"%s\"" % Game.request_text(r))
	lines.append("* (Village mood: %s)" % Game.village_mood_name())
	await narrate(lines)


func read_city_sign() -> void:
	if Game.has_flag("road_cleared"):
		await narrate(["* The road to the city. Carts rattle along it again, bringing post and flour to Lillevik.",
			"> The city can wait. All my friends are right here."])
	else:
		await narrate(["* The road out of Lillevik, towards the city. A rockslide blocks it a little way back.",
			"> Humans can't move rocks that big. Hmm... but maybe a troll could."])


# --------------------------------------------------------------------------
# hide and seek
# --------------------------------------------------------------------------
func update_tussa() -> void:
	var t: NPC = world.npcs.get("tussa")
	if t == null or t.state == "script":
		return
	if Game.is_active("s_tussa") and Game.quest_step("s_tussa") < 3:
		var s: Vector2 = World.TUSSA_SPOTS[Game.quest_step("s_tussa")]
		var p := Vector3(s.x, 0, s.y)
		t.script_place(p, p + Vector3(1, 0, -1), "cower")
		t.state = "hide_seek"
	elif t.state == "hide_seek":
		t.state = "idle"
		t.place_by_schedule()


func found_tussa(t: NPC) -> void:
	Sound.sfx("giggle", 1.2)
	t.state = "script"
	t.script_mode = "cheer"
	var remaining := 2 - Game.quest_step("s_tussa")
	t.bark(NpcDB.pick(["Aww! You found me!", "Hey! How did you know?!", "No fair! You peeked!"]) + (" Again!" if remaining > 0 else ""), 2.4)
	Game.inc("tussa_found")
	await get_tree().create_timer(2.2).timeout
	world.spawn_puff(t.global_position + Vector3(0, 0.6, 0), Color(0.95, 0.9, 0.8))
	t.state = "idle"
	if Game.quest_step("s_tussa") < 3:
		update_tussa()
	else:
		t.state = "idle"
		t.place_by_schedule()
		var r: Vector2 = Layout.ANCHORS["ring"]
		t.global_position = Vector3(r.x + 3, world.ground_height(r.x + 3, r.y + 3), r.y + 3)


# --------------------------------------------------------------------------
# reactions
# --------------------------------------------------------------------------
func on_human_fled(_n: NPC) -> void:
	if _puzzle_cd > 0.0:
		return
	_puzzle_cd = 14.0
	await get_tree().create_timer(1.6).timeout
	world.show_bark(world.player, NpcDB.pick(NpcDB.PUZZLED), 3.0)


# --------------------------------------------------------------------------
# sleeping and the morning paper
# --------------------------------------------------------------------------
func sleep_prompt() -> void:
	if busy:
		return
	busy = true
	world.player.busy = true
	Game.time_running = false
	var h := Game.minutes / 60.0
	var q := "Crawl into your moss bed and sleep until morning?"
	if h < 17.0:
		q = "It's still daytime... Take a long nap until tomorrow morning?"
	await ui.say("", q, 1.0, null)
	var c: int = await ui.choose(["Sleep", "Not yet"])
	ui.close_dialogue()
	if c == 0:
		await _sleep_sequence("")
	world.player.busy = false
	Game.time_running = true
	busy = false


func _passed_out() -> void:
	busy = true
	world.player.busy = true
	Game.time_running = false
	await _sleep_sequence("It's terribly late... %s yawns an enormous troll yawn, wanders home half asleep, and flops into the moss bed." % Game.player_name)
	world.player.busy = false
	Game.time_running = true
	busy = false


func _sleep_sequence(msg: String) -> void:
	Sound.sfx("sleep")
	await ui.fade_out(1.2)
	if msg != "":
		await ui.say("", msg, 1.0, null)
		ui.close_dialogue()
	var report := Game.advance_day()
	world.start_day()
	world.place_player_at_home()
	Game.save_game()
	await ui.show_paper(compose_paper(report))
	Game.set_flag("read_paper")
	Sound.update_music()
	await ui.fade_in(1.2)
	world.show_bark(world.player, NpcDB.pick(["What a lovely morning!", "*yaaawn* Good morning, mountain!", "I smell blueberries. And adventure.", "A new day! I wonder what the humans are up to."]), 3.0)


func compose_paper(report: Array) -> Dictionary:
	var stories: Array = []
	var headline := ""
	var sub := ""
	var mood := Game.village_trust()
	var known := Game.has_flag("astrid_friend")
	var litter := 0
	var gifts := 0
	for e in report:
		match e.get("type", ""):
			"doorstep":
				gifts += 1
				var tmpl: String = NpcDB.NPCS[e["npc"]]["doorstep"][e["pref"]]
				stories.append(tmpl.replace("{item}", "a " + ItemDB.name_of(e["item"])).replace("the a ", "the "))
			"gift":
				if e.get("pref", "") == "love":
					stories.append("%s was seen accepting a %s from the troll, smiling from ear to ear." % [NpcDB.name_of(e["npc"]), ItemDB.name_of(e["item"])])
	litter = int(Game.counters.get("litter_yesterday", 0))
	Game.counters["litter_yesterday"] = 0
	# special headlines (shown once)
	var specials := [
		["festival_ready", "paper_festival", "HARVEST FESTIVAL TONIGHT!", "Trolls and humans to celebrate together for the first time in history."],
		["goat_saved", "paper_goat", "BUKKEN COMES HOME!", "Troll returns lost goat. \"He was very polite,\" says Lars. \"The troll, not the goat.\""],
		["road_cleared", "paper_road", "ROCKSLIDE VANISHES OVERNIGHT!" if not known else "TROLL CLEARS THE CITY ROAD!", "Boulders the size of barns were found in the fjord. The post can finally get through."],
		["astrid_friend", "paper_kite", "GIRL SAYS TROLL RETURNED HER KITE", "\"He's nice and he has a scarf,\" reports Astrid, 8 and three quarters."],
	]
	for s in specials:
		if Game.has_flag(s[0]) and not Game.has_flag(s[1]):
			Game.flags[s[1]] = true
			headline = s[2]
			sub = s[3]
			break
	if headline == "" and Game.is_active("m7_meeting"):
		headline = "VILLAGE MEETING: THE TROLL QUESTION"
		sub = "Mayor Margit asks every villager to make up their own mind."
	if headline == "":
		if mood < 12.0:
			if Game.day <= 2 and Game.has_flag("first_flee"):
				headline = "TROLL SIGHTED IN LILLEVIK!"
				sub = "Villagers flee. Goats locked up. Ole says \"I told you so.\""
			elif gifts > 0 or litter > 0:
				headline = "MYSTERIOUS HELPER STRIKES!"
				sub = "Gifts on doorsteps and a strangely tidy square. Who could it be?"
			else:
				headline = "QUIET DAY IN LILLEVIK"
				sub = "Nothing to report. Suspiciously nothing."
		elif mood < 28.0:
			headline = "IS THE TROLL... BEHIND THE GIFTS?"
			sub = "A theory is spreading through the village. Solveig denies spreading it."
		elif mood < 45.0:
			headline = "TROLL SEEN HUMMING WHILE PICKING UP RUBBISH"
			sub = "\"It had a lovely voice,\" admits one witness."
		elif mood < 62.0:
			headline = "TROLLS: MISUNDERSTOOD?"
			sub = "The great debate continues at the bakery."
		elif mood < 80.0:
			headline = "OUR TROLL NEIGHBOUR: A PROFILE"
			sub = "Likes: moss, jam, long walks. Dislikes: being screamed at."
		else:
			headline = "LILLEVIK LOVES ITS TROLL"
			sub = "Official. Everyone agrees. Even Ole, mostly."
	if litter > 0:
		stories.append("%d pieces of rubbish vanished from the streets overnight. Mayor Margit calls it \"baffling, but appreciated\"." % litter if mood < 40.0 else "%s the troll tidied up %d pieces of rubbish. The square is spotless." % [Game.player_name, litter])
	if stories.is_empty():
		stories.append(NpcDB.pick(["Ole caught a fish. He says it was enormous. The fish was unavailable for comment.",
			"Solveig reminds everyone that the shop is open, even if the road is not.",
			"Ingrid's cinnamon buns remain the best in the county, according to Ingrid."]))
	var weather := NpcDB.pick(["Crisp and clear. Good day for berry picking.", "Autumn winds from the fjord. Hold on to your hats, Ole.",
		"Soft clouds over the mountains. Northern lights possible tonight.", "Cool morning, golden afternoon."])
	return {
		"title": "LILLEVIK TIDENDE",
		"date": "Day %d  -  %s" % [Game.day, Game.weekday_name()],
		"headline": headline,
		"sub": sub,
		"stories": stories.slice(0, 4),
		"myth": MYTHS[(Game.day - 1) % MYTHS.size()],
		"weather": weather,
		"mood": Game.village_mood_name(),
		"mood_value": mood,
	}


# --------------------------------------------------------------------------
# intro and festival
# --------------------------------------------------------------------------
func intro() -> void:
	busy = true
	world.player.busy = true
	Game.time_running = false
	await ui.fade_in(1.5)
	await narrate([
		"* High above the fjord, where the clouds get stuck on the mountaintops, lies Trollfjell.",
		"* Here lives a young troll named {name}.",
		"* {name} loves moss, blueberries, and the smell of rain on warm stones.",
		"* And more than anything, {name} has always wanted to meet the humans who live in the little village below...",
	])
	world.player.busy = false
	Game.time_running = true
	busy = false
	ui.show_controls_hint()
	await get_tree().create_timer(0.8).timeout
	world.show_bark(world.player, "What a lovely morning! I should visit Granny Ur.", 3.5)
	Game.check_quests()


func festival() -> void:
	_festival_running = true
	busy = true
	world.cutscene = true
	var p := world.player
	p.busy = true
	Game.time_running = false
	await ui.fade_out(1.2)
	ui.hud.visible = false
	Game.minutes = maxf(Game.minutes, 20.5 * 60.0)
	world.daynight.aurora_forced = true
	var b: Vector3 = world.anchor_position("bonfire", "")
	var fire := _make_bonfire(b)
	var order := ["margit", "granny", "ingrid", "stein", "astrid", "tussa", "ole", "lyng", "lars", "gubben", "solveig"]
	var n := order.size() + 1
	for i in range(order.size()):
		var a := TAU * float(i + 1) / n
		var pos := b + Vector3(sin(a), 0, cos(a)) * 6.5
		var npc: NPC = world.npcs[order[i]]
		npc.script_place(pos, b, "idle")
	p.global_position = b + Vector3(0, 0, 6.5)
	p.global_position.y = world.ground_height(p.global_position.x, p.global_position.z) + 0.1
	p.face_toward(b)
	world.bukken.global_position = b + Vector3(8.5, 0, 3)
	world.bukken.global_position.y = world.ground_height(world.bukken.global_position.x, world.bukken.global_position.z)
	world.rig.override_pose = [b + Vector3(0, 9, 17), b + Vector3(0, 1.5, 0)]
	world.rig.cam.global_position = b + Vector3(0, 9, 17)
	Sound.play_music("festival")
	await ui.fade_in(1.5)
	var lines := [
		["margit", "Welcome, everyone! People of Lillevik... and trolls of Trollfjell!"],
		["margit", "For hundreds of years we told stories about trolls. Scary ones. Silly ones. Wrong ones."],
		["margit", "Tonight, we start a new story. Together."],
		["granny", "Well said, little mayor. Now, where is this cake I've heard so much about?"],
		["ingrid", "Seven layers of cloudberry cream! One for each troll... and a few for the humans."],
		["ole", "Hmph. I suppose I'll have to change my stories now. 'Once upon a time, there was a troll who picked up litter...'"],
		["tussa", "Astrid! Astrid! Come dance with me!"],
		["astrid", "Only if you teach me the troll dance!"],
		["stein", "Hrm. I brought a rock. For the bonfire. Rocks do not burn. It can watch."],
		["gubben", "I left my bridge for this. Best decision in three hundred years."],
		["lars", "Even Bukken came! Look at him. He's eating the tablecloth."],
		["solveig", "I'm writing EVERYTHING down. This is going on the front page!"],
		["lyng", "Flowers for everyone's hair! Yes, you too, Ole."],
		[">", "I never understood why the humans were scared of me..."],
		[">", "...but I'm so glad they aren't any more."],
		["granny", "Kindness is like moss, sprout. Slow... but in the end, it covers everything."],
	]
	for l in lines:
		if l[0] == ">":
			await say_player(l[1])
		else:
			var who: NPC = world.npcs[l[0]]
			who.script_mode = "talk"
			await say(who, l[1])
			who.script_mode = "idle"
	ui.close_dialogue()
	for id in order:
		(world.npcs[id] as NPC).script_mode = "dance"
	p.play_mode("dance", 14.0)
	var lanterns := _sky_lanterns(b)
	world.rig.override_pose = [b + Vector3(-12, 7, 10), b + Vector3(0, 3, 0)]
	await get_tree().create_timer(4.0).timeout
	world.rig.override_pose = [b + Vector3(10, 10, -6), b + Vector3(0, 4, 0)]
	await get_tree().create_timer(5.0).timeout
	await ui.title_card("The End", "...of the beginning. Life on Trollfjell goes on.\nThank you for playing!")
	Game.set_flag("festival_done")
	ui.hud.visible = true
	world.rig.override_pose = []
	for id in order:
		(world.npcs[id] as NPC).release_script()
	world.daynight.aurora_forced = false
	get_tree().create_timer(60.0).timeout.connect(func():
		if is_instance_valid(fire):
			fire.queue_free()
		if is_instance_valid(lanterns):
			lanterns.queue_free())
	world.cutscene = false
	p.busy = false
	Game.time_running = true
	Game.save_game()
	Sound.update_music()
	busy = false
	_festival_running = false


func _make_bonfire(b: Vector3) -> Node3D:
	var root := Node3D.new()
	world.add_child(root)
	root.global_position = b + Vector3(0, 0.6, 0)
	var f := CPUParticles3D.new()
	f.amount = 50
	f.lifetime = 1.1
	f.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	f.emission_sphere_radius = 0.7
	f.direction = Vector3.UP
	f.spread = 15.0
	f.initial_velocity_min = 2.0
	f.initial_velocity_max = 4.0
	f.gravity = Vector3(0, 1, 0)
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.85, 0.3))
	grad.set_color(1, Color(0.9, 0.25, 0.1))
	f.color_ramp = grad
	var m := BoxMesh.new()
	m.size = Vector3(0.3, 0.3, 0.3)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	m.material = mat
	f.mesh = m
	root.add_child(f)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.6, 0.3)
	l.light_energy = 3.0
	l.omni_range = 16.0
	l.position = Vector3(0, 1.5, 0)
	root.add_child(l)
	return root


func _sky_lanterns(b: Vector3) -> Node3D:
	var s := CPUParticles3D.new()
	world.add_child(s)
	s.global_position = b + Vector3(0, 2, 0)
	s.amount = 30
	s.lifetime = 12.0
	s.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	s.emission_box_extents = Vector3(10, 1, 10)
	s.direction = Vector3.UP
	s.spread = 8.0
	s.initial_velocity_min = 1.2
	s.initial_velocity_max = 2.0
	s.gravity = Vector3(0.2, 0.05, 0)
	var m := BoxMesh.new()
	m.size = Vector3(0.28, 0.36, 0.28)
	m.material = Mats.unshaded(Color(1.0, 0.72, 0.38))
	s.mesh = m
	return s
