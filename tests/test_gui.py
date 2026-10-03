exec(open('tests/test_addon.py').read())
lua.execute(r'''
widgets = {}
local function widget(kind, name, parent)
    local w={kind=kind, name=name, parent=parent, scripts={}, shown=true, value=''}
    local methods={}
    function methods:SetScript(k,v) self.scripts[k]=v end
    function methods:SetText(v) self.value=v; if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end end
    function methods:GetText() return self.value end
    function methods:SetChecked(v) self.checked=v end
    function methods:GetChecked() return self.checked end
    function methods:IsShown() return self.shown end
    function methods:SetShown(v) local old=self.shown; self.shown=v; if v and not old and self.scripts.OnShow then self.scripts.OnShow(self) end end
    function methods:Hide() self:SetShown(false) end
    function methods:Show() self:SetShown(true) end
    function methods:CreateFontString() return widget('font',nil,self) end
    function methods:SetBackdropColor(r,g,b,a) self.color={r,g,b,a} end
    function methods:CreateTexture() return widget('texture') end
    function methods:GetStringHeight() return 600 end
    function methods:GetWidth() return 140 end
    function methods:GetHeight() return 140 end
    function methods:GetFrameLevel() return 1 end
    function methods:GetEffectiveScale() return 1 end
    function methods:GetCenter() return 200,200 end
    setmetatable(w,{__index=function(_,k) return methods[k] or function() end end})
    widgets[#widgets+1]=w
    if name then _G[name]=w end
    return w
end
CreateFrame=widget; Minimap=widget('Minimap'); UIParent=widget('UIParent')
GameTooltip=widget('tooltip'); UISpecialFrames={}
function GetCursorPosition() return 200,300 end
ns.InitOptions(PeaceAndQuietDB)
assert(PeaceAndQuietMinimapButton:IsShown())
PeaceAndQuietMinimapButton.scripts.OnClick(nil,'LeftButton')
assert(PeaceAndQuietOptions:IsShown())
assert(#UISpecialFrames==1)
local edits, checks={},{}
for _,w in ipairs(widgets) do
    if w.kind=='EditBox' then edits[#edits+1]=w end
    if w.kind=='CheckButton' then checks[#checks+1]=w end
end
assert(#checks==8 and #edits==2)
checks[1]:SetChecked(false); checks[1].scripts.OnClick(checks[1])
assert(PeaceAndQuietDB.enabled==false)
checks[2]:SetChecked(false); checks[2].scripts.OnClick(checks[2])
assert(not PeaceAndQuietMinimapButton:IsShown())
edits[1]:SetText('pineapple'); PeaceAndQuietDB.ignored.vote=true
edits[1].scripts.OnEnterPressed()
assert(edits[1]:GetText()=='')
local confirmed=false
for _,w in ipairs(widgets) do if w.value=='Added: pineapple' then confirmed=true end end
assert(confirmed, 'Enter provides confirmation')
edits[1]:SetText('Banana bread')
for _,w in ipairs(widgets) do if w.value=='Add term' then w.scripts.OnClick() end end
assert(PeaceAndQuietDB.custom.pineapple and PeaceAndQuietDB.custom['banana bread'])
assert(PeaceAndQuietDB.ignored.vote)
for _,w in ipairs(widgets) do if w.value=='Reset button position' then w.scripts.OnClick() end end
assert(PeaceAndQuietMinimapButton:IsShown() and PeaceAndQuietDB.minimap.angle==225)
PeaceAndQuietMinimapButton.scripts.OnDragStart(PeaceAndQuietMinimapButton)
PeaceAndQuietMinimapButton.scripts.OnUpdate()
assert(math.abs(PeaceAndQuietDB.minimap.angle-90)<0.01)
PeaceAndQuietMinimapButton.scripts.OnDragStop(PeaceAndQuietMinimapButton)
assert(PeaceAndQuietMinimapButton.scripts.OnUpdate==nil)
assert(ns.ParseTerms(string.rep('a',121))==nil)
ns.ToggleOptions(); assert(not PeaceAndQuietOptions:IsShown())
ns.ToggleOptions(); assert(PeaceAndQuietOptions:IsShown() and #UISpecialFrames==1)
local function has(values, term)
    for _,v in ipairs(values) do if v==term then return true end end
    return false
end
PeaceAndQuietDB.mode='aggressive'; ns.Compile(PeaceAndQuietDB)
local terms,total=ns.ActiveTerms('')
assert(total==#terms and total>200)
assert(has(terms,'trump') and has(terms,'pineapple') and not has(terms,'vote'))
assert(has(terms,'pride'))
PeaceAndQuietDB.mode='strict'; ns.Compile(PeaceAndQuietDB)
assert(not has(ns.ActiveTerms(''),'pride'))
PeaceAndQuietDB.custom.vote=true; ns.Compile(PeaceAndQuietDB)
assert(has(ns.ActiveTerms(''),'vote'), 'custom terms override built-in ignore')
local filtered=ns.ActiveTerms('PINE')
assert(#filtered==1 and filtered[1]=='pineapple')
assert(#ns.ActiveTerms('xyznotaterm')==0)
for i=2,#terms do assert(terms[i-1]<terms[i], 'sorted and unique') end
for _,w in ipairs(widgets) do if w.kind=='Button' and w.value=='Manage filter terms' then w.scripts.OnClick() end end
edits[2]:SetText('PINE')
local found=false
for _,w in ipairs(widgets) do if w.kind=='font' and w.value=='pineapple  (custom)' then found=true end end
assert(found, 'search updates displayed list')
local row
for _,w in ipairs(widgets) do
    if w.kind=='CheckButton' and rawget(w,'term')=='pineapple' and w:IsShown() then row=w end
end
assert(row and row:GetChecked())
row:SetChecked(false); row.scripts.OnClick(row)
assert(not ns.Match('pineapple') and row:IsShown() and not row:GetChecked())
assert(has(ns.TermChoices('pine'),'pineapple'), 'unchecked custom remains available')
row:SetChecked(true); row.scripts.OnClick(row)
assert(ns.Match('pineapple') and row:GetChecked())
ns.SetTermEnabled('trump',false)
assert(not ns.Match('trump') and has(ns.TermChoices('trump'),'trump'))
ns.Compile(PeaceAndQuietDB)
assert(not ns.Match('trump'), 'disabled term survives recompilation')
ns.SetTermEnabled('trump',true); assert(ns.Match('trump'))
PeaceAndQuietDB.custom.vote=nil; PeaceAndQuietDB.mode='aggressive'; ns.Compile(PeaceAndQuietDB)
assert(not ns.termCatalog.vote.enabled and has(ns.TermChoices('vote'),'vote'), 'legacy ignored terms retained unchecked')
ns.SetTermEnabled('vote',true); assert(ns.Match('vote') and PeaceAndQuietDB.ignored.vote==nil)
PeaceAndQuietDB.custom.trump=true; ns.Compile(PeaceAndQuietDB)
ns.SetTermEnabled('trump',false); assert(not ns.Match('trump'), 'disable built-in plus custom duplicate')
PeaceAndQuietDB.mode='strict'; ns.Compile(PeaceAndQuietDB)
PeaceAndQuietDB.mode='aggressive'; ns.Compile(PeaceAndQuietDB)
assert(not ns.Match('trump'), 'mode change preserves disabled rule')
ns.SetTermEnabled('pineapple',false)
edits[1]:SetText('another term'); edits[1].scripts.OnEnterPressed()
assert(not ns.Match('pineapple'), 'saving custom editor preserves checkbox state')
PeaceAndQuietDB.mode='aggressive'; ns.Compile(PeaceAndQuietDB)
local _,aggressiveTotal=ns.TermChoices('')
PeaceAndQuietDB.mode='strict'; ns.Compile(PeaceAndQuietDB)
local _,strictTotal=ns.TermChoices('')
assert(aggressiveTotal==strictTotal, 'full catalog in both modes')
assert(has(ns.TermChoices('pride'),'pride') and not ns.termCatalog.pride.enabled)
ns.SetTermEnabled('pride',true)
assert(ns.Match('pride'), 'individual aggressive rule can be enabled in strict mode')
ns.Compile(PeaceAndQuietDB); assert(ns.Match('pride'), 'override persists')
ns.SetTermEnabled('pride',false); assert(not ns.Match('pride'))
local ok,msg=ns.AddCustomTerm('pineapple')
assert(ok and msg=='Enabled: pineapple' and ns.Match('pineapple'))
ok,msg=ns.AddCustomTerm('PINEAPPLE')
assert(ok and msg=='Already filtered: pineapple')
assert(not ns.AddCustomTerm('   '))
assert(not ns.AddCustomTerm(string.rep('a',121)))
assert(ns.Match('another term'), 'adding keeps previously added terms')
assert(ns.DeleteTerm('trump'))
assert(not ns.termCatalog.trump and not ns.Match('trump') and PeaceAndQuietDB.custom.trump==nil)
PeaceAndQuietDB.mode='aggressive'; ns.Compile(PeaceAndQuietDB)
assert(not ns.termCatalog.trump and not ns.Match('trump'), 'deleted preset remains absent')
assert(ns.UndoDelete()=='trump' and ns.termCatalog.trump, 'undo restores preset/custom entry')
assert(not ns.Match('trump'), 'undo preserves prior disabled state')
assert(ns.DeleteTerm('pineapple') and not ns.termCatalog.pineapple)
assert(ns.UndoDelete()=='pineapple' and ns.Match('pineapple'))
ns.DeleteTerm('pineapple'); ns.AddCustomTerm('pineapple')
assert(ns.UndoDelete()==nil and ns.Match('pineapple'), 're-add invalidates stale undo')
edits[2]:SetText('pineapple')
local deleteRow
for _,w in ipairs(widgets) do
    if w.kind=='CheckButton' and rawget(w,'term')=='pineapple' and w:IsShown() then deleteRow=w end
end
assert(deleteRow)
deleteRow.delete.scripts.OnClick()
assert(not ns.termCatalog.pineapple)
local deletionBanner=false
for _,w in ipairs(widgets) do
    if w.value=='Deleted: pineapple' and w.parent:IsShown() and w.parent.color[2]==0.24 then deletionBanner=true end
end
assert(deletionBanner, 'deletion shows green feedback banner')
for _,w in ipairs(widgets) do if w.kind=='Button' and w.value=='Undo delete' then w.scripts.OnClick() end end
assert(ns.termCatalog.pineapple and ns.Match('pineapple'))
edits[1]:SetText('ux feedback'); edits[1].scripts.OnEnterPressed()
local success=false
for _,w in ipairs(widgets) do if w.value=='Added: ux feedback' then success=true end end
assert(success)
''')
print('PASS: GUI callbacks, settings, term edits, validation, icon visibility, dragging, and panel reuse (mock WoW UI).')
