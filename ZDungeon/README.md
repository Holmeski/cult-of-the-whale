# ZDungeon

A dungeon planner for World of Warcraft: Forever. For every 5-player dungeon it answers four questions: which quests are there and what are they worth, is the trip worth the time, what gear drops that I can use, and have I got everything before I leave.

Type `/zd` to open it.

Status: early release. Built and tested outside the game; in-game testing is in progress.

## What it does

### Where do I go next?
- One button that gives you up to three dungeon options for your level, best quest XP per hour first.
- Each option shows the quest XP ready, how far away it is, and how many gear upgrades are waiting.
- Pick one and click **Start guide**.

### The dungeon guide
- With ZQuest installed, the guide for a dungeon loads onto **ZQuest's own guide card**, under a **Dungeons** tab next to **Quests**. It uses ZQuest's arrow, its "Getting there" travel steps, its map pins and its automatic ticking.
- ZDungeon's guides live in ZQuest's own **ZQuest Dungeons** menu. Where ZQuest ships a guide for a dungeon, ZDungeon's planned guide takes its place under the same name; other dungeons get their own entry there. On the Dungeons tab, the tab reads **Change dungeon**.
- The guide plans the trip from where you stand: it always takes the nearest errand that is allowed yet (a pickup, something to fetch, a hand-in), so everything in one town is done in one visit and quest chains stay in order. Then the trip to the entrance, what to finish inside, and the hand-ins, nearest to the door first.
- A chain quest that sends you somewhere first gets its own step: where the bookshelf is, or where the mobs are, before the hand-in. Dungeon quests whose mobs or items are all outside the instance are done on the way in.
- Each step names who to talk to or what to kill, so ZQuest's Find button can target and mark them.
- It only includes what you can do at your level. Quests you are too low for are listed at the end with the level they need.
- Click **Quests** to go back to your leveling guide where you left it, and **Dungeons** to return to the dungeon guide.
- Without ZQuest, ZDungeon shows the same steps on a small card of its own.

### Deep dives
- A page per dungeon: what it is like, what to look out for, how to tank it, heal it and deal damage in it, and every boss in order with its tricks.
- Your own role comes first.
- Written so far: Ruins of Lordaeron, Wailing Caverns, Shadowfang Keep, Blackfathom Deeps, Excavation Site: Wetlands, City of Dalaran, Gnomeregan, Razorfen Kraul and the Scarlet Monastery Graveyard. More are added as they are researched.

### Level-up cheers
- When a new level opens a dungeon or new dungeon quests, ZDungeon congratulates you and says what just opened.

### Quests and XP
- Every quest for each dungeon, for your faction and class, with its level and the XP it pays at your level.
- Status for each quest: done, in your log, available, behind a chain, or needs a higher level.
- For chain quests, the steps you have to do first and the XP they pay on the way.
- Who gives each quest and where, with a button to show it on the map.
- XP comes from the game itself where the game will answer. Estimates are marked `~`.
- A quest more than 5 levels below you pays less: 80%, 60%, 40%, 20%, then 10%. ZDungeon checks your own hand-ins to learn whether the game's listed XP already includes that cut, and adjusts if it does not.
- With ZQuest, the step you are on shows the quest's XP and a click opens the quest.

### Is it worth the trip
- Where the entrance is, the route from where you are standing (flights, zeppelins, boats, walking, Hearthstone) and about how long it takes.
- Flight paths you have not picked up in the zones on the way.
- Quest XP per hour for the whole trip: travel both ways plus the run. Click the "XP left" heading to rank every dungeon this way.
- Run times start as typical figures and switch to your own average once you have finished a run.

Travel times need ZQuest.

### Gear
- Every boss drop and quest reward your class can use, with the slot and where it comes from.
- How much of an upgrade each piece is over what you are wearing, for your spec, biggest first.
- A star on the best piece in the dungeon for each slot.

The gear list needs DungeonJournal. Upgrade numbers need Forever Leveling BiS.

### Quest sharing
- A **Quest sharing** window lists the dungeon quests you are missing that a party member could share with you, and the ones in your log that you can share.
- **Ask the party in chat** posts both lists in party chat: what you are missing, what you can share, and whether everyone has them.
- **Share mine with the party** offers each of your shareable dungeon quests to the group.

### Before you leave
- At the dungeon door, a warning listing quests you could have picked up but have not.
- Inside, a small tracker with the quest items and kills you still need, with counts.
- A reminder after each boss, and a "don't leave yet" alert after the last boss if anything is still missing.
- An alert if you leave without finishing an objective.

## Commands

| Command | What it does |
|---|---|
| `/zd` | Open or close the window |
| `/zd next` | Where do I go next? |
| `/zd guide` | Open your dungeon guide (or pick a dungeon if you have none) |
| `/zd share` | Open quest sharing |
| `/zd check` | Print the missing-quest checklist for the current dungeon |
| `/zd tracker` | Turn the in-dungeon tracker off or on |

## Works with

ZDungeon runs on its own. These addons are optional and each adds something:

| Addon | Adds |
|---|---|
| ZQuest | The Dungeons tab on its guide card, the arrow and waypoints, travel routes and times |
| DungeonJournal (ForeverDungeonJournal) | The gear list |
| Forever Leveling BiS | Upgrade numbers for your spec |
| NeedRoll | A button that opens an item in NeedRoll |

ZDungeon reads the gear list and upgrade numbers from those addons while the game is running. It does not include their data.

## Install

Copy the `ZDungeon` folder into `World of Warcraft\_forever_\Interface\AddOns`, restart the game, and make sure ZDungeon is ticked on the AddOns screen.

## Known gaps

- The Drowned City, Krol'dok Stronghold, Alcaz Prison and Blackmaw Hold show gear only; their quests are not in the quest data yet.
- The "don't leave yet" alert knows the last boss of the original dungeons only.
- Scarlet Monastery, Dire Maul, Stratholme and Blackrock Spire are each one entry, not split by wing.

## Credits and license

Quest data is generated from [QuestieDB](https://github.com/Questie/QuestieDB), which is licensed under the GNU General Public License v3. ZDungeon is released under the same license.

The deep dives are ZDungeon's own text. Their mechanics were checked against the WoW Forever dungeon guides at [Method](https://www.method.gg/wow-forever) and [Warcraft Tavern](https://www.warcrafttavern.com/forever/).

Thanks to the authors of Questie, OpenXP, DungeonJournal, Forever Leveling BiS and NeedRoll. ZDungeon is not affiliated with any of them, or with Blizzard Entertainment.

The `tools` folder holds the scripts that rebuild `Data.lua` from QuestieDB. The game ignores it.
