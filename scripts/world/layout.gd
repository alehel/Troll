class_name Layout
extends RefCounted
## Hand-designed world layout. Kept in sync with tools/layout.py which is used
## for quick top-down previews of the terrain.

const X0 := -130.0
const X1 := 130.0
const Z0 := -150.0
const Z1 := 130.0
const STEP := 2.0
const SEA_Y := 0.0
const SHORE_Z := 68.0
const VILLAGE_Y := 3.0
const PLATEAU_Y := 28.0

## Playable bounds (invisible walls).
const PLAY_MIN := Vector2(-96.0, -126.0)
const PLAY_MAX := Vector2(112.0, 96.0)

## River polyline: (x, bed height, z).
const RIVER := [
	Vector3(35, 26.5, -82), Vector3(33, 26.3, -68), Vector3(31, 26.0, -56), Vector3(31, 14.6, -45),
	Vector3(32, 12.6, -30), Vector3(34, 7.6, -12), Vector3(38, 5.4, 5), Vector3(44, 2.4, 22),
	Vector3(48, 1.5, 40), Vector3(50, 0.9, 58), Vector3(52, -0.8, 72), Vector3(54, -3.0, 88),
]
const RIVER_HALF := 3.2
const RIVER_WATER_OFFSET := 0.55
## Lake: x, z, radius, water height.
const LAKE := [35.0, -96.0, 13.0, 27.2]

## Flattened zones: x, z, radius, falloff, target height (NAN = use base height).
const FLATS := [
	[0, 44, 12, 8, NAN],
	[-17, 35, 6, 4, NAN],
	[17, 33, 6, 4, NAN],
	[0, 24, 7, 4, NAN],
	[-24, 55, 6, 4, NAN],
	[24, 58, 6, 4, NAN],
	[-50, 42, 16, 8, NAN],
	[30, 18, 6, 4, NAN],
	[-14, 62, 7, 5, NAN],
	[-20, -78, 10, 8, NAN],
	[-36, -103, 9, 6, NAN],
	[-2, -91, 8, 6, NAN],
	[-57, -82, 9, 6, NAN],
	[15, -105, 8, 6, NAN],
	[62, -20, 11, 8, NAN],
	[-66, -104, 14, 6, 27.2],
]

## Paths: name, width, points (x, z, y or NAN for "follow the ground").
const PATHS := [
	["trail", 3.2, [Vector3(0, NAN, 28), Vector3(-3, NAN, 16), Vector3(3, NAN, 0), Vector3(0, NAN, -14),
		Vector3(-6, NAN, -28), Vector3(-9, 15.8, -40), Vector3(-18, 21.5, -49), Vector3(-27, 27.4, -58),
		Vector3(-25, NAN, -69), Vector3(-20, NAN, -78)]],
	["home", 2.6, [Vector3(-20, NAN, -78), Vector3(-29, NAN, -90), Vector3(-35, NAN, -100)]],
	["granny", 2.6, [Vector3(-20, NAN, -78), Vector3(-10, NAN, -85), Vector3(-3, NAN, -89)]],
	["stein", 2.6, [Vector3(-20, NAN, -78), Vector3(-40, NAN, -79), Vector3(-54, NAN, -81)]],
	["lyng", 2.4, [Vector3(-3, NAN, -89), Vector3(7, NAN, -97), Vector3(14, NAN, -103)]],
	["lake", 2.4, [Vector3(7, NAN, -97), Vector3(19, NAN, -93), Vector3(23, NAN, -91)]],
	["bridge", 2.6, [Vector3(2, NAN, -4), Vector3(18, NAN, -10), Vector3(34, 9.4, -12), Vector3(50, NAN, -15),
		Vector3(60, NAN, -19)]],
	["east_road", 4.0, [Vector3(6, NAN, 45), Vector3(24, NAN, 46), Vector3(48, 3.4, 42), Vector3(72, NAN, 46),
		Vector3(100, NAN, 50), Vector3(130, NAN, 52)]],
	["farm_road", 3.4, [Vector3(-6, NAN, 44), Vector3(-26, NAN, 42), Vector3(-44, NAN, 41)]],
	["dock", 2.6, [Vector3(3, NAN, 50), Vector3(8, NAN, 60), Vector3(9, NAN, 66)]],
	["lane_bakery", 2.4, [Vector3(-6, NAN, 41), Vector3(-15, NAN, 38)]],
	["lane_store", 2.4, [Vector3(6, NAN, 41), Vector3(15, NAN, 36)]],
	["lane_astrid", 2.4, [Vector3(-5, NAN, 49), Vector3(-21, NAN, 53)]],
	["lane_ole", 2.4, [Vector3(8, NAN, 60), Vector3(21, NAN, 58)]],
	["lane_chapel", 2.4, [Vector3(24, NAN, 46), Vector3(29, NAN, 22)]],
	["beach", 2.4, [Vector3(-4, NAN, 50), Vector3(-12, NAN, 60)]],
]

## Buildings: id -> [x, z, face_x, face_z, kind]. The door faces the face point.
const HOUSES := {
	"bakery": [-17.0, 35.0, -6.0, 41.0, "bakery"],
	"store": [17.0, 33.0, 6.0, 41.0, "store"],
	"mayor": [0.0, 23.5, 0.0, 34.0, "mayor"],
	"astrid": [-24.0, 55.0, -5.0, 49.0, "astrid"],
	"ole": [24.0, 58.0, 8.0, 60.0, "ole"],
	"farm": [-50.0, 36.0, -44.0, 41.0, "farm"],
	"chapel": [30.0, 17.5, 29.0, 26.0, "chapel"],
}

## Named points NPCs walk between and the story refers to.
const ANCHORS := {
	"square": Vector2(0, 44),
	"well": Vector2(0, 44),
	"notice_board": Vector2(-4, 36),
	"bakery_stand": Vector2(-10, 40),
	"store_bench": Vector2(10, 37),
	"beach": Vector2(-12, 60),
	"bonfire": Vector2(-14, 63),
	"dock": Vector2(9, 71),
	"dock_end": Vector2(9, 79),
	"net_rack": Vector2(16, 63),
	"farm_pen": Vector2(-52, 50),
	"farm_yard": Vector2(-44, 44),
	"chapel_yard": Vector2(26, 26),
	"east_road": Vector2(30, 46),
	"rockslide": Vector2(72, 46),
	"city_gate": Vector2(108, 50),
	"ring": Vector2(-20, -78),
	"home": Vector2(-36, -103),
	"home_bed": Vector2(-39, -107),
	"cauldron": Vector2(-31, -101),
	"granny_hut": Vector2(-2, -94),
	"granny_yard": Vector2(-4, -87),
	"stein_rocks": Vector2(-57, -82),
	"lyng_garden": Vector2(15, -105),
	"lake_shore": Vector2(24, -90),
	"troll_bridge": Vector2(34, -12),
	"under_bridge": Vector2(39.5, -9.5),
	"glade": Vector2(62, -20),
	"bog": Vector2(-66, -104),
	"waterfall": Vector2(31, -44),
	"kite_tree": Vector2(-22, -26),
	"goat_ledge": Vector2(56, -30),
	"hat_rock": Vector2(-48, -60),
	"festival": Vector2(-14, 63),
}

## Village navigation graph for humans: node -> [x, z]; edges listed below.
const NAV := {
	"S": Vector2(0, 44), "SN": Vector2(0, 35), "SE": Vector2(8, 43), "SW": Vector2(-8, 43), "SS": Vector2(0, 51),
	"M": Vector2(0, 30), "B1": Vector2(-8, 40), "B": Vector2(-12, 38.5), "ST1": Vector2(8, 40), "ST": Vector2(12, 37),
	"A1": Vector2(-6, 49), "A": Vector2(-19, 52.5), "D0": Vector2(4, 52), "D1": Vector2(8, 60), "D2": Vector2(9, 67),
	"D3": Vector2(9, 72), "D4": Vector2(9, 79), "O": Vector2(19.5, 58), "NR": Vector2(16, 63),
	"BE1": Vector2(-5, 51), "BE": Vector2(-12, 60), "BF": Vector2(-14, 63),
	"F1": Vector2(-18, 43), "F2": Vector2(-30, 42), "F3": Vector2(-44, 42), "F4": Vector2(-50, 49), "FH": Vector2(-47, 39.5),
	"E1": Vector2(16, 45), "E2": Vector2(24, 46), "C1": Vector2(27, 34), "C": Vector2(28.5, 23),
	"NB": Vector2(-4, 37),
}
const NAV_EDGES := [
	["S", "SN"], ["S", "SE"], ["S", "SW"], ["S", "SS"], ["SN", "M"], ["SN", "NB"], ["NB", "B1"], ["SW", "B1"],
	["B1", "B"], ["SE", "ST1"], ["SN", "ST1"], ["ST1", "ST"], ["SS", "A1"], ["SW", "A1"], ["A1", "A"],
	["SS", "D0"], ["D0", "D1"], ["D1", "D2"], ["D2", "D3"], ["D3", "D4"], ["D1", "O"], ["D1", "NR"], ["NR", "O"],
	["SS", "BE1"], ["A1", "BE1"], ["BE1", "BE"], ["BE", "BF"], ["SW", "F1"], ["F1", "F2"], ["F2", "F3"],
	["F3", "F4"], ["F3", "FH"], ["SE", "E1"], ["E1", "E2"], ["E2", "C1"], ["C1", "C"],
]

## Rockslide boulders blocking the east road.
const BOULDERS := [
	Vector2(68, 45), Vector2(71.5, 48.5), Vector2(74, 44.5), Vector2(77, 47.5), Vector2(72, 42),
]
