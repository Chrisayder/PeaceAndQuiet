exec(open('tests/test_gui.py').read())
lua.execute(r'''
local now,ticks,updates=100,0,0
function GetTime() return now end
function debugprofilestop() ticks=ticks+0.25; return ticks end
function UpdateAddOnMemoryUsage() updates=updates+1 end
function GetAddOnMemoryUsage(name) assert(name=='PeaceAndQuiet'); return 2048 end
C_AddOnProfiler={IsEnabled=function() return true end,
    GetAddOnMetric=function(name,metric) assert(name=='PeaceAndQuiet' and metric==1); return 0.12 end}
Enum={AddOnProfilerMetric={RecentAverageTime=1}}
ns.ResetPerformance()
local t=ns.PerfStart(); ns.PerfFinish(t)
local s=ns.PerformanceSnapshot()
assert(s.calls==1 and s.total==0.25 and s.average==0.25 and s.peak==0.25)
assert(s.memory==2048 and s.peakMemory==2048 and s.cpu==0.12)
ns.PerformanceSnapshot(); assert(updates==1, 'memory refresh throttled')
now=104; ns.PerformanceSnapshot(); assert(updates==1)
now=105; ns.PerformanceSnapshot(); assert(updates==2)
ns.ResetPerformance(); s=ns.PerformanceSnapshot()
assert(s.calls==0 and s.total==0 and s.average==0)
PeaceAndQuietDB.enabled=true
local before=ns.PerformanceSnapshot().calls
filters.CHAT_MSG_CHANNEL(nil,'CHAT_MSG_CHANNEL','hello world')
assert(ns.PerformanceSnapshot().calls==before+1, 'real filter instrumented')
PeaceAndQuietDB.enabled=false
filters.CHAT_MSG_CHANNEL(nil,'CHAT_MSG_CHANNEL','hello world')
assert(ns.PerformanceSnapshot().calls==before+1, 'paused filtering not measured')
local count=ns.PerformanceSnapshot().calls
ns.PerfFinish(99999)
assert(ns.PerformanceSnapshot().calls==count, 'clock reset sample dropped')
function GetAddOnMemoryUsage() error('API unavailable') end
now=110; s=ns.PerformanceSnapshot(); assert(s.memory==nil)
C_AddOnProfiler.IsEnabled=function() return false end
s=ns.PerformanceSnapshot(); assert(s.cpu==nil)
debugprofilestop=nil; assert(ns.PerfStart()==nil)
assert(not ns.PerformanceSnapshot().timer)
for _,w in ipairs(widgets) do
    if w.kind=='Button' and w.value=='Performance' then w.scripts.OnClick() end
end
local displayed=false
for _,w in ipairs(widgets) do
    if w.kind=='font' and w.value:find('Addon memory:',1,true) then displayed=true end
end
assert(displayed, 'performance panel displays metrics and unavailable fallbacks')
SlashCmdList.PEACEANDQUIET('perf')
''')
print('PASS: timing, memory/CPU readings, throttling, reset, disabled filter, missing APIs, performance view and command.')
