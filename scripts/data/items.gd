class_name ItemDB
extends RefCounted
## Every item in the game. "cat" is used for sorting and flavour.

const ITEMS := {
	# --- Foraged -----------------------------------------------------------
	"blueberry": {"name": "Blueberry", "plural": "Blueberries", "cat": "forage",
		"desc": "Blåbær. Sweet and blue. Stains troll tongues for days."},
	"lingonberry": {"name": "Lingonberry", "plural": "Lingonberries", "cat": "forage",
		"desc": "Tyttebær. Tart little red jewels from the forest floor."},
	"cloudberry": {"name": "Cloudberry", "plural": "Cloudberries", "cat": "forage",
		"desc": "Multe. The golden treasure of the bog. Humans go wild for these."},
	"chanterelle": {"name": "Chanterelle", "plural": "Chanterelles", "cat": "forage",
		"desc": "Kantarell. A golden funnel mushroom that smells faintly of apricots."},
	"wildflower": {"name": "Wildflower", "plural": "Wildflowers", "cat": "forage",
		"desc": "A cheerful little flower from the meadow."},
	"heather": {"name": "Heather", "plural": "Heather sprigs", "cat": "forage",
		"desc": "Lyng. Purple and hardy, just like Granny Ur."},
	"moss": {"name": "Moss", "plural": "Moss clumps", "cat": "forage",
		"desc": "Soft, springy, delicious. (To trolls.)"},
	"pinecone": {"name": "Pinecone", "plural": "Pinecones", "cat": "forage",
		"desc": "A spruce cone. Makes a satisfying crunch."},
	"pretty_stone": {"name": "Pretty Stone", "plural": "Pretty Stones", "cat": "forage",
		"desc": "Smooth and speckled. Stein would approve."},
	"crystal": {"name": "Mountain Crystal", "plural": "Mountain Crystals", "cat": "forage",
		"desc": "Bergkrystall. Glitters like frost in the sun."},
	"feather": {"name": "Feather", "plural": "Feathers", "cat": "forage",
		"desc": "Dropped by a passing ptarmigan."},
	"driftwood": {"name": "Driftwood", "plural": "Driftwood", "cat": "forage",
		"desc": "Silvery wood, washed smooth by the fjord."},
	# --- Crafted -----------------------------------------------------------
	"blueberry_jam": {"name": "Blueberry Jam", "plural": "Blueberry Jams", "cat": "crafted",
		"desc": "A jar of homemade blåbærsyltetøy with a checkered lid."},
	"lingonberry_jam": {"name": "Lingonberry Jam", "plural": "Lingonberry Jams", "cat": "crafted",
		"desc": "Tyttebærsyltetøy. Humans put it on everything."},
	"cloudberry_cream": {"name": "Cloudberry Cream", "plural": "Cloudberry Creams", "cat": "crafted",
		"desc": "Multekrem. Whipped cream and cloudberries. Pure joy in a bowl."},
	"mushroom_soup": {"name": "Mushroom Soup", "plural": "Mushroom Soups", "cat": "crafted",
		"desc": "A warm bowl of chanterelle soup. Only a little bit of moss in it."},
	"heather_tea": {"name": "Heather Tea", "plural": "Heather Teas", "cat": "crafted",
		"desc": "A soothing purple tea. Good for nerves. Humans have many nerves."},
	"bouquet": {"name": "Bouquet", "plural": "Bouquets", "cat": "crafted",
		"desc": "Flowers and heather, tied with a bit of grass. Very sweet."},
	"moss_pillow": {"name": "Moss Pillow", "plural": "Moss Pillows", "cat": "crafted",
		"desc": "The comfiest thing in the whole mountain."},
	"wood_carving": {"name": "Troll Carving", "plural": "Troll Carvings", "cat": "crafted",
		"desc": "A little wooden troll with a big smile. It looks a bit like you!"},
	# --- Gifts from humans ------------------------------------------------
	"waffle": {"name": "Heart Waffle", "plural": "Heart Waffles", "cat": "treat",
		"desc": "A heart-shaped Norwegian waffle. Still warm."},
	"brown_cheese": {"name": "Brown Cheese", "plural": "Brown Cheeses", "cat": "treat",
		"desc": "Brunost. Sweet, caramelly, and very Norwegian."},
	"cinnamon_bun": {"name": "Cinnamon Bun", "plural": "Cinnamon Buns", "cat": "treat",
		"desc": "A skillingsbolle from Ingrid's bakery."},
	"wool_yarn": {"name": "Wool Yarn", "plural": "Wool Yarn", "cat": "treat",
		"desc": "Soft yarn from Lars' sheep. Granny would knit wonders with this."},
	"dried_fish": {"name": "Dried Cod", "plural": "Dried Cod", "cat": "treat",
		"desc": "Tørrfisk from Ole's racks. Chewy. Very chewy."},
	# --- Quest items -------------------------------------------------------
	"kite": {"name": "Astrid's Kite", "plural": "Astrid's Kite", "cat": "quest",
		"desc": "A red, yellow and blue kite. Someone must be missing this."},
	"lucky_hat": {"name": "Ole's Lucky Hat", "plural": "Ole's Lucky Hat", "cat": "quest",
		"desc": "A yellow sou'wester that smells like the sea."},
	"goat_bell": {"name": "Goat Bell", "plural": "Goat Bells", "cat": "quest",
		"desc": "A little brass bell. Ding!"},
}

## Recipes cooked at the cauldron in your hollow.
const RECIPES := {
	"blueberry_jam": {"needs": {"blueberry": 3}},
	"lingonberry_jam": {"needs": {"lingonberry": 3}},
	"moss_pillow": {"needs": {"moss": 3}},
	"cloudberry_cream": {"needs": {"cloudberry": 2}},
	"bouquet": {"needs": {"wildflower": 2, "heather": 1}},
	"heather_tea": {"needs": {"heather": 2}},
	"mushroom_soup": {"needs": {"chanterelle": 2}},
	"wood_carving": {"needs": {"driftwood": 2}},
}

const RECIPE_ORDER := [
	"blueberry_jam", "lingonberry_jam", "moss_pillow", "cloudberry_cream",
	"bouquet", "heather_tea", "mushroom_soup", "wood_carving",
]


static func name_of(id: String) -> String:
	return ITEMS.get(id, {}).get("name", id)


static func plural_of(id: String) -> String:
	return ITEMS.get(id, {}).get("plural", name_of(id))


static func count_name(id: String, n: int) -> String:
	if n == 1:
		return "1 " + name_of(id)
	return "%d %s" % [n, plural_of(id)]


static func desc_of(id: String) -> String:
	return ITEMS.get(id, {}).get("desc", "")


static func category(id: String) -> String:
	return ITEMS.get(id, {}).get("cat", "misc")


static func is_giftable(id: String) -> bool:
	return category(id) != "quest"
