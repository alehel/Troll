class_name GiftSpot
extends Interactable
## A little wicker basket by a villager's door. Gifts left here are found
## the next morning.

var npc_id := ""
var _item_mi: MeshInstance3D
static var _basket: ArrayMesh


func setup(id: String) -> void:
	npc_id = id
	radius = 1.0
	focus_height = 0.8
	if _basket == null:
		var k := MeshKit.new(4001)
		var wicker := Color(0.72, 0.55, 0.32)
		k.cylinder(Vector3(0, 0, 0), 0.26, 0.32, 0.26, 8, wicker, Color(0.5, 0.36, 0.2))
		k.box(Vector3(0, 0.27, 0), Vector3(0.6, 0.04, 0.06), wicker.darkened(0.2))
		k.box(Vector3(-0.3, 0.42, 0), Vector3(0.05, 0.32, 0.05), wicker.darkened(0.1))
		k.box(Vector3(0.3, 0.42, 0), Vector3(0.05, 0.32, 0.05), wicker.darkened(0.1))
		k.box(Vector3(0, 0.58, 0), Vector3(0.65, 0.05, 0.05), wicker.darkened(0.1))
		k.box(Vector3(0, 0.2, 0.2), Vector3(0.35, 0.02, 0.2), Color(0.85, 0.25, 0.25))
		_basket = k.commit()
	var mi := MeshInstance3D.new()
	mi.mesh = _basket
	mi.material_override = Mats.world(0.0, 0.0)
	add_child(mi)
	_item_mi = MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.16
	s.height = 0.26
	s.radial_segments = 8
	s.rings = 4
	_item_mi.mesh = s
	_item_mi.position = Vector3(0, 0.32, 0)
	add_child(_item_mi)
	refresh()


func refresh() -> void:
	var has := Game.doorstep.has(npc_id)
	_item_mi.visible = has
	if has:
		var col := Color(0.95, 0.4, 0.4)
		var item: String = Game.doorstep[npc_id]
		match ItemDB.category(item):
			"forage":
				col = Color(0.5, 0.7, 0.3)
			"crafted":
				col = Color(0.95, 0.65, 0.3)
			"treat":
				col = Color(0.9, 0.75, 0.45)
		_item_mi.material_override = Mats.solid(col, false)


func get_prompt() -> String:
	var n := NpcDB.name_of(npc_id)
	if Game.doorstep.has(npc_id):
		return "Gift waiting for " + n
	return "Leave a gift for " + n


func interact(_player: Node) -> void:
	world.story.leave_doorstep_gift(self)
