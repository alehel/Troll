class_name Buildings
extends Node3D
## Builds the village of Lillevik and the troll dwellings on the plateau as a
## handful of merged meshes plus box colliders.

const WHITE := Color(0.93, 0.91, 0.86)
const STONE := Color(0.5, 0.49, 0.47)
const WOOD := Color(0.5, 0.36, 0.24)
const DARK_WOOD := Color(0.33, 0.23, 0.16)
const TURF := Color(0.38, 0.54, 0.26)
const FALU := Color(0.62, 0.2, 0.16)
const OCHRE := Color(0.86, 0.68, 0.34)
const SLATE := Color(0.3, 0.32, 0.36)
const GLASS := Color(0.2, 0.24, 0.32)

var terrain: Terrain
var kit := MeshKit.new(31)
var glass := MeshKit.new(32)
var glow := MeshKit.new(33)
var body: StaticBody3D
var small: StaticBody3D
## id -> {door: Vector3, gift: Vector3, xf: Transform3D}
var houses := {}
var smoke_points: Array = []
var smoke_nodes: Array = []
## Bridge decks: [{a, dir, len, width, pts}]
var bridges: Array = []
var lamp_points: Array = []
var fire_points: Array = []
var window_material: ShaderMaterial
const DOCK_X := 9.0
const DOCK_Z0 := 69.0
const DOCK_Z1 := 85.5
var dock_y := 1.0
var lamp_material: ShaderMaterial
## Circles (x, z, r) where vegetation should not grow.
var clearings: Array = []


func build(t: Terrain) -> void:
	terrain = t
	dock_y = maxf(terrain.height_at(DOCK_X, DOCK_Z0 + 0.8) + 0.06, 0.9)
	kit.jitter = 0.015
	body = StaticBody3D.new()
	body.name = "BuildingColliders"
	body.collision_layer = 1 | 16
	add_child(body)
	# small props block walking but not the camera
	small = StaticBody3D.new()
	small.name = "PropColliders"
	small.collision_layer = 1
	add_child(small)
	for id in Layout.HOUSES.keys():
		_build_house(id)
	_build_farm_extras()
	_build_ole_extras()
	_build_village_props()
	_build_dock()
	_build_bridges()
	_build_fences()
	_build_player_hollow()
	_build_granny_hut()
	_build_stein_circle()
	_build_lyng_garden()
	_build_troll_ring()
	_build_bonfire()
	_build_city_gate()
	_commit()


# --------------------------------------------------------------------------
# helpers
# --------------------------------------------------------------------------
func gy(x: float, z: float) -> float:
	return terrain.height_at(x, z)


func place(x: float, z: float, fx: float, fz: float, sink := 0.0) -> Transform3D:
	var dir := Vector2(fx - x, fz - z)
	var yaw := atan2(dir.x, dir.y) if dir.length() > 0.01 else 0.0
	return Transform3D(Basis(Vector3.UP, yaw), Vector3(x, gy(x, z) - sink, z))


func place_yaw(x: float, z: float, yaw: float, y := NAN) -> Transform3D:
	var yy := gy(x, z) if is_nan(y) else y
	return Transform3D(Basis(Vector3.UP, yaw), Vector3(x, yy, z))


func collider(xf: Transform3D, center: Vector3, size: Vector3, small_prop := false) -> void:
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.transform = xf * Transform3D(Basis.IDENTITY, center)
	(small if small_prop else body).add_child(cs)


func cyl_collider(pos: Vector3, radius: float, height: float, small_prop := false) -> void:
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = radius
	sh.height = height
	cs.shape = sh
	cs.position = pos + Vector3(0, height * 0.5, 0)
	(small if small_prop else body).add_child(cs)


func clear_zone(x: float, z: float, r: float) -> void:
	clearings.append(Vector3(x, z, r))


func window(k_xf: Transform3D, c: Vector3, facing: Vector3, frame := WHITE) -> void:
	## A framed window on a wall. `facing` is the wall normal in local space.
	var yaw := atan2(facing.x, facing.z)
	var wxf := k_xf * Transform3D(Basis(Vector3.UP, yaw), c)
	kit.xform = wxf
	kit.box(Vector3.ZERO, Vector3(0.95, 0.95, 0.08), frame)
	glass.xform = wxf
	glass.box(Vector3(0, 0, 0.03), Vector3(0.7, 0.7, 0.06), GLASS)
	kit.box(Vector3(0, 0, 0.07), Vector3(0.7, 0.07, 0.02), frame)
	kit.box(Vector3(0, 0, 0.07), Vector3(0.07, 0.7, 0.02), frame)


func smoke(pos: Vector3) -> void:
	smoke_points.append(pos)


# --------------------------------------------------------------------------
# houses
# --------------------------------------------------------------------------
func _generic_house(xf: Transform3D, w: float, d: float, h: float, wall: Color, trim: Color, roof: Color, roof_h := 2.0, door_col := Color(0.25, 0.35, 0.45), door_x := 0.0) -> Dictionary:
	kit.xform = xf
	var base := 0.3
	kit.box(Vector3(0, base - 0.6, 0), Vector3(w + 0.3, 1.2, d + 0.3), STONE)
	kit.box(Vector3(0, base + h * 0.5, 0), Vector3(w, h, d), wall)
	# siding lines
	var lines := int(h / 0.45)
	for i in range(1, lines):
		var y := base + i * 0.45
		kit.box(Vector3(0, y, d * 0.5 + 0.01), Vector3(w, 0.05, 0.03), wall.darkened(0.12))
		kit.box(Vector3(0, y, -d * 0.5 - 0.01), Vector3(w, 0.05, 0.03), wall.darkened(0.12))
		kit.box(Vector3(w * 0.5 + 0.01, y, 0), Vector3(0.03, 0.05, d), wall.darkened(0.12))
		kit.box(Vector3(-w * 0.5 - 0.01, y, 0), Vector3(0.03, 0.05, d), wall.darkened(0.12))
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			kit.box(Vector3(sx * w * 0.5, base + h * 0.5, sz * d * 0.5), Vector3(0.22, h, 0.22), trim)
	var roof_col := roof
	kit.gable_roof(Vector3(0, base + h, 0), w, d, roof_h, 0.45, roof_col, wall)
	# bark/board edge under a turf roof
	if roof == TURF:
		kit.box(Vector3(0, base + h + 0.05, d * 0.5 + 0.42), Vector3(w + 0.9, 0.12, 0.12), DARK_WOOD)
		kit.box(Vector3(0, base + h + 0.05, -d * 0.5 - 0.42), Vector3(w + 0.9, 0.12, 0.12), DARK_WOOD)
	# door
	kit.box(Vector3(door_x, base + 0.95, d * 0.5 + 0.06), Vector3(1.0, 1.9, 0.1), door_col)
	kit.box(Vector3(door_x, base + 1.95, d * 0.5 + 0.08), Vector3(1.3, 0.14, 0.12), trim)
	kit.box(Vector3(door_x + 0.3, base + 0.95, d * 0.5 + 0.13), Vector3(0.08, 0.08, 0.06), Color(0.85, 0.75, 0.3))
	kit.box(Vector3(door_x, base - 0.1, d * 0.5 + 0.5), Vector3(1.4, 0.45, 0.8), STONE.lightened(0.1))
	# windows
	var wy := base + h * 0.55
	var span := w * 0.5 - 1.2
	for wx in [-span, span]:
		if absf(wx - door_x) > 1.2:
			window(xf, Vector3(wx, wy, d * 0.5 + 0.02), Vector3(0, 0, 1), trim)
		window(xf, Vector3(wx, wy, -d * 0.5 - 0.02), Vector3(0, 0, -1), trim)
	window(xf, Vector3(w * 0.5 + 0.02, wy, 0), Vector3(1, 0, 0), trim)
	window(xf, Vector3(-w * 0.5 - 0.02, wy, 0), Vector3(-1, 0, 0), trim)
	if h > 4.0:
		for wx in [-span, 0.0, span]:
			window(xf, Vector3(wx, base + h * 0.8, d * 0.5 + 0.02), Vector3(0, 0, 1), trim)
	# chimney
	kit.xform = xf
	var ch := Vector3(w * 0.25, base + h + roof_h * 0.55, -d * 0.12)
	kit.box(ch, Vector3(0.7, roof_h * 1.1 + 0.6, 0.7), STONE)
	kit.box(ch + Vector3(0, roof_h * 0.55 + 0.35, 0), Vector3(0.85, 0.15, 0.85), STONE.darkened(0.2))
	smoke(xf * (ch + Vector3(0, roof_h * 0.6 + 0.5, 0)))
	collider(xf, Vector3(0, base + h * 0.5, 0), Vector3(w + 0.2, h + 1.2, d + 0.2))
	var door := xf * Vector3(door_x, 0, d * 0.5 + 0.9)
	var gift := xf * Vector3(door_x + 1.3, 0, d * 0.5 + 1.1)
	door.y = gy(door.x, door.z)
	gift.y = gy(gift.x, gift.z)
	return {"door": door, "gift": gift, "xf": xf}


func _build_house(id: String) -> void:
	var d: Array = Layout.HOUSES[id]
	var x: float = d[0]
	var z: float = d[1]
	var xf := place(x, z, d[2], d[3])
	var info := {}
	match id:
		"bakery":
			info = _generic_house(xf, 8.0, 6.0, 2.8, OCHRE, WHITE, TURF, 2.2, Color(0.55, 0.22, 0.18))
			kit.xform = xf
			# hanging sign with a bun
			kit.box(Vector3(2.2, 2.9, 3.4), Vector3(0.08, 0.08, 0.9), DARK_WOOD)
			kit.box(Vector3(2.2, 2.45, 3.75), Vector3(0.1, 0.7, 0.7), WOOD)
			kit.blob(Vector3(2.28, 2.45, 3.75), Vector3(0.06, 0.25, 0.25), Color(0.85, 0.6, 0.3), 2, 6)
		"store":
			info = _generic_house(xf, 8.5, 6.0, 2.9, WHITE, Color(0.55, 0.2, 0.18), TURF, 2.2, Color(0.3, 0.45, 0.35))
			kit.xform = xf
			kit.box(Vector3(0, 3.0, 3.1), Vector3(3.2, 0.6, 0.12), Color(0.55, 0.2, 0.18))
			kit.box(Vector3(0, 3.0, 3.18), Vector3(2.8, 0.35, 0.05), Color(0.95, 0.9, 0.75))
			# crates and barrels
			for i in range(3):
				kit.box(Vector3(-3.0 + i * 0.1, 0.35 + i * 0.7, 3.6), Vector3(0.7, 0.7, 0.7), WOOD.lightened(0.1))
			kit.cylinder(Vector3(3.2, 0.0, 3.8), 0.4, 0.4, 1.0, 7, Color(0.45, 0.3, 0.2))
			kit.cylinder(Vector3(3.7, 0.0, 3.2), 0.4, 0.4, 1.0, 7, Color(0.45, 0.3, 0.2))
		"mayor":
			info = _generic_house(xf, 9.5, 7.0, 5.0, WHITE, Color(0.24, 0.36, 0.3), SLATE, 2.6, Color(0.24, 0.36, 0.3))
			kit.xform = xf
			# porch roof
			kit.box(Vector3(0, 2.6, 4.2), Vector3(2.6, 0.12, 1.6), SLATE)
			kit.box(Vector3(-1.1, 1.3, 4.8), Vector3(0.14, 2.6, 0.14), WHITE)
			kit.box(Vector3(1.1, 1.3, 4.8), Vector3(0.14, 2.6, 0.14), WHITE)
			# flagpole with the Norwegian flag
			kit.cylinder(Vector3(4.5, 0, 6.0), 0.08, 0.06, 7.0, 5, WHITE)
			kit.box(Vector3(5.4, 6.4, 6.0), Vector3(1.6, 1.1, 0.05), Color(0.73, 0.1, 0.18))
			kit.box(Vector3(5.1, 6.4, 6.0), Vector3(0.3, 1.12, 0.06), WHITE)
			kit.box(Vector3(5.4, 6.4, 6.0), Vector3(1.62, 0.3, 0.06), WHITE)
			kit.box(Vector3(5.1, 6.4, 6.0), Vector3(0.14, 1.14, 0.07), Color(0.0, 0.16, 0.4))
			kit.box(Vector3(5.4, 6.4, 6.0), Vector3(1.64, 0.14, 0.07), Color(0.0, 0.16, 0.4))
		"astrid":
			info = _generic_house(xf, 7.0, 5.5, 2.7, Color(0.95, 0.83, 0.47), WHITE, TURF, 2.0, Color(0.3, 0.5, 0.6))
			kit.xform = xf
			# a little swing
			kit.box(Vector3(-4.8, 1.2, 1.5), Vector3(0.15, 2.4, 0.15), WOOD)
			kit.box(Vector3(-4.8, 1.2, 3.5), Vector3(0.15, 2.4, 0.15), WOOD)
			kit.box(Vector3(-4.8, 2.4, 2.5), Vector3(0.15, 0.15, 2.3), WOOD)
			kit.box(Vector3(-4.8, 1.4, 2.5), Vector3(0.03, 1.9, 0.03), Color(0.8, 0.75, 0.6))
			kit.box(Vector3(-4.8, 0.45, 2.5), Vector3(0.5, 0.06, 0.8), Color(0.75, 0.3, 0.25))
		"ole":
			info = _generic_house(xf, 6.0, 5.0, 2.5, FALU, WHITE, TURF, 1.9, Color(0.2, 0.3, 0.45))
		"farm":
			info = _generic_house(xf, 8.5, 6.0, 3.0, FALU, WHITE, TURF, 2.2, Color(0.9, 0.88, 0.8))
		"chapel":
			info = _build_chapel(xf)
	houses[id] = info
	clear_zone(x, z, 8.5)


func _build_chapel(xf: Transform3D) -> Dictionary:
	# long axis along local Z, door at +Z (gable end)
	kit.xform = xf
	var w := 5.0
	var d := 9.0
	var h := 3.4
	kit.box(Vector3(0, -0.3, 0), Vector3(w + 0.3, 1.2, d + 0.3), STONE)
	kit.box(Vector3(0, 0.3 + h * 0.5, 0), Vector3(w, h, d), WHITE)
	var rot := xf * Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3.ZERO)
	kit.xform = rot
	kit.gable_roof(Vector3(0, 0.3 + h, 0), d, w, 2.8, 0.35, Color(0.24, 0.22, 0.24), WHITE)
	kit.xform = xf
	# tower + spire at the front
	kit.box(Vector3(0, 0.3 + h + 2.4, d * 0.5 - 1.0), Vector3(1.8, 4.8, 1.8), WHITE)
	var spire := xf * Transform3D(Basis(Vector3.UP, PI * 0.25), Vector3(0, 0.3 + h + 4.8, d * 0.5 - 1.0))
	kit.xform = spire
	kit.cone(Vector3.ZERO, 1.45, 3.6, 4, Color(0.24, 0.22, 0.24))
	kit.xform = xf
	kit.box(Vector3(0, 0.3 + h + 8.8, d * 0.5 - 1.0), Vector3(0.1, 0.9, 0.1), Color(0.85, 0.75, 0.3))
	kit.box(Vector3(0, 0.3 + h + 8.95, d * 0.5 - 1.0), Vector3(0.5, 0.1, 0.1), Color(0.85, 0.75, 0.3))
	# door + windows
	kit.box(Vector3(0, 1.3, d * 0.5 + 0.06), Vector3(1.3, 2.2, 0.1), Color(0.45, 0.25, 0.18))
	for zz in [-2.5, 0.0, 2.5]:
		window(xf, Vector3(w * 0.5 + 0.02, 2.0, zz), Vector3(1, 0, 0))
		window(xf, Vector3(-w * 0.5 - 0.02, 2.0, zz), Vector3(-1, 0, 0))
	collider(xf, Vector3(0, 0.3 + h * 0.5, 0), Vector3(w + 0.2, h + 1.2, d + 0.2))
	# small graveyard fence stones / flowers
	kit.xform = xf
	for i in range(4):
		kit.box(Vector3(-3.8, 0.35, -2.5 + i * 1.6), Vector3(0.5, 0.7, 0.2), STONE.lightened(0.15))
	var door := xf * Vector3(0, 0, d * 0.5 + 1.0)
	door.y = gy(door.x, door.z)
	var gift := xf * Vector3(1.4, 0, d * 0.5 + 1.2)
	gift.y = gy(gift.x, gift.z)
	return {"door": door, "gift": gift, "xf": xf}


func _build_farm_extras() -> void:
	# barn
	var bxf := place(-64.0, 44.0, -52.0, 44.0)
	kit.xform = bxf
	kit.box(Vector3(0, -0.3, 0), Vector3(10.3, 1.2, 8.3), STONE)
	kit.box(Vector3(0, 0.3 + 2.2, 0), Vector3(10, 4.4, 8), FALU)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			kit.box(Vector3(sx * 5, 2.5, sz * 4), Vector3(0.25, 4.4, 0.25), WHITE)
	kit.gable_roof(Vector3(0, 4.7, 0), 10, 8, 3.0, 0.4, TURF, FALU)
	# big barn doors with white X
	kit.box(Vector3(0, 1.6, 4.06), Vector3(3.6, 3.0, 0.1), FALU.darkened(0.15))
	kit.box_rot(Vector3(-0.9, 1.6, 4.12), Vector3(0.15, 3.3, 0.05), Vector3(0, 0, 0.55), WHITE)
	kit.box_rot(Vector3(-0.9, 1.6, 4.12), Vector3(0.15, 3.3, 0.05), Vector3(0, 0, -0.55), WHITE)
	kit.box_rot(Vector3(0.9, 1.6, 4.12), Vector3(0.15, 3.3, 0.05), Vector3(0, 0, 0.55), WHITE)
	kit.box_rot(Vector3(0.9, 1.6, 4.12), Vector3(0.15, 3.3, 0.05), Vector3(0, 0, -0.55), WHITE)
	kit.box(Vector3(0, 3.2, 4.1), Vector3(3.8, 0.18, 0.12), WHITE)
	collider(bxf, Vector3(0, 2.5, 0), Vector3(10.2, 5.0, 8.2))
	clear_zone(-64, 44, 9)
	# stabbur (storehouse on stilts)
	var sxf := place(-38.0, 29.0, -30.0, 38.0)
	kit.xform = sxf
	for sx in [-1.2, 1.2]:
		for sz in [-1.0, 1.0]:
			kit.box(Vector3(sx, 0.4, sz), Vector3(0.3, 1.0, 0.3), STONE)
			kit.box(Vector3(sx, 0.95, sz), Vector3(0.5, 0.12, 0.5), DARK_WOOD)
	kit.box(Vector3(0, 2.1, 0), Vector3(3.2, 2.2, 2.8), Color(0.55, 0.36, 0.22))
	kit.box(Vector3(0, 3.35, 0), Vector3(3.8, 0.3, 3.4), Color(0.5, 0.33, 0.2))
	kit.gable_roof(Vector3(0, 3.5, 0), 3.8, 3.4, 1.6, 0.35, TURF, Color(0.55, 0.36, 0.22))
	kit.box(Vector3(0, 1.8, 1.42), Vector3(0.9, 1.5, 0.08), DARK_WOOD)
	collider(sxf, Vector3(0, 1.8, 0), Vector3(3.4, 3.6, 3.0))
	clear_zone(-38, 29, 4)
	# hay bales
	for p in [Vector2(-56, 36), Vector2(-57.5, 37), Vector2(-56.5, 38.6)]:
		var y := gy(p.x, p.y)
		kit.xform = Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3(p.x, y + 0.6, p.y))
		kit.cylinder(Vector3(0, -0.7, 0), 0.6, 0.6, 1.4, 8, Color(0.85, 0.75, 0.4), Color(0.78, 0.66, 0.34))
		cyl_collider(Vector3(p.x, y, p.y), 0.7, 1.2, true)


func _build_ole_extras() -> void:
	# boathouse (naust) by the water
	var nxf := place(22.0, 66.0, 22.0, 80.0, 0.3)
	kit.xform = nxf
	kit.box(Vector3(0, 1.3, 0), Vector3(4.5, 2.6, 6.0), FALU.darkened(0.1))
	kit.gable_roof(Vector3(0, 2.6, 0), 4.5, 6.0, 1.7, 0.3, TURF, FALU.darkened(0.1))
	collider(nxf, Vector3(0, 1.3, 0), Vector3(4.6, 3.0, 6.1))
	# the naust's gable faces the water: make a door on +z
	kit.box(Vector3(0, 1.1, 3.02), Vector3(2.4, 2.0, 0.08), DARK_WOOD)
	clear_zone(22, 66, 4)
	# fish drying rack (hjell)
	var a: Vector2 = Layout.ANCHORS["net_rack"]
	var rxf := place(a.x + 2.0, a.y - 1.5, a.x + 2.0, a.y + 5.0)
	kit.xform = rxf
	for sx in [-2.0, 0.0, 2.0]:
		kit.box_rot(Vector3(sx, 1.1, 0.35), Vector3(0.12, 2.4, 0.12), Vector3(0.3, 0, 0), WOOD)
		kit.box_rot(Vector3(sx, 1.1, -0.35), Vector3(0.12, 2.4, 0.12), Vector3(-0.3, 0, 0), WOOD)
	kit.box(Vector3(0, 2.15, 0), Vector3(4.6, 0.1, 0.1), WOOD)
	for i in range(7):
		kit.box(Vector3(-1.8 + i * 0.6, 1.7, 0), Vector3(0.18, 0.8, 0.08), Color(0.78, 0.74, 0.62))
	collider(rxf, Vector3(0, 1.1, 0), Vector3(4.6, 2.2, 1.0), true)


func _build_village_props() -> void:
	# well in the square
	var w: Vector2 = Layout.ANCHORS["well"]
	var y := gy(w.x, w.y)
	kit.xform = Transform3D(Basis.IDENTITY, Vector3(w.x, y, w.y))
	kit.cylinder(Vector3(0, -0.2, 0), 1.1, 1.1, 1.1, 9, STONE, STONE.darkened(0.3))
	kit.cylinder(Vector3(0, 0.85, 0), 0.85, 0.85, 0.06, 9, Color(0.15, 0.2, 0.3))
	kit.box(Vector3(-1.0, 1.5, 0), Vector3(0.18, 2.2, 0.18), WOOD)
	kit.box(Vector3(1.0, 1.5, 0), Vector3(0.18, 2.2, 0.18), WOOD)
	kit.gable_roof(Vector3(0, 2.5, 0), 2.4, 1.6, 0.8, 0.15, TURF, WOOD)
	kit.box(Vector3(0, 1.9, 0), Vector3(2.0, 0.1, 0.1), DARK_WOOD)
	kit.cylinder(Vector3(0.1, 1.2, 0), 0.22, 0.25, 0.4, 6, Color(0.55, 0.4, 0.26))
	cyl_collider(Vector3(w.x, y - 0.2, w.y), 1.2, 2.0, true)
	# notice board
	var nb: Vector2 = Layout.ANCHORS["notice_board"]
	var nxf := place(nb.x, nb.y - 1.2, 0.0, 44.0)
	kit.xform = nxf
	kit.box(Vector3(-1.1, 1.0, 0), Vector3(0.15, 2.0, 0.15), DARK_WOOD)
	kit.box(Vector3(1.1, 1.0, 0), Vector3(0.15, 2.0, 0.15), DARK_WOOD)
	kit.box(Vector3(0, 1.55, 0), Vector3(2.3, 1.1, 0.1), WOOD)
	kit.box(Vector3(0, 2.2, 0), Vector3(2.6, 0.15, 0.4), DARK_WOOD)
	kit.box(Vector3(-0.55, 1.6, 0.07), Vector3(0.6, 0.7, 0.02), Color(0.95, 0.93, 0.85))
	kit.box(Vector3(0.35, 1.45, 0.07), Vector3(0.55, 0.5, 0.02), Color(0.95, 0.88, 0.7))
	kit.box(Vector3(0.6, 1.85, 0.07), Vector3(0.4, 0.35, 0.02), Color(0.85, 0.92, 0.95))
	collider(nxf, Vector3(0, 1.0, 0), Vector3(2.4, 2.0, 0.4), true)
	# benches
	for b in [[Vector2(-5, 47), Vector2(0, 44)], [Vector2(5, 47.5), Vector2(0, 44)], [Vector2(10, 38.5), Vector2(10, 44)], [Vector2(-10, 57), Vector2(-14, 70)]]:
		var p: Vector2 = b[0]
		var f: Vector2 = b[1]
		var bxf := place(p.x, p.y, f.x, f.y)
		kit.xform = bxf
		kit.box(Vector3(0, 0.45, 0), Vector3(1.8, 0.1, 0.5), WOOD)
		kit.box(Vector3(0, 0.75, -0.25), Vector3(1.8, 0.4, 0.08), WOOD)
		kit.box(Vector3(-0.75, 0.22, 0), Vector3(0.1, 0.45, 0.45), DARK_WOOD)
		kit.box(Vector3(0.75, 0.22, 0), Vector3(0.1, 0.45, 0.45), DARK_WOOD)
		collider(bxf, Vector3(0, 0.4, 0), Vector3(1.8, 0.8, 0.6), true)
	# bakery stand
	var bs: Vector2 = Layout.ANCHORS["bakery_stand"]
	var sxf := place(bs.x - 1.2, bs.y - 1.2, 0.0, 44.0)
	kit.xform = sxf
	kit.box(Vector3(0, 0.8, 0), Vector3(2.0, 0.1, 0.9), WOOD)
	for sx in [-0.9, 0.9]:
		kit.box(Vector3(sx, 0.4, 0), Vector3(0.1, 0.8, 0.8), DARK_WOOD)
	kit.box(Vector3(-0.9, 1.4, -0.35), Vector3(0.08, 1.2, 0.08), DARK_WOOD)
	kit.box(Vector3(0.9, 1.4, -0.35), Vector3(0.08, 1.2, 0.08), DARK_WOOD)
	kit.box_rot(Vector3(0, 2.05, 0.05), Vector3(2.3, 0.08, 1.2), Vector3(0.3, 0, 0), Color(0.85, 0.3, 0.3))
	for i in range(4):
		kit.blob(Vector3(-0.7 + i * 0.45, 0.95, 0.05), Vector3(0.18, 0.12, 0.18), Color(0.82, 0.58, 0.3), 2, 6)
	collider(sxf, Vector3(0, 0.5, 0), Vector3(2.0, 1.0, 1.0), true)
	# lamp posts
	for lp in [Vector2(-2.5, 38.5), Vector2(6.5, 48.8), Vector2(-9, 46.8), Vector2(9, 48.2), Vector2(5.2, 62.5), Vector2(-26, 45.6), Vector2(22, 49.2), Vector2(-7, 58)]:
		_lamp_post(lp.x, lp.y)
	# flower boxes & barrels scattered
	for fb in [Vector2(-12, 32), Vector2(13, 31), Vector2(-3, 20), Vector2(4, 20)]:
		kit.xform = Transform3D(Basis.IDENTITY, Vector3(fb.x, gy(fb.x, fb.y), fb.y))
		kit.box(Vector3(0, 0.25, 0), Vector3(1.2, 0.5, 0.5), WOOD)
		for i in range(4):
			var c: Color = [Color(0.9, 0.3, 0.35), Color(0.95, 0.85, 0.3), Color(0.95, 0.95, 0.9), Color(0.7, 0.4, 0.8)][i]
			kit.blob(Vector3(-0.45 + i * 0.3, 0.6, 0), Vector3(0.14, 0.14, 0.14), c, 2, 5)
	clear_zone(0, 44, 13)


func _lamp_post(x: float, z: float) -> void:
	var y := gy(x, z)
	kit.xform = Transform3D(Basis.IDENTITY, Vector3(x, y, z))
	kit.cylinder(Vector3(0, 0, 0), 0.12, 0.08, 2.6, 5, Color(0.2, 0.2, 0.22))
	kit.box(Vector3(0, 2.65, 0), Vector3(0.45, 0.08, 0.45), Color(0.2, 0.2, 0.22))
	kit.cone(Vector3(0, 3.1, 0), 0.35, 0.3, 4, Color(0.2, 0.2, 0.22))
	glow.xform = kit.xform
	glow.box(Vector3(0, 2.88, 0), Vector3(0.32, 0.4, 0.32), Color(1.0, 0.85, 0.5))
	lamp_points.append(Vector3(x, y + 2.9, z))
	cyl_collider(Vector3(x, y, z), 0.2, 2.5, true)


func _build_dock() -> void:
	var x := DOCK_X
	var z0 := DOCK_Z0
	var z1 := DOCK_Z1
	var deck_y := dock_y
	kit.xform = Transform3D.IDENTITY
	var zz := z0
	while zz < z1:
		kit.box(Vector3(x, deck_y, zz + 0.3), Vector3(2.6, 0.12, 0.55), WOOD.lightened(0.05 if int(zz * 2) % 2 == 0 else 0.0))
		zz += 0.6
	zz = z0 + 1.0
	while zz < z1:
		for sx in [-1.25, 1.25]:
			kit.cylinder(Vector3(x + sx, -4.0, zz), 0.14, 0.14, deck_y + 4.0, 5, DARK_WOOD)
		zz += 3.2
	var c := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(2.6, 0.5, z1 - z0)
	c.shape = sh
	c.position = Vector3(x, deck_y - 0.2, (z0 + z1) * 0.5)
	body.add_child(c)
	# railing-less edges: invisible low walls so you don't walk off into the fjord
	for sx in [-1.35, 1.35]:
		var cw := CollisionShape3D.new()
		var sw := BoxShape3D.new()
		sw.size = Vector3(0.1, 2.0, z1 - z0 - 5.0)
		cw.shape = sw
		cw.position = Vector3(x + sx, deck_y + 1.0, (z0 + z1) * 0.5 + 2.5)
		body.add_child(cw)
	var ce := CollisionShape3D.new()
	var se := BoxShape3D.new()
	se.size = Vector3(2.8, 2.0, 0.1)
	ce.shape = se
	ce.position = Vector3(x, deck_y + 1.0, z1 + 0.05)
	body.add_child(ce)
	# a rowboat and Ole's fishing boat
	_boat(Transform3D(Basis(Vector3.UP, 0.1), Vector3(x + 2.8, 0.15, 80.5)), 4.2, Color(0.85, 0.85, 0.8), Color(0.25, 0.45, 0.6))
	_boat(Transform3D(Basis(Vector3.UP, -0.2), Vector3(x - 3.4, 0.2, 84.0)), 6.0, Color(0.9, 0.9, 0.86), Color(0.7, 0.2, 0.18))


func _boat(xf: Transform3D, length: float, hull: Color, stripe: Color) -> void:
	kit.xform = xf
	var hl := length * 0.5
	var w := length * 0.22
	# hull: a box with tapered ends
	kit.box(Vector3(0, 0.2, 0), Vector3(w * 1.6, 0.55, length * 0.6), hull)
	kit.box(Vector3(0, 0.45, 0), Vector3(w * 1.65, 0.1, length * 0.6), stripe)
	for s in [-1.0, 1.0]:
		var tip := Vector3(0, 0.7, s * hl)
		var a := Vector3(-w * 0.8, 0.5, s * hl * 0.6)
		var b := Vector3(w * 0.8, 0.5, s * hl * 0.6)
		var a2 := Vector3(-w * 0.8, -0.1, s * hl * 0.6)
		var b2 := Vector3(w * 0.8, -0.1, s * hl * 0.6)
		var bot := Vector3(0, -0.1, s * hl * 0.9)
		if s > 0:
			kit.tri(a, tip, a2, hull)
			kit.tri(a2, tip, bot, hull)
			kit.tri(tip, b, b2, hull)
			kit.tri(tip, b2, bot, hull)
			kit.tri(a, b, tip, hull.darkened(0.3))
		else:
			kit.tri(tip, a, a2, hull)
			kit.tri(tip, a2, bot, hull)
			kit.tri(b, tip, b2, hull)
			kit.tri(b2, tip, bot, hull)
			kit.tri(b, a, tip, hull.darkened(0.3))
	kit.box(Vector3(0, 0.5, 0), Vector3(w * 1.5, 0.08, 0.35), WOOD)


func _build_bridges() -> void:
	# village bridge on the east road (wooden) and the old troll bridge (stone)
	_arch_bridge(Vector2(48.0, 42.4), Vector2(1.0, -0.08), 10.5, 4.0, false)
	_arch_bridge(Vector2(34.0, -12.2), Vector2(1.0, -0.16), 10.5, 3.4, true)


## Deck height on a bridge at (x, z), or NAN when not on a bridge.
func bridge_height(x: float, z: float) -> float:
	for b in bridges:
		var a: Vector2 = b["a"]
		var d: Vector2 = b["dir"]
		var rel := Vector2(x, z) - a
		var along := rel.dot(d)
		var across := absf(rel.dot(Vector2(-d.y, d.x)))
		var len: float = b["len"]
		if along >= 0.0 and along <= len and across <= b["width"] * 0.5:
			var pts: Array = b["pts"]
			var f := along / len * (pts.size() - 1)
			var k := clampi(int(f), 0, pts.size() - 2)
			return lerpf((pts[k] as Vector3).y, (pts[k + 1] as Vector3).y, f - k)
	return NAN


func _arch_bridge(center: Vector2, dir: Vector2, half_len: float, width: float, stone: bool) -> void:
	dir = dir.normalized()
	var side := Vector2(-dir.y, dir.x)
	var side3 := Vector3(side.x, 0, side.y)
	var a := center - dir * half_len
	var b := center + dir * half_len
	var ha := terrain.height_at(a.x, a.y) + 0.03
	var hb := terrain.height_at(b.x, b.y) + 0.03
	var wl := terrain.water_level_at(center.x, center.y)
	var mid := (ha + hb) * 0.5
	var peak := maxf(maxf(ha, hb) + 0.45, wl + 1.3)
	var bump := peak - mid
	var n := 18
	var pts: Array = []
	for i in range(n + 1):
		var t := float(i) / n
		var p := a.lerp(b, t)
		pts.append(Vector3(p.x, lerpf(ha, hb, t) + bump * sin(PI * t), p.y))
	bridges.append({"a": a, "dir": dir, "len": half_len * 2.0, "width": width, "pts": pts})
	var faces := PackedVector3Array()
	var hw := width * 0.5
	var down := Vector3(0, -0.4, 0)
	var deck := STONE.lightened(0.05) if stone else WOOD
	kit.xform = Transform3D.IDENTITY
	for i in range(n):
		var p0: Vector3 = pts[i]
		var p1: Vector3 = pts[i + 1]
		var l0 := p0 - side3 * hw
		var r0 := p0 + side3 * hw
		var l1 := p1 - side3 * hw
		var r1 := p1 + side3 * hw
		var c := deck.darkened(0.06 * (i % 2))
		kit.quad(l0, l1, r1, r0, c)
		kit.quad(r0, r1, r1 + down, r0 + down, c.darkened(0.2))
		kit.quad(l1, l0, l0 + down, l1 + down, c.darkened(0.2))
		kit.quad(l0 + down, r0 + down, r1 + down, l1 + down, c.darkened(0.4))
		faces.append_array([l0, l1, r1, l0, r1, r0])
		# railings / parapets
		var seg := p1 - p0
		var basis := Basis.looking_at(seg.normalized(), Vector3.UP)
		for sgn: float in [-1.0, 1.0]:
			var m := (p0 + p1) * 0.5 + side3 * (hw - 0.15) * sgn
			var xf := Transform3D(basis, m)
			kit.xform = xf
			if stone:
				kit.box(Vector3(0, 0.3, 0), Vector3(0.4, 0.6 + 0.08 * ((i + (1 if sgn > 0 else 0)) % 2), seg.length() + 0.04), STONE.darkened(0.04 * ((i + 1) % 2)))
			else:
				kit.box(Vector3(0, 0.85, 0), Vector3(0.12, 0.12, seg.length() + 0.02), DARK_WOOD)
				kit.box(Vector3(0, 0.45, 0), Vector3(0.14, 0.9, 0.14), DARK_WOOD)
			kit.xform = Transform3D.IDENTITY
			if i > 0 and i < n - 1:
				collider(xf, Vector3(0, 0.7, 0), Vector3(0.3, 1.4, seg.length()), true)
	# supports
	var cpt: Vector3 = pts[n / 2]
	if stone:
		for off: float in [-0.3, 0.3]:
			var q: Vector3 = pts[int(n * (0.5 + off))]
			kit.box(Vector3(q.x, (q.y + terrain.height_at(q.x, q.z)) * 0.5 - 0.5, q.z), Vector3(1.6, maxf(0.5, q.y - terrain.height_at(q.x, q.z) + 0.5), width), STONE.darkened(0.1))
		kit.blob(cpt + side3 * (hw + 0.1) + Vector3(0, 0.55, 0), Vector3(0.5, 0.25, 0.3), Color(0.4, 0.55, 0.26), 2, 5)
	else:
		for off: float in [-0.25, 0.25]:
			var q2: Vector3 = pts[int(n * (0.5 + off))]
			for sgn2: float in [-1.0, 1.0]:
				var pp := q2 + side3 * (hw - 0.3) * sgn2
				var g := terrain.height_at(pp.x, pp.z) - 1.0
				kit.cylinder(Vector3(pp.x, g, pp.z), 0.16, 0.16, pp.y - g, 5, DARK_WOOD)
	var cs := CollisionShape3D.new()
	var sh := ConcavePolygonShape3D.new()
	sh.set_faces(faces)
	sh.backface_collision = true
	cs.shape = sh
	small.add_child(cs)


func _fence(points: Array, col := Color(0.55, 0.42, 0.28)) -> void:
	for i in range(points.size() - 1):
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var len := a.distance_to(b)
		var n := maxi(1, int(len / 2.2))
		for k in range(n + 1):
			var p := a.lerp(b, float(k) / n)
			var y := gy(p.x, p.y)
			kit.xform = Transform3D(Basis.IDENTITY, Vector3(p.x, y, p.y))
			kit.box(Vector3(0, 0.55, 0), Vector3(0.14, 1.2, 0.14), col.darkened(0.15))
		var yaw := atan2(b.x - a.x, b.y - a.y)
		var mid := (a + b) * 0.5
		var my := (gy(a.x, a.y) + gy(b.x, b.y)) * 0.5
		var pitch := atan2(gy(b.x, b.y) - gy(a.x, a.y), len)
		var xf := Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, -pitch), Vector3(mid.x, my, mid.y))
		kit.xform = xf
		kit.box(Vector3(0, 0.45, 0), Vector3(0.08, 0.1, len), col)
		kit.box(Vector3(0, 0.9, 0), Vector3(0.08, 0.1, len), col)
		collider(Transform3D(Basis(Vector3.UP, yaw), Vector3(mid.x, my, mid.y)), Vector3(0, 0.6, 0), Vector3(0.2, 1.4, len), true)


func _build_fences() -> void:
	# goat pen at the farm (gap on the east side to walk in)
	_fence([Vector2(-44, 47), Vector2(-44, 57), Vector2(-60, 57), Vector2(-60, 47), Vector2(-50, 47)])
	# along the fjord beach near the square
	_fence([Vector2(-30, 64), Vector2(-24, 66)])
	# chapel yard
	_fence([Vector2(25, 13), Vector2(35, 13), Vector2(35, 22)], Color(0.9, 0.88, 0.82))


# --------------------------------------------------------------------------
# troll dwellings
# --------------------------------------------------------------------------
func _big_rock(pos: Vector3, size: Vector3, seed_value: int, mossy := true, yaw := 0.0) -> void:
	var rk := MeshKit.new(seed_value)
	rk.jitter = 0.03
	rk.xform = Transform3D(Basis(Vector3.UP, yaw), pos)
	rk.blob(Vector3.ZERO, size, Color(0.52, 0.51, 0.5), 4, 8, 0.18, true)
	if mossy:
		rk.blob(Vector3(0, size.y * 0.72, 0), Vector3(size.x * 0.75, size.y * 0.35, size.z * 0.75), Color(0.4, 0.55, 0.26), 2, 7, 0.12)
	for i in range(rk.verts.size()):
		kit.verts.append(rk.verts[i])
		kit.norms.append(rk.norms[i])
		kit.cols.append(rk.cols[i])
		kit.uvs.append(rk.uvs[i])
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = maxf(size.x, size.z) * 0.85
	sh.height = size.y * 1.8
	cs.shape = sh
	cs.position = pos
	body.add_child(cs)


func _build_player_hollow() -> void:
	var h: Vector2 = Layout.ANCHORS["home"]
	var base := Vector3(h.x, gy(h.x, h.y), h.y)
	# horseshoe of great mossy boulders opening towards the path (south-east)
	_big_rock(base + Vector3(-7.5, 0.5, -5.0), Vector3(3.5, 3.2, 3.0), 51)
	_big_rock(base + Vector3(-3.0, 0.8, -8.5), Vector3(4.2, 3.8, 3.2), 52)
	_big_rock(base + Vector3(2.5, 0.4, -8.0), Vector3(3.2, 3.0, 2.8), 53)
	_big_rock(base + Vector3(-9.0, 0.3, 0.5), Vector3(2.6, 2.4, 2.8), 54)
	_big_rock(base + Vector3(6.0, 0.2, -4.5), Vector3(2.2, 2.0, 2.4), 55)
	# overhanging slab
	kit.xform = Transform3D(Basis.from_euler(Vector3(0.12, 0.3, 0.05)), base + Vector3(-3.5, 4.4, -5.5))
	kit.blob(Vector3.ZERO, Vector3(5.0, 0.9, 3.4), Color(0.5, 0.49, 0.48), 3, 8, 0.12)
	kit.blob(Vector3(0, 0.6, 0), Vector3(4.2, 0.4, 2.8), Color(0.38, 0.54, 0.25), 2, 8, 0.1)
	collider(kit.xform, Vector3(0, 0.2, 0), Vector3(8.0, 1.2, 5.0))
	# moss bed
	var bed: Vector2 = Layout.ANCHORS["home_bed"]
	var by := gy(bed.x, bed.y)
	kit.xform = Transform3D(Basis(Vector3.UP, 0.3), Vector3(bed.x, by, bed.y))
	kit.blob(Vector3(0, 0.2, 0), Vector3(1.6, 0.45, 2.3), Color(0.36, 0.52, 0.24), 3, 8, 0.08, true)
	kit.blob(Vector3(0, 0.62, -1.4), Vector3(0.8, 0.3, 0.5), Color(0.9, 0.86, 0.75), 2, 6)
	kit.box(Vector3(0, 0.6, 0.5), Vector3(2.4, 0.12, 2.0), Color(0.75, 0.25, 0.22))
	kit.box(Vector3(0, 0.62, 0.0), Vector3(2.42, 0.13, 0.25), Color(0.95, 0.9, 0.8))
	kit.box(Vector3(0, 0.62, 1.0), Vector3(2.42, 0.13, 0.25), Color(0.95, 0.9, 0.8))
	# chest
	kit.xform = Transform3D(Basis(Vector3.UP, 0.6), Vector3(bed.x + 3.0, by, bed.y - 1.0))
	kit.box(Vector3(0, 0.4, 0), Vector3(1.3, 0.8, 0.8), WOOD)
	kit.box(Vector3(0, 0.85, 0), Vector3(1.35, 0.15, 0.85), DARK_WOOD)
	kit.box(Vector3(0, 0.6, 0.42), Vector3(0.2, 0.25, 0.05), Color(0.85, 0.7, 0.3))
	# cauldron over a fire
	var c: Vector2 = Layout.ANCHORS["cauldron"]
	var cy := gy(c.x, c.y)
	kit.xform = Transform3D(Basis.IDENTITY, Vector3(c.x, cy, c.y))
	for i in range(7):
		var a := TAU * i / 7.0
		kit.blob(Vector3(sin(a) * 1.0, 0.15, cos(a) * 1.0), Vector3(0.3, 0.22, 0.3), STONE, 2, 5)
	kit.cylinder(Vector3(0, 0.45, 0), 0.7, 0.85, 0.5, 8, Color(0.16, 0.16, 0.18))
	kit.cylinder(Vector3(0, 0.95, 0), 0.85, 0.7, 0.4, 8, Color(0.18, 0.18, 0.2))
	kit.cylinder(Vector3(0, 1.3, 0), 0.62, 0.62, 0.02, 8, Color(0.45, 0.3, 0.5))
	for a2 in [0.0, 2.1, 4.2]:
		kit.box_rot(Vector3(sin(a2) * 0.55, 0.3, cos(a2) * 0.55), Vector3(0.1, 0.8, 0.1), Vector3(0.3 * cos(a2), 0, -0.3 * sin(a2)), Color(0.15, 0.15, 0.15))
	glow.xform = kit.xform
	glow.box(Vector3(0, 0.12, 0), Vector3(0.7, 0.2, 0.7), Color(1.0, 0.55, 0.2))
	fire_points.append(Vector3(c.x, cy + 0.4, c.y))
	smoke(Vector3(c.x, cy + 1.5, c.y))
	cyl_collider(Vector3(c.x, cy, c.y), 1.0, 1.4, true)
	# lantern on a pole and a sign
	_troll_lantern(base.x + 4.5, base.z + 3.5)
	var sxf := place(base.x + 7.0, base.z + 6.0, base.x + 14.0, base.z + 12.0)
	kit.xform = sxf
	kit.box(Vector3(0, 0.7, 0), Vector3(0.15, 1.4, 0.15), DARK_WOOD)
	kit.box(Vector3(0, 1.3, 0.05), Vector3(1.4, 0.6, 0.1), WOOD)
	# mushrooms
	for m in [Vector2(-4.5, -2.5), Vector2(-4.0, -3.2), Vector2(3.5, 1.5)]:
		_mushroom(base.x + m.x, base.z + m.y, 0.5)
	clear_zone(h.x, h.y, 11)


func _mushroom(x: float, z: float, s: float) -> void:
	var y := gy(x, z)
	kit.xform = Transform3D(Basis.IDENTITY.scaled(Vector3(s, s, s)), Vector3(x, y, z))
	kit.cylinder(Vector3(0, 0, 0), 0.18, 0.14, 0.6, 6, Color(0.95, 0.92, 0.85))
	kit.blob(Vector3(0, 0.62, 0), Vector3(0.5, 0.3, 0.5), Color(0.85, 0.15, 0.12), 3, 7, 0.0)
	for i in range(4):
		var a := TAU * i / 4.0 + 0.4
		kit.box(Vector3(sin(a) * 0.3, 0.8, cos(a) * 0.3), Vector3(0.1, 0.06, 0.1), Color(1, 1, 1))


func _troll_lantern(x: float, z: float) -> void:
	var y := gy(x, z)
	kit.xform = Transform3D(Basis.IDENTITY, Vector3(x, y, z))
	kit.box(Vector3(0, 1.2, 0), Vector3(0.18, 2.4, 0.18), DARK_WOOD)
	kit.box(Vector3(0.4, 2.35, 0), Vector3(0.9, 0.12, 0.12), DARK_WOOD)
	kit.box(Vector3(0.75, 2.05, 0), Vector3(0.05, 0.4, 0.05), Color(0.2, 0.2, 0.2))
	glow.xform = kit.xform
	glow.box(Vector3(0.75, 1.72, 0), Vector3(0.34, 0.42, 0.34), Color(1.0, 0.8, 0.45))
	lamp_points.append(Vector3(x + 0.75, y + 1.7, z))
	cyl_collider(Vector3(x, y, z), 0.25, 2.4, true)


func _build_granny_hut() -> void:
	var g: Vector2 = Layout.ANCHORS["granny_hut"]
	var yard: Vector2 = Layout.ANCHORS["granny_yard"]
	var xf := place(g.x, g.y - 2.0, yard.x, yard.y + 2.0)
	kit.xform = xf
	kit.cylinder(Vector3(0, -0.4, 0), 3.4, 3.2, 2.9, 9, Color(0.55, 0.45, 0.35), null, false)
	for i in range(9):
		var a := TAU * (i + 0.5) / 9.0
		kit.blob(Vector3(sin(a) * 3.3, 0.1, cos(a) * 3.3), Vector3(0.6, 0.5, 0.5), STONE, 2, 5, 0.2)
	kit.cone(Vector3(0, 2.3, 0), 4.2, 2.6, 9, TURF)
	kit.blob(Vector3(0, 4.7, 0), Vector3(0.4, 0.3, 0.4), Color(0.9, 0.8, 0.3), 2, 5)
	# round door + windows
	kit.xform = xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 1.05, 3.25))
	kit.cylinder(Vector3(0, -0.05, 0), 0.8, 0.8, 0.12, 10, Color(0.3, 0.45, 0.3))
	kit.xform = xf
	kit.box(Vector3(0.45, 1.0, 3.42), Vector3(0.12, 0.12, 0.08), Color(0.9, 0.75, 0.3))
	window(xf, Vector3(2.2, 1.4, 2.5), Vector3(0.7, 0, 0.7).normalized())
	window(xf, Vector3(-2.2, 1.4, 2.5), Vector3(-0.7, 0, 0.7).normalized())
	kit.xform = xf
	kit.box(Vector3(1.2, 3.5, -1.0), Vector3(0.6, 1.8, 0.6), STONE)
	smoke(xf * Vector3(1.2, 4.6, -1.0))
	cyl_collider(xf.origin + Vector3(0, -0.5, 0), 3.6, 4.0)
	# laundry line with knitted socks
	var lxf := xf * Transform3D(Basis.IDENTITY, Vector3(-5.0, 0, 2.0))
	kit.xform = lxf
	kit.box(Vector3(0, 0.9, -2.0), Vector3(0.12, 1.8, 0.12), DARK_WOOD)
	kit.box(Vector3(0, 0.9, 2.0), Vector3(0.12, 1.8, 0.12), DARK_WOOD)
	kit.box(Vector3(0, 1.75, 0), Vector3(0.03, 0.03, 4.0), Color(0.85, 0.8, 0.7))
	var sock_cols := [Color(0.8, 0.25, 0.25), Color(0.3, 0.45, 0.75), Color(0.95, 0.85, 0.4), Color(0.4, 0.65, 0.35)]
	for i in range(4):
		kit.box(Vector3(0, 1.45, -1.3 + i * 0.85), Vector3(0.08, 0.55, 0.22), sock_cols[i])
		kit.box(Vector3(0, 1.2, -1.2 + i * 0.85), Vector3(0.08, 0.18, 0.3), sock_cols[i])
	# rocking chair
	var rxf := xf * Transform3D(Basis(Vector3.UP, 0.5), Vector3(3.0, 0, 4.3))
	kit.xform = rxf
	kit.box(Vector3(0, 0.55, 0), Vector3(0.9, 0.1, 0.8), WOOD)
	kit.box(Vector3(0, 1.0, -0.38), Vector3(0.9, 0.9, 0.08), WOOD)
	kit.box(Vector3(-0.42, 0.25, 0), Vector3(0.06, 0.5, 0.06), DARK_WOOD)
	kit.box(Vector3(0.42, 0.25, 0), Vector3(0.06, 0.5, 0.06), DARK_WOOD)
	kit.box(Vector3(-0.42, 0.05, 0), Vector3(0.06, 0.06, 1.1), DARK_WOOD)
	kit.box(Vector3(0.42, 0.05, 0), Vector3(0.06, 0.06, 1.1), DARK_WOOD)
	clear_zone(g.x, g.y, 7)


func _build_stein_circle() -> void:
	var s: Vector2 = Layout.ANCHORS["stein_rocks"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 61
	for i in range(9):
		var a := TAU * i / 9.0
		var p := Vector2(s.x + sin(a) * 7.0, s.y + cos(a) * 7.0)
		if absf(wrapf(a - PI * 0.5, -PI, PI)) < 0.55:
			continue # leave an opening towards the path
		var y := gy(p.x, p.y)
		var hgt := rng.randf_range(1.8, 3.0)
		kit.xform = Transform3D(Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, rng.randf_range(-0.08, 0.08)), Vector3(p.x, y, p.y))
		kit.box(Vector3(0, hgt * 0.5 - 0.2, 0), Vector3(1.0, hgt, 0.7), Color(0.55, 0.54, 0.53))
		kit.box(Vector3(0, hgt - 0.15, 0), Vector3(1.05, 0.2, 0.75), Color(0.42, 0.55, 0.3))
		cyl_collider(Vector3(p.x, y, p.y), 0.6, hgt, true)
	# cairns
	for c: Vector2 in [Vector2(-3.0, 2.0), Vector2(2.5, -2.5), Vector2(3.0, 3.0)]:
		var p2 := s + c
		var y2 := gy(p2.x, p2.y)
		kit.xform = Transform3D(Basis.IDENTITY, Vector3(p2.x, y2, p2.y))
		var yy := 0.0
		for k in range(5):
			var r := 0.6 - k * 0.1
			kit.blob(Vector3(0, yy + r * 0.4, 0), Vector3(r, r * 0.45, r * 0.9), Color(0.6, 0.58, 0.56).darkened(0.05 * (k % 2)), 2, 6, 0.1)
			yy += r * 0.75
		cyl_collider(Vector3(p2.x, y2, p2.y), 0.5, 2.0, true)
	# Stein's stone seat
	_big_rock(Vector3(s.x - 1.0, gy(s.x - 1.0, s.y - 3.5) + 0.2, s.y - 3.5), Vector3(1.8, 1.1, 1.4), 62, true)
	clear_zone(s.x, s.y, 8)


func _build_lyng_garden() -> void:
	var l: Vector2 = Layout.ANCHORS["lyng_garden"]
	# hollow stump house
	var hp := l + Vector2(3.5, -3.5)
	var xf := place(hp.x, hp.y, l.x - 3.0, l.y + 4.0)
	kit.xform = xf
	kit.cylinder(Vector3(0, -0.5, 0), 2.8, 2.3, 3.8, 9, Color(0.45, 0.32, 0.22), Color(0.6, 0.48, 0.32))
	for i in range(5):
		var a := TAU * i / 5.0 + 0.3
		kit.box_rot(Vector3(sin(a) * 2.6, 0.2, cos(a) * 2.6), Vector3(0.7, 0.6, 1.8), Vector3(0, a, 0.3), Color(0.42, 0.3, 0.2))
	kit.blob(Vector3(0, 3.4, 0), Vector3(2.6, 0.7, 2.6), Color(0.38, 0.55, 0.26), 2, 8, 0.1)
	kit.box(Vector3(0, 1.0, 2.45), Vector3(0.9, 1.7, 0.2), Color(0.55, 0.3, 0.45))
	window(xf, Vector3(1.4, 2.2, 1.9), Vector3(0.6, 0, 0.8).normalized())
	cyl_collider(xf.origin + Vector3(0, -0.5, 0), 2.8, 4.0)
	# garden beds
	var flower_cols := [Color(0.95, 0.4, 0.5), Color(0.98, 0.85, 0.3), Color(0.7, 0.45, 0.85), Color(0.95, 0.95, 0.9), Color(0.95, 0.55, 0.25)]
	for b in range(3):
		var bp := l + Vector2(-3.5 + b * 3.0, 2.0)
		var y := gy(bp.x, bp.y)
		kit.xform = Transform3D(Basis.IDENTITY, Vector3(bp.x, y, bp.y))
		kit.box(Vector3(0, 0.15, 0), Vector3(2.2, 0.35, 1.4), Color(0.4, 0.28, 0.18))
		for k in range(6):
			kit.blob(Vector3(-0.8 + (k % 3) * 0.8, 0.45, -0.35 + (k / 3) * 0.7), Vector3(0.22, 0.2, 0.22), flower_cols[(b * 2 + k) % flower_cols.size()], 2, 5)
	for m in [Vector2(-5, -1), Vector2(-5.5, 0), Vector2(5, 3), Vector2(4.2, 3.5), Vector2(-1, 5)]:
		_mushroom(l.x + m.x, l.y + m.y, 0.7)
	# twig fence arc
	var pts := []
	for i in range(9):
		var a := PI * 1.05 * i / 8.0
		pts.append(l + Vector2(cos(a), -sin(a)) * 7.5)
	_fence(pts, Color(0.5, 0.4, 0.3))
	clear_zone(l.x, l.y, 8)


func _build_troll_ring() -> void:
	var r: Vector2 = Layout.ANCHORS["ring"]
	var y := gy(r.x, r.y)
	kit.xform = Transform3D(Basis.IDENTITY, Vector3(r.x, y, r.y))
	for i in range(10):
		var a := TAU * i / 10.0
		kit.blob(Vector3(sin(a) * 1.4, 0.12, cos(a) * 1.4), Vector3(0.35, 0.25, 0.35), STONE, 2, 5, 0.15)
	for i in range(5):
		var a2 := TAU * i / 5.0
		kit.box_rot(Vector3(sin(a2) * 0.5, 0.35, cos(a2) * 0.5), Vector3(0.18, 0.18, 1.3), Vector3(0.5, a2, 0), DARK_WOOD)
	glow.xform = kit.xform
	glow.box(Vector3(0, 0.2, 0), Vector3(0.6, 0.15, 0.6), Color(1.0, 0.5, 0.2))
	fire_points.append(Vector3(r.x, y + 0.4, r.y))
	# log benches
	for a3 in [0.6, 2.2, 3.8, 5.3]:
		var p := r + Vector2(sin(a3), cos(a3)) * 4.2
		var by := gy(p.x, p.y)
		kit.xform = Transform3D(Basis(Vector3.UP, a3 + PI * 0.5) * Basis(Vector3.FORWARD, PI * 0.5), Vector3(p.x, by + 0.35, p.y))
		kit.cylinder(Vector3(0, -1.2, 0), 0.35, 0.35, 2.4, 6, Color(0.45, 0.33, 0.22), Color(0.72, 0.6, 0.42))
	cyl_collider(Vector3(r.x, y, r.y), 1.4, 0.6, true)
	clear_zone(r.x, r.y, 6)


func _build_bonfire() -> void:
	var b: Vector2 = Layout.ANCHORS["bonfire"]
	var y := gy(b.x, b.y)
	kit.xform = Transform3D(Basis.IDENTITY, Vector3(b.x, y, b.y))
	for i in range(8):
		var a := TAU * i / 8.0
		kit.box_rot(Vector3(sin(a) * 0.6, 0.9, cos(a) * 0.6), Vector3(0.22, 2.2, 0.22), Vector3(0.35 * cos(a), 0, -0.35 * sin(a)), Color(0.45, 0.35, 0.25))
	for i in range(8):
		var a4 := TAU * (i + 0.5) / 8.0
		kit.blob(Vector3(sin(a4) * 1.5, 0.12, cos(a4) * 1.5), Vector3(0.35, 0.25, 0.35), STONE, 2, 5, 0.15)
	cyl_collider(Vector3(b.x, y, b.y), 1.3, 2.0, true)
	clear_zone(b.x, b.y, 6)


func _build_city_gate() -> void:
	var g: Vector2 = Layout.ANCHORS["city_gate"]
	var xf := place(g.x, g.y, g.x - 10.0, g.y)
	kit.xform = xf
	kit.box(Vector3(-2.5, 0.6, 0), Vector3(0.2, 1.2, 0.2), Color(0.9, 0.9, 0.9))
	kit.box(Vector3(2.5, 0.6, 0), Vector3(0.2, 1.2, 0.2), Color(0.9, 0.9, 0.9))
	for i in range(5):
		kit.box(Vector3(-2.0 + i * 1.0, 0.95, 0), Vector3(1.0, 0.22, 0.1), Color(0.85, 0.15, 0.15) if i % 2 == 0 else Color(0.95, 0.95, 0.95))
	kit.box(Vector3(3.6, 1.0, 0), Vector3(0.14, 2.0, 0.14), DARK_WOOD)
	kit.box(Vector3(3.6, 1.8, 0.1), Vector3(1.4, 0.45, 0.08), Color(0.2, 0.4, 0.7))
	kit.box(Vector3(3.6, 1.8, 0.15), Vector3(1.1, 0.12, 0.05), Color(0.95, 0.95, 0.95))


func _commit() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "BuildingsMesh"
	mi.mesh = kit.commit()
	mi.material_override = Mats.world(0.12)
	add_child(mi)
	window_material = Mats.glow(Color(1.0, 0.82, 0.48), 0.0).duplicate()
	window_material.set_shader_parameter("albedo", GLASS)
	var gm := MeshInstance3D.new()
	gm.name = "Windows"
	gm.mesh = glass.commit()
	gm.material_override = window_material
	add_child(gm)
	lamp_material = Mats.glow(Color(1.0, 0.8, 0.45), 0.4).duplicate()
	var lm := MeshInstance3D.new()
	lm.name = "Lamps"
	lm.mesh = glow.commit()
	lm.material_override = lamp_material
	lm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(lm)
	# chimney smoke (one shared material so the day/night cycle can tint it)
	var smoke_mat := StandardMaterial3D.new()
	smoke_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smoke_mat.albedo_color = Color(0.85, 0.85, 0.85)
	for p in smoke_points:
		var sm := make_smoke(p, smoke_mat)
		add_child(sm)
		smoke_nodes.append(sm)
	# little flames for the fires
	for f in fire_points:
		add_child(make_fire(f))


static func make_fire(p: Vector3) -> CPUParticles3D:
	var f := CPUParticles3D.new()
	f.position = p - Vector3(0, 0.15, 0)
	f.amount = 14
	f.lifetime = 0.7
	f.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	f.emission_sphere_radius = 0.25
	f.direction = Vector3.UP
	f.spread = 12.0
	f.initial_velocity_min = 0.8
	f.initial_velocity_max = 1.6
	f.gravity = Vector3(0, 0.5, 0)
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.85, 0.35))
	grad.set_color(1, Color(0.95, 0.3, 0.1))
	f.color_ramp = grad
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1.0))
	curve.add_point(Vector2(1, 0.1))
	f.scale_amount_curve = curve
	var m := BoxMesh.new()
	m.size = Vector3(0.18, 0.18, 0.18)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	m.material = mat
	f.mesh = m
	return f


static func make_smoke(p: Vector3, mat: Material = null) -> CPUParticles3D:
	var s := CPUParticles3D.new()
	s.position = p
	s.amount = 10
	s.lifetime = 4.0
	s.direction = Vector3(0.2, 1, 0)
	s.spread = 10.0
	s.initial_velocity_min = 0.5
	s.initial_velocity_max = 0.9
	s.gravity = Vector3(0.12, 0.05, 0)
	s.scale_amount_min = 0.5
	s.scale_amount_max = 1.0
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.4))
	curve.add_point(Vector2(0.5, 1.0))
	curve.add_point(Vector2(1, 0.0))
	s.scale_amount_curve = curve
	var m := BoxMesh.new()
	m.size = Vector3(0.5, 0.5, 0.5)
	m.material = mat if mat != null else Mats.unshaded(Color(0.85, 0.85, 0.85))
	s.mesh = m
	return s
