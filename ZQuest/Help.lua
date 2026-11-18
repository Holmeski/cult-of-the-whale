local _, addon = ...
local L = addon.locale.Get
local H = {}

H[L"I'm missing a lot of exp, why?"] = L[[
You should be grinding mobs between quests, not just moving from objective to objective.

This guide is based on speed - which means less quests to turn in. Grinding from quest to quest makes up for the lost xp.
]]

H[L"Why is my guide missing levels?"] = L[[
The level ranges on our guides are intended for standard exp rates, do not worry about following the leveling brackets while on 20% or 50% exp.

Just follow the guide the best you can.
]]

H[L"Why is my guide skipping lots of steps or zones?"] = L[[
These are inefficient areas that we skip if you are missing quest chains or if you are ahead in levels compared to the guide.
]]

H[L"What are command the line options?"] = L[[
|cff909090/zq|r - Open general addon settings
|cff909090/zq import|r - Open Import Guide interface
|cff909090/zq debug|r - enable debugging output
|cff909090/zq splits|r - Toggle Level Splits on or off, if enabled
|cff909090/zq show||hide||toggle|r - Toggle all enabled frames on or off
|cff909090/zq feedback|r - Report a bug, suggest something, leave a comment or rate ZQuest
|cff909090/zq check|r - Check the guide's waypoints against Questie (|cff909090/zq check fix|r moves wrong ones)
|cff909090/zq bugform|r - Full bug details to paste into a bug report
|cff909090/zq where|r - Smart start: jump to the right guide step for your character
|cff909090/zq catchup|r - List quest chains Smart start skipped and where to get them
|cff909090/zq news|r - Show the ZQuest welcome and what's new window
|cff909090/zq path|r - Arrow paths through cave entrances and ramps (add, done, undo, clear, off/on). /zq path to <zone> leads the arrow to a zone
|cff909090/zq perf|r - Record 30 seconds of play and print how long each part of ZQuest took (for stutter reports)
|cff909090/zq help|r - This output
]]

addon.help = H

local C = {}

C["TomTom"] = {
    ["Reason"] = L"has known incompatibilities with the Waypoint Arrow.",
    ["Recommendation"] = L"Disable it if you're experiencing navigation issues."
}
C["SilverDragon"] = C["TomTom"]
C["TotemTimers"] = C["TomTom"]
C["Leatrix Maps"] = C["TomTom"]

C["Narcissus"] = {
    ["Reason"] = L"has known incompatibilities with Proximity targeting TargetUnit() calls.",
    ["Recommendation"] = L"Install BugSack or disable Targeting -> 'Only show when in range'."
}

addon.compatibility = C
