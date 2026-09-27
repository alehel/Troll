extends Node
## Global game state: time, inventory, relationships, quests, flags and saving.

signal inventory_changed
signal notify(text: String, icon: String)
signal trust_changed(id: String, value: float, delta: float)
signal friendship_changed(id: String, value: float)
signal quest_changed(id: String)
signal quest_completed(id: String)
signal flag_changed(flag: String)
signal day_started(day: int)
signal settings_changed

const SAVE_PATH := "user://savegame.json"
const SETTINGS_PATH := "user://settings.cfg"
const DAY_START := 360.0 # 06:00
const DAY_END := 1560.0 # 02:00 the next night
const MINUTES_PER_SECOND := 1.25

const STAGE_NAMES := ["Terrified", "Scared", "Wary", "Curious", "Friendly", "Friend"]
const STAGE_MIN := [0.0, 15.0, 35.0, 55.0, 75.0, 90.0]
const STAGE_ICONS := ["face_terrified", "face_scared", "face_wary", "face_curious", "face_friendly", "face_friend"]

var player_name := "Mose"
var day := 1
var minutes := DAY_START
var time_running := false
var inventory := {}
var trust := {}
var friendship := {}
var flags := {}
var counters := {}
var quests := {}
var known_recipes: Array = []
var gifted_today := {}
var talked_today := {}
var doorstep := {}
var events_today: Array = []
var picked := {}
var cleaned := {}
## Daily favours: [{npc, item, n, done, asked}]
var requests: Array = []
var player_pos := Vector3.ZERO
var player_yaw := 0.0
var has_player_pos := false
var playing := false

var settings := {
	"music": 0.7,
	"sfx": 0.8,
	"render_scale": 0.75,
	"dither": true,
	"fullscreen": false,
	"text_speed": 1.0,
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	load_settings()
	new_game()


# --------------------------------------------------------------------------
# Input
# --------------------------------------------------------------------------
func _key(action: String, keys: Array, joy_buttons: Array = [], axes: Array = []) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.25)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)
	for b in joy_buttons:
		var j := InputEventJoypadButton.new()
		j.button_index = b
		InputMap.action_add_event(action, j)
	for a in axes:
		var m := InputEventJoypadMotion.new()
		m.axis = a[0]
		m.axis_value = a[1]
		InputMap.action_add_event(action, m)


func _setup_input() -> void:
	_key("move_left", [KEY_A, KEY_LEFT], [JOY_BUTTON_DPAD_LEFT], [[JOY_AXIS_LEFT_X, -1.0]])
	_key("move_right", [KEY_D, KEY_RIGHT], [JOY_BUTTON_DPAD_RIGHT], [[JOY_AXIS_LEFT_X, 1.0]])
	_key("move_forward", [KEY_W, KEY_UP], [JOY_BUTTON_DPAD_UP], [[JOY_AXIS_LEFT_Y, -1.0]])
	_key("move_back", [KEY_S, KEY_DOWN], [JOY_BUTTON_DPAD_DOWN], [[JOY_AXIS_LEFT_Y, 1.0]])
	_key("run", [KEY_SHIFT], [JOY_BUTTON_RIGHT_SHOULDER, JOY_BUTTON_B])
	_key("interact", [KEY_E, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER], [JOY_BUTTON_A])
	_key("cancel", [KEY_BACKSPACE, KEY_Q], [JOY_BUTTON_B])
	_key("inventory", [KEY_TAB, KEY_I], [JOY_BUTTON_Y])
	_key("journal", [KEY_J], [JOY_BUTTON_X])
	_key("pause", [KEY_ESCAPE], [JOY_BUTTON_START])
	_key("cam_left", [KEY_Z, KEY_COMMA], [JOY_BUTTON_LEFT_SHOULDER], [[JOY_AXIS_RIGHT_X, -1.0]])
	_key("cam_right", [KEY_C, KEY_PERIOD], [], [[JOY_AXIS_RIGHT_X, 1.0]])
	_key("zoom_in", [KEY_EQUAL, KEY_KP_ADD])
	_key("zoom_out", [KEY_MINUS, KEY_KP_SUBTRACT])
	_key("tilt_up", [KEY_PAGEUP, KEY_R], [], [[JOY_AXIS_RIGHT_Y, -1.0]])
	_key("tilt_down", [KEY_PAGEDOWN, KEY_F], [], [[JOY_AXIS_RIGHT_Y, 1.0]])
	_key("fullscreen", [KEY_F11])
	_key("ui_tab_next", [KEY_E, KEY_RIGHT, KEY_D], [JOY_BUTTON_RIGHT_SHOULDER])
	_key("ui_tab_prev", [KEY_Q, KEY_LEFT, KEY_A], [JOY_BUTTON_LEFT_SHOULDER])


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("fullscreen"):
		settings["fullscreen"] = not settings["fullscreen"]
		apply_settings()
		save_settings()


# --------------------------------------------------------------------------
# New game / time
# --------------------------------------------------------------------------
func new_game() -> void:
	day = 1
	minutes = DAY_START + 60.0 # wake at 07:00 on the first day
	inventory = {}
	trust = {}
	friendship = {}
	for id in NpcDB.humans():
		trust[id] = 0.0
	for id in NpcDB.trolls():
		friendship[id] = 20.0
	flags = {}
	counters = {}
	quests = {}
	known_recipes = []
	gifted_today = {}
	talked_today = {}
	doorstep = {}
	events_today = []
	picked = {}
	cleaned = {}
	requests = []
	has_player_pos = false
	player_name = "Mose"


func _process(delta: float) -> void:
	if time_running and playing:
		minutes += delta * MINUTES_PER_SECOND
		if minutes >= DAY_END:
			minutes = DAY_END
			flags["passed_out"] = true
			emit_signal("flag_changed", "passed_out")


func hour() -> float:
	return fmod(minutes / 60.0, 24.0)


func clock_text() -> String:
	var total := int(minutes)
	var h := (total / 60) % 24
	var m := (total % 60) / 10 * 10
	return "%02d:%02d" % [h, m]


func is_night() -> bool:
	var h := minutes / 60.0
	return h >= 21.0 or h < 6.0


func is_late() -> bool:
	return minutes / 60.0 >= 20.0


func weekday_name() -> String:
	var names := ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
	return names[(day - 1) % 7]


## Called when the troll sleeps. Resolves overnight events and starts a new day.
func advance_day() -> Array:
	var report: Array = []
	# doorstep gifts are found in the morning
	for id in doorstep.keys():
		var item: String = doorstep[id]
		var pref := NpcDB.preference(id, item)
		var gain: float = {"love": 10.0, "like": 6.0, "neutral": 3.0, "dislike": 1.0}[pref]
		var before := trust_stage(id)
		add_trust(id, gain, false)
		report.append({"type": "doorstep", "npc": id, "item": item, "pref": pref, "stage_up": trust_stage(id) > before})
	doorstep = {}
	for e in events_today:
		report.append(e)
	events_today = []
	gifted_today = {}
	talked_today = {}
	cleaned = {}
	day += 1
	minutes = DAY_START
	generate_requests()
	flags.erase("passed_out")
	counters["litter_yesterday"] = counter("litter_today")
	counters["litter_today"] = 0
	has_player_pos = false
	emit_signal("day_started", day)
	check_quests()
	return report


func log_event(e: Dictionary) -> void:
	events_today.append(e)


const TROLL_REWARDS := {"granny": "waffle", "stein": "crystal", "tussa": "feather", "lyng": "heather_tea", "gubben": "dried_fish"}


## Pick one or two friends who would like a favour today.
func generate_requests() -> void:
	requests = []
	if day < 2:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = day * 92821 + 17
	var candidates: Array = []
	for id in NpcDB.trolls():
		candidates.append(id)
	for id in NpcDB.humans():
		if trust_stage(id) >= 3:
			candidates.append(id)
	var count := 1 if day < 4 else 2
	for i in range(count):
		if candidates.is_empty():
			break
		var who: String = candidates[rng.randi() % candidates.size()]
		candidates.erase(who)
		var pool: Array = []
		for it in NpcDB.NPCS[who].get("loves", []) + NpcDB.NPCS[who].get("likes", []):
			var cat := ItemDB.category(it)
			if cat == "forage" or (cat == "crafted" and known_recipes.has(it)):
				pool.append(it)
		if pool.is_empty():
			continue
		var item: String = pool[rng.randi() % pool.size()]
		var n := 1 if ItemDB.category(item) == "crafted" or item in ["crystal", "cloudberry"] else rng.randi_range(2, 3)
		requests.append({"npc": who, "item": item, "n": n, "done": false, "asked": false})


func request_for(npc_id: String) -> Dictionary:
	for r in requests:
		if r["npc"] == npc_id and not r["done"]:
			return r
	return {}


func request_text(r: Dictionary) -> String:
	return "%s would like %s." % [NpcDB.name_of(r["npc"]), ItemDB.count_name(r["item"], int(r["n"]))]


# --------------------------------------------------------------------------
# Inventory
# --------------------------------------------------------------------------
func add_item(id: String, n := 1, silent := false) -> void:
	inventory[id] = int(inventory.get(id, 0)) + n
	emit_signal("inventory_changed")
	if not silent:
		emit_signal("notify", "+ " + ItemDB.count_name(id, n), id)
	check_quests()


func remove_item(id: String, n := 1) -> bool:
	var have := int(inventory.get(id, 0))
	if have < n:
		return false
	have -= n
	if have <= 0:
		inventory.erase(id)
	else:
		inventory[id] = have
	emit_signal("inventory_changed")
	check_quests()
	return true


func count(id: String) -> int:
	return int(inventory.get(id, 0))


func has_items(needs: Dictionary) -> bool:
	for k in needs.keys():
		if count(k) < int(needs[k]):
			return false
	return true


func take_items(needs: Dictionary) -> bool:
	if not has_items(needs):
		return false
	for k in needs.keys():
		remove_item(k, int(needs[k]))
	return true


func sorted_inventory() -> Array:
	var order := {"quest": 0, "crafted": 1, "treat": 2, "forage": 3}
	var ids := inventory.keys()
	ids.sort_custom(func(a, b):
		var ca: int = order.get(ItemDB.category(a), 9)
		var cb: int = order.get(ItemDB.category(b), 9)
		if ca != cb:
			return ca < cb
		return ItemDB.name_of(a) < ItemDB.name_of(b))
	return ids


func learn_recipe(id: String) -> void:
	if not known_recipes.has(id):
		known_recipes.append(id)
		emit_signal("notify", "New recipe: " + ItemDB.name_of(id), id)


# --------------------------------------------------------------------------
# Relationships
# --------------------------------------------------------------------------
func get_trust(id: String) -> float:
	return float(trust.get(id, 0.0))


func add_trust(id: String, amount: float, announce := true) -> void:
	var mult := NpcDB.trust_multiplier(id)
	var before := get_trust(id)
	var stage_before := trust_stage(id)
	var v := clampf(before + amount * mult, 0.0, 100.0)
	trust[id] = v
	emit_signal("trust_changed", id, v, v - before)
	var stage_after := trust_stage(id)
	if announce and stage_after > stage_before:
		emit_signal("notify", "%s now feels %s" % [NpcDB.name_of(id), STAGE_NAMES[stage_after].to_lower()], STAGE_ICONS[stage_after])
	check_quests()


## Spread a bit of goodwill over every villager.
func add_village_trust(amount: float) -> void:
	for id in NpcDB.humans():
		add_trust(id, amount, false)


func trust_stage(id: String) -> int:
	var t := get_trust(id)
	var s := 0
	for i in range(STAGE_MIN.size()):
		if t >= STAGE_MIN[i]:
			s = i
	return s


func village_trust() -> float:
	var ids := NpcDB.humans()
	if ids.is_empty():
		return 0.0
	var total := 0.0
	for id in ids:
		total += get_trust(id)
	return total / ids.size()


func village_mood_name() -> String:
	var v := village_trust()
	if v < 12:
		return "Panicked"
	if v < 28:
		return "Nervous"
	if v < 45:
		return "Whispering"
	if v < 62:
		return "Curious"
	if v < 80:
		return "Warming up"
	return "Welcoming"


func get_friendship(id: String) -> float:
	return float(friendship.get(id, 0.0))


func add_friendship(id: String, amount: float) -> void:
	var v := clampf(get_friendship(id) + amount, 0.0, 100.0)
	friendship[id] = v
	emit_signal("friendship_changed", id, v)
	check_quests()


func hearts(id: String) -> int:
	if NpcDB.is_human(id):
		return int(floor(get_trust(id) / 10.0))
	return int(floor(get_friendship(id) / 10.0))


# --------------------------------------------------------------------------
# Flags & counters
# --------------------------------------------------------------------------
func set_flag(f: String, value: Variant = true) -> void:
	flags[f] = value
	emit_signal("flag_changed", f)
	check_quests()


func has_flag(f: String) -> bool:
	return flags.has(f) and flags[f] != false


func inc(counter: String, n := 1) -> void:
	counters[counter] = int(counters.get(counter, 0)) + n
	check_quests()


func counter(c: String) -> int:
	return int(counters.get(c, 0))


# --------------------------------------------------------------------------
# Quests
# --------------------------------------------------------------------------
func quest_state(id: String) -> String:
	return quests.get(id, {}).get("state", "")


func is_active(id: String) -> bool:
	return quest_state(id) == "active"


func is_done(id: String) -> bool:
	return quest_state(id) == "done"


func quest_step(id: String) -> int:
	return int(quests.get(id, {}).get("step", 0))


func current_step(id: String) -> Dictionary:
	var q: Dictionary = QuestDB.get_quest(id)
	var steps: Array = q.get("steps", [])
	var s := quest_step(id)
	if s < steps.size():
		return steps[s]
	return {}


func start_quest(id: String) -> void:
	if quests.has(id):
		return
	quests[id] = {"state": "active", "step": 0}
	var q := QuestDB.get_quest(id)
	emit_signal("notify", "New task: " + q.get("title", id), "book")
	emit_signal("quest_changed", id)
	_run_actions(QuestDB.get_quest(id).get("on_start", []))
	_run_actions(current_step(id).get("on_enter", []))
	check_quests()


func advance_quest(id: String) -> void:
	if not is_active(id):
		return
	var step := current_step(id)
	_run_actions(step.get("on_done", []))
	var q := QuestDB.get_quest(id)
	var s := quest_step(id) + 1
	quests[id]["step"] = s
	if s >= q.get("steps", []).size():
		quests[id]["state"] = "done"
		_run_actions(q.get("on_complete", []))
		emit_signal("notify", "Task complete: " + q.get("title", id), "heart")
		emit_signal("quest_changed", id)
		emit_signal("quest_completed", id)
		Sound.sfx("quest")
	else:
		emit_signal("quest_changed", id)
		_run_actions(current_step(id).get("on_enter", []))
	check_quests()


var _checking := false


## Automatic quest progression: steps whose goal is met advance by themselves,
## and quests with an "auto" start condition begin on their own.
func check_quests() -> void:
	if _checking or not playing:
		return
	_checking = true
	var changed := true
	var guard := 0
	while changed and guard < 20:
		changed = false
		guard += 1
		for id in QuestDB.QUESTS.keys():
			var q: Dictionary = QuestDB.QUESTS[id]
			if not quests.has(id):
				if q.has("auto") and cond_met(q["auto"]):
					quests[id] = {"state": "active", "step": 0}
					emit_signal("notify", "New task: " + q.get("title", id), "book")
					emit_signal("quest_changed", id)
					_run_actions(q.get("on_start", []))
					_run_actions(current_step(id).get("on_enter", []))
					changed = true
				continue
			if not is_active(id):
				continue
			var step := current_step(id)
			if step.has("goal") and not step.has("turn_in") and cond_met(step["goal"]):
				_checking = false
				advance_quest(id)
				_checking = true
				changed = true
	_checking = false


func cond_met(c: Dictionary) -> bool:
	for k in c.keys():
		var v: Variant = c[k]
		match k:
			"have":
				if not has_items(v):
					return false
			"flag":
				if not has_flag(v):
					return false
			"not_flag":
				if has_flag(v):
					return false
			"trust":
				if get_trust(v[0]) < float(v[1]):
					return false
			"stage":
				if trust_stage(v[0]) < int(v[1]):
					return false
			"friendship":
				if get_friendship(v[0]) < float(v[1]):
					return false
			"village":
				if village_trust() < float(v):
					return false
			"counter":
				if counter(v[0]) < int(v[1]):
					return false
			"quest_done":
				if not is_done(v):
					return false
			"quest_active":
				if not is_active(v):
					return false
			"day":
				if day < int(v):
					return false
			"stage_all":
				for id in NpcDB.humans():
					if trust_stage(id) < int(v):
						return false
			"recipe":
				if not known_recipes.has(v):
					return false
			"hour_min":
				if minutes / 60.0 < float(v):
					return false
			"all":
				for sub in v:
					if not cond_met(sub):
						return false
			"any":
				var ok := false
				for sub in v:
					if cond_met(sub):
						ok = true
						break
				if not ok:
					return false
	return true


func _run_actions(actions: Array) -> void:
	for a in actions:
		var act: Dictionary = a
		for k in act.keys():
			var v: Variant = act[k]
			match k:
				"give":
					for item in v.keys():
						add_item(item, int(v[item]))
				"take":
					for item in v.keys():
						remove_item(item, int(v[item]))
				"flag":
					set_flag(v)
				"recipe":
					learn_recipe(v)
				"trust":
					add_trust(v[0], float(v[1]))
				"village_trust":
					add_village_trust(float(v))
				"friendship":
					add_friendship(v[0], float(v[1]))
				"start":
					start_quest(v)
				"notify":
					emit_signal("notify", v, "book")


## Active quests sorted: main story first.
func active_quests() -> Array:
	var out: Array = []
	for id in QuestDB.ORDER:
		if is_active(id):
			out.append(id)
	return out


func tracked_objective() -> String:
	var act := active_quests()
	if act.is_empty():
		for r in requests:
			if not r["done"]:
				return "Favour: " + request_text(r)
		return ""
	var id: String = act[0]
	var step := current_step(id)
	return step.get("text", "")


# --------------------------------------------------------------------------
# Saving
# --------------------------------------------------------------------------
func to_dict() -> Dictionary:
	return {
		"version": 1,
		"player_name": player_name,
		"day": day,
		"minutes": minutes,
		"inventory": inventory,
		"trust": trust,
		"friendship": friendship,
		"flags": flags,
		"counters": counters,
		"quests": quests,
		"known_recipes": known_recipes,
		"gifted_today": gifted_today,
		"talked_today": talked_today,
		"doorstep": doorstep,
		"events_today": events_today,
		"picked": picked,
		"cleaned": cleaned,
		"requests": requests,
		"player_pos": [player_pos.x, player_pos.y, player_pos.z],
		"player_yaw": player_yaw,
		"has_player_pos": has_player_pos,
	}


func from_dict(d: Dictionary) -> void:
	new_game()
	player_name = d.get("player_name", "Mose")
	day = int(d.get("day", 1))
	minutes = float(d.get("minutes", DAY_START))
	inventory = _int_dict(d.get("inventory", {}))
	for k in d.get("trust", {}).keys():
		trust[k] = float(d["trust"][k])
	for k in d.get("friendship", {}).keys():
		friendship[k] = float(d["friendship"][k])
	flags = d.get("flags", {})
	counters = _int_dict(d.get("counters", {}))
	quests = {}
	var qd: Dictionary = d.get("quests", {})
	for k in qd.keys():
		quests[k] = {"state": qd[k].get("state", "active"), "step": int(qd[k].get("step", 0))}
	known_recipes = d.get("known_recipes", [])
	gifted_today = d.get("gifted_today", {})
	talked_today = d.get("talked_today", {})
	doorstep = d.get("doorstep", {})
	events_today = d.get("events_today", [])
	picked = {}
	var pk: Dictionary = d.get("picked", {})
	for k in pk.keys():
		picked[k] = int(pk[k])
	cleaned = d.get("cleaned", {})
	requests = []
	for r in d.get("requests", []):
		requests.append({"npc": r.get("npc", ""), "item": r.get("item", ""), "n": int(r.get("n", 1)),
			"done": bool(r.get("done", false)), "asked": bool(r.get("asked", false))})
	var p: Array = d.get("player_pos", [0, 0, 0])
	player_pos = Vector3(p[0], p[1], p[2])
	player_yaw = float(d.get("player_yaw", 0.0))
	has_player_pos = bool(d.get("has_player_pos", false))


func _int_dict(src: Dictionary) -> Dictionary:
	var out := {}
	for k in src.keys():
		out[k] = int(src[k])
	return out


func save_game() -> bool:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Could not save the game")
		return false
	f.store_string(JSON.stringify(to_dict(), "\t"))
	f.close()
	return true


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var data: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return false
	from_dict(data)
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


# --------------------------------------------------------------------------
# Settings
# --------------------------------------------------------------------------
func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(SETTINGS_PATH) == OK:
		for k in settings.keys():
			settings[k] = cf.get_value("settings", k, settings[k])
	apply_settings()


func save_settings() -> void:
	var cf := ConfigFile.new()
	for k in settings.keys():
		cf.set_value("settings", k, settings[k])
	cf.save(SETTINGS_PATH)


func apply_settings() -> void:
	if DisplayServer.get_name() != "headless":
		var want_fs: bool = settings["fullscreen"]
		var mode := DisplayServer.window_get_mode()
		var is_fs := mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		if want_fs and not is_fs:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		elif not want_fs and is_fs:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	emit_signal("settings_changed")
