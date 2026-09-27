class_name Animal
extends Interactable
## Goats and sheep at Lars' farm. Bukken the goat is the star of a story task.

const PEN_MIN := Vector2(-58.5, 48.5)
const PEN_MAX := Vector2(-45.5, 55.5)

var species := "goat"
var is_bukken := false
var model: CharacterModel
var state := "pen" # pen, ledge, follow
var _target := Vector3.ZERO
var _wait := 0.0
var _speed_now := 0.0
var _last := Vector3.ZERO
var _t := 0.0


func setup(sp: String, w: Node, bukken := false) -> void:
	species = sp
	world = w
	is_bukken = bukken
	model = CharacterModel.new()
	if sp == "goat":
		var cols := [Color(0.92, 0.9, 0.86), Color(0.55, 0.4, 0.28), Color(0.3, 0.26, 0.24)]
		model.build_goat(Color(0.95, 0.93, 0.88) if bukken else cols[randi() % cols.size()], bukken)
	else:
		model.build_sheep()
	add_child(model)
	radius = 1.0
	focus_height = 1.3
	_wait = randf_range(0.5, 3.0)


func get_prompt() -> String:
	if is_bukken and state == "ledge":
		return "Call Bukken"
	if is_bukken and state == "follow":
		return "Pat Bukken"
	return "Pet the " + species


func refresh() -> void:
	if not is_bukken:
		return
	var q := "m6_goat"
	if Game.is_active(q) and not Game.has_flag("goat_found"):
		_set_state("ledge")
	elif Game.is_active(q) and Game.has_flag("goat_found") and not Game.has_flag("goat_home"):
		_set_state("follow")
	else:
		_set_state("pen")


func _set_state(s: String) -> void:
	if s == state and _target != Vector3.ZERO:
		return
	state = s
	match s:
		"pen":
			if not _in_pen(global_position):
				var p := Vector3(randf_range(PEN_MIN.x, PEN_MAX.x), 0, randf_range(PEN_MIN.y, PEN_MAX.y))
				p.y = world.ground_height(p.x, p.z)
				global_position = p
			_target = global_position
		"ledge":
			var a: Vector3 = world.anchor_position("goat_ledge", "")
			global_position = a
			_target = a
		"follow":
			var pl: Node3D = world.player
			if pl and global_position.distance_to(pl.global_position) > 20.0:
				global_position = pl.global_position + Vector3(2, 0, 2)
				global_position.y = world.ground_height(global_position.x, global_position.z)
			_target = global_position


func _in_pen(p: Vector3) -> bool:
	return p.x > PEN_MIN.x - 0.5 and p.x < PEN_MAX.x + 0.5 and p.z > PEN_MIN.y - 0.5 and p.z < PEN_MAX.y + 0.5


func interact(player: Node) -> void:
	Sound.sfx("bleat" if species == "goat" else "baa", randf_range(0.9, 1.2) * (0.85 if is_bukken else 1.0))
	if is_bukken and state == "ledge":
		Game.set_flag("goat_found")
		_set_state("follow")
		world.show_bark(self, "Meh!", 1.8)
		world.show_bark(player, "Come on, Bukken! Let's go home.", 2.6)
		return
	world.show_bark(self, "Meh!" if species == "goat" else "Baa!", 1.4)
	world.spawn_puff(global_position + Vector3(0, 1.2, 0), Color(1.0, 0.6, 0.7))


func _physics_process(delta: float) -> void:
	if world == null:
		return
	_t += delta
	var moving := false
	var spd := 0.9
	match state:
		"pen", "ledge":
			_wait -= delta
			if _wait <= 0.0:
				_wait = randf_range(2.0, 6.0)
				if state == "pen":
					_target = Vector3(randf_range(PEN_MIN.x, PEN_MAX.x), 0, randf_range(PEN_MIN.y, PEN_MAX.y))
				else:
					var a: Vector3 = world.anchor_position("goat_ledge", "")
					_target = a + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
		"follow":
			var pl: Node3D = world.player
			var d := pl.global_position - global_position
			d.y = 0
			if d.length() > 2.6:
				_target = pl.global_position - d.normalized() * 2.2
				spd = clampf(d.length() * 1.2, 1.0, 7.5)
			else:
				_target = global_position
			if _in_pen(global_position):
				Game.set_flag("goat_home")
				_set_state("pen")
				world.show_bark(self, "Meeeh!", 2.0)
				Sound.sfx("bleat", 1.0)
			elif d.length() > 40.0:
				global_position = pl.global_position - d.normalized() * 3.0
	var to := _target - global_position
	to.y = 0
	if to.length() > 0.15:
		var dir := to.normalized()
		global_position += dir * minf(spd * delta, to.length())
		model.rotation.y = lerp_angle(model.rotation.y, atan2(dir.x, dir.z), clampf(delta * 8.0, 0, 1))
		moving = true
	global_position.y = world.ground_height(global_position.x, global_position.z)
	var hs := (global_position - _last).length() / maxf(delta, 0.001)
	_last = global_position
	_speed_now = lerpf(_speed_now, hs if moving else 0.0, clampf(delta * 8.0, 0.0, 1.0))
	model.set_mode("graze" if not moving and fmod(_t, 7.0) < 4.0 else "idle")
	model.animate(delta, _speed_now)
