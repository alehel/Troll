class_name World
extends Node3D
## Builds and owns the whole 3D world and offers shared queries (ground
## height, navigation, anchors) to actors and the story.

signal bark_requested(target: Node3D, text: String, seconds: float)
signal built

const LITTER_SPOTS := [
	[-12, 32, "ingrid"], [-21, 41, "ingrid"], [-9, 35.5, "ingrid"],
	[21, 38, "solveig"], [12, 29.5, "solveig"], [22.5, 29, "solveig"],
	[-6, 28, "margit"], [7, 27, "margit"], [4, 33, "margit"],
	[5, 49, ""], [-6, 47.5, ""], [9, 40, ""], [-3, 53, ""],
	[-29, 59, "astrid"], [-18, 59, "astrid"], [-27, 50, "astrid"],
	[17, 61.5, "ole"], [27, 62, "ole"], [14, 57, "ole"],
	[-39, 45, "lars"], [-35, 38, "lars"], [-30, 46, "lars"],
	[-21, 64, ""], [-6, 63, ""], [25, 31, "margit"],
]

const FORAGE := {
	"bush_blue": [[-26, -94, 5, 2], [-12, -94, 6, 2], [-40, -82, 10, 2], [4, -76, 10, 2], [-60, -96, 8, 1],
		[-30, -22, 12, 2], [18, -30, 10, 2], [45, -5, 10, 2], [62, -20, 8, 2]],
	"bush_lingon": [[-35, -30, 14, 3], [10, -40, 12, 2], [-15, -5, 12, 2], [30, -25, 10, 2], [55, -30, 10, 2]],
	"bush_cloud": [[-66, -104, 11, 8]],
	"mushroom": [[-40, -15, 14, 3], [15, -20, 12, 3], [-10, -35, 10, 2], [45, -35, 10, 2]],
	"flower": [[-30, 25, 12, 3], [30, 30, 10, 2], [-16, 58, 4, 1], [62, -20, 9, 3], [40, 58, 8, 2], [-60, 62, 8, 2]],
	"heather": [[-45, -70, 12, 3], [10, -88, 12, 3], [-5, -110, 10, 2], [45, -75, 10, 2], [-70, -80, 8, 2]],
	"moss": [[-30, -112, 8, 2], [-55, -90, 10, 2], [20, -112, 8, 2], [0, -66, 10, 2], [35, -70, 8, 2]],
	"pinecone": [[-45, -25, 12, 3], [20, -15, 12, 2], [0, -45, 10, 2], [50, -10, 10, 2]],
	"crystal": [[20, -42.5, 6, 2], [42, -43, 6, 2], [-40, -43, 8, 1], [-65, -45, 8, 1], [8, -42, 5, 1]],
	"feather": [[-20, -60, 15, 2], [30, -88, 10, 2], [-40, 10, 12, 2], [20, 10, 10, 2]],
	"stone": [[-35, 67, 8, 2], [25, 70, 6, 2], [-50, 66, 8, 1]],
}

const TUSSA_SPOTS := [Vector2(-46, -95), Vector2(27, -103), Vector2(-5, -67)]

var terrain: Terrain
var water: Water
var buildings: Buildings
var vegetation: Vegetation
var daynight: DayNight
var player: Player
var rig: CameraRig
var story: Node
var ui: Node
var npcs := {}
var animals: Array = []
var bukken: Animal
var forage_spots: Array = []
var gift_spots := {}
var pickups: Array = []
var litter_nodes: Array = []
var boulders: Array = []
var kite_tree: Node3D
var _kite_vis: Node3D
var _astar := AStar3D.new()
var _nav_ids := {}
var _spot_points: Array = []
var cutscene := false
var _rng := RandomNumberGenerator.new()


# --------------------------------------------------------------------------
# construction
# --------------------------------------------------------------------------
func build() -> void:
	_rng.seed = 777
	terrain = Terrain.new()
	terrain.name = "Terrain"
	add_child(terrain)
	terrain.build()
	for c in terrain.get_children():
		if c is StaticBody3D:
			(c as StaticBody3D).collision_layer = 2
			(c as StaticBody3D).collision_mask = 0
	water = Water.new()
	water.name = "Water"
	add_child(water)
	water.build(terrain)
	buildings = Buildings.new()
	buildings.name = "Buildings"
	add_child(buildings)
	buildings.build(terrain)
	var clear: Array = buildings.clearings.duplicate()
	clear.append(Vector3(72, 46, 9)) # rockslide
	clear.append(Vector3(48, 42, 9)) # village bridge
	clear.append(Vector3(34, -12, 9)) # troll bridge
	clear.append(Vector3(9, 76, 10)) # dock
	var kt: Vector2 = Layout.ANCHORS["kite_tree"]
	clear.append(Vector3(kt.x, kt.y, 3.5))
	for s in TUSSA_SPOTS:
		clear.append(Vector3(s.x, s.y, 2.0))
	vegetation = Vegetation.new()
	vegetation.name = "Vegetation"
	add_child(vegetation)
	vegetation.build(terrain, func(x: float, z: float) -> bool:
		for c in clear:
			if Vector2(x - c.x, z - c.y).length() < c.z:
				return true
		return false)
	daynight = DayNight.new()
	daynight.name = "DayNight"
	add_child(daynight)
	daynight.build(buildings)
	var life := AmbientLife.new()
	life.name = "AmbientLife"
	add_child(life)
	life.build(terrain)
	_build_nav()
	_invisible_walls()
	_spawn_objects()
	_spawn_player()
	_spawn_npcs()
	_spawn_animals()
	Game.quest_changed.connect(func(_id): _on_quest_changed())
	emit_signal("built")


func _on_quest_changed() -> void:
	for p in pickups:
		(p as ItemPickup).refresh()
	if _kite_vis:
		_kite_vis.visible = Game.is_active("m5_kite") and not Game.has_flag("kite_dropped")
	if bukken:
		bukken.refresh()
	if story:
		story.update_tussa()


func _build_nav() -> void:
	var i := 0
	for k in Layout.NAV.keys():
		var p: Vector2 = Layout.NAV[k]
		_astar.add_point(i, Vector3(p.x, 0, p.y))
		_nav_ids[k] = i
		i += 1
	for e in Layout.NAV_EDGES:
		_astar.connect_points(_nav_ids[e[0]], _nav_ids[e[1]])


func _invisible_walls() -> void:
	var body := StaticBody3D.new()
	body.name = "Bounds"
	add_child(body)
	var mn := Layout.PLAY_MIN
	var mx := Layout.PLAY_MAX
	var cx := (mn.x + mx.x) * 0.5
	var cz := (mn.y + mx.y) * 0.5
	var sx := mx.x - mn.x
	var sz := mx.y - mn.y
	for w in [[Vector3(cx, 50, mn.y), Vector3(sx + 4, 200, 2)], [Vector3(cx, 50, mx.y), Vector3(sx + 4, 200, 2)],
			[Vector3(mn.x, 50, cz), Vector3(2, 200, sz + 4)], [Vector3(mx.x, 50, cz), Vector3(2, 200, sz + 4)]]:
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = w[1]
		cs.shape = sh
		cs.position = w[0]
		body.add_child(cs)


func _valid_spot(x: float, z: float, max_slope := 0.8, min_gap := 2.2) -> bool:
	if x < Layout.PLAY_MIN.x + 3 or x > Layout.PLAY_MAX.x - 3 or z < Layout.PLAY_MIN.y + 3 or z > Layout.PLAY_MAX.y - 3:
		return false
	var h := terrain.height_at(x, z)
	if h < 0.3:
		return false
	if terrain.normal_at(x, z).y < max_slope:
		return false
	if terrain.water_level_at(x, z) > h - 0.1:
		return false
	if terrain.path_weight_at(x, z) > 0.5:
		return false
	for c in buildings.clearings:
		if Vector2(x - c.x, z - c.y).length() < c.z * 0.72:
			return false
	for t in vegetation.tree_points:
		if Vector2(x - t.x, z - t.y).length() < 1.3:
			return false
	for p in _spot_points:
		if Vector2(x - p.x, z - p.y).length() < min_gap:
			return false
	return true


func _find_spot(cx: float, cz: float, r: float, max_slope := 0.8) -> Vector2:
	for i in range(60):
		var a := _rng.randf() * TAU
		var d := sqrt(_rng.randf()) * r
		var x := cx + cos(a) * d
		var z := cz + sin(a) * d
		if _valid_spot(x, z, max_slope):
			return Vector2(x, z)
	return Vector2(INF, INF)


func _add_forage(kind: String, p: Vector2, idx: int) -> void:
	var f := ForageSpot.new()
	f.name = "Forage_%s_%d" % [kind, idx]
	f.world = self
	add_child(f)
	f.setup("%s_%d" % [kind, idx], kind)
	f.global_position = Vector3(p.x, terrain.height_at(p.x, p.y) - 0.05, p.y)
	forage_spots.append(f)
	_spot_points.append(p)


func _spawn_objects() -> void:
	# foraging
	for kind in FORAGE.keys():
		var idx := 0
		for z in FORAGE[kind]:
			for n in range(int(z[3])):
				var slope := 0.55 if kind == "crystal" else 0.8
				var p := _find_spot(z[0], z[1], z[2], slope)
				if p.x == INF:
					continue
				_add_forage(kind, p, idx)
				idx += 1
	# river stones and beach driftwood
	var ridx := 0
	var rp: Array = terrain.river_points()
	for i in range(2, rp.size() - 2):
		var a: Vector3 = rp[i]
		var b: Vector3 = rp[i + 1]
		var dir := Vector2(b.x - a.x, b.z - a.z).normalized()
		var side := Vector2(-dir.y, dir.x) * (Layout.RIVER_HALF + 3.2) * (1 if i % 2 == 0 else -1)
		var p2 := Vector2(a.x, a.z) + side
		if _valid_spot(p2.x, p2.y, 0.7):
			_add_forage("stone", p2, 100 + ridx)
			ridx += 1
	var didx := 0
	var x := -70.0
	while x < 90.0 and didx < 14:
		x += _rng.randf_range(7.0, 14.0)
		var sz := Terrain.shore_z(x)
		for k in range(12):
			var z := sz - 6.0 + k * 0.8
			var h := terrain.height_at(x, z)
			if h > 0.25 and h < 1.3 and terrain.normal_at(x, z).y > 0.8:
				var ok := true
				for c in buildings.clearings:
					if Vector2(x - c.x, z - c.y).length() < c.z * 0.6:
						ok = false
				if ok and absf(x - Buildings.DOCK_X) > 3.0:
					_add_forage("driftwood", Vector2(x, z), didx)
					didx += 1
				break
	# gift baskets
	for id in NpcDB.humans():
		var house: String = NpcDB.NPCS[id]["house"]
		var info: Dictionary = buildings.houses[house]
		var g := GiftSpot.new()
		g.name = "Gift_" + id
		g.world = self
		add_child(g)
		g.setup(id)
		g.global_position = info["gift"]
		gift_spots[id] = g
	# boulders
	for i in range(Layout.BOULDERS.size()):
		var bp: Vector2 = Layout.BOULDERS[i]
		var b := Boulder.new()
		b.name = "Boulder_%d" % i
		b.world = self
		add_child(b)
		b.setup(i)
		b.global_position = Vector3(bp.x, terrain.height_at(bp.x, bp.y) - 0.2, bp.y)
		boulders.append(b)
	# bed, cauldron, notice board, signs
	var bed: Vector2 = Layout.ANCHORS["home_bed"]
	var bed_obj := SimpleObject.new().setup("Sleep", func(_p): story.sleep_prompt(), 1.8, 0.8)
	bed_obj.world = self
	add_child(bed_obj)
	bed_obj.global_position = Vector3(bed.x, terrain.height_at(bed.x, bed.y), bed.y)
	var cau: Vector2 = Layout.ANCHORS["cauldron"]
	var cau_obj := SimpleObject.new().setup("Cook at the cauldron", func(_p): ui.open_craft(), 1.6, 1.4)
	add_child(cau_obj)
	cau_obj.global_position = Vector3(cau.x, terrain.height_at(cau.x, cau.y), cau.y)
	var nb: Vector2 = Layout.ANCHORS["notice_board"]
	var nb_obj := SimpleObject.new().setup("Read the notice board", func(_p): story.read_notice_board(), 1.8, 1.8)
	add_child(nb_obj)
	nb_obj.global_position = Vector3(nb.x, terrain.height_at(nb.x, nb.y - 1.2), nb.y - 1.2)
	var home: Vector2 = Layout.ANCHORS["home"]
	var sign_obj := SimpleObject.new().setup("Read the sign", func(_p): story.narrate(["* The sign reads: \"%s's Hollow. Trolls welcome. Humans also welcome (please knock).\"" % Game.player_name]), 1.4, 1.4)
	add_child(sign_obj)
	sign_obj.global_position = Vector3(home.x + 7.0, terrain.height_at(home.x + 7.0, home.y + 6.0), home.y + 6.0)
	var gate: Vector2 = Layout.ANCHORS["city_gate"]
	var gate_obj := SimpleObject.new().setup("Read the road sign", func(_p): story.read_city_sign(), 2.5, 1.6)
	add_child(gate_obj)
	gate_obj.global_position = Vector3(gate.x, terrain.height_at(gate.x, gate.y), gate.y)
	# pickups
	var hat_vis := _hat_visual()
	var hr: Vector2 = Layout.ANCHORS["hat_rock"]
	var hat := ItemPickup.new()
	hat.name = "LuckyHat"
	hat.world = self
	add_child(hat)
	hat.setup("lucky_hat", "got_hat", hat_vis)
	hat.available_fn = func() -> bool: return Game.is_active("s_ole_hat") and Game.count("lucky_hat") == 0
	hat.global_position = Vector3(hr.x, terrain.height_at(hr.x, hr.y), hr.y)
	pickups.append(hat)
	var kite := ItemPickup.new()
	kite.name = "KitePickup"
	kite.world = self
	add_child(kite)
	kite.setup("kite", "got_kite", _kite_visual())
	kite.available_fn = func() -> bool: return Game.has_flag("kite_dropped") and Game.count("kite") == 0 and not Game.is_done("m5_kite")
	var kt: Vector2 = Layout.ANCHORS["kite_tree"]
	kite.global_position = Vector3(kt.x + 1.8, terrain.height_at(kt.x + 1.8, kt.y + 1.2), kt.y + 1.2)
	pickups.append(kite)
	_build_kite_tree()


func _hat_visual() -> Node3D:
	var n := Node3D.new()
	var k := MeshKit.new(71)
	var y := Color(0.95, 0.8, 0.2)
	k.cylinder(Vector3(0, 0.1, 0), 0.5, 0.52, 0.05, 10, y.darkened(0.1), y)
	k.cylinder(Vector3(0, 0.12, 0), 0.26, 0.17, 0.28, 8, y)
	var mi := MeshInstance3D.new()
	mi.mesh = k.commit()
	mi.material_override = Mats.world(0.0, 0.0)
	mi.rotation.z = 0.3
	n.add_child(mi)
	return n


func _kite_visual(big := false) -> Node3D:
	var n := Node3D.new()
	var k := MeshKit.new(72)
	var s := 1.3 if big else 0.8
	k.tri(Vector3(0, 0.9, 0) * s, Vector3(0.45, 0.35, 0) * s, Vector3(0, 0.35, 0) * s, Color(0.9, 0.25, 0.25))
	k.tri(Vector3(0, 0.9, 0) * s, Vector3(0, 0.35, 0) * s, Vector3(-0.45, 0.35, 0) * s, Color(0.95, 0.8, 0.25))
	k.tri(Vector3(0, 0.35, 0) * s, Vector3(0.45, 0.35, 0) * s, Vector3(0, -0.4, 0) * s, Color(0.3, 0.45, 0.85))
	k.tri(Vector3(0, 0.35, 0) * s, Vector3(0, -0.4, 0) * s, Vector3(-0.45, 0.35, 0) * s, Color(0.95, 0.95, 0.9))
	# back faces
	k.tri(Vector3(0.45, 0.35, 0) * s, Vector3(0, 0.9, 0) * s, Vector3(0, 0.35, 0) * s, Color(0.9, 0.25, 0.25))
	k.tri(Vector3(0, 0.35, 0) * s, Vector3(0, 0.9, 0) * s, Vector3(-0.45, 0.35, 0) * s, Color(0.95, 0.8, 0.25))
	k.tri(Vector3(0.45, 0.35, 0) * s, Vector3(0, 0.35, 0) * s, Vector3(0, -0.4, 0) * s, Color(0.3, 0.45, 0.85))
	k.tri(Vector3(0, -0.4, 0) * s, Vector3(0, 0.35, 0) * s, Vector3(-0.45, 0.35, 0) * s, Color(0.95, 0.95, 0.9))
	for i in range(4):
		k.box(Vector3(0.05 * (i % 2), -0.55 - i * 0.22, 0) * s, Vector3(0.12, 0.06, 0.04) * s, Color(0.9, 0.25, 0.25) if i % 2 == 0 else Color(0.95, 0.8, 0.25))
	var mi := MeshInstance3D.new()
	mi.mesh = k.commit()
	mi.material_override = Mats.world(0.0, 0.0)
	n.add_child(mi)
	return n


func _build_kite_tree() -> void:
	var kt: Vector2 = Layout.ANCHORS["kite_tree"]
	var y := terrain.height_at(kt.x, kt.y)
	kite_tree = Node3D.new()
	kite_tree.name = "KiteTree"
	add_child(kite_tree)
	kite_tree.global_position = Vector3(kt.x, y, kt.y)
	var mi := MeshInstance3D.new()
	mi.mesh = Vegetation.spruce_mesh(1)
	mi.material_override = Mats.world(0.0, 0.25)
	mi.scale = Vector3(1.5, 1.8, 1.5)
	kite_tree.add_child(mi)
	_kite_vis = _kite_visual(true)
	_kite_vis.position = Vector3(0.9, 6.5, 1.4)
	_kite_vis.rotation = Vector3(0.3, 0.6, 0.5)
	kite_tree.add_child(_kite_vis)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.6
	sh.height = 4.0
	cs.shape = sh
	cs.position = Vector3(0, 2, 0)
	body.add_child(cs)
	kite_tree.add_child(body)
	var shake := SimpleObject.new().setup("Shake the tree", func(p): _shake_kite_tree(p), 2.0, 2.5)
	shake.available_fn = func() -> bool: return Game.is_active("m5_kite") and Game.quest_step("m5_kite") == 1 and not Game.has_flag("kite_dropped")
	add_child(shake)
	shake.global_position = kite_tree.global_position


func _shake_kite_tree(p: Node) -> void:
	(p as Player).play_mode("shake", 1.2)
	Sound.sfx("rustle", 1.0)
	var tw := create_tween()
	for i in range(6):
		tw.tween_property(kite_tree, "rotation:z", 0.05 * (1 if i % 2 == 0 else -1), 0.1)
	tw.tween_property(kite_tree, "rotation:z", 0.0, 0.1)
	var fall := create_tween()
	fall.tween_interval(0.8)
	fall.tween_property(_kite_vis, "position", Vector3(1.8, 0.4, 1.2), 0.9).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	fall.tween_callback(func():
		_kite_vis.visible = false
		Game.set_flag("kite_dropped")
		refresh_day_objects())
	show_bark(p, "Something's coming down!", 2.0)


func _spawn_player() -> void:
	player = Player.new()
	player.name = "Player"
	player.world = self
	player.collision_layer = 8
	player.collision_mask = 1 | 2 | 4 | 16
	add_child(player)
	rig = CameraRig.new()
	rig.name = "CameraRig"
	rig.terrain = terrain
	add_child(rig)
	rig.target = player
	player.rig = rig
	place_player_at_home()


func place_player_at_home() -> void:
	var home: Vector2 = Layout.ANCHORS["home"]
	var p := Vector2(home.x + 3.5, home.y + 4.5)
	player.global_position = Vector3(p.x, terrain.height_at(p.x, p.y) + 0.1, p.y)
	player.velocity = Vector3.ZERO
	player.face_toward(Vector3(-20, 0, -78))
	rig.yaw_target = 0.75
	rig.snap()


func _spawn_npcs() -> void:
	for id in NpcDB.NPCS.keys():
		var n := NPC.new()
		n.name = "NPC_" + id
		add_child(n)
		n.setup(id, self)
		n.place_by_schedule()
		npcs[id] = n


func _spawn_animals() -> void:
	for i in range(5):
		var a := Animal.new()
		a.name = "Animal_%d" % i
		add_child(a)
		a.setup("goat" if i < 3 else "sheep", self)
		var p := Vector3(randf_range(Animal.PEN_MIN.x, Animal.PEN_MAX.x), 0, randf_range(Animal.PEN_MIN.y, Animal.PEN_MAX.y))
		p.y = ground_height(p.x, p.z)
		a.global_position = p
		animals.append(a)
	bukken = Animal.new()
	bukken.name = "Bukken"
	add_child(bukken)
	bukken.setup("goat", self, true)
	var bp := Vector3(-50, 0, 52)
	bp.y = ground_height(bp.x, bp.z)
	bukken.global_position = bp
	animals.append(bukken)


# --------------------------------------------------------------------------
# day refresh
# --------------------------------------------------------------------------
func refresh_day_objects() -> void:
	for f in forage_spots:
		(f as ForageSpot).refresh()
	for g in gift_spots.values():
		(g as GiftSpot).refresh()
	for p in pickups:
		(p as ItemPickup).refresh()
	for i in range(boulders.size()):
		var b = boulders[i]
		if is_instance_valid(b) and Game.has_flag("boulder_%d" % i):
			b.queue_free()
	if _kite_vis:
		_kite_vis.visible = Game.is_active("m5_kite") and not Game.has_flag("kite_dropped")
	bukken.refresh()


func spawn_litter() -> void:
	for l in litter_nodes:
		if is_instance_valid(l):
			l.queue_free()
	litter_nodes.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + Game.day * 7919
	var count := 6 if Game.day == 1 else rng.randi_range(3, 5)
	if Game.has_flag("game_complete"):
		count = rng.randi_range(1, 3)
	var idxs := range(LITTER_SPOTS.size())
	for i in range(idxs.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = idxs[i]
		idxs[i] = idxs[j]
		idxs[j] = tmp
	for n in range(count):
		var s: Array = LITTER_SPOTS[idxs[n]]
		var lid := "d%d_%d" % [Game.day, idxs[n]]
		if Game.cleaned.has(lid):
			continue
		var l := Litter.new()
		l.name = "Litter_" + lid
		l.world = self
		add_child(l)
		l.setup(lid, Litter.KINDS[rng.randi() % Litter.KINDS.size()], s[2])
		l.global_position = Vector3(s[0], ground_height(s[0], s[1]), s[1])
		litter_nodes.append(l)


func start_day() -> void:
	refresh_day_objects()
	spawn_litter()
	for n in npcs.values():
		(n as NPC).place_by_schedule()
	story.update_tussa()


# --------------------------------------------------------------------------
# queries
# --------------------------------------------------------------------------
func ground_height(x: float, z: float) -> float:
	var h := terrain.height_at(x, z)
	var bh := buildings.bridge_height(x, z)
	if not is_nan(bh):
		h = maxf(h, bh)
	if absf(x - Buildings.DOCK_X) < 1.3 and z > Buildings.DOCK_Z0 and z < Buildings.DOCK_Z1:
		h = maxf(h, buildings.dock_y + 0.06)
	return h


func water_depth_at(p: Vector3) -> float:
	var lvl := terrain.water_level_at(p.x, p.z)
	if lvl == -INF:
		return 0.0
	return lvl - p.y


func anchor_position(a: String, npc_id: String) -> Vector3:
	if a == "home":
		var house: String = NpcDB.NPCS.get(npc_id, {}).get("house", "")
		if house != "" and buildings.houses.has(house):
			var d: Vector3 = buildings.houses[house]["door"]
			return Vector3(d.x, ground_height(d.x, d.z), d.z)
		a = NpcDB.NPCS.get(npc_id, {}).get("schedule", [[0, "ring", 1]])[0][1]
	var p: Vector2 = Layout.ANCHORS.get(a, Vector2.ZERO)
	return Vector3(p.x, ground_height(p.x, p.y), p.y)


func nav_path(from: Vector3, to: Vector3) -> Array:
	var a := _astar.get_closest_point(Vector3(from.x, 0, from.z))
	var b := _astar.get_closest_point(Vector3(to.x, 0, to.z))
	var out: Array = []
	var pts := _astar.get_point_path(a, b)
	for i in range(pts.size()):
		var q: Vector3 = pts[i]
		# skip the first node if it's behind us relative to the second
		if i == 0 and pts.size() > 1:
			var q1: Vector3 = pts[1]
			if Vector2(from.x - q1.x, from.z - q1.z).length() < Vector2(q.x - q1.x, q.z - q1.z).length():
				continue
		out.append(Vector3(q.x, 0, q.z))
	out.append(Vector3(to.x, 0, to.z))
	return out


func is_free_spot(x: float, z: float) -> bool:
	var space := get_world_3d().direct_space_state
	var q := PhysicsShapeQueryParameters3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 0.6
	q.shape = sh
	q.transform = Transform3D(Basis.IDENTITY, Vector3(x, ground_height(x, z) + 0.9, z))
	q.collision_mask = 1
	var hits := space.intersect_shape(q, 1)
	if not hits.is_empty():
		return false
	return water_depth_at(Vector3(x, ground_height(x, z), z)) < 0.1


## World position of the current objective (or null).
func objective_target() -> Variant:
	var act := Game.active_quests()
	var where := ""
	if act.is_empty():
		for r in Game.requests:
			if not r["done"]:
				where = "npc:" + String(r["npc"])
				break
	else:
		# prefer the first quest step that points somewhere
		for qid in act:
			var step := Game.current_step(qid)
			where = step.get("where", "")
			if where == "" and step.has("talk"):
				where = "npc:" + String(step["talk"])
			if where == "" and step.has("turn_in"):
				var take: Dictionary = step["turn_in"].get("take", {})
				if Game.has_items(take):
					where = "npc:" + String(step["turn_in"]["npc"])
			if where != "":
				break
	if where == "":
		return null
	var pp := player.global_position
	if where.begins_with("npc:"):
		var n: NPC = npcs.get(where.substr(4))
		if n == null:
			return null
		if n.state == "hidden":
			return anchor_position("home", n.id)
		return n.global_position + Vector3(0, n.model.height, 0)
	if where.begins_with("anchor:"):
		return anchor_position(where.substr(7), "") + Vector3(0, 1.5, 0)
	if where.begins_with("spot:"):
		return _nearest(forage_spots.filter(func(f): return f.kind == where.substr(5) and f.available), pp)
	match where:
		"litter":
			return _nearest(litter_nodes.filter(func(l): return is_instance_valid(l)), pp)
		"gift":
			return _nearest(gift_spots.values().filter(func(g): return not Game.doorstep.has(g.npc_id)), pp)
		"boulders":
			return _nearest(boulders.filter(func(b): return is_instance_valid(b)), pp)
		"bukken":
			return bukken.global_position + Vector3(0, 1.4, 0)
		"kite":
			if Game.has_flag("kite_dropped"):
				return _nearest(pickups.filter(func(p): return p.visible and p.item == "kite"), pp)
			return kite_tree.global_position + Vector3(0, 6.5, 0)
		"invite":
			var left: Array = []
			for id in NpcDB.trolls():
				if not Game.has_flag("invited_" + id):
					left.append(npcs[id])
			return _nearest(left, pp)
	return null


func _nearest(nodes: Array, from: Vector3) -> Variant:
	var best: Variant = null
	var bd := 1e9
	for n in nodes:
		var d := (n as Node3D).global_position.distance_to(from)
		if d < bd:
			bd = d
			best = (n as Node3D).global_position + Vector3(0, 1.2, 0)
	return best


func is_cutscene() -> bool:
	return cutscene


func is_speaking(n: Node) -> bool:
	return ui != null and ui.is_speaking(n)


func show_bark(target: Node3D, text: String, seconds := 2.5) -> void:
	emit_signal("bark_requested", target, text, seconds)


func on_human_fled(n: NPC) -> void:
	if not Game.has_flag("first_flee"):
		Game.set_flag("first_flee")
	story.on_human_fled(n)


func on_litter_cleaned(l: Litter) -> void:
	for n in npcs.values():
		var npc := n as NPC
		if not npc.is_human or not npc.visible or npc.state == "flee":
			continue
		if npc.global_position.distance_to(l.global_position) < 14.0:
			var st := Game.trust_stage(npc.id)
			if st >= 1:
				Game.add_trust(npc.id, 1.5)
				npc.bark(NpcDB.pick(["Did the troll just... tidy up?", "Oh! Thank you!", "Well I never! A tidy troll!", "Look at that. Hm."]) if st < 3 else NpcDB.pick(["Thank you, {name}!", "You're a treasure, {name}!", "Lillevik has never been so tidy!"]), 2.4)


func spawn_puff(p: Vector3, col: Color) -> void:
	var s := CPUParticles3D.new()
	s.one_shot = true
	s.emitting = false
	s.amount = 12
	s.lifetime = 0.7
	s.explosiveness = 0.95
	s.direction = Vector3.UP
	s.spread = 80.0
	s.initial_velocity_min = 1.5
	s.initial_velocity_max = 3.0
	s.gravity = Vector3(0, -4, 0)
	var m := BoxMesh.new()
	m.size = Vector3(0.15, 0.15, 0.15)
	m.material = Mats.unshaded(col)
	s.mesh = m
	add_child(s)
	s.global_position = p
	s.emitting = true
	get_tree().create_timer(1.5).timeout.connect(s.queue_free)


func spawn_splash(p: Vector3) -> void:
	spawn_puff(p, Color(0.85, 0.95, 1.0))
	spawn_puff(p + Vector3(0.5, 0, 0.3), Color(1, 1, 1))


var _amb_t := 0.0


func _process(delta: float) -> void:
	if daynight:
		daynight.update(Game.minutes)
		Sound.set_night_amount(daynight.night_amount)
	_amb_t -= delta
	if _amb_t <= 0.0 and player and rig:
		_amb_t = 0.4
		# listen from the camera focus so the title screen orbit hears the valley too
		var ear: Vector3 = rig.cam.global_position if not rig.override_pose.is_empty() else player.global_position
		var q := Terrain.polyline_query(ear.x, ear.z, terrain.river_points())
		var v := clampf(1.0 - (q.x - 3.0) / 22.0, 0.0, 1.0)
		var fall := Vector2(ear.x - 31.0, ear.z + 48.0).length()
		v = maxf(v, clampf(1.0 - fall / 40.0, 0.0, 1.0))
		Sound.set_river_amount(v * v)
