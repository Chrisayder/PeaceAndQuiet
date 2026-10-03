local _, ns = ...
local db, tab
local seen, order = {}, {}
local fallback
ns.session = {checked = 0, blocked = 0}
local function safe(value)
    if canaccessvalue and not canaccessvalue(value) then return false end
    if issecretvalue and issecretvalue(value) then return false end
    return true
end
local function text(value)
    if not safe(value) or type(value) ~= 'string' then return '?' end
    -- Store readable text; do not replay links, textures, or injected colors.
    return value:gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', '')
        :gsub('|H.-|h(.-)|h', '%1'):gsub('|T.-|t', ''):gsub('|A.-|a', '')
        :gsub('|', '||'):gsub('[%c]', ' ')
end
local function render(entry)
    return string.format('[%s] [%s] %s: %s |cff65d6b4[matched: %s]|r',
        date('%m/%d %H:%M:%S', entry.time), entry.channel, entry.sender, entry.message, entry.term)
end
function ns.InitHistory(settings)
    db = settings
    if type(db.history) ~= 'table' then db.history = {} end
    while #db.history > 500 do table.remove(db.history, 1) end
end
function ns.OpenHistory()
    if InCombatLockdown and InCombatLockdown() then return false, 'Open the tab after combat.' end
    tab = nil
    for _, name in ipairs(CHAT_FRAMES or {}) do
        local candidate = _G[name]
        if candidate and candidate.name == 'Filtered Chat' then tab = candidate; break end
    end
    if not tab and FCF_OpenNewWindow then tab = FCF_OpenNewWindow('Filtered Chat', true) end
    if not tab then return false, 'No chat tab available. /pq history prints the last 20 records.' end
    if tab.RemoveAllMessageGroups then tab:RemoveAllMessageGroups() end
    if tab.RemoveAllChannels then tab:RemoveAllChannels() end
    if tab.SetMaxLines then tab:SetMaxLines(550) end
    tab:Clear()
    tab:AddMessage('|cff65d6b4Peace and Quiet: live blocked messages; last 500 retained. /pq status shows activity.|r')
    for _, entry in ipairs(db.history) do tab:AddMessage(render(entry)) end
    if FCF_SelectDockFrame then FCF_SelectDockFrame(tab) end
    return true
end
function ns.Observe(chatFrame, event, message, sender, channel, lineID, blocked, term)
    -- Blizzard invokes each filter once per chat frame. Count/store an event once.
    if safe(lineID) and type(lineID) == 'number' and lineID > 0 then
        local key = event .. ':' .. lineID
        if seen[key] then return end
        seen[key] = true; order[#order + 1] = key
        if #order > 512 then seen[table.remove(order, 1)] = nil end
    else
        local now = GetTime and GetTime() or 0
        local key = event .. '\n' .. text(sender) .. '\n' .. message
        local identity = chatFrame or ns
        if fallback and fallback.key == key and fallback.time == now and not fallback.frames[identity] then
            fallback.frames[identity] = true
            return
        end
        fallback = {key = key, time = now, frames = {[identity] = true}}
    end
    ns.session.checked = ns.session.checked + 1
    if not blocked then return end
    ns.session.blocked = ns.session.blocked + 1
    local entry = {time = time(), sender = text(sender), message = text(message),
        channel = safe(channel) and type(channel) == 'string' and channel ~= '' and text(channel)
            or event:gsub('CHAT_MSG_', ''), term = text(term)}
    db.history[#db.history + 1] = entry
    if #db.history > 500 then table.remove(db.history, 1) end
    if tab and tab.name == 'Filtered Chat' then tab:AddMessage(render(entry)) end
end
function ns.PrintHistory(output)
    output('Saved blocked messages: ' .. #db.history .. ' (showing last 20)')
    for i = math.max(1, #db.history - 19), #db.history do output(render(db.history[i])) end
end
function ns.ClearHistory()
    db.history = {}
    if tab then tab:Clear() end
end
