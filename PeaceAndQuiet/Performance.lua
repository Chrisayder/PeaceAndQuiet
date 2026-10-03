local addonName, ns = ...
local stats = {calls=0,total=0,peak=0}
local lastMemory, memory, peakMemory
local function number(value)
    if canaccessvalue and not canaccessvalue(value) then return nil end
    if issecretvalue and issecretvalue(value) then return nil end
    if type(value)=='number' and value>=0 and value<math.huge then return value end
end
local function read(fn,...)
    if type(fn)~='function' then return nil end
    local ok,value=pcall(fn,...)
    if ok then return number(value) end
end
function ns.PerfStart()
    if debugprofilestop then return debugprofilestop() end
end
function ns.PerfFinish(start)
    if not start or not debugprofilestop then return end
    local elapsed=debugprofilestop()-start
    -- Another addon may reset the shared profiling clock. Discard that sample.
    if elapsed<0 then return end
    stats.calls=stats.calls+1; stats.total=stats.total+elapsed
    stats.peak=math.max(stats.peak,elapsed)
end
function ns.ResetPerformance()
    stats.calls=0; stats.total=0; stats.peak=0
    peakMemory=memory
end
function ns.PerformanceSnapshot()
    local now=GetTime and GetTime() or 0
    if not lastMemory or now-lastMemory>=5 then
        lastMemory=now
        memory=nil
        if type(UpdateAddOnMemoryUsage)=='function' then
            local ok=pcall(UpdateAddOnMemoryUsage)
            if ok then memory=read(GetAddOnMemoryUsage,addonName) end
        end
        if memory then peakMemory=math.max(peakMemory or 0,memory) end
    end
    local cpu
    if C_AddOnProfiler and C_AddOnProfiler.IsEnabled and C_AddOnProfiler.GetAddOnMetric
        and Enum and Enum.AddOnProfilerMetric then
        local ok,enabled=pcall(C_AddOnProfiler.IsEnabled)
        if ok and enabled and Enum.AddOnProfilerMetric.RecentAverageTime then
            cpu=read(C_AddOnProfiler.GetAddOnMetric,addonName,Enum.AddOnProfilerMetric.RecentAverageTime)
        end
    end
    return {memory=memory,peakMemory=peakMemory,cpu=cpu,calls=stats.calls,total=stats.total,
        average=stats.calls>0 and stats.total/stats.calls or 0,peak=stats.peak,timer=type(debugprofilestop)=='function'}
end
function ns.PerformanceText()
    local s=ns.PerformanceSnapshot()
    local function mem(n) return n and string.format('%.2f MiB (%.0f KiB)',n/1024,n) or 'Unavailable on this client' end
    local lines={
        'Addon memory: '..mem(s.memory),
        'Peak sampled memory: '..mem(s.peakMemory),
        '',
        'Blizzard CPU recent average: '..(s.cpu and string.format('%.4f ms',s.cpu) or 'Unavailable / profiler disabled'),
        '',
        'Filter + logging timing (since login or reset)',
    }
    if s.timer then
        lines[#lines+1]=string.format('Timed filter calls: %d',s.calls)
        lines[#lines+1]=string.format('Average per call: %.4f ms',s.average)
        lines[#lines+1]=string.format('Slowest call: %.4f ms',s.peak)
        lines[#lines+1]=string.format('Total measured time: %.3f ms',s.total)
    else lines[#lines+1]='Timing API unavailable on this client.' end
    return table.concat(lines,'\n')
end
