class_name Vegetation
extends Node3D
## Scatters trees, bushes, rocks, grass and flowers using MultiMeshes.

var terrain: Terrain
var blocked: Callable # func(x, z) -> bool
var _instances := {} # mesh key -> Array[Transform3D]
var _meshes := {} # mesh key -> ArrayMesh
var _mats := {} # mesh key -> Material
var _colliders: StaticBody3D
var _rng := RandomNumberGenerator.new()
## Positions of trees so other systems (e.g. kite tree) can avoid them.
var tree_points: Array = []


static func spruce_mesh(v: int) -> ArrayMesh:
	var k := MeshKit.new(100 + v)
	k.jitter = 0.025
	var greens := [Color(0.16, 0.34, 0.2), Color(0.19, 0.38, 0.22), Color(0.14, 0.3, 0.21)]
	var g: Color = greens[v % greens.size()]
	k.cylinder(Vector3(0, -0.4, 0), 0.3, 0.18, 2.0, 5, Color(0.36, 0.25, 0.17))
	var tiers := 4
	for t in range(tiers):
		var f := float(t) / tiers
		var y := 1.1 + f * 4.2
		var r := lerpf(2.3, 0.75, f)
		var hgt := lerpf(2.6, 2.0, f)
		k.cone(Vector3(0, y, 0), r, hgt, 7, g.lightened(0.05 * t) if t % 2 == 0 else g)
	return k.commit()


static func birch_mesh(v: int) -> ArrayMesh:
	var k := MeshKit.new(200 + v)
	k.jitter = 0.03
	var bark := Color(0.9, 0.88, 0.82)
	k.cylinder(Vector3(0, -0.3, 0), 0.17, 0.11, 4.2, 5, bark)
	for i in range(4):
		k.box(Vector3(0, 0.6 + i * 0.9, 0), Vector3(0.36, 0.1, 0.36), Color(0.2, 0.18, 0.17))
	var leaves := [Color(0.56, 0.6, 0.26), Color(0.86, 0.7, 0.26), Color(0.88, 0.55, 0.22), Color(0.46, 0.58, 0.24)]
	var c: Color = leaves[v % leaves.size()]
	k.blob(Vector3(0, 4.3, 0), Vector3(1.5, 1.3, 1.5), c, 3, 7, 0.12)
	k.blob(Vector3(0.7, 3.6, 0.3), Vector3(1.0, 0.9, 1.0), c.darkened(0.08), 3, 6, 0.12)
	k.blob(Vector3(-0.6, 3.8, -0.4), Vector3(1.0, 0.9, 1.0), c.lightened(0.06), 3, 6, 0.12)
	return k.commit()


static func rowan_mesh() -> ArrayMesh:
	var k := MeshKit.new(301)
	k.jitter = 0.03
	k.cylinder(Vector3(0, -0.3, 0), 0.2, 0.13, 3.2, 5, Color(0.42, 0.36, 0.3))
	var c := Color(0.8, 0.32, 0.18)
	k.blob(Vector3(0, 3.6, 0), Vector3(1.6, 1.2, 1.6), c, 3, 7, 0.15)
	k.blob(Vector3(0.8, 3.0, 0.2), Vector3(0.9, 0.8, 0.9), Color(0.72, 0.42, 0.18), 3, 6, 0.1)
	for i in range(5):
		var a := TAU * i / 5.0
		k.blob(Vector3(sin(a) * 1.3, 3.1, cos(a) * 1.3), Vector3(0.25, 0.25, 0.25), Color(0.85, 0.12, 0.1), 2, 4)
	return k.commit()


static func mountain_birch_mesh(v: int) -> ArrayMesh:
	var k := MeshKit.new(400 + v)
	k.jitter = 0.03
	k.xform = Transform3D(Basis.from_euler(Vector3(0.2, 0, 0.15)), Vector3.ZERO)
	k.cylinder(Vector3(0, -0.2, 0), 0.13, 0.08, 2.0, 5, Color(0.82, 0.8, 0.74))
	k.xform = Transform3D.IDENTITY
	var c := Color(0.86, 0.7, 0.25) if v % 2 == 0 else Color(0.76, 0.56, 0.2)
	k.blob(Vector3(0.3, 2.1, 0.35), Vector3(1.0, 0.75, 1.0), c, 3, 6, 0.15)
	k.blob(Vector3(-0.3, 1.7, 0.1), Vector3(0.7, 0.55, 0.7), c.darkened(0.1), 2, 5, 0.1)
	return k.commit()


static func juniper_mesh() -> ArrayMesh:
	var k := MeshKit.new(501)
	k.jitter = 0.03
	k.blob(Vector3(0, 0.6, 0), Vector3(0.7, 0.9, 0.7), Color(0.22, 0.38, 0.32), 3, 6, 0.15, true)
	k.blob(Vector3(0.4, 0.4, 0.2), Vector3(0.5, 0.5, 0.5), Color(0.2, 0.34, 0.29), 2, 5, 0.1, true)
	return k.commit()


static func bush_mesh(c: Color) -> ArrayMesh:
	var k := MeshKit.new(601)
	k.jitter = 0.03
	k.blob(Vector3(0, 0.45, 0), Vector3(0.8, 0.6, 0.8), c, 3, 6, 0.15, true)
	k.blob(Vector3(0.5, 0.35, 0.3), Vector3(0.5, 0.45, 0.5), c.lightened(0.07), 2, 5, 0.1, true)
	return k.commit()


static func rock_mesh(v: int, mossy: bool) -> ArrayMesh:
	var k := MeshKit.new(700 + v)
	k.jitter = 0.035
	var g := Color(0.55, 0.54, 0.52) if v % 2 == 0 else Color(0.5, 0.49, 0.5)
	k.blob(Vector3(0, 0.2, 0), Vector3(1.0, 0.75, 0.9), g, 4, 7, 0.22, true)
	if mossy:
		k.blob(Vector3(0.05, 0.62, 0.0), Vector3(0.75, 0.25, 0.65), Color(0.4, 0.56, 0.26), 2, 6, 0.1)
	return k.commit()


static func grass_mesh(c: Color) -> ArrayMesh:
	var k := MeshKit.new(801)
	for i in range(4):
		var a := TAU * i / 4.0 + 0.3
		var d := Vector3(sin(a), 0, cos(a))
		var side := Vector3(d.z, 0, -d.x) * 0.06
		var tip := d * 0.18 + Vector3(0, 0.42 + 0.08 * (i % 2), 0)
		k.tri(-side, tip, side, c)
		k.tri(side, tip, -side, c.darkened(0.1))
	return k.commit()


static func flower_mesh(c: Color) -> ArrayMesh:
	var k := MeshKit.new(901)
	var stem := Color(0.3, 0.5, 0.2)
	k.tri(Vector3(-0.02, 0, 0), Vector3(0, 0.32, 0), Vector3(0.02, 0, 0), stem)
	k.tri(Vector3(0.02, 0, 0), Vector3(0, 0.32, 0), Vector3(-0.02, 0, 0), stem)
	k.box(Vector3(0, 0.34, 0), Vector3(0.14, 0.06, 0.14), c)
	return k.commit()


func _add(key: String, mesh_factory: Callable, t: Transform3D, mat: Material = null) -> void:
	if not _meshes.has(key):
		_meshes[key] = mesh_factory.call()
		_mats[key] = mat if mat != null else Mats.world(0.0, 0.0)
	# chunk instances so frustum culling can skip distant groups
	var chunk := "%s@%d_%d" % [key, int(floor(t.origin.x / 48.0)), int(floor(t.origin.z / 48.0))]
	if not _instances.has(chunk):
		_instances[chunk] = []
	_instances[chunk].append(t)


func _tree_collider(p: Vector3, radius: float) -> void:
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = radius
	sh.height = 4.0
	cs.shape = sh
	cs.position = p + Vector3(0, 2.0, 0)
	_colliders.add_child(cs)


func _in_play(x: float, z: float) -> bool:
	return x > Layout.PLAY_MIN.x - 4 and x < Layout.PLAY_MAX.x + 4 and z > Layout.PLAY_MIN.y - 4 and z < Layout.PLAY_MAX.y + 4


func build(t: Terrain, blocked_fn: Callable) -> void:
	terrain = t
	blocked = blocked_fn
	_rng.seed = 12345
	_colliders = StaticBody3D.new()
	_colliders.name = "VegetationColliders"
	add_child(_colliders)
	_scatter_trees()
	_scatter_rocks()
	_scatter_ground_cover()
	_flush()


func _ok_ground(x: float, z: float, max_slope := 0.78) -> bool:
	if blocked.is_valid() and blocked.call(x, z):
		return false
	var h := terrain.height_at(x, z)
	if h < 1.3:
		return false
	if terrain.normal_at(x, z).y < max_slope:
		return false
	if terrain.river_weight_at(x, z) > 0.01:
		return false
	var lx: float = Layout.LAKE[0]
	var lz: float = Layout.LAKE[1]
	if Vector2(x - lx, z - lz).length() < Layout.LAKE[2] + 3.5:
		return false
	return true


func _scatter_trees() -> void:
	var step := 3.6
	var z := Layout.Z0 + 2.0
	while z < Layout.Z1 - 2.0:
		var x := Layout.X0 + 2.0
		while x < Layout.X1 - 2.0:
			var px := x + _rng.randf_range(-1.6, 1.6)
			var pz := z + _rng.randf_range(-1.6, 1.6)
			x += step
			var n := Terrain.fbm(px * 0.03, pz * 0.03, 77, 3)
			var h := terrain.height_at(px, pz)
			if h > 48.0:
				continue
			var roll := _rng.randf()
			var kind := ""
			if pz < -54.0:
				# plateau: sparse mountain birches and junipers
				if roll < 0.05 + n * 0.05:
					kind = "mbirch"
				elif roll < 0.12:
					kind = "juniper"
			elif pz < 16.0:
				var density := 0.45 + (n - 0.5) * 0.7
				if roll < density * 0.82:
					kind = "spruce"
				elif roll < density:
					kind = "birch"
				elif roll < density + 0.03:
					kind = "rowan"
			elif pz < 64.0:
				var edge := 0.12 if (absf(px) > 60.0) else 0.035
				if roll < edge * 0.5:
					kind = "spruce"
				elif roll < edge:
					kind = "birch"
				elif roll < edge + 0.01:
					kind = "rowan"
			else:
				if absf(px) > 70.0 and roll < 0.1:
					kind = "spruce"
			if kind == "":
				continue
			if not _ok_ground(px, pz, 0.72):
				continue
			if terrain.path_distance(px, pz) < 2.4:
				continue
			var y := terrain.height_at(px, pz)
			var s := _rng.randf_range(0.8, 1.25)
			var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s * _rng.randf_range(0.9, 1.15), s))
			var tr := Transform3D(basis, Vector3(px, y, pz))
			match kind:
				"spruce":
					var v := _rng.randi() % 3
					_add("spruce%d" % v, spruce_mesh.bind(v), tr, Mats.world(0.0, 0.25))
				"birch":
					var v2 := _rng.randi() % 4
					_add("birch%d" % v2, birch_mesh.bind(v2), tr, Mats.world(0.0, 0.5))
				"rowan":
					_add("rowan", rowan_mesh, tr, Mats.world(0.0, 0.5))
				"mbirch":
					var v3 := _rng.randi() % 2
					_add("mbirch%d" % v3, mountain_birch_mesh.bind(v3), tr, Mats.world(0.0, 0.5))
				"juniper":
					_add("juniper", juniper_mesh, tr)
			if kind != "juniper" and _in_play(px, pz):
				_tree_collider(Vector3(px, y, pz), 0.4 * s)
				tree_points.append(Vector2(px, pz))
		z += step


func _scatter_rocks() -> void:
	for i in range(420):
		var px := _rng.randf_range(Layout.X0 + 4, Layout.X1 - 4)
		var pz := _rng.randf_range(Layout.Z0 + 4, Layout.Z1 - 20)
		var h := terrain.height_at(px, pz)
		var ny := terrain.normal_at(px, pz).y
		var chance := 0.15
		if pz < -50.0:
			chance = 0.8
		elif ny < 0.85:
			chance = 0.6
		if _rng.randf() > chance:
			continue
		if blocked.is_valid() and blocked.call(px, pz):
			continue
		if terrain.path_distance(px, pz) < 2.0 or h < 0.5:
			continue
		if terrain.river_weight_at(px, pz) > 0.3:
			continue
		var s := _rng.randf_range(0.4, 1.6)
		if _rng.randf() < 0.1:
			s *= 1.8
		var basis := Basis.from_euler(Vector3(_rng.randf_range(-0.2, 0.2), _rng.randf() * TAU, 0)).scaled(Vector3(s, s, s))
		var tr := Transform3D(basis, Vector3(px, h - 0.15 * s, pz))
		var v := _rng.randi() % 3
		var mossy := pz < -40.0 and _rng.randf() < 0.6
		var key := "rock%d%s" % [v, "m" if mossy else ""]
		_add(key, rock_mesh.bind(v, mossy), tr)
		if s > 0.8 and _in_play(px, pz):
			var cs := CollisionShape3D.new()
			var sh := SphereShape3D.new()
			sh.radius = 0.8 * s
			cs.shape = sh
			cs.position = Vector3(px, h + 0.1 * s, pz)
			_colliders.add_child(cs)


func _scatter_ground_cover() -> void:
	var grass_c := [Color(0.5, 0.72, 0.3), Color(0.42, 0.62, 0.26), Color(0.62, 0.66, 0.3)]
	var flower_c := [Color(0.98, 0.95, 0.85), Color(0.98, 0.84, 0.3), Color(0.94, 0.55, 0.66), Color(0.62, 0.48, 0.86)]
	for i in range(5200):
		var px := _rng.randf_range(Layout.PLAY_MIN.x, Layout.PLAY_MAX.x)
		var pz := _rng.randf_range(Layout.PLAY_MIN.y, Layout.PLAY_MAX.y)
		if not _ok_ground(px, pz, 0.8):
			continue
		if terrain.path_weight_at(px, pz) > 0.2:
			continue
		var h := terrain.height_at(px, pz)
		var tr := Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.8, 1.4)), Vector3(px, h, pz))
		var roll := _rng.randf()
		if pz > 14.0 and roll < 0.22:
			var fc: int = _rng.randi() % flower_c.size()
			_add("flower%d" % fc, flower_mesh.bind(flower_c[fc]), tr, Mats.world(0.0, 1.0))
		elif pz < -50.0 and roll < 0.2:
			_add("heathflower", flower_mesh.bind(Color(0.72, 0.45, 0.72)), tr, Mats.world(0.0, 1.0))
		else:
			var gi := 0
			if pz < -50.0:
				gi = 2
			elif pz < 14.0:
				gi = 1
			_add("grass%d" % gi, grass_mesh.bind(grass_c[gi]), tr, Mats.world(0.0, 1.0))
	# some bushes along the forest edges
	for i in range(160):
		var px := _rng.randf_range(Layout.PLAY_MIN.x, Layout.PLAY_MAX.x)
		var pz := _rng.randf_range(-60.0, 60.0)
		if not _ok_ground(px, pz, 0.8) or terrain.path_distance(px, pz) < 1.8:
			continue
		var h := terrain.height_at(px, pz)
		var s := _rng.randf_range(0.7, 1.3)
		var tr := Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s, s)), Vector3(px, h, pz))
		_add("bush", bush_mesh.bind(Color(0.32, 0.5, 0.24)), tr, Mats.world(0.0, 0.3))


func _flush() -> void:
	for chunk in _instances.keys():
		var key: String = chunk.split("@")[0]
		var list: Array = _instances[chunk]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = _meshes[key]
		mm.instance_count = list.size()
		for i in range(list.size()):
			mm.set_instance_transform(i, list[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "MM_" + chunk.replace("@", "_")
		mmi.multimesh = mm
		mmi.material_override = _mats[key]
		if key.begins_with("grass") or key.begins_with("flower") or key.begins_with("heath"):
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
