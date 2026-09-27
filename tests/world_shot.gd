extends Node3D
## Debug: builds the static world and saves screenshots from a few cameras.

var shots := []
var idx := 0
var frames := 0
var cam: Camera3D


func _ready() -> void:
	var t0 := Time.get_ticks_msec()
	var terrain := Terrain.new()
	add_child(terrain)
	terrain.build()
	print("terrain ms ", Time.get_ticks_msec() - t0)
	var water := Water.new()
	add_child(water)
	water.build(terrain)
	print("water ms ", Time.get_ticks_msec() - t0)
	var b := Buildings.new()
	add_child(b)
	b.build(terrain)
	print("buildings ms ", Time.get_ticks_msec() - t0)
	var veg := Vegetation.new()
	add_child(veg)
	var clear: Array = b.clearings
	veg.build(terrain, func(x: float, z: float) -> bool:
		for c in clear:
			if Vector2(x - c.x, z - c.y).length() < c.z:
				return true
		return false)
	print("vegetation ms ", Time.get_ticks_msec() - t0)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.shadow_enabled = true
	sun.light_energy = 1.1
	sun.light_color = Color(1.0, 0.95, 0.85)
	add_child(sun)
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ShaderMaterial.new()
	sm.shader = load("res://shaders/sky.gdshader")
	sm.set_shader_parameter("sun_dir", -sun.global_transform.basis.z * -1.0)
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.6, 0.75)
	env.ambient_light_energy = 0.6
	env.fog_enabled = true
	env.fog_light_color = Color(0.75, 0.85, 0.92)
	env.fog_density = 0.004
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	cam = Camera3D.new()
	cam.fov = 45
	cam.far = 1500
	add_child(cam)
	shots = [
		["village", Vector3(0, 22, 90), Vector3(0, 3, 45)],
		["village_close", Vector3(-6, 10, 62), Vector3(-2, 3, 42)],
		["plateau", Vector3(-10, 45, -50), Vector3(-20, 28, -90)],
		["waterfall", Vector3(20, 22, -25), Vector3(31, 18, -50)],
		["overview", Vector3(0, 160, 160), Vector3(0, 10, -20)],
		["dock", Vector3(25, 8, 85), Vector3(9, 1, 70)],
	]
	if OS.get_cmdline_user_args().size() > 0:
		var only := OS.get_cmdline_user_args()[0]
		shots = shots.filter(func(s): return s[0] == only)
	_setup_shot()


func _setup_shot() -> void:
	var s: Array = shots[idx]
	cam.position = s[1]
	cam.look_at(s[2])


func _process(_d: float) -> void:
	frames += 1
	if frames < 6:
		return
	frames = 0
	var img := get_viewport().get_texture().get_image()
	var path := "user://shot_%s.png" % shots[idx][0]
	img.save_png(path)
	print("saved ", ProjectSettings.globalize_path(path))
	idx += 1
	if idx >= shots.size():
		get_tree().quit()
	else:
		_setup_shot()
