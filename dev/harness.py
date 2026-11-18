# Offline test harness for ZDungeon: loads the addon under a mock WoW API
# and prints every dungeon guide it writes. Run from the repo root:
#   python3 dev/harness.py <level> zq gear      (env ZD_SIDE=Horde|Alliance, ZD_CLASS=MAGE)
import sys
from lupa import luajit21 as lupa
rt = lupa.LuaRuntime(unpack_returned_tuples=True)
LEVEL = int(sys.argv[1]) if len(sys.argv) > 1 else 27
ZQMODE = (sys.argv[2] if len(sys.argv) > 2 else "zq")
ZQ = ZQMODE in ("zq", "zqold")
GEAR = (sys.argv[3] if len(sys.argv) > 3 else "gear") == "gear"
import os
_SIDE, _CLASS = os.environ.get('ZD_SIDE', 'Horde'), os.environ.get('ZD_CLASS', 'MAGE')
rt.execute(('''
local LEVEL, SIDE, CLASS = %d, "__SIDE__", "__CLASS__"
DONE = {[5722]=true, [880]=true}
LOG = {[1486]=2, [962]=3}
OBJ = {[1486] = {{text="Deviate Hide: 14/20", finished=false}}, [962] = {{text="Serpentbloom: 10/10", finished=true}}}
LIVE = {[1486]=3850, [962]=3250, [1487]=4900, [914]=5250, [959]=3250, [6981]=6300, [1491]=3250, [1489]=700, [1490]=280}
INSTANCE = nil; SUBZONE = ""; GHOST = false; CLOCK = 1000
local function mock(kind)
  local o = {__kind = kind, shown = true, scripts = {}, text = nil}
  return setmetatable(o, {__index = function(t, k)
    if k == "SetText" then return function(s, v) assert(v == nil or type(v) == "string" or type(v) == "number", "SetText type") s.text = v end end
    if k == "GetText" then return function(s) return s.text end end
    if k == "SetScript" then return function(s, n, fn) s.scripts[n] = fn end end
    if k == "Show" then return function(s) s.shown = true end end
    if k == "Hide" then return function(s) s.shown = false end end
    if k == "SetShown" then return function(s, v) assert(type(v) == "boolean", "SetShown needs boolean") s.shown = v end end
    if k == "IsShown" then return function(s) return s.shown end end
    if k == "SetChecked" then return function(s, v) s.checked = v end end
    if k == "GetChecked" then return function(s) return s.checked end end
    if k == "CreateFontString" or k == "CreateTexture" then return function() return mock(k) end end
    if k == "GetStringHeight" then return function() return 80 end end
    if k == "GetPoint" then return function() return "CENTER", nil, "CENTER", 0, 0 end end
    return function() end
  end})
end
FRAMES = {}
function CreateFrame(t, name, parent, tpl) local f = mock(t) if name then _G[name] = f end FRAMES[#FRAMES+1] = f return f end
UIParent = mock("UIParent"); UISpecialFrames = {}
BackdropTemplateMixin = {}
function UnitFactionGroup() return SIDE end
function UnitClass() return "Mage", CLASS end
function UnitLevel() return LEVEL end
function UnitXPMax() return 23200 end
function GetMaxPlayerLevel() return 60 end
function GetTime() return CLOCK end
function UnitName() return "Raistlin" end
function GetRealmName() return "Test" end
function UnitIsDeadOrGhost() return GHOST end
function IsInInstance() if INSTANCE then return true, "party" end return false, "none" end
function GetInstanceInfo() if INSTANCE then return INSTANCE[1], "party", 1, "", 5, 0, false, INSTANCE[2] end return "Kalimdor", "none", 0, "", 0, 0, false, 1 end
function GetSubZoneText() return SUBZONE end
function GetRealZoneText() return "The Barrens" end
REQUESTED = 0
C_QuestLog = {IsPushableQuest = function(id) return id ~= 962 end, IsQuestFlaggedCompleted = function(id) return DONE[id] or false end, IsOnQuest = function(id) return LOG[id] ~= nil end,
  GetQuestObjectives = function(id) return OBJ[id] or {} end, RequestLoadQuestByID = function(id) REQUESTED = REQUESTED + 1 end}
function GetNumQuestLogEntries() return 3, 2 end
function GetQuestLogTitle(i) if i == 1 then return "Barrens", 0, nil, true end if i == 2 then return "Deviate Hides", 17, nil, false, false, false, 0, 1486 end return "Serpentbloom", 18, nil, false, false, false, 0, 962 end
function GetQuestLogRewardXP(id) return LIVE[id] or 0 end
C_Map = {GetMapInfo = function(m) return {name = "Zone" .. m} end}
C_Timer = {After = function(t, fn) fn() end}
SlashCmdList = {}
GROUPED = false CHAT = {} PUSHED = {}
function IsInGroup() return GROUPED end function IsInRaid() return false end
function SendChatMessage(msg, chan) assert(#msg <= 255, 'chat line too long') CHAT[#CHAT+1] = chan .. ': ' .. msg end
function QuestLogPushQuest() PUSHED[#PUSHED+1] = SELECTED end function SelectQuestLogEntry(i) SELECTED = i end
GEAR_ADDONS = %s

ITEMS = { -- id -> {classID, subID, equipLoc, minLevel}
  [6460]={4,3,"INVTYPE_WAIST",18}, [10410]={4,2,"INVTYPE_LEGS",18}, [6465]={4,1,"INVTYPE_ROBE",18}, [252782]={9,1,"",0},
  [6480]={4,2,"INVTYPE_LEGS",0}, [918]={1,0,"INVTYPE_BAG",0}, [10413]={4,2,"INVTYPE_HAND",17}, [6461]={4,1,"INVTYPE_SHOULDER",30},
  [5243]={2,19,"INVTYPE_RANGEDRIGHT",17}, [6472]={2,5,"INVTYPE_2HWEAPON",19}, [777]={4,1,"INVTYPE_FEET",15}, [778]={4,0,"INVTYPE_FINGER",15},
}
INVTYPE_WAIST="Waist" INVTYPE_LEGS="Legs" INVTYPE_ROBE="Chest" INVTYPE_HAND="Hands" INVTYPE_SHOULDER="Shoulder" INVTYPE_RANGEDRIGHT="Ranged" INVTYPE_2HWEAPON="Two-Hand" INVTYPE_FEET="Feet" INVTYPE_FINGER="Finger" INVTYPE_BAG="Bag"
function GetItemInfoInstant(id) local i = ITEMS[id] if not i then return nil end return id, "t", "s", i[3], 1, i[1], i[2] end
function GetItemInfo(id) local i = ITEMS[id] if not i then return nil end return "n", "l", 3, 20, i[4] end
GameTooltip = setmetatable({}, {__index = function() return function() end end})
NR = {}
function NeedRoll_ShowItem(id) NR[#NR+1] = "item " .. tostring(id) return true end
function NeedRoll_ShowLoot(n) NR[#NR+1] = "loot " .. tostring(n) return true end
if GEAR_ADDONS then
  ForeverDungeonJournal_NS = {DB = {
    ["Wailing Caverns"] = {
      quests = {{id = 1486, name = "Deviate Hides", faction = "Both", rewardItems = {{6480, "Slick Deviate Leggings", 2}, {918, "Deviate Hide Pack", 1}}},
                {id = 962, name = "Serpentbloom", faction = "Horde", rewardItems = {{777, "Apothecary Slippers", 2}}},
                {id = 1, name = "Alliance Only", faction = "Alliance", rewardItems = {{778, "Blue Ring", 2}}}},
      bosses = {{name = "Lord Cobrahn", loot = {{6460, "Cobrahn's Grasp", "Waist, Mail", 3}, {10410, "Leggings of the Fang", "Legs, Leather", 3}, {6465, "Robe of the Moccasin", "Chest, Cloth", 3}, {252782, "Pattern: Wisdom's Leather Gloves", "Recipe, Leatherworking", 3}}},
                {description = "Rare spawn.", rare = true},
                {name = "Lord Serpentis", loot = {{6461, "Serpent's Shoulders", "Shoulder, Cloth", 3}, {5243, "Firebelcher", "Ranged, Wand", 3}, {6472, "Stinging Viper", "Two-Hand, Mace", 3}, {99999, "Unknown To Game Robe", "Chest, Cloth", 3}, {99998, "Unknown Plate", "Chest, Plate", 3}}},
                {name = "Trash Drops", trash = true, loot = {{10413, "Gloves of the Fang", "Hands, Leather", 3, "Druid of the Fang"}}}},
    },
    ["Scarlet Monastery: Library"] = {bosses = {{name = "Arcanist Doan", loot = {{6465, "Robe of Doan", "Chest, Cloth", 3}}}}},
    ["Lower Blackrock Spire"] = {bosses = {{name = "Wyrmthalak", loot = {{6461, "Mantle", "Shoulder, Cloth", 3}}}}},
  }}
  local GAIN = {[6465] = 12.4, [777] = 3.1, [5243] = -2.5}
  CHANGED = nil
  ForeverLevelingBiS_API = {version = 2,
    GetGain = function(id) if id == 6461 then return nil end if id == 99999 then return nil, true end return GAIN[id] or 0 end,
    ScoreItem = function(id) return (GAIN[id] or 0) + 20 end,
    GetSpec = function() return "frost", "held", "MAGE" end,
    OnChanged = function(fn) CHANGED = fn end}
end
PRINTS = {}
function print(...) PRINTS[#PRINTS+1] = table.concat({...}, " ") end
RAID = {}
RaidWarningFrame = {}; ChatTypeInfo = {RAID_WARNING = {}}
function RaidNotice_AddMessage(f, msg, info) assert(type(msg) == "string" and type(info) == "table") RAID[#RAID+1] = msg end
function PlaySound() end
ARROW = {}
RXPGuides = {HasDungeonGuide = function(n) return n ~= "Uldaman" end, LoadDungeonGuide = function(n) return true end,
  SetArrowTarget = function(m, x, y, title) ARROW[#ARROW+1] = "set " .. m .. " " .. tostring(title) return true end, ClearArrowTarget = function() ARROW[#ARROW+1] = "clear" return true end}
GUIDES = {} LOADED = {}
if %s then
  RXPGuides.RegisterGuide = function(text) local n = text:match("#name ([^\\n]+)") local g = text:match("#group ([^\\n]+)") GUIDES[g .. "||" .. n] = text return true end
  RXPGuides.HasGuide = function(g, n) return GUIDES[g .. "||" .. n] ~= nil end
  RXPGuides.LoadGuideByName = function(g, n) if not GUIDES[g .. "||" .. n] then return false end LOADED[#LOADED+1] = n return true end
end
if %s then
  RXPGuides.TravelEstimate = function(m, x, y, title) return {secs = 540 + m %% 7 * 60, legs = {{kind="walk", text="Go to the Orgrimmar flight master"}, {kind="fly", text="Fly to Crossroads"}, {kind="walk", text="Head into Zone" .. m}}, newFlights = {"Ratchet"}} end
end
''' % (LEVEL, "true" if GEAR else "false", "true" if ZQMODE == "zq" else "false", "true" if ZQ else "false")).replace("__SIDE__", _SIDE).replace("__CLASS__", _CLASS))
ns = rt.eval('{}')
for f in ('Data.lua', 'Tips.lua', 'Core.lua'):
    src = open('ZDungeon/' + f, encoding='utf-8').read()
    fn = rt.eval('function(src, name) return assert(loadstring(src, name)) end')(src, '@' + f)
    fn('ZDungeon', ns)
out = rt.eval('''function(ns)
  local log = {}
  local function P(s) log[#log+1] = s end
  local function fire(...) for _, f in ipairs(FRAMES) do local h = f.scripts.OnEvent if h then h(f, ...) end end end
  local function flush(tag) for _, s in ipairs(PRINTS) do P("  [chat] " .. s) end for _, s in ipairs(RAID) do P("  [RAID WARNING] " .. s) end PRINTS, RAID = {}, {} end
  fire("ADDON_LOADED", "ZDungeon")
  SlashCmdList.ZDUNGEON("")
  local f = ZDungeonFrame
  assert(f and f:IsShown(), "window not shown")
  local function dump(tag)
    P("## " .. tag .. " :: " .. tostring(f.header:GetText()))
    P("   " .. tostring(f.summary:GetText()))
    P("   " .. tostring(f.travel:GetText()))
    P("   " .. tostring(f.rate:GetText()))
    for i, r in ipairs(f.rows) do if r.shown and rawget(r,"row") then
      local c = {} for j, cell in ipairs(r.cells) do c[j] = tostring(cell:GetText()) end
      P("   " .. table.concat(c, " | ")) end end
    P("   more: " .. tostring(f.more:GetText()))
  end
  dump("initial")
  local n = 0
  local function each(fn) for _, b in ipairs(f.dungeonButtons) do if b.shown and rawget(b,"dungeon") then fn(b) end end end
  each(function(b)
    n = n + 1
    b.scripts.OnClick(b)
    for _, r in ipairs(f.rows) do if r.shown and rawget(r,"row") then r.scripts.OnClick(r) assert(type(f.detail:GetText()) == "string") end end
    for _, h in ipairs(f.colHeaders) do h.scripts.OnClick(h) h.scripts.OnClick(h) end
  end)
  f.colHeaders[3].scripts.OnClick(f.colHeaders[3])
  each(function(b) P(("[%s] %s"):format(tostring(b.name:GetText()), tostring(b.xp:GetText()))) end)
  P("dungeons shown: " .. n .. "  xp requests: " .. REQUESTED)
  -- per-hour mode
  for _, fr in ipairs(FRAMES) do if fr.scripts.OnClick and fr ~= f then end end
  each(function(b) if b.dungeon.key == "WC" or b.dungeon.key == "EXCAV" or b.dungeon.key == "ULDA" then
    b.scripts.OnClick(b) dump(b.dungeon.key)
    for _, r in ipairs(f.rows) do if r.shown and rawget(r,"row") and (r.row.status == "chain" or r.row.status == "log") then r.scripts.OnClick(r) P("-- detail --\\n" .. f.detail:GetText()) end end
    P("map button: " .. tostring(f.mapButton.shown) .. " guide button: " .. tostring(f.guideButton.shown) .. " entrance: " .. tostring(f.entranceButton.shown))
  end end)
  f.entranceButton.scripts.OnClick(f.entranceButton) f.mapButton.scripts.OnClick(f.mapButton) f.guideButton.scripts.OnClick(f.guideButton)
  f.otherClasses.checked = true f.otherClasses.scripts.OnClick(f.otherClasses)
  f.hideDone.checked = true f.hideDone.scripts.OnClick(f.hideDone)
  for _, fr in ipairs(FRAMES) do local w = fr.scripts.OnMouseWheel if w then w(fr, -1) w(fr, 1) end end
  flush()

  -- gear view
  P("== GEAR ==")
  f.gearMode.scripts.OnClick(f.gearMode)
  local function gdump(tag)
    P("## " .. tag .. " :: " .. tostring(f.header:GetText()))
    P("   " .. tostring(f.summary:GetText()))
    for i, r in ipairs(f.rows) do if r.shown and rawget(r,"row") then
      local c = {} for j = 1, 4 do c[j] = tostring(r.cells[j]:GetText()) end
      P("   " .. table.concat(c, " | ")) end end
    P("   more: " .. tostring(f.more:GetText()) .. " | loot button: " .. tostring(f.lootButton.shown) .. " map: " .. tostring(f.mapButton.shown))
  end
  each(function(b) if b.dungeon.key == "WC" then b.scripts.OnClick(b) end end)
  gdump("WC gear")
  for _, r in ipairs(f.rows) do if r.shown and rawget(r,"row") then r.scripts.OnClick(r) r.scripts.OnEnter(r) r.scripts.OnLeave(r) P("-- " .. (f.detail:GetText():gsub("\\n", " / "))) end end
  f.showUnusable.checked = true f.showUnusable.scripts.OnClick(f.showUnusable) gdump("WC incl. unusable")
  f.showUnusable.checked = false f.showUnusable.scripts.OnClick(f.showUnusable)
  f.upgradesOnly.checked = true f.upgradesOnly.scripts.OnClick(f.upgradesOnly) gdump("WC upgrades only")
  f.upgradesOnly.checked = false f.upgradesOnly.scripts.OnClick(f.upgradesOnly)
  for i = 1, 4 do f.colHeaders[i].scripts.OnClick(f.colHeaders[i]) f.colHeaders[i].scripts.OnClick(f.colHeaders[i]) end
  f.lootButton.scripts.OnClick(f.lootButton) P("needroll: " .. table.concat(NR, ", "))
  each(function(b) b.scripts.OnClick(b) end)
  each(function(b) if b.dungeon.key == "SM" or b.dungeon.key == "BRS" or b.dungeon.key == "RFC" then b.scripts.OnClick(b) gdump(b.dungeon.key) end end)
  if CHANGED then CHANGED() end
  fire("GET_ITEM_INFO_RECEIVED", 6465, true)
  f.questMode.scripts.OnClick(f.questMode)
  each(function(b) if b.dungeon.key == "WC" then b.scripts.OnClick(b) end end)
  dump("back to quests")
  P("checks: hideDone " .. tostring(f.hideDone.shown) .. " upgradesOnly " .. tostring(f.upgradesOnly.shown) .. " cell5 " .. tostring(f.rows[1].cells[5].shown))
  flush()



  P("== QUEST SHARING ==")
  if not f:IsShown() then SlashCmdList.ZDUNGEON("") end
  each(function(b) if b.dungeon.key == "WC" then b.scripts.OnClick(b) end end)
  ZDungeonDB.zq = nil
  SlashCmdList.ZDUNGEON("share")
  P(tostring(ZDungeonShare.title:GetText())) P(tostring(ZDungeonShare.body:GetText()))
  ZDungeonShare.ask.scripts.OnClick(ZDungeonShare.ask) ZDungeonShare.give.scripts.OnClick(ZDungeonShare.give) flush()
  GROUPED = true
  ZDungeonShare.ask.scripts.OnClick(ZDungeonShare.ask) ZDungeonShare.give.scripts.OnClick(ZDungeonShare.give)
  for _, c in ipairs(CHAT) do P("  [" .. c .. "]") end P("pushed log entries: " .. table.concat(PUSHED, ",")) flush()
  CHAT = {} each(function(b) if b.dungeon.key == "BRD" or b.dungeon.key == "BRS" then b.scripts.OnClick(b) ZDungeonShare.ask.scripts.OnClick(ZDungeonShare.ask) end end)
  P("long lists split into " .. #CHAT .. " lines") GROUPED = false
  each(function(b) if b.dungeon.key == "WC" then b.scripts.OnClick(b) end end)
  P("== ZQUEST TAB ==")
  P("provider: " .. tostring(RXPGuides.DungeonTab and RXPGuides.DungeonTab.group))
  if RXPGuides.RegisterGuide then
    RXPGuides.DungeonTab.Open() P("tab with nothing saved opens Where next: " .. tostring(ZDungeonNext and ZDungeonNext.shown))
    each(function(b) if true then b.scripts.OnClick(b) f.planButton.scripts.OnClick(f.planButton) end end)
    P("loaded: " .. table.concat(LOADED, " | "))
    for k, text in pairs(GUIDES) do P("---- " .. k) P(text) end
    P("own card shown: " .. tostring(ZDungeonCard and ZDungeonCard.shown or false))
    LOADED = {} RXPGuides.DungeonTab.Open() P("tab reloads: " .. table.concat(LOADED, " | "))
    P("saved: " .. tostring(ZDungeonDB.zq["Raistlin-Test"].name))
    flush()
  end
  -- guide card, where next, level up
  P("== GUIDE CARD ==")
  if RXPGuides.RegisterGuide and not ZDungeonCard then
    local function btn(fn) return {shown = false, scripts = {OnClick = fn or function() end}, GetText = function() return "(zquest has the guide)" end} end
    ZDungeonCard = {shown = false, title = btn(), body = btn(), mapButton = btn(), arrowButton = btn(), openButton = btn(),
      nextButton = btn(function() SlashCmdList.ZDUNGEON("next") end)}
  end
  local function cdump(tag) P("# " .. tag .. " :: " .. tostring(ZDungeonCard and ZDungeonCard.shown and ZDungeonCard.title:GetText())) if ZDungeonCard and ZDungeonCard.shown then P(tostring(ZDungeonCard.body:GetText())) P("  map button: " .. tostring(ZDungeonCard.mapButton.shown)) end end
  SlashCmdList.ZDUNGEON("")  -- reopen window
  each(function(b) if b.dungeon.key == "WC" then b.scripts.OnClick(b) end end)
  f.planButton.scripts.OnClick(f.planButton)
  cdump("WC plan started")
  ZDungeonCard.mapButton.scripts.OnClick(ZDungeonCard.mapButton)
  LOG[1487] = 4 LOG[959] = 5 fire("QUEST_LOG_UPDATE") cdump("picked two up (not in fake log scan, so unchanged is fine)")
  DONE[1489] = true DONE[1490] = true fire("QUEST_LOG_UPDATE") cdump("chain steps done")
  INSTANCE = {"Wailing Caverns", 43} fire("PLAYER_ENTERING_WORLD") cdump("inside") P("tracker hidden while card shows: " .. tostring(not (ZDungeonTracker and ZDungeonTracker.shown)))
  INSTANCE = nil fire("PLAYER_ENTERING_WORLD")
  for _, id in ipairs({1486, 962, 1487, 959, 914, 6981, 1491, 865}) do DONE[id] = true end
  fire("QUEST_TURNED_IN") cdump("all done") flush()
  SlashCmdList.ZDUNGEON("guide") P("card hidden by /zd guide: " .. tostring(not ZDungeonCard.shown)) SlashCmdList.ZDUNGEON("guide") P("card back: " .. tostring(ZDungeonCard.shown))
  ZDungeonCard.openButton.scripts.OnClick(ZDungeonCard.openButton)
  P("== WHERE NEXT ==")
  ZDungeonCard.nextButton.scripts.OnClick(ZDungeonCard.nextButton)
  local nf = ZDungeonNext
  P(tostring(nf.note:GetText()))
  for i = 1, 3 do local o = nf.options[i] if o.shown then P(tostring(o.text:GetText())) P("") end end
  if nf.options[1].shown then nf.options[1].open.scripts.OnClick(nf.options[1].open) P("details opened on: " .. tostring(f.header:GetText())) end
  SlashCmdList.ZDUNGEON("next") if nf.options[2].shown then nf.options[2].go.scripts.OnClick(nf.options[2].go) cdump("plan from option 2") end
  P("saved plan key: " .. tostring(ZDungeonDB.plans and ZDungeonDB.plans["Raistlin-Test"] and ZDungeonDB.plans["Raistlin-Test"].key))
  P("== LEVEL UP ==")
  for _, lv in ipairs({21, 24, 26, 28, 29, 30, 60}) do fire("PLAYER_LEVEL_UP", lv) P("level " .. lv .. ":") flush() end

  P("== DEEP DIVE / ARROW / CHAIN LEVEL ==")
  if not f:IsShown() then SlashCmdList.ZDUNGEON("") end
  f.tipsMode.scripts.OnClick(f.tipsMode)
  each(function(b) if b.dungeon.key == "EXCAV" then b.scripts.OnClick(b) end end)
  P(tostring(f.header:GetText())) P(tostring(f.tipsText:GetText()))
  P("detail hidden: " .. tostring(not f.detailFrame.shown) .. " rows hidden: " .. tostring(not f.rows[1].shown))
  each(function(b) b.scripts.OnClick(b) assert(type(f.tipsText:GetText()) == "string") end)
  each(function(b) if b.dungeon.key == "ULDA" then b.scripts.OnClick(b) P(tostring(f.tipsText:GetText())) end end)
  for _, fr in ipairs(FRAMES) do local w = fr.scripts.OnMouseWheel if w then w(fr, -1) w(fr, 1) end end
  f.gearMode.scripts.OnClick(f.gearMode) P("gear after tips, headers shown: " .. tostring(f.colHeaders[1].shown) .. " detail: " .. tostring(f.detailFrame.shown))
  f.questMode.scripts.OnClick(f.questMode) P("quests after tips, cell5: " .. tostring(f.rows[1].cells[5].shown) .. " tips hidden: " .. tostring(not f.tipsFrame.shown))
  each(function(b) if b.dungeon.key == "DALA" then b.scripts.OnClick(b) dump("DALA") f.planButton.scripts.OnClick(f.planButton) end end)
  cdump("DALA plan")
  ZDungeonCard.arrowButton.scripts.OnClick(ZDungeonCard.arrowButton) P("arrow button: " .. tostring(ZDungeonCard.arrowButton:GetText()))
  ZDungeonCard.arrowButton.scripts.OnClick(ZDungeonCard.arrowButton)
  SlashCmdList.ZDUNGEON("guide") SlashCmdList.ZDUNGEON("guide")
  P("arrow calls: " .. table.concat(ARROW, " | "))
  for _, id in ipairs({1486, 962, 1487, 959, 914, 6981, 1491, 865, 1489, 1490}) do DONE[id] = nil end LOG[1487] = nil LOG[959] = nil
  SlashCmdList.ZDUNGEON("guide")
  -- standing at the door
  P("== at the Wailing Caverns door ==")
  SUBZONE = "Wailing Caverns" fire("ZONE_CHANGED") flush()
  P("tracker shown: " .. tostring(ZDungeonTracker and ZDungeonTracker.shown)) P(tostring(ZDungeonTracker and ZDungeonTracker.body:GetText()))
  P("== zone in ==")
  INSTANCE = {"Wailing Caverns", 43} SUBZONE = "" CLOCK = CLOCK + 60 fire("PLAYER_ENTERING_WORLD") flush()
  P(tostring(ZDungeonTracker.title:GetText())) P(tostring(ZDungeonTracker.body:GetText()))
  P("== boss 1 ==") CLOCK = CLOCK + 600 fire("ENCOUNTER_END", 585, "Lady Anacondra", 1, 5, 1) fire("BOSS_KILL", 585, "Lady Anacondra") flush()
  P("== wipe (not a kill) ==") CLOCK = CLOCK + 60 fire("ENCOUNTER_END", 586, "Lord Cobrahn", 1, 5, 0) flush()
  P("== corpse run ==") GHOST = true INSTANCE = nil fire("PLAYER_ENTERING_WORLD") flush() GHOST = false INSTANCE = {"Wailing Caverns", 43} fire("PLAYER_ENTERING_WORLD") flush()
  P("== final boss, hides short ==") CLOCK = CLOCK + 1500 fire("ENCOUNTER_END", 592, "Mutanus the Devourer", 1, 5, 1) flush()
  P("== leave without them ==") INSTANCE = nil CLOCK = CLOCK + 120 fire("PLAYER_ENTERING_WORLD") flush()
  P("run times: " .. tostring(ZDungeonDB.runs and ZDungeonDB.runs.WC and ZDungeonDB.runs.WC.avg))
  P("== second run, hides done ==") OBJ[1486][1] = {text="Deviate Hide: 20/20", finished=true}
  INSTANCE = {"Wailing Caverns", 43} CLOCK = CLOCK + 60 fire("PLAYER_ENTERING_WORLD") CLOCK = CLOCK + 900 fire("BOSS_KILL", 592, "Mutanus the Devourer") INSTANCE = nil fire("PLAYER_ENTERING_WORLD") flush()
  P("== new dungeon by name ==") INSTANCE = {"Excavation Site: Wetlands", 2999} fire("PLAYER_ENTERING_WORLD") flush() P(tostring(ZDungeonTracker.title:GetText())) INSTANCE = nil fire("PLAYER_ENTERING_WORLD") flush()
  SlashCmdList.ZDUNGEON("check") SlashCmdList.ZDUNGEON("tracker") SlashCmdList.ZDUNGEON("tracker") flush()
  fire("QUEST_LOG_UPDATE") fire("QUEST_DATA_LOAD_RESULT", 1486, true) fire("PLAYER_LEVEL_UP", 28)
  SlashCmdList.ZDUNGEON("") assert(not f:IsShown())
  return table.concat(log, "\\n")
end''')(ns)
print(out)
