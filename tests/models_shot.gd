extends Node3D

var frames := 0

func _ready() -> void:
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 20)
	ground.mesh = pm
	ground.material_override = Mats.solid(Color(0.4, 0.6, 0.28), false)
	add_child(ground)
	var x := -9.0
	var player := CharacterModel.new()
	player.build_troll({"skin": Color(0.6, 0.53, 0.45), "hair": Color(0.45, 0.62, 0.3), "hair_style": "moss", "scarf": Color(0.8, 0.25, 0.22), "belly": Color(0.7, 0.62, 0.52), "nose": 1.1})
	player.position = Vector3(x, 0, 0)
	add_child(player)
	x += 2.6
	for id in NpcDB.NPCS.keys():
		var n: Dictionary = NpcDB.NPCS[id]
		var m := CharacterModel.new()
		if n["kind"] == "troll":
			m.build_troll(n["look"])
		else:
			m.build_human(n["look"])
		m.position = Vector3(x, 0, 0 if n["kind"] == "troll" else 2.0)
		x += 2.2 if n["kind"] == "troll" else 1.3
		add_child(m)
	var g := CharacterModel.new()
	g.build_goat(Color(0.9, 0.88, 0.84), true)
	g.position = Vector3(x, 0, 2)
	g.rotation.y = 0.8
	add_child(g)
	var s := CharacterModel.new()
	s.build_sheep()
	s.position = Vector3(x + 1.5, 0, 2)
	s.rotation.y = -0.6
	add_child(s)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 30, 0)
	sun.shadow_enabled = true
	sun.light_energy = 0.9
	add_child(sun)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.6, 0.75, 0.9)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.6, 0.75)
	env.ambient_light_energy = 0.5
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var cam := Camera3D.new()
	cam.fov = 40
	add_child(cam)
	cam.position = Vector3(1, 3.2, 11)
	cam.look_at(Vector3(1, 1.1, 0))

func _process(_d: float) -> void:
	frames += 1
	if frames == 5:
		get_viewport().get_texture().get_image().save_png("user://shot_models.png")
		get_tree().quit()
