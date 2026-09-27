class_name NPC
extends Interactable
## A villager or a troll. Humans follow a daily schedule through the village,
## and run away from the player while they are still afraid of trolls.

var id := ""
var data := {}
var is_human := false
var model: CharacterModel
var state := "idle" # idle, walk, flee, hidden, talk, script, hide_seek, backaway
var path: Array = []
var speed := 1.6
var anchor := ""
var wander := 0.0
var hide_until := -1.0
var face_dir := Vector3(0, 0, 1)
var _body: AnimatableBody3D
var _shape: CollisionShape3D
var _think := 0.0
var _wander_wait := 0.0
var _bark_cd := 0.0
var _waved_day := -1
var _scared_cd := 0.0
var _last_pos := Vector3.ZERO
var _speed_now := 0.0
var script_mode := "idle"
var seek_index := 0


func setup(npc_id: String, w: Node) -> void:
	id = npc_id
	world = w
	data = NpcDB.get_npc(id)
	is_human = data.get("kind", "") == "human"
	model = CharacterModel.new()
	if is_human:
		model.build_human(data["look"])
	else:
		model.build_troll(data["look"])
	add_child(model)
	_body = AnimatableBody3D.new()
	_body.sync_to_physics = false
	_body.collision_layer = 4
	_body.collision_mask = 0
	_shape = CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35 if is_human else 0.6 * float(data["look"].get("size", 1.0))
	cap.height = model.height
	_shape.shape = cap
	_shape.position = Vector3(0, model.height * 0.5, 0)
	_body.add_child(_shape)
	add_child(_body)
	radius = 1.3 if is_human else 1.8
	focus_height = model.height + 0.2
	prompt = "Talk"
	speed = 1.5 if is_human else 1.3


func display_name() -> String:
	return data.get("name", id)


func voice() -> float:
	return float(data.get("voice", 1.0))


func get_prompt() -> String:
	if state == "hide_seek":
		return "Found you!"
	if is_human and Game.trust_stage(id) == 0:
		return "Say hello"
	return "Talk to " + display_name()


func can_interact(_player: Node) -> bool:
	if state == "hidden" or state == "flee":
		return false
	return visible


func interact(player: Node) -> void:
	if state == "hide_seek":
		world.story.found_tussa(self)
		return
	world.story.talk(self)


# --------------------------------------------------------------------------
# schedule
# --------------------------------------------------------------------------
func scheduled() -> Array:
	var h := Game.minutes / 60.0
	var sched: Array = data.get("schedule", [])
	if sched.is_empty():
		return ["home", 0.0]
	if is_human and (h >= 24.0 or h < float(sched[0][0])):
		return ["home", 0.0]
	var cur: Array = sched[0]
	for e in sched:
		if h >= float(e[0]):
			cur = e
	return [cur[1], float(cur[2])]


func anchor_pos(a: String) -> Vector3:
	return world.anchor_position(a, id)


## Place directly at the current scheduled spot (used at load / new day).
func place_by_schedule() -> void:
	var s := scheduled()
	anchor = s[0]
	wander = s[1]
	path.clear()
	if is_human and anchor == "home":
		_set_hidden(true)
		global_position = anchor_pos("home")
		state = "hidden"
		hide_until = -1.0
		return
	_set_hidden(false)
	var p := anchor_pos(anchor)
	if wander > 0.5:
		p += Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * wander * 0.5
	p.y = world.ground_height(p.x, p.z)
	global_position = p
	state = "idle"
	_wander_wait = randf_range(1.0, 4.0)


func _set_hidden(h: bool) -> void:
	visible = not h
	if _shape:
		_shape.disabled = h


func go_to(p: Vector3, run := false) -> void:
	if is_human:
		path = world.nav_path(global_position, p)
	else:
		path = [p]
	speed = (4.6 if is_human else 5.0) if run else (1.5 if is_human else 1.3)
	state = "walk"


# --------------------------------------------------------------------------
# behaviour
# --------------------------------------------------------------------------
func start_flee() -> void:
	if state == "flee" or state == "hidden":
		return
	state = "flee"
	var door: Vector3 = anchor_pos("home")
	path = world.nav_path(global_position, door)
	speed = 4.8
	bark(NpcDB.pick(data.get("flee", ["AAH!"])), 2.4)
	Sound.sfx("scream", voice() * randf_range(0.9, 1.1), -4.0)
	hide_until = Game.minutes + randf_range(45.0, 80.0)
	world.on_human_fled(self)


func bark(text: String, seconds := 2.5) -> void:
	world.show_bark(self, text.replace("{name}", Game.player_name), seconds)
	_bark_cd = seconds + 3.0


func begin_talk(player: Node3D) -> void:
	state = "talk"
	path.clear()
	_face(player.global_position, 1.0)


func end_talk() -> void:
	if state == "talk":
		state = "idle"
		_wander_wait = randf_range(2.0, 5.0)


func _face(p: Vector3, t: float) -> void:
	var d := p - global_position
	d.y = 0
	if d.length() < 0.01:
		return
	_turn_to(d, t)


func _turn_to(d: Vector3, t: float) -> void:
	var yaw := lerp_angle(model.rotation.y, atan2(d.x, d.z), clampf(t, 0.0, 1.0))
	model.rotation.y = yaw
	face_dir = Vector3(sin(yaw), 0, cos(yaw))


func _physics_process(delta: float) -> void:
	if world == null:
		return
	_bark_cd -= delta
	_think -= delta
	var player: Node3D = world.player
	var to_player := player.global_position - global_position if player else Vector3(999, 0, 999)
	var pdist := Vector2(to_player.x, to_player.z).length()
	match state:
		"hidden":
			if _think <= 0.0:
				_think = 1.0
				var s := scheduled()
				if s[0] != "home" and Game.minutes >= hide_until and not world.is_cutscene():
					# only come out when the troll isn't right at the door
					if not is_human or Game.trust_stage(id) > 0 or pdist > 12.0:
						_emerge(s)
			return
		"script":
			model.set_mode(script_mode)
			model.animate(delta, 0.0 if script_mode != "walk" else 1.4)
			return
		"hide_seek":
			model.set_mode("cower")
			model.animate(delta, 0.0)
			return
		"talk":
			_face(player.global_position, delta * 8.0)
			model.set_mode("talk" if world.is_speaking(self) else "idle")
			model.animate(delta, 0.0)
			return
	# react to the troll
	if is_human and Game.playing and not world.is_cutscene() and player:
		var stage := Game.trust_stage(id)
		if stage == 0 and state != "flee" and pdist < 7.5 and not world.player.busy:
			start_flee()
		elif stage == 1 and state != "flee":
			_scared_cd -= delta
			if pdist < 3.6:
				if _scared_cd <= 0.0:
					_scared_cd = 5.0
					if _bark_cd <= 0.0:
						bark(NpcDB.pick(data.get("scared", ["Eep!"])), 2.4)
				model.tremble(1.0)
			else:
				model.tremble(0.0)
		elif stage >= 4 and pdist < 7.0 and _waved_day != Game.day and state != "flee":
			_waved_day = Game.day
			bark(NpcDB.pick(["Hi, {name}!", "Hello, {name}!", "Oh! {name}! Hello!", "Good to see you, {name}!"]), 2.0)
			model.set_mode("wave")
	# schedule changes
	if _think <= 0.0 and state != "flee":
		_think = 1.0
		var s2 := scheduled()
		if s2[0] != anchor:
			anchor = s2[0]
			wander = s2[1]
			go_to(anchor_pos(anchor))
	# movement
	var moving := false
	if (state == "walk" or state == "flee") and not path.is_empty():
		var tgt: Vector3 = path[0]
		var d := tgt - global_position
		d.y = 0
		var step := speed * delta
		if d.length() <= step + 0.05:
			global_position = Vector3(tgt.x, global_position.y, tgt.z)
			path.pop_front()
		else:
			var dir := d.normalized()
			global_position += dir * step
			_turn_to(dir, delta * 10.0)
		moving = true
		global_position.y = world.ground_height(global_position.x, global_position.z)
		if path.is_empty():
			_arrived()
	elif state == "idle":
		# stand still facing the troll if they're friendly and near
		if pdist < 5.0 and (not is_human or Game.trust_stage(id) >= 2):
			_face(player.global_position, delta * 4.0)
		elif is_human and Game.trust_stage(id) == 1 and pdist < 6.0:
			_face(player.global_position, delta * 4.0)
		else:
			_wander_wait -= delta
			if _wander_wait <= 0.0 and wander > 0.4:
				_wander_wait = randf_range(3.0, 8.0)
				var base := anchor_pos(anchor)
				var off := Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() * randf_range(0.3, 1.0) * wander
				var p := base + off
				if world.is_free_spot(p.x, p.z):
					path = [p]
					speed = 1.2 if is_human else 1.0
					state = "walk"
	var hs := (global_position - _last_pos).length() / maxf(delta, 0.001)
	_last_pos = global_position
	_speed_now = lerpf(_speed_now, hs if moving else 0.0, clampf(delta * 10.0, 0.0, 1.0))
	if state == "flee":
		model.set_mode("flee")
	elif model.mode == "wave" and _bark_cd > 0.5:
		pass
	elif is_human and Game.trust_stage(id) == 1 and pdist < 3.6:
		model.set_mode("cower")
	elif id == "gubben" and not moving:
		model.set_mode("sleep" if Game.is_night() else "sit")
	else:
		model.set_mode("idle")
	model.animate(delta, _speed_now)


func _arrived() -> void:
	if state == "flee" or (is_human and anchor == "home"):
		_set_hidden(true)
		state = "hidden"
		_think = 2.0
		model.tremble(0.0)
		return
	state = "idle"
	_wander_wait = randf_range(2.0, 6.0)


func _emerge(s: Array) -> void:
	anchor = s[0]
	wander = s[1]
	var door := anchor_pos("home")
	global_position = Vector3(door.x, world.ground_height(door.x, door.z), door.z)
	_set_hidden(false)
	state = "idle"
	go_to(anchor_pos(anchor))


## Put the NPC under story control at a position.
func script_place(p: Vector3, look_at_pos: Vector3, mode_name := "idle") -> void:
	state = "script"
	script_mode = mode_name
	path.clear()
	_set_hidden(false)
	global_position = Vector3(p.x, world.ground_height(p.x, p.z), p.z)
	face_dir = (look_at_pos - global_position)
	face_dir.y = 0
	if face_dir.length() > 0.01:
		face_dir = face_dir.normalized()
		model.rotation.y = atan2(face_dir.x, face_dir.z)


func release_script() -> void:
	if state == "script":
		state = "idle"
		place_by_schedule()
