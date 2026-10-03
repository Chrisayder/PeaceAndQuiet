exec(open('tests/test_performance.py').read())
lua.execute(r'''
local now=200
function GetTime() return now end
PeaceAndQuietDB.enabled=true
assert(ns.AddBlockedGuild('  Test Guild  '))
local keys,rules=ns.GuildEntries('test'); assert(#keys==1 and rules['test guild'].enabled)
assert(not ns.MatchGuild('CHAT_MSG_CHANNEL','Unknown-Realm','GUID-X'))
ns.LearnGuild('Alice-Realm','GUID-A','Test Guild')
local blocked,reason=ns.MatchGuild('CHAT_MSG_CHANNEL','Alice-Realm','GUID-A')
assert(blocked and reason=='Guild: Test Guild')
assert(not ns.MatchGuild('CHAT_MSG_CHANNEL','Alice-OtherRealm','GUID-B'))
assert(not ns.MatchGuild('CHAT_MSG_CHANNEL','Alice',nil), 'ambiguous first name does not match')
assert(not ns.MatchGuild('CHAT_MSG_BN_WHISPER','Alice-Realm','GUID-A'))
assert(not ns.MatchGuild('CHAT_MSG_WHISPER_INFORM','Alice-Realm','GUID-A'))
assert(not ns.MatchGuild('CHAT_MSG_CHANNEL','Alice-Realm','GUID-WRONG'))
ns.SetGuildEnabled('test guild',false)
assert(not ns.MatchGuild('CHAT_MSG_WHISPER','Alice-Realm','GUID-A'))
ns.SetGuildEnabled('test guild',true)
local result=filters.CHAT_MSG_CHANNEL(nil,'CHAT_MSG_CHANNEL','hello friend','Alice-Realm','','1. General','','',0,1,'',0,99991,'GUID-A')
assert(result, 'guild block does not require political words')
assert(PeaceAndQuietDB.history[#PeaceAndQuietDB.history].term=='Guild: Test Guild')
PeaceAndQuietDB.scopes.public=false
assert(not filters.CHAT_MSG_CHANNEL(nil,'CHAT_MSG_CHANNEL','hello','Alice-Realm','','','','',0,1,'',0,99992,'GUID-A'))
PeaceAndQuietDB.scopes.public=true
ns.LearnGuild('Alice-Realm','GUID-A','Different Guild')
assert(not ns.MatchGuild('CHAT_MSG_CHANNEL','Alice-Realm','GUID-A'), 'guild change replaces evidence')
ns.LearnGuild('Alice-Realm','GUID-A','Test Guild')
now=801; assert(not ns.MatchGuild('CHAT_MSG_CHANNEL','Alice-Realm','GUID-A'), 'membership expires')
ns.LearnGuild('Alice-Realm','GUID-A','Test Guild')
ns.LearnGuild('Alice-Realm',nil,'')
assert(not ns.MatchGuild('CHAT_MSG_CHANNEL','Alice-Realm','GUID-A'), 'unguilded WHO result invalidates cache')
ns.LearnGuild('Shortname','GUID-S','Test Guild')
assert(ns.MatchGuild('CHAT_MSG_SAY','Shortname','GUID-S'))
assert(not ns.MatchGuild('CHAT_MSG_SAY','Shortname',nil))
function UnitGUID(unit) if unit=='target' then return 'GUID-T' end end
function UnitFullName(unit) return 'Target','Surname' end
function UnitIsPlayer() return true end
function GetGuildInfo() return 'Test Guild' end
ns.ScanGuildUnit('target')
assert(ns.MatchGuild('CHAT_MSG_WHISPER','Target-Surname','GUID-T'))
GetGuildInfo=function() return nil end
ns.ScanGuildUnit('target')
assert(not ns.MatchGuild('CHAT_MSG_WHISPER','Target-Surname','GUID-T'))
C_FriendList={GetNumWhoResults=function() return 1 end,
    GetWhoInfo=function() return {fullName='Remote-Surname',fullGuildName='Test Guild'} end}
ns.ScanGuildWho()
assert(ns.MatchGuild('CHAT_MSG_CHANNEL','Remote-Surname',nil))
assert(ns.DeleteGuild('test guild') and not ns.MatchGuild('CHAT_MSG_CHANNEL','Remote-Surname',nil))
assert(ns.GuildKey('Guild-One')~=ns.GuildKey('Guild One'), 'punctuation significant')
assert(not ns.AddBlockedGuild('|cffff0000Fake'))
ns.AddBlockedGuild('Test Guild')
ns.InitGuilds(PeaceAndQuietDB)
assert(ns.MatchGuild('CHAT_MSG_CHANNEL','Remote-Surname',nil), 'settings survive initialization')
ns.ClearGuildCache(); assert(ns.GuildCacheCount()==0)
local oldCount=#widgets
for i=1,oldCount do
    local w=widgets[i]
    if w.kind=='Button' and w.value=='Guilds (Work in progress)' then w.scripts.OnClick() end
end
local input,search
for i=oldCount+1,#widgets do
    local w=widgets[i]
    if w.kind=='EditBox' then if not input then input=w else search=w end end
end
assert(input and search)
input:SetText('GUI Guild'); input.scripts.OnEnterPressed()
assert(PeaceAndQuietDB.blockedGuilds['gui guild'].enabled and input:GetText()=='')
search:SetText('GUI')
local row
for _,w in ipairs(widgets) do
    if w.kind=='CheckButton' and rawget(w,'key')=='gui guild' and w:IsShown() then row=w end
end
assert(row)
row:SetChecked(false); row.scripts.OnClick(row)
assert(not PeaceAndQuietDB.blockedGuilds['gui guild'].enabled)
row.delete.scripts.OnClick()
assert(PeaceAndQuietDB.blockedGuilds['gui guild']==nil)
for i=1,1010 do ns.LearnGuild('Player-'..i,'GUID-'..i,'Test Guild') end
assert(ns.GuildCacheCount()<=1000, 'bounded cache')
''')
print('PASS: guild rules, scopes, identity safety, changed/expired membership, WHO, unit discovery, logging, bounded cache, and GUI add/toggle/delete.')
