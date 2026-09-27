class_name MeshKit
extends RefCounted
## Tiny procedural mesh builder for flat-shaded, vertex-coloured low-poly
## geometry. Faces are wound clockwise (Godot's front face convention).

var verts := PackedVector3Array()
var norms := PackedVector3Array()
var cols := PackedColorArray()
var uvs := PackedVector2Array()
var xform := Transform3D.IDENTITY
## Random colour jitter per face (0 = off) for a hand-painted pixel feel.
var jitter := 0.0
var _rng := RandomNumberGenerator.new()


func _init(seed_value: int = 1) -> void:
	_rng.seed = seed_value


func clear() -> void:
	verts.clear()
	norms.clear()
	cols.clear()
	uvs.clear()


func is_empty() -> bool:
	return verts.is_empty()


func _jit(c: Color) -> Color:
	if jitter <= 0.0:
		return c
	var j := _rng.randf_range(-jitter, jitter)
	return Color(clampf(c.r + j, 0, 1), clampf(c.g + j, 0, 1), clampf(c.b + j * 0.8, 0, 1), c.a)


## Triangle given in world/local space (already transformed).
func tri_raw(a: Vector3, b: Vector3, c: Vector3, col: Color, uv_a := Vector2.ZERO, uv_b := Vector2.ZERO, uv_c := Vector2.ZERO) -> void:
	var n := (c - a).cross(b - a)
	if n.length_squared() < 1e-12:
		return
	n = n.normalized()
	verts.append(a)
	verts.append(b)
	verts.append(c)
	norms.append(n)
	norms.append(n)
	norms.append(n)
	cols.append(col)
	cols.append(col)
	cols.append(col)
	uvs.append(uv_a)
	uvs.append(uv_b)
	uvs.append(uv_c)


## Triangle with a colour per vertex (smoothly blended), flat normal.
func tri_colors(a: Vector3, b: Vector3, c: Vector3, ca: Color, cb: Color, cc: Color) -> void:
	var n := (c - a).cross(b - a)
	if n.length_squared() < 1e-12:
		return
	n = n.normalized()
	verts.append(a)
	verts.append(b)
	verts.append(c)
	norms.append(n)
	norms.append(n)
	norms.append(n)
	cols.append(ca)
	cols.append(cb)
	cols.append(cc)
	uvs.append(Vector2.ZERO)
	uvs.append(Vector2.ZERO)
	uvs.append(Vector2.ZERO)


func tri(a: Vector3, b: Vector3, c: Vector3, col: Color) -> void:
	tri_raw(xform * a, xform * b, xform * c, _jit(col))


## Quad a-b-c-d in clockwise order when seen from the front.
func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color) -> void:
	var jc := _jit(col)
	var ta := xform * a
	var tb := xform * b
	var tc := xform * c
	var td := xform * d
	tri_raw(ta, tb, tc, jc)
	tri_raw(ta, tc, td, jc)


## Axis aligned box (in the current transform) centred at `c`.
func box(c: Vector3, size: Vector3, col: Color, top_col: Variant = null) -> void:
	var h := size * 0.5
	var p := [
		c + Vector3(-h.x, -h.y, -h.z), c + Vector3(h.x, -h.y, -h.z),
		c + Vector3(h.x, -h.y, h.z), c + Vector3(-h.x, -h.y, h.z),
		c + Vector3(-h.x, h.y, -h.z), c + Vector3(h.x, h.y, -h.z),
		c + Vector3(h.x, h.y, h.z), c + Vector3(-h.x, h.y, h.z),
	]
	var tc: Color = col if top_col == null else top_col
	quad(p[4], p[5], p[6], p[7], tc) # top
	quad(p[3], p[2], p[1], p[0], col.darkened(0.25)) # bottom
	quad(p[7], p[6], p[2], p[3], col) # +z
	quad(p[5], p[4], p[0], p[1], col) # -z
	quad(p[6], p[5], p[1], p[2], col) # +x
	quad(p[4], p[7], p[3], p[0], col) # -x


## Box with arbitrary rotation (yaw, pitch, roll in radians).
func box_rot(c: Vector3, size: Vector3, rot: Vector3, col: Color) -> void:
	var saved := xform
	xform = xform * Transform3D(Basis.from_euler(rot), c)
	box(Vector3.ZERO, size, col)
	xform = saved


func cylinder(base: Vector3, r_bottom: float, r_top: float, height: float, sides: int, col: Color, cap_col: Variant = null, caps := true) -> void:
	var cc: Color = col if cap_col == null else cap_col
	for i in range(sides):
		var a0 := TAU * float(i) / sides
		var a1 := TAU * float(i + 1) / sides
		var d0 := Vector3(sin(a0), 0, cos(a0))
		var d1 := Vector3(sin(a1), 0, cos(a1))
		var b0 := base + d0 * r_bottom
		var b1 := base + d1 * r_bottom
		var t0 := base + d0 * r_top + Vector3(0, height, 0)
		var t1 := base + d1 * r_top + Vector3(0, height, 0)
		if r_top > 0.001:
			quad(t0, t1, b1, b0, col)
		else:
			tri(t0, b1, b0, col)
		if caps:
			if r_top > 0.001:
				tri(base + Vector3(0, height, 0), t1, t0, cc)
			tri(base, b0, b1, col.darkened(0.3))


func cone(base: Vector3, r: float, height: float, sides: int, col: Color, caps := true) -> void:
	cylinder(base, r, 0.0, height, sides, col, null, caps)


## Low poly sphere-ish blob (UV sphere with optional random displacement).
func blob(c: Vector3, radius: Vector3, col: Color, rings := 4, segs := 6, noise := 0.0, flatten_bottom := false) -> void:
	var pts := []
	for r in range(rings + 1):
		var row := []
		var v := float(r) / rings
		var phi := PI * v
		for s in range(segs):
			var th := TAU * float(s) / segs + (0.5 if r % 2 == 1 else 0.0) * TAU / segs
			var p := Vector3(sin(phi) * sin(th), cos(phi), sin(phi) * cos(th))
			if noise > 0.0 and r > 0 and r < rings:
				p *= 1.0 + _rng.randf_range(-noise, noise)
			if flatten_bottom and p.y < -0.2:
				p.y = -0.2 - (p.y + 0.2) * 0.15
			row.append(c + p * radius)
		pts.append(row)
	for r in range(rings):
		for s in range(segs):
			var s1 := (s + 1) % segs
			var a: Vector3 = pts[r][s]
			var b: Vector3 = pts[r][s1]
			var cc: Vector3 = pts[r + 1][s1]
			var d: Vector3 = pts[r + 1][s]
			var shade := col.lightened(0.06) if r < rings / 2 else col
			if r == 0:
				tri(a, cc, d, shade)
			elif r == rings - 1:
				tri(a, b, d, shade)
			else:
				quad(a, b, cc, d, shade)


## Gable roof prism along local X. Width = x extent, depth = z extent.
func gable_roof(c: Vector3, width: float, depth: float, height: float, overhang: float, col: Color, gable_col: Color) -> void:
	var hw := width * 0.5 + overhang
	var hd := depth * 0.5 + overhang
	var y0 := c.y
	var y1 := c.y + height
	var l0 := Vector3(c.x - hw, y0, c.z - hd)
	var l1 := Vector3(c.x - hw, y0, c.z + hd)
	var r0 := Vector3(c.x + hw, y0, c.z - hd)
	var r1 := Vector3(c.x + hw, y0, c.z + hd)
	var tl := Vector3(c.x - hw, y1, c.z)
	var tr := Vector3(c.x + hw, y1, c.z)
	# roof slopes
	quad(tl, tr, r1, l1, col)
	quad(tr, tl, l0, r0, col.darkened(0.08))
	# underside
	quad(l1, r1, r0, l0, col.darkened(0.45))
	# gables (triangles at the ends, inset by overhang)
	var gw := width * 0.5
	var gd := depth * 0.5
	var gl0 := Vector3(c.x - gw, y0, c.z - gd)
	var gl1 := Vector3(c.x - gw, y0, c.z + gd)
	var gr0 := Vector3(c.x + gw, y0, c.z - gd)
	var gr1 := Vector3(c.x + gw, y0, c.z + gd)
	var gtl := Vector3(c.x - gw, y0 + height * (gd / hd), c.z)
	var gtr := Vector3(c.x + gw, y0 + height * (gd / hd), c.z)
	tri(gtl, gl1, gl0, gable_col)
	tri(gtr, gr0, gr1, gable_col)


func commit(existing: ArrayMesh = null) -> ArrayMesh:
	var mesh := existing if existing != null else ArrayMesh.new()
	if verts.is_empty():
		return mesh
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Faces for a ConcavePolygonShape3D (collision).
func faces() -> PackedVector3Array:
	return verts
