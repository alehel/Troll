class_name NpcDB
extends RefCounted
## Characters of Trollfjell and the village of Lillevik.
## Human "schedule" entries are [start_hour, anchor, wander_radius]; the anchor
## "home" means the character is indoors.

const NPCS := {
	# ======================================================================
	# TROLLS
	# ======================================================================
	"granny": {
		"name": "Granny Ur", "kind": "troll", "title": "The oldest troll on the mountain",
		"voice": 0.7,
		"look": {"skin": Color(0.55, 0.52, 0.48), "size": 1.05, "nose": 1.25, "hair": Color(0.88, 0.88, 0.9),
			"hair_style": "bun", "belly": Color(0.62, 0.6, 0.55), "shawl": Color(0.55, 0.3, 0.45), "glasses": true},
		"schedule": [[6.0, "granny_yard", 2.5], [10.5, "ring", 3.0], [14.0, "granny_yard", 2.5]],
		"loves": ["wool_yarn", "blueberry_jam", "brown_cheese"],
		"likes": ["moss", "blueberry", "heather_tea", "cinnamon_bun", "waffle", "moss_pillow"],
		"dislikes": ["pinecone"],
		"greet": ["Ah, my little moss-sprout!", "There you are, {name}. Mind the bogs.",
			"Hmm? Oh, it's you. I thought you were a boulder that learned to walk."],
		"chat": [
			"When I was young, this whole valley was ice. Very cold. Very quiet. Terrible for knitting.",
			"Humans are like mushrooms, dear. They pop up everywhere and nobody knows how.",
			"Kindness is like moss. It grows slowly, but one day it covers everything.",
			"Tussa has been asking about the humans again. That child is braver than a bear in a bee's nest.",
			"My knees tell me there will be northern lights tonight. Or rain. My knees are not very specific.",
			"Did you remember to eat your moss? A troll without moss is just a grumpy rock.",
			"The old tales say trolls turn to stone in sunlight. Pfft. I've had many sunbaths. Still soft as a pillow.",
			"If a human runs away from you, don't chase them. Nobody likes being chased. Except goats. Goats love it.",
		],
		"chat_high": ["You've grown so much, {name}. Still clumsy, but in a dignified way.",
			"I'm proud of you. Don't tell Stein I said anything nice. He'll get jealous."],
		"gift": {
			"love": ["Oh! Oh my! You remembered! Come here, let me pinch your nose.", "This is the loveliest thing. I shall knit you a sock. Maybe even two."],
			"like": ["How thoughtful. Thank you, dear.", "Now that's a proper present."],
			"neutral": ["Well! I'll find a use for it. I always do.", "Thank you, sprout."],
			"dislike": ["Hm. I shall... put it somewhere. Somewhere far away."],
		},
	},
	"stein": {
		"name": "Stein", "kind": "troll", "title": "Rock collector. Very strong. Very gentle.",
		"voice": 0.55,
		"look": {"skin": Color(0.5, 0.53, 0.56), "size": 1.3, "nose": 0.9, "hair": Color(0.42, 0.58, 0.28),
			"hair_style": "tree", "belly": Color(0.58, 0.6, 0.62)},
		"schedule": [[6.0, "stein_rocks", 3.0]],
		"loves": ["crystal", "pretty_stone"],
		"likes": ["dried_fish", "driftwood", "brown_cheese", "mushroom_soup"],
		"dislikes": ["wildflower", "bouquet", "heather"],
		"greet": ["Hrm. {name}.", "Rock solid day, eh?", "You again. Good."],
		"chat": [
			"This rock is my favourite. No. THIS rock is my favourite.",
			"Some trolls collect stamps. Stamps are flat. Rocks have... depth.",
			"I once sat still for eleven years. Birds built a nest on my head. Nice birds.",
			"Humans stack stones too. Walls. Houses. Hrm. Maybe they're not so bad.",
			"Granny says I should 'express my feelings'. I expressed one. It was a pebble.",
			"You want to be strong? Lift with your knees. And your heart. Mostly knees.",
		],
		"chat_high": ["You are a good troll, {name}. Solid. Like granite.", "I made you a cairn. It's over there. It says 'friend' in rock."],
		"gift": {
			"love": ["...Is this for me? *sniff* It's beautiful. Don't look at me.", "Oh. OH. A proper stone. I shall name it... Stone."],
			"like": ["Good. Useful. Thank you.", "Hrm! Not bad."],
			"neutral": ["It is not a rock. But thank you.", "Hrm. Okay."],
			"dislike": ["Flowers? What do I do with flowers. They are just... soft rocks that die."],
		},
	},
	"tussa": {
		"name": "Tussa", "kind": "troll", "title": "Granny's grandchild. Full of questions.",
		"voice": 1.45,
		"look": {"skin": Color(0.66, 0.56, 0.44), "size": 0.62, "nose": 1.0, "hair": Color(0.9, 0.5, 0.2),
			"hair_style": "tuft", "belly": Color(0.74, 0.64, 0.5), "scarf": Color(0.3, 0.55, 0.8)},
		"schedule": [[7.0, "lake_shore", 5.0], [11.0, "ring", 6.0], [15.0, "lake_shore", 5.0], [19.0, "granny_yard", 3.0]],
		"loves": ["waffle", "cinnamon_bun", "cloudberry_cream"],
		"likes": ["feather", "pinecone", "blueberry", "pretty_stone", "cloudberry"],
		"dislikes": ["mushroom_soup", "heather_tea"],
		"greet": ["{name}! {name}! Guess what! No, guess!", "Heehee! Did you see me? I was hiding. Very well.", "Hi hi hi!"],
		"chat": [
			"Is it true humans have only ONE nose each? That seems so wasteful!",
			"I tried to eat a pinecone. Would not recommend. Would do again.",
			"When I grow up I want to be a mountain. Or a baker. Maybe both!",
			"Granny says the humans are scared of us. But why? I'm adorable!",
			"Can you teach me to lift boulders? I lifted a snail yesterday. It was a big snail.",
			"Do humans have tails? Stein says they keep them in their trousers.",
		],
		"chat_high": ["You're my favourite big troll! Don't tell Stein. Actually, tell him. He'll laugh. Maybe.",
			"When I'm big I'm going to help humans just like you!"],
		"gift": {
			"love": ["WAAAH! For ME? You're the best troll in the whole wide world!", "Yummy yummy yummy! Can I have another one tomorrow?"],
			"like": ["Ooh! Thank you!", "Neat! I'm going to show everyone!"],
			"neutral": ["Hmm! Okay! Thanks!"],
			"dislike": ["Bleh! ...I mean, thank you. Bleh."],
		},
	},
	"lyng": {
		"name": "Lyng", "kind": "troll", "title": "Gardener of the plateau",
		"voice": 1.1,
		"look": {"skin": Color(0.5, 0.56, 0.44), "size": 0.95, "nose": 0.85, "hair": Color(0.62, 0.42, 0.66),
			"hair_style": "flowers", "belly": Color(0.6, 0.66, 0.52), "shawl": Color(0.85, 0.75, 0.45)},
		"schedule": [[6.0, "lyng_garden", 3.5]],
		"loves": ["wildflower", "heather", "chanterelle", "bouquet"],
		"likes": ["moss", "cloudberry", "pinecone", "heather_tea"],
		"dislikes": ["dried_fish"],
		"greet": ["Oh, hello, {name}. The chanterelles said you'd come.", "Welcome, welcome. Mind the snails, they're napping.",
			"Good day. Have you smelled the heather today? You should."],
		"chat": [
			"Every mushroom is a little umbrella for someone smaller.",
			"I talk to my flowers every morning. They mostly listen. The tulips are rude.",
			"Heather tea is good for nerves. I hear humans have a great many nerves.",
			"The bog is full of cloudberries this time of year. Golden, like tiny suns.",
			"If you want to make a human smile, give them something that grew. Growing things are honest.",
		],
		"chat_high": ["You have soil under your nails and kindness in your heart. That's all a gardener needs.",
			"I planted a flower and named it after you. It's very tall and a bit lopsided."],
		"gift": {
			"love": ["Oh, how lovely. It smells like the whole mountain.", "You have a gardener's heart, {name}. Thank you."],
			"like": ["That's very sweet of you.", "Thank you. I'll find it a nice spot."],
			"neutral": ["Thank you, dear. Everything has its place."],
			"dislike": ["Oh... I'll... compost it. Lovingly."],
		},
	},
	"gubben": {
		"name": "Gubben Grå", "kind": "troll", "title": "Guardian of the old stone bridge",
		"voice": 0.62,
		"look": {"skin": Color(0.48, 0.5, 0.46), "size": 1.1, "nose": 1.5, "hair": Color(0.75, 0.76, 0.74),
			"hair_style": "beard", "belly": Color(0.56, 0.58, 0.54)},
		"schedule": [[0.0, "under_bridge", 0.6]],
		"loves": ["moss_pillow", "dried_fish", "brown_cheese"],
		"likes": ["driftwood", "heather_tea", "waffle", "mushroom_soup", "moss"],
		"dislikes": ["crystal"],
		"greet": ["WHO'S THAT TRIP-TRAPPING... oh. It's you. Hello, {name}.",
			"Zzz... hm? Oh! I was guarding the bridge. With my eyes closed. For stealth.",
			"Ah, a visitor! Nobody visits a bridge troll. Nobody."],
		"chat": [
			"My great-great-grandfather had a disagreement with some goats. Three of them. Gruff fellows. Humans still tell stories about it.",
			"The old tales! Trolls who eat children! Trolls who steal princesses! Pah. We mostly eat moss. And porridge on Sundays.",
			"Why are the humans scared? Long ago, some trolls were... not polite. Stories last longer than trolls do.",
			"I've guarded this bridge for 300 years. Nobody has ever tried to steal it. I'm very good at my job.",
			"A pillow! That's what this bridge needs. A nice soft moss pillow.",
			"Did you know the humans think trolls burst in sunlight? I burst once. It was a sneeze.",
		],
		"chat_high": ["You come by so often now. My bridge has never felt so popular.",
			"I told the fish about you. They were very impressed. Fish are hard to impress."],
		"gift": {
			"love": ["For me? For old Grå? Oh... I haven't had a present since the Middle Ages.", "Ohhh, marvellous. My back thanks you. My front also thanks you."],
			"like": ["How kind. Very kind. Zzz... sorry. Very kind!", "Hm! Splendid."],
			"neutral": ["Hmm. I shall guard it. Along with the bridge."],
			"dislike": ["What is this? Is it a trap? It feels like a trap."],
		},
	},
	# ======================================================================
	# HUMANS
	# ======================================================================
	"ingrid": {
		"name": "Ingrid", "kind": "human", "title": "The village baker", "house": "bakery",
		"voice": 1.3,
		"look": {"skin": Color(0.96, 0.8, 0.68), "hair": Color(0.85, 0.62, 0.3), "hair_style": "bun",
			"hat": "scarf", "hat_color": Color(0.85, 0.35, 0.35), "top": Color(0.95, 0.9, 0.8), "bottom": Color(0.45, 0.3, 0.5),
			"apron": Color(0.98, 0.97, 0.94), "height": 1.0},
		"schedule": [[6.5, "bakery_stand", 1.5], [12.0, "square", 6.0], [14.0, "bakery_stand", 1.5], [19.0, "home", 0.0]],
		"loves": ["cloudberry", "cloudberry_cream", "blueberry_jam"],
		"likes": ["blueberry", "lingonberry", "lingonberry_jam", "wildflower", "bouquet", "heather_tea"],
		"dislikes": ["moss", "pinecone", "pretty_stone"],
		"flee": ["AAAH! A TROLL! Not in my bakery!", "Eeek! My buns! Save the buns!", "HELP! It's HUGE!", "Troll! TROLL! Somebody fetch a broom!"],
		"scared": ["P-please... I'm very stringy! Not tasty!", "Stay back! I've got... a whisk!", "N-nice troll... good troll..."],
		"stage_lines": {
			2: ["You're the one who's been leaving jam, aren't you? It was... actually very good jam.",
				"I'm not scared. I'm just holding this rolling pin for... baking reasons.",
				"Hello, troll. Please don't sit on anything. Things break."],
			3: ["What do trolls eat, anyway? Is it true you eat... moss? Just moss?",
				"I tried cloudberry buns this morning. They'd be better with real bog cloudberries.",
				"My grandmother said trolls steal bread. You don't steal bread, do you? ...Want some?"],
			4: ["Morning, {name}! The ovens are warm if you want to stand near them.",
				"You know, the village has been happier since you started helping.",
				"Here's a secret: the trick to good waffles is a pinch of cardamom. Don't tell Solveig."],
			5: ["{name}! My favourite customer. Well, you've never bought anything. But still!",
				"I saved you a waffle. It's heart-shaped. Because... you know. Heart."],
		},
		"treat": "waffle",
		"gift": {
			"love": ["Cloudberries! Real bog cloudberries! Oh, you wonderful creature!", "This is perfect! I could bake a whole cake around this!"],
			"like": ["Oh! That's very kind of you.", "Thank you! I'll put it to good use."],
			"neutral": ["Oh. Thank you, I suppose.", "How... thoughtful."],
			"dislike": ["Is this... for eating? Oh dear."],
		},
		"doorstep": {
			"love": "\"Who could have left such a treasure?\" Ingrid asks every customer about the {item} left at the bakery.",
			"like": "Ingrid found {item} by her door. \"A secret admirer?\" she giggled.",
			"neutral": "Ingrid found {item} on her doorstep. She is puzzled, but not unhappy.",
			"dislike": "Ingrid found {item} on her doorstep. She poked it with a broom.",
		},
	},
	"ole": {
		"name": "Ole", "kind": "human", "title": "Old fisherman. Knows every troll story.", "house": "ole",
		"voice": 0.85, "trust_mult": 0.8,
		"look": {"skin": Color(0.9, 0.72, 0.6), "hair": Color(0.85, 0.85, 0.85), "hair_style": "bald", "beard": true,
			"hat": "souwester", "hat_color": Color(0.95, 0.8, 0.2), "top": Color(0.2, 0.3, 0.45), "bottom": Color(0.3, 0.3, 0.32),
			"height": 0.97},
		"schedule": [[6.0, "dock", 1.5], [11.0, "net_rack", 1.5], [15.0, "dock_end", 1.0], [18.0, "net_rack", 1.5], [20.0, "home", 0.0]],
		"loves": ["heather_tea", "wood_carving", "driftwood"],
		"likes": ["mushroom_soup", "lingonberry_jam", "feather", "pretty_stone"],
		"dislikes": ["wildflower", "bouquet", "heather"],
		"flee": ["TROLL! I knew it! I told them!", "Back! Back, you beast! I've got a... net!", "Hide the fish! Hide the children! Hide ME!",
			"Seventy years at sea and THIS is how I go?!"],
		"scared": ["Don't come closer. I bite. ...I have three teeth, but I bite.", "I know your tricks, troll. I've read the stories.", "Hmph! Stay where I can see you."],
		"stage_lines": {
			2: ["Hmph. You again. The one who cleans up. Don't think that makes us friends.",
				"The stories say trolls burst in the sunlight. You're not bursting. Suspicious.",
				"Someone tidied my nets last night. I'm not saying it was you. I'm not saying it wasn't."],
			3: ["My father swore he saw a troll eat a whole goat. Maybe it was a very big troll. Or a very small goat.",
				"The fjord's calm today. Good day for sitting and thinking. And not being eaten.",
				"Ever been on a boat, troll? No? The boat would sink. Ha!"],
			4: ["{name}! Come, stand. Well, don't stand ON the dock. Stand near the dock.",
				"I've been telling the young ones a new story. About a troll who picks up litter. They don't believe me.",
				"Have a look at the fjord with me. Best view in Norway."],
			5: ["I was wrong about you, {name}. Seventy-three years old and still learning. Don't tell anyone.",
				"If anyone says a bad word about trolls now, they answer to me. And my net."],
		},
		"treat": "dried_fish",
		"gift": {
			"love": ["Heh! Now THIS is a proper gift. You've got taste, troll.", "Well, I'll be... Thank you. Truly."],
			"like": ["Hmph. Not bad. Not bad at all.", "Thank you. I suppose."],
			"neutral": ["What am I supposed to do with this?", "Hmph. Thanks."],
			"dislike": ["Flowers? For me? Do I look like a flower sort of man?"],
		},
		"doorstep": {
			"love": "Ole claims he \"doesn't care\" about the {item} left at his door. He has shown it to everyone. Twice.",
			"like": "Ole found {item} on his step. \"Probably a trick,\" he muttered, and kept it.",
			"neutral": "Ole found {item} on his step and grumbled about it all morning.",
			"dislike": "Ole found {item} on his doorstep and threw it in the fjord. Then he fished it out again.",
		},
	},
	"astrid": {
		"name": "Astrid", "kind": "human", "title": "Eight years old. Fearless. Mostly.", "house": "astrid",
		"voice": 1.6, "trust_mult": 1.4,
		"look": {"skin": Color(0.97, 0.82, 0.72), "hair": Color(0.95, 0.85, 0.5), "hair_style": "braids",
			"hat": "beanie", "hat_color": Color(0.85, 0.25, 0.3), "top": Color(0.35, 0.55, 0.8), "bottom": Color(0.3, 0.3, 0.45),
			"height": 0.72},
		"schedule": [[8.0, "square", 7.0], [11.0, "beach", 5.0], [14.0, "square", 8.0], [17.0, "beach", 4.0], [19.0, "home", 0.0]],
		"loves": ["pretty_stone", "crystal", "feather"],
		"likes": ["wildflower", "bouquet", "blueberry", "pinecone", "wood_carving", "cloudberry", "kite"],
		"dislikes": ["mushroom_soup", "chanterelle"],
		"flee": ["MAMMA! A REAL TROLL!", "Eeeeeek!", "It's a troll! A real, real troll!"],
		"scared": ["Are you... are you going to eat me?", "I'm not scared! ...I'm a little scared.", "My papa says trolls eat kids who don't eat their fish."],
		"stage_lines": {
			2: ["Are you a real troll? Can I touch your nose? ...No? Okay.",
				"I saw you pick up the rubbish! Trolls aren't supposed to do that!",
				"Do you live in a cave? Is it cozy? Does it have a bed?"],
			3: ["Do trolls have birthday parties? Do they last a whole month?",
				"I collect pretty stones. Do trolls collect things?",
				"Grown-ups are silly. You're obviously nice. You have a scarf!"],
			4: ["{name}! {name}! Watch me do a cartwheel! ...That wasn't a very good one.",
				"When I grow up, I'm going to be a troll scientist.",
				"Everyone's being nicer about trolls now. I told them all about you!"],
			5: ["You're my best friend. Well, you and Tussa. You're my best friends!",
				"I drew a picture of you. I gave you a crown because you're the king of kindness."],
		},
		"treat": "cinnamon_bun",
		"gift": {
			"love": ["WOW! Is this for me? It's the most beautiful thing ever!", "I'm going to keep this forever and ever!"],
			"like": ["Thank you, troll!", "Ooh, neat!"],
			"neutral": ["Um. Thanks!"],
			"dislike": ["Eww! ...I mean, thank you. Eww."],
		},
		"doorstep": {
			"love": "Astrid found {item} at her door and hasn't stopped smiling. She insists \"the troll did it\". Nobody believes her.",
			"like": "Astrid found {item} on her doorstep and carried it to school.",
			"neutral": "Astrid found {item} on the doorstep and put it in her secret box.",
			"dislike": "Astrid found {item} on her doorstep. She offered it to the cat. The cat declined.",
		},
	},
	"lars": {
		"name": "Lars", "kind": "human", "title": "Goat farmer. Easily startled.", "house": "farm",
		"voice": 1.0,
		"look": {"skin": Color(0.92, 0.74, 0.62), "hair": Color(0.45, 0.3, 0.2), "hair_style": "short", "beard": true,
			"hat": "cap", "hat_color": Color(0.3, 0.45, 0.3), "top": Color(0.75, 0.25, 0.2), "bottom": Color(0.3, 0.4, 0.6),
			"height": 1.05},
		"schedule": [[6.5, "farm_pen", 4.0], [12.0, "farm_yard", 3.0], [13.0, "farm_pen", 4.0], [19.0, "home", 0.0]],
		"loves": ["mushroom_soup", "chanterelle", "lingonberry_jam"],
		"likes": ["blueberry", "lingonberry", "driftwood", "heather_tea", "cloudberry"],
		"dislikes": ["crystal", "pinecone"],
		"flee": ["Uff da! TROLL! Run, goats, run!", "Not my goats! You can't have my goats!", "AAH! Troll in the field! Troll in the field!"],
		"scared": ["The goats are not for eating! They're for... milk. And cuddles.", "I've got a pitchfork! Somewhere! In the barn!",
			"S-stay on that side of the fence, please."],
		"stage_lines": {
			2: ["You're not here for the goats, are you? Promise?",
				"Someone tidied up the farm road last night... Was that you?",
				"The goats seem to like you. Goats are good judges of character. Mostly."],
			3: ["Did you know goats can climb trees? It's true. Terrible habit.",
				"The chanterelles are good this year. A chanterelle soup, now that's a meal.",
				"Hard work, farming. You look like you could lift a cow. Could you lift a cow?"],
			4: ["{name}! Morning! The goats were asking about you. Well, bleating. Same thing.",
				"Farming's easier with a friend nearby. And you're a very big friend.",
				"Here, give Geita a scratch behind the ears. She likes that."],
			5: ["You're always welcome at this farm, {name}. The goats insist.",
				"My grandfather would faint if he saw me chatting with a troll. Good. He was a grump."],
		},
		"treat": "wool_yarn",
		"gift": {
			"love": ["Oh! My favourite! How did you know?", "This is wonderful. Thank you, friend!"],
			"like": ["Thank you kindly!", "Now that's nice."],
			"neutral": ["Oh. Thanks, I think."],
			"dislike": ["Hm. The goats might eat it. The goats eat everything."],
		},
		"doorstep": {
			"love": "Lars found {item} by his door. \"The goats didn't do this,\" he said. \"I checked.\"",
			"like": "Lars found {item} at his door and shared it with his goats.",
			"neutral": "Lars found {item} on his step. The goats seem suspicious.",
			"dislike": "Lars found {item} on his doorstep. The goats ate it.",
		},
	},
	"solveig": {
		"name": "Solveig", "kind": "human", "title": "Shopkeeper, postmistress, news reporter", "house": "store",
		"voice": 1.2,
		"look": {"skin": Color(0.95, 0.78, 0.66), "hair": Color(0.3, 0.2, 0.15), "hair_style": "long", "glasses": true,
			"hat": "none", "top": Color(0.55, 0.3, 0.55), "bottom": Color(0.25, 0.25, 0.3), "height": 0.98},
		"schedule": [[8.0, "store_bench", 2.0], [13.0, "square", 6.0], [15.0, "store_bench", 2.0], [19.5, "home", 0.0]],
		"loves": ["bouquet", "wildflower", "heather"],
		"likes": ["blueberry_jam", "lingonberry_jam", "heather_tea", "feather", "crystal", "cloudberry_cream"],
		"dislikes": ["pinecone", "moss", "driftwood"],
		"flee": ["Oh my STARS! It's enormous!", "Close the shop! CLOSE THE SHOP!", "Troll! Somebody call the mayor! Somebody call EVERYONE!"],
		"scared": ["I have a very loud voice. I'll scream. I'll really scream!", "Please don't break anything. Everything in here is for sale.",
			"Oh dear, oh dear, oh dear..."],
		"stage_lines": {
			2: ["So YOU'RE the mystery helper! Oh, wait until I tell everyone! ...Can I tell everyone?",
				"Word travels fast in Lillevik. Mostly because I carry it.",
				"I suppose you don't need anything from the shop. Trolls don't use money, do you?"],
			3: ["Have you heard? Margit might call a village meeting. About YOU!",
				"I've been reading everything about trolls. Most of the books are terrible. Very rude.",
				"The road to the city has been blocked for weeks. No deliveries, no post. It's a disaster!"],
			4: ["{name}, darling! You look lovely today. Is that new moss?",
				"I told the whole village you're a gentleman troll. They believed me, eventually.",
				"If you ever want to send a letter, I'll post it for free. Troll discount."],
			5: ["You know what, {name}? You're the best thing that's happened to Lillevik in years.",
				"I've started a fan club. It's me. I'm the fan club. We have badges."],
		},
		"treat": "brown_cheese",
		"gift": {
			"love": ["For ME? Oh, you shouldn't have! Well, you should have. I'm glad you did!", "Oh, this is gorgeous! Everyone will be SO jealous."],
			"like": ["How delightful!", "Oh, thank you, dear!"],
			"neutral": ["Oh. Well. Thank you!", "I'll put it in the window. Maybe."],
			"dislike": ["Oh. How... rustic."],
		},
		"doorstep": {
			"love": "Solveig found {item} on her doorstep and told the entire village by breakfast.",
			"like": "Solveig found {item} by her door. \"A gift from the mysterious helper!\" she announced.",
			"neutral": "Solveig found {item} on her step. She is investigating.",
			"dislike": "Solveig found {item} on her doorstep. She has filed a complaint. With herself.",
		},
	},
	"margit": {
		"name": "Mayor Margit", "kind": "human", "title": "Mayor of Lillevik", "house": "mayor",
		"voice": 0.95,
		"look": {"skin": Color(0.93, 0.76, 0.64), "hair": Color(0.6, 0.6, 0.62), "hair_style": "bun", "glasses": true,
			"hat": "none", "top": Color(0.7, 0.12, 0.15), "bottom": Color(0.12, 0.14, 0.2), "apron": Color(0.12, 0.2, 0.45),
			"height": 1.0},
		"schedule": [[8.0, "notice_board", 1.5], [10.0, "square", 7.0], [13.0, "chapel_yard", 3.0], [16.0, "square", 6.0], [19.0, "home", 0.0]],
		"loves": ["wood_carving", "cloudberry_cream", "bouquet"],
		"likes": ["crystal", "heather_tea", "blueberry_jam", "lingonberry_jam", "cloudberry"],
		"dislikes": ["driftwood", "moss", "pinecone"],
		"flee": ["Everyone stay calm! I'M NOT CALM!", "Troll alert! This is not a drill!", "I shall write a strongly worded letter! From inside my house!"],
		"scared": ["As mayor, I must ask you to... to... please go away?", "There are rules about trolls. I'm sure there are. Somewhere.",
			"I'm very important. I'd taste terrible. Full of paperwork."],
		"stage_lines": {
			2: ["I have received reports of a troll... tidying. This is highly irregular.",
				"The village is divided about you. Half are terrified. The other half is Astrid.",
				"Please keep to the paths. And don't frighten anyone. More than you have to."],
			3: ["The archives say the last troll incident was in 1743. A goat went missing. It was found later. In a tree.",
				"I'll be honest with you, troll. I'm starting to think we've been unfair.",
				"If the village agrees, perhaps... well. Let's not rush things."],
			4: ["{name}. The village council has discussed you. Mostly nice things.",
				"I've amended the village rules. 'Trolls must be greeted politely.' It passed unanimously.",
				"The Harvest Festival is our biggest celebration of the year. Lanterns, music, a great bonfire."],
			5: ["As mayor of Lillevik, I declare you an honorary villager. As Margit, I say: thank you, friend.",
				"You've changed this village, {name}. For the better."],
		},
		"treat": "brown_cheese",
		"gift": {
			"love": ["Oh my. This is exquisite. It shall have a place of honour in the town hall.", "How... how did you know? This is perfect."],
			"like": ["Very kind of you. Thank you.", "The village thanks you. And so do I."],
			"neutral": ["Noted. Thank you.", "I shall file this under 'gifts'."],
			"dislike": ["I have plenty of these. It's called the beach."],
		},
		"doorstep": {
			"love": "Mayor Margit found {item} on her doorstep. \"Remarkable,\" she said, and blushed.",
			"like": "Mayor Margit found {item} at her door and has called it \"a hopeful sign\".",
			"neutral": "Mayor Margit found {item} at her door. She wrote it down in a very serious notebook.",
			"dislike": "Mayor Margit found {item} on her doorstep. She has formed a committee to investigate.",
		},
	},
}

## What the troll mumbles after a human runs away screaming.
const PUZZLED := [
	"Hm? Did I forget to brush my tusks?",
	"Was it something I said? I didn't say anything...",
	"Maybe they're late for something.",
	"Humans are so fast! Where are they all going?",
	"Oh! Maybe they're playing hide and seek.",
	"Do I have moss on my nose? I always have moss on my nose.",
	"I just wanted to say hello...",
	"Strange. I smiled my nicest smile.",
]


static func get_npc(id: String) -> Dictionary:
	return NPCS.get(id, {})


static func name_of(id: String) -> String:
	return NPCS.get(id, {}).get("name", id)


static func is_human(id: String) -> bool:
	return NPCS.get(id, {}).get("kind", "") == "human"


static func humans() -> Array:
	var out: Array = []
	for id in NPCS.keys():
		if NPCS[id]["kind"] == "human":
			out.append(id)
	return out


static func trolls() -> Array:
	var out: Array = []
	for id in NPCS.keys():
		if NPCS[id]["kind"] == "troll":
			out.append(id)
	return out


static func trust_multiplier(id: String) -> float:
	return float(NPCS.get(id, {}).get("trust_mult", 1.0))


static func preference(id: String, item: String) -> String:
	var n: Dictionary = NPCS.get(id, {})
	if n.get("loves", []).has(item):
		return "love"
	if n.get("likes", []).has(item):
		return "like"
	if n.get("dislikes", []).has(item):
		return "dislike"
	return "neutral"


static func pick(arr: Array) -> String:
	if arr.is_empty():
		return "..."
	return arr[randi() % arr.size()]
