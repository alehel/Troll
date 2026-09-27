class_name Boulder
extends Interactable
## Rockslide boulder on the east road. Needs the Troll Lift.

var index := 0
var _mesh: MeshInstance3D
var _body: StaticBody3D
var busy := false


func setup(i: int) -> void:
	index = i
	prompt = "Lift boulder"
	radius = 2.0
	focus_height = 2.4
	var k := MeshKit.new(5000 + i)
	k.jitter = 0.03
	k.blob(Vector3(0, 0.9, 0), Vector3(1.5, 1.25, 1.35), Color(0.55, 0.53, 0.5), 4, 8, 0.2, true)
	_mesh = MeshInstance3D.new()
	_mesh.mesh = k.commit()
	_mesh.material_override = Mats.world(0.0, 0.0)
	add_child(_mesh)
	_body = StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 1.4
	cs.shape = sh
	cs.position = Vector3(0, 0.9, 0)
	_body.add_child(cs)
	add_child(_body)
	rotation.y = i * 1.3


func get_prompt() -> String:
	if Game.has_flag("troll_lift"):
		return "Lift boulder"
	return "Push boulder"


func can_interact(_p: Node) -> bool:
	return not busy and visible


var _over := Vector3.ZERO
var _dest := Vector3.ZERO
var _player: Player


func interact(player: Node) -> void:
	var p := player as Player
	if not Game.has_flag("troll_lift"):
		p.play_mode("shake", 1.0)
		Sound.sfx("thud", 0.7)
		world.show_bark(p, NpcDB.pick(["Hnnnngh! It won't budge!", "Oof! Too heavy... Maybe Stein knows a trick.", "Nope. This rock is very attached to this road."]), 2.6)
		return
	busy = true
	_player = p
	p.busy = true
	p.play_mode("lift", 0.6)
	Sound.sfx("lift", 0.8)
	_over = p.global_position + Vector3(0, 2.8, 0)
	_dest = Vector3(global_position.x + randf_range(-3, 3), -3.0, 76.0 + randf_range(0, 6))
	var tw := create_tween()
	tw.tween_property(self, "global_position", _over, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(_start_carry)
	tw.tween_interval(0.5)
	tw.tween_method(_fly, 0.0, 1.0, 1.4)
	tw.tween_callback(_landed)


func _start_carry() -> void:
	_player.carrying = true


func _fly(t: float) -> void:
	var q := _over.lerp(_dest, t)
	q.y = lerpf(_over.y, _dest.y, t) + sin(t * PI) * 6.0
	global_position = q
	rotation.x = t * 6.0


func _landed() -> void:
	_player.carrying = false
	_player.busy = false
	Sound.sfx("splash", 0.8)
	world.spawn_splash(Vector3(_dest.x, 0.2, _dest.z))
	Game.set_flag("boulder_%d" % index)
	Game.inc("boulders")
	if randf() < 0.6:
		Game.add_item("pretty_stone")
	Game.add_village_trust(0.8)
	visible = false
	queue_free()
