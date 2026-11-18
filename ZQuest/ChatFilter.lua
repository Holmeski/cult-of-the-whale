-- Hide other players' guide-addon chatter
--
-- RestedXP Guides, OpenXP and older ZQuest versions post lines like
-- "{rt3} RestedXP Guides: I just leveled from 21 to 22 in 1h 4m" or
-- "... Flying to Booty Bay ETA 2:10" to party, guild and other channels.
-- With "Hide other players' guide messages" on (the default), ZQuest keeps
-- those out of your chat windows. Only lines in that exact format from a
-- known guide addon are hidden; ordinary chat is never touched.

local _, addon = ...

local cf = {}
addon.chatFilter = cf

-- names guide addons sign their lines with (addon titles)
local SENDERS = {"RestedXP", "RXP", "OpenXP", "ZQuest"}
-- what they announce
local KINDS = {
    "I just leveled",          -- level ups
    "Flying to ",              -- flight ETAs
}

function cf.IsGuideSpam(msg)
    if type(msg) ~= "string" then return false end
    -- the "{rt3} Title: text" format BuildNotification uses (any raid icon)
    local title, text = msg:match("^{[^}]+}%s*([^:]+):%s*(.+)$")
    if not title then
        -- promo tag some versions add to the end of their lines
        if msg:find("%- free leveling guide addon%)") then return true end
        return false
    end
    local known
    for _, s in ipairs(SENDERS) do
        if title:find(s, 1, true) then known = true break end
    end
    if not known then return false end
    for _, k in ipairs(KINDS) do
        if text:find(k, 1, true) then return true end
    end
    return false
end

local function Filter(_, _, msg, ...)
    local p = addon.settings and addon.settings.profile
    if p and p.zqHideGuideSpam == false then return false end
    return cf.IsGuideSpam(msg)
end

local EVENTS = {
    "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER", "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER",
    "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_EMOTE", "CHAT_MSG_CHANNEL", "CHAT_MSG_WHISPER",
}
if ChatFrame_AddMessageEventFilter then
    for _, e in ipairs(EVENTS) do ChatFrame_AddMessageEventFilter(e, Filter) end
end
