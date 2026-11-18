# Attribution and changes

ZQuest is a modified version of **OpenXP**, which is itself a modified version of **RestedXP Guides** by RestedXP.
ZQuest renames the addon, adds the ZQuest Purple theme (the default) and its own logo, and keeps everything else
from OpenXP 1.3.59. The notes below describe OpenXP's changes from RestedXP Guides.

- OpenXP: https://github.com/mjared123/OpenXP

- Original: https://github.com/RestedXP/RXPGuides
- Upstream commit this fork starts from: `b9f2e254c1604f70fd6ddca1dae61dd84156cd13` (2026-11-07)
- License: Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (see `LICENSE`).
  ZQuest must stay free and non-commercial and be shared under the same license.

ZQuest and OpenXP are not affiliated with or endorsed by RestedXP. Guide groups and guides that still carry the
RestedXP name were written by RestedXP and are kept here with credit.

## Changes from the original

- Renamed the addon to OpenXP (`OpenXP.toc`, `OpenXP_TBC.toc`, `OpenXP_Vanilla.toc`) and changed the title, notes and author.
- Removed the CurseForge and Wago project IDs so OpenXP never updates through RestedXP's listings.
- Renamed saved variables from `RXP*` to `OXP*` so OpenXP's settings and progress don't overwrite RestedXP's.
- Removed the `lang/` folder of translated guides for now, and turned off the translated-guide switch so every client language loads the English guides.
- Fixed a texture path that pointed at the `RXPGuides` folder.
- Dropped RestedXP's packaging and CI files.
- Added Smart start (`SmartStart.lua`): picks the right guide section and step from the player's level, zone, quest log and completed quests, and skips quest chains whose earlier quests were skipped (`/oxp where`, `/oxp catchup`).
- Added `/oxp` and `/openxp` slash commands, and pointed bug reports at OpenXP's GitHub issues instead of RestedXP's Discord.
- Optional guide card (`OpenXPCard.lua`, Settings > Guide Window > "Use the OpenXP guide card"). Since 1.3.58 the default look is RestedXP's own guide window, themes, arrow and Active Targets frame again. The card has drag-resize, a step list, quest-chain help for steps whose quest isn't in your log, a dial waypoint arrow and an XP line with time to level; while it is on, RestedXP's window runs hidden as the step engine. Visible "RestedXP" titles now say OpenXP; guide group names that RestedXP wrote still carry their name internally.
- Added a welcome / what's new window (`WelcomeFrame.lua`, `/oxp news`).
- New guides written for OpenXP (`Guides/openxp/`, `Guides/openxp-classic/`): Alliance 21-60 and Horde 22-60 for WoW Forever and Classic Era, and dungeon quest guides for both factions. Routes were generated with `tools/build_route.py` and `tools/build_dungeons.py` from public quest facts (quest ids, levels, coordinates). No RestedXP paid guide content is used.
- Optional Questie support: when the separate Questie addon is installed, OpenXP reads its quest data in game for quest chains and levels. Questie's data is not bundled.
- Added quest tooltips for mobs and NPCs (`OpenXPTooltips.lua`), quest icons on map pins, auto loot and max camera distance options, and turned Sell Junk on by default.
- Gave OpenXP its own addon message channel so it doesn't exchange version checks with RestedXP.
- The release zip (`tools/package.py`) only includes the files that load on WoW Forever and Classic Era.
- Removed the files that only load on other WoW versions (Retail, TBC, Wrath, Cata, MoP, Season of Discovery), guides that no Forever or Classic Era guide list loads, unused textures and RestedXP's developer scripts. They remain in RestedXP's repository.
- Added key bindings to target a quest mob or NPC from the Active Targets list.
- ZQuest: the 21-60 routes' class trainer positions and the quest order rules come from Questie's open quest and NPC data (facts such as NPC names, positions and quest prerequisites), worked out with the scripts in `tools/`. No Questie code is included, and ZQuest reads Questie itself only while the game runs.
- Added step history to the guide card with Done / Skipped / Chain missed tags, and made manual step changes stick.

- ZQuest 1.7.0 brings over OpenXP 1.3.60 to 1.3.64 (fixes, the mark-step-done option, quest availability checks, route corrections and the Night Watchman's Torch guide), adapted to ZQuest's reordered routes. OpenXP's Spanish translation and its Thousand Needles reorder are not included.

## Bundled fonts

The `Fonts/` folder holds fonts under the SIL Open Font License 1.1. Each license is in `Fonts/licenses/`.
They are free to bundle, but the fonts themselves are not under CC BY-NC-SA.

- Atkinson Hyperlegible, Regular and Bold: Copyright 2020 Braille Institute of America, Inc. Unmodified.
- Lexend: Copyright 2018 The Lexend Project Authors. Static Regular instance, cut down to Latin, Greek and Cyrillic.
- Open Sans: Copyright 2020 The Open Sans Project Authors. Static Regular instance, cut down to Latin, Greek and Cyrillic.
- Roboto: Copyright 2011 The Roboto Project Authors. Static Regular instance, cut down to Latin, Greek and Cyrillic.
- Noto Sans: Copyright 2022 The Noto Project Authors. Static Regular instance, cut down to Latin, Greek and Cyrillic.
- Fira Sans: Copyright 2012-2015 The Mozilla Foundation and Telefonica S.A. Cut down to Latin, Greek and Cyrillic.
