-- ZQuest welcome / what's new window
--
-- Shown the first time ZQuest loads on an account, and once after every
-- update, with the changes in that version. /zq welcome opens it again.

local addonName, addon = ...

-- The version comes from the .toc (## Version), so it is only set in one place.
-- ZQuest is in beta, so versions look like 1.1.5-beta.
local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or _G.GetAddOnMetadata
local OPENXP_VERSION = (GetAddOnMetadata and GetAddOnMetadata(addonName, "Version")) or "dev"
addon.openxpVersion = OPENXP_VERSION

-- Newest first. Each entry: version, date, list of changes.
local CHANGELOG = {
    {
        version = "1.7.5",
        date = "November 2026",
        changes = {
            "When a step needs a quest you don't have and the guide picks that quest up on an earlier step, the card now takes you to the pickup on its own and brings you back afterwards",
            "Fixed: coming back to the leveling guide could land you on the kill step of a quest whose pickup was a few steps behind you",
        },
    },
    {
        version = "1.7.4",
        date = "November 2026",
        changes = {
            "Standing next to someone who gives a quest later in the guide? The card now has you pick it up first, then takes you back to the step you were on",
            "Map pins for steps you've already done out of order are gone",
            "Fixed: the Find button said Nobody to find here on Talk to steps",
        },
    },
    {
        version = "1.7.3",
        date = "November 2026",
        changes = {
            "When a step is about several mobs or people, each gets its own row above the Find button. Click a row to target and mark exactly that one",
            "Kill and collect steps that don't name their mobs now get them from Questie, if you have it",
        },
    },
    {
        version = "1.7.2",
        date = "November 2026",
        changes = {
            "The step you're on now shows what its quest pays: the XP at your level and how much of a level that is. It says reduced when you've outleveled the quest",
            "Click that line to open the quest in your quest log (or its pop-up if you don't have it yet). Shift-click puts the quest in chat",
        },
    },
    {
        version = "1.7.1",
        date = "November 2026",
        changes = {
            "New: a Find button on the guide card, above its top right corner. Click it to target the quest giver or mob for the step you're on and put a marker over its head",
            "Under the name it says where that is, such as The Sepulcher, down in the crypt. Right-click the button to write your own note for anyone who is hard to find",
            "Things you click on, like a bookshelf, can't be targeted. The button says so and the arrow takes you there",
            "With ZDungeon installed, the card has Quests and Dungeons tabs",
        },
    },
    {
        version = "1.7.0",
        date = "November 2026",
        changes = {
            "This version brings over the fixes from OpenXP 1.3.60 to 1.3.64. Thanks to the OpenXP contributors",
            "New: mark a step done yourself if the addon didn't notice you did it. Right-click it in the step list, or pick Mark this step done in the menu",
            "Skipping a step where you'd pick up a quest now also skips the rest of that quest chain further on",
            "Quest chain warnings (quests to do first) are now orange with an alert icon, and show once in chat",
            "Quests are only shown when the game will offer them: Chief Engineer Scooty, Onu, A Friend of the Family, The Shamed Lieutenant, Scout Support and Blood of Innocents",
            "Horde Hillsbrad 27-28: if you still have Battle of Hillsbrad part 2, the guide has you finish it before part 3",
            "Horde Thousand Needles: Salt Flat Venom and Hardened Shells moved from 27-28 to 30-31, where the mobs fit your level. A Bump in the Road is now finished before you hand it in",
            "Horde Dustwallow Marsh: buy 3 Soothing Spices from Jandia in Freewind Post before you leave. Other vendor items now say buy instead of kill the vendor",
            "Hide waypoint arrow now really hides the arrow",
            "New setting: Arrow points straight at the target (Settings, next to the route line options). Same as /zq path off",
            "Arrow fixes in Ashenvale: around Astranaar, and at both ends of the Talondeep Path tunnel",
            "Find my place (/zq where) no longer tells you to hand in a quest you haven't finished, or sends you to a zone a few levels above you. A dungeon guide you picked stays picked after you log out",
            "Junk deleting and selling never touch quest items anymore",
            "No more Lua error in dungeon guides like Blackrock Depths, and the step list no longer comes up blank with a custom font from another addon",
            "New optional guide: Night Watchman's Torch (ZQuest Extras > Collectibles). Only doable after 8 PM game time",
            "Drop rates: removed the made-up \"about 80% drop\" from loot steps. Real drop rates stay",
            "Alliance: Darkshore As Water Cascades turn-in fixed, class quest steps in Azshara, Western Plaguelands and Felwood only show for that class, Hearts of the Lost removed (it isn't in Forever), Gerenzo's Orders warns it's an elite fight",
            "Horde 22-23: on your way through Undercity, Warriors, Rogues, Paladins and Hunters can train Swords",
        },
    },
    {
        version = "1.6.2",
        date = "November 2026",
        changes = {
            "Kill and collect steps in the same area now show together, so you can work on them at once. Any you haven't finished come back on their own right after (121 groups in the 21-60 routes)",
        },
    },
    {
        version = "1.6.1",
        date = "November 2026",
        changes = {
            "Class training is now part of the 21-60 routes: a training step whenever the route passes your class trainer, a short detour when you're a visit behind, and a trip to a capital if you're 6 levels behind. Every class trains at least every 6 levels",
            "The training pop-up is off by default (Settings > Helpers > Training reminder pop-up)",
        },
    },
    {
        version = "1.6.0",
        date = "November 2026",
        changes = {
            "Training reminder: at each level with new spells, the arrow points to your nearest class trainer",
            "Hearthstone tips: set your Hearthstone at the town a guide section is based in, and use it when it gets you to the next step faster",
            "Repair, ammo (Hunters) and food and drink reminders that point you to the nearest vendor who can help",
            "Quest log full warning before a step gives you quests you have no room for, with quests worth dropping",
            "Routes 21-60 reordered using Questie's quest chains: about 7% less walking, quest order kept",
            "ZQuest now leans on Questie and warns at login if it isn't installed",
        },
    },
    {
        version = "1.5.1",
        date = "November 2026",
        changes = {
            "Routes 21-60: \"Fly to\" steps wherever you change zone and know both flight paths, at the real flight master spots, plus steps to pick up a zone's flight path the first time you get there",
            "New bag check: when your bags are nearly full, a notice shows and the arrow points at the nearest vendor until you open one (Settings: Bag check)",
        },
    },
    {
        version = "1.5.0",
        date = "November 2026",
        changes = {
            "Routes 21-60: travel steps added wherever a step changes zone, each class gets its own trip to class trainers and back, and steps are reordered to cut walking (quest order is kept)",
            "ZQuest keeps its own saved data and brings over your OpenXP settings and progress the first time it loads",
            "New /zq check: compares the guide's waypoints with Questie's NPC spots and lists any that are off (/zq check fix moves them for this session)",
            "Feedback links can be changed in game: /zq feedback repo <url> and /zq feedback page <url>",
            "ZQuest Purple: guide titles in WoW's Morpheus font, a gold progress line under the title and a gold flash when a step is done",
            "Hides other players' guide-addon level-up and flying messages (Settings > Communications)",
        },
    },
    {
        version = "1.4.2",
        date = "November 2026",
        changes = {
            "Removed the level-up messages ZQuest posted to party and guild chat",
        },
    },
    {
        version = "1.4.1",
        date = "November 2026",
        changes = {
            "ZQuest Purple is more regal: deeper royal purple with gold borders, gold rims on the arrow, buttons and scrollbar, gold checkmarks and step titles, and a gold route line",
        },
    },
    {
        version = "1.4.0",
        date = "November 2026",
        changes = {
            "OpenXP is now ZQuest. Use /zq or /zquest (/oxp still works)",
            "New default theme, ZQuest Purple: royal purple guide window with gold trim on the borders, banner, buttons, scrollbar and arrow, and a gold route line. RXP Blue and the others are still in Settings > Look and Feel",
            "The welcome, feedback and settings windows use the same purple, and ZQuest has its own logo",
        },
    },
    {
        version = "1.3.59",
        date = "November 2026",
        changes = {
            "Fixed the arrow pointing the wrong way on hills, ridges and near caves. It now points straight at the guide's waypoint, like RestedXP",
            "The old detours around hills, cliffs and through learned cave entrances are in Settings > Smart arrow (detours), off by default. /zq path clear forgets learned cave entrances near you",
        },
    },
    {
        version = "1.3.58",
        date = "November 2026",
        changes = {
            "The guide window, themes, arrow and Quest Targets frame look like RestedXP Guides again: the RXP Blue theme, banner header, class icon, step list and classic arrow",
            "Theme choice is back in Settings > Look and Feel (RXP Blue, Red, Green, DarkMode, ZQuest Minimal, ZQuest Gold and Custom), and so are the other guide window options",
            "The ZQuest guide card is still there: Settings > Guide Window > \"Use the ZQuest guide card\" (needs a reload)",
            "Smart start, step memory, quest tooltips, route lines and the quest target key bindings work in both looks",
        },
    },
    {
        version = "1.3.57",
        date = "November 2026",
        changes = {
            "Fixed the guide sometimes showing a later quest in a chain instead of the first one. Smart start now starts you on the chain's first quest",
            "On a quest chain warning, the new \"Go back to step N\" button takes you to the step with the chain's first quest and brings you back once the chain is done. \"Do the chain\" still works for chains the guide doesn't pick up itself",
        },
    },
    {
        version = "1.3.56",
        date = "November 2026",
        changes = {
            "Smart start puts you after the furthest point you've reached in a section, not back at the first quest you skipped. Open steps before that are listed in /zq catchup",
            "Smart start skips quests that are gray for your level, but only when the rest of their chain is gray too. Class quests are never skipped this way",
        },
    },
    {
        version = "1.3.55",
        date = "November 2026",
        changes = {
            "The skulls on the world map for every quest mob are now off by default. Turn them back on in Settings with \"Mob markers on the world map\". When on, they're smaller and sit under the map's own icons, the kill areas and the route line",
        },
    },
    {
        version = "1.3.54",
        date = "November 2026",
        changes = {
            "Your place in the guide no longer jumps back when you log in. Steps you skipped stay skipped. If you're a bit above a section's level, ZQuest tells you to type /zq where instead of moving you",
            "Installing partway through: if you still have a zone's quests, Smart start keeps you in that zone instead of sending you ahead (no more level 16s sent to Auberdine mid-Westfall). Turn-ins for quests you never picked up are skipped instead of being where you start",
            "Getting there: until you open a flight master's map with ZQuest installed, the directions remind you to do it once, so it knows which flight paths you have",
        },
    },
    {
        version = "1.3.53",
        date = "November 2026",
        changes = {
            "Class quests that several trainers give are now picked up from your own race's capital: no more trips to Darnassus or Ironforge for quests your own city has",
            "Warlocks: the Succubus chain no longer sends you to Ironforge for Gakin's Summons. You already meet Gakin in Stormwind at 20",
            "Class quest parts we don't have good location data for yet are left out for now instead of showing a step with no directions. Dungeon parts now point to the dungeon entrance",
        },
    },
    {
        version = "1.3.52",
        date = "November 2026",
        changes = {
            "Alliance Shamans: Call of Water fixed. It sent you to Silverpine Forest (a Horde zone) and skipped the waterskins. It now has all three waterskins (Wetlands, Redridge, Ashenvale) and the Forgotten Shrine at Stendel's Pond in Westfall, done as the route passes those zones",
            "Human Warriors: the Burning Rock for Fire Hardened Mail now comes from Gutspill in Duskwood, not a Horde mob in Silverpine",
            "Class quest trips at the end of a section are now ordered by zone, so you finish what's nearby before travelling (fewer back-and-forth trips for Druids, Warriors, Warlocks and Shamans)",
        },
    },
    {
        version = "1.3.51",
        date = "November 2026",
        changes = {
            "Human Hunters: no more trip to Teldrassil for arrows at level 6. Buy them in Goldshire",
            "Undead: the campfire step for The Great Outdoors now points to Brill instead of Durotar",
            "Orc and Troll Warlocks: the Ruzan step for Vile Familiars works again (its map point was broken)",
            "Darkshore: the Travel to Auberdine step now points to Auberdine",
        },
    },
    {
        version = "1.3.50",
        date = "November 2026",
        changes = {
            "Human Paladins: the end of The Tome of Divinity (Redemption) in the 19-20 guide. Revive Henze Faulk and get the Defias Script by Stone Cairn Lake on the way to Redridge, then turn it in at the Stormwind Cathedral before you hearth to Darkshore",
            "Gnome Priests: Confounding Flash from High Priestess Mims in Ironforge at level 10",
            "Dwarf Priests: Desperate Prayer now shows. Pick it up from High Priest Rohan in Ironforge at 10 and turn it in to High Priestess Laurena when you reach Stormwind (the step was hidden by a typo and pointed at the wrong NPC)",
        },
    },
    {
        version = "1.3.48",
        date = "November 2026",
        changes = {
            "Less stutter while running: the minimap's blue areas and purple line are redrawn only when you've moved at least a pixel on the minimap, not 20 times a second",
            "Kill areas are looked up at most twice a second instead of every frame",
            "New /zq perf: records 30 seconds of play and prints how long each part of ZQuest took, the slowest frames and how fast memory grew, so stutter reports can point at the cause",
        },
    },
    {
        version = "1.3.47",
        date = "November 2026",
        changes = {
            "Undead Paladins: the Wolfsbane chain from 20 (Silverpine, Fenris Isle, Ott in Hillsbrad, then Old Fire-Eye). The Kor Gem and dungeon parts are marked as group content",
        },
    },
    {
        version = "1.3.46",
        date = "November 2026",
        changes = {
            "Horde 22-60 now has class quests, like Alliance: Warlock Felhunter, Felsteed and the Bloodrobe and Orb of Orahil, Warrior Brutal Armor and Berserker Stance, Shaman Water and Air totems, Rogue poisons and Ravenholdt, Druid Aquatic Form and Cure Poison, Mage robe and wand. The shared route is unchanged: these steps only show for your class",
        },
    },
    {
        version = "1.3.45",
        date = "November 2026",
        changes = {
            "Fixed no guide loading at all on German, Spanish and Chinese game clients (\"Smart start couldn't find a guide section for your level\"), for both Alliance and Horde",
        },
    },
    {
        version = "1.3.44",
        date = "November 2026",
        changes = {
            "Fixed step lines going blank after you change the font, until the guide window was resized",
        },
    },
    {
        version = "1.3.43",
        date = "November 2026",
        changes = {
            "Fixed the Font setting doing nothing: every font fell back to Arial Narrow. The font you pick now shows on the guide card, step list and arrow",
        },
    },
    {
        version = "1.3.42",
        date = "November 2026",
        changes = {
            "Fixed 1.3.41 showing the old guide window instead of the ZQuest card (a font check stopped the card from loading)",
        },
    },
    {
        version = "1.3.41",
        date = "November 2026",
        changes = {
            "Fixed the new fonts sometimes not changing anything. /zq fonts shows which fonts load",
        },
    },
    {
        version = "1.3.40",
        date = "November 2026",
        changes = {
            "ZQuest now comes with fonts made for easy reading: Atkinson Hyperlegible (designed for low vision, in regular and bold), Lexend, Open Sans, Roboto, Noto Sans and Fira Sans. Pick one in Settings > Guide Window > Font",
        },
    },
    {
        version = "1.3.39",
        date = "November 2026",
        changes = {
            "Fixed: a turn-in step for a quest you don't have (because an earlier part of its chain is still in your log) now asks whether to do the chain or skip it, instead of sending you to turn in nothing",
            "Hunters: The Absent Minded Prospector now starts at part 1 in Darkshore. Parts you've already done skip themselves",
        },
    },
    {
        version = "1.3.38",
        date = "November 2026",
        changes = {
            "Pick your own font: Settings > Guide Window > Font. Choose one of the game's fonts, or any font from another addon that shares fonts through SharedMedia (ElvUI, Details, SharedMedia and others)",
            "New Text outline setting (thin or thick) to make text easier to read over busy backgrounds",
            "Guide Font Size now goes up to 20, and the step list and DONE tags grow with it",
        },
    },
    {
        version = "1.3.37",
        date = "November 2026",
        changes = {
            "Class quests in the 21-60 guide, shown only to your class: Warlock Succubus, Felhunter and Felsteed; Shaman water and air totems; Druid Aquatic Form, Cure Poison and the Great Cat Spirit; Rogue poisons; your race's priest spell",
            "Class chains worth doing while you level: Verigan's Fist (Paladin), Fire Hardened Mail and the Whirlwind weapon (Warrior), the Bloodrobe and Orahil and Soran'ruk orbs (Warlock), the Astral Knot Robe and wand (Mage), Ravenholdt (Rogue), the rest of The Absent Minded Prospector (Hunter)",
            "The shared route doesn't move: class steps are only added to it",
        },
    },
    {
        version = "1.3.36",
        date = "November 2026",
        changes = {
            "Fixed short stutters (hitching) while running: the purple route line and the arrow worked out their way around mountains again every few steps. Ways are now remembered, follow you as you walk, and new ones are spread over frames",
            "The minimap line is only redrawn when something changed, and with the route line turned off no route work is done at all",
            "Quest data read from Questie is kept instead of being looked up again many times a second",
        },
    },
    {
        version = "1.3.35",
        date = "November 2026",
        changes = {
            "The purple line to another zone now follows each zone's terrain on the way, not just your own zone's (Wetlands to Stonetalon no longer cuts over the mountains after the Talondeep Path)",
            "No purple line inside the capitals, where it went through walls and water; the arrow still points the way",
            "The route no longer counts on quests only Hunters pick up in the 1-20 guide (The Absent Minded Prospector in the Wetlands); routes rebuilt",
        },
    },
    {
        version = "1.3.34",
        date = "November 2026",
        changes = {
            "Chinese, Korean and Russian clients: NPC, item and quest names no longer show as squares. ZQuest now uses your client's own font when its default font can't draw your language",
        },
    },
    {
        version = "1.3.33",
        date = "November 2026",
        changes = {
            "The purple route line skips steps for quests you don't have and won't pick up on the way, so it no longer sends you across a city for nothing",
            "Steps inside cities are put in the shortest order that still picks quests up before turning them in",
        },
    },
    {
        version = "1.3.32",
        date = "November 2026",
        changes = {
            "Checked every zone-to-zone trip in the 21-60 guides against flights, boats, the tram, riding and your Hearthstone, and picked the fastest each time",
            "Travel steps now use your Hearthstone when it's ready and gets you there sooner",
            "First trips to towns you don't have a flight path for yet name the real way in, like the boat to Feathermoon or riding through Deadwind Pass to Nethergarde Keep",
            "Fixed where the Stormwind Harbor boat docks",
        },
    },
    {
        version = "1.3.31",
        date = "November 2026",
        changes = {
            "WoW Forever's new boats: Stormwind Harbor to Auberdine, and the Menethil boat that runs Menethil, Southshore, Auberdine and back to Menethil. The arrow, the Getting there lines and the guide's travel steps all use them",
            "Stormwind to the Wetlands is now the two boats (about 10 minutes) instead of flying to Thelsamar and running through Dun Algaz (about 13)",
        },
    },
    {
        version = "1.3.30",
        date = "November 2026",
        changes = {
            "Levels 21-60: the step that sends you to the next zone now names the fastest way by time, like \"Fly to Auberdine, then take the boat from Auberdine to Menethil Harbor, then take the boat from Menethil Harbor to Theramore\", instead of always saying fly",
            "The route planner picks zones with real trip times: flight times, boats and the tram with their waits, and riding to towns you don't have the flight path for yet",
        },
    },
    {
        version = "1.3.29",
        date = "November 2026",
        changes = {
            "When the next step is in another zone, the guide shows how to get there: which flight master to fly from, the boat, zeppelin or Deeprun Tram to take, your Hearthstone when it's ready, and the roads and passes from zone to zone. The arrow points at each leg and the purple line follows the whole way on the zone, continent and minimap",
            "A finished turn-in you're standing next to is done first: if the guide wants you across the zone but a later turn-in is right here (you finished that quest early), it shows that one, then goes back to the step you were on",
            "The purple line skips steps ahead whose quests you've already done, so it doesn't send you somewhere and back for nothing",
            "New setting: Show the way to other zones (on by default)",
        },
    },
    {
        version = "1.3.28",
        date = "November 2026",
        changes = {
            "The quest chain prompt only shows up when you really missed part of a chain (say it started at level 12 and you're 20 now), not while you're working through it or when this step turns in the quest before",
        },
    },
    {
        version = "1.3.27",
        date = "November 2026",
        changes = {
            "Breadcrumb quests you can't get any more are skipped: if you already have or did the quest a breadcrumb leads to (like Supplies from Darkshire for The Hermit in Duskwood), its pickup and turn-in are ticked off and chat tells you why",
        },
    },
    {
        version = "1.3.26",
        date = "November 2026",
        changes = {
            "Levels 21-60 replanned, Alliance and Horde: the planner now knows how many mobs each quest wants, how often quest items drop and how fast mobs respawn, so it picks the camp that's really faster, not just the closest",
            "Loot steps say roughly how often the item drops (about 35% drop)",
            "Mobs that count for two quests are killed once: their kills and drops count for both at the same time",
            "Quest givers and turn-ins right by the way you're going are visited on the way",
            "Quests with very rare drops or thinly spread mobs are left out when they're slower than killing mobs",
            "The plan walks along the roads like the route line does",
        },
    },
    {
        version = "1.3.25",
        date = "November 2026",
        changes = {
            "Kill and loot areas for every zone, not just Duskwood: quest mob areas are shaded blue on the world map and minimap (needs Questie), and the arrow says you're there anywhere inside",
            "The route line and the arrow keep to the roads: if a road goes your way, you're sent along it instead of off it to cut a corner through mobs",
            "The way also steers around mob camps near your level when there's a clear way past, not just ones well above you",
            "Walking terrain for the starting zones too: Elwynn, Westfall, Dun Morogh, Teldrassil, Darkshore, Durotar, Mulgore, Tirisfal and Silverpine",
            "Turn the areas off in the settings (Kill and loot areas on the maps) if you'd rather just have the arrow",
        },
    },
    {
        version = "1.3.24",
        date = "November 2026",
        changes = {
            "Every race's starting zone guides are back in the guide picker: open ZQuest Alliance (or Horde) > Starting zones, and your own race is listed first",
            "The guide picker is in level order: Starting zones, then Levels 10-19, 20-29 and so on, and the guides inside each one go by level and route order",
            "ZQuest Alliance / Horde now sits above the dungeon guides",
        },
    },
    {
        version = "1.3.23",
        date = "November 2026",
        changes = {
            "Choose whether to show the route line on the world map and minimap, and its colour (purple by default), right here or in the settings",
            "Questie is recommended: ZQuest uses it to mark where your quest mobs spawn and for quest chains and levels",
        },
    },
    {
        version = "1.3.22",
        date = "November 2026",
        changes = {
            "ZQuest is now for WoW Forever only: the Classic Era guides and data are gone, making the download smaller",
        },
    },
    {
        version = "1.3.21",
        date = "November 2026",
        changes = {
            "Loot spots skip mobs more than 2 levels above the quest (no more level 29 Fetid Corpses for Ghoul Fangs) and favour mobs near your level",
            "Thin spots where you'd wait for respawns are no longer picked: Vial of Spider Venom is now the Black Widow Hatchlings by Raven Hill",
            "Loot steps name the mobs that actually live at the spot",
            "Blue areas are filled solid, without the stripes",
        },
    },
    {
        version = "1.3.20",
        date = "November 2026",
        changes = {
            "Cleaner route line: one smooth purple line with rounded corners, a few small direction arrows and a dot at the end, no glow",
        },
    },
    {
        version = "1.3.19",
        date = "November 2026",
        changes = {
            "Kill and loot areas are blue; the purple route line is thinner",
        },
    },
    {
        version = "1.3.18",
        date = "November 2026",
        changes = {
            "Duskwood test: kill and loot areas are smooth purple shapes on the world map and minimap, for your current step and the next few",
            "A purple route line with direction arrows runs from you through your next steps on the world map and minimap, around mountains and high-level packs",
        },
    },
    {
        version = "1.3.17",
        date = "November 2026",
        changes = {
            "Duskwood test: kill and loot steps show their area shaded on the world map and minimap. Anywhere inside it the arrow says Here; outside, it leads you to the nearest edge",
            "World map: a glowing purple line shows the way to your next step, around mountains and high-level packs",
        },
    },
    {
        version = "1.3.16",
        date = "November 2026",
        changes = {
            "Duskwood test: kill and loot steps are now areas. The outline is drawn on your map and the arrow walks you round the spawns instead of back to one spot",
            "World map: a line shows the way the arrow takes you around mountains and packs",
            "World map: marks on every spawn of the mobs your current step needs (uses Questie's data when it's installed)",
        },
    },
    {
        version = "1.3.15",
        date = "November 2026",
        changes = {
            "Routes no longer send you for a breadcrumb quest after you already have the quest it leads to (The Hermit in Duskwood after Supplies from Darkshire); all 21-60 routes rebuilt",
        },
    },
    {
        version = "1.3.14",
        date = "November 2026",
        changes = {
            "The arrow no longer learns inns and city buildings as caves (it sent you to \"Enter the cave\" for the Darkshire inn)",
        },
    },
    {
        version = "1.3.13",
        date = "November 2026",
        changes = {
            "If you updated ZQuest without restarting WoW, it now tells you to restart: new files like the terrain arrow only load after a full restart, not a /reload",
        },
    },
    {
        version = "1.3.12",
        date = "November 2026",
        changes = {
            "The arrow now walks around mountains, cliffs, lakes and high-level packs in every zone on the 21-60 routes, not just Duskwood",
            "All 21-60 Alliance and Horde routes rebuilt with walking distances around the terrain: about 18% less walking in total and 13-16% less per quest",
        },
    },
    {
        version = "1.3.11",
        date = "November 2026",
        changes = {
            "New installs start right away: the guide card and arrow show up on login with the right guide for your race and level, no clicks or settings needed",
            "Clicking the minimap button before a guide is loaded now loads one instead of doing nothing",
            "This What's new window now also shows after you update and /reload, not only after restarting the game",
            "Fixed two file names that could stop parts of ZQuest loading on a Mac",
        },
    },
    {
        version = "1.3.10",
        date = "November 2026",
        changes = {
            "Duskwood steps rebuilt with walking distances around the mountains: quests are picked up before the areas they share (Eight-Legged Menaces before the wolves), objectives use the densest spot on your way, and Darkshire's quests are all grabbed before you leave",
            "About 7% less walking and much less time near mobs well above your level in 21-24 Duskwood, with the same quests",
        },
    },
    {
        version = "1.3.9",
        date = "November 2026",
        changes = {
            "Arrow walks around mountains, cliffs and rivers in Duskwood instead of pointing straight into them (more zones to come)",
            "Arrow steers around packs of mobs 3 or more levels above you, like the Brightwood worgen at level 22, and takes the direct way again once you've outleveled them",
        },
    },
    {
        version = "1.3.8",
        date = "November 2026",
        changes = {
            "New Feedback window: report a bug, suggest something, leave a comment or rate ZQuest. Open it with /zq feedback or \"Feedback and bugs\" in the right-click menu",
            "The bug report link fills in your ZQuest version, guide and step for you, and \"Full bug details\" has everything else to paste in",
        },
    },
    {
        version = "1.3.7",
        date = "November 2026",
        changes = {
            "Guide picker is one click shorter: the level brackets (Levels 20-29, 30-39 ...) sit right in your faction's menu next to the 1-20 guides",
        },
    },
    {
        version = "1.3.6-beta",
        date = "November 2026",
        changes = {
            "The guide picker no longer runs off the screen: long guide lists (like ZQuest 21-60) are split into Levels 20-29, 30-39, 40-49 and 50-59, so every guide can be clicked",
        },
    },
    {
        version = "1.3.5-beta",
        date = "November 2026",
        changes = {
            "Fixed a Lua error when walking through a quest chain (\"attempt to index field 'step'\")",
            "Level-up announcements no longer try to /emote when you're solo: WoW Forever blocks addons from doing that",
        },
    },
    {
        version = "1.3.4-beta",
        date = "November 2026",
        changes = {
            "The arrow knows the way from Ashenvale into Stonetalon Mountains: through the Talondeep Path tunnel, instead of straight at the mountains on the border",
            "New /zq path to <zone> (or /zq path to <x> <y> on your map): the arrow leads you there, through any tunnels and passes it knows, then goes back to the guide. For example /zq path to Stonetalon",
        },
    },
    {
        version = "1.3.3-beta",
        date = "November 2026",
        changes = {
            "Put back a few WoW Forever quests that 1.3.2 wrongly left out with the Season of Discovery ones (their quest givers have new NPC ids like Season of Discovery's). Alliance 21-60 has 498 quests, Horde 22-60 has 444",
        },
    },
    {
        version = "1.3.2-beta",
        date = "November 2026",
        changes = {
            "Removed Season of Discovery quests that aren't in WoW Forever from the 21-60 routes, like Alonso's Dragonslayer quests in Ashenvale and the scroll and book quests. They came in through Questie's data",
            "Routes rebuilt without them: Alliance 21-60 has 492 quests, Horde 22-60 has 444",
        },
    },
    {
        version = "1.3.1-beta",
        date = "November 2026",
        changes = {
            "The arrow now walks you around caves and cliffs. When a quest is inside a cave or up on a ridge, it first points at the entrance or the bottom of the ramp (\"Enter Jasperlode Mine\"), then at the quest. Leaving a cave works the same way",
            "ZQuest learns cave entrances by itself: walk into a cave once and the arrow uses that entrance from then on",
            "New /zq path command: stand at a ramp, pass or cave mouth and type /zq path add to save it as a stepping stone toward the arrow's target, then /zq path done. /zq path off turns all of this off",
        },
    },
    {
        version = "1.3.0-beta",
        date = "November 2026",
        changes = {
            "New 21-60 routes for both factions (WoW Forever). The route builder now plays the route in its head: it tracks your level as you go, picks the next zone by the most XP per minute, and comes back to zones as their higher quests open up, like the well-known leveling routes do",
            "Quests join the route only once they're at most 2 levels above you, quests above your level count as slower, and gray quests are left out",
            "About 60% more quests: Alliance 21-60 has 505 turn-ins (was 318), Horde 22-60 has 427 (was 221). New stops include the Swamp of Sorrows, Blasted Lands, Alterac, the Barrens and quick capital-city stops for chain quests",
            "Section names now show the levels you'll really be at. When the next quests are a bit high, a step tells you to kill mobs on the way or run a dungeon that fits your level",
        },
    },
    {
        version = "1.2.3-beta",
        date = "November 2026",
        changes = {
            "The 21-60 guides no longer send you to quests far above your level. A quest now has to be at most 2 levels above where its section ends (for example, the 21-23 Ashenvale section no longer has the level 27 Raene's Cleansing)",
            "The 40-60 guides were rebuilt with WoW Forever's quests included, like 21-40 were in 1.2.0",
        },
    },
    {
        version = "1.2.2-beta",
        date = "November 2026",
        changes = {
            "Hearth steps now check where your Hearthstone is set. If it's somewhere else (say you missed a \"set your Hearthstone\" step earlier), the step says so in red, with a heads-up in chat and on screen, so you know to travel there another way and skip the step",
        },
    },
    {
        version = "1.2.1-beta",
        date = "November 2026",
        changes = {
            "New section for Shen'dralas, Forever's new zone south of Desolace (Alliance 39-40, Horde 38-39). It's short for now: it has the quests whose givers are known so far, and will grow as more of the zone is mapped",
            "The arrow now knows the Shen'dralas, Riverglades and Darkspear Islands maps",
        },
    },
    {
        version = "1.2.0-beta",
        date = "November 2026",
        changes = {
            "Levels 21-40 guides rebuilt with WoW Forever's own quests included (from Questie). About 50 more quests across Wetlands, Duskwood, Stranglethorn, Desolace, Hillsbrad and Badlands, nothing taken out",
        },
    },
    {
        version = "1.1.9-beta",
        date = "November 2026",
        changes = {
            "New for guide makers: /zq questdump saves what your installed Questie knows about quests (including WoW Forever's new quests) so the guide tools can find quests the guides are missing. It stays on your PC",
        },
    },
    {
        version = "1.1.8-beta",
        date = "November 2026",
        changes = {
            "The quest loot icon on enemy nameplates now sits centred above the enemy's name, bigger and with an outlined count, instead of hiding behind the level",
        },
    },
    {
        version = "1.1.7-beta",
        date = "November 2026",
        changes = {
            "Quest items stand out more: a QUEST ITEM - DON'T SELL banner with a quest icon, an orange tooltip border, and a quest marker on the bag slot",
            "Enemy tooltips now list the quest items they drop that you still need, with the item's icon and your count, even with Questie installed and even for quests you'll pick up later (like Gooey Spider Legs from spiders)",
            "Enemies that drop an item you need show its icon and your count beside their nameplate (turn it off under Extras: Quest loot on nameplates)",
        },
    },
    {
        version = "1.1.6-beta",
        date = "November 2026",
        changes = {
            "Bag items a quest needs now say so on their tooltip, with the quest and how many you have (like Gooey Spider Legs 2/6), so you don't sell them. This includes items the guide tells you to save for a quest you'll pick up later",
            "Enemy tooltips now show your progress on item drops they give (like Gooey Spider Legs from spiders), not just kills",
            "If Questie is installed with its tooltips turned off, ZQuest shows the quest progress on enemies instead",
        },
    },
    {
        version = "1.1.5-beta",
        date = "November 2026",
        changes = {
            "ZQuest is in beta testing, so version numbers now end in -beta",
            "The version shown on the guide footer and this window now matches the installed version (it was stuck on 0.9.9)",
        },
    },
    {
        version = "1.1.4",
        date = "November 2026",
        changes = {
            "Skipped quest chains now lists every quest you skipped or whose chain was missed in your current guide, with its step number and what it needs first. Before, it only remembered the last Find my place and forgot it on reload",
        },
    },
    {
        version = "1.1.3",
        date = "November 2026",
        changes = {
            "\"Go here\" steps (like heading up a ramp) count as done once you've run past them towards the next stop, so the arrow no longer sends you back",
        },
    },
    {
        version = "1.1.2",
        date = "November 2026",
        changes = {
            "Each step on the card shows its step number under the icon",
            "Trainer steps (class and pet) are done as soon as you talk to the trainer. You don't have to train everything, and a visit earlier at the same level counts too",
        },
    },
    {
        version = "1.1.1",
        date = "November 2026",
        changes = {
            "Fixed a Lua error when starting a quest chain walk-through (Do the chain, Get the quest)",
        },
    },
    {
        version = "1.1.0",
        date = "November 2026",
        changes = {
            "Scroll the mouse wheel up over the guide card to see earlier steps. Each one is tagged Done, Skipped or Chain missed. Click a step to go back to it",
            "Going back to a step now stays there, even if that step is already done. Press Next or Back to step N to carry on",
            "Next marks a step you didn't finish as Skipped",
            "The step list (click the step counter) shows the same tags",
            "New Quest Targets list in the card's style: a row per mob or NPC with its portrait, name and key binding",
            "Two new key bindings: Target a quest mob and Target a quest NPC (Key Bindings > ZQuest)",
            "Removed files for other WoW versions (Retail, TBC, Wrath, Cata, MoP, SoD) and unused guides and textures",
        },
    },
    {
        version = "1.0.0",
        date = "November 2026",
        changes = {
            "Horde routes from 22 to 60, so both factions now go 1 to 60",
            "Classic Era: 21 to 60 routes for Alliance and Horde",
            "Dungeon guides for both factions: pick up the dungeon quests, run it, turn them in",
            "Tooltips: mobs show which of your quests they count for and your progress, NPCs show the guide step that needs them",
            "Click the step counter on the card to see every step and jump to any of them",
            "Flight timers now show under the card",
            "Map and minimap pins show the ! and ? quest icons next to the step number",
            "Gold XP line along the bottom of the card. Hover it for XP per hour and time to level",
            "New options: auto loot and max camera distance (both off until you turn them on). Sell junk is on by default",
            "The card only redraws when something changes, and the download is smaller",
            "If Questie isn't installed you get a one-time tip about what it adds",
        },
    },
    {
        version = "0.9.9",
        date = "November 2026",
        changes = {
            "Your place in each guide is saved on the character, including steps you skipped ahead to, and kept through reloads and relogs",
            "Fixed the back button bouncing you forward again",
            "Party and guild announcements (level ups, quest progress, flight times) are on by default",
        },
    },
    {
        version = "0.9.8",
        date = "November 2026",
        changes = {
            "The guide card can go narrower still (down to 200)",
            "Active Targets, the quest item bar and Level splits now match the guide card's look",
        },
    },
    {
        version = "0.9.7",
        date = "November 2026",
        changes = {
            "The guide card can be made about 25% narrower; buttons slim down and wrap to fit",
        },
    },
    {
        version = "0.9.6",
        date = "November 2026",
        changes = {
            "Turn in steps for a quest you have but haven't finished now say so, list what's left, and offer Finish it or Skip this step",
            "Finish it walks you through the objectives with the arrow, then brings you back to turn it in",
        },
    },
    {
        version = "0.9.5",
        date = "November 2026",
        changes = {
            "Fixed steps for quests that aren't in your quest log (like Mathystra Relics) being treated as if you had them. The guide now checks the quest log itself",
        },
    },
    {
        version = "0.9.4",
        date = "November 2026",
        changes = {
            "If the guide card hits an error it now says so in chat instead of silently not updating",
        },
    },
    {
        version = "0.9.3",
        date = "November 2026",
        changes = {
            "The step you're on is always at the top of the card",
            "Background steps (like looting an item while you do other things) are labelled Along the way and dimmed",
            "Finished steps are marked Done and faded",
            "Pickup steps say You get this quest at this step",
        },
    },
    {
        version = "0.9.2",
        date = "November 2026",
        changes = {
            "New /zq step command: prints what the guide card sees for the steps on screen, for bug reports",
            "Questie lookups work with both ways Questie exposes its quest data",
        },
    },
    {
        version = "0.9.1",
        date = "November 2026",
        changes = {
            "Quest chain info now comes from Questie while you play, so install Questie to get chains, levels and Do the chain. It stays current whenever Questie updates",
            "Without Questie, every step still checks your quest log and offers Skip this step or Get the quest",
        },
    },
    {
        version = "0.9.0",
        date = "November 2026",
        changes = {
            "Every step now checks your quest log. A step for a quest you don't have says so, with Skip this step or Get the quest",
            "Quest chains: when a step needs earlier quests, the card lists them with their levels and offers Do the chain",
            "Do the chain walks you through each earlier quest (pick up, objectives, turn in) with the arrow, then drops you back into the guide",
            "Pickup steps are no longer skipped behind your back; you choose",
        },
    },
    {
        version = "0.8.3",
        date = "November 2026",
        changes = {
            "Pickup steps for quests you can't get yet (you skipped the quest before it) are skipped automatically, like the Beached Sea Creature quests if you never did Washed Ashore",
        },
    },
    {
        version = "0.8.2",
        date = "November 2026",
        changes = {
            "Steps for a quest you don't have now say so, with buttons to skip the step or go back and get the quest. Once you have it, the guide brings you back",
        },
    },
    {
        version = "0.8.1",
        date = "November 2026",
        changes = {
            "Guide font size now changes right away, no reload needed",
        },
    },
    {
        version = "0.8.0",
        date = "November 2026",
        changes = {
            "Resize the guide card: drag the grip in its bottom right corner. A taller card shows more of the route under Up next",
            "Settings cleaned up: options that did nothing with the new card are gone",
            "Window scale, arrow scale, arrow text size and Lock frames now apply to the new card and arrow right away",
            "New Reset Guide Window button in settings puts the card back to its starting spot and size",
        },
    },
    {
        version = "0.7.0",
        date = "November 2026",
        changes = {
            "Brand new guide window: a compact card with a badge for each step, check marks, kill and loot bars and an Up next line",
            "Buttons on the card: back, skip, Find my place, guides menu, settings and collapse to one line",
            "New arrow: a pointer in a round dial with the distance in big text, and a green check when you arrive",
            "Drag the card anywhere; right-click it for the guides menu",
        },
    },
    {
        version = "0.6.0",
        date = "November 2026",
        changes = {
            "New minimal look by default: flat dark panels, thin borders, a clean font and ZQuest blue highlights",
            "This window has the new look too",
        },
    },
    {
        version = "0.5.0",
        date = "November 2026",
        changes = {
            "Bigger, easier to read guide text and arrow distance",
            "The step you're on now has a gold bar, and finished steps fade back",
            "Progress bar along the bottom of the guide window: Step 12 of 148",
            "Right-click the guide window for Find my place, Skipped quest chains and What's new, no commands needed",
            "The same buttons are at the top of the ZQuest settings",
            "Removed the guide menus ZQuest doesn't use (dungeon, mage, survival and endgame lists)",
        },
    },
    {
        version = "0.4.0",
        date = "November 2026",
        changes = {
            "Alliance guides now go all the way to 60",
            "30-40: Hillsbrad and Alterac, Arathi, Stranglethorn, Dustwallow, Thousand Needles and Desolace",
            "40-50: Badlands, Tanaris, Feralas, Hinterlands, Searing Gorge and Azshara",
            "50-60: Un'Goro, Felwood, Winterspring, Burning Steppes, the Plaguelands and Silithus",
            "21-30 now gives you the Redridge quests if you didn't pick them up earlier",
        },
    },
    {
        version = "0.3.0",
        date = "November 2026",
        changes = {
            "New Alliance 21-30 route: Ashenvale, Stonetalon, Wetlands, Redridge and Duskwood",
            "The 20-21 guides now carry straight on into 21-30, for Hunters too",
            "Smart start knows the new sections, so it can place you anywhere from 1 to 30",
        },
    },
    {
        version = "0.2.0",
        date = "November 2026",
        changes = {
            "New ZQuest look: navy and gold guide window, gold borders and a glowing guide arrow",
            "New ZQuest icon in the AddOns list, minimap button and guide window",
            "Smart start: ZQuest finds your place in the guide from your level, zone and quests",
            "Skipped a section? Quest chains you can't start anymore are skipped for you",
            "This welcome window, which also shows what's new after each update",
        },
    },
    {
        version = "0.1.0",
        date = "November 2026",
        changes = {
            "First release: free leveling guides for WoW Forever",
            "Alliance 1-21 for every starting race, with class quests built in",
        },
    },
}

-- Same palette as the ZQuest Purple guide window theme. "gold" is the accent
-- (royal gold), "blue" the lavender bullets and "goldDark" the hairline border.
local COLORS = {
    bg = {18 / 255, 7 / 255, 32 / 255, 0.96}, -- ZQuest Purple
    panel = {28 / 255, 11 / 255, 48 / 255, 0.9},
    gold = {230 / 255, 195 / 255, 106 / 255},
    goldDark = {150 / 255, 116 / 255, 52 / 255},
    blue = {197 / 255, 139 / 255, 255 / 255},
    text = {0.86, 0.86, 0.9},
    muted = {0.6, 0.62, 0.7},
}

local GOLD_HEX = "|cFFE6C36A"
local BLUE_HEX = "|cFFC58BFF"
local LOGO = "Interface/AddOns/" .. addonName .. "/Textures/zquest_logo-128"

local frame

local function Backdrop(f, bg, border)
    f:SetBackdrop({
        bgFile = "Interface/Buttons/WHITE8X8",
        edgeFile = "Interface/Buttons/WHITE8X8",
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1},
    })
    f:SetBackdropColor(unpack(bg))
    f:SetBackdropBorderColor(unpack(border))
end

local function MakeButton(parent, text, primary)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(150, 30)
    Backdrop(b, primary and {86 / 255, 36 / 255, 132 / 255, 1} or COLORS.panel,
             primary and COLORS.gold or COLORS.goldDark)
    local label = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER")
    label:SetText(text)
    label:SetTextColor(unpack(primary and {1, 1, 1} or COLORS.text))
    b.label = label
    b:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(1, 1, 1, 0.8)
    end)
    b:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(unpack(primary and COLORS.gold or COLORS.goldDark))
    end)
    return b
end

local function BuildBody(mode, lastSeen)
    local lines = {}
    if mode == "welcome" then
        table.insert(lines, GOLD_HEX .. "Welcome, adventurer!|r")
        table.insert(lines, "")
        table.insert(lines, "ZQuest is a free, community-made leveling guide for WoW Forever. " ..
            "Follow the arrow and the steps, and it takes you from quest to quest by the fastest route.")
        table.insert(lines, "")
        table.insert(lines, BLUE_HEX .. "•|r  Already leveling? Smart start finds where you are from your level, zone and quests.")
        table.insert(lines, BLUE_HEX .. "•|r  " .. GOLD_HEX .. "Right-click the guide window|r for Find my place, Skipped quest chains and What's new.")
        table.insert(lines, BLUE_HEX .. "•|r  The same buttons are at the top of the settings (" .. GOLD_HEX .. "/zq|r or the minimap button).")
    else
        table.insert(lines, GOLD_HEX .. "What's new|r")
        for _, entry in ipairs(CHANGELOG) do
            if lastSeen and entry.version == lastSeen then break end
            table.insert(lines, "")
            table.insert(lines, string.format("%sVersion %s|r  |cFF9EA0B2%s|r", BLUE_HEX, entry.version, entry.date))
            for _, change in ipairs(entry.changes) do
                table.insert(lines, BLUE_HEX .. "•|r  " .. change)
            end
        end
    end
    return table.concat(lines, "\n")
end

local function CreateWelcomeFrame()
    local f = CreateFrame("Frame", "OpenXPWelcomeFrame", UIParent, "BackdropTemplate")
    f:SetSize(480, 500)
    f:SetPoint("CENTER", 0, 60)
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    Backdrop(f, COLORS.bg, COLORS.gold)
    tinsert(_G.UISpecialFrames, "OpenXPWelcomeFrame") -- Escape closes it

    -- Header band
    local header = f:CreateTexture(nil, "BORDER")
    header:SetPoint("TOPLEFT", 4, -4)
    header:SetPoint("TOPRIGHT", -4, -4)
    header:SetHeight(110)
    header:SetColorTexture(1, 1, 1, 0.03)

    local divider = f:CreateTexture(nil, "ARTWORK")
    divider:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
    divider:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, 0)
    divider:SetHeight(1)
    divider:SetColorTexture(COLORS.gold[1], COLORS.gold[2], COLORS.gold[3], 0.6)

    -- Glowing logo
    local glow = f:CreateTexture(nil, "ARTWORK")
    glow:SetTexture("Interface/Cooldown/star4")
    glow:SetBlendMode("ADD")
    glow:SetVertexColor(COLORS.blue[1], COLORS.blue[2], COLORS.blue[3], 0.35)
    glow:SetSize(150, 150)
    glow:SetPoint("LEFT", f, "TOPLEFT", -8, -58)

    local pulse = glow:CreateAnimationGroup()
    pulse:SetLooping("BOUNCE")
    local a = pulse:CreateAnimation("Alpha")
    a:SetFromAlpha(0.35)
    a:SetToAlpha(0.9)
    a:SetDuration(1.6)
    a:SetSmoothing("IN_OUT")
    pulse:Play()

    local logo = f:CreateTexture(nil, "OVERLAY")
    logo:SetTexture(LOGO)
    logo:SetSize(84, 84)
    logo:SetPoint("CENTER", glow, "CENTER")

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 128, -30)
    title:SetText("ZQuest")
    title:SetTextColor(1, 1, 1)
    title:SetShadowOffset(2, -2)

    local subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    subtitle:SetText("Free leveling guides for WoW Forever")
    subtitle:SetTextColor(unpack(COLORS.text))

    local badge = CreateFrame("Frame", nil, f, "BackdropTemplate")
    badge:SetSize(70, 20)
    badge:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -8)
    Backdrop(badge, {16 / 255, 40 / 255, 70 / 255, 1}, COLORS.blue)
    local badgeText = badge:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    badgeText:SetPoint("CENTER")
    badgeText:SetText("v" .. OPENXP_VERSION)
    badgeText:SetTextColor(unpack(COLORS.blue))

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)

    -- Scrolling body
    local panel = CreateFrame("Frame", nil, f, "BackdropTemplate")
    panel:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -128)
    panel:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 138)
    Backdrop(panel, COLORS.panel, COLORS.goldDark)

    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -10)
    scroll:SetPoint("BOTTOMRIGHT", -28, 10)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(400, 10)
    scroll:SetScrollChild(content)

    local body = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    body:SetPoint("TOPLEFT")
    body:SetWidth(400)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    body:SetSpacing(3)
    body:SetTextColor(unpack(COLORS.text))
    f.body, f.content = body, content

    -- Choices: the route line on the maps, its colour, and a Questie tip
    local route = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    route:SetSize(24, 24)
    route:SetPoint("TOPLEFT", panel, "BOTTOMLEFT", 0, -8)
    local routeText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    routeText:SetPoint("LEFT", route, "RIGHT", 4, 0)
    routeText:SetText("Show route lines on the world map and minimap")
    routeText:SetTextColor(unpack(COLORS.text))
    route:SetScript("OnClick", function(self)
        local p = addon.settings and addon.settings.profile
        if p then p.openxpMapRoute = self:GetChecked() and true or false end
    end)

    local swatch = CreateFrame("Button", nil, f, "BackdropTemplate")
    swatch:SetSize(36, 18)
    swatch:SetPoint("LEFT", routeText, "RIGHT", 10, 0)
    Backdrop(swatch, {0.9, 0.76, 0.42, 1}, COLORS.goldDark)
    local swatchText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    swatchText:SetPoint("LEFT", swatch, "RIGHT", 6, 0)
    swatchText:SetText("Colour")
    swatchText:SetTextColor(unpack(COLORS.muted))
    local function ShowColor()
        local p = addon.settings and addon.settings.profile
        local c = p and p.openxpRouteColor or {0.9, 0.76, 0.42}
        swatch:SetBackdropColor(c[1], c[2], c[3], 1)
    end
    swatch:SetScript("OnClick", function()
        local p = addon.settings and addon.settings.profile
        if not p then return end
        local c = p.openxpRouteColor or {0.9, 0.76, 0.42}
        local old = {c[1], c[2], c[3]}
        local function Apply(r, g, b)
            p.openxpRouteColor = {r, g, b}
            ShowColor()
        end
        local picker = _G.ColorPickerFrame
        local function Picked()
            Apply(picker:GetColorRGB())
        end
        local function Cancel(prev)
            if type(prev) == "table" and prev.r then Apply(prev.r, prev.g, prev.b) else Apply(old[1], old[2], old[3]) end
        end
        if picker.SetupColorPickerAndShow then
            picker:SetupColorPickerAndShow({r = c[1], g = c[2], b = c[3], hasOpacity = false,
                                            swatchFunc = Picked, cancelFunc = Cancel})
        else
            picker.func, picker.cancelFunc, picker.hasOpacity = Picked, Cancel, false
            picker.previousValues = {r = c[1], g = c[2], b = c[3]}
            picker:SetColorRGB(c[1], c[2], c[3])
            picker:Hide()
            picker:Show()
        end
    end)

    local questie = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    questie:SetPoint("TOPLEFT", route, "BOTTOMLEFT", 4, -8)
    questie:SetPoint("RIGHT", f, "RIGHT", -16, 0)
    questie:SetJustifyH("LEFT")
    f.questie = questie

    f.route, f.ShowColor = route, ShowColor

    -- Buttons
    local start = MakeButton(f, "Start leveling", true)
    start:SetPoint("BOTTOMRIGHT", f, "BOTTOM", -6, 16)
    start:SetScript("OnClick", function()
        f:Hide()
        local level = UnitLevel("player") or 1
        if addon.smartStart and addon.smartStart.HasGuide and not addon.smartStart.HasGuide() then
            addon.smartStart.EnsureGuide()
        elseif addon.smartStart and level > 1 then
            addon.smartStart.Run()
        elseif addon.SelectDefaultGuide then
            addon.SelectDefaultGuide()
        end
    end)

    local later = MakeButton(f, "Close", false)
    later:SetPoint("BOTTOMLEFT", f, "BOTTOM", 6, 16)
    later:SetScript("OnClick", function() f:Hide() end)

    -- Fade in
    local fade = f:CreateAnimationGroup()
    local fa = fade:CreateAnimation("Alpha")
    fa:SetFromAlpha(0)
    fa:SetToAlpha(1)
    fa:SetDuration(0.35)
    f:SetScript("OnShow", function()
        fade:Play()
        if PlaySound and SOUNDKIT and SOUNDKIT.IG_QUEST_LIST_OPEN then
            PlaySound(SOUNDKIT.IG_QUEST_LIST_OPEN)
        end
    end)

    f:Hide()
    return f
end

local welcome = {}
addon.welcome = welcome
welcome.changelog = CHANGELOG

-- mode: "welcome" (first run) or "update"; lastSeen: version the player saw last
function welcome.Show(mode, lastSeen)
    frame = frame or CreateWelcomeFrame()
    frame.body:SetText(BuildBody(mode or "welcome", lastSeen))
    frame.content:SetHeight(frame.body:GetStringHeight() + 10)
    local p = addon.settings and addon.settings.profile
    frame.route:SetChecked(not (p and p.openxpMapRoute == false))
    frame.ShowColor()
    if _G.QuestieLoader then
        frame.questie:SetText(BLUE_HEX .. "Questie is installed.|r ZQuest uses it for spawn marks, quest chains and levels.")
    else
        frame.questie:SetText(BLUE_HEX .. "Recommended: install the free Questie addon.|r ZQuest uses it to mark where your quest mobs spawn and to show quest chains and levels.")
    end
    frame:Show()
end

-- Decide whether to show on login. Returns the mode shown, or nil.
function welcome.CheckOnLogin()
    if not ZQData then return end
    local lastSeen = ZQData.openxpLastSeenVersion
    local mode
    if not lastSeen then
        mode = "welcome"
    elseif lastSeen ~= OPENXP_VERSION then
        mode = "update"
    end
    ZQData.openxpLastSeenVersion = OPENXP_VERSION
    -- 0.5.0 made the guide text bigger. Testers who still have the old
    -- small default get the new one once; a size they picked is kept.
    local profile = addon.settings and addon.settings.profile
    if mode == "update" and profile and lastSeen < "0.5.0" then
        local changed
        if profile.guideFontSize == 9 then profile.guideFontSize = 12; changed = true end
        if profile.arrowText == 9 then profile.arrowText = 12 end
        if changed and addon.UpdateGuideFontSize then addon.UpdateGuideFontSize() end
        if changed and addon.ReloadGuide and addon.currentGuide then addon:ReloadGuide(true) end
    end
    -- The route line on the maps is new: everyone gets asked once, on a
    -- first install or on the update that brings it.
    if not mode and not ZQData.openxpRouteAsked then mode = "update" end
    ZQData.openxpRouteAsked = true
    if mode then welcome.Show(mode, lastSeen) end
    return mode
end
