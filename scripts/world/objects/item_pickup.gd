class_name ItemPickup
extends Interactable
## A single special item lying in the world (Astrid's kite, Ole's hat...).

var item := ""
var pickup_flag := ""
var available_fn: Callable
var _t := 0.0
var _vis: Node3D


func setup(item_id: String, flag: String, visual: Node3D) -> void:
	item = item_id
	pickup_flag = flag
	prompt = "Pick up " + ItemDB.name_of(item_id)
	radius = 1.2
	focus_height = 1.0
	_vis = visual
	add_child(visual)


func _process(delta: float) -> void:
	_t += delta
	if _vis:
		_vis.position.y = 0.15 + sin(_t * 2.5) * 0.08
		_vis.rotation.y += delta * 0.8


func refresh() -> void:
	var ok := not Game.has_flag(pickup_flag)
	if available_fn.is_valid():
		ok = ok and available_fn.call()
	visible = ok


func can_interact(_p: Node) -> bool:
	return visible


func interact(_player: Node) -> void:
	Game.set_flag(pickup_flag)
	Game.add_item(item)
	Sound.sfx("pickup", 1.2)
	visible = false
