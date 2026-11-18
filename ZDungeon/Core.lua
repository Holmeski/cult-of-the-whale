-- ZDungeon: every quest for each dungeon, how to get it, what it is worth,
-- how long it takes to get there, and what you still need before you leave.
-- Quest data is in Data.lua (generated from QuestieDB). Open with /zd.
local addonName, ns = ...

local floor, max, min = math.floor, math.max, math.min
local tinsert, sort, concat = table.insert, table.sort, table.concat

local ROWS = 12
local ROW_H = 20
local COLS = {
    {key = "name", label = "Quest", w = 204, justify = "LEFT"},
    {key = "level", label = "Lvl", w = 34, justify = "CENTER"},
    {key = "xp", label = "XP now", w = 62, justify = "RIGHT"},
    {key = "status", label = "Status", w = 128, justify = "LEFT", pad = 10},
    {key = "where", label = "Pick up", w = 156, justify = "LEFT"},
}

local GEAR_COLS = {
    {key = "name", label = "Item", w = 204, justify = "LEFT"},
    {key = "slot", label = "Slot", w = 116, justify = "LEFT"},
    {key = "gain", label = "Upgrade", w = 70, justify = "RIGHT"},
    {key = "source", label = "From", w = 198, justify = "LEFT", pad = 10},
}

local state = {dungeon = nil, sortKey = "xp", sortDesc = true, offset = 0, selected = nil,
               hideDone = false, otherClasses = false, perHour = false,
               mode = "quests", gearSort = "gain", gearDesc = true, gearSelected = nil,
               upgradesOnly = false, showUnusable = false}

-- set further down; declared here so the window and the tracker can call them
local StartPlan, OpenNext, UpdateCard, card
local plan -- the dungeon guide in progress: {key, ids, chain, order, arrived}

local function Secret(v)
    return issecretvalue and issecretvalue(v) or false
end

local function Now()
    return GetTime and GetTime() or 0
end

-- ---------------------------------------------------------------------------
-- Player and quest state
-- ---------------------------------------------------------------------------

local function PlayerSide()
    return UnitFactionGroup("player") == "Alliance" and "A" or "H"
end

local function PlayerClass()
    local _, token = UnitClass("player")
    return token or ""
end

local function ForMyClass(q)
    if not q.cls then return true end
    local mine = PlayerClass()
    for name in q.cls:gmatch("[^/]+") do
        if name:upper() == mine then return true end
    end
    return false
end

local function ForMySide(q)
    return q.side == "B" or q.side == PlayerSide()
end

local IsFlagged = (C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted) or IsQuestFlaggedCompleted

local function IsDone(id)
    if not IsFlagged then return false end
    local ok, done = pcall(IsFlagged, id)
    return ok and not Secret(done) and done and true or false
end

-- Quests in the log, read from the log itself (C_QuestLog.IsOnQuest alone has
-- been wrong on Forever).
local logCache
local function QuestLog()
    if logCache then return logCache end
    local ids = {}
    if GetQuestLogTitle and GetNumQuestLogEntries then
        for i = 1, (GetNumQuestLogEntries()) or 0 do
            local _, _, _, isHeader, _, _, _, questID = GetQuestLogTitle(i)
            if not isHeader and questID and questID > 0 then ids[questID] = i end
        end
    elseif C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then
        for i = 1, C_QuestLog.GetNumQuestLogEntries() or 0 do
            local info = C_QuestLog.GetInfo(i)
            if info and not info.isHeader and info.questID then ids[info.questID] = i end
        end
    end
    logCache = ids
    return ids
end

local function InLog(id)
    if QuestLog()[id] then return true end
    -- a collapsed header hides its quests from the scan above
    if next(QuestLog()) == nil and C_QuestLog and C_QuestLog.IsOnQuest then
        local ok, on = pcall(C_QuestLog.IsOnQuest, id)
        return ok and on and true or false
    end
    return false
end

-- What a quest in your log still needs: {{text = "Deviate Hide: 14/20", done = false}, ...}
local function Objectives(id)
    local out = {}
    if C_QuestLog and C_QuestLog.GetQuestObjectives then
        local ok, objs = pcall(C_QuestLog.GetQuestObjectives, id)
        if ok and type(objs) == "table" then
            for _, o in ipairs(objs) do
                if type(o) == "table" and not Secret(o.finished) and not Secret(o.text) then
                    tinsert(out, {text = o.text or "?", done = o.finished and true or false})
                end
            end
            return out
        end
    end
    local idx = QuestLog()[id]
    if idx and GetNumQuestLeaderBoards and GetQuestLogLeaderBoard then
        for j = 1, GetNumQuestLeaderBoards(idx) or 0 do
            local text, _, finished = GetQuestLogLeaderBoard(j, idx)
            if text and not Secret(text) then tinsert(out, {text = text, done = finished and true or false}) end
        end
    end
    return out
end

-- ---------------------------------------------------------------------------
-- XP
-- ---------------------------------------------------------------------------

-- Scaling by level, used only when the game will not tell us a quest's XP:
-- full value until you are 6 levels above the quest, then 20% less per
-- level, down to 10%.
local function ScaleXP(xp, questLevel, charLevel)
    if not xp or xp <= 0 then return 0 end
    local maxLevel = GetMaxPlayerLevel and GetMaxPlayerLevel() or 60
    if charLevel >= maxLevel then return 0 end
    local mult = 2 * (questLevel - charLevel) + 20
    if mult < 1 then mult = 1 elseif mult > 10 then mult = 10 end
    xp = xp * mult / 10
    if xp <= 100 then
        xp = 5 * floor((xp + 2) / 5)
    elseif xp <= 500 then
        xp = 10 * floor((xp + 5) / 10)
    elseif xp <= 1000 then
        xp = 25 * floor((xp + 12) / 25)
    else
        xp = 50 * floor((xp + 25) / 50)
    end
    return floor(xp)
end
ns.ScaleXP = ScaleXP

-- The game's own number comes first: it knows the XP of any quest once it has
-- loaded the quest, and it already includes whatever multiplier the server
-- is running. Quests it has not loaded yet are asked for and show up a
-- moment later.
local clientXP, asked = {}, {}
local ScheduleRefresh

local function ClientXP(id, request)
    local known = clientXP[id]
    if known then return known end
    if not GetQuestLogRewardXP then return nil end
    local ok, xp = pcall(GetQuestLogRewardXP, id)
    if ok and type(xp) == "number" and not Secret(xp) and xp > 0 then
        clientXP[id] = xp
        return xp
    end
    if request and not asked[id] and C_QuestLog and C_QuestLog.RequestLoadQuestByID then
        asked[id] = true
        pcall(C_QuestLog.RequestLoadQuestByID, id)
    end
    return nil
end

-- How far the game's numbers sit above the stored ones (the server's
-- multiplier), worked out from the quests where both are known and used for
-- the quests the game has not answered for.
local ratioCache, ratioCount = 1, -1
local function Ratio()
    local n = 0
    for _ in pairs(clientXP) do n = n + 1 end
    if n == ratioCount then return ratioCache end
    ratioCount = n
    local level = UnitLevel("player") or 1
    local list = {}
    for id, xp in pairs(clientXP) do
        local q = ns.quests[id]
        -- only quests you do not outlevel, so level scaling cannot blur the comparison
        if q and q.xp > 0 and level <= q.level + 5 then tinsert(list, xp / q.xp) end
    end
    if #list < 5 then ratioCache = 1 return 1 end
    sort(list)
    ratioCache = max(1, min(5, list[floor((#list + 1) / 2)]))
    return ratioCache
end

-- XP for a quest now, and whether that number is an estimate.
local function QuestXP(id, request)
    local q = ns.quests[id]
    if not q then return 0, true end
    if (UnitLevel("player") or 1) >= (GetMaxPlayerLevel and GetMaxPlayerLevel() or 60) then return 0, false end
    local live = ClientXP(id, request)
    if live then return live, false end
    local est = ScaleXP(q.xp, q.level, UnitLevel("player") or 1)
    return floor(est * Ratio() + 0.5), true
end

-- ---------------------------------------------------------------------------
-- Chains and status
-- ---------------------------------------------------------------------------

-- The prerequisite that applies to this character out of an "any of" list.
local function PickAny(list)
    local firstOk
    for _, id in ipairs(list) do
        if IsDone(id) then return id, true end
        local q = ns.quests[id]
        if q and not firstOk and ForMySide(q) and ForMyClass(q) then firstOk = id end
    end
    return firstOk or list[1], false
end

-- Unfinished quests that must be done first, earliest first.
local function Chain(id, out, seen)
    out, seen = out or {}, seen or {}
    local q = ns.quests[id]
    if not q or seen[id] then return out end
    seen[id] = true
    local needs = {}
    if q.preAll then for _, p in ipairs(q.preAll) do tinsert(needs, p) end end
    if q.preAny then
        local p, done = PickAny(q.preAny)
        if p and not done then tinsert(needs, p) end
    end
    for _, p in ipairs(needs) do
        if ns.quests[p] and not IsDone(p) and not seen[p] then
            Chain(p, out, seen)
            tinsert(out, p)
        end
    end
    return out
end

-- The highest level any quest in a chain asks for (0 when there is no chain).
local function ChainLevel(chain)
    local need = 0
    for _, p in ipairs(chain) do
        local q = ns.quests[p]
        if q and (q.req or 1) > need then need = q.req end
    end
    return need
end

local STATUS = {
    done = {text = "Done", r = 0.5, g = 0.5, b = 0.5, order = 5},
    log = {text = "In your log", r = 0.4, g = 0.8, b = 1, order = 1},
    ready = {text = "Available", r = 0.3, g = 1, b = 0.3, order = 2},
    chain = {text = "Chain first", r = 1, g = 0.82, b = 0, order = 3},
    level = {text = "Level", r = 1, g = 0.4, b = 0.3, order = 4},
}

local function Status(id)
    local q = ns.quests[id]
    if IsDone(id) then return "done" end
    if InLog(id) then return "log" end
    if (UnitLevel("player") or 1) < (q.req or 1) then return "level" end
    if #Chain(id) > 0 then return "chain" end
    return "ready"
end

local function ZoneName(mapID)
    if mapID and C_Map and C_Map.GetMapInfo then
        local info = C_Map.GetMapInfo(mapID)
        if info and info.name then return info.name end
    end
    return nil
end

local function WhereShort(p)
    if not p then return "Unknown" end
    if p.k == "item" then
        if p.inside then return "Drop inside" end
        return "Drop: " .. (p.from or p.n)
    end
    if p.inside then return "Inside the dungeon" end
    if p.m then return ZoneName(p.m) or p.n end
    return p.n
end

local function WhereLong(p)
    if not p then return "unknown" end
    local s
    if p.k == "item" then
        s = "the item |cffffffff" .. p.n .. "|r"
        if p.from then s = s .. ", dropped by |cffffffff" .. p.from .. "|r" end
    else
        s = "|cffffffff" .. p.n .. "|r"
    end
    if p.inside then
        s = s .. " (inside " .. p.inside .. ")"
    elseif p.m then
        s = s .. (" (%s %.1f, %.1f)"):format(ZoneName(p.m) or "map " .. p.m, p.x or 0, p.y or 0)
    end
    return s
end

local function Comma(n)
    local s = tostring(floor(n or 0))
    local k
    repeat s, k = s:gsub("^(%d+)(%d%d%d)", "%1,%2") until k == 0
    return s
end

local function Minutes(secs)
    local m = floor((secs or 0) / 60 + 0.5)
    if m < 1 then return "under a minute" end
    return m .. " min"
end

-- ---------------------------------------------------------------------------
-- Building the list for a dungeon
-- ---------------------------------------------------------------------------

local function Visible(id)
    local q = ns.quests[id]
    if not q or not ForMySide(q) then return false end
    if not state.otherClasses and not ForMyClass(q) then return false end
    return true
end

local function BuildRows(d)
    local rows = {}
    for _, id in ipairs(d.quests) do
        if Visible(id) then
            local q = ns.quests[id]
            local st = Status(id)
            if not (state.hideDone and st == "done") then
                local xp, approx = QuestXP(id, true)
                local chain = Chain(id)
                local chainXP = 0
                for _, p in ipairs(chain) do chainXP = chainXP + (QuestXP(p, true)) end
                local needLevel = ChainLevel(chain)
                tinsert(rows, {id = id, q = q, name = q.name, level = q.level, status = st,
                               chainLevel = needLevel > (UnitLevel("player") or 1) and needLevel or nil,
                               xp = st == "done" and 0 or xp, approx = approx, unknown = approx and q.xp == 0,
                               chain = chain, chainXP = chainXP, where = WhereShort(q.start)})
            end
        end
    end
    local key, desc = state.sortKey, state.sortDesc
    sort(rows, function(a, b)
        local x, y = a[key], b[key]
        if key == "status" then x, y = STATUS[a.status].order, STATUS[b.status].order end
        if x == y then
            if a.xp ~= b.xp then return a.xp > b.xp end
            return a.id < b.id
        end
        if desc then return x > y end
        return x < y
    end)
    return rows
end

-- XP still on the table in a dungeon for this character:
-- ready now, all unfinished dungeon quests, extra from the chain steps leading to them.
local function DungeonTotals(d)
    local now, all, extra, count, left = 0, 0, 0, 0, 0
    local counted = {}
    for _, id in ipairs(d.quests) do
        local q = ns.quests[id]
        if q and ForMySide(q) and ForMyClass(q) then
            count = count + 1
            local st = Status(id)
            if st ~= "done" then
                left = left + 1
                local xp = QuestXP(id)
                if st == "ready" or st == "log" then now = now + xp end
                all = all + xp
                counted[id] = true
            end
        end
    end
    for _, id in ipairs(d.quests) do
        if counted[id] then
            for _, p in ipairs(Chain(id)) do
                if not counted[p] then counted[p] = true extra = extra + (QuestXP(p)) end
            end
        end
    end
    return now, all, extra, count, left
end

-- ---------------------------------------------------------------------------
-- What a dungeon still needs from you
-- ---------------------------------------------------------------------------

-- needed:   quests in your log with objectives left   {q, lines = {"Deviate Hide: 14/20"}}
-- turnin:   quests in your log with everything done
-- outside:  quests you could pick up before going in
-- inside:   quests that start inside (an NPC or a drop)
-- locked:   quests behind a chain or a level
local function Needs(d)
    logCache = nil
    local n = {needed = {}, turnin = {}, outside = {}, inside = {}, locked = {}}
    for _, id in ipairs(d.quests) do
        local q = ns.quests[id]
        if q and ForMySide(q) and ForMyClass(q) then
            local st = Status(id)
            if st == "log" then
                local lines = {}
                for _, o in ipairs(Objectives(id)) do
                    if not o.done then tinsert(lines, o.text) end
                end
                if #lines > 0 then
                    tinsert(n.needed, {id = id, q = q, lines = lines})
                else
                    tinsert(n.turnin, {id = id, q = q})
                end
            elseif st == "ready" then
                local p = q.start
                if p and (p.inside or p.k == "item") then
                    tinsert(n.inside, {id = id, q = q})
                else
                    tinsert(n.outside, {id = id, q = q})
                end
            elseif st == "chain" or st == "level" then
                tinsert(n.locked, {id = id, q = q, status = st})
            end
        end
    end
    return n
end

local function NeededSummary(n, limit)
    local parts = {}
    for _, e in ipairs(n.needed) do
        for _, line in ipairs(e.lines) do
            if #parts < (limit or 4) then tinsert(parts, line) end
        end
    end
    return concat(parts, ", ")
end

-- Which dungeon you are standing in, if any.
local function MatchName(text, exact)
    if type(text) ~= "string" or text == "" or Secret(text) then return nil end
    text = text:lower()
    for _, d in ipairs(ns.dungeons) do
        if not d.side or d.side == PlayerSide() then
            local names = {d.name}
            if d.aka then for _, a in ipairs(d.aka) do tinsert(names, a) end end
            for _, name in ipairs(names) do
                name = name:lower()
                if text == name or (not exact and text:find(name, 1, true)) then return d end
            end
        end
    end
end

local function CurrentDungeon()
    if not IsInInstance or not GetInstanceInfo then return nil end
    local inside, kind = IsInInstance()
    if not inside or (kind ~= "party" and kind ~= "raid") then return nil end
    local name, _, _, _, _, _, _, instanceID = GetInstanceInfo()
    for _, d in ipairs(ns.dungeons) do
        if d.inst and d.inst == instanceID then return d end
    end
    return MatchName(name)
end

-- ---------------------------------------------------------------------------
-- Alerts and the in-dungeon tracker
-- ---------------------------------------------------------------------------

local function Say(msg)
    print("|cffffd100ZDungeon:|r " .. msg)
end

local function Alert(msg)
    Say(msg)
    if RaidNotice_AddMessage and RaidWarningFrame and ChatTypeInfo and ChatTypeInfo["RAID_WARNING"] then
        local plain = msg:gsub("|c%x%x%x%x%x%x%x%x", "")
        plain = plain:gsub("|r", "")
        pcall(RaidNotice_AddMessage, RaidWarningFrame, plain, ChatTypeInfo["RAID_WARNING"])
    end
    if PlaySound then pcall(PlaySound, 8959, "Master") end
end

local Backdrop = BackdropTemplateMixin and "BackdropTemplate" or nil

local function SetBackdrop(f, a)
    if not f.SetBackdrop then return end
    f:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
    f:SetBackdropColor(0.05, 0.05, 0.07, a or 0.95)
    f:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
end

local function Text(parent, font, justify)
    local t = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
    t:SetJustifyH(justify or "LEFT")
    if t.SetWordWrap then t:SetWordWrap(false) end
    return t
end

local tracker
local run = {dungeon = nil, entered = 0, bosses = 0, lastBoss = 0}
local preview -- a dungeon you are standing outside of

local function TrackerText(d, inside)
    local n = Needs(d)
    local L = {}
    local function add(s) if #L < 22 then tinsert(L, s) end end
    if #n.needed > 0 then
        add("|cffff6644Still needed|r")
        for _, e in ipairs(n.needed) do
            add("|cffffd100" .. e.q.name .. "|r")
            for _, line in ipairs(e.lines) do add("   " .. line) end
        end
    end
    if #n.turnin > 0 then
        add(("|cff40ff40%d quest%s ready to hand in|r"):format(#n.turnin, #n.turnin == 1 and "" or "s"))
    end
    if #n.outside > 0 then
        add(inside and "|cffff6644Not picked up (outside the dungeon)|r" or "|cffff6644Pick up before you go in|r")
        for _, e in ipairs(n.outside) do
            local p = e.q.start
            add(("   %s |cff999999- %s%s|r"):format(e.q.name, p and p.n or "?",
                p and p.m and (", " .. (ZoneName(p.m) or "")) or ""))
        end
    end
    if #n.inside > 0 then
        add("|cff66ccffStarts inside|r")
        for _, e in ipairs(n.inside) do
            local p = e.q.start
            local from = p and (p.k == "item" and ("drops from " .. (p.from or "?")) or p.n) or "?"
            add(("   %s |cff999999- %s|r"):format(e.q.name, from))
        end
    end
    if #n.locked > 0 then
        add(("|cff999999%d more behind a chain or level (see /zd)|r"):format(#n.locked))
    end
    if #L == 0 then add("|cff40ff40Nothing left to get here.|r") end
    return concat(L, "\n"), n
end

local function CreateTracker()
    local f = CreateFrame("Frame", "ZDungeonTracker", UIParent, Backdrop)
    f:SetSize(290, 120)
    f:SetPoint("RIGHT", UIParent, "RIGHT", -40, 120)
    f:SetFrameStrata("MEDIUM")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if ZDungeonDB and self.GetPoint then
            local point, _, rel, x, y = self:GetPoint(1)
            if point then ZDungeonDB.trackerPos = {point, rel, x, y} end
        end
    end)
    SetBackdrop(f, 0.8)
    local pos = ZDungeonDB and ZDungeonDB.trackerPos
    if pos and pos[1] then
        f:ClearAllPoints()
        f:SetPoint(pos[1], UIParent, pos[2] or pos[1], pos[3] or 0, pos[4] or 0)
    end
    f.title = Text(f, "GameFontNormalSmall")
    f.title:SetPoint("TOPLEFT", 8, -7)
    f.title:SetWidth(250)
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 3, 3)
    close:SetScript("OnClick", function()
        f.closedFor = run.dungeon or preview
        f:Hide()
    end)
    f.body = Text(f, "GameFontHighlightSmall")
    f.body:SetPoint("TOPLEFT", 8, -24)
    f.body:SetWidth(274)
    f.body:SetJustifyV("TOP")
    if f.body.SetWordWrap then f.body:SetWordWrap(true) end
    if f.body.SetSpacing then f.body:SetSpacing(2) end
    f:Hide()
    return f
end

local function UpdateTracker()
    local d = run.dungeon or preview
    if not d or (ZDungeonDB and ZDungeonDB.noTracker) then
        if tracker then tracker:Hide() end
        return
    end
    if card and card:IsShown() and plan and plan.key == d.key then
        if tracker then tracker:Hide() end
        return
    end
    if not tracker then tracker = CreateTracker() end
    if tracker.closedFor == d then return end
    tracker.closedFor = nil
    local text = TrackerText(d, run.dungeon ~= nil)
    tracker.title:SetText("ZDungeon: " .. d.name)
    tracker.body:SetText(text)
    local h = tracker.body.GetStringHeight and tracker.body:GetStringHeight()
    tracker:SetHeight((type(h) == "number" and h or 100) + 34)
    tracker:Show()
end

local function Checklist(d, where)
    local n = Needs(d)
    local miss = #n.outside
    if miss > 0 then
        Alert(("%s: you are missing %d quest%s you could have picked up."):format(d.name, miss, miss == 1 and "" or "s"))
        for _, e in ipairs(n.outside) do
            local p = e.q.start
            Say(("   %s - from %s%s. A party member may be able to share it."):format(e.q.name, p and p.n or "?",
                p and p.m and (" in " .. (ZoneName(p.m) or "?")) or ""))
        end
    elseif where == "manual" then
        Say(d.name .. ": no quests left to pick up outside.")
    end
    if #n.inside > 0 and where ~= "near" then
        for _, e in ipairs(n.inside) do
            local p = e.q.start
            Say(("   Starts inside: %s (%s)."):format(e.q.name,
                p and (p.k == "item" and ("drops from " .. (p.from or "?")) or p.n) or "?"))
        end
    end
    return n
end

local lastNear = {}

local function OnEnter(d)
    run.dungeon, run.entered, run.bosses = d, Now(), 0
    preview = nil
    if tracker then tracker.closedFor = nil end
    -- told at the door a moment ago: do not say it all again
    if Now() - (lastNear[d.key] or -1000) > 180 then Checklist(d, "enter") end
    UpdateTracker()
end

local function OnLeave(d)
    local n = Needs(d)
    if #n.needed > 0 then
        Alert(("You left %s still needing: %s"):format(d.name, NeededSummary(n, 5)))
    end
    -- remember how long your runs take, for the XP per hour figure
    local mins = (Now() - run.entered) / 60
    if run.bosses > 0 and mins >= 8 and mins <= 300 and ZDungeonDB then
        ZDungeonDB.runs = ZDungeonDB.runs or {}
        local r = ZDungeonDB.runs[d.key] or {n = 0, avg = 0}
        r.avg = (r.avg * r.n + mins) / (r.n + 1)
        r.n = min(r.n + 1, 5) -- recent runs count for more
        ZDungeonDB.runs[d.key] = r
    end
    run.dungeon = nil
    UpdateTracker()
end

local function CheckLocation()
    local d = CurrentDungeon()
    if d ~= run.dungeon then
        if run.dungeon and not d then
            -- a corpse run is not leaving
            if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then return end
            OnLeave(run.dungeon)
        elseif d then
            if run.dungeon then OnLeave(run.dungeon) end
            OnEnter(d)
        end
    end
    if d then return end
    -- standing at a dungeon's door
    local near = MatchName(GetSubZoneText and GetSubZoneText(), true)
        or MatchName(GetRealZoneText and GetRealZoneText(), true)
    if near ~= preview then
        preview = near
        if near and Now() - (lastNear[near.key] or -1000) > 600 then
            lastNear[near.key] = Now()
            Checklist(near, "near")
        end
        UpdateTracker()
    end
end

local function OnBossKill(name)
    local d = run.dungeon
    if not d or Now() - run.lastBoss < 3 then return end
    run.lastBoss = Now()
    run.bosses = run.bosses + 1
    local final = false
    if d.final and type(name) == "string" and not Secret(name) then
        for _, boss in ipairs(d.final) do
            if boss == name then final = true end
        end
    end
    local n = Needs(d)
    if #n.needed > 0 then
        local what = NeededSummary(n, 5)
        if final then
            Alert(("%s is down, but don't leave yet. Still needed: %s"):format(name, what))
        else
            Say("Still needed here: " .. what)
        end
    elseif final then
        Say(("%s is down and every quest objective you have for %s is done."):format(name, d.name))
    end
    UpdateTracker()
end

-- ---------------------------------------------------------------------------
-- Getting there
-- ---------------------------------------------------------------------------

local travelCache = {}
local function Travel(d)
    local api = _G.RXPGuides
    if not (d.entrance and api and api.TravelEstimate) then return nil end
    local c = travelCache[d.key]
    if c and Now() - c.at < 20 then return c.plan end
    local ok, plan = pcall(api.TravelEstimate, d.entrance.m, d.entrance.x, d.entrance.y, d.name)
    plan = ok and type(plan) == "table" and plan or nil
    travelCache[d.key] = {at = Now(), plan = plan}
    return plan
end

local function RunMinutes(d)
    local r = ZDungeonDB and ZDungeonDB.runs and ZDungeonDB.runs[d.key]
    if r and r.n > 0 then return r.avg, true end
    return d.run or 60, false
end

-- Quest XP per hour for the whole trip: there, the run, and back.
local function PerHour(d, xp)
    local plan = Travel(d)
    if not plan then return nil end
    local mins = RunMinutes(d) + 2 * plan.secs / 60
    if mins <= 0 then return nil end
    return xp / mins * 60, mins
end

local function TravelText(d)
    if not d.entrance then return "" end
    local e = d.entrance
    local s = ("Entrance: |cffffffff%s|r (%.1f, %.1f)."):format(ZoneName(e.m) or "?", e.x, e.y)
    if run.dungeon == d then return s .. "  You are inside." end
    local plan = Travel(d)
    if not plan then
        if not (_G.RXPGuides and _G.RXPGuides.TravelEstimate) then
            return s .. "  |cff999999Travel times need ZQuest.|r"
        end
        return s
    end
    local legs = {}
    for _, leg in ipairs(plan.legs or {}) do
        if #legs < 4 then tinsert(legs, leg.text) end
    end
    s = s .. ("  About |cffffd100%s|r from here"):format(Minutes(plan.secs))
    if #legs > 0 then s = s .. ": " .. concat(legs, " > ") end
    s = s .. "."
    if plan.newFlights and #plan.newFlights > 0 then
        local names = {}
        for i, name in ipairs(plan.newFlights) do if i <= 3 then tinsert(names, name) end end
        s = s .. "  |cff66ccffFlight paths to pick up on the way: " .. concat(names, ", ") .. ".|r"
    end
    return s
end

-- ---------------------------------------------------------------------------
-- Gear: what drops here that you can use
--
-- The loot lists are read from the DungeonJournal addon while the game runs
-- (boss drops and quest rewards), and the upgrade numbers come from Forever
-- Leveling BiS's public API, for the spec you picked there. Neither addon's
-- data is copied into ZDungeon; without them this view says what is missing.
-- ---------------------------------------------------------------------------

local function Journal()
    local j = _G.ForeverDungeonJournal_NS
    return j and type(j.DB) == "table" and j.DB or nil
end

local function BiS()
    local api = _G.ForeverLevelingBiS_API
    if type(api) == "table" and (api.version or 1) >= 2 and api.GetGain and api.ScoreItem then return api end
end

local function Plain(name)
    name = name:lower():gsub("^the%s+", "")
    return name
end

-- The journal's pages for one dungeon: {key = page}. Wings are separate pages
-- there ("Scarlet Monastery: Library", "Lower Blackrock Spire").
local function JournalPages(d)
    local db = Journal()
    if not db then return nil end
    local names = {Plain(d.name)}
    if d.aka then for _, a in ipairs(d.aka) do tinsert(names, Plain(a)) end end
    local pages, any = {}, false
    for key, page in pairs(db) do
        if type(key) == "string" and type(page) == "table" then
            local k = Plain(key)
            for _, n in ipairs(names) do
                if k == n or k:sub(1, #n + 1) == n .. ":" then pages[key] = page any = true break end
            end
        end
    end
    return any and pages or nil
end

local WEAPONS = { -- weapon subclass ids each class can use
    WARRIOR = {[0] = 1, [1] = 1, [2] = 1, [3] = 1, [4] = 1, [5] = 1, [6] = 1, [7] = 1, [8] = 1, [10] = 1, [13] = 1, [15] = 1, [16] = 1, [18] = 1},
    PALADIN = {[0] = 1, [1] = 1, [4] = 1, [5] = 1, [6] = 1, [7] = 1, [8] = 1},
    HUNTER = {[0] = 1, [1] = 1, [2] = 1, [3] = 1, [6] = 1, [7] = 1, [8] = 1, [10] = 1, [13] = 1, [15] = 1, [16] = 1, [18] = 1},
    ROGUE = {[2] = 1, [3] = 1, [4] = 1, [7] = 1, [13] = 1, [15] = 1, [16] = 1, [18] = 1},
    PRIEST = {[4] = 1, [10] = 1, [15] = 1, [19] = 1},
    SHAMAN = {[0] = 1, [1] = 1, [4] = 1, [5] = 1, [10] = 1, [13] = 1, [15] = 1},
    MAGE = {[7] = 1, [10] = 1, [15] = 1, [19] = 1},
    WARLOCK = {[7] = 1, [10] = 1, [15] = 1, [19] = 1},
    DRUID = {[4] = 1, [5] = 1, [10] = 1, [13] = 1, [15] = 1},
}
local ARMOR = { -- armor subclass id -> classes (and the level it opens at)
    [2] = {ROGUE = 1, DRUID = 1, HUNTER = 1, SHAMAN = 1, WARRIOR = 1, PALADIN = 1},
    [3] = {HUNTER = 40, SHAMAN = 40, WARRIOR = 1, PALADIN = 1},
    [4] = {WARRIOR = 40, PALADIN = 40},
    [6] = {WARRIOR = 1, PALADIN = 1, SHAMAN = 1},
    [7] = {PALADIN = 1}, [8] = {DRUID = 1}, [9] = {SHAMAN = 1},
}
local ARMOR_WORD = {cloth = 1, leather = 2, mail = 3, plate = 4, shield = 6, libram = 7, idol = 8, totem = 9}

local InstantInfo = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant

-- Is this a piece of gear, and can your class ever wear it?
-- Returns gear, usable, slotText
local function GearKind(id, slotText)
    local cls = PlayerClass()
    local classID, subID, equipLoc
    if InstantInfo then
        local ok, _, _, _, loc, _, c, sub = pcall(InstantInfo, id)
        if ok then classID, subID, equipLoc = c, sub, loc end
    end
    if classID == 2 or classID == 4 then
        if not equipLoc or equipLoc == "" then return false end
        local text = slotText or (_G[equipLoc] or "")
        if classID == 2 then
            return true, (WEAPONS[cls] or {})[subID] ~= nil, text
        end
        local who = ARMOR[subID]
        return true, (not who) or who[cls] ~= nil, text
    elseif classID then
        return false
    end
    -- the game did not answer: go by the journal's own "Legs, Leather" text
    if not slotText then return false end
    local lower = slotText:lower()
    if lower:find("recipe") or lower:find("quest item") or lower:find("blueprint") or lower:find("reagent") then
        return false
    end
    for word, sub in pairs(ARMOR_WORD) do
        if lower:find(word, 1, true) then
            local who = ARMOR[sub]
            return true, (not who) or who[cls] ~= nil, slotText
        end
    end
    return true, true, slotText
end

local function QualityColor(q)
    local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q or 1]
    if c and c.hex then return c.hex end
    return ({[0] = "|cff9d9d9d", "|cffffffff", "|cff1eff00", "|cff0070dd", "|cffa335ee", "|cffff8000"})[q or 1] or "|cffffffff"
end

local function GearRows(d)
    local pages = JournalPages(d)
    if not pages then return nil end
    local api = BiS()
    local side = PlayerSide() == "A" and "Alliance" or "Horde"
    local level = UnitLevel("player") or 1
    local rows, byKey = {}, {}
    local function add(id, name, slotText, quality, source, questID)
        if type(id) ~= "number" or type(name) ~= "string" then return end
        local gear, usable, slot = GearKind(id, slotText)
        if not gear then return end
        local key = id .. "|" .. source
        if byKey[key] then return end
        local row = {id = id, name = name, slot = slot or "", quality = quality, source = source,
                     questID = questID, usable = usable and true or false}
        byKey[key] = row
        if api and row.usable then
            local ok, gain, loading = pcall(api.GetGain, id)
            if ok then row.gain, row.loading = gain, loading end
            local ok2, score = pcall(api.ScoreItem, id)
            if ok2 and type(score) == "number" then row.score = score end
        end
        if GetItemInfo then
            local ok, _, _, _, _, minLevel = pcall(GetItemInfo, id)
            if ok and type(minLevel) == "number" and minLevel > level then row.needLevel = minLevel end
        end
        tinsert(rows, row)
    end
    for key, page in pairs(pages) do
        local wing = key:match(":%s*(.+)$")
        for _, boss in ipairs(type(page.bosses) == "table" and page.bosses or {}) do
            if type(boss) == "table" and type(boss.loot) == "table" then
                for _, it in ipairs(boss.loot) do
                    if type(it) == "table" then
                        local from = boss.trash and ("Trash" .. (it[5] and (": " .. it[5]) or "")) or (boss.name or "?")
                        if wing then from = from .. " (" .. wing .. ")" end
                        add(it[1], it[2], it[3], it[4], from)
                    end
                end
            end
        end
        for _, q in ipairs(type(page.quests) == "table" and page.quests or {}) do
            if type(q) == "table" and type(q.rewardItems) == "table"
                and (not q.faction or q.faction == "Both" or q.faction == side) then
                for _, it in ipairs(q.rewardItems) do
                    if type(it) == "table" then
                        add(it[1], it[2], nil, it[3], "Quest: " .. (q.name or "?"), q.id)
                    end
                end
            end
        end
    end
    -- the best piece here for each slot, by the BiS addon's score
    local best = {}
    for _, row in ipairs(rows) do
        if row.usable and row.score then
            local b = best[row.slot]
            if not b or row.score > b.score then best[row.slot] = row end
        end
    end
    for _, row in pairs(best) do
        -- only worth a mark when it would actually go on: an upgrade now, or gear for a later level
        if (row.gain and row.gain > 0) or (not row.gain and row.needLevel) then row.best = true end
    end
    return rows
end

local function GainText(row)
    if not row.usable then return "|cff808080can't use|r" end
    if row.loading then return "|cff808080...|r" end
    if row.gain then
        if row.gain > 0 then return ("|cff40ff40+%.1f|r"):format(row.gain) end
        if row.gain == 0 then return "|cff808080worn|r" end
        return ("|cff808080%.1f|r"):format(row.gain)
    end
    if row.needLevel then return "|cffffd100Lvl " .. row.needLevel .. "|r" end
    return "|cff808080-|r"
end

local function SortGear(rows)
    local key, desc = state.gearSort, state.gearDesc
    sort(rows, function(a, b)
        local x, y
        if key == "gain" then
            -- upgrades first, then pieces for later levels, then the rest
            x = a.gain or (a.usable and a.needLevel and -1000 or -2000)
            y = b.gain or (b.usable and b.needLevel and -1000 or -2000)
        else
            x, y = a[key] or "", b[key] or ""
        end
        if x == y then
            if a.name ~= b.name then return a.name < b.name end
            return a.source < b.source
        end
        if desc then return x > y end
        return x < y
    end)
end

local function SpecName()
    local api = BiS()
    if not (api and api.GetSpec) then return nil end
    local ok, spec = pcall(api.GetSpec)
    if ok and type(spec) == "string" then return spec:sub(1, 1):upper() .. spec:sub(2) end
end

local function GearDetail(row)
    local L = {}
    tinsert(L, ("%s%s|r  |cffbbbbbb%s|r%s"):format(QualityColor(row.quality), row.name, row.slot,
        row.best and "  |cffffd100Best piece here for this slot|r" or ""))
    tinsert(L, "From: |cffffffff" .. row.source .. "|r")
    if row.questID and ns.quests[row.questID] then
        local st = Status(row.questID)
        tinsert(L, "That quest: " .. (st == "chain" and "needs a chain first" or st == "level" and ("needs level " .. ns.quests[row.questID].req) or STATUS[st].text:lower()) .. ".")
    end
    local spec = SpecName()
    if not row.usable then
        tinsert(L, "Your class can't use this.")
    elseif not BiS() then
        tinsert(L, "|cff999999Install Forever Leveling BiS to see whether it is an upgrade.|r")
    elseif row.loading then
        tinsert(L, "Still loading this item from the game.")
    elseif row.gain and row.gain > 0 then
        tinsert(L, ("|cff40ff40Upgrade of +%.1f|r over what you wear%s."):format(row.gain, spec and (" (" .. spec .. ")") or ""))
    elseif row.gain == 0 then
        tinsert(L, "You are wearing it.")
    elseif row.gain then
        tinsert(L, ("Not an upgrade (%.1f against what you wear%s)."):format(row.gain, spec and (", " .. spec) or ""))
    elseif row.needLevel then
        tinsert(L, ("|cffffd100Needs level %d.|r No comparison until you can wear it."):format(row.needLevel))
    else
        tinsert(L, "No comparison available for this piece.")
    end
    tinsert(L, "|cff999999Point at the row for the item's tooltip. Upgrade numbers are Forever Leveling BiS's, for the spec set there.|r")
    return concat(L, "\n")
end

-- ---------------------------------------------------------------------------
-- Window
-- ---------------------------------------------------------------------------

local frame
local Refresh

local function SelectDungeon(d)
    state.dungeon, state.offset, state.selected, state.gearSelected = d, 0, nil, nil
    if ZDungeonDB then ZDungeonDB.last = d.key end
    Refresh()
end

local function ShowOnMap(p)
    if not (p and p.m) then return end
    if C_Map and C_Map.SetUserWaypoint and UiMapPoint and C_Map.CanSetUserWaypointOnMap
        and C_Map.CanSetUserWaypointOnMap(p.m) then
        pcall(function()
            C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(p.m, p.x / 100, p.y / 100))
            if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
                C_SuperTrack.SetSuperTrackedUserWaypoint(true)
            end
        end)
    end
    if OpenWorldMap then
        pcall(OpenWorldMap, p.m)
    elseif WorldMapFrame then
        if not WorldMapFrame:IsShown() and ToggleWorldMap then pcall(ToggleWorldMap) end
        if WorldMapFrame.SetMapID then pcall(WorldMapFrame.SetMapID, WorldMapFrame, p.m) end
    end
end

local function XPText(xp, approx, unknown)
    if unknown then return "?" end
    return (approx and "~" or "") .. Comma(xp)
end

local function DetailText(row)
    local q = row.q
    local L = {}
    local head = ("|cffffd100%s|r  (level %d, needs level %d)"):format(q.name, q.level, q.req)
    if q.cls then head = head .. "  |cff69ccf0" .. q.cls .. " only|r" end
    tinsert(L, head)
    if q.text and q.text ~= "" then tinsert(L, "|cffbbbbbb" .. q.text .. "|r") end
    if row.status == "log" then
        local left = {}
        for _, o in ipairs(Objectives(row.id)) do
            if not o.done then tinsert(left, o.text) end
        end
        if #left > 0 then
            tinsert(L, "|cffff6644Still needed:|r " .. concat(left, ", "))
        else
            tinsert(L, "|cff40ff40Everything done: ready to hand in.|r")
        end
    end
    tinsert(L, "Pick up from " .. WhereLong(q.start))
    if q.finish and (not q.start or q.finish.n ~= q.start.n) then
        tinsert(L, "Turn in to " .. WhereLong(q.finish))
    end
    if q.skill then tinsert(L, "|cffff6644Needs a profession.|r") end
    if q.rep then tinsert(L, "|cffff6644Needs reputation.|r") end
    if #row.chain > 0 then
        local parts = {}
        for i, p in ipairs(row.chain) do
            local pq = ns.quests[p]
            local who = pq.start and (" - " .. WhereShort(pq.start) .. (pq.start.k ~= "item" and pq.start.m and (": " .. pq.start.n) or "")) or ""
            local xp, approx = QuestXP(p, true)
            local note = InLog(p) and "  |cff66ccff[in your log]|r" or ""
            if (pq.req or 1) > (UnitLevel("player") or 1) then note = note .. "  |cffff6644[needs level " .. pq.req .. "]|r" end
            tinsert(parts, ("  %d. %s (lvl %d, %s XP)%s%s"):format(i, pq.name, pq.level,
                XPText(xp, approx, approx and pq.xp == 0), who, note))
        end
        tinsert(L, ("|cffffd100Do first (%d step%s, +%s XP on the way):|r%s"):format(#row.chain,
            #row.chain == 1 and "" or "s", Comma(row.chainXP),
            row.chainLevel and ("  |cffff6644You can't start this chain until level " .. row.chainLevel .. ".|r") or ""))
        tinsert(L, concat(parts, "\n"))
    end
    local xpLine
    if row.status == "done" then
        xpLine = "Already done on this character."
    elseif row.unknown then
        xpLine = "XP for this quest is not known yet (the game has not answered for it)."
    else
        local need = UnitXPMax and UnitXPMax("player") or 0
        local pct = need > 0 and (" = %.1f%% of your current level"):format(row.xp / need * 100) or ""
        xpLine = ("|cff40ff40%s XP|r at level %d%s"):format(XPText(row.xp, row.approx), UnitLevel("player") or 0, pct)
        if row.approx then xpLine = xpLine .. "  |cff999999(estimate: the game has not given its own number)|r" end
    end
    tinsert(L, xpLine)
    return concat(L, "\n")
end

local function CreateWindow()
    local f = CreateFrame("Frame", "ZDungeonFrame", UIParent, Backdrop)
    f:SetSize(900, 620)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    SetBackdrop(f)
    f:Hide()
    if UISpecialFrames then tinsert(UISpecialFrames, "ZDungeonFrame") end

    local title = Text(f, "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 14, -12)
    title:SetText("ZDungeon")
    local sub = Text(f, "GameFontDisableSmall")
    sub:SetPoint("LEFT", title, "RIGHT", 10, -1)
    sub:SetText("dungeon planner")

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 2, 2)

    local function ModeButton(label, x, mode)
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetSize(74, 22)
        b:SetPoint("TOPRIGHT", x, -9)
        b:SetText(label)
        b:SetScript("OnClick", function()
            state.mode, state.offset = mode, 0
            Refresh()
        end)
        return b
    end
    f.tipsMode = ModeButton("Deep dive", -40, "tips")
    f.gearMode = ModeButton("Gear", -118, "gear")
    f.questMode = ModeButton("Quests", -196, "quests")
    local nextButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    nextButton:SetSize(150, 22)
    nextButton:SetPoint("TOPRIGHT", -278, -9)
    nextButton:SetText("Where do I go next?")
    nextButton:SetScript("OnClick", function() OpenNext() end)

    -- Dungeon list -----------------------------------------------------
    f.dungeonButtons = {}
    local left = CreateFrame("Frame", nil, f, Backdrop)
    left:SetPoint("TOPLEFT", 12, -40)
    left:SetSize(256, 568)
    SetBackdrop(left, 0.6)
    local lh = Text(left, "GameFontNormalSmall")
    lh:SetPoint("TOPLEFT", 8, -7)
    lh:SetText("Dungeon")
    local mode = CreateFrame("Button", nil, left)
    mode:SetSize(110, 18)
    mode:SetPoint("TOPRIGHT", -6, -4)
    f.modeText = Text(mode, "GameFontNormalSmall", "RIGHT")
    f.modeText:SetAllPoints()
    mode:SetScript("OnClick", function()
        state.perHour = not state.perHour
        Refresh()
    end)
    for i = 1, #ns.dungeons do
        local b = CreateFrame("Button", nil, left)
        b:SetSize(248, 20)
        b:SetPoint("TOPLEFT", 4, -24 - (i - 1) * 21)
        b.bg = b:CreateTexture(nil, "BACKGROUND")
        b.bg:SetAllPoints()
        b.bg:SetColorTexture(1, 0.82, 0, 0.18)
        b.bg:Hide()
        local hl = b:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.08)
        b.name = Text(b, "GameFontHighlightSmall")
        b.name:SetPoint("LEFT", 6, 0)
        b.name:SetWidth(178)
        b.xp = Text(b, "GameFontHighlightSmall", "RIGHT")
        b.xp:SetPoint("RIGHT", -6, 0)
        b:SetScript("OnClick", function(self) if self.dungeon then SelectDungeon(self.dungeon) end end)
        f.dungeonButtons[i] = b
    end

    -- Right side -------------------------------------------------------
    local right = CreateFrame("Frame", nil, f, Backdrop)
    right:SetPoint("TOPLEFT", left, "TOPRIGHT", 6, 0)
    right:SetSize(614, 568)
    SetBackdrop(right, 0.6)
    f.right = right

    f.header = Text(right, "GameFontNormalLarge")
    f.header:SetPoint("TOPLEFT", 10, -8)
    local function Wrapped(y, h, w)
        local t = Text(right, "GameFontHighlightSmall")
        t:SetPoint("TOPLEFT", 10, y)
        t:SetWidth(w or 594)
        t:SetHeight(h)
        t:SetJustifyV("TOP")
        if t.SetWordWrap then t:SetWordWrap(true) end
        return t
    end
    f.summary = Wrapped(-30, 26)
    f.travel = Wrapped(-58, 39, 424)
    f.rate = Wrapped(-98, 13)

    f.entranceButton = CreateFrame("Button", nil, right, "UIPanelButtonTemplate")
    f.entranceButton:SetSize(70, 20)
    f.entranceButton:SetPoint("TOPRIGHT", -8, -60)
    f.entranceButton:SetText("Entrance")
    f.entranceButton:SetScript("OnClick", function()
        if state.dungeon then ShowOnMap(state.dungeon.entrance) end
    end)

    f.planButton = CreateFrame("Button", nil, right, "UIPanelButtonTemplate")
    f.planButton:SetSize(88, 20)
    f.planButton:SetPoint("TOPRIGHT", -82, -60)
    f.planButton:SetText("Start guide")
    f.planButton:SetScript("OnClick", function()
        if state.dungeon then StartPlan(state.dungeon) end
    end)

    local function Check(label, x, key)
        local c = CreateFrame("CheckButton", nil, right, "UICheckButtonTemplate")
        c:SetSize(22, 22)
        c:SetPoint("TOPRIGHT", x, -4)
        local t = Text(right, "GameFontHighlightSmall", "RIGHT")
        t:SetPoint("RIGHT", c, "LEFT", -1, 0)
        t:SetText(label)
        c.label = t
        c:SetScript("OnClick", function(self)
            state[key] = self:GetChecked() and true or false
            state.offset = 0
            Refresh()
        end)
        return c
    end
    f.hideDone = Check("Hide done", -8, "hideDone")
    f.otherClasses = Check("Other classes", -100, "otherClasses")
    f.upgradesOnly = Check("Upgrades only", -8, "upgradesOnly")
    f.showUnusable = Check("Show what I can't use", -120, "showUnusable")

    -- column headers (laid out by ApplyLayout for the quest or the gear table)
    f.colHeaders = {}
    for i = 1, #COLS do
        local h = CreateFrame("Button", nil, right)
        h.text = Text(h, "GameFontNormalSmall")
        h.text:SetAllPoints()
        h:SetScript("OnClick", function()
            local col = f.cols and f.cols[i]
            if not col then return end
            if state.mode == "gear" then
                if state.gearSort == col.key then
                    state.gearDesc = not state.gearDesc
                else
                    state.gearSort, state.gearDesc = col.key, col.key == "gain"
                end
            elseif state.sortKey == col.key then
                state.sortDesc = not state.sortDesc
            else
                state.sortKey = col.key
                state.sortDesc = (col.key == "xp" or col.key == "level")
            end
            state.offset = 0
            Refresh()
        end)
        f.colHeaders[i] = h
    end

    -- rows
    f.rows = {}
    local list = CreateFrame("Frame", nil, right)
    list:SetPoint("TOPLEFT", 4, -134)
    list:SetSize(606, ROWS * ROW_H)
    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(_, delta)
        local n = f.data and #f.data or 0
        state.offset = max(0, min(max(0, n - ROWS), state.offset - delta * 3))
        Refresh()
    end)
    for i = 1, ROWS do
        local r = CreateFrame("Button", nil, list)
        r:SetSize(606, ROW_H)
        r:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
        r.bg = r:CreateTexture(nil, "BACKGROUND")
        r.bg:SetAllPoints()
        r.bg:SetColorTexture(1, 0.82, 0, 0.18)
        r.bg:Hide()
        local hl = r:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.07)
        r.cells = {}
        for c = 1, #COLS do
            r.cells[c] = Text(r, "GameFontHighlightSmall")
        end
        r:SetScript("OnClick", function(self)
            if self.row then
                if self.row.isGear then
                    state.gearSelected = self.row.key
                else
                    state.selected = self.row.id
                end
                Refresh()
            end
        end)
        r:SetScript("OnEnter", function(self)
            if self.row and self.row.isGear and GameTooltip then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                pcall(GameTooltip.SetHyperlink, GameTooltip, "item:" .. self.row.id)
                GameTooltip:Show()
            end
        end)
        r:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        f.rows[i] = r
    end
    f.more = Text(right, "GameFontDisableSmall", "RIGHT")
    f.more:SetPoint("TOPRIGHT", list, "BOTTOMRIGHT", -6, -2)

    -- detail
    local detail = CreateFrame("Frame", nil, right, Backdrop)
    detail:SetPoint("BOTTOMLEFT", 4, 4)
    detail:SetSize(606, 166)
    SetBackdrop(detail, 0.5)
    f.detailFrame = detail

    -- deep dive: one long page of text, scrolled with the mouse wheel
    local scroll = CreateFrame("ScrollFrame", nil, right)
    scroll:SetPoint("TOPLEFT", 8, -112)
    scroll:SetSize(598, 448)
    local page = CreateFrame("Frame", nil, scroll)
    page:SetSize(598, 448)
    scroll:SetScrollChild(page)
    f.tipsText = Text(page, "GameFontHighlight")
    f.tipsText:SetPoint("TOPLEFT", 4, -2)
    f.tipsText:SetWidth(580)
    f.tipsText:SetJustifyV("TOP")
    if f.tipsText.SetWordWrap then f.tipsText:SetWordWrap(true) end
    if f.tipsText.SetSpacing then f.tipsText:SetSpacing(4) end
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local h = f.tipsText.GetStringHeight and f.tipsText:GetStringHeight()
        local limit = max(0, (type(h) == "number" and h or 0) - 430)
        f.tipsScroll = max(0, min(limit, (f.tipsScroll or 0) - delta * 60))
        self:SetVerticalScroll(f.tipsScroll)
    end)
    scroll:Hide()
    f.tipsFrame, f.tipsPage = scroll, page
    f.tipsScroll, f.tableShown = 0, true

    f.detail = Text(detail, "GameFontHighlightSmall")
    f.detail:SetPoint("TOPLEFT", 8, -8)
    f.detail:SetWidth(590)
    f.detail:SetHeight(126)
    f.detail:SetJustifyV("TOP")
    if f.detail.SetWordWrap then f.detail:SetWordWrap(true) end
    if f.detail.SetSpacing then f.detail:SetSpacing(2) end

    f.mapButton = CreateFrame("Button", nil, detail, "UIPanelButtonTemplate")
    f.mapButton:SetSize(150, 22)
    f.mapButton:SetPoint("BOTTOMLEFT", 6, 6)
    f.mapButton:SetText("Show pick-up on map")
    f.mapButton:SetScript("OnClick", function(self) ShowOnMap(self.place) end)

    f.guideButton = CreateFrame("Button", nil, detail, "UIPanelButtonTemplate")
    f.guideButton:SetSize(190, 22)
    f.guideButton:SetPoint("BOTTOMRIGHT", -6, 6)
    f.guideButton:SetText("Open walkthrough in ZQuest")
    f.lootButton = CreateFrame("Button", nil, detail, "UIPanelButtonTemplate")
    f.lootButton:SetSize(150, 22)
    f.lootButton:SetPoint("BOTTOMLEFT", 6, 6)
    f.lootButton:SetText("Open in NeedRoll")
    f.lootButton:SetScript("OnClick", function(self)
        if self.item and NeedRoll_ShowItem and pcall(NeedRoll_ShowItem, self.item) then return end
        if state.dungeon and NeedRoll_ShowLoot then pcall(NeedRoll_ShowLoot, state.dungeon.name) end
    end)
    f.lootButton:Hide()

    f.guideButton:SetScript("OnClick", function()
        local api = _G.RXPGuides
        if state.dungeon and api and api.LoadDungeonGuide then
            if api.LoadDungeonGuide(state.dungeon.name) then
                Say("loaded the " .. state.dungeon.name .. " walkthrough in ZQuest.")
            end
        end
    end)
    return f
end

-- Put the column headers and row cells where the active table wants them.
local function ApplyLayout(f, cols)
    if f.cols == cols then return end
    f.cols = cols
    local x = 8
    for i = 1, #COLS do
        local col = cols[i]
        local h = f.colHeaders[i]
        if col then
            local cx = x + (col.pad or 0)
            h:ClearAllPoints()
            h:SetSize(col.w, 18)
            h:SetPoint("TOPLEFT", cx, -114)
            h.text:SetJustifyH(col.justify)
            h:Show()
            for _, r in ipairs(f.rows) do
                local cell = r.cells[i]
                cell:ClearAllPoints()
                cell:SetPoint("LEFT", cx - 4, 0)
                cell:SetWidth(col.w - 4)
                cell:SetJustifyH(col.justify)
                cell:SetTextColor(1, 1, 1)
                cell:Show()
            end
            x = cx + col.w
        else
            h:Hide()
            for _, r in ipairs(f.rows) do r.cells[i]:SetText("") r.cells[i]:Hide() end
        end
    end
end

local function ShowChecks(f, gear)
    for _, c in ipairs({f.hideDone, f.otherClasses}) do c:SetShown(not gear) c.label:SetShown(not gear) end
    for _, c in ipairs({f.upgradesOnly, f.showUnusable}) do c:SetShown(gear) c.label:SetShown(gear) end
    f.hideDone:SetChecked(state.hideDone)
    f.otherClasses:SetChecked(state.otherClasses)
    f.upgradesOnly:SetChecked(state.upgradesOnly)
    f.showUnusable:SetChecked(state.showUnusable)
end

-- The deep dive page for a dungeon: what it is, what to look out for, and
-- what to do in your role (yours first).
local ROLE_FIRST = {WARRIOR = "tank", PRIEST = "heal"}
local ROLE_NAME = {tank = "Tanking it", heal = "Healing it", dps = "Dealing damage"}

local function TipsText(d)
    local t = ns.tips and ns.tips[d.key]
    if not t then
        local have = {}
        for _, other in ipairs(ns.dungeons) do
            if ns.tips and ns.tips[other.key] then tinsert(have, other.name) end
        end
        return "|cffffd100No deep dive written for " .. d.name .. " yet.|r\n\nWritten so far: " .. concat(have, ", ")
            .. ".\n\nThe rest are added as they are researched; Forever changed many of the old dungeons, so they are not filled in from Classic memory."
    end
    local L = {}
    local function head(s) tinsert(L, "") tinsert(L, "|cffffd100" .. s .. "|r") end
    local function list(items) for _, line in ipairs(items or {}) do tinsert(L, "  -  " .. line) end end
    tinsert(L, t.about)
    head("Look out for")
    list(t.watch)
    local first = ROLE_FIRST[PlayerClass()] or "dps"
    local order = {first}
    for _, r in ipairs({"tank", "heal", "dps"}) do if r ~= first then tinsert(order, r) end end
    for i, r in ipairs(order) do
        head(ROLE_NAME[r] .. (i == 1 and "  |cff40ff40(most likely you)|r" or ""))
        list(t[r])
    end
    head("Bosses, in order")
    for i, b in ipairs(t.bosses or {}) do
        tinsert(L, ("  %d.  |cffffffff%s|r  -  %s"):format(i, b[1], b[2]))
    end
    tinsert(L, "")
    tinsert(L, "|cff808080Mechanics checked against current WoW Forever dungeon guides, " .. (ns.tipsChecked or "") .. ". Scroll with the mouse wheel.|r")
    return concat(L, "\n")
end

local function ShowTable(f, on)
    for _, h in ipairs(f.colHeaders) do if not on then h:Hide() end end
    for _, r in ipairs(f.rows) do if not on then r:Hide() end end
    if on then
        f.cols = nil -- the next ApplyLayout shows the headers again
        f.tipsFrame:Hide()
        f.detailFrame:Show()
    else
        f.more:SetText("")
        f.detailFrame:Hide()
        f.tipsFrame:Show()
    end
end

local function RefreshTips(f, d)
    if f.tableShown ~= false then ShowTable(f, false) f.tableShown = false end
    for _, c in ipairs({f.hideDone, f.otherClasses, f.upgradesOnly, f.showUnusable}) do c:Hide() c.label:Hide() end
    f.header:SetText(("%s  |cff888888levels %d-%d|r"):format(d.name, d.lo, d.hi))
    f.summary:SetText("Deep dive: what this dungeon is like and how to play your part in it.")
    f.travel:SetText(TravelText(d))
    f.rate:SetText("")
    f.entranceButton:SetShown(d.entrance and true or false)
    f.tipsText:SetText(TipsText(d))
    if f.tipsFor ~= d then
        f.tipsFor, f.tipsScroll = d, 0
        f.tipsFrame:SetVerticalScroll(0)
    end
    local h = f.tipsText.GetStringHeight and f.tipsText:GetStringHeight()
    f.tipsPage:SetHeight(max(448, (type(h) == "number" and h or 448) + 20))
end

local bisHooked
local function RefreshGear(f, d)
    ApplyLayout(f, GEAR_COLS)
    ShowChecks(f, true)
    f.header:SetText(("%s  |cff888888levels %d-%d|r"):format(d.name, d.lo, d.hi))
    f.travel:SetText(TravelText(d))
    f.rate:SetText("")
    f.entranceButton:SetShown(d.entrance and true or false)
    f.mapButton:Hide()
    f.guideButton:Hide()
    for i, col in ipairs(GEAR_COLS) do
        local arrow = state.gearSort == col.key and (state.gearDesc and " v" or " ^") or ""
        f.colHeaders[i].text:SetText(col.label .. arrow)
    end

    local api = BiS()
    if api and api.OnChanged and not bisHooked then
        bisHooked = true
        pcall(api.OnChanged, function()
            if frame and frame:IsShown() and state.mode == "gear" then ScheduleRefresh() end
        end)
    end

    local all = GearRows(d)
    local data = {}
    if not all then
        f.summary:SetText(Journal() and "DungeonJournal has no loot page for this dungeon."
            or "The gear list is read from the DungeonJournal addon (ForeverDungeonJournal), which is not loaded.")
    else
        local usable, upgrades, top = 0, 0, nil
        for _, row in ipairs(all) do
            row.isGear, row.key = true, row.id .. "|" .. row.source
            if row.usable then
                usable = usable + 1
                if row.gain and row.gain > 0 then
                    upgrades = upgrades + 1
                    if not top or row.gain > top.gain then top = row end
                end
            end
            if (row.usable or state.showUnusable) and not (state.upgradesOnly and not (row.gain and row.gain > 0)) then
                tinsert(data, row)
            end
        end
        SortGear(data)
        local text = ("%d piece%s here your class can use."):format(usable, usable == 1 and "" or "s")
        if api then
            local spec = SpecName()
            text = text .. ("  |cff40ff40%d upgrade%s|r over what you wear%s."):format(upgrades,
                upgrades == 1 and "" or "s", spec and (" as " .. spec) or "")
            if top then
                text = text .. ("  Biggest: %s%s|r (+%.1f) from %s."):format(QualityColor(top.quality), top.name, top.gain, top.source)
            end
        else
            text = text .. "  |cff999999Forever Leveling BiS is not loaded, so they are not ranked.|r"
        end
        f.summary:SetText(text)
    end
    f.data = data

    state.offset = max(0, min(state.offset, max(0, #data - ROWS)))
    local selectedRow
    for _, row in ipairs(data) do if row.key == state.gearSelected then selectedRow = row end end
    if not selectedRow and data[1] then selectedRow = data[1] state.gearSelected = data[1].key end
    for i = 1, ROWS do
        local r = f.rows[i]
        local row = data[i + state.offset]
        r.row = row
        if row then
            r.cells[1]:SetText(QualityColor(row.quality) .. row.name .. "|r" .. (row.best and " |cffffd100*|r" or ""))
            r.cells[2]:SetText(row.slot)
            r.cells[3]:SetText(GainText(row))
            r.cells[4]:SetText(row.source)
            local c = row.usable and 1 or 0.5
            r.cells[2]:SetTextColor(c * 0.85, c * 0.85, c * 0.85)
            r.cells[3]:SetTextColor(1, 1, 1)
            r.cells[4]:SetTextColor(c * 0.85, c * 0.85, c * 0.85)
            r.bg:SetShown(row.key == state.gearSelected)
            r:Show()
        else
            r:Hide()
        end
    end
    if #data > ROWS then
        f.more:SetText(("showing %d-%d of %d (scroll for more)   * best piece here for its slot"):format(state.offset + 1,
            min(#data, state.offset + ROWS), #data))
    else
        f.more:SetText(#data > 0 and "* best piece here for its slot" or "")
    end
    if selectedRow then
        f.detail:SetText(GearDetail(selectedRow))
    else
        f.detail:SetText(all and "Nothing to show here with the current filters." or "")
    end
    f.lootButton.item = selectedRow and selectedRow.id or nil
    f.lootButton:SetShown((NeedRoll_ShowItem or NeedRoll_ShowLoot) and all and true or false)
end

Refresh = function()
    if not frame or not frame:IsShown() then return end
    logCache = nil
    local f = frame
    local side = PlayerSide()
    local lvl = UnitLevel("player") or 1

    -- dungeon list
    f.modeText:SetText(state.perHour and "XP per hour  <>" or "XP left  <>")
    local shown = 0
    local first
    for _, d in ipairs(ns.dungeons) do
        if not d.side or d.side == side then
            local now, all, extra, count, left = DungeonTotals(d)
            if count > 0 or JournalPages(d) then
                shown = shown + 1
                first = first or d
                local b = f.dungeonButtons[shown]
                b.dungeon = d
                b.name:SetText(("%s |cff888888%d-%d|r"):format(d.name, d.lo, d.hi))
                if count == 0 then
                    b.xp:SetText("|cff808080gear only|r")
                elseif left == 0 then
                    b.xp:SetText("|cff808080done|r")
                elseif state.perHour then
                    local rate = now > 0 and PerHour(d, now)
                    b.xp:SetText(rate and Comma(rate) or "|cff808080-|r")
                else
                    b.xp:SetText(all > 0 and Comma(all) or "?")
                end
                if lvl < d.lo - 2 then
                    b.name:SetTextColor(1, 0.4, 0.3)
                elseif lvl > d.hi + 2 then
                    b.name:SetTextColor(0.6, 0.6, 0.6)
                else
                    b.name:SetTextColor(1, 1, 1)
                end
                b.bg:SetShown(state.dungeon == d)
                b:Show()
            end
        end
    end
    for i = shown + 1, #f.dungeonButtons do f.dungeonButtons[i]:Hide() end
    if not state.dungeon then
        -- open on the dungeon you are in, else the last one used, else the first in your level range
        state.dungeon = run.dungeon or preview
        for i = 1, shown do
            local d = f.dungeonButtons[i].dungeon
            if not state.dungeon and ZDungeonDB and ZDungeonDB.last == d.key then state.dungeon = d end
        end
        if not state.dungeon then
            for i = 1, shown do
                local d = f.dungeonButtons[i].dungeon
                if lvl <= d.hi then state.dungeon = d break end
            end
        end
        state.dungeon = state.dungeon or first
        for i = 1, shown do f.dungeonButtons[i].bg:SetShown(f.dungeonButtons[i].dungeon == state.dungeon) end
    end
    local d = state.dungeon
    if not d then
        f.header:SetText("No dungeon quests found for this character")
        return
    end

    if state.mode == "tips" then
        RefreshTips(f, d)
        return
    end
    if f.tableShown == false then ShowTable(f, true) f.tableShown = true end
    if state.mode == "gear" then
        RefreshGear(f, d)
        return
    end
    ApplyLayout(f, COLS)
    ShowChecks(f, false)
    f.lootButton:Hide()

    -- rows first: building them asks the game for any XP it has not loaded
    local data = BuildRows(d)
    f.data = data

    -- header
    local now, all, extra, count, left = DungeonTotals(d)
    f.header:SetText(("%s  |cff888888levels %d-%d|r"):format(d.name, d.lo, d.hi))
    local need = UnitXPMax and UnitXPMax("player") or 0
    local function pct(v) return need > 0 and (" (%.0f%% of a level)"):format(v / need * 100) or "" end
    if count == 0 then
        f.summary:SetText("No quest data for this dungeon yet. Its gear is under the Gear button.")
    elseif left == 0 then
        f.summary:SetText(("All %d quests done."):format(count))
    else
        local text = ("|cff40ff40%s XP|r ready to pick up now%s.  |cffffd100%s XP|r for all %d quests left%s.")
            :format(Comma(now), pct(now), Comma(all), left, pct(all))
        if extra > 0 then
            text = text .. ("  Chain steps on the way add %s XP."):format(Comma(extra))
        end
        f.summary:SetText(text)
    end

    -- getting there
    f.travel:SetText(TravelText(d))
    local rateText = ""
    if left > 0 and now > 0 then
        local rate, mins = PerHour(d, now)
        if rate then
            local runMins, mine = RunMinutes(d)
            rateText = ("|cff40ff40About %s quest XP per hour|r for the trip: %d min there and back, %d min inside (%s). Kill XP is extra.")
                :format(Comma(rate), floor(mins - runMins + 0.5), floor(runMins + 0.5),
                    mine and "your average" or "a typical run")
        end
    end
    f.rate:SetText(rateText)
    f.entranceButton:SetShown(d.entrance and true or false)

    -- headers
    for i, col in ipairs(COLS) do
        local arrow = state.sortKey == col.key and (state.sortDesc and " v" or " ^") or ""
        f.colHeaders[i].text:SetText(col.label .. arrow)
    end

    -- rows
    state.offset = max(0, min(state.offset, max(0, #data - ROWS)))
    local selectedRow
    for _, row in ipairs(data) do if row.id == state.selected then selectedRow = row end end
    if not selectedRow and data[1] then selectedRow = data[1] state.selected = data[1].id end
    for i = 1, ROWS do
        local r = f.rows[i]
        local row = data[i + state.offset]
        r.row = row
        if row then
            local st = STATUS[row.status]
            local name = row.q.cls and (row.name .. " |cff69ccf0[" .. row.q.cls .. "]|r") or row.name
            r.cells[1]:SetText(name)
            r.cells[2]:SetText(row.level)
            if row.status == "done" then
                r.cells[3]:SetText("-")
            else
                r.cells[3]:SetText(XPText(row.xp, row.approx, row.unknown))
            end
            local stText = st.text
            if row.status == "level" then stText = "Level " .. row.q.req end
            if row.status == "chain" then
                stText = row.chainLevel and ("Chain (%d), level %d"):format(#row.chain, row.chainLevel)
                    or ("Chain first (%d)"):format(#row.chain)
            end
            r.cells[4]:SetText(stText)
            r.cells[4]:SetTextColor(st.r, st.g, st.b)
            r.cells[5]:SetText(row.where)
            local dim = row.status == "done"
            local c = dim and 0.5 or 1
            r.cells[1]:SetTextColor(c, c, c)
            r.cells[2]:SetTextColor(c, c, c)
            r.cells[5]:SetTextColor(c * 0.85, c * 0.85, c * 0.85)
            if dim then r.cells[3]:SetTextColor(0.5, 0.5, 0.5) else r.cells[3]:SetTextColor(0.25, 1, 0.25) end
            r.bg:SetShown(row.id == state.selected)
            r:Show()
        else
            r:Hide()
        end
    end
    if #data > ROWS then
        f.more:SetText(("showing %d-%d of %d (scroll for more)"):format(state.offset + 1,
            min(#data, state.offset + ROWS), #data))
    else
        f.more:SetText("")
    end

    -- detail
    if selectedRow then
        f.detail:SetText(DetailText(selectedRow))
        local p = selectedRow.q.start
        -- point at the first chain step when there is one
        if #selectedRow.chain > 0 then
            local pq = ns.quests[selectedRow.chain[1]]
            if pq and pq.start and pq.start.m then p = pq.start end
            f.mapButton:SetText("Show first step on map")
        else
            f.mapButton:SetText("Show pick-up on map")
        end
        f.mapButton.place = p
        f.mapButton:SetShown(p and p.m and true or false)
    else
        f.detail:SetText(#data == 0 and "Nothing to show here with the current filters." or "")
        f.mapButton:Hide()
    end
    local api = _G.RXPGuides
    f.guideButton:SetShown(api and api.HasDungeonGuide and api.HasDungeonGuide(d.name) and true or false)
end

local function Toggle()
    if not frame then frame = CreateWindow() end
    if frame:IsShown() then
        frame:Hide()
    else
        state.dungeon = run.dungeon or preview or state.dungeon
        frame:Show()
        Refresh()
    end
end
ns.Toggle = Toggle

function ZDungeon_OnAddonCompartmentClick() Toggle() end

SLASH_ZDUNGEON1 = "/zd"
SLASH_ZDUNGEON2 = "/zdungeon"
SlashCmdList["ZDUNGEON"] = function(input)
    input = type(input) == "string" and input:lower():gsub("^%s+", ""):gsub("%s+$", "") or ""
    if input == "tracker" then
        ZDungeonDB.noTracker = not ZDungeonDB.noTracker
        if tracker then tracker.closedFor = nil end
        Say("the in-dungeon tracker is " .. (ZDungeonDB.noTracker and "off." or "on."))
        UpdateTracker()
    elseif input == "next" then
        OpenNext()
    elseif input == "guide" or input == "plan" then
        if plan and ZDungeonDB.cardHidden then
            ZDungeonDB.cardHidden = nil
            UpdateCard()
        elseif plan and card and card:IsShown() then
            ZDungeonDB.cardHidden = true
            UpdateCard()
            UpdateTracker()
        else
            local d = run.dungeon or preview or state.dungeon
            if d then StartPlan(d) else OpenNext() end
        end
    elseif input == "check" then
        local d = run.dungeon or preview or state.dungeon
        if d then Checklist(d, "manual") else Say("open /zd and pick a dungeon first.") end
    else
        Toggle()
    end
end

-- ---------------------------------------------------------------------------
-- The guide card: one dungeon, step by step
--
-- A small window like ZQuest's guide card. It lists what to do for one
-- dungeon in order: chain quests first, pick-ups (nearest first), the trip
-- to the entrance, what to get inside, and the hand-ins. Steps tick
-- themselves off from your quest log.
-- ---------------------------------------------------------------------------

local function CharKey()
    return (UnitName and UnitName("player") or "?") .. "-" .. (GetRealmName and GetRealmName() or "?")
end

local function DungeonByKey(key)
    for _, d in ipairs(ns.dungeons) do if d.key == key then return d end end
end

local function PlaceKey(p)
    return (p and p.n or "?") .. "|" .. (p and p.m or 0)
end

local function PlaceText(p)
    if not p then return "?" end
    if p.inside then return p.n .. " (inside)" end
    if p.m then return ("%s, %s (%.0f, %.0f)"):format(p.n, ZoneName(p.m) or "?", p.x or 0, p.y or 0) end
    return p.n
end

local function TravelSecs(p)
    local api = _G.RXPGuides
    if not (p and p.m and api and api.TravelEstimate) then return nil end
    local ok, t = pcall(api.TravelEstimate, p.m, p.x, p.y, p.n)
    return ok and type(t) == "table" and t.secs or nil
end

-- The steps for the current plan, with live done flags.
local function PlanSteps()
    local d = plan and DungeonByKey(plan.key)
    if not d then return nil end
    local steps = {}
    local function add(step) tinsert(steps, step) end
    local myLevel = UnitLevel("player") or 1
    -- the level a quest is really waiting for: the highest one its unfinished chain asks for
    local function LockLevel(id)
        local need = 0
        for _, p in ipairs(Chain(id)) do
            local q = ns.quests[p]
            if q and (q.req or 1) > myLevel and q.req > need then need = q.req end
        end
        return need > 0 and need or nil
    end
    local function GroupLock(ids)
        local need = nil
        for _, id in ipairs(ids) do
            if not IsDone(id) and not InLog(id) then
                local l = LockLevel(id)
                if not l then return nil end
                if not need or l > need then need = l end
            end
        end
        return need
    end

    for _, id in ipairs(plan.chain) do
        local q = ns.quests[id]
        if q then
            local lvl = UnitLevel("player") or 1
            local blocked = not IsDone(id) and not InLog(id) and (q.req or 1) > lvl
            add({kind = "chain", text = "Chain quest: " .. q.name,
                 sub = blocked and ("Needs level " .. q.req .. ". You are level " .. lvl .. ".")
                     or (InLog(id) and "In your log. Finish it and hand it in." or ("Get it from " .. PlaceText(q.start))),
                 place = q.start, done = IsDone(id), blocked = blocked, level = q.req})
        end
    end

    -- pick-ups outside, one step per quest giver, in the order worked out when the plan started
    local groups, order = {}, {}
    for _, id in ipairs(plan.ids) do
        local q = ns.quests[id]
        local p = q and q.start
        if p and not p.inside and p.k ~= "item" then
            local k = PlaceKey(p)
            if not groups[k] then groups[k] = {place = p, ids = {}} tinsert(order, k) end
            tinsert(groups[k].ids, id)
        end
    end
    sort(order, function(a, b)
        local x, y = plan.order[a] or 1e9, plan.order[b] or 1e9
        if x == y then return a < b end
        return x < y
    end)
    for _, k in ipairs(order) do
        local g = groups[k]
        local names, done = {}, true
        for _, id in ipairs(g.ids) do
            tinsert(names, ns.quests[id].name)
            if not (IsDone(id) or InLog(id)) then done = false end
        end
        local lock = not done and GroupLock(g.ids) or nil
        add({kind = "pickup", text = "Pick up from " .. g.place.n, sub = concat(names, ", ") .. "  -  " .. (ZoneName(g.place.m) or "?")
             .. (" (%.0f, %.0f)"):format(g.place.x or 0, g.place.y or 0), place = g.place, done = done,
             blocked = lock and true or false, level = lock})
    end

    local arrived = plan.arrived or run.dungeon == d
    local travel = "Go to " .. d.name
    local tsub = d.entrance and (("Entrance: %s (%.0f, %.0f)"):format(ZoneName(d.entrance.m) or "?", d.entrance.x, d.entrance.y)) or ""
    if not arrived then
        local t = Travel(d)
        if t then
            tsub = tsub .. ".  About " .. Minutes(t.secs)
            if t.legs and t.legs[1] then tsub = tsub .. ": " .. t.legs[1].text end
        end
    end
    add({kind = "travel", text = travel, sub = tsub, place = d.entrance, done = arrived and true or false})

    for _, id in ipairs(plan.ids) do
        local q = ns.quests[id]
        local p = q and q.start
        if p and (p.inside or p.k == "item") then
            add({kind = "inside", text = "Inside: get " .. q.name,
                 sub = p.k == "item" and ("Drops from " .. (p.from or "?")) or ("From " .. p.n), done = IsDone(id) or InLog(id)})
        end
    end

    for _, id in ipairs(plan.ids) do
        local q = ns.quests[id]
        if q then
            local done, sub = IsDone(id), nil
            if not done then
                if InLog(id) then
                    local left = {}
                    for _, o in ipairs(Objectives(id)) do if not o.done then tinsert(left, o.text) end end
                    if #left == 0 then done = true else sub = concat(left, ", ") end
                else
                    sub = "Not picked up yet."
                end
            end
            local lock = not done and not InLog(id) and LockLevel(id) or nil
            add({kind = "do", text = "Finish: " .. q.name, sub = sub, done = done, blocked = lock and true or false, level = lock})
        end
    end

    local tgroups, torder = {}, {}
    for _, id in ipairs(plan.ids) do
        local q = ns.quests[id]
        local p = q and (q.finish or q.start)
        if p then
            local k = PlaceKey(p)
            if not tgroups[k] then tgroups[k] = {place = p, ids = {}} tinsert(torder, k) end
            tinsert(tgroups[k].ids, id)
        end
    end
    for _, k in ipairs(torder) do
        local g = tgroups[k]
        local names, done = {}, true
        for _, id in ipairs(g.ids) do
            tinsert(names, ns.quests[id].name)
            if not IsDone(id) then done = false end
        end
        local lock = not done and GroupLock(g.ids) or nil
        add({kind = "turnin", text = "Hand in to " .. g.place.n, sub = concat(names, ", ") .. "  -  " .. PlaceText(g.place),
             place = g.place.m and g.place or nil, done = done, blocked = lock and true or false, level = lock})
    end
    return steps, d
end

local function CreateCard()
    local f = CreateFrame("Frame", "ZDungeonCard", UIParent, Backdrop)
    f:SetSize(320, 160)
    f:SetPoint("LEFT", UIParent, "LEFT", 40, 60)
    f:SetFrameStrata("MEDIUM")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if ZDungeonDB and self.GetPoint then
            local point, _, rel, x, y = self:GetPoint(1)
            if point then ZDungeonDB.cardPos = {point, rel, x, y} end
        end
    end)
    SetBackdrop(f, 0.85)
    local pos = ZDungeonDB and ZDungeonDB.cardPos
    if pos and pos[1] then
        f:ClearAllPoints()
        f:SetPoint(pos[1], UIParent, pos[2] or pos[1], pos[3] or 0, pos[4] or 0)
    end
    f.title = Text(f, "GameFontNormal")
    f.title:SetPoint("TOPLEFT", 10, -8)
    f.title:SetWidth(270)
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 3, 3)
    close:SetScript("OnClick", function()
        if ZDungeonDB then ZDungeonDB.cardHidden = true end
        UpdateCard()
        UpdateTracker()
    end)
    f.body = Text(f, "GameFontHighlightSmall")
    f.body:SetPoint("TOPLEFT", 10, -30)
    f.body:SetWidth(300)
    f.body:SetJustifyV("TOP")
    if f.body.SetWordWrap then f.body:SetWordWrap(true) end
    if f.body.SetSpacing then f.body:SetSpacing(3) end
    local function Button(label, w, x, fn)
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetSize(w, 20)
        b:SetPoint("BOTTOMLEFT", x, 8)
        b:SetText(label)
        b:SetScript("OnClick", fn)
        return b
    end
    f.mapButton = Button("Map", 50, 8, function(self) ShowOnMap(self.place) end)
    f.nextButton = Button("Where next?", 92, 60, function() OpenNext() end)
    f.arrowButton = Button("Arrow on", 76, 154, function()
        if ZDungeonDB then ZDungeonDB.noArrow = not ZDungeonDB.noArrow end
        UpdateCard()
    end)
    f.openButton = Button("Details", 66, 232, function()
        local d = plan and DungeonByKey(plan.key)
        if d then
            if not frame then frame = CreateWindow() end
            state.dungeon, state.offset, state.selected = d, 0, nil
            frame:Show()
            Refresh()
        end
    end)
    f:Hide()
    return f
end

local function ReleaseArrow()
    local api = _G.RXPGuides
    if card and card.arrowKey and api and api.ClearArrowTarget then pcall(api.ClearArrowTarget) end
    if card then card.arrowKey = nil end
end

UpdateCard = function()
    if not plan or (ZDungeonDB and ZDungeonDB.cardHidden) then
        ReleaseArrow()
        if card then card:Hide() end
        return
    end
    local steps, d = PlanSteps()
    if not steps then
        if card then card:Hide() end
        return
    end
    if run.dungeon == d and not plan.arrived then
        plan.arrived = true
        steps = PlanSteps()
    end
    if not card then card = CreateCard() end
    -- a chain step you are too low for holds up everything that needs it:
    -- the first thing you can actually do is the current step
    local held = false
    for _, st in ipairs(steps) do
        if st.kind == "chain" and st.blocked and not st.done then held = true end
    end
    local doneCount, current, waiting, waitLevel = 0, nil, {}, 0
    for i, st in ipairs(steps) do
        if st.done then
            doneCount = doneCount + 1
        elseif st.blocked then
            tinsert(waiting, st)
            if (st.level or 0) > waitLevel then waitLevel = st.level end
        elseif st.kind == "chain" and held then
            tinsert(waiting, st) -- later links of a chain whose first link is level-locked
        elseif not current then
            current = i
        end
    end
    card.title:SetText(("%s  |cff888888%d of %d|r"):format(d.name, doneCount, #steps))
    local L = {}
    if not current then
        if #waiting > 0 then
            tinsert(L, ("|cffff6644Nothing more to do here until level %d.|r"):format(waitLevel))
        else
            tinsert(L, "|cff40ff40Everything on this list is done.|r")
        end
        tinsert(L, "Click |cffffd100Where next?|r for your next options.")
    else
        if doneCount > 0 then
            tinsert(L, ("|cff808080[x] %d step%s done|r"):format(doneCount, doneCount == 1 and "" or "s"))
        end
        local st = steps[current]
        tinsert(L, "|cffffd100> " .. st.text .. "|r")
        if st.sub and st.sub ~= "" then tinsert(L, "   |cffffffff" .. st.sub .. "|r") end
        local shown, rest = 0, 0
        for i = current + 1, #steps do
            local n = steps[i]
            if not n.done and not n.blocked then
                if shown < 5 then
                    tinsert(L, "|cffbbbbbb[ ] " .. n.text .. "|r")
                    shown = shown + 1
                else
                    rest = rest + 1
                end
            end
        end
        if rest > 0 then tinsert(L, ("|cff808080... and %d more|r"):format(rest)) end
    end
    if #waiting > 0 then
        tinsert(L, ("|cffff6644Waiting for level %d:|r"):format(waitLevel > 0 and waitLevel or 0))
        for i, st in ipairs(waiting) do
            if i <= 4 then tinsert(L, "|cffff6644   " .. st.text .. "|r") end
        end
        if #waiting > 4 then tinsert(L, ("|cff808080   ... and %d more|r"):format(#waiting - 4)) end
    end
    card.body:SetText(concat(L, "\n"))
    local place = current and steps[current].place or nil
    -- hand ZQuest's arrow the current step (and give it back when there is none)
    local api = _G.RXPGuides
    if api and api.SetArrowTarget then
        local want = nil
        if place and place.m and place.x and not (ZDungeonDB and ZDungeonDB.noArrow) then
            want = place.m .. ":" .. place.x .. ":" .. place.y .. ":" .. steps[current].text
        end
        if want ~= card.arrowKey then
            card.arrowKey = want
            if want then
                pcall(api.SetArrowTarget, place.m, place.x, place.y, steps[current].text)
            elseif api.ClearArrowTarget then
                pcall(api.ClearArrowTarget)
            end
        end
    end
    card.arrowButton:SetText((ZDungeonDB and ZDungeonDB.noArrow) and "Arrow off" or "Arrow on")
    card.arrowButton:SetShown(api and api.SetArrowTarget and true or false)
    card.mapButton.place = place
    card.mapButton:SetShown(place and place.m and true or false)
    local h = card.body.GetStringHeight and card.body:GetStringHeight()
    card:SetHeight((type(h) == "number" and h or 110) + 70)
    card:Show()
    if plan.wasDone == false and not current then
        Say(("%s: everything on your guide is done. Click Where next? for your options."):format(d.name))
    end
    plan.wasDone = not current
    if tracker and tracker:IsShown() then UpdateTracker() end
end

StartPlan = function(d)
    logCache = nil
    local ids, chain, seen, order = {}, {}, {}, {}
    for _, id in ipairs(d.quests) do
        local q = ns.quests[id]
        if q and ForMySide(q) and ForMyClass(q) then
            local st = Status(id)
            if st == "ready" or st == "log" or st == "chain" then
                tinsert(ids, id)
                for _, p in ipairs(Chain(id)) do
                    if not seen[p] then seen[p] = true tinsert(chain, p) end
                end
            end
        end
    end
    -- quests that are both a chain step and a dungeon quest stay in the quest list only
    local isQuest = {}
    for _, id in ipairs(ids) do isQuest[id] = true end
    local onlyChain = {}
    for _, id in ipairs(chain) do if not isQuest[id] then tinsert(onlyChain, id) end end
    -- nearest quest giver first, by travel time from where you are now
    -- ...but a quest that needs another quest on this list comes after it
    local secs, depth = {}, {}
    for _, id in ipairs(ids) do
        local p = ns.quests[id].start
        if p then
            local k = PlaceKey(p)
            if secs[k] == nil then secs[k] = (p.m and TravelSecs(p)) or 36000 end
            local n = 0
            for _, c in ipairs(Chain(id)) do if isQuest[c] then n = n + 1 end end
            depth[k] = min(depth[k] or 99, n)
        end
    end
    for k, v in pairs(secs) do order[k] = (depth[k] or 0) * 100000 + v end
    plan = {key = d.key, ids = ids, chain = onlyChain, order = order, arrived = run.dungeon == d, wasDone = false}
    if ZDungeonDB then
        ZDungeonDB.plans = ZDungeonDB.plans or {}
        ZDungeonDB.plans[CharKey()] = plan
        ZDungeonDB.cardHidden = nil
    end
    if #ids == 0 then
        Say(d.name .. ": no quests you can do there right now, so the guide only has the trip.")
    end
    UpdateCard()
    UpdateTracker()
end

-- ---------------------------------------------------------------------------
-- Where do I go next?
-- ---------------------------------------------------------------------------

local nextFrame

local function NextOptions()
    logCache = nil
    local lvl = UnitLevel("player") or 1
    local side = PlayerSide()
    local list, upcoming = {}, nil
    for _, d in ipairs(ns.dungeons) do
        if not d.side or d.side == side then
            if lvl >= d.lo and lvl <= d.hi + 2 then
                local now, all, extra, count, left = DungeonTotals(d)
                local n = Needs(d)
                local rate, mins = nil, nil
                if now > 0 then rate, mins = PerHour(d, now) end
                local t = Travel(d)
                if left > 0 then tinsert(list, {d = d, now = now, all = all, left = left, count = count, rate = rate,
                               secs = t and t.secs, ready = #n.outside + #n.inside, inlog = #n.needed + #n.turnin,
                               locked = #n.locked, score = (rate or now) + left * 0.001}) end
            elseif lvl < d.lo and (not upcoming or d.lo < upcoming.lo) then
                upcoming = d
            end
        end
    end
    sort(list, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        return a.d.lo < b.d.lo
    end)
    local top = {}
    for i = 1, min(3, #list) do
        local o = list[i]
        -- gear only for the ones shown: it makes the game load every item
        local rows = GearRows(o.d)
        if rows then
            o.upgrades = 0
            for _, row in ipairs(rows) do
                if row.usable and row.gain and row.gain > 0 then
                    o.upgrades = o.upgrades + 1
                    if not o.bestGear or row.gain > o.bestGear.gain then o.bestGear = row end
                end
            end
        end
        tinsert(top, o)
    end
    return top, upcoming
end

local function OptionText(i, o)
    local d = o.d
    local L = {}
    tinsert(L, ("|cffffd100%d. %s|r  |cff888888levels %d-%d|r"):format(i, d.name, d.lo, d.hi))
    local q
    if o.count == 0 then
        q = "No quest data yet."
    elseif o.left == 0 then
        q = "All quests done."
    else
        q = ("|cff40ff40%s quest XP|r ready"):format(Comma(o.now))
        local bits = {}
        if o.inlog > 0 then tinsert(bits, o.inlog .. " in your log") end
        if o.ready > 0 then tinsert(bits, o.ready .. " to pick up") end
        if o.locked > 0 then tinsert(bits, o.locked .. " behind a chain or level") end
        if #bits > 0 then q = q .. " (" .. concat(bits, ", ") .. ")" end
        q = q .. "."
    end
    tinsert(L, q)
    local trip = {}
    if o.secs then tinsert(trip, "About " .. Minutes(o.secs) .. " away") end
    if o.rate then tinsert(trip, ("about %s quest XP per hour"):format(Comma(o.rate))) end
    if #trip > 0 then tinsert(L, concat(trip, ", ") .. ".") end
    if o.upgrades then
        if o.upgrades > 0 then
            tinsert(L, ("|cff40ff40%d gear upgrade%s|r, best: %s%s|r (+%.1f)."):format(o.upgrades, o.upgrades == 1 and "" or "s",
                QualityColor(o.bestGear.quality), o.bestGear.name, o.bestGear.gain))
        else
            tinsert(L, "|cff808080No gear upgrades for you there right now.|r")
        end
    end
    return concat(L, "\n")
end

local function CreateNext()
    local f = CreateFrame("Frame", "ZDungeonNext", UIParent, Backdrop)
    f:SetSize(560, 200)
    f:SetPoint("CENTER", 0, 80)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    SetBackdrop(f)
    if UISpecialFrames then tinsert(UISpecialFrames, "ZDungeonNext") end
    local title = Text(f, "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 14, -12)
    title:SetText("Where do I go next?")
    f.note = Text(f, "GameFontDisableSmall")
    f.note:SetPoint("TOPLEFT", 14, -36)
    f.note:SetWidth(520)
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 2, 2)
    f.options = {}
    for i = 1, 3 do
        local o = CreateFrame("Frame", nil, f, Backdrop)
        o:SetSize(536, 92)
        o:SetPoint("TOPLEFT", 12, -58 - (i - 1) * 98)
        SetBackdrop(o, 0.6)
        o.text = Text(o, "GameFontHighlightSmall")
        o.text:SetPoint("TOPLEFT", 10, -8)
        o.text:SetWidth(400)
        o.text:SetHeight(78)
        o.text:SetJustifyV("TOP")
        if o.text.SetWordWrap then o.text:SetWordWrap(true) end
        if o.text.SetSpacing then o.text:SetSpacing(2) end
        o.go = CreateFrame("Button", nil, o, "UIPanelButtonTemplate")
        o.go:SetSize(104, 22)
        o.go:SetPoint("TOPRIGHT", -10, -14)
        o.go:SetText("Start guide")
        o.go:SetScript("OnClick", function()
            if o.dungeon then StartPlan(o.dungeon) f:Hide() end
        end)
        o.open = CreateFrame("Button", nil, o, "UIPanelButtonTemplate")
        o.open:SetSize(104, 22)
        o.open:SetPoint("TOPRIGHT", -10, -44)
        o.open:SetText("Details")
        o.open:SetScript("OnClick", function()
            if not o.dungeon then return end
            if not frame then frame = CreateWindow() end
            state.dungeon, state.offset, state.selected, state.gearSelected = o.dungeon, 0, nil, nil
            frame:Show()
            Refresh()
            f:Hide()
        end)
        f.options[i] = o
    end
    f:Hide()
    return f
end

local function RefreshNext()
    if not nextFrame or not nextFrame:IsShown() then return end
    local top, upcoming = NextOptions()
    local lvl = UnitLevel("player") or 1
    for i = 1, 3 do
        local o, row = top[i], nextFrame.options[i]
        row.dungeon = o and o.d or nil
        if o then
            row.text:SetText(OptionText(i, o))
            row:Show()
        else
            row:Hide()
        end
    end
    local note
    if #top == 0 then
        note = upcoming and ("No dungeon is in your level range yet. %s opens at level %d."):format(upcoming.name, upcoming.lo)
            or "No dungeon is in your level range."
    else
        note = ("Dungeons in range at level %d, best quest XP per hour first."):format(lvl)
        if upcoming then note = note .. ("  Next to open: %s at level %d."):format(upcoming.name, upcoming.lo) end
    end
    nextFrame.note:SetText(note)
    nextFrame:SetHeight(66 + max(1, #top) * 98)
end

OpenNext = function()
    if not nextFrame then nextFrame = CreateNext() end
    nextFrame:Show()
    RefreshNext()
end

-- A cheer when a level opens something new: a dungeon, or dungeon quests.
local function OnLevelUp(level)
    level = tonumber(level) or UnitLevel("player") or 1
    local side = PlayerSide()
    local opened, quests = {}, {}
    for _, d in ipairs(ns.dungeons) do
        if not d.side or d.side == side then
            if d.lo == level then
                tinsert(opened, ("%s (levels %d-%d)"):format(d.name, d.lo, d.hi))
            end
            if level >= d.lo - 2 and level <= d.hi + 2 then
                for _, id in ipairs(d.quests) do
                    local q = ns.quests[id]
                    if q and q.req == level and ForMySide(q) and ForMyClass(q) and not IsDone(id) then
                        tinsert(quests, q.name .. " (" .. d.name .. ")")
                    end
                end
            end
        end
    end
    if #opened == 0 and #quests == 0 then return end
    if #opened > 0 then
        Alert(("Congratulations on level %d! New dungeon%s for you: %s."):format(level, #opened == 1 and "" or "s", concat(opened, ", ")))
    else
        Alert(("Congratulations on level %d! %d new dungeon quest%s you can pick up."):format(level, #quests, #quests == 1 and "" or "s"))
    end
    for i, name in ipairs(quests) do
        if i <= 6 then Say("   New quest: " .. name) end
    end
    Say("Type /zd next, or click Where do I go next?, to see your best options.")
end

-- ---------------------------------------------------------------------------
-- Events
-- ---------------------------------------------------------------------------

local pending
ScheduleRefresh = function()
    if pending then return end
    pending = true
    C_Timer.After(0.4, function()
        pending = false
        logCache = nil
        Refresh()
        UpdateCard()
        UpdateTracker()
        if nextFrame and nextFrame:IsShown() then RefreshNext() end
    end)
end

local events = CreateFrame("Frame")
for _, e in ipairs({"ADDON_LOADED", "QUEST_LOG_UPDATE", "PLAYER_LEVEL_UP", "QUEST_TURNED_IN", "QUEST_ACCEPTED",
                    "QUEST_DATA_LOAD_RESULT", "BAG_UPDATE_DELAYED", "PLAYER_ENTERING_WORLD", "ZONE_CHANGED",
                    "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA", "PLAYER_UNGHOST", "PLAYER_ALIVE",
                    "ENCOUNTER_END", "BOSS_KILL", "GET_ITEM_INFO_RECEIVED"}) do
    pcall(events.RegisterEvent, events, e)
end
events:SetScript("OnEvent", function(_, event, arg1, arg2, arg3, arg4, arg5)
    if event == "ADDON_LOADED" then
        if arg1 == addonName then
            ZDungeonDB = ZDungeonDB or {}
            local saved = ZDungeonDB.plans and ZDungeonDB.plans[CharKey()]
            if type(saved) == "table" and saved.key and type(saved.ids) == "table" then
                saved.chain, saved.order = saved.chain or {}, saved.order or {}
                plan = saved
            end
            print("|cffffd100ZDungeon|r loaded. Type |cffffffff/zd|r to see dungeon quests and their XP.")
        end
    elseif event == "ENCOUNTER_END" then
        if arg5 == 1 or arg5 == true then OnBossKill(arg2) end
    elseif event == "BOSS_KILL" then
        OnBossKill(arg2)
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS"
        or event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_UNGHOST" or event == "PLAYER_ALIVE" then
        travelCache = {}
        C_Timer.After(1, function() CheckLocation() UpdateCard() end)
    elseif event == "GET_ITEM_INFO_RECEIVED" then
        -- fires constantly elsewhere (auction scans): only matters while the gear list is up
        if frame and frame:IsShown() and state.mode == "gear" then ScheduleRefresh() end
    elseif event == "PLAYER_LEVEL_UP" then
        clientXP, ratioCount = {}, -1
        OnLevelUp(arg1)
        ScheduleRefresh()
    else
        ScheduleRefresh()
    end
end)
