local _, ns = ...
local db
local cache, guidNames = {}, {}
local ttl, limit = 600, 1000
local events = CreateFrame('Frame')
local function safe(v)
    if canaccessvalue and not canaccessvalue(v) then return false end
    if issecretvalue and issecretvalue(v) then return false end
    return true
end
local function text(v) return safe(v) and type(v)=='string' end
local function clock() return GetTime and GetTime() or 0 end
function ns.GuildKey(value)
    if not text(value) then return nil end
    -- Literal names: punctuation is significant, unlike political keywords.
    local key=value:gsub('^%s+',''):gsub('%s+$',''):gsub('%s+',' ')
    if key=='' or #key>120 or key:find('[|%c]') then return nil end
    return key:lower(), key
end
local function identity(name)
    if not text(name) or not name:find('-',1,true) then return nil end
    return name:lower()
end
local function forget(name)
    local row=cache[name]
    if row and row.guid and guidNames[row.guid]==name then guidNames[row.guid]=nil end
    cache[name]=nil
end
function ns.LearnGuild(name, guid, guild)
    local key=identity(name)
    if not key then
        -- GUID alone remains a safe identity when the client only exposes a first name.
        if text(guid) and guid~='' then key='guid:'..guid else return end
    end
    if not text(guild) then return end
    local guildKey, display=ns.GuildKey(guild)
    forget(key)
    if not guildKey then return end
    local row={guild=guildKey,display=display,seen=clock()}
    if text(guid) and guid~='' then row.guid=guid; guidNames[guid]=key end
    cache[key]=row
    local count,oldest,oldTime=0,nil,math.huge
    for k,v in pairs(cache) do
        if clock()-v.seen>ttl then forget(k)
        else count=count+1; if v.seen<oldTime then oldest=k; oldTime=v.seen end end
    end
    if count>limit and oldest then forget(oldest) end
end
function ns.ScanGuildUnit(unit)
    if not GetGuildInfo or not UnitGUID or not UnitFullName then return end
    local guid=UnitGUID(unit)
    if not text(guid) or guid=='' then return end
    if UnitIsPlayer then local isPlayer=UnitIsPlayer(unit); if not safe(isPlayer) or not isPlayer then return end end
    local first,second=UnitFullName(unit)
    if not text(first) then return end
    local name=first
    if text(second) and second~='' then name=first..'-'..second end
    local guild=GetGuildInfo(unit)
    if not text(guild) then
        -- Do not keep an older membership after new data becomes unavailable.
        local known=guidNames[guid]; if known then forget(known) end
        return
    end
    ns.LearnGuild(name,guid,guild)
end
function ns.ScanGuildWho()
    if not C_FriendList or not C_FriendList.GetNumWhoResults or not C_FriendList.GetWhoInfo then return end
    local count=C_FriendList.GetNumWhoResults()
    if not safe(count) or type(count)~='number' then return end
    for i=1,math.min(count,1000) do
        local row=C_FriendList.GetWhoInfo(i)
        if safe(row) and type(row)=='table' then ns.LearnGuild(row.fullName,nil,row.fullGuildName) end
    end
end
function ns.ScanGuildUnits()
    for _,unit in ipairs({'player','target','focus','mouseover'}) do ns.ScanGuildUnit(unit) end
    for i=1,4 do ns.ScanGuildUnit('party'..i) end
    for i=1,40 do ns.ScanGuildUnit('raid'..i) end
end
function ns.AddBlockedGuild(value)
    local key,display=ns.GuildKey(value)
    if not key then return false,'Enter a guild name (1-120 bytes, no chat markup).' end
    db.blockedGuilds[key]={name=display,enabled=true}
    ns.ScanGuildUnits()
    return true,'Guild blocked: '..display
end
function ns.GuildEntries(query)
    local keys={}
    query=(query or ''):lower()
    for key in pairs(db.blockedGuilds) do if key:find(query,1,true) then keys[#keys+1]=key end end
    table.sort(keys)
    return keys,db.blockedGuilds
end
function ns.SetGuildEnabled(key,enabled)
    if db.blockedGuilds[key] then db.blockedGuilds[key].enabled=enabled end
end
function ns.DeleteGuild(key)
    local row=db.blockedGuilds[key]; db.blockedGuilds[key]=nil; return row
end
function ns.ClearGuildCache() cache={}; guidNames={} end
function ns.GuildCacheCount()
    local count=0
    for key,row in pairs(cache) do
        if clock()-row.seen>ttl then forget(key) else count=count+1 end
    end
    return count
end
function ns.MatchGuild(event,sender,guid)
    if not db or not next(db.blockedGuilds) then return false end
    -- Battle.net identities and outgoing whisper recipients are not sender guild identities.
    if event:find('BN_',1,true) or event=='CHAT_MSG_WHISPER_INFORM' then return false end
    local key=text(guid) and guidNames[guid] or nil
    key=key or identity(sender)
    local row=key and cache[key]
    if not row then return false end
    if clock()-row.seen>ttl then forget(key); return false end
    if row.guid and text(guid) and guid~='' and row.guid~=guid then return false end
    local rule=db.blockedGuilds[row.guild]
    if rule and rule.enabled then return true,'Guild: '..rule.name end
    return false
end
function ns.InitGuilds(settings)
    db=settings
    if type(db.blockedGuilds)~='table' then db.blockedGuilds={} end
    for _,event in ipairs({'PLAYER_LOGIN','PLAYER_TARGET_CHANGED','UPDATE_MOUSEOVER_UNIT','PLAYER_FOCUS_CHANGED',
        'GROUP_ROSTER_UPDATE','NAME_PLATE_UNIT_ADDED','UNIT_NAME_UPDATE','PLAYER_GUILD_UPDATE','WHO_LIST_UPDATE'}) do
        pcall(events.RegisterEvent,events,event)
    end
    events:SetScript('OnEvent',function(_,event,unit)
        if not next(db.blockedGuilds) then return end
        if event=='WHO_LIST_UPDATE' then ns.ScanGuildWho()
        elseif event=='NAME_PLATE_UNIT_ADDED' or event=='UNIT_NAME_UPDATE' or event=='PLAYER_GUILD_UPDATE' then
            if text(unit) then ns.ScanGuildUnit(unit) end
        elseif event=='PLAYER_TARGET_CHANGED' then ns.ScanGuildUnit('target')
        elseif event=='UPDATE_MOUSEOVER_UNIT' then ns.ScanGuildUnit('mouseover')
        elseif event=='PLAYER_FOCUS_CHANGED' then ns.ScanGuildUnit('focus')
        else ns.ScanGuildUnits() end
    end)
end
