extends Node
## Walks the troll along the main routes using real movement input and checks
## that every leg can be completed (no blocked paths, no impossible slopes).
##   godot --path . -- --walktest

var main: Node
var world: World
var failures: Array = []

const ROUTES := {
	"village_to_plateau": [Vector2(-3, 40), Vector2(-7, 37), Vector2(-9.5, 27), Vector2(-7, 16), Vector2(3, 0), Vector2(0, -14), Vector2(-6, -28),
		Vector2(-9, -40), Vector2(-18, -49), Vector2(-27, -58), Vector2(-25, -69), Vector2(-21, -74)],
	"ring_to_homes": [Vector2(-22, -80), Vector2(-29, -90), Vector2(-33, -99), Vector2(-29, -90), Vector2(-23, -81),
		Vector2(-10, -85), Vector2(-4, -88), Vector2(7, -97), Vector2(13, -101), Vector2(7, -97), Vector2(19, -93),
		Vector2(23, -91)],
	"stein": [Vector2(-22, -80), Vector2(-40, -79), Vector2(-52, -81)],
	"bridge_and_glade": [Vector2(3, 0), Vector2(2, -4), Vector2(18, -10), Vector2(34, -12), Vector2(50, -15), Vector2(60, -19), Vector2(56, -28)],
	"village_loop": [Vector2(-3, 40), Vector2(-6, 41), Vector2(-12, 39), Vector2(-6, 44), Vector2(-26, 42), Vector2(-44, 41),
		Vector2(-47, 47), Vector2(-44, 41), Vector2(-26, 42), Vector2(-5, 49), Vector2(-19, 53), Vector2(-5, 49),
		Vector2(3, 50), Vector2(8, 60), Vector2(20, 58), Vector2(8, 60), Vector2(9, 68), Vector2(9, 83)],
	"east_road": [Vector2(6, 45), Vector2(24, 46), Vector2(48, 42), Vector2(72, 46), Vector2(100, 50)],
	"to_bog_and_hat": [Vector2(-22, -80), Vector2(-40, -79), Vector2(-50, -90), Vector2(-62, -100), Vector2(-50, -90), Vector2(-42, -78), Vector2(-45, -65), Vector2(-48, -62)],
	"kite_tree": [Vector2(-6, -28), Vector2(-14, -27), Vector2(-20, -26)],
}


func run(m: Node) -> void:
	main = m
	world = m.world
	await _go()


func wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _go() -> void:
	main.show_title()
	await wait(0.5)
	main._start_new("Tester")
	await wait(1.0)
	# skip intro text
	var t := 0.0
	while main.story.busy and t < 30.0:
		if main.ui.dialogue.waiting:
			main.ui.dialogue._advance()
		await wait(0.05)
		t += 0.05
	Game.minutes = 9.0 * 60.0
	Game.set_flag("boulder_0")
	for i in range(5):
		Game.set_flag("boulder_%d" % i)
	world.refresh_day_objects()
	# villagers and trolls wander around; don't let them block the test routes
	for n in world.npcs.values():
		(n as NPC)._body.collision_layer = 0
	await wait(0.2)
	for name in ROUTES.keys():
		await _walk(name, ROUTES[name])
	print("=== WALKTEST END: %d failures ===" % failures.size())
	for f in failures:
		print("  - ", f)
	get_tree().quit(1 if failures.size() > 0 else 0)


func _walk(route_name: String, pts: Array) -> void:
	var p: Player = world.player
	var start: Vector2 = pts[0]
	p.global_position = Vector3(start.x, world.ground_height(start.x, start.y) + 0.3, start.y)
	p.velocity = Vector3.ZERO
	world.rig.snap()
	await wait(0.3)
	var ok := true
	for i in range(1, pts.size()):
		var tgt: Vector2 = pts[i]
		var tleft := 25.0
		var stuck := 0.0
		var last := Vector2(p.global_position.x, p.global_position.z)
		while tleft > 0.0:
			var pos := Vector2(p.global_position.x, p.global_position.z)
			var d := tgt - pos
			if d.length() < 1.6:
				break
			# convert desired world direction into camera-relative input
			var dir := d.normalized()
			var fwd := world.rig.flat_forward()
			var right := world.rig.flat_right()
			var iy := dir.dot(Vector2(fwd.x, fwd.z))
			var ix := dir.dot(Vector2(right.x, right.z))
			_set_axis(ix, iy)
			Input.action_press("run")
			await wait(0.1)
			tleft -= 0.1
			var now := Vector2(p.global_position.x, p.global_position.z)
			if now.distance_to(last) < 0.05:
				stuck += 0.1
			else:
				stuck = 0.0
			last = now
			if stuck > 2.5:
				break
		_set_axis(0, 0)
		Input.action_release("run")
		var reached := Vector2(p.global_position.x, p.global_position.z).distance_to(tgt) < 1.8
		if not reached:
			ok = false
			var msg := "%s: could not reach leg %d %s (stopped at %.1f, %.1f)" % [route_name, i, tgt, p.global_position.x, p.global_position.z]
			print("  FAIL ", msg)
			failures.append(msg)
			p.global_position = Vector3(tgt.x, world.ground_height(tgt.x, tgt.y) + 0.5, tgt.y)
			await wait(0.2)
	if ok:
		print("  ok: ", route_name)


func _set_axis(x: float, y: float) -> void:
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
