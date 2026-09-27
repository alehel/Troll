class_name DayNight
extends Node3D
## Drives sun/moon light, sky colours, fog, stars, northern lights and lamps
## from the in-game clock.

## hour, sky top, horizon, light colour, light energy, ambient colour, ambient energy, is_moon
const KEYS := [
	[0.0, Color(0.03, 0.05, 0.13), Color(0.09, 0.11, 0.22), Color(0.62, 0.68, 0.88), 0.24, Color(0.3, 0.33, 0.46), 0.52, true],
	[5.0, Color(0.05, 0.07, 0.17), Color(0.2, 0.2, 0.33), Color(0.62, 0.68, 0.88), 0.18, Color(0.32, 0.33, 0.45), 0.52, true],
	[6.2, Color(0.22, 0.3, 0.52), Color(0.9, 0.62, 0.5), Color(1.0, 0.7, 0.5), 0.35, Color(0.48, 0.42, 0.55), 0.5, false],
	[7.5, Color(0.3, 0.48, 0.78), Color(0.95, 0.8, 0.68), Color(1.0, 0.85, 0.68), 0.75, Color(0.52, 0.52, 0.66), 0.52, false],
	[9.5, Color(0.3, 0.52, 0.86), Color(0.72, 0.84, 0.93), Color(1.0, 0.94, 0.84), 0.95, Color(0.55, 0.6, 0.74), 0.52, false],
	[13.0, Color(0.27, 0.5, 0.88), Color(0.7, 0.83, 0.94), Color(1.0, 0.97, 0.9), 1.0, Color(0.56, 0.62, 0.76), 0.52, false],
	[16.5, Color(0.3, 0.5, 0.84), Color(0.8, 0.82, 0.8), Color(1.0, 0.9, 0.74), 0.92, Color(0.56, 0.57, 0.7), 0.5, false],
	[18.5, Color(0.33, 0.4, 0.7), Color(0.98, 0.66, 0.42), Color(1.0, 0.66, 0.38), 0.72, Color(0.58, 0.47, 0.52), 0.48, false],
	[19.8, Color(0.2, 0.22, 0.46), Color(0.88, 0.46, 0.4), Color(0.98, 0.5, 0.38), 0.32, Color(0.44, 0.37, 0.5), 0.46, false],
	[20.6, Color(0.1, 0.12, 0.3), Color(0.42, 0.28, 0.4), Color(0.7, 0.55, 0.7), 0.05, Color(0.33, 0.32, 0.5), 0.46, false],
	[21.3, Color(0.05, 0.07, 0.18), Color(0.16, 0.16, 0.3), Color(0.62, 0.68, 0.88), 0.16, Color(0.31, 0.33, 0.46), 0.5, true],
	[24.0, Color(0.03, 0.05, 0.13), Color(0.09, 0.11, 0.22), Color(0.62, 0.68, 0.88), 0.24, Color(0.3, 0.33, 0.46), 0.52, true],
]

var sun: DirectionalLight3D
var env: Environment
var sky_mat: ShaderMaterial
var buildings: Buildings
var lamps: Array = []
var aurora_forced := false
var night_amount := 0.0


func build(b: Buildings) -> void:
	buildings = b
	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 70.0
	sun.shadow_bias = 0.08
	sun.shadow_normal_bias = 1.5
	sun.shadow_opacity = 0.75
	add_child(sun)
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky_mat = ShaderMaterial.new()
	sky_mat.shader = load("res://shaders/sky.gdshader")
	sky.sky_material = sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = true
	env.fog_density = 0.0045
	env.fog_sky_affect = 0.15
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	# warm lights near lamps (limited number to stay cheap)
	var pts: Array = b.lamp_points.duplicate()
	pts.append_array(b.fire_points)
	for p in pts:
		var l := OmniLight3D.new()
		l.position = p
		l.light_color = Color(1.0, 0.72, 0.4)
		l.omni_range = 7.0
		l.light_energy = 0.0
		l.shadow_enabled = false
		add_child(l)
		lamps.append(l)


static func _lerp_key(a: Array, b: Array, t: float) -> Array:
	var out := [0.0]
	for i in range(1, 7):
		if a[i] is Color:
			out.append((a[i] as Color).lerp(b[i], t))
		else:
			out.append(lerpf(a[i], b[i], t))
	out.append(a[7] if t < 0.5 else b[7])
	return out


func _sample(h: float) -> Array:
	h = fmod(h, 24.0)
	for i in range(KEYS.size() - 1):
		var a: Array = KEYS[i]
		var b: Array = KEYS[i + 1]
		if h >= a[0] and h <= b[0]:
			var t: float = (h - a[0]) / maxf(b[0] - a[0], 0.001)
			t = t * t * (3.0 - 2.0 * t)
			return _lerp_key(a, b, t)
	return KEYS[0]


func sun_direction(h: float) -> Vector3:
	## Direction pointing towards the sun. Rises in the east (+X), south at noon (+Z), sets in the west.
	var t := (h - 6.4) / (20.4 - 6.4)
	var th := clampf(t, -0.1, 1.1) * PI
	var elev := sin(clampf(t, 0.0, 1.0) * PI) * deg_to_rad(38.0) - deg_to_rad(4.0)
	return Vector3(cos(th) * cos(elev), sin(elev), sin(th) * cos(elev)).normalized()


func moon_direction(h: float) -> Vector3:
	var hh := fmod(h + 24.0 - 19.5, 24.0) # the moon is up from 19:30 to 07:30
	var t := hh / 12.0
	var th := clampf(t, 0.0, 1.0) * PI
	var elev := sin(clampf(t, 0.0, 1.0) * PI) * deg_to_rad(40.0) + deg_to_rad(6.0)
	return Vector3(cos(th) * cos(elev), sin(elev), sin(th) * cos(elev)).normalized()


func update(minutes: float) -> void:
	var h := minutes / 60.0
	var k := _sample(h)
	var is_moon: bool = k[7]
	var dir := moon_direction(h) if is_moon else sun_direction(h)
	if dir.y < 0.08:
		dir.y = 0.08
		dir = dir.normalized()
	sun.look_at_from_position(Vector3.ZERO, -dir, Vector3.UP if absf(dir.y) < 0.99 else Vector3.FORWARD)
	sun.light_color = k[3]
	sun.light_energy = k[4]
	env.ambient_light_color = k[5]
	env.ambient_light_energy = k[6]
	env.fog_light_color = (k[2] as Color).lerp(k[1], 0.25)
	sky_mat.set_shader_parameter("top_color", k[1])
	sky_mat.set_shader_parameter("horizon_color", k[2])
	sky_mat.set_shader_parameter("ground_color", (k[2] as Color).darkened(0.3))
	sky_mat.set_shader_parameter("sun_color", k[3])
	sky_mat.set_shader_parameter("sun_dir", sun_direction(h))
	sky_mat.set_shader_parameter("moon_dir", moon_direction(h))
	var hh := fmod(h, 24.0)
	var night := 0.0
	if hh >= 20.0 or hh < 6.5:
		night = 1.0
		if hh >= 20.0 and hh < 21.5:
			night = (hh - 20.0) / 1.5
		elif hh >= 5.2 and hh < 6.5:
			night = 1.0 - (hh - 5.2) / 1.3
	night_amount = night
	sky_mat.set_shader_parameter("stars", night)
	var aurora := 0.0
	if aurora_forced or (Game.day % 3 != 1):
		aurora = night * (1.0 if aurora_forced else 0.75)
	sky_mat.set_shader_parameter("aurora", aurora)
	sky_mat.set_shader_parameter("cloud_amount", 0.35 + 0.35 * float(hash(Game.day) % 100) / 100.0)
	var glow := clampf((night - 0.1) * 1.4, 0.0, 1.0)
	if hh >= 18.5 and hh < 20.0:
		glow = maxf(glow, (hh - 18.5) / 1.5 * 0.6)
	if buildings:
		buildings.window_material.set_shader_parameter("emission_energy", glow * 0.95)
		buildings.lamp_material.set_shader_parameter("emission_energy", 0.15 + glow * 0.75)
	for l in lamps:
		(l as OmniLight3D).light_energy = glow * 1.1
	if buildings:
		for sm in buildings.smoke_nodes:
			var m: StandardMaterial3D = (sm as CPUParticles3D).mesh.material
			m.albedo_color = Color(0.85, 0.85, 0.85).lerp(Color(0.22, 0.24, 0.32), night)
	Mats.water().set_shader_parameter("night", night)
