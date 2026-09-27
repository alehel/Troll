class_name QuestDB
extends RefCounted
## Story and side tasks.
##
## Step kinds:
##   goal     – completes by itself when the condition is met
##   talk     – completes when talking to that NPC (plays "lines")
##   turn_in  – {npc, take:{item:n}} completes when talking to the NPC while
##              carrying the items (plays "lines"; otherwise plays "remind")
## Line prefixes: "> " is spoken by the player troll, "* " is narration,
## "@id: " makes another character speak. Everything else is the NPC.
## "allow_scared" lets the step happen even while that human is still afraid.

const ORDER := [
	"m1_wake", "m2_hello", "m3_secret", "m4_strength", "m5_kite", "m6_goat", "m7_meeting", "m8_festival",
	"s_lyng", "s_tussa", "s_cloudberry", "s_gubben", "s_ingrid", "s_ole_hat",
]

const QUESTS := {
	# ======================================================================
	# MAIN STORY
	# ======================================================================
	"m1_wake": {
		"title": "A Troll Wakes", "main": true, "giver": "granny",
		"desc": "A new day on Trollfjell. Granny Ur wants to see you.",
		"auto": {"day": 1},
		"steps": [
			{"text": "Visit Granny Ur at her turf hut (east of your hollow).", "talk": "granny", "lines": [
				"There's my little moss-sprout! Awake before noon! Will wonders never cease.",
				"> Good morning, Granny Ur!",
				"Listen, dear. My porridge is sad. Porridge without blueberries is just... wet sadness.",
				"Would you pick me 3 Blueberries? The bushes grow all over the plateau. Look for the blue dots.",
			]},
			{"text": "Pick 3 Blueberries from the bushes on the plateau.", "where": "spot:bush_blue", "goal": {"have": {"blueberry": 3}}},
			{"text": "Bring 3 Blueberries to Granny Ur.", "turn_in": {"npc": "granny", "take": {"blueberry": 3}}, "lines": [
				"Ooh, plump ones! You have good eyes for a troll with such a big nose.",
				"Now, let me teach you something every troll should know: jam.",
				"* Granny Ur taught you how to make Blueberry Jam, Lingonberry Jam and Moss Pillows!",
				"Cook it at the cauldron in your hollow. 3 berries in, 1 jar out. Magic! Well, cooking.",
			], "remind": ["3 Blueberries, dear. The blue ones. Not the rocks. Stein, stop giving the child rocks."],
				"on_done": [{"recipe": "blueberry_jam"}, {"recipe": "lingonberry_jam"}, {"recipe": "moss_pillow"}]},
			{"text": "Cook a Blueberry Jam at the cauldron in your hollow.", "where": "anchor:cauldron", "goal": {"flag": "crafted_blueberry_jam"}},
			{"text": "Show your jam to Granny Ur.", "talk": "granny", "lines": [
				"Look at that! A proper jar of jam. I'm so proud I could crumble.",
				"You know... you've always wanted to visit the humans in the village down by the fjord.",
				"Humans LOVE jam. Take it down to Lillevik and say hello. Be polite. Don't step on anyone.",
				"> I'll be the politest troll they've ever seen!",
				"Follow the trail down the cliff and through the forest. The village is by the water.",
			]},
		],
		"on_complete": [{"start": "m2_hello"}],
	},
	"m2_hello": {
		"title": "Hello, Humans!", "main": true, "giver": "granny",
		"desc": "Go down to the village and make some new friends.",
		"steps": [
			{"text": "Follow the trail down to Lillevik and say hello to a human.", "where": "anchor:square", "goal": {"flag": "first_flee"}},
			{"text": "That... didn't go as planned. Go back and ask Granny Ur about it.", "talk": "granny", "lines": [
				"> Granny! The humans screamed and ran away! Every single one!",
				"Ah. Yes. I was afraid of that.",
				"Humans tell stories about trolls, dear. Very old, very silly stories.",
				"> What kind of stories?",
				"Oh... this and that. Nothing for a sprout like you to worry about.",
				"Humans are like deer. You can't catch their friendship by running at them.",
				"Start small. Leave a present on a doorstep, where they'll find it in the morning. Every house has a little basket by the door.",
				"And tidy up! Humans love tidiness. There's always rubbish blowing about in the village.",
				"Kindness is like moss, remember? Slow, but it covers everything.",
			]},
		],
		"on_complete": [{"start": "m3_secret"}],
	},
	"m3_secret": {
		"title": "Secret Kindness", "main": true, "giver": "granny",
		"desc": "The humans are shy. Help them in secret, and let them discover you're kind.",
		"steps": [
			{"text": "Leave a gift in a villager's doorstep basket.", "where": "gift", "goal": {"flag": "doorstep_gift"}},
			{"text": "Tidy up 3 pieces of litter in the village.", "where": "litter", "goal": {"counter": ["litter", 3]}},
			{"text": "Sleep in your moss bed and see what the village makes of it.", "where": "anchor:home_bed", "goal": {"flag": "read_paper"}},
		],
		"on_complete": [{"start": "m4_strength"}, {"village_trust": 3.0}],
	},
	"m4_strength": {
		"title": "Troll Strength", "main": true, "giver": "granny",
		"desc": "A rockslide has blocked the road out of Lillevik. Only a troll could move those boulders.",
		"steps": [
			{"text": "Ask Stein (at the standing stones, west on the plateau) to teach you the Troll Lift.", "talk": "stein", "lines": [
				"> Stein! The humans' road is blocked by a rockslide. Could you teach me to lift big boulders?",
				"Hrm. The Troll Lift. Ancient technique. Very secret. Very... lifty.",
				"First, a test of dedication. Bring me 2 Mountain Crystals.",
				"They grow by the cliffs near the waterfall. Sparkly. You'll see.",
				"> Is that really a test, or do you just want crystals?",
				"...Both. Both is good.",
			]},
			{"text": "Find 2 Mountain Crystals near the cliffs around the waterfall.", "where": "spot:crystal", "goal": {"have": {"crystal": 2}}},
			{"text": "Bring 2 Mountain Crystals to Stein.", "turn_in": {"npc": "stein", "take": {"crystal": 2}}, "lines": [
				"*sniff* They're beautiful. Okay. The Troll Lift.",
				"Bend your knees. Hug the rock. Tell it something nice. Then LIFT.",
				"> Tell it something nice?",
				"Rocks are heavy because they are sad. Nobody hugs them. Hrm.",
				"* You learned the Troll Lift! You can now move great boulders.",
			], "remind": ["2 Mountain Crystals. By the cliffs near the waterfall. Sparkly."], "on_done": [{"flag": "troll_lift"}]},
			{"text": "Clear the rockslide on the east road out of Lillevik (5 boulders).", "where": "boulders", "goal": {"counter": ["boulders", 5]}},
		],
		"on_complete": [{"village_trust": 6.0}, {"flag": "road_cleared"}],
	},
	"m5_kite": {
		"title": "A Brave Little Human", "main": true, "giver": "astrid",
		"desc": "One little girl in Lillevik doesn't seem quite as scared as the others.",
		"auto": {"all": [{"quest_done": "m3_secret"}, {"trust": ["astrid", 12.0]}]},
		"steps": [
			{"text": "Someone small is watching you from the village. Talk to Astrid.", "talk": "astrid", "allow_scared": true, "lines": [
				"H-hello? Are you... a real troll?",
				"> I am! My name is {name}. What's yours?",
				"...Astrid. I'm eight. And three quarters.",
				"Everyone says trolls are scary. But you put jam on our doorsteps.",
				"Um. Can a troll help with something? My kite flew away up the mountain. Into the forest.",
				"Nobody will go get it. Because of... um. Trolls.",
				"> Don't worry, Astrid. I'll find your kite!",
			]},
			{"text": "Find Astrid's kite. It got stuck in a tall tree in the forest west of the trail.", "where": "kite", "goal": {"have": {"kite": 1}}},
			{"text": "Return the kite to Astrid.", "turn_in": {"npc": "astrid", "take": {"kite": 1}}, "allow_scared": true, "lines": [
				"MY KITE! You found it! You really found it!",
				"Papa says trolls eat children. Do you eat children?",
				"> Eat... children? No! Why would anybody eat a child? I eat moss! And porridge on Sundays!",
				"Hehe! I KNEW it! I'm going to tell EVERYONE!",
				"* Astrid runs off, kite flapping behind her, shouting \"THE TROLL IS NICE!\" at everyone she sees.",
				"> ...People think trolls eat children? How strange humans are.",
			], "remind": ["Did you find my kite? It's red and yellow and blue. It went into the forest, near the trail."],
				"on_done": [{"trust": ["astrid", 20.0]}, {"village_trust": 3.0}]},
		],
		"on_complete": [{"flag": "astrid_friend"}],
	},
	"m6_goat": {
		"title": "The Lost Goat", "main": true, "giver": "lars",
		"desc": "Lars' best goat, Bukken, has gone missing. The villagers suspect a certain troll...",
		"auto": {"all": [{"quest_done": "m5_kite"}, {"quest_done": "m4_strength"}]},
		"steps": [
			{"text": "Astrid has news. Talk to her in the village.", "talk": "astrid", "allow_scared": true, "lines": [
				"{name}! Something terrible happened! Lars' goat Bukken is missing!",
				"And... and everyone thinks a troll ate him.",
				"> What? I would never! Goats are friends, not food!",
				"I know! But grown-ups don't listen. If you found Bukken, they'd HAVE to believe you!",
				"> Hmm. Who sees everything that goes up and down this valley...? Gubben Grå! The troll under the old stone bridge!",
			]},
			{"text": "Ask Gubben Grå under the old stone bridge in the forest if he's seen a goat.", "talk": "gubben", "lines": [
				"A goat? Oh, I've seen a goat. TRIP-TRAP, TRIP-TRAP, right over my bridge!",
				"So I said, in my most terrifying voice: 'WHO'S THAT TRIP-TRAPPING OVER MY BRIDGE?'",
				"And it said: 'Meh.' Very rude.",
				"It went east, toward the berry glade. Probably eating something it shouldn't.",
				"Hm. That reminds me of a family story. Never mind. Off you go.",
			]},
			{"text": "Find Bukken the goat east of the old stone bridge.", "where": "bukken", "goal": {"flag": "goat_found"}},
			{"text": "Lead Bukken home to the goat pen at Lars' farm (west side of the village).", "where": "anchor:farm_pen", "goal": {"flag": "goat_home"}},
			{"text": "Talk to Lars at the farm.", "talk": "lars", "allow_scared": true, "lines": [
				"BUKKEN! My Bukken! You're alive!",
				"And you... you brought him back? You didn't... eat him?",
				"> I would never eat a goat! He's a very nice goat. A bit rude. But nice.",
				"Uff da. I owe you an apology, troll. And a thank you. And... here. Wool from my sheep.",
				"* Lars gives you a bundle of soft Wool Yarn.",
				"I'll tell the others. The troll brought Bukken home!",
			], "on_done": [{"give": {"wool_yarn": 1}}, {"trust": ["lars", 25.0]}, {"village_trust": 4.0}]},
		],
		"on_complete": [{"flag": "goat_saved"}],
	},
	"m7_meeting": {
		"title": "The Village Meeting", "main": true, "giver": "margit",
		"desc": "Mayor Margit has called a village meeting. The topic: you.",
		"auto": {"all": [{"quest_done": "m6_goat"}, {"village": 38.0}]},
		"steps": [
			{"text": "Something new is pinned to the notice board in the village square. Read it.", "where": "anchor:notice_board", "goal": {"flag": "read_meeting_notice"}},
			{"text": "Earn the trust of every villager, so none of them are afraid of you (all at least 'Wary').", "goal": {"stage_all": 2}},
			{"text": "Talk to Mayor Margit about the meeting.", "talk": "margit", "lines": [
				"Ah. {name}. The troll. The village held its meeting last night.",
				"It was... loud. Solveig talked for two hours. Ole fell asleep. Astrid made a speech on a chair.",
				"But we reached a decision.",
				"We were wrong about you. All of those old stories... they were just stories.",
				"> So... nobody is going to run away screaming any more?",
				"Well. Ole might. But he runs from seagulls too.",
				"The Harvest Festival is coming. Every year we light a great bonfire on the beach.",
				"And this year, the village would like to invite you. And... your troll friends. If they'd like to come.",
				"> A festival! With humans AND trolls? That's the most wonderful thing I've ever heard!",
			], "on_done": [{"village_trust": 5.0}]},
		],
		"on_complete": [{"start": "m8_festival"}],
	},
	"m8_festival": {
		"title": "The Harvest Festival", "main": true, "giver": "margit",
		"desc": "Help prepare the first ever Harvest Festival for trolls and humans together.",
		"steps": [
			{"text": "Invite your troll friends to the festival: Granny Ur, Stein, Tussa, Lyng and Gubben Grå.", "where": "invite", "goal": {"counter": ["invited", 5]}},
			{"text": "Bring 3 Cloudberries to Ingrid for the festival cake.", "turn_in": {"npc": "ingrid", "take": {"cloudberry": 3}}, "lines": [
				"Cloudberries! Now THIS will be a cake worthy of trolls.",
				"A cloudberry cream cake. Six layers. No, seven! Do trolls like seven?",
				"> Trolls like everything!",
			], "remind": ["For the cake I need 3 Cloudberries. They grow in the bog up on the mountain, don't they?"]},
			{"text": "Bring 4 Driftwood to Ole for the bonfire.", "turn_in": {"npc": "ole", "take": {"driftwood": 4}}, "lines": [
				"Hmph. Good dry wood. You carried all this?",
				"The bonfire will be the biggest this fjord has seen in fifty years.",
				"...Thank you, troll. I mean it.",
			], "remind": ["The bonfire needs 4 pieces of Driftwood. You'll find it washed up along the beach."]},
			{"text": "Bring a Bouquet to Solveig to decorate the square. (Lyng the gardener troll knows how to make one.)", "turn_in": {"npc": "solveig", "take": {"bouquet": 1}}, "lines": [
				"Oh! Oh, it's PERFECT! I'll put it right in the middle of the table.",
				"This will be the most talked-about festival in Lillevik history. I'll make sure of it!",
			], "remind": ["The festival table needs a Bouquet! Wildflowers and heather, tied together. You can make one, can't you?"]},
			{"text": "Tell Mayor Margit that everything is ready.", "talk": "margit", "lines": [
				"Everything is ready? Wonderful. Simply wonderful.",
				"The festival begins tonight at 20:00, down by the bonfire on the beach.",
				"Don't be late, {name}. You're the guest of honour.",
			], "on_done": [{"flag": "festival_ready"}]},
			{"text": "Go to the bonfire on the beach after 20:00 for the Harvest Festival.", "where": "anchor:bonfire", "goal": {"flag": "festival_done"}},
		],
		"on_complete": [{"flag": "game_complete"}],
	},
	# ======================================================================
	# SIDE TASKS
	# ======================================================================
	"s_lyng": {
		"title": "Lyng's Recipes", "giver": "lyng",
		"desc": "Lyng the gardener knows many recipes from the mountain.",
		"offer": {"npc": "lyng", "cond": {"quest_done": "m1_wake"}, "lines": [
			"You've been cooking! I can smell the jam on you.",
			"Would you like to learn my recipes? Teas, soups, bouquets... humans adore bouquets.",
			"Bring me 2 Chanterelles and 2 Heather, and I'll teach you everything.",
			"Chanterelles hide under the spruce trees in the forest. Heather grows all over the plateau.",
		]},
		"steps": [
			{"text": "Bring 2 Chanterelles and 2 Heather to Lyng.", "turn_in": {"npc": "lyng", "take": {"chanterelle": 2, "heather": 2}}, "lines": [
				"Perfect. Smell that! That's the smell of the whole mountain.",
				"* Lyng taught you to make Bouquets, Heather Tea and Mushroom Soup!",
				"Remember: a gift that grew is a gift that's true.",
			], "remind": ["2 Chanterelles from under the spruces, and 2 Heather from the plateau."],
				"on_done": [{"recipe": "bouquet"}, {"recipe": "heather_tea"}, {"recipe": "mushroom_soup"}, {"friendship": ["lyng", 10.0]}]},
		],
	},
	"s_tussa": {
		"title": "Hide and Seek", "giver": "tussa",
		"desc": "Tussa wants to play hide and seek. Tussa is VERY good at hiding. Supposedly.",
		"offer": {"npc": "tussa", "cond": {"quest_done": "m1_wake"}, "lines": [
			"{name}! Play with me! Let's play hide and seek! I hide, you seek!",
			"I'll hide three times. You'll NEVER find me. I'm the best hider on the whole mountain!",
			"Close your eyes and count to a hundred! ...Okay, to ten. GO!",
			"* Tussa scampers off, giggling loudly.",
		]},
		"steps": [
			{"text": "Find Tussa, who is hiding somewhere on the plateau. (Found 0/3)", "where": "npc:tussa", "goal": {"counter": ["tussa_found", 1]}},
			{"text": "Find Tussa again! (Found 1/3)", "where": "npc:tussa", "goal": {"counter": ["tussa_found", 2]}},
			{"text": "Find Tussa one last time! (Found 2/3)", "where": "npc:tussa", "goal": {"counter": ["tussa_found", 3]}},
			{"text": "Talk to Tussa.", "talk": "tussa", "lines": [
				"Aww, you found me AGAIN! How did you do it?",
				"> Your tail was sticking out. Every time.",
				"...I don't have a tail. That's a very fancy scarf.",
				"You win! Here, take my best feather. I found it all by myself!",
			], "on_done": [{"give": {"feather": 2}}, {"friendship": ["tussa", 15.0]}, {"flag": "tussa_done_hiding"}]},
		],
	},
	"s_cloudberry": {
		"title": "Golden Berries", "giver": "granny",
		"desc": "Granny Ur has a very special recipe.",
		"offer": {"npc": "granny", "cond": {"quest_done": "m3_secret"}, "lines": [
			"Sprout, have you been to the bog, west of your hollow? The cloudberries are ripe.",
			"Bring me 2 Cloudberries and I'll show you how to make multekrem. Cloudberry cream!",
			"Humans would cross mountains for a bowl of it. They'd even cross trolls.",
		]},
		"steps": [
			{"text": "Bring 2 Cloudberries from the bog to Granny Ur.", "turn_in": {"npc": "granny", "take": {"cloudberry": 2}}, "lines": [
				"Golden as the midnight sun! Now watch closely...",
				"* Granny Ur taught you how to make Cloudberry Cream!",
				"Whip gently. Love generously. Don't eat it all yourself. I know you, sprout.",
			], "remind": ["The bog is west of your hollow. Look for the golden berries."],
				"on_done": [{"recipe": "cloudberry_cream"}, {"friendship": ["granny", 8.0]}]},
		],
	},
	"s_gubben": {
		"title": "A Pillow for the Bridge", "giver": "gubben",
		"desc": "Gubben Grå has been sleeping on cold stone for 300 years.",
		"offer": {"npc": "gubben", "cond": {"recipe": "moss_pillow"}, "lines": [
			"Oof. My back. Three hundred years on cold stone does things to a troll.",
			"If only somebody made me a nice, soft Moss Pillow...",
			"...That was a hint. A very big hint. Like a boulder.",
		]},
		"steps": [
			{"text": "Cook a Moss Pillow and bring it to Gubben Grå.", "turn_in": {"npc": "gubben", "take": {"moss_pillow": 1}}, "lines": [
				"Ohhh. Ohhhh! It's so SOFT. I may never guard anything again.",
				"You know, I whittle a bit, when nobody's crossing. Which is always.",
				"Here. Let me show you how to carve driftwood into little figures.",
				"* Gubben Grå taught you how to make Troll Carvings!",
			], "remind": ["A Moss Pillow. 3 Moss, cooked in your cauldron. Soft. Squishy. Mine."],
				"on_done": [{"recipe": "wood_carving"}, {"friendship": ["gubben", 15.0]}]},
		],
	},
	"s_ingrid": {
		"title": "Troll Jam Taste Test", "giver": "ingrid",
		"desc": "Ingrid the baker is curious about troll cooking.",
		"offer": {"npc": "ingrid", "cond": {"stage": ["ingrid", 3]}, "lines": [
			"I've been thinking about your jam. Troll jam in a Lillevik bun... imagine it!",
			"Could you bring me a Blueberry Jam and a Lingonberry Jam? For science. Baking science.",
		]},
		"steps": [
			{"text": "Bring a Blueberry Jam and a Lingonberry Jam to Ingrid.", "turn_in": {"npc": "ingrid", "take": {"blueberry_jam": 1, "lingonberry_jam": 1}}, "lines": [
				"Mmm! Oh, this is... this is better than mine. Don't tell anyone.",
				"Here, take these. Fresh heart waffles. You've earned them.",
			], "remind": ["One Blueberry Jam and one Lingonberry Jam, please!"],
				"on_done": [{"give": {"waffle": 2}}, {"trust": ["ingrid", 10.0]}]},
		],
	},
	"s_ole_hat": {
		"title": "Ole's Lucky Hat", "giver": "ole",
		"desc": "Ole's lucky sou'wester blew away in a storm.",
		"offer": {"npc": "ole", "cond": {"stage": ["ole", 2]}, "lines": [
			"Hmph. You. Troll. You go up the mountain, don't you?",
			"My lucky hat blew away in the autumn storm. Yellow sou'wester. Forty years I've had it.",
			"The wind took it up toward the cliffs, west of the waterfall trail. Not that I expect a troll to care.",
		]},
		"steps": [
			{"text": "Find Ole's yellow hat near the cliff edge west of the mountain trail.", "where": "anchor:hat_rock", "goal": {"have": {"lucky_hat": 1}}},
			{"text": "Return the lucky hat to Ole.", "turn_in": {"npc": "ole", "take": {"lucky_hat": 1}}, "lines": [
				"My hat! My lucky hat!",
				"...",
				"Thank you, troll. I... thank you. Here. The best dried cod in the fjord.",
			], "remind": ["It's a yellow hat. Up near the cliffs, west of the trail. Can't miss it. Unless you're a troll."],
				"on_done": [{"give": {"dried_fish": 2}}, {"trust": ["ole", 15.0]}]},
		],
	},
}


static func get_quest(id: String) -> Dictionary:
	return QUESTS.get(id, {})
