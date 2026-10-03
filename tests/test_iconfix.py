exec(open('tests/test_redesign.py').read())
lua.execute(r'''
local b=PeaceAndQuietMinimapButton
assert(rawget(b,'icon')==nil and rawget(b,'Icon')==nil, 'text must not occupy collector texture fields')
assert(b.pqLabel.kind=='font' and b.pqLabel:GetText()=='PQ')
-- Mirror the texture-selection branch used by Ellesmere, without the test
-- widget mock's catch-all method fallback for nonexistent fields.
local collectorButton={icon=rawget(b,'icon'),Icon=rawget(b,'Icon')}
local icon=collectorButton.icon or collectorButton.Icon
if icon then icon:GetTexCoord() end
PeaceAndQuietDB.enabled=false; ns.RefreshButton()
PeaceAndQuietDB.enabled=true; ns.RefreshButton()
b.scripts.OnEnter(b); b.scripts.OnLeave(b)
assert(b.pqLabel:GetText()=='PQ')
''')
print('PASS: text badge avoids Ellesmere texture fields; enabled, paused, and hover updates still work.')
