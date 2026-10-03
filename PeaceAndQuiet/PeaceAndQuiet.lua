local addonName, ns = ...
local db
local groups = {
    public = {'CHANNEL', 'SAY', 'YELL', 'EMOTE', 'TEXT_EMOTE'},
    guild = {'GUILD', 'OFFICER'},
    group = {'PARTY', 'PARTY_LEADER', 'RAID', 'RAID_LEADER', 'RAID_WARNING',
        'INSTANCE_CHAT', 'INSTANCE_CHAT_LEADER', 'BATTLEGROUND', 'BATTLEGROUND_LEADER'},
    whispers = {'WHISPER', 'WHISPER_INFORM', 'BN_WHISPER', 'BN_WHISPER_INFORM'},
    community = {'COMMUNITIES_CHANNEL'},
}
local eventGroup = {}
for group, events in pairs(groups) do
    for _, event in ipairs(events) do eventGroup['CHAT_MSG_' .. event] = group end
end
local function say(message)
    print('|cff65d6b4Peace and Quiet:|r ' .. message)
end
local function accessible(value)
    if canaccessvalue then return canaccessvalue(value) end
    if issecretvalue then return not issecretvalue(value) end
    return true
end
local function filter(chatFrame, event, message, sender, ...)
    if not db or not db.enabled or not db.scopes[eventGroup[event]] then return false end
    -- Never examine or transform protected chat data.
    if not accessible(message) or type(message) ~= 'string' then return false end
    local started=ns.PerfStart()
    local blocked, term = ns.MatchGuild(event,sender,select(10,...))
    if not blocked then blocked,term=ns.Match(message) end
    ns.Observe(chatFrame, event, message, sender, select(2, ...), select(9, ...), blocked, term)
    ns.PerfFinish(started)
    return blocked
end
local function status()
    say((db.enabled and 'ON' or 'OFF') .. ', mode: ' .. db.mode)
    say('This session: ' .. ns.session.checked .. ' messages checked, ' .. ns.session.blocked .. ' blocked. Saved: ' .. #db.history .. '/500.')
    local scopes = {}
    for name, enabled in pairs(db.scopes) do scopes[#scopes + 1] = name .. '=' .. (enabled and 'on' or 'off') end
    table.sort(scopes)
    say(table.concat(scopes, ', '))
end
local function list(set, label)
    local terms = {}
    for term, enabled in pairs(set) do if enabled then terms[#terms + 1] = term end end
    table.sort(terms)
    say(label .. ' (' .. #terms .. ')')
    for _, term in ipairs(terms) do say(term) end
end
local function command(input)
    local cmd, rest = input:match('^%s*(%S*)%s*(.-)%s*$')
    cmd = cmd:lower()
    if cmd == 'options' or cmd == 'config' then ns.ToggleOptions()
    elseif cmd == 'on' or cmd == 'off' then
        db.enabled = cmd == 'on'; ns.RefreshButton(); status()
    elseif cmd == 'status' then status()
    elseif cmd == 'perf' then
        for line in ns.PerformanceText():gmatch('[^\n]+') do say(line) end
    elseif cmd == 'log' then
        local ok, reason = ns.OpenHistory()
        if not ok then say(reason) end
    elseif cmd == 'history' then ns.PrintHistory(say)
    elseif cmd == 'clear' then ns.ClearHistory(); say('Saved blocked messages cleared.')
    elseif cmd == 'mode' and (rest == 'aggressive' or rest == 'strict') then
        db.mode = rest; ns.Compile(db); status()
    elseif cmd == 'scope' then
        local name, value = rest:match('^(%S+)%s+(%S+)$')
        if groups[name] and (value == 'on' or value == 'off') then
            db.scopes[name] = value == 'on'; status()
        else say('Usage: /pq scope public|guild|group|whispers|community on|off') end
    elseif cmd == 'add' or cmd == 'remove' or cmd == 'ignore' or cmd == 'unignore' then
        local term = ns.Normalize(rest)
        if term == '' or #term > 120 then say('Enter a word or phrase (1-120 bytes).'); return end
        if cmd == 'add' then db.custom[term] = true; db.disabledTerms[term] = nil; db.deletedTerms[term] = nil
        elseif cmd == 'remove' then db.custom[term] = nil
        elseif cmd == 'ignore' then db.ignored[term] = true
        else db.ignored[term] = nil; db.disabledTerms[term] = nil end
        ns.Compile(db); say('Updated: ' .. term)
    elseif cmd == 'list' then
        list(db.custom, 'Custom blocked terms'); list(db.ignored, 'Ignored built-in terms')
        list(db.disabledTerms, 'Unchecked filter terms')
    elseif cmd == 'test' and rest ~= '' then
        local blocked, term = ns.Match(rest)
        say(blocked and ('Would hide; matched: ' .. term) or 'No matching rule.')
    else
        say('/pq on | off | status | mode aggressive | mode strict')
        say('/pq add PHRASE | remove PHRASE | ignore BUILTIN | unignore BUILTIN | list')
        say('/pq scope public|guild|group|whispers|community on|off')
        say('/pq test MESSAGE (local preview, sends nothing)')
        say('/pq log (live tab) | history (last 20) | clear (erase history)')
        say('/pq options (settings and minimap button controls)')
        say('/pq perf (performance snapshot)')
    end
end
ns.RunCommand = command
local frame = CreateFrame('Frame')
frame:RegisterEvent('ADDON_LOADED')
frame:SetScript('OnEvent', function(self, _, name)
    if name ~= addonName then return end
    PeaceAndQuietDB = type(PeaceAndQuietDB) == 'table' and PeaceAndQuietDB or {}
    db = PeaceAndQuietDB
    if type(db.enabled) ~= 'boolean' then db.enabled = true end
    if db.mode ~= 'strict' and db.mode ~= 'aggressive' then db.mode = 'aggressive' end
    for _, key in ipairs({'custom', 'ignored', 'scopes', 'disabledTerms', 'enabledTerms', 'deletedTerms'}) do
        if type(db[key]) ~= 'table' then db[key] = {} end
    end
    for group in pairs(groups) do
        if type(db.scopes[group]) ~= 'boolean' then db.scopes[group] = true end
    end
    ns.Compile(db)
    ns.InitHistory(db)
    ns.InitGuilds(db)
    ns.InitOptions(db)
    local register = ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter or ChatFrame_AddMessageEventFilter
    if register then
        for event in pairs(eventGroup) do register(event, filter) end
        say('Loaded. ' .. db.mode .. ' filtering ' .. (db.enabled and 'ON.' or 'OFF.') .. ' /pq for controls.')
    else say('Chat filtering API unavailable on this build; filtering could not start.') end
    SLASH_PEACEANDQUIET1 = '/pq'
    SLASH_PEACEANDQUIET2 = '/peaceandquiet'
    SlashCmdList.PEACEANDQUIET = command
    self:UnregisterEvent('ADDON_LOADED')
    self:RegisterEvent('PLAYER_LOGIN')
    self:SetScript('OnEvent', function(loginFrame, event)
        if event == 'PLAYER_LOGIN' then
            local ok, reason = ns.OpenHistory()
            if not ok then say(reason) end
            loginFrame:UnregisterEvent('PLAYER_LOGIN')
        end
    end)
end)
