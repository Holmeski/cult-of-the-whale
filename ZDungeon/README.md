# ZDungeon

A dungeon planner for World of Warcraft: Forever. For every 5-player dungeon it answers four questions: which quests are there and what are they worth, is the trip worth the time, what gear drops that I can use, and have I got everything before I leave.

Type `/zd` to open it.

Status: early release. Built and tested outside the game; in-game testing is in progress.

## What it does

### Quests and XP
- Every quest for each dungeon, for your faction and class, with its level and the XP it pays at your level.
- Status for each quest: done, in your log, available, behind a chain, or needs a higher level.
- For chain quests, the steps you have to do first and the XP they pay on the way.
- Who gives each quest and where, with a button to show it on the map.
- XP comes from the game itself where the game will answer. Estimates are marked `~`.

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

### Before you leave
- At the dungeon door, a warning listing quests you could have picked up but have not.
- Inside, a small tracker with the quest items and kills you still need, with counts.
- A reminder after each boss, and a "don't leave yet" alert after the last boss if anything is still missing.
- An alert if you leave without finishing an objective.

## Commands

| Command | What it does |
|---|---|
| `/zd` | Open or close the window |
| `/zd check` | Print the missing-quest checklist for the current dungeon |
| `/zd tracker` | Turn the in-dungeon tracker off or on |

## Works with

ZDungeon runs on its own. These addons are optional and each adds something:

| Addon | Adds |
|---|---|
| ZQuest | Travel routes and times, and a button that opens the dungeon walkthrough |
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

Thanks to the authors of Questie, OpenXP, DungeonJournal, Forever Leveling BiS and NeedRoll. ZDungeon is not affiliated with any of them, or with Blizzard Entertainment.

The `tools` folder holds the scripts that rebuild `Data.lua` from QuestieDB. The game ignores it.
