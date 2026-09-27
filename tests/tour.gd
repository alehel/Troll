extends Node
## Takes gameplay-camera screenshots at interesting places and times.
##   godot --path . -- --tour

var main: Node
var world: World

const STOPS := [
	["hollow_morning", Vector2(-32, -98), 7.5, 0.75],
	["granny_hut", Vector2(-6, -84), 9.0, 2.6],
	["lake_noon", Vector2(22, -86), 12.5, 2.4],
	["waterfall", Vector2(24, -38), 14.0, 2.2],
	["troll_bridge", Vector2(24, -8), 15.0, 1.6],
	["forest", Vector2(-2, -20), 11.0, 3.1],
	["village_square", Vector2(4, 50), 11.0, 3.4],
	["village_bridge", Vector2(40, 48), 16.0, 0.9],
	["dock_evening", Vector2(12, 66), 18.8, 3.6],
	["farm", Vector2(-40, 46), 10.0, -1.9],
	["village_night", Vector2(2, 52), 22.5, 3.3],
	["plateau_night", Vector2(-20, -70), 23.5, 3.1],
]


func run(m: Node) -> void:
	main = m
	world = m.world
	await _go()


func wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _go() -> void:
	main.show_title()
	await wait(0.3)
	main._start_new("Mose")
	await wait(3.0)
	var t := 0.0
	while (main.story.busy or main.ui.dialogue.visible) and t < 30.0:
		if main.ui.dialogue.waiting:
			main.ui.dialogue._advance()
		await wait(0.05)
		t += 0.05
	main.ui.hud.hint_panel.visible = false
	# make the villagers friendly so they stay in view
	for id in NpcDB.humans():
		Game.trust[id] = 50.0
	for s in STOPS:
		Game.minutes = float(s[2]) * 60.0
		for n in world.npcs.values():
			(n as NPC).place_by_schedule()
		var p: Vector2 = s[1]
		world.player.global_position = Vector3(p.x, world.ground_height(p.x, p.y) + 0.2, p.y)
		world.player.velocity = Vector3.ZERO
		world.rig.yaw_target = s[3]
		world.rig.snap()
		await wait(1.2)
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png("user://tour_%s.png" % s[0])
		print("TOUR ", s[0])
	get_tree().quit()
