class_name Litter
extends Interactable
## Rubbish around the village. Tidying it up makes the villagers happier.

const KINDS := ["paper", "bottle", "crate", "branch", "bin", "can"]
static var _cache := {}

var litter_id := ""
var kind := "paper"
var owner_id := ""


func setup(lid: String, k: String, owner: String) -> void:
	litter_id = lid
	kind = k
	owner_id = owner
	prompt = "Tidy up"
	radius = 1.1
	focus_height = 0.8
	var mi := MeshInstance3D.new()
	mi.mesh = _mesh(k)
	mi.material_override = Mats.world(0.0, 0.0)
	add_child(mi)
	rotation.y = randf() * TAU


static func _mesh(k: String) -> ArrayMesh:
	if _cache.has(k):
		return _cache[k]
	var m := MeshKit.new(3000 + k.length())
	match k:
		"paper":
			m.box_rot(Vector3(0, 0.03, 0), Vector3(0.4, 0.03, 0.3), Vector3(0, 0.3, 0.05), Color(0.95, 0.94, 0.88))
			m.box_rot(Vector3(0.35, 0.03, 0.2), Vector3(0.3, 0.03, 0.25), Vector3(0, -0.5, 0.1), Color(0.9, 0.88, 0.8))
			m.blob(Vector3(-0.3, 0.1, 0.2), Vector3(0.12, 0.1, 0.12), Color(0.95, 0.94, 0.9), 2, 5, 0.3)
		"bottle":
			m.xform = Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3(0, 0.09, 0))
			m.cylinder(Vector3(0, -0.2, 0), 0.08, 0.08, 0.3, 6, Color(0.3, 0.6, 0.35))
			m.cylinder(Vector3(0, 0.1, 0), 0.08, 0.03, 0.15, 6, Color(0.3, 0.6, 0.35))
			m.xform = Transform3D.IDENTITY
			m.box(Vector3(0.3, 0.03, 0.2), Vector3(0.25, 0.03, 0.2), Color(0.95, 0.94, 0.88))
		"crate":
			m.box_rot(Vector3(0, 0.2, 0), Vector3(0.6, 0.4, 0.5), Vector3(0, 0, 0.4), Color(0.6, 0.45, 0.28))
			m.box_rot(Vector3(0.5, 0.05, 0.1), Vector3(0.5, 0.06, 0.12), Vector3(0, 0.7, 0), Color(0.55, 0.4, 0.25))
			m.box_rot(Vector3(-0.3, 0.05, 0.4), Vector3(0.4, 0.06, 0.12), Vector3(0, -0.4, 0), Color(0.55, 0.4, 0.25))
		"branch":
			m.xform = Transform3D(Basis(Vector3.FORWARD, PI * 0.5) * Basis(Vector3.RIGHT, 0.2), Vector3(0, 0.1, 0))
			m.cylinder(Vector3(0, -0.8, 0), 0.08, 0.05, 1.6, 5, Color(0.42, 0.3, 0.2))
			m.xform = Transform3D.IDENTITY
			m.blob(Vector3(0.6, 0.2, 0.1), Vector3(0.35, 0.25, 0.35), Color(0.3, 0.5, 0.25), 2, 5, 0.2)
			m.blob(Vector3(-0.2, 0.15, -0.2), Vector3(0.25, 0.2, 0.25), Color(0.85, 0.65, 0.25), 2, 5, 0.2)
		"bin":
			m.xform = Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3(0, 0.3, 0))
			m.cylinder(Vector3(0, -0.4, 0), 0.3, 0.33, 0.8, 8, Color(0.35, 0.45, 0.4))
			m.xform = Transform3D.IDENTITY
			m.box(Vector3(0.7, 0.03, 0.1), Vector3(0.35, 0.03, 0.3), Color(0.95, 0.94, 0.88))
			m.blob(Vector3(0.6, 0.06, -0.3), Vector3(0.12, 0.06, 0.1), Color(0.8, 0.6, 0.3), 2, 5)
			m.box(Vector3(0.9, 0.05, 0.4), Vector3(0.12, 0.08, 0.2), Color(0.75, 0.2, 0.2))
		"can":
			m.xform = Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3(0, 0.07, 0))
			m.cylinder(Vector3(0, -0.1, 0), 0.07, 0.07, 0.2, 6, Color(0.75, 0.2, 0.2))
			m.xform = Transform3D.IDENTITY
			m.box_rot(Vector3(0.25, 0.03, -0.1), Vector3(0.3, 0.03, 0.22), Vector3(0, 0.8, 0), Color(0.95, 0.94, 0.88))
	var mesh := m.commit()
	_cache[k] = mesh
	return mesh


func interact(player: Node) -> void:
	Game.cleaned[litter_id] = true
	Game.inc("litter")
	Game.inc("litter_today")
	if owner_id != "":
		Game.add_trust(owner_id, 1.2, false)
	Game.add_village_trust(0.35)
	Sound.sfx("clean", randf_range(0.9, 1.1))
	(player as Player).play_mode("lift", 0.4)
	world.spawn_puff(global_position + Vector3(0, 0.3, 0), Color(0.95, 0.95, 0.9))
	world.on_litter_cleaned(self)
	queue_free()
