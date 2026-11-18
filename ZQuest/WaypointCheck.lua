-- Waypoint check (/zq check)
--
-- Compares each accept and turn-in step of the guide you're on with where
-- Questie says that quest's giver or turn-in NPC stands. Steps more than
-- LIMIT yards off, on another map, or for a quest your race can't take are
-- listed in a window you can copy from (and saved in ZQData.waypointReport).
-- /zq check fix also moves those waypoints to Questie's spot for this
-- session, so you can play on while the guide gets fixed.
-- Needs the free Questie addon; nothing of Questie's is copied into ZQuest.

local _, addon = ...
local L = addon.locale.Get
local fmt = string.format
local HBD = LibStub("HereBeDragons-2.0")

local wc = {}
addon.waypointCheck = wc

local LIMIT = 40 -- yards

local function Print(msg, ...)
    print("|cFFE6C36AZQuest:|r " .. fmt(msg, ...))
end

local function MapName(id)
    local info = id and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(id)
    return info and info.name or tostring(id)
end

local raceBit
local function RaceOk(q)
    local races = q and q.requiredRaces or 0
    if races == 0 or not bit then return true end
    if not raceBit then
        local id = UnitRace and select(3, UnitRace("player"))
        raceBit = id and 2 ^ (id - 1) or 0
    end
    return raceBit == 0 or bit.band(races, raceBit) ~= 0
end

-- The step's waypoint: its first .goto
local function GotoOf(step)
    for _, e in ipairs(step.elements or {}) do
        if e.x and e.y and e.zone and (e.tag == "goto" or e.wx) then return e end
    end
end

local function Check(guide)
    local card = addon.card
    local out, pending, checked = {}, 0, 0
    for index, step in ipairs(guide.steps or {}) do
        local g = GotoOf(step)
        for _, e in ipairs(step.elements or {}) do
            local kind = e.tag
            local id = e.questId
            if g and id and (kind == "accept" or kind == "turnin") then
                local info = card.QuestInfoOf(id)
                if not info then
                    pending = pending + 1
                else
                    checked = checked + 1
                    local spot = kind == "accept" and info.s or info.f
                    local issue = {step = index, kind = kind, quest = id, name = info.n or "?", g = g}
                    if not RaceOk(info.q) then
                        issue.why = L("your race or faction can't take this quest")
                        tinsert(out, issue)
                    elseif spot and spot[2] and spot[2] > 0 and spot[3] then
                        local sx, sy, si = HBD:GetWorldCoordinatesFromZone(spot[3] / 100, spot[4] / 100, spot[2])
                        local d = sx and g.wx and si == g.instance and HBD:GetWorldDistance(si, g.wx, g.wy, sx, sy)
                        if not d or d > LIMIT then
                            issue.npc, issue.qzone, issue.qx, issue.qy = spot[1], spot[2], spot[3], spot[4]
                            issue.wx, issue.wy, issue.instance = sx, sy, si
                            issue.yards = d
                            issue.why = d and fmt(L("%d yards off"), d) or L("on another map")
                            tinsert(out, issue)
                        end
                    end
                end
            end
        end
    end
    return out, pending, checked
end

local function ReportText(guide, issues)
    local lines = {fmt("ZQuest %s waypoint check: %s", addon.openxpVersion or addon.release or "", guide.name or "?")}
    for _, i in ipairs(issues) do
        local g = i.g
        local where = i.npc and fmt("  Questie: %s, %s %.2f,%.2f", i.npc, MapName(i.qzone), i.qx, i.qy) or ""
        tinsert(lines, fmt("Step %d %s %d %s: guide %s %.2f,%.2f - %s.%s", i.step, i.kind, i.quest, i.name,
                           MapName(g.zone), g.x, g.y, i.why, where))
    end
    return table.concat(lines, "\n")
end

-- A simple window with the report in a box you can select and copy
local frame
local function Show(text)
    if not frame then
        frame = CreateFrame("Frame", "ZQuestWaypointCheckFrame", UIParent, "BackdropTemplate")
        frame:SetSize(620, 360)
        frame:SetPoint("CENTER")
        frame:SetFrameStrata("DIALOG")
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
        frame:SetBackdrop({bgFile = "Interface/BUTTONS/WHITE8X8", edgeFile = "Interface/BUTTONS/WHITE8X8", edgeSize = 1})
        frame:SetBackdropColor(18 / 255, 7 / 255, 32 / 255, 0.96)
        frame:SetBackdropBorderColor(150 / 255, 116 / 255, 52 / 255, 1)
        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 12, -10)
        title:SetTextColor(230 / 255, 195 / 255, 106 / 255)
        title:SetText(L("ZQuest waypoint check"))
        local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        hint:SetPoint("TOPLEFT", 12, -32)
        hint:SetText(L("Ctrl+A then Ctrl+C to copy. Send it to whoever maintains the guide."))
        local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", 2, 2)
        local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 12, -52)
        scroll:SetPoint("BOTTOMRIGHT", -32, 12)
        local edit = CreateFrame("EditBox", nil, scroll)
        edit:SetMultiLine(true)
        edit:SetAutoFocus(false)
        edit:SetFontObject(ChatFontNormal)
        edit:SetWidth(560)
        edit:SetScript("OnEscapePressed", function() frame:Hide() end)
        scroll:SetScrollChild(edit)
        frame.edit = edit
        tinsert(UISpecialFrames, "ZQuestWaypointCheckFrame")
    end
    frame.edit:SetText(text)
    frame.edit:HighlightText()
    frame:Show()
end

local function Apply(issues)
    local moved = 0
    for _, i in ipairs(issues) do
        if i.wx and i.qzone then
            local g = i.g
            g.zone, g.x, g.y = i.qzone, i.qx, i.qy
            g.wx, g.wy, g.instance = i.wx, i.wy, i.instance
            moved = moved + 1
        end
    end
    if moved > 0 then
        if addon.UpdateMap then pcall(addon.UpdateMap) end
        if addon.UpdateGotoSteps then pcall(addon.UpdateGotoSteps) end
    end
    return moved
end

function wc.Run(args)
    local card = addon.card
    if not (_G.QuestieLoader and card and card.QuestInfoOf) then
        return Print(L("The waypoint check needs the free Questie addon. Install and enable it, then try /zq check again."))
    end
    local guide = addon.currentGuide
    if not (guide and guide.steps) then return Print(L("Load a guide first.")) end
    local issues, pending, checked = Check(guide)
    if checked == 0 and pending > 0 then
        return Print(L("Questie is still loading its quest data. Try again in a few seconds."))
    end
    local text = ReportText(guide, issues)
    if type(ZQData) == "table" then
        ZQData.waypointReport = ZQData.waypointReport or {}
        ZQData.waypointReport[guide.name or "?"] = text
    end
    if #issues == 0 then
        return Print(L("Checked %d quest steps in %s: every waypoint is within %d yards of Questie's NPC."),
                     checked, guide.name or "?", LIMIT)
    end
    Print(L("Checked %d quest steps in %s: %d look wrong."), checked, guide.name or "?", #issues)
    if args == "fix" then
        local moved = Apply(issues)
        Print(L("Moved %d waypoints to Questie's spot until you reload."), moved)
    else
        Print(L("Type /zq check fix to move them to Questie's spot until you reload."))
    end
    Show(text)
end
