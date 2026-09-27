class_name Water
extends Node3D
## Fjord, river and mountain lake surfaces. Depth is baked into vertex colours
## so the shader can draw shallow water and shore foam without depth textures.

var terrain: Terrain


func build(t: Terrain) -> void:
	terrain = t
	_build_fjord()
	_build_ring()
	_build_river()
	_build_lake()
	_build_waterfall_mist()


func _add_mesh(verts: PackedVector3Array, cols: PackedColorArray, uvs: PackedVector2Array, mesh_name: String) -> MeshInstance3D:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	var norms := PackedVector3Array()
	norms.resize(verts.size())
	for i in range(0, verts.size(), 3):
		var n := (verts[i + 2] - verts[i]).cross(verts[i + 1] - verts[i])
		n = n.normalized() if n.length_squared() > 1e-10 else Vector3.UP
		if n.y < 0.0:
			n = -n
		norms[i] = n
		norms[i + 1] = n
		norms[i + 2] = n
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = mesh
	mi.material_override = Mats.water()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


func _depth_col(depth: float, flowing := 0.0, white := 0.0) -> Color:
	return Color(clampf(depth / 8.0, 0.0, 1.0), flowing, white, 1.0)


func _tri(v: PackedVector3Array, c: PackedColorArray, u: PackedVector2Array,
		a: Vector3, b: Vector3, cc: Vector3, ca: Color, cb: Color, ccc: Color,
		ua := Vector2.ZERO, ub := Vector2.ZERO, uc := Vector2.ZERO) -> void:
	v.append(a)
	v.append(b)
	v.append(cc)
	c.append(ca)
	c.append(cb)
	c.append(ccc)
	u.append(ua)
	u.append(ub)
	u.append(uc)


func _build_fjord() -> void:
	var v := PackedVector3Array()
	var c := PackedColorArray()
	var u := PackedVector2Array()
	var step := Layout.STEP
	for j in range(terrain.nz - 1):
		var z0 := Layout.Z0 + j * step
		if z0 < 40.0:
			continue
		for i in range(terrain.nx - 1):
			var x0 := Layout.X0 + i * step
			var h00 := terrain.heights[j * terrain.nx + i]
			var h10 := terrain.heights[j * terrain.nx + i + 1]
			var h01 := terrain.heights[(j + 1) * terrain.nx + i]
			var h11 := terrain.heights[(j + 1) * terrain.nx + i + 1]
			if minf(minf(h00, h10), minf(h01, h11)) > Layout.SEA_Y + 0.25:
				continue
			var y := Layout.SEA_Y
			var p00 := Vector3(x0, y, z0)
			var p10 := Vector3(x0 + step, y, z0)
			var p01 := Vector3(x0, y, z0 + step)
			var p11 := Vector3(x0 + step, y, z0 + step)
			var c00 := _depth_col(y - h00)
			var c10 := _depth_col(y - h10)
			var c01 := _depth_col(y - h01)
			var c11 := _depth_col(y - h11)
			_tri(v, c, u, p00, p10, p11, c00, c10, c11)
			_tri(v, c, u, p00, p11, p01, c00, c11, c01)
	_add_mesh(v, c, u, "Fjord")


func _build_ring() -> void:
	var v := PackedVector3Array()
	var c := PackedColorArray()
	var u := PackedVector2Array()
	var y := Layout.SEA_Y
	var big := 3000.0
	var deep := _depth_col(8.0)
	var rects := [
		[Vector2(-big, Layout.Z1), Vector2(big, big)],
		[Vector2(-big, -big), Vector2(big, Layout.Z0)],
		[Vector2(-big, Layout.Z0), Vector2(Layout.X0, Layout.Z1)],
		[Vector2(Layout.X1, Layout.Z0), Vector2(big, Layout.Z1)],
	]
	for r in rects:
		var a: Vector2 = r[0]
		var b: Vector2 = r[1]
		var p00 := Vector3(a.x, y, a.y)
		var p10 := Vector3(b.x, y, a.y)
		var p01 := Vector3(a.x, y, b.y)
		var p11 := Vector3(b.x, y, b.y)
		_tri(v, c, u, p00, p10, p11, deep, deep, deep)
		_tri(v, c, u, p00, p11, p01, deep, deep, deep)
	_add_mesh(v, c, u, "Sea")


func _build_river() -> void:
	var pts: Array = terrain.river_points()
	var samples: Array = [] # Vector3 centre (x, water y, z)
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var n := int(ceil(Vector2(b.x - a.x, b.z - a.z).length() / 1.5))
		for k in range(n):
			var t := float(k) / n
			samples.append(Vector3(lerpf(a.x, b.x, t), lerpf(a.y, b.y, t) + Layout.RIVER_WATER_OFFSET, lerpf(a.z, b.z, t)))
	var last: Vector3 = pts[pts.size() - 1]
	samples.append(Vector3(last.x, last.y + Layout.RIVER_WATER_OFFSET, last.z))
	var v := PackedVector3Array()
	var c := PackedColorArray()
	var u := PackedVector2Array()
	var half := Layout.RIVER_HALF + 2.6
	var dist := 0.0
	var prev_l := Vector3.ZERO
	var prev_r := Vector3.ZERO
	var prev_c := Vector3.ZERO
	var prev_cl := Color()
	var prev_cr := Color()
	var prev_cc := Color()
	for i in range(samples.size()):
		var s: Vector3 = samples[i]
		var s0: Vector3 = samples[maxi(i - 1, 0)]
		var s1: Vector3 = samples[mini(i + 1, samples.size() - 1)]
		var dir := Vector3(s1.x - s0.x, 0, s1.z - s0.z).normalized()
		var side := Vector3(-dir.z, 0, dir.x)
		var drop := absf(s1.y - s0.y) / maxf(Vector2(s1.x - s0.x, s1.z - s0.z).length(), 0.1)
		var white := clampf((drop - 0.35) * 1.4, 0.0, 1.0)
		var l := s - side * half
		var r := s + side * half
		var cl := _depth_col(s.y - terrain.height_at(l.x, l.z), 1.0, white)
		var cr := _depth_col(s.y - terrain.height_at(r.x, r.z), 1.0, white)
		var cc := _depth_col(s.y - terrain.height_at(s.x, s.z), 1.0, white)
		if i > 0:
			dist += Vector2(s.x - prev_c.x, s.z - prev_c.z).length()
			var d0 := dist - Vector2(s.x - prev_c.x, s.z - prev_c.z).length()
			# left half
			_tri(v, c, u, prev_l, prev_c, s, prev_cl, prev_cc, cc, Vector2(0, d0), Vector2(0.5, d0), Vector2(0.5, dist))
			_tri(v, c, u, prev_l, s, l, prev_cl, cc, cl, Vector2(0, d0), Vector2(0.5, dist), Vector2(0, dist))
			# right half
			_tri(v, c, u, prev_c, prev_r, r, prev_cc, prev_cr, cr, Vector2(0.5, d0), Vector2(1, d0), Vector2(1, dist))
			_tri(v, c, u, prev_c, r, s, prev_cc, cr, cc, Vector2(0.5, d0), Vector2(1, dist), Vector2(0.5, dist))
		prev_l = l
		prev_r = r
		prev_c = s
		prev_cl = cl
		prev_cr = cr
		prev_cc = cc
	_add_mesh(v, c, u, "River")


func _build_lake() -> void:
	var lx: float = Layout.LAKE[0]
	var lz: float = Layout.LAKE[1]
	var lr: float = Layout.LAKE[2] + 2.5
	var ly: float = Layout.LAKE[3]
	var v := PackedVector3Array()
	var c := PackedColorArray()
	var u := PackedVector2Array()
	var rings := 8
	var segs := 28
	for ri in range(rings):
		var r0 := lr * float(ri) / rings
		var r1 := lr * float(ri + 1) / rings
		for si in range(segs):
			var a0 := TAU * si / segs
			var a1 := TAU * (si + 1) / segs
			var p0 := Vector3(lx + sin(a0) * r0, ly, lz + cos(a0) * r0)
			var p1 := Vector3(lx + sin(a1) * r0, ly, lz + cos(a1) * r0)
			var q0 := Vector3(lx + sin(a0) * r1, ly, lz + cos(a0) * r1)
			var q1 := Vector3(lx + sin(a1) * r1, ly, lz + cos(a1) * r1)
			var cp0 := _depth_col(ly - terrain.height_at(p0.x, p0.z))
			var cp1 := _depth_col(ly - terrain.height_at(p1.x, p1.z))
			var cq0 := _depth_col(ly - terrain.height_at(q0.x, q0.z))
			var cq1 := _depth_col(ly - terrain.height_at(q1.x, q1.z))
			_tri(v, c, u, p0, q0, q1, cp0, cq0, cq1)
			if ri > 0:
				_tri(v, c, u, p0, q1, p1, cp0, cq1, cp1)
	_add_mesh(v, c, u, "Lake")


func _build_waterfall_mist() -> void:
	var p := CPUParticles3D.new()
	p.name = "WaterfallMist"
	var base := Vector3(31.0, 0.0, -44.0)
	base.y = terrain.height_at(base.x, base.z) + 0.8
	p.position = base
	p.amount = 40
	p.lifetime = 1.6
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(2.5, 0.3, 1.0)
	p.direction = Vector3(0, 1, 0.3)
	p.spread = 35.0
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 2.5
	p.gravity = Vector3(0, -1.2, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.1
	var q := BoxMesh.new()
	q.size = Vector3(0.35, 0.35, 0.35)
	q.material = Mats.unshaded(Color(0.92, 0.97, 1.0))
	p.mesh = q
	add_child(p)
