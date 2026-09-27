class_name ForageSpot
extends Interactable
## A bush, mushroom, flower or treasure that can be gathered once per day
## (or every few days).

const KINDS := {
	"bush_blue": {"item": "blueberry", "min": 1, "max": 2, "regrow": 1, "verb": "Pick blueberries"},
	"bush_lingon": {"item": "lingonberry", "min": 1, "max": 2, "regrow": 1, "verb": "Pick lingonberries"},
	"bush_cloud": {"item": "cloudberry", "min": 1, "max": 1, "regrow": 1, "verb": "Pick a cloudberry"},
	"mushroom": {"item": "chanterelle", "min": 1, "max": 2, "regrow": 2, "verb": "Pick chanterelles"},
	"flower": {"item": "wildflower", "min": 1, "max": 2, "regrow": 1, "verb": "Pick wildflowers"},
	"heather": {"item": "heather", "min": 1, "max": 2, "regrow": 1, "verb": "Pick heather"},
	"moss": {"item": "moss", "min": 1, "max": 2, "regrow": 1, "verb": "Gather moss"},
	"pinecone": {"item": "pinecone", "min": 1, "max": 1, "regrow": 1, "verb": "Pick up pinecone"},
	"stone": {"item": "pretty_stone", "min": 1, "max": 1, "regrow": 2, "verb": "Pick up pretty stone"},
	"crystal": {"item": "crystal", "min": 1, "max": 1, "regrow": 3, "verb": "Pry loose crystal"},
	"feather": {"item": "feather", "min": 1, "max": 1, "regrow": 1, "verb": "Pick up feather", "chance": 0.45},
	"driftwood": {"item": "driftwood", "min": 1, "max": 1, "regrow": 2, "verb": "Pick up driftwood"},
}

static var _mesh_cache := {}

var spot_id := ""
var kind := ""
var info := {}
var available := true
var _full: MeshInstance3D
var _base: MeshInstance3D


func setup(sid: String, k: String) -> void:
	spot_id = sid
	kind = k
	info = KINDS[k]
	prompt = info["verb"]
	radius = 1.1
	focus_height = 0.9
	var meshes := _meshes_for(k)
	if meshes[0] != null:
		_base = MeshInstance3D.new()
		_base.mesh = meshes[0]
		_base.material_override = Mats.world(0.0, 0.3)
		add_child(_base)
	_full = MeshInstance3D.new()
	_full.mesh = meshes[1]
	_full.material_override = Mats.world(0.0, 0.0) if k != "crystal" else Mats.glow(Color(0.6, 0.9, 1.0), 0.35)
	if k == "crystal":
		_full.material_override = _crystal_mat()
	add_child(_full)
	rotation.y = randf() * TAU


static func _crystal_mat() -> ShaderMaterial:
	var m := Mats.world(0.0, 0.0).duplicate() as ShaderMaterial
	m.set_shader_parameter("emission_color", Color(0.4, 0.8, 1.0))
	m.set_shader_parameter("emission_energy", 0.35)
	return m


static func _meshes_for(k: String) -> Array:
	if _mesh_cache.has(k):
		return _mesh_cache[k]
	var base := MeshKit.new(1000 + k.length())
	var full := MeshKit.new(2000 + k.length())
	base.jitter = 0.03
	full.jitter = 0.03
	match k:
		"bush_blue":
			base.blob(Vector3(0, 0.45, 0), Vector3(0.75, 0.55, 0.75), Color(0.24, 0.42, 0.22), 3, 7, 0.15, true)
			for i in range(9):
				var a := TAU * i / 9.0
				var r := 0.55 + 0.15 * (i % 2)
				full.box(Vector3(sin(a) * r, 0.45 + 0.2 * ((i * 7) % 3 - 1), cos(a) * r), Vector3(0.14, 0.14, 0.14), Color(0.3, 0.38, 0.8))
			full.box(Vector3(0, 0.95, 0), Vector3(0.14, 0.14, 0.14), Color(0.35, 0.42, 0.85))
		"bush_lingon":
			base.blob(Vector3(0, 0.22, 0), Vector3(0.6, 0.3, 0.6), Color(0.2, 0.4, 0.22), 3, 7, 0.15, true)
			for i in range(8):
				var a := TAU * i / 8.0 + 0.3
				var r := 0.3 + 0.2 * (i % 2)
				full.box(Vector3(sin(a) * r, 0.42, cos(a) * r), Vector3(0.11, 0.11, 0.11), Color(0.88, 0.18, 0.18))
		"bush_cloud":
			for i in range(4):
				var a := TAU * i / 4.0
				base.box_rot(Vector3(sin(a) * 0.18, 0.12, cos(a) * 0.18), Vector3(0.3, 0.04, 0.22), Vector3(0, a, 0.2), Color(0.35, 0.55, 0.28))
			base.cylinder(Vector3(0, 0, 0), 0.02, 0.02, 0.35, 4, Color(0.4, 0.5, 0.3))
			full.blob(Vector3(0, 0.42, 0), Vector3(0.12, 0.12, 0.12), Color(0.98, 0.65, 0.2), 2, 6)
			full.blob(Vector3(0.3, 0.3, 0.15), Vector3(0.09, 0.09, 0.09), Color(0.98, 0.7, 0.25), 2, 5)
		"mushroom":
			for p in [Vector3(0, 0, 0), Vector3(0.25, 0, 0.15), Vector3(-0.2, 0, 0.2)]:
				var s := 1.0 if p == Vector3.ZERO else 0.7
				full.cylinder(p, 0.05 * s, 0.07 * s, 0.22 * s, 5, Color(0.95, 0.72, 0.3))
				full.cylinder(p + Vector3(0, 0.2 * s, 0), 0.07 * s, 0.2 * s, 0.1 * s, 7, Color(0.98, 0.78, 0.3), Color(0.9, 0.65, 0.25))
		"flower":
			var cols := [Color(0.95, 0.5, 0.62), Color(1.0, 0.95, 0.9), Color(0.95, 0.8, 0.3)]
			for i in range(6):
				var a := TAU * i / 6.0
				var p2 := Vector3(sin(a) * 0.3, 0, cos(a) * 0.3)
				base.box(p2 + Vector3(0, 0.22, 0), Vector3(0.03, 0.44, 0.03), Color(0.3, 0.55, 0.22))
				full.box(p2 + Vector3(0, 0.46, 0), Vector3(0.16, 0.08, 0.16), cols[i % 3])
				full.box(p2 + Vector3(0, 0.5, 0), Vector3(0.06, 0.04, 0.06), Color(0.98, 0.85, 0.3))
		"heather":
			base.blob(Vector3(0, 0.2, 0), Vector3(0.55, 0.28, 0.55), Color(0.3, 0.42, 0.25), 3, 6, 0.2, true)
			for i in range(10):
				var a := TAU * i / 10.0
				var r := 0.2 + 0.25 * (i % 3) / 2.0
				full.box(Vector3(sin(a) * r, 0.42 + 0.05 * (i % 2), cos(a) * r), Vector3(0.08, 0.16, 0.08), Color(0.72, 0.42, 0.72))
		"moss":
			base.blob(Vector3(0, 0.15, 0), Vector3(0.55, 0.35, 0.5), Color(0.5, 0.5, 0.5), 3, 6, 0.2, true)
			full.blob(Vector3(0, 0.38, 0), Vector3(0.5, 0.2, 0.45), Color(0.45, 0.68, 0.28), 2, 7, 0.15)
			full.blob(Vector3(0.2, 0.46, 0.1), Vector3(0.2, 0.12, 0.2), Color(0.55, 0.75, 0.32), 2, 5)
		"pinecone":
			full.blob(Vector3(0, 0.12, 0), Vector3(0.12, 0.18, 0.12), Color(0.5, 0.33, 0.2), 3, 6, 0.1)
			full.blob(Vector3(0.25, 0.1, 0.1), Vector3(0.1, 0.14, 0.1), Color(0.45, 0.3, 0.18), 3, 6, 0.1)
		"stone":
			full.blob(Vector3(0, 0.1, 0), Vector3(0.22, 0.14, 0.18), Color(0.72, 0.72, 0.76), 3, 6, 0.1, true)
			full.box(Vector3(0.05, 0.2, 0), Vector3(0.18, 0.03, 0.05), Color(0.92, 0.88, 0.75))
		"crystal":
			base.blob(Vector3(0, 0.1, 0), Vector3(0.5, 0.3, 0.45), Color(0.45, 0.44, 0.44), 3, 6, 0.2, true)
			for p3 in [[Vector3(0, 0.2, 0), 0.0, 0.7], [Vector3(0.15, 0.2, 0.1), 0.4, 0.45], [Vector3(-0.15, 0.2, 0.05), -0.45, 0.5]]:
				var kxf := Transform3D(Basis(Vector3.FORWARD, p3[1]), p3[0])
				full.xform = kxf
				full.cylinder(Vector3.ZERO, 0.09, 0.0, p3[2], 5, Color(0.6, 0.88, 1.0))
			full.xform = Transform3D.IDENTITY
		"feather":
			full.tri(Vector3(-0.05, 0.03, -0.25), Vector3(0.05, 0.03, 0.25), Vector3(0.1, 0.03, -0.1), Color(0.97, 0.96, 0.92))
			full.tri(Vector3(-0.05, 0.03, -0.25), Vector3(-0.08, 0.03, 0.1), Vector3(0.05, 0.03, 0.25), Color(0.9, 0.9, 0.86))
			full.tri(Vector3(0.1, 0.031, -0.1), Vector3(0.05, 0.031, 0.25), Vector3(-0.05, 0.031, -0.25), Color(0.97, 0.96, 0.92))
			full.tri(Vector3(0.05, 0.031, 0.25), Vector3(-0.08, 0.031, 0.1), Vector3(-0.05, 0.031, -0.25), Color(0.9, 0.9, 0.86))
		"driftwood":
			full.xform = Transform3D(Basis(Vector3.FORWARD, PI * 0.5) * Basis(Vector3.RIGHT, 0.1), Vector3(0, 0.15, 0))
			full.cylinder(Vector3(0, -0.8, 0), 0.14, 0.11, 1.6, 6, Color(0.72, 0.68, 0.6), Color(0.82, 0.78, 0.68))
			full.xform = Transform3D.IDENTITY
			full.box_rot(Vector3(0.3, 0.15, 0.2), Vector3(0.06, 0.06, 0.5), Vector3(0, 0.7, 0), Color(0.68, 0.64, 0.56))
	var res := [base.commit() if not base.is_empty() else null, full.commit()]
	_mesh_cache[k] = res
	return res


func refresh() -> void:
	available = true
	if Game.picked.has(spot_id) and Game.day - int(Game.picked[spot_id]) < int(info["regrow"]):
		available = false
	if info.has("chance"):
		var h := hash(spot_id + str(Game.day)) % 1000
		if float(h) / 1000.0 > float(info["chance"]):
			available = false
	_full.visible = available
	if _base == null:
		visible = available


func can_interact(_p: Node) -> bool:
	return available and is_visible_in_tree()


func interact(player: Node) -> void:
	if not available:
		return
	var n := randi_range(int(info["min"]), int(info["max"]))
	Game.picked[spot_id] = Game.day
	Game.add_item(info["item"], n)
	Sound.sfx("pickup", randf_range(0.95, 1.1))
	(player as Player).play_mode("lift", 0.35)
	refresh()
