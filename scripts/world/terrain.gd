class_name Terrain
extends Node3D
## Procedural height field for the valley: a fjord village in the south, a
## forested slope, an escarpment with a waterfall and the troll plateau up north.
## The same functions are mirrored in tools/terrain_preview.py.

static var inst: Terrain

var nx := 0
var nz := 0
var heights := PackedFloat32Array()
var path_w := PackedFloat32Array()
var river_w := PackedFloat32Array()

var _paths: Array = [] # [{pts: Array[Vector3], half, min: Vector2, max: Vector2, name}]
var _river: Array = [] # Array[Vector3] (x, bed, z)
var _river_min := Vector2.ZERO
var _river_max := Vector2.ZERO


# --------------------------------------------------------------------------
# Noise (deterministic, identical to the python preview)
# --------------------------------------------------------------------------
static func hash2(ix: int, iz: int, s: int) -> float:
	var h := (ix * 374761393 + iz * 668265263 + s * 144665) & 0xFFFFFFFF
	h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
	h = h ^ (h >> 16)
	return float(h & 0xFFFF) / 65535.0


static func vnoise(x: float, z: float, s: int) -> float:
	var fx0 := floorf(x)
	var fz0 := floorf(z)
	var ix := int(fx0)
	var iz := int(fz0)
	var fx := x - fx0
	var fz := z - fz0
	var u := fx * fx * (3.0 - 2.0 * fx)
	var v := fz * fz * (3.0 - 2.0 * fz)
	var a := hash2(ix, iz, s)
	var b := hash2(ix + 1, iz, s)
	var c := hash2(ix, iz + 1, s)
	var d := hash2(ix + 1, iz + 1, s)
	var top := a + (b - a) * u
	var bot := c + (d - c) * u
	return top + (bot - top) * v


static func fbm(x: float, z: float, s: int, octaves := 4) -> float:
	var total := 0.0
	var amp := 0.5
	var f := 1.0
	var norm := 0.0
	for i in range(octaves):
		total += amp * vnoise(x * f, z * f, s + i * 17)
		norm += amp
		amp *= 0.5
		f *= 2.03
	return total / norm


static func sstep(e0: float, e1: float, x: float) -> float:
	var t := clampf((x - e0) / (e1 - e0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


# --------------------------------------------------------------------------
# Height function
# --------------------------------------------------------------------------
static func shore_z(x: float) -> float:
	return Layout.SHORE_Z + 5.0 * sin(x * 0.045) + (fbm(x * 0.05, 3.7, 11) - 0.5) * 8.0


static func base_height(x: float, z: float) -> float:
	var sz := shore_z(x)
	var h := 0.0
	var vy := Layout.VILLAGE_Y
	if z > sz:
		h = maxf(vy - (z - sz) * 0.55, -9.0)
	elif z > 18.0:
		h = lerpf(vy + 0.6, vy, sstep(18.0, sz, z))
	elif z > -10.0:
		h = lerpf(9.0, vy + 0.6, sstep(-10.0, 18.0, z))
	elif z > -44.0:
		h = lerpf(16.0, 9.0, sstep(-44.0, -10.0, z))
	elif z > -54.0:
		h = lerpf(Layout.PLATEAU_Y, 16.0, sstep(-54.0, -44.0, z))
	else:
		h = Layout.PLATEAU_Y
	var amp := 0.5
	if z < -54.0:
		amp = 3.0
	elif z < -8.0:
		amp = 2.6
	elif z < sz - 8.0:
		amp = 0.9
	h += (fbm(x * 0.035, z * 0.035, 3) - 0.5) * 2.0 * amp
	var wz := -112.0 - (fbm(x * 0.02, 1.3, 13) - 0.5) * 22.0
	if z < wz:
		var d := wz - z
		h += d * (0.7 + fbm(x * 0.03, z * 0.03, 5) * 1.1) + (fbm(x * 0.08, z * 0.08, 6) - 0.5) * d * 0.5
	var ax := absf(x)
	var wall_start := 86.0 + (fbm(z * 0.02, 7.7, 14) - 0.5) * 16.0
	if x > 0.0:
		var opening := sstep(10.0, 26.0, z) * (1.0 - sstep(64.0, 80.0, z))
		wall_start = lerpf(wall_start, 150.0, opening)
	if ax > wall_start:
		var d2 := ax - wall_start
		h += d2 * (0.7 + fbm(x * 0.03, z * 0.03, 8) * 1.1) + (fbm(x * 0.06, z * 0.06, 7) - 0.5) * d2 * 0.5
	return minf(h, 140.0)


static func seg_closest(px: float, pz: float, a: Vector3, b: Vector3) -> Vector2:
	## Returns (distance, t) for point to segment a-b in the XZ plane.
	var dx := b.x - a.x
	var dz := b.z - a.z
	var l2 := dx * dx + dz * dz
	var t := 0.0
	if l2 > 1e-6:
		t = clampf(((px - a.x) * dx + (pz - a.z) * dz) / l2, 0.0, 1.0)
	var cx := a.x + dx * t
	var cz := a.z + dz * t
	return Vector2(sqrt((px - cx) * (px - cx) + (pz - cz) * (pz - cz)), t)


## Returns Vector2(distance, height_at_closest) for a polyline of Vector3(x, y, z).
static func polyline_query(px: float, pz: float, pts: Array) -> Vector2:
	var best := 1e9
	var by := 0.0
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var r := seg_closest(px, pz, a, b)
		if r.x < best:
			best = r.x
			by = lerpf(a.y, b.y, r.y)
	return Vector2(best, by)


func _prepare() -> void:
	_paths.clear()
	for p in Layout.PATHS:
		var pts: Array = []
		var mn := Vector2(1e9, 1e9)
		var mx := Vector2(-1e9, -1e9)
		for v in p[2]:
			var vv: Vector3 = v
			var y := vv.y
			if is_nan(y):
				y = base_height(vv.x, vv.z)
			pts.append(Vector3(vv.x, y, vv.z))
			mn = Vector2(minf(mn.x, vv.x), minf(mn.y, vv.z))
			mx = Vector2(maxf(mx.x, vv.x), maxf(mx.y, vv.z))
		var half: float = p[1] * 0.5
		var pad := half + 4.5
		_paths.append({"name": p[0], "pts": pts, "half": half,
			"min": mn - Vector2(pad, pad), "max": mx + Vector2(pad, pad)})
	_river = Layout.RIVER.duplicate()
	_river_min = Vector2(1e9, 1e9)
	_river_max = Vector2(-1e9, -1e9)
	for v in _river:
		_river_min = Vector2(minf(_river_min.x, v.x), minf(_river_min.y, v.z))
		_river_max = Vector2(maxf(_river_max.x, v.x), maxf(_river_max.y, v.z))
	var rp := Layout.RIVER_HALF + 6.0
	_river_min -= Vector2(rp, rp)
	_river_max += Vector2(rp, rp)


## Full height with all designed features. Returns (height, path weight, river weight).
func compute(x: float, z: float) -> Vector3:
	var h := base_height(x, z)
	for f in Layout.FLATS:
		var d := Vector2(x - f[0], z - f[1]).length()
		var r: float = f[2]
		var fall: float = f[3]
		if d < r + fall:
			var w := 1.0 - sstep(r, r + fall, d)
			var t: float = f[4]
			if is_nan(t):
				t = base_height(f[0], f[1])
			h = lerpf(h, t, w)
	var pw := 0.0
	for p in _paths:
		var mn: Vector2 = p["min"]
		var mx: Vector2 = p["max"]
		if x < mn.x or z < mn.y or x > mx.x or z > mx.y:
			continue
		var q := polyline_query(x, z, p["pts"])
		var half: float = p["half"]
		if q.x < half + 4.0:
			var w2 := 1.0 - sstep(half, half + 4.0, q.x)
			h = lerpf(h, q.y - 0.05, w2)
			pw = maxf(pw, 1.0 - sstep(half - 0.6, half + 0.4, q.x))
	var rw := 0.0
	if x > _river_min.x and z > _river_min.y and x < _river_max.x and z < _river_max.y:
		var rq := polyline_query(x, z, _river)
		if rq.x < Layout.RIVER_HALF + 5.0:
			var w3 := 1.0 - sstep(Layout.RIVER_HALF, Layout.RIVER_HALF + 5.0, rq.x)
			h = minf(h, lerpf(h, rq.y, w3))
			rw = 1.0 - sstep(Layout.RIVER_HALF + 0.5, Layout.RIVER_HALF + 2.5, rq.x)
	var lx: float = Layout.LAKE[0]
	var lz: float = Layout.LAKE[1]
	var lr: float = Layout.LAKE[2]
	var ly: float = Layout.LAKE[3]
	var ld := Vector2(x - lx, z - lz).length()
	if ld < lr + 6.0:
		var bed := ly + 0.4
		if ld < lr:
			bed = ly - 2.5 * (1.0 - (ld / lr) * (ld / lr))
		var w4 := 1.0 - sstep(lr - 1.0, lr + 6.0, ld)
		h = minf(h, lerpf(h, bed, w4))
	return Vector3(h, pw, rw)


func generate() -> void:
	inst = self
	_prepare()
	nx = int((Layout.X1 - Layout.X0) / Layout.STEP) + 1
	nz = int((Layout.Z1 - Layout.Z0) / Layout.STEP) + 1
	heights.resize(nx * nz)
	path_w.resize(nx * nz)
	river_w.resize(nx * nz)
	for j in range(nz):
		var z := Layout.Z0 + j * Layout.STEP
		for i in range(nx):
			var x := Layout.X0 + i * Layout.STEP
			var r := compute(x, z)
			var k := j * nx + i
			heights[k] = r.x
			path_w[k] = r.y
			river_w[k] = r.z


# --------------------------------------------------------------------------
# Queries
# --------------------------------------------------------------------------
func _h(i: int, j: int) -> float:
	i = clampi(i, 0, nx - 1)
	j = clampi(j, 0, nz - 1)
	return heights[j * nx + i]


## Exact height matching the rendered triangles.
func height_at(x: float, z: float) -> float:
	var gx := (x - Layout.X0) / Layout.STEP
	var gz := (z - Layout.Z0) / Layout.STEP
	if gx < 0.0 or gz < 0.0 or gx >= nx - 1 or gz >= nz - 1:
		return base_height(x, z)
	var i := int(gx)
	var j := int(gz)
	var fx := gx - i
	var fz := gz - j
	var h00 := _h(i, j)
	var h10 := _h(i + 1, j)
	var h01 := _h(i, j + 1)
	var h11 := _h(i + 1, j + 1)
	if fx >= fz:
		return h00 + (h10 - h00) * fx + (h11 - h10) * fz
	return h00 + (h01 - h00) * fz + (h11 - h01) * fx


func normal_at(x: float, z: float) -> Vector3:
	var e := 0.5
	var hl := height_at(x - e, z)
	var hr := height_at(x + e, z)
	var hd := height_at(x, z - e)
	var hu := height_at(x, z + e)
	return Vector3(hl - hr, 2.0 * e, hd - hu).normalized()


func path_weight_at(x: float, z: float) -> float:
	var i := clampi(int(round((x - Layout.X0) / Layout.STEP)), 0, nx - 1)
	var j := clampi(int(round((z - Layout.Z0) / Layout.STEP)), 0, nz - 1)
	return path_w[j * nx + i]


func river_weight_at(x: float, z: float) -> float:
	var i := clampi(int(round((x - Layout.X0) / Layout.STEP)), 0, nx - 1)
	var j := clampi(int(round((z - Layout.Z0) / Layout.STEP)), 0, nz - 1)
	return river_w[j * nx + i]


## Distance from a point to the nearest path centre line (XZ).
func path_distance(x: float, z: float) -> float:
	var best := 1e9
	for p in _paths:
		var mn: Vector2 = p["min"]
		var mx: Vector2 = p["max"]
		if x < mn.x - 10 or z < mn.y - 10 or x > mx.x + 10 or z > mx.y + 10:
			continue
		best = minf(best, polyline_query(x, z, p["pts"]).x - p["half"])
	return best


## Water surface height at a point, or -INF when dry.
func water_level_at(x: float, z: float) -> float:
	var lx: float = Layout.LAKE[0]
	var lz: float = Layout.LAKE[1]
	if Vector2(x - lx, z - lz).length() < Layout.LAKE[2] + 1.0:
		return Layout.LAKE[3]
	if x > _river_min.x and z > _river_min.y and x < _river_max.x and z < _river_max.y:
		var rq := polyline_query(x, z, _river)
		if rq.x < Layout.RIVER_HALF + 0.8:
			return rq.y + Layout.RIVER_WATER_OFFSET
	if z > 40.0:
		return Layout.SEA_Y
	return -INF


func river_points() -> Array:
	return _river


func path_list() -> Array:
	return _paths


# --------------------------------------------------------------------------
# Colours
# --------------------------------------------------------------------------
func color_for(x: float, z: float, h: float, ny: float, pw: float, rw: float) -> Color:
	var n1 := fbm(x * 0.07, z * 0.07, 21, 3)
	var n2 := vnoise(x * 0.4, z * 0.4, 33)
	var meadow := Color(0.4, 0.62, 0.26)
	if n1 > 0.57:
		meadow = Color(0.47, 0.67, 0.28)
	elif n1 < 0.4:
		meadow = Color(0.34, 0.55, 0.23)
	var forest := Color(0.27, 0.45, 0.22)
	if n1 > 0.61:
		forest = Color(0.4, 0.36, 0.24)
	elif n1 < 0.38:
		forest = Color(0.22, 0.38, 0.2)
	var heath := Color(0.5, 0.57, 0.3)
	if n1 > 0.66:
		heath = Color(0.52, 0.44, 0.5)
	elif n1 < 0.37:
		heath = Color(0.38, 0.52, 0.24)
	if n2 > 0.9:
		heath = Color(0.66, 0.66, 0.5)
	var zb := z + (n1 - 0.5) * 14.0
	var c := meadow
	if zb < 14.0:
		c = forest.lerp(meadow, sstep(4.0, 14.0, zb))
	if zb < -50.0:
		c = heath.lerp(forest, sstep(-56.0, -50.0, zb))
	# bog
	var bd := Vector2(x + 66.0, z + 104.0).length()
	if bd < 18.0:
		var bog := Color(0.47, 0.5, 0.26) if n2 > 0.4 else Color(0.4, 0.36, 0.23)
		c = bog.lerp(c, sstep(12.0, 18.0, bd))
	# beach
	if z > 45.0 and h < 1.4:
		var sand := Color(0.84, 0.78, 0.6) if n2 > 0.3 else Color(0.78, 0.72, 0.56)
		c = sand.lerp(c, sstep(0.9, 1.4, h))
		if h < -0.2:
			c = Color(0.62, 0.62, 0.5)
	# high ground
	if h > 40.0:
		c = c.lerp(Color(0.55, 0.53, 0.47), sstep(40.0, 52.0, h))
	# steep rock, with horizontal strata and a little moss on the ledges
	if ny < 0.8:
		var band := posmod(int(floor(h / 1.7 + n1 * 1.5)), 3)
		var rock: Color = [Color(0.53, 0.51, 0.49), Color(0.46, 0.45, 0.44), Color(0.58, 0.55, 0.5)][band]
		if n2 > 0.72:
			rock = rock.lerp(Color(0.36, 0.48, 0.27), 0.45)
		c = c.lerp(rock, sstep(0.8, 0.68, ny))
	if h > 58.0 + n1 * 18.0 and ny > 0.55:
		c = Color(0.93, 0.95, 0.98)
	# river bed gravel
	if rw > 0.05:
		c = c.lerp(Color(0.52, 0.5, 0.44), clampf(rw, 0.0, 1.0))
	# paths
	if pw > 0.05:
		var dirt := Color(0.55, 0.43, 0.3) if z < 15.0 else Color(0.64, 0.55, 0.42)
		if n2 > 0.7:
			dirt = dirt.darkened(0.08)
		c = c.lerp(dirt, clampf(pw * 1.5, 0.0, 1.0))
	return c


# --------------------------------------------------------------------------
# Mesh + collision
# --------------------------------------------------------------------------
func build() -> void:
	generate()
	var kit := MeshKit.new(7)
	# colour per grid vertex, blended across triangles
	var vcol := PackedColorArray()
	vcol.resize(nx * nz)
	for j in range(nz):
		for i in range(nx):
			var k := j * nx + i
			var x := Layout.X0 + i * Layout.STEP
			var z := Layout.Z0 + j * Layout.STEP
			var dx := _h(i + 1, j) - _h(i - 1, j)
			var dz := _h(i, j + 1) - _h(i, j - 1)
			var ny := Vector3(-dx, 4.0 * Layout.STEP * 0.5, -dz).normalized().y
			var c := color_for(x, z, heights[k], ny, path_w[k], river_w[k])
			var jit := (float(Terrain.hash2(i, j, 5) ) - 0.5) * 0.035
			vcol[k] = Color(clampf(c.r + jit, 0, 1), clampf(c.g + jit, 0, 1), clampf(c.b + jit * 0.7, 0, 1))
	for j in range(nz - 1):
		var z0 := Layout.Z0 + j * Layout.STEP
		var z1 := z0 + Layout.STEP
		for i in range(nx - 1):
			var x0 := Layout.X0 + i * Layout.STEP
			var x1 := x0 + Layout.STEP
			var k00 := j * nx + i
			var k10 := k00 + 1
			var k01 := k00 + nx
			var k11 := k01 + 1
			var p00 := Vector3(x0, heights[k00], z0)
			var p10 := Vector3(x1, heights[k10], z0)
			var p01 := Vector3(x0, heights[k01], z1)
			var p11 := Vector3(x1, heights[k11], z1)
			kit.tri_colors(p00, p10, p11, vcol[k00], vcol[k10], vcol[k11])
			kit.tri_colors(p00, p11, p01, vcol[k00], vcol[k11], vcol[k01])
	var col_faces := kit.verts.duplicate()
	# skirts hide cracks against the distant mountain mesh
	_add_skirts(kit)
	var mi := MeshInstance3D.new()
	mi.name = "TerrainMesh"
	mi.mesh = kit.commit()
	mi.material_override = Mats.world(0.28)
	add_child(mi)
	var body := StaticBody3D.new()
	body.name = "TerrainBody"
	var cs := CollisionShape3D.new()
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(col_faces)
	cs.shape = shape
	body.add_child(cs)
	add_child(body)
	_build_outer()


func _add_skirts(kit: MeshKit) -> void:
	var col := Color(0.4, 0.4, 0.38)
	for i in range(nx - 1):
		for side: int in [0, nz - 1]:
			var z := Layout.Z0 + side * Layout.STEP
			var a := Vector3(Layout.X0 + i * Layout.STEP, _h(i, side), z)
			var b := Vector3(Layout.X0 + (i + 1) * Layout.STEP, _h(i + 1, side), z)
			var a2 := a - Vector3(0, 30, 0)
			var b2 := b - Vector3(0, 30, 0)
			kit.quad(a, b, b2, a2, col)
			kit.quad(b, a, a2, b2, col)
	for j in range(nz - 1):
		for side: int in [0, nx - 1]:
			var x := Layout.X0 + side * Layout.STEP
			var a := Vector3(x, _h(side, j), Layout.Z0 + j * Layout.STEP)
			var b := Vector3(x, _h(side, j + 1), Layout.Z0 + (j + 1) * Layout.STEP)
			var a2 := a - Vector3(0, 30, 0)
			var b2 := b - Vector3(0, 30, 0)
			kit.quad(a, b, b2, a2, col)
			kit.quad(b, a, a2, b2, col)


static func outer_height(x: float, z: float) -> float:
	var h := base_height(x, z)
	var dx := maxf(0.0, maxf(Layout.X0 - x, x - Layout.X1))
	var dz := maxf(0.0, maxf(Layout.Z0 - z, z - Layout.Z1))
	var dout := sqrt(dx * dx + dz * dz)
	if h > 4.0:
		h += sstep(0.0, 90.0, dout) * fbm(x * 0.011, z * 0.011, 9, 3) * 150.0
	return minf(h, 280.0)


func _build_outer() -> void:
	var kit := MeshKit.new(11)
	kit.jitter = 0.02
	var step := 10.0
	var ox0 := -430.0
	var ox1 := 430.0
	var oz0 := -460.0
	var oz1 := 430.0
	var cx := int((ox1 - ox0) / step)
	var cz := int((oz1 - oz0) / step)
	var hs := PackedFloat32Array()
	hs.resize((cx + 1) * (cz + 1))
	for j in range(cz + 1):
		for i in range(cx + 1):
			hs[j * (cx + 1) + i] = outer_height(ox0 + i * step, oz0 + j * step)
	for j in range(cz):
		for i in range(cx):
			var x0 := ox0 + i * step
			var z0 := oz0 + j * step
			var x1 := x0 + step
			var z1 := z0 + step
			if x0 >= Layout.X0 and x1 <= Layout.X1 and z0 >= Layout.Z0 and z1 <= Layout.Z1:
				continue
			var p00 := Vector3(x0, hs[j * (cx + 1) + i], z0)
			var p10 := Vector3(x1, hs[j * (cx + 1) + i + 1], z0)
			var p01 := Vector3(x0, hs[(j + 1) * (cx + 1) + i], z1)
			var p11 := Vector3(x1, hs[(j + 1) * (cx + 1) + i + 1], z1)
			if p00.y < -3 and p10.y < -3 and p01.y < -3 and p11.y < -3:
				continue # hidden under the fjord
			var na := (p11 - p00).cross(p10 - p00).normalized()
			var ca := color_for(x0 + 6, z0 + 3, (p00.y + p10.y + p11.y) / 3.0, absf(na.y), 0.0, 0.0)
			kit.tri(p00, p10, p11, ca)
			var nb := (p01 - p00).cross(p11 - p00).normalized()
			var cb := color_for(x0 + 3, z0 + 6, (p00.y + p11.y + p01.y) / 3.0, absf(nb.y), 0.0, 0.0)
			kit.tri(p00, p11, p01, cb)
	var mi := MeshInstance3D.new()
	mi.name = "Mountains"
	mi.mesh = kit.commit()
	mi.material_override = Mats.world(0.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
