class_name AmbientLife
extends Node3D
## Little living details: seagulls over the fjord, butterflies in the meadows
## during the day and fireflies at night.

var terrain: Terrain
var _gulls: Array = [] # [{node, wing_l, wing_r, center, radius, speed, angle, height, phase}]
var _flies: Array = [] # [{node, wing_l, wing_r, home, target, t}]
var _fireflies: Array = []
var _t := 0.0


func build(t: Terrain) -> void:
	terrain = t
	var rng := RandomNumberGenerator.new()
	rng.seed = 314
	for i in range(6):
		_add_gull(Vector3(rng.randf_range(-40, 60), 0, rng.randf_range(78, 120)), rng)
	var meadows := [Vector2(-30, 25), Vector2(30, 30), Vector2(62, -20), Vector2(-60, 60), Vector2(40, 58), Vector2(-15, 55), Vector2(10, -85), Vector2(-45, -70)]
	for m in meadows:
		for k in range(2):
			_add_butterfly(m + Vector2(rng.randf_range(-5, 5), rng.randf_range(-5, 5)), rng)
	for spot in [Vector3(0, 0, -30), Vector3(28, 0, -88), Vector3(-22, 0, 18), Vector3(-64, 0, -100), Vector3(40, 0, 20), Vector3(-30, 0, -50), Vector3(-10, 0, 60)]:
		var p: Vector3 = spot
		p.y = terrain.height_at(p.x, p.z) + 1.2
		_fireflies.append(_make_fireflies(p))


func _wing(col: Color, s: float) -> MeshInstance3D:
	var k := MeshKit.new(90)
	k.tri(Vector3(0, 0, -0.12) * s, Vector3(0.5, 0, 0) * s, Vector3(0, 0, 0.12) * s, col)
	k.tri(Vector3(0, 0, 0.12) * s, Vector3(0.5, 0, 0) * s, Vector3(0, 0, -0.12) * s, col.darkened(0.15))
	var mi := MeshInstance3D.new()
	mi.mesh = k.commit()
	mi.material_override = Mats.world(0.0, 0.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


func _add_gull(center: Vector3, rng: RandomNumberGenerator) -> void:
	var n := Node3D.new()
	add_child(n)
	var body := MeshInstance3D.new()
	var bm := CapsuleMesh.new()
	bm.radius = 0.12
	bm.height = 0.6
	bm.radial_segments = 6
	bm.rings = 2
	body.mesh = bm
	body.rotation.x = PI * 0.5
	body.material_override = Mats.solid(Color(0.97, 0.97, 0.95), false)
	n.add_child(body)
	var wl := _wing(Color(0.92, 0.93, 0.95), 1.6)
	var wr := _wing(Color(0.92, 0.93, 0.95), 1.6)
	wr.scale = Vector3(-1, 1, 1)
	n.add_child(wl)
	n.add_child(wr)
	_gulls.append({"node": n, "wl": wl, "wr": wr, "center": center, "radius": rng.randf_range(8, 20),
		"speed": rng.randf_range(0.18, 0.3) * (1 if rng.randf() < 0.5 else -1), "angle": rng.randf() * TAU,
		"height": rng.randf_range(9, 16), "phase": rng.randf() * TAU})


func _add_butterfly(home: Vector2, rng: RandomNumberGenerator) -> void:
	var n := Node3D.new()
	add_child(n)
	var cols := [Color(0.98, 0.95, 0.9), Color(0.98, 0.8, 0.3), Color(0.55, 0.7, 0.98), Color(0.95, 0.55, 0.3)]
	var c: Color = cols[rng.randi() % cols.size()]
	var wl := _wing(c, 0.35)
	var wr := _wing(c, 0.35)
	wr.scale = Vector3(-1, 1, 1)
	n.add_child(wl)
	n.add_child(wr)
	var h := Vector3(home.x, terrain.height_at(home.x, home.y) + 0.8, home.y)
	n.position = h
	_flies.append({"node": n, "wl": wl, "wr": wr, "home": h, "target": h, "t": rng.randf() * 3.0, "phase": rng.randf() * TAU})


func _make_fireflies(p: Vector3) -> CPUParticles3D:
	var f := CPUParticles3D.new()
	add_child(f)
	f.position = p
	f.amount = 14
	f.lifetime = 5.0
	f.preprocess = 5.0
	f.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	f.emission_box_extents = Vector3(9, 1.2, 9)
	f.direction = Vector3(0, 1, 0)
	f.spread = 180.0
	f.initial_velocity_min = 0.1
	f.initial_velocity_max = 0.35
	f.gravity = Vector3.ZERO
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(0.2, 1.0))
	curve.add_point(Vector2(0.8, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	f.scale_amount_curve = curve
	var m := BoxMesh.new()
	m.size = Vector3(0.09, 0.09, 0.09)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.85, 1.0, 0.45)
	m.material = mat
	f.mesh = m
	f.emitting = false
	f.visible = false
	return f


func _process(delta: float) -> void:
	_t += delta
	var h := fmod(Game.minutes / 60.0, 24.0)
	var night := h >= 21.0 or h < 5.0
	var day := h >= 8.0 and h < 18.5
	for g in _gulls:
		g["angle"] += g["speed"] * delta
		var a: float = g["angle"]
		var c: Vector3 = g["center"]
		var r: float = g["radius"]
		var pos := c + Vector3(cos(a) * r, g["height"] + sin(_t * 0.5 + g["phase"]) * 1.2, sin(a) * r)
		var node: Node3D = g["node"]
		var tangent := Vector3(-sin(a), 0, cos(a)) * signf(g["speed"])
		node.position = pos
		node.rotation.y = atan2(tangent.x, tangent.z)
		node.rotation.z = -0.25 * signf(g["speed"])
		var flap := sin(_t * 7.0 + g["phase"])
		var glide := sin(_t * 0.4 + g["phase"]) > 0.2
		var wa := 0.1 if glide else flap * 0.55
		(g["wl"] as Node3D).rotation.z = wa
		(g["wr"] as Node3D).rotation.z = -wa
		node.visible = not night
	for f in _flies:
		var node2: Node3D = f["node"]
		node2.visible = day
		if not day:
			continue
		f["t"] -= delta
		if f["t"] <= 0.0:
			f["t"] = randf_range(1.0, 3.0)
			var home: Vector3 = f["home"]
			f["target"] = home + Vector3(randf_range(-3, 3), randf_range(-0.3, 0.8), randf_range(-3, 3))
		var to: Vector3 = f["target"] - node2.position
		node2.position += to * clampf(delta * 0.8, 0.0, 1.0) + Vector3(0, sin(_t * 9.0 + f["phase"]) * 0.01, 0)
		if to.length() > 0.05:
			node2.rotation.y = lerp_angle(node2.rotation.y, atan2(to.x, to.z), clampf(delta * 4.0, 0.0, 1.0))
		var w := sin(_t * 22.0 + f["phase"]) * 1.1
		(f["wl"] as Node3D).rotation.z = w
		(f["wr"] as Node3D).rotation.z = -w
	for ff in _fireflies:
		var p := ff as CPUParticles3D
		if p.visible != night:
			p.visible = night
			p.emitting = night
