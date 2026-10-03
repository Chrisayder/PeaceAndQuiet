from pathlib import Path
import sys
from lupa.lua51 import LuaRuntime

root = Path('PeaceAndQuiet')
checks = 0
for modern in (True, False):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute('''
        function time() return 100000 end
        function date(fmt, t) return '09/29 12:00:00' end
        filters = {}; logs = {}; SlashCmdList = {}; ns = {}
        function print(s) logs[#logs+1] = s end
        function register(e, f) filters[e] = f end
        function CreateFrame()
            frame = {}
            function frame:RegisterEvent(e) end
            function frame:UnregisterEvent(e) end
            function frame:SetScript(e, f) self.callback = f end
            return frame
        end
    ''')
    lua.execute('ChatFrameUtil = {AddMessageEventFilter=register}' if modern else 'ChatFrame_AddMessageEventFilter=register')
    for name in ('Rules.lua', 'Filter.lua', 'History.lua', 'Performance.lua', 'Guilds.lua', 'Options.lua', 'GuildOptions.lua', 'PeaceAndQuiet.lua'):
        lua.execute('assert(loadstring(...))("PeaceAndQuiet", ns)', (root / name).read_text())
    lua.execute('frame:callback("ADDON_LOADED", "Unrelated")')
    assert lua.eval('PeaceAndQuietDB == nil')
    lua.execute('frame:callback("ADDON_LOADED", "PeaceAndQuiet")')
    def check(message, expected, event='CHAT_MSG_CHANNEL'):
        global checks
        result = lua.globals().filters[event](None, event, message)
        assert result == expected, (modern, message, result, expected)
        checks += 1
    for message in ('Trump is great', 'Biden is terrible', 'MAGA', 'vote for anyone',
                    'free Palestine', 'support Israel', 'gender debate', 'taxes are high',
                    '|cffff0000trump|r', '|Hitem:1|h[Biden]|h', 'climate-change',
                    'tRUmP', 'tr\u200bump', 'left-wing parties', 'DEI'):
        check(message, True)
    check('LFM RFK need tank', False)
    check('rfk jr', True)
    check('RFK Jr. is in the news', True)
    for message in ('LFM Molten Core need a tank', 'LF mage for ice block',
                    'Can someone summon?', 'WTS [Peacebloom]', 'trumpet music',
                    'party at Stormwind', 'Alliance versus Horde', 'need a transmute',
                    '|Hitem:123|h[Thunderfury]|h', 'presidentially', ''):
        check(message, False)
    for event in lua.globals().filters.keys(): check('politics', True, event)
    cmd = lua.globals().SlashCmdList.PEACEANDQUIET
    cmd('off'); check('Trump', False)
    cmd('on'); cmd('scope whispers off'); check('Trump', False, 'CHAT_MSG_WHISPER')
    check('Trump', True)
    cmd('scope whispers on'); check('Trump', True, 'CHAT_MSG_WHISPER')
    cmd('mode strict'); check('vote for a raid leader', False); check('election', True)
    cmd('mode aggressive'); check('vote for a raid leader', True)
    cmd('ignore vote'); check('vote for a raid leader', False); check('vote for Trump', True)
    cmd('unignore vote'); check('vote for a raid leader', True)
    cmd('add banana bread'); check('banana-bread', True); check('banana', False)
    cmd('remove banana bread'); check('banana bread', False)
    cmd('add .+%[]'); check('normal message', False)
    cmd('test Trump'); assert 'Would hide' in lua.globals().logs[len(lua.globals().logs)]
    cmd('scope bad on'); cmd('list'); cmd(''); cmd('add')
    lua.execute('function canaccessvalue(v) return false end')
    check('Trump', False)
    lua.execute('canaccessvalue=nil; function issecretvalue(v) return true end')
    check('Trump', False)
    lua.execute('issecretvalue=nil')
    check(None, False)
    cmd('off'); cmd('mode strict'); cmd('add custom phrase')
    lua.execute('frame:callback("ADDON_LOADED", "PeaceAndQuiet")')
    assert lua.eval('PeaceAndQuietDB.enabled == false and PeaceAndQuietDB.mode == "strict"')
    cmd('on'); check('custom phrase', True)
    assert lua.eval('filters.CHAT_MSG_SYSTEM == nil and filters.CHAT_MSG_MONSTER_SAY == nil')
    lua.execute('''
        SlashCmdList.PEACEANDQUIET('clear')
        local f = filters.CHAT_MSG_CHANNEL
        local a, b = {}, {}
        f(a, 'CHAT_MSG_CHANNEL', 'Trump', 'Tester', '', '1. General', '', '', 0, 1, '', 901)
        f(b, 'CHAT_MSG_CHANNEL', 'Trump', 'Tester', '', '1. General', '', '', 0, 1, '', 901)
        assert(#PeaceAndQuietDB.history == 1, 'duplicate across frames')
        assert(PeaceAndQuietDB.history[1].sender == 'Tester')
        assert(PeaceAndQuietDB.history[1].channel == '1. General')
        assert(PeaceAndQuietDB.history[1].term == 'trump')
        f(a, 'CHAT_MSG_CHANNEL', 'Trump', 'Tester', '', '1. General', '', '', 0, 1, '', 902)
        assert(#PeaceAndQuietDB.history == 2, 'distinct identical messages')
        ns.InitHistory(PeaceAndQuietDB)
        assert(#PeaceAndQuietDB.history == 2, 'history survives initialization')
        CHAT_FRAMES = {}
        function FCF_OpenNewWindow(name, noDefault)
            assert(noDefault)
            ChatFrame3 = {name=name, lines={}}
            function ChatFrame3:RemoveAllMessageGroups() end
            function ChatFrame3:RemoveAllChannels() end
            function ChatFrame3:Clear() self.lines={} end
            function ChatFrame3:AddMessage(s) self.lines[#self.lines+1]=s end
            CHAT_FRAMES = {'ChatFrame3'}
            return ChatFrame3
        end
        assert(ns.OpenHistory())
        assert(#ChatFrame3.lines == 3, 'history replay')
        f(a, 'CHAT_MSG_CHANNEL', 'Biden', 'Tester', '', '', '', '', 0, 1, '', 903)
        assert(#ChatFrame3.lines == 4, 'live update')
        local old = ChatFrame3
        ns.OpenHistory()
        assert(ChatFrame3 == old, 'reuse existing tab')
        for i=1000,1600 do
            f(a, 'CHAT_MSG_CHANNEL', 'Trump', 'Tester', '', '', '', '', 0, 1, '', i)
        end
        assert(#PeaceAndQuietDB.history == 500, 'bounded history')
        SlashCmdList.PEACEANDQUIET('history')
        SlashCmdList.PEACEANDQUIET('status')
        SlashCmdList.PEACEANDQUIET('clear')
        assert(#PeaceAndQuietDB.history == 0 and #ChatFrame3.lines == 0)
        f(a, 'CHAT_MSG_CHANNEL', 'Trump', 'Tester')
        f(b, 'CHAT_MSG_CHANNEL', 'Trump', 'Tester')
        assert(#PeaceAndQuietDB.history == 1, 'fallback frame deduplication')
        f(a, 'CHAT_MSG_CHANNEL', 'Trump', 'Tester')
        assert(#PeaceAndQuietDB.history == 2)
        function InCombatLockdown() return true end
        assert(ns.OpenHistory() == false)
        InCombatLockdown = nil
        CHAT_FRAMES = {}; FCF_OpenNewWindow = nil
        assert(ns.OpenHistory() == false)
    ''')
print(f'PASS: {checks} filter checks, plus initialization, persistence, commands, and API fallback checks (Lua 5.1).')
