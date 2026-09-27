"""World layout constants (mirror of scripts/world/layout.gd)."""

X0, X1 = -130.0, 130.0
Z0, Z1 = -150.0, 130.0
STEP = 2.0
SEA_Y = 0.0
SHORE_Z = 68.0
VILLAGE_Y = 3.0
PLATEAU_Y = 28.0

# (x, z, bed_y)
RIVER = [
    (35, -82, 26.5), (33, -68, 26.3), (31, -56, 26.0), (31, -45, 14.6),
    (32, -30, 12.6), (34, -12, 7.6), (38, 5, 5.4), (44, 22, 2.4),
    (48, 40, 1.5), (50, 58, 0.9), (52, 72, -0.8), (54, 88, -3.0),
]
RIVER_HALF = 3.2
LAKE = (35.0, -96.0, 13.0, 27.2)  # x, z, radius, water y

# (x, z, radius, falloff, target_y or None)
FLATS = [
    (0, 44, 12, 8, None),        # village square
    (-17, 35, 6, 4, None),       # bakery
    (17, 33, 6, 4, None),        # store
    (0, 24, 7, 4, None),         # mayor
    (-24, 55, 6, 4, None),       # astrid's house
    (24, 58, 6, 4, None),        # ole's cottage
    (-50, 42, 16, 8, None),      # farm
    (30, 18, 6, 4, None),        # chapel
    (-14, 62, 7, 5, None),       # festival beach
    (-20, -78, 10, 8, None),     # troll gathering ring
    (-36, -103, 9, 6, None),     # player's hollow
    (-2, -91, 8, 6, None),       # granny
    (-57, -82, 9, 6, None),      # stein
    (15, -105, 8, 6, None),      # lyng
    (62, -20, 11, 8, None),      # berry glade
    (-66, -104, 14, 6, 27.2),    # cloudberry bog
]

PATHS = [
    {"name": "trail", "width": 3.2, "pts": [
        (-7, 37, None), (-9.5, 27, None), (-7, 16, None), (3, 0, None), (0, -14, None), (-6, -28, None),
        (-9, -40, 15.8), (-18, -49, 21.5), (-27, -58, 27.4), (-25, -69, None), (-20, -78, None)]},
    {"name": "home", "width": 2.6, "pts": [(-20, -78, None), (-29, -90, None), (-35, -100, None)]},
    {"name": "granny", "width": 2.6, "pts": [(-20, -78, None), (-10, -85, None), (-3, -89, None)]},
    {"name": "stein", "width": 2.6, "pts": [(-20, -78, None), (-40, -79, None), (-54, -81, None)]},
    {"name": "lyng", "width": 2.4, "pts": [(-3, -89, None), (7, -97, None), (14, -103, None)]},
    {"name": "lake", "width": 2.4, "pts": [(7, -97, None), (19, -93, None), (23, -91, None)]},
    {"name": "bridge", "width": 2.6, "pts": [(2, -4, None), (18, -10, None), (34, -12, 9.4), (50, -15, None), (60, -19, None)]},
    {"name": "east_road", "width": 4.0, "pts": [(6, 45, None), (24, 46, None), (48, 42, 3.4), (72, 46, None), (100, 50, None), (130, 52, None)]},
    {"name": "farm_road", "width": 3.4, "pts": [(-6, 44, None), (-26, 42, None), (-44, 41, None)]},
    {"name": "dock", "width": 2.6, "pts": [(3, 50, None), (8, 60, None), (9, 69.5, None)]},
    {"name": "lane_bakery", "width": 2.4, "pts": [(-6, 41, None), (-15, 38, None)]},
    {"name": "lane_store", "width": 2.4, "pts": [(6, 41, None), (15, 36, None)]},
    {"name": "lane_astrid", "width": 2.4, "pts": [(-5, 49, None), (-21, 53, None)]},
    {"name": "lane_ole", "width": 2.4, "pts": [(8, 60, None), (21, 58, None)]},
    {"name": "lane_chapel", "width": 2.4, "pts": [(24, 46, None), (29, 22, None)]},
    {"name": "beach", "width": 2.4, "pts": [(-4, 50, None), (-12, 60, None)]},
]

LANDMARKS = {
    "square": (0, 44), "bakery": (-17, 35), "store": (17, 33), "mayor": (0, 24),
    "astrid": (-24, 55), "ole": (24, 58), "farm": (-50, 42), "chapel": (30, 18),
    "bonfire": (-14, 62), "dock": (9, 78), "rockslide": (72, 46), "bridgeV": (48, 42),
    "trollbridge": (34, -12), "glade": (62, -20), "ring": (-20, -78), "home": (-36, -103),
    "granny": (-2, -91), "stein": (-57, -82), "lyng": (15, -105), "lake": (35, -96),
    "bog": (-66, -104), "fall": (31, -50),
}
