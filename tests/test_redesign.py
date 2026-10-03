exec(open('tests/test_guilds.py').read())
lua.execute(r'''
local views={}
for _,w in ipairs(widgets) do
    if w.kind=='font' then
        if w.value=='FILTERING' then views.settings=w.parent.parent end
        if w.value=='Manage filter terms' then views.terms=w.parent end
        if w.value=='Performance monitor' then views.performance=w.parent end
        if w.value=='Guild blocking - Work in progress' then views.guilds=w.parent end
    end
end
for _,name in ipairs({'settings','terms','performance','guilds'}) do
    assert(views[name],name)
    PeaceAndQuietOptions.ShowPage(name)
    for key,view in pairs(views) do assert(view:IsShown()==(key==name),'only selected page shown') end
end
local back
for _,w in ipairs(widgets) do
    if w.kind=='Button' and w.value=='Back' and w.parent==views.guilds then back=w end
end
back.scripts.OnClick()
assert(views.settings:IsShown() and not views.guilds:IsShown())
local wip=false
for _,w in ipairs(widgets) do
    if w.kind=='Button' and w.value=='Guilds (Work in progress)' then wip=true end
end
assert(wip)
''')
print('PASS: exclusive page navigation, Back behavior, and WIP label.')
