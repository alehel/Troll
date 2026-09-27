class_name CharacterModel
extends Node3D
## Procedurally built, procedurally animated character made of primitive
## shapes. Models face +Z. Call animate() every frame.

var kind := "troll"
var body: Node3D # bobbing root for everything above the legs
var head: Node3D
var arm_l: Node3D
var arm_r: Node3D
var leg_l: Node3D
var leg_r: Node3D
var tail: Node3D
var height := 2.3
var mode := "idle"
var _phase := 0.0
var _t := 0.0
var _tremble := 0.0
var _body_base_y := 0.0


# --------------------------------------------------------------------------
# primitive helpers
# --------------------------------------------------------------------------
static func _sphere(r: float, segs := 10, rings := 6) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = segs
	m.rings = rings
	return m


static func _capsule(r: float, h: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = maxf(h, r * 2.0)
	m.radial_segments = 8
	m.rings = 3
	return m


static func _cyl(top: float, bottom: float, h: float, segs := 8) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = segs
	m.rings = 1
	return m


func _part(parent: Node3D, mesh: Mesh, col: Color, pos: Vector3, scl := Vector3.ONE, rot := Vector3.ZERO, outline := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = Mats.solid(col, outline, 0.03 if kind != "human" else 0.02)
	mi.position = pos
	mi.scale = scl
	mi.rotation = rot
	parent.add_child(mi)
	return mi


func _pivot(parent: Node3D, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	parent.add_child(n)
	return n


# --------------------------------------------------------------------------
# builders
# --------------------------------------------------------------------------
func build_troll(look: Dictionary) -> void:
	kind = "troll"
	var skin: Color = look.get("skin", Color(0.6, 0.53, 0.45))
	var belly: Color = look.get("belly", skin.lightened(0.15))
	var hair: Color = look.get("hair", Color(0.45, 0.62, 0.3))
	var nose_s: float = look.get("nose", 1.0)
	var size: float = look.get("size", 1.0)
	scale = Vector3.ONE * size
	height = 2.5 * size
	var dark := Color(0.12, 0.1, 0.09)
	# legs
	leg_l = _pivot(self, Vector3(-0.34, 0.62, 0))
	leg_r = _pivot(self, Vector3(0.34, 0.62, 0))
	for leg in [leg_l, leg_r]:
		_part(leg, _capsule(0.2, 0.75), skin.darkened(0.08), Vector3(0, -0.28, 0))
		_part(leg, _sphere(0.27), skin.darkened(0.12), Vector3(0, -0.58, 0.1), Vector3(1.0, 0.5, 1.3))
	body = _pivot(self, Vector3.ZERO)
	_part(body, _sphere(0.8, 12, 7), skin, Vector3(0, 1.28, 0), Vector3(1.0, 1.02, 0.9))
	_part(body, _sphere(0.56), belly, Vector3(0, 1.12, 0.3), Vector3(1.0, 1.05, 0.62), Vector3.ZERO, false)
	# tail
	tail = _pivot(body, Vector3(0, 0.95, -0.66))
	_part(tail, _capsule(0.06, 0.75), skin, Vector3(0, -0.12, -0.3), Vector3.ONE, Vector3(-1.1, 0, 0))
	_part(tail, _sphere(0.15), hair, Vector3(0, -0.28, -0.62))
	# arms
	arm_l = _pivot(body, Vector3(-0.8, 1.66, 0.02))
	arm_r = _pivot(body, Vector3(0.8, 1.66, 0.02))
	for arm in [arm_l, arm_r]:
		_part(arm, _capsule(0.15, 1.0), skin, Vector3(0, -0.45, 0))
		_part(arm, _sphere(0.21), skin.darkened(0.05), Vector3(0, -0.95, 0.03))
	arm_l.rotation.z = -0.18
	arm_r.rotation.z = 0.18
	# head
	head = _pivot(body, Vector3(0, 2.02, 0.06))
	_part(head, _sphere(0.54, 12, 7), skin, Vector3(0, 0.02, 0))
	var nose_col := skin.lerp(Color(0.82, 0.52, 0.46), 0.3)
	_part(head, _capsule(0.17 * nose_s, 0.55 * nose_s), nose_col, Vector3(0, -0.04, 0.5 + 0.08 * nose_s), Vector3.ONE, Vector3(1.35, 0, 0))
	_part(head, _sphere(0.2 * nose_s), nose_col, Vector3(0, -0.12, 0.6 + 0.2 * nose_s), Vector3(1.0, 0.95, 0.95))
	for sx in [-1.0, 1.0]:
		_part(head, _sphere(0.085, 8, 4), dark, Vector3(sx * 0.18, 0.13, 0.46), Vector3.ONE, Vector3.ZERO, false)
		_part(head, _sphere(0.03, 6, 3), Color(1, 1, 1), Vector3(sx * 0.18 - 0.025, 0.16, 0.53), Vector3.ONE, Vector3.ZERO, false)
		_part(head, BoxMesh.new(), hair.darkened(0.35), Vector3(sx * 0.19, 0.28, 0.46), Vector3(0.2, 0.05, 0.06), Vector3(0, 0, -sx * 0.25), false)
		# ears
		_part(head, _cyl(0.0, 0.13, 0.42, 5), skin, Vector3(sx * 0.55, 0.08, -0.02), Vector3.ONE, Vector3(0, 0, -sx * 1.25))
		# tiny tusks
		_part(head, _cyl(0.0, 0.04, 0.12, 4), Color(0.98, 0.95, 0.85), Vector3(sx * 0.13, -0.32, 0.42), Vector3.ONE, Vector3.ZERO, false)
	_part(head, BoxMesh.new(), dark, Vector3(0, -0.36, 0.44), Vector3(0.26, 0.035, 0.04), Vector3.ZERO, false)
	# hair styles
	match look.get("hair_style", "moss"):
		"moss":
			for p in [Vector3(0, 0.5, -0.05), Vector3(0.22, 0.42, 0.05), Vector3(-0.24, 0.44, -0.02), Vector3(0.05, 0.4, -0.3)]:
				_part(head, _sphere(0.22, 8, 5), hair, p, Vector3(1.0, 0.7, 1.0))
			_part(head, _sphere(0.08, 6, 4), Color(0.95, 0.5, 0.6), Vector3(0.28, 0.6, 0.12), Vector3.ONE, Vector3.ZERO, false)
			_part(head, _sphere(0.04, 6, 3), Color(1.0, 0.9, 0.4), Vector3(0.3, 0.64, 0.18), Vector3.ONE, Vector3.ZERO, false)
		"bun":
			_part(head, _sphere(0.5, 10, 6), hair, Vector3(0, 0.18, -0.1), Vector3(1.05, 0.75, 1.0))
			_part(head, _sphere(0.22, 8, 5), hair, Vector3(0, 0.62, -0.18))
			_part(head, _cyl(0.02, 0.02, 0.5, 4), Color(0.45, 0.3, 0.2), Vector3(0, 0.66, -0.18), Vector3.ONE, Vector3(0, 0, 1.2), false)
		"tree":
			_part(head, _sphere(0.4, 8, 5), hair, Vector3(0, 0.36, -0.05), Vector3(1.1, 0.5, 1.1))
			_part(head, _cyl(0.04, 0.06, 0.7, 5), Color(0.9, 0.88, 0.82), Vector3(0.1, 0.8, -0.05))
			_part(head, _sphere(0.3, 8, 5), Color(0.85, 0.72, 0.25), Vector3(0.1, 1.2, -0.05), Vector3(1.0, 0.9, 1.0))
			_part(head, _sphere(0.2, 8, 5), Color(0.8, 0.6, 0.2), Vector3(0.28, 1.05, 0.05))
		"tuft":
			_part(head, _cyl(0.0, 0.2, 0.55, 6), hair, Vector3(0, 0.7, -0.05), Vector3.ONE, Vector3(-0.2, 0, 0))
			_part(head, _cyl(0.0, 0.14, 0.4, 6), hair, Vector3(0.16, 0.6, -0.02), Vector3.ONE, Vector3(0, 0, -0.5))
		"flowers":
			_part(head, _sphere(0.48, 10, 6), hair, Vector3(0, 0.22, -0.1), Vector3(1.1, 0.7, 1.05))
			var fc := [Color(0.98, 0.9, 0.4), Color(0.95, 0.45, 0.55), Color(1, 1, 1), Color(0.95, 0.6, 0.3)]
			for i in range(5):
				var a := TAU * i / 5.0
				_part(head, _sphere(0.08, 6, 3), fc[i % fc.size()], Vector3(sin(a) * 0.35, 0.5, cos(a) * 0.3 - 0.1), Vector3.ONE, Vector3.ZERO, false)
		"beard":
			_part(head, _sphere(0.42, 10, 6), hair, Vector3(0, -0.45, 0.28), Vector3(1.0, 1.4, 0.7))
			_part(head, _sphere(0.4, 8, 5), hair, Vector3(0, 0.38, -0.12), Vector3(1.1, 0.5, 1.0))
			for sx2 in [-1.0, 1.0]:
				_part(head, _sphere(0.1, 6, 4), hair, Vector3(sx2 * 0.2, 0.3, 0.45), Vector3(1.4, 0.6, 0.8))
	if look.has("scarf"):
		var sc: Color = look["scarf"]
		var tor := TorusMesh.new()
		tor.inner_radius = 0.42
		tor.outer_radius = 0.66
		tor.rings = 12
		tor.ring_segments = 6
		_part(body, tor, sc, Vector3(0, 1.78, 0.02), Vector3(1.0, 0.9, 0.95))
		_part(body, BoxMesh.new(), sc, Vector3(0.3, 1.45, 0.5), Vector3(0.22, 0.55, 0.08), Vector3(0.15, 0, 0.1))
	if look.has("shawl"):
		_part(body, _sphere(0.85, 10, 6), look["shawl"], Vector3(0, 1.62, -0.02), Vector3(1.08, 0.42, 1.0))
	if look.get("glasses", false):
		for sx3 in [-1.0, 1.0]:
			var g := TorusMesh.new()
			g.inner_radius = 0.08
			g.outer_radius = 0.11
			g.rings = 8
			g.ring_segments = 4
			_part(head, g, Color(0.25, 0.2, 0.15), Vector3(sx3 * 0.18, 0.13, 0.52), Vector3.ONE, Vector3(PI * 0.5, 0, 0), false)
	_body_base_y = 0.0


func build_human(look: Dictionary) -> void:
	kind = "human"
	var skin: Color = look.get("skin", Color(0.95, 0.8, 0.68))
	var hair: Color = look.get("hair", Color(0.5, 0.35, 0.2))
	var top: Color = look.get("top", Color(0.4, 0.5, 0.7))
	var bottom: Color = look.get("bottom", Color(0.3, 0.3, 0.35))
	var h: float = look.get("height", 1.0)
	scale = Vector3.ONE * h
	height = 1.7 * h
	var dark := Color(0.1, 0.08, 0.08)
	leg_l = _pivot(self, Vector3(-0.1, 0.52, 0))
	leg_r = _pivot(self, Vector3(0.1, 0.52, 0))
	for leg in [leg_l, leg_r]:
		_part(leg, _capsule(0.085, 0.52), bottom, Vector3(0, -0.24, 0))
		_part(leg, BoxMesh.new(), Color(0.25, 0.18, 0.14), Vector3(0, -0.5, 0.04), Vector3(0.15, 0.08, 0.24))
	body = _pivot(self, Vector3.ZERO)
	_part(body, _capsule(0.25, 0.66), top, Vector3(0, 0.84, 0))
	_part(body, _cyl(0.25, 0.3, 0.22, 8), bottom, Vector3(0, 0.56, 0))
	if look.has("apron"):
		_part(body, BoxMesh.new(), look["apron"], Vector3(0, 0.7, 0.22), Vector3(0.34, 0.5, 0.04))
	arm_l = _pivot(body, Vector3(-0.3, 1.05, 0))
	arm_r = _pivot(body, Vector3(0.3, 1.05, 0))
	for arm in [arm_l, arm_r]:
		_part(arm, _capsule(0.068, 0.46), top, Vector3(0, -0.2, 0))
		_part(arm, _sphere(0.075, 6, 4), skin, Vector3(0, -0.44, 0))
	arm_l.rotation.z = -0.12
	arm_r.rotation.z = 0.12
	head = _pivot(body, Vector3(0, 1.38, 0))
	_part(head, _sphere(0.25, 10, 6), skin, Vector3.ZERO)
	for sx in [-1.0, 1.0]:
		_part(head, _sphere(0.032, 6, 3), dark, Vector3(sx * 0.085, 0.02, 0.225), Vector3.ONE, Vector3.ZERO, false)
	_part(head, _sphere(0.045, 6, 3), skin.darkened(0.08), Vector3(0, -0.03, 0.245), Vector3.ONE, Vector3.ZERO, false)
	if h < 0.8:
		for sx in [-1.0, 1.0]:
			_part(head, _sphere(0.035, 6, 3), Color(0.95, 0.55, 0.55), Vector3(sx * 0.13, -0.05, 0.2), Vector3.ONE, Vector3.ZERO, false)
	match look.get("hair_style", "short"):
		"short":
			_part(head, _sphere(0.265, 10, 6), hair, Vector3(0, 0.06, -0.035), Vector3(1.0, 0.85, 1.0))
		"bun":
			_part(head, _sphere(0.265, 10, 6), hair, Vector3(0, 0.06, -0.035), Vector3(1.0, 0.85, 1.0))
			_part(head, _sphere(0.1, 8, 4), hair, Vector3(0, 0.24, -0.16))
		"braids":
			_part(head, _sphere(0.265, 10, 6), hair, Vector3(0, 0.06, -0.035), Vector3(1.0, 0.85, 1.0))
			for sx in [-1.0, 1.0]:
				_part(head, _capsule(0.05, 0.3), hair, Vector3(sx * 0.2, -0.2, -0.06), Vector3.ONE, Vector3(0, 0, sx * 0.15))
				_part(head, _sphere(0.035, 6, 3), Color(0.9, 0.3, 0.3), Vector3(sx * 0.225, -0.34, -0.06), Vector3.ONE, Vector3.ZERO, false)
		"long":
			_part(head, _sphere(0.27, 10, 6), hair, Vector3(0, 0.04, -0.05), Vector3(1.02, 0.95, 1.0))
			_part(head, BoxMesh.new(), hair, Vector3(0, -0.22, -0.14), Vector3(0.42, 0.4, 0.12))
		"bald":
			_part(head, _sphere(0.26, 10, 6), hair, Vector3(0, -0.02, -0.06), Vector3(1.0, 0.55, 0.95))
	if look.get("beard", false):
		_part(head, _sphere(0.17, 8, 5), hair, Vector3(0, -0.14, 0.13), Vector3(1.0, 1.05, 0.7))
	if look.get("glasses", false):
		_part(head, BoxMesh.new(), Color(0.15, 0.12, 0.1), Vector3(0, 0.025, 0.24), Vector3(0.24, 0.05, 0.02), Vector3.ZERO, false)
	var hc: Color = look.get("hat_color", Color(0.8, 0.3, 0.3))
	match look.get("hat", "none"):
		"beanie":
			_part(head, _sphere(0.27, 10, 6), hc, Vector3(0, 0.1, -0.01), Vector3(1.0, 0.7, 1.0))
			_part(head, _sphere(0.075, 6, 4), Color(0.97, 0.95, 0.9), Vector3(0, 0.3, 0))
		"souwester":
			_part(head, _cyl(0.17, 0.26, 0.2, 10), hc, Vector3(0, 0.2, -0.02))
			_part(head, _cyl(0.36, 0.38, 0.03, 12), hc, Vector3(0, 0.1, -0.06), Vector3.ONE, Vector3(-0.15, 0, 0))
		"cap":
			_part(head, _sphere(0.27, 10, 6), hc, Vector3(0, 0.09, -0.02), Vector3(1.0, 0.62, 1.0))
			_part(head, BoxMesh.new(), hc.darkened(0.15), Vector3(0, 0.1, 0.25), Vector3(0.3, 0.03, 0.18))
		"scarf":
			_part(head, _sphere(0.275, 10, 6), hc, Vector3(0, 0.07, -0.03), Vector3(1.02, 0.85, 1.02))
			_part(head, _sphere(0.06, 6, 3), hc.darkened(0.15), Vector3(0, -0.12, -0.24))


func build_goat(col: Color, bell := false) -> void:
	kind = "animal"
	height = 1.0
	var dark := Color(0.15, 0.12, 0.1)
	body = _pivot(self, Vector3.ZERO)
	_part(body, _capsule(0.26, 1.0), col, Vector3(0, 0.62, 0), Vector3.ONE, Vector3(PI * 0.5, 0, 0))
	leg_l = _pivot(self, Vector3(-0.14, 0.45, 0.3))
	leg_r = _pivot(self, Vector3(0.14, 0.45, 0.3))
	arm_l = _pivot(self, Vector3(-0.14, 0.45, -0.3))
	arm_r = _pivot(self, Vector3(0.14, 0.45, -0.3))
	for leg in [leg_l, leg_r, arm_l, arm_r]:
		_part(leg, _capsule(0.055, 0.46), col.darkened(0.1), Vector3(0, -0.22, 0))
	head = _pivot(body, Vector3(0, 0.95, 0.5))
	_part(head, _capsule(0.13, 0.38), col, Vector3(0, 0, 0.08), Vector3.ONE, Vector3(1.1, 0, 0))
	for sx in [-1.0, 1.0]:
		_part(head, _cyl(0.0, 0.045, 0.3, 5), Color(0.45, 0.4, 0.35), Vector3(sx * 0.08, 0.2, -0.05), Vector3.ONE, Vector3(-0.5, 0, sx * 0.2))
		_part(head, _sphere(0.028, 5, 3), dark, Vector3(sx * 0.1, 0.06, 0.15), Vector3.ONE, Vector3.ZERO, false)
		_part(head, _sphere(0.06, 5, 3), col, Vector3(sx * 0.15, 0.04, 0.0), Vector3(1.5, 0.6, 0.8))
	_part(head, _capsule(0.035, 0.16), Color(0.9, 0.88, 0.82), Vector3(0, -0.2, 0.2))
	tail = _pivot(body, Vector3(0, 0.78, -0.62))
	_part(tail, _sphere(0.07, 5, 3), col, Vector3(0, 0.03, 0))
	if bell:
		_part(body, _cyl(0.05, 0.08, 0.1, 6), Color(0.9, 0.75, 0.3), Vector3(0, 0.7, 0.62))


func build_sheep() -> void:
	kind = "animal"
	height = 1.0
	var wool := Color(0.95, 0.94, 0.9)
	var face := Color(0.18, 0.16, 0.15)
	body = _pivot(self, Vector3.ZERO)
	_part(body, _sphere(0.45, 10, 6), wool, Vector3(0, 0.66, 0), Vector3(1.0, 0.85, 1.25))
	for p in [Vector3(0.2, 0.9, 0.2), Vector3(-0.2, 0.92, -0.2), Vector3(0, 0.95, 0.35)]:
		_part(body, _sphere(0.2, 8, 4), wool, p)
	leg_l = _pivot(self, Vector3(-0.16, 0.35, 0.28))
	leg_r = _pivot(self, Vector3(0.16, 0.35, 0.28))
	arm_l = _pivot(self, Vector3(-0.16, 0.35, -0.28))
	arm_r = _pivot(self, Vector3(0.16, 0.35, -0.28))
	for leg in [leg_l, leg_r, arm_l, arm_r]:
		_part(leg, _capsule(0.05, 0.36), face, Vector3(0, -0.17, 0))
	head = _pivot(body, Vector3(0, 0.82, 0.58))
	_part(head, _sphere(0.16, 8, 5), face, Vector3(0, 0, 0.05), Vector3(0.9, 1.0, 1.2))
	_part(head, _sphere(0.14, 8, 4), wool, Vector3(0, 0.12, -0.02))
	for sx in [-1.0, 1.0]:
		_part(head, _sphere(0.06, 5, 3), face, Vector3(sx * 0.16, 0.02, -0.02), Vector3(1.6, 0.6, 0.8))


# --------------------------------------------------------------------------
# animation
# --------------------------------------------------------------------------
func set_mode(m: String) -> void:
	mode = m


func tremble(amount: float) -> void:
	_tremble = amount


## speed: horizontal speed in m/s.
func animate(delta: float, speed: float) -> void:
	_t += delta
	var moving := speed > 0.15
	var stride := 1.0 if kind == "troll" else 1.3
	if kind == "animal":
		stride = 1.6
	if moving:
		_phase += delta * (3.0 + speed * 1.6) * stride
	else:
		_phase = lerpf(_phase, round(_phase / PI) * PI, clampf(delta * 6.0, 0, 1))
	var swing := sin(_phase)
	var amp := clampf(speed * 0.18, 0.0, 0.9)
	var bob := absf(sin(_phase)) * clampf(speed * 0.025, 0.0, 0.12)
	var breathe := sin(_t * 2.2) * 0.012
	if body:
		body.position.y = bob
		body.scale = Vector3(1.0 - breathe * 0.5, 1.0 + breathe, 1.0 - breathe * 0.5)
		body.rotation = Vector3.ZERO
		body.position.x = 0.0
	if leg_l:
		leg_l.rotation.x = swing * amp
		leg_r.rotation.x = -swing * amp
	if kind == "animal":
		if arm_l:
			arm_l.rotation.x = -swing * amp
			arm_r.rotation.x = swing * amp
		if head:
			head.rotation.x = (0.4 + sin(_t * 0.7) * 0.2) if (mode == "graze") else sin(_t * 1.3) * 0.08
		if tail:
			tail.rotation.y = sin(_t * 9.0) * 0.4
		return
	var arm_swing := -swing * amp * 0.9
	var la := Vector3(arm_swing, 0, -0.15)
	var ra := Vector3(-arm_swing, 0, 0.15)
	var head_rot := Vector3(sin(_t * 0.9) * 0.03, sin(_t * 0.5) * 0.08, 0)
	match mode:
		"flee":
			la = Vector3(-2.7 + sin(_t * 20.0) * 0.35, 0, -0.4)
			ra = Vector3(-2.7 + cos(_t * 20.0) * 0.35, 0, 0.4)
			head_rot = Vector3(-0.25, sin(_t * 12.0) * 0.2, 0)
		"carry":
			la = Vector3(-2.9, 0, -0.35)
			ra = Vector3(-2.9, 0, 0.35)
		"talk":
			head_rot = Vector3(sin(_t * 6.0) * 0.06, sin(_t * 1.7) * 0.1, 0)
			la = Vector3(-0.2 + sin(_t * 3.0) * 0.15, 0, -0.25)
			ra = Vector3(-0.4 + sin(_t * 3.7 + 1.0) * 0.25, 0, 0.3)
		"wave":
			ra = Vector3(-2.6, 0, 0.6 + sin(_t * 10.0) * 0.4)
		"cheer":
			la = Vector3(-2.8, 0, -0.6 + sin(_t * 8.0) * 0.2)
			ra = Vector3(-2.8, 0, 0.6 - sin(_t * 8.0) * 0.2)
			if body:
				body.position.y = absf(sin(_t * 6.0)) * 0.15
		"dance":
			la = Vector3(-1.6 + sin(_t * 5.0) * 0.8, 0, -0.9)
			ra = Vector3(-1.6 - sin(_t * 5.0) * 0.8, 0, 0.9)
			if body:
				body.position.y = absf(sin(_t * 5.0)) * 0.2
				body.rotation.z = sin(_t * 2.5) * 0.12
			if leg_l:
				leg_l.rotation.x = sin(_t * 5.0) * 0.4
				leg_r.rotation.x = -sin(_t * 5.0) * 0.4
		"cower":
			la = Vector3(-2.2, 0, 0.5)
			ra = Vector3(-2.2, 0, -0.5)
			head_rot = Vector3(0.4, 0, 0)
			if body:
				body.rotation.x = 0.2
		"sit":
			if leg_l:
				leg_l.rotation.x = -1.4
				leg_r.rotation.x = -1.4
			if body:
				body.position.y = -0.45 * (1.0 if kind == "troll" else 0.8)
			la = Vector3(-0.5, 0, -0.3)
			ra = Vector3(-0.5, 0, 0.3)
		"sleep":
			if leg_l:
				leg_l.rotation.x = -1.4
				leg_r.rotation.x = -1.4
			if body:
				body.position.y = -0.45
			head_rot = Vector3(0.45, 0, 0.25)
			la = Vector3(-0.3, 0, -0.1)
			ra = Vector3(-0.3, 0, 0.1)
		"lift":
			la = Vector3(-1.2, 0, -0.1)
			ra = Vector3(-1.2, 0, 0.1)
			if body:
				body.rotation.x = 0.25
		"shake":
			la = Vector3(-1.4 + sin(_t * 25.0) * 0.3, 0, -0.2)
			ra = Vector3(-1.4 - sin(_t * 25.0) * 0.3, 0, 0.2)
			if body:
				body.position.x = sin(_t * 30.0) * 0.05
	if arm_l:
		arm_l.rotation = arm_l.rotation.lerp(la, clampf(delta * 12.0, 0.0, 1.0))
		arm_r.rotation = arm_r.rotation.lerp(ra, clampf(delta * 12.0, 0.0, 1.0))
	if head:
		head.rotation = head.rotation.lerp(head_rot, clampf(delta * 8.0, 0.0, 1.0))
	if tail:
		tail.rotation.y = sin(_t * 2.0 + _phase) * 0.35
		tail.rotation.x = sin(_t * 1.3) * 0.1
	if _tremble > 0.0 and body:
		body.position.x = sin(_t * 60.0) * 0.02 * _tremble
