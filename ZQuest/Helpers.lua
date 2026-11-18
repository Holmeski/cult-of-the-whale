-- Helpers: small notices that keep you moving, using Questie's NPC data
--
-- Each check watches one thing and, when it needs you, shows a notice and
-- (where there's somewhere to go) points the arrow at the nearest friendly
-- NPC that can help. One notice shows at a time, the most urgent first:
--
--   questlog  quest log too full for the quests this step gives you
--   repair    gear close to breaking: nearest vendor who repairs
--   bags      bags nearly full: nearest vendor (junk sells itself there)
--   trainer   new spells at this level: nearest trainer for your class
--   ammo      Hunters low on arrows or bullets: nearest ammo vendor
--   food      low on food and drink: nearest innkeeper or food vendor
--   sethome   this part of the guide is based in a town your Hearthstone
--             isn't set to: the innkeeper there (only once you're nearby)
--   hearth    your Hearthstone gets you to the next step faster than going
--             there yourself
--
-- Opening the right window (vendor, trainer) clears a notice; Dismiss hides
-- it until the problem goes away and comes back. Each check can be turned
-- off in Settings. NPCs come from Questie, read while the game runs; without
-- Questie the bag check falls back to vendors in the guide.

local _, addon = ...
local L = addon.locale.Get
local fmt = string.format
local HBD = LibStub("HereBeDragons-2.0")

local hp = {}
addon.helpers = hp

-- npcFlags as Questie stores them (classic server values)
local FLAG = {VENDOR = 4, FLIGHT = 8, TRAINER = 16, INNKEEPER = 128, REPAIR = 16384}
hp.FLAG = FLAG
local HEARTHSTONE = 6948
local QUEST_LOG_MAX = 20
local HOME_NEAR = 400 -- yards: offer to set your Hearthstone once this close to the innkeeper

local function Profile()
    return addon.settings and addon.settings.profile
end

local OFF_BY_DEFAULT = {zqTrainerCheck = true}
local function On(key)
    local p = Profile()
    if OFF_BY_DEFAULT[key] then return p and p[key] == true end
    return not p or p[key] ~= false
end

local function Opt(key, default)
    local p = Profile()
    return p and p[key] or default
end

local function band(a, b)
    return bit and bit.band(a or 0, b) ~= 0
end

---------------------------------------------------------------------------
-- NPC index from Questie: vendors, trainers, innkeepers (built once, in the
-- background, a few hundred NPCs per frame)
---------------------------------------------------------------------------

hp.npcs = nil -- list of {name, sub, flags, map, x, y}
local building

local function QuestieParts()
    local loader = _G.QuestieLoader
    if not (loader and loader.ImportModule) then return end
    local okD, db = pcall(loader.ImportModule, loader, "QuestieDB")
    local okZ, zdb = pcall(loader.ImportModule, loader, "ZoneDB")
    if okD and db and okZ and zdb then return db, zdb end
end

local function Query(db, id, key)
    if db.QueryNPCSingle then
        local ok, v = pcall(db.QueryNPCSingle, id, key)
        if ok then return v end
    end
    local npc = addon.card and addon.card.QGet and addon.card.QGet("NPC", id)
    return npc and npc[key]
end

-- Questie's NPC id list is either {id, id, ...} or {[id] = something}
local function IdList(t)
    local out = {}
    if type(t) ~= "table" then return out end
    if type(t[1]) == "number" then
        for _, id in ipairs(t) do out[#out + 1] = id end
    else
        for id in pairs(t) do if type(id) == "number" then out[#out + 1] = id end end
    end
    return out
end

local WANT = FLAG.VENDOR + FLAG.TRAINER + FLAG.INNKEEPER + FLAG.REPAIR

function hp.BuildIndex(done)
    if hp.npcs or building then return end
    local db, zdb = QuestieParts()
    if not db then return end
    local queue = IdList(db.NPCPointers or db.npcData)
    if #queue == 0 then return end
    building = true
    local faction = UnitFactionGroup and UnitFactionGroup("player") == "Horde" and "H" or "A"
    local list, i = {}, 1
    local function Step()
        local stop = math.min(i + 400, #queue)
        for k = i, stop do
            local id = queue[k]
            local flags = Query(db, id, "npcFlags")
            if type(flags) == "number" and band(flags, WANT) then
                local friendly = Query(db, id, "friendlyToFaction")
                if type(friendly) == "string" and friendly:find(faction) then
                    local spawns = Query(db, id, "spawns")
                    local name = Query(db, id, "name") or "?"
                    local sub = Query(db, id, "subName")
                    for area, pts in pairs(type(spawns) == "table" and spawns or {}) do
                        local okM, map = pcall(zdb.GetUiMapIdByAreaId, zdb, area)
                        if okM and map and map > 0 and type(pts) == "table" then
                            for _, pt in ipairs(pts) do
                                if pt[1] and pt[1] >= 0 then
                                    list[#list + 1] = {name, sub, flags, map, pt[1], pt[2]}
                                end
                            end
                        end
                    end
                end
            end
        end
        i = stop + 1
        if i <= #queue then
            C_Timer.After(0, Step)
        else
            hp.npcs, building = list, nil
            if done then done() end
            hp.Update()
        end
    end
    C_Timer.After(0, Step)
end

-- World position of an index entry (worked out once)
local function World(n)
    if n.wx == nil then
        local wx, wy, wi = HBD:GetWorldCoordinatesFromZone(n[5] / 100, n[6] / 100, n[4])
        n.wx, n.wy, n.wi = wx or false, wy, wi
    end
    if n.wx then return n.wx, n.wy, n.wi end
end

-- Nearest NPC (same continent) that match(n) accepts: target, yards
function hp.Nearest(match, fromX, fromY, fromInst)
    local px, py, inst = fromX, fromY, fromInst
    if not px then px, py, inst = HBD:GetPlayerWorldPosition() end
    if not (px and hp.npcs) then return end
    local best, bestD
    for _, n in ipairs(hp.npcs) do
        if match(n) then
            local wx, wy, wi = World(n)
            if wx and wi == inst then
                local d = HBD:GetWorldDistance(inst, px, py, wx, wy)
                if d and (not bestD or d < bestD) then best, bestD = n, d end
            end
        end
    end
    if best then
        local title = best[1] .. (best[2] and best[2] ~= "" and (" <" .. best[2] .. ">") or "")
        return {wx = best.wx, wy = best.wy, instance = best.wi, map = best[4], title = title, npc = best}, bestD
    end
end

local function SubHas(n, words)
    local sub = n[2]
    if type(sub) ~= "string" then return false end
    for _, w in ipairs(words) do
        if sub:find(w, 1, true) then return true end
    end
    return false
end

-- Vendors, innkeepers and Hearthstone spots in the current guide (no Questie)
local function GuideVendors()
    local out = {}
    local guide = addon.currentGuide
    for _, step in ipairs(guide and guide.steps or {}) do
        local g, sells
        for _, e in ipairs(step.elements or {}) do
            if e.wx and e.zone and not g then g = e end
            if e.tag == "vendor" or e.tag == "home" then sells = true end
            for _, t in ipairs(type(e.targets) == "table" and e.targets or {}) do
                if type(t) == "string" and t:find("Innkeeper") then sells = true end
            end
        end
        if g and sells then out[#out + 1] = g end
    end
    return out
end

local function NearestGuideVendor()
    local px, py, inst = HBD:GetPlayerWorldPosition()
    if not px then return end
    local best, bestD
    for _, g in ipairs(GuideVendors()) do
        if g.instance == inst then
            local d = HBD:GetWorldDistance(inst, px, py, g.wx, g.wy)
            if d and (not bestD or d < bestD) then best, bestD = g, d end
        end
    end
    if best then return {wx = best.wx, wy = best.wy, instance = best.instance, title = L("Vendor")}, bestD end
end

---------------------------------------------------------------------------
-- What the player has
---------------------------------------------------------------------------

local NumFree = (C_Container and C_Container.GetContainerNumFreeSlots) or _G.GetContainerNumFreeSlots
local NumSlots = (C_Container and C_Container.GetContainerNumSlots) or _G.GetContainerNumSlots
local ItemInfo = (C_Container and C_Container.GetContainerItemInfo) or _G.GetContainerItemInfo
local ItemInstant = (C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant

function hp.FreeSlots()
    if not NumFree then return end
    local free = 0
    for bag = 0, 4 do
        local n, bagType = NumFree(bag)
        if n and (bagType == 0 or bagType == nil) then free = free + n end
    end
    return free
end

-- lowest durability of equipped gear, 0-100
function hp.LowestDurability()
    if not GetInventoryItemDurability then return end
    local low
    for slot = 1, 18 do
        local cur, max = GetInventoryItemDurability(slot)
        if cur and max and max > 0 then
            local pct = cur / max * 100
            if not low or pct < low then low = pct end
        end
    end
    return low
end

local function ItemCountAndId(bag, slot)
    local info, count, _, _, _, _, _, _, id = ItemInfo(bag, slot)
    if type(info) == "table" then return info.stackCount, info.itemID end
    return count, id
end

-- food and drink items in your bags (Consumable > Food & Drink)
function hp.FoodCount()
    if not (NumSlots and ItemInfo and ItemInstant) then return end
    local total = 0
    for bag = 0, 4 do
        for slot = 1, NumSlots(bag) or 0 do
            local count, id = ItemCountAndId(bag, slot)
            if id then
                local _, _, _, _, _, classID, subClassID = ItemInstant(id)
                if classID == 0 and subClassID == 5 then total = total + (count or 1) end
            end
        end
    end
    return total
end

function hp.AmmoCount()
    if not (GetInventoryItemCount and GetInventoryItemID) then return end
    if not GetInventoryItemID("player", 18) then return end -- no ranged weapon
    return GetInventoryItemCount("player", 0) or 0
end

local function ClassToken()
    return UnitClass and select(2, UnitClass("player"))
end

local function HearthReady()
    if not (GetItemCount and GetItemCount(HEARTHSTONE) > 0) then return false end
    local cd = (C_Container and C_Container.GetItemCooldown) or _G.GetItemCooldown
    if not cd then return true end
    local start, duration = cd(HEARTHSTONE)
    return not start or start == 0 or (start + duration - GetTime()) <= 0
end

-- the step the guide is on, and where it wants you to go
local function CurrentStep()
    local guide = addon.currentGuide
    local i = guide and addon.GetGuideProgress and addon.GetGuideProgress()
    return guide and i and guide.steps and guide.steps[i]
end

local function StepTarget(step)
    for _, e in ipairs(step and step.elements or {}) do
        if e.wx and e.instance then return {wx = e.wx, wy = e.wy, instance = e.instance, map = e.zone} end
    end
    for _, e in ipairs(step and step.elements or {}) do
        if e.tag == "zone" and e.map then
            local wx, wy, wi = HBD:GetWorldCoordinatesFromZone(0.5, 0.5, e.map)
            if wx then return {wx = wx, wy = wy, instance = wi, map = e.map, zoneOnly = true} end
        end
    end
end

---------------------------------------------------------------------------
-- The checks. Each returns nil (nothing to say) or
-- {title, text, target = {wx, wy, instance, title} or nil}
---------------------------------------------------------------------------

local checks = {}
local order = {"questlog", "repair", "bags", "trainer", "ammo", "food", "sethome", "hearth"}
hp.checks = checks

checks.questlog = function()
    if not (GetNumQuestLogEntries and GetQuestLogTitle) then return end
    local step = CurrentStep()
    local _, numQuests = GetNumQuestLogEntries()
    numQuests = numQuests or 0
    local inLog = {}
    local entries = {}
    local numEntries = GetNumQuestLogEntries()
    for i = 1, numEntries or 0 do
        local title, level, _, isHeader, _, _, _, questID = GetQuestLogTitle(i)
        if not isHeader and questID then
            inLog[questID] = true
            entries[#entries + 1] = {title = title, level = level or 0, id = questID}
        end
    end
    local new = 0
    for _, e in ipairs(step and step.elements or {}) do
        if e.tag == "accept" and e.questId and not inLog[e.questId] and not e.completed then new = new + 1 end
    end
    if new == 0 or numQuests + new <= QUEST_LOG_MAX then return end
    -- quests worth dropping: gray ones first, then ones this guide never uses
    local used = {}
    for _, s in ipairs(addon.currentGuide and addon.currentGuide.steps or {}) do
        for _, e in ipairs(s.elements or {}) do if e.questId then used[e.questId] = true end end
    end
    local level = UnitLevel and UnitLevel("player") or 60
    local gray = level - ((GetQuestGreenRange and GetQuestGreenRange()) or 8)
    table.sort(entries, function(a, b) return a.level < b.level end)
    local pick = {}
    for _, q in ipairs(entries) do
        if q.level > 0 and q.level < gray and #pick < 3 then pick[#pick + 1] = q.title end
    end
    for _, q in ipairs(entries) do
        if not used[q.id] and #pick < 3 then
            local already
            for _, t in ipairs(pick) do if t == q.title then already = true end end
            if not already then pick[#pick + 1] = q.title end
        end
    end
    local need = numQuests + new - QUEST_LOG_MAX
    local text = fmt(L("This step gives you %d more. Drop %d first."), new, need)
    if #pick > 0 then text = text .. "\n" .. L("Good ones to drop:") .. " " .. table.concat(pick, ", ") end
    return {title = fmt(L("Quest log full: %d of %d"), numQuests, QUEST_LOG_MAX), text = text}
end

checks.repair = function()
    local low = hp.LowestDurability()
    if not low or low > Opt("zqRepairPct", 20) then return end
    local t, d = hp.Nearest(function(n) return band(n[3], FLAG.REPAIR) end)
    return {title = fmt(L("Gear at %d%%: time to repair"), low), target = t, yards = d,
            text = t and fmt(L("The arrow points to %s, %d yards away."), t.title, d) or
                L("Repair at the next vendor with an anvil.")}
end

checks.bags = function()
    local free = hp.FreeSlots()
    if not free or free > Opt("zqBagFreeSlots", 4) then return end
    local t, d = hp.Nearest(function(n) return band(n[3], FLAG.VENDOR) end)
    if not t then t, d = NearestGuideVendor() end
    return {title = fmt(L("Bags almost full: %d free"), free), target = t, yards = d,
            text = t and fmt(L("The arrow points to %s, %d yards away. Junk sells when you open a vendor."), t.title, d) or
                L("Sell junk at the next vendor or innkeeper you pass.")}
end

-- new spells come every even level in Classic (and at 1-10 for some classes)
checks.trainer = function()
    local level = UnitLevel and UnitLevel("player") or 1
    if level < 4 or level % 2 == 1 then return end
    if type(ZQCData) == "table" and (ZQCData.zqTrainedLevel or 0) >= level then return end
    local token = ClassToken()
    if not token then return end
    local className = token:sub(1, 1) .. token:sub(2):lower()
    local localName = UnitClass("player")
    local t, d = hp.Nearest(function(n)
        return band(n[3], FLAG.TRAINER) and SubHas(n, {className .. " Trainer", localName})
    end)
    return {title = fmt(L("New spells at level %d"), level), target = t, yards = d,
            text = t and fmt(L("Your nearest %s trainer: %s, %d yards away."), localName, t.title, d) or
                fmt(L("Visit a %s trainer in a capital city."), localName)}
end

checks.ammo = function()
    if ClassToken() ~= "HUNTER" then return end
    local n = hp.AmmoCount()
    if not n or n >= Opt("zqAmmoMin", 200) then return end
    local t, d = hp.Nearest(function(x)
        return band(x[3], FLAG.VENDOR) and SubHas(x, {"Bow", "Gun", "Ammo", "Arrow", "Bullet", "General Goods", "Trade Supplies"})
    end)
    return {title = fmt(L("Low on ammo: %d left"), n), target = t, yards = d,
            text = t and fmt(L("The arrow points to %s, %d yards away."), t.title, d) or L("Buy ammo at a general goods vendor.")}
end

checks.food = function()
    local level = UnitLevel and UnitLevel("player") or 1
    if level < 6 then return end
    local n = hp.FoodCount()
    if not n or n >= Opt("zqFoodMin", 5) then return end
    local t, d = hp.Nearest(function(x)
        return band(x[3], FLAG.INNKEEPER) or (band(x[3], FLAG.VENDOR) and
            SubHas(x, {"Food", "Drink", "Baker", "Butcher", "Cook", "Fruit", "Bread", "Cheese", "Meat", "Mushroom"}))
    end)
    return {title = fmt(L("Low on food and drink: %d left"), n), target = t, yards = d,
            text = t and fmt(L("The arrow points to %s, %d yards away."), t.title, d) or L("Stock up at the next innkeeper.")}
end

-- The town this part of the guide keeps coming back to: the innkeeper
-- nearest the middle of its quest givers in the guide's main zone
local hubCache = {}
local function GuideHub(guide)
    if not guide then return end
    if hubCache[guide] ~= nil then return hubCache[guide] or nil end
    local count, sx, sy, n, inst = {}, 0, 0, 0, nil
    for _, s in ipairs(guide.steps or {}) do
        local g, quest
        for _, e in ipairs(s.elements or {}) do
            if e.wx and not g then g = e end
            if e.tag == "accept" or e.tag == "turnin" then quest = true end
        end
        if g and quest and g.zone then count[g.zone] = (count[g.zone] or 0) + 1 end
    end
    local main, most = nil, 0
    for z, c in pairs(count) do if c > most then main, most = z, c end end
    if not main or most < 8 then hubCache[guide] = false return end
    for _, s in ipairs(guide.steps or {}) do
        for _, e in ipairs(s.elements or {}) do
            if e.wx and e.zone == main then
                local quest
                for _, e2 in ipairs(s.elements) do if e2.tag == "accept" or e2.tag == "turnin" then quest = true end end
                if quest then sx, sy, n, inst = sx + e.wx, sy + e.wy, n + 1, e.instance end
                break
            end
        end
    end
    if n == 0 or not hp.npcs then return end -- ask again once Questie's NPCs are in
    local t = hp.Nearest(function(x) return band(x[3], FLAG.INNKEEPER) and x[4] == main end, sx / n, sy / n, inst)
    hubCache[guide] = t or false
    return t
end

checks.sethome = function()
    local hub = GuideHub(addon.currentGuide)
    if not hub then return end
    local home = type(ZQCData) == "table" and ZQCData.zqHome
    if home and home.map == hub.map and home.wx and hub.wx and home.instance == hub.instance and
        HBD:GetWorldDistance(hub.instance, home.wx, home.wy, hub.wx, hub.wy) < 300 then return end
    local px, py, inst = HBD:GetPlayerWorldPosition()
    if not (px and inst == hub.instance) then return end
    local d = HBD:GetWorldDistance(inst, px, py, hub.wx, hub.wy)
    if not d or d > HOME_NEAR then return end
    return {title = L("Set your Hearthstone here"), target = hub, yards = d,
            text = fmt(L("This part of the guide keeps coming back here. Talk to %s, %d yards away."), hub.title, d)}
end

checks.hearth = function()
    local home = type(ZQCData) == "table" and ZQCData.zqHome
    if not (home and home.wx and HearthReady()) then return end
    if UnitOnTaxi and UnitOnTaxi("player") then return end
    local target = StepTarget(CurrentStep())
    local px, py, inst = HBD:GetPlayerWorldPosition()
    if not (target and px) then return end
    local fromHome = home.instance == target.instance and
        HBD:GetWorldDistance(target.instance, home.wx, home.wy, target.wx, target.wy)
    local fromHere = inst == target.instance and HBD:GetWorldDistance(inst, px, py, target.wx, target.wy)
    -- worth it: the step is in your Hearthstone's zone, or much closer to home than to you
    local inHomeZone = target.map and home.map == target.map and (not fromHere or fromHere > 600)
    local muchCloser = fromHome and (not fromHere or (fromHere > 1500 and fromHome < fromHere / 3))
    if not (inHomeZone or muchCloser) then return end
    local where = home.name or L("your inn")
    return {title = fmt(L("Hearth to %s"), where),
            text = fmt(L("Your Hearthstone is ready and the next step is closer to %s than to you."), where)}
end

---------------------------------------------------------------------------
-- Notice and arrow
---------------------------------------------------------------------------

local notice
local function Notice()
    if notice then return notice end
    local f = CreateFrame("Frame", "ZQuestHelperNotice", UIParent, "BackdropTemplate")
    f:SetSize(320, 62)
    f:SetPoint("TOP", UIParent, "TOP", 0, -140)
    f:SetFrameStrata("HIGH")
    f:SetBackdrop({bgFile = "Interface/BUTTONS/WHITE8X8", edgeFile = "Interface/BUTTONS/WHITE8X8", edgeSize = 1})
    f:SetBackdropColor(18 / 255, 7 / 255, 32 / 255, 0.94)
    f:SetBackdropBorderColor(214 / 255, 178 / 255, 96 / 255, 1)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOPLEFT", 10, -8)
    f.title:SetTextColor(230 / 255, 195 / 255, 106 / 255)
    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.text:SetPoint("TOPLEFT", 10, -26)
    f.text:SetPoint("RIGHT", -72, 0)
    f.text:SetJustifyH("LEFT")
    f.more = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.more:SetPoint("BOTTOMLEFT", 10, 6)
    local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    b:SetSize(62, 20)
    b:SetPoint("RIGHT", -8, 0)
    b:SetText(L("Dismiss"))
    b:SetScript("OnClick", function() hp.Dismiss() end)
    f:Hide()
    notice = f
    return f
end

local showing      -- key of the check on screen
local snoozed = {} -- key -> true until that check has nothing to say again
hp.snoozed = snoozed

local function ReleaseArrow()
    local ph = addon.pathHints
    if ph and ph.go and ph.go.zqHelper then
        ph.go = nil
        if ph.Reset then ph.Reset() end
    end
end

local function PointArrow(key, t, title)
    local ph = addon.pathHints
    if not (ph and t and t.wx) then return ReleaseArrow() end
    if ph.go and not ph.go.zqHelper then return end -- "/zq path to" wins
    ph.go = {wx = t.wx, wy = t.wy, instance = t.instance, arrow = true, title = title, zqHelper = key}
    if ph.Reset then ph.Reset() end
    local af = addon.arrowFrame
    local p = Profile()
    if af and not af:IsShown() and not (p and p.disableArrow) then af:Show() end
end

function hp.Dismiss()
    if showing then snoozed[showing] = true end
    showing = nil
    ReleaseArrow()
    if notice then notice:Hide() end
    hp.Update()
end

-- clear one check after you've dealt with it (vendor or trainer opened)
function hp.Done(key)
    snoozed[key] = nil
    if showing == key then
        showing = nil
        ReleaseArrow()
        if notice then notice:Hide() end
    end
end

local SETTING = {questlog = "zqQuestLogCheck", repair = "zqRepairCheck", bags = "zqBagCheck",
                 trainer = "zqTrainerCheck", ammo = "zqAmmoCheck", food = "zqFoodCheck",
                 sethome = "zqHearthCheck", hearth = "zqHearthCheck"}

function hp.Update()
    if (IsInInstance and IsInInstance()) or (UnitOnTaxi and UnitOnTaxi("player")) or
        (InCombatLockdown and InCombatLockdown()) then
        return
    end
    local first, firstKey, others = nil, nil, 0
    for _, key in ipairs(order) do
        if On(SETTING[key]) then
            local ok, r = pcall(checks[key])
            if ok and r then
                if not snoozed[key] then
                    if first then others = others + 1 else first, firstKey = r, key end
                end
            else
                snoozed[key] = nil -- nothing to say: the next time counts again
            end
        end
    end
    if not first then
        if showing then
            showing = nil
            ReleaseArrow()
            if notice then notice:Hide() end
        end
        return
    end
    local f = Notice()
    f.title:SetText(first.title)
    f.text:SetText(first.text or "")
    f.more:SetText(others > 0 and fmt(L("+%d more after this"), others) or "")
    f:SetHeight(first.text and #first.text > 70 and 74 or 62)
    f:Show()
    if showing ~= firstKey or first.target then
        PointArrow(firstKey, first.target, first.title)
    end
    showing = firstKey
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------

local function WarnNoQuestie()
    if _G.QuestieLoader then return end
    print("|cFFE6C36AZQuest:|r " .. L("Questie isn't installed or enabled. ZQuest uses it for waypoints, quest chains, vendors, trainers and inns. Install the free Questie addon and reload."))
    if StaticPopupDialogs and StaticPopup_Show then
        StaticPopupDialogs["ZQUEST_NEED_QUESTIE"] = StaticPopupDialogs["ZQUEST_NEED_QUESTIE"] or {
            text = L("ZQuest works best with the free Questie addon installed. Without it, the waypoint check, quest chains and the vendor, trainer and inn helpers can't run."),
            button1 = OKAY or "OK", timeout = 0, whileDead = true, hideOnEscape = true,
        }
        StaticPopup_Show("ZQUEST_NEED_QUESTIE")
    end
end
hp.WarnNoQuestie = WarnNoQuestie

local ev = CreateFrame("Frame")
for _, e in ipairs({"BAG_UPDATE_DELAYED", "UPDATE_INVENTORY_DURABILITY", "UNIT_INVENTORY_CHANGED",
                    "PLAYER_LEVEL_UP", "QUEST_LOG_UPDATE", "MERCHANT_SHOW", "MERCHANT_CLOSED",
                    "TRAINER_SHOW", "HEARTHSTONE_BOUND", "ZONE_CHANGED_NEW_AREA", "PLAYER_ENTERING_WORLD",
                    "PLAYER_REGEN_ENABLED"}) do
    pcall(ev.RegisterEvent, ev, e)
end
local warned
ev:SetScript("OnEvent", function(_, event, arg1)
    if event == "MERCHANT_SHOW" then
        hp.Done("bags"); hp.Done("repair"); hp.Done("ammo"); hp.Done("food")
    elseif event == "TRAINER_SHOW" then
        -- a trainer for your class: this level's spells are dealt with
        if not (IsTradeskillTrainer and IsTradeskillTrainer()) and type(ZQCData) == "table" then
            ZQCData.zqTrainedLevel = UnitLevel("player")
        end
        hp.Done("trainer")
    elseif event == "HEARTHSTONE_BOUND" then
        local px, py, inst = HBD:GetPlayerWorldPosition()
        if type(ZQCData) == "table" and px then
            ZQCData.zqHome = {wx = px, wy = py, instance = inst, map = HBD:GetPlayerZone(),
                              name = GetBindLocation and GetBindLocation()}
        end
        hp.Done("sethome")
    elseif event == "PLAYER_LEVEL_UP" then
        snoozed.trainer = nil
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Questie builds its database after login: start the NPC index a bit later
        C_Timer.After(20, function() hp.BuildIndex() end)
        if not warned then
            warned = true
            C_Timer.After(15, WarnNoQuestie)
        end
    end
    hp.Update()
end)

-- step-dependent checks (quest log, Hearthstone) also look every few seconds
if C_Timer and C_Timer.NewTicker then
    C_Timer.NewTicker(4, function() hp.Update() end)
end

-- old name, used by earlier settings and tests
addon.bagCheck = {FreeSlots = hp.FreeSlots, Check = hp.Update, Clear = hp.Dismiss}

-- ZDungeon (companion addon): find and open the walkthrough for a dungeon by
-- its name, e.g. RXPGuides.LoadDungeonGuide("Wailing Caverns").
local function FindDungeonGuide(dungeon)
    if type(dungeon) ~= "string" or not addon.guides then return end
    local want = dungeon:lower():gsub("^the ", "")
    for _, guide in pairs(addon.guides) do
        if type(guide) == "table" and type(guide.group) == "string" and type(guide.name) == "string"
            and guide.group:find("Dungeons", 1, true) and guide.name:lower():find(want, 1, true) then
            return guide
        end
    end
end

_G.RXPGuides.HasDungeonGuide = function(dungeon) return FindDungeonGuide(dungeon) ~= nil end
_G.RXPGuides.LoadDungeonGuide = function(dungeon)
    local guide = FindDungeonGuide(dungeon)
    if not guide then return false end
    addon:LoadGuide(guide)
    return true
end

-- ZDungeon (companion addon): load any registered guide by its group and
-- name, and ask whether one exists. Guides are added at run time with
-- RXPGuides.RegisterGuide(text).
_G.RXPGuides.HasGuide = function(group, name)
    return addon.GetGuideTable(group, name) ~= nil
end
_G.RXPGuides.LoadGuideByName = function(group, name)
    local guide = addon.GetGuideTable(group, name)
    if not guide then return false end
    addon:LoadGuide(guide)
    return true
end
