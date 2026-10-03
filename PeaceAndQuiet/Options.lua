local _, ns = ...
local db, panel, button, refresh
local function skin(frame, r, g, b)
    frame:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1})
    frame:SetBackdropColor(r or 0.065,g or 0.075,b or 0.09,1)
    frame:SetBackdropBorderColor(0.18,0.22,0.26,1)
end
local function label(parent, value, x, y, template)
    local text = parent:CreateFontString(nil, 'OVERLAY', template or 'GameFontNormal')
    text:SetPoint('TOPLEFT', x, y); text:SetText(value)
    if not template or template=='GameFontNormalLarge' then text:SetTextColor(0.4,0.88,0.77)
    elseif template=='GameFontHighlightSmall' then text:SetTextColor(0.64,0.7,0.76)
    else text:SetTextColor(0.9,0.93,0.96) end
    return text
end
local function inputStyle(edit)
    skin(edit,0.035,0.045,0.055)
    edit:SetFontObject(ChatFontNormal); edit:SetTextInsets(8,8,0,0)
end
local function action(parent, title, x, y, width, callback)
    local b = CreateFrame('Button', nil, parent, 'BackdropTemplate')
    skin(b,0.11,0.14,0.17)
    local titleText=b:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
    titleText:SetPoint('CENTER'); titleText:SetWidth(width-8); titleText:SetWordWrap(false)
    b:SetFontString(titleText)
    b:SetPoint('TOPLEFT', x, y); b:SetSize(width, 24); b:SetText(title)
    b:SetScript('OnEnter',function(self) self:SetBackdropColor(0.16,0.24,0.27,1); self:SetBackdropBorderColor(0.4,0.88,0.77,1) end)
    b:SetScript('OnLeave',function(self)
        self:SetBackdropColor(self.selected and 0.12 or 0.11,self.selected and 0.27 or 0.14,self.selected and 0.25 or 0.17,1)
        self:SetBackdropBorderColor(0.18,0.22,0.26,1)
    end)
    b:SetScript('OnClick', callback)
    return b
end
local function checkbox(parent, title, x, y, get, set)
    local b = CreateFrame('CheckButton', nil, parent, 'UICheckButtonTemplate')
    b:SetPoint('TOPLEFT', x, y); b:SetSize(26, 26)
    local t = b:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    t:SetPoint('LEFT', b, 'RIGHT', 3, 0); t:SetText(title)
    b:SetScript('OnClick', function(self) set(not not self:GetChecked()); refresh() end)
    b.read = function() b:SetChecked(get()) end
    return b
end
ns.UI={label=label,action=action,skin=skin,inputStyle=inputStyle}
local function placeButton()
    local radians = math.rad(db.minimap.angle)
    button:ClearAllPoints()
    button:SetPoint('CENTER', Minimap, 'CENTER', math.cos(radians) * (Minimap:GetWidth()/2 + 8),
        math.sin(radians) * (Minimap:GetHeight()/2 + 8))
end
function ns.RefreshButton()
    if not button then return end
    button:SetShown(not db.minimap.hide)
    local active=db.enabled
    button.pqLabel:SetTextColor(active and (button.hovered and 0.7 or 0.4) or 0.5,
        active and (button.hovered and 1 or 0.88) or 0.55,
        active and (button.hovered and 0.9 or 0.77) or 0.6)
end
local function sortedText(set)
    local values = {}
    for value, enabled in pairs(set) do if enabled then values[#values+1] = value end end
    table.sort(values); return table.concat(values, '\n')
end
local function parseTerms(value)
    local result = {}
    for line in value:gmatch('[^\r\n]+') do
        local term = ns.Normalize(line)
        if #term > 120 then return nil, 'Each term must be 120 bytes or fewer.' end
        if term ~= '' then result[term] = true end
    end
    return result
end
ns.ParseTerms = parseTerms
function ns.ActiveTerms(query)
    local values, seen = {}, {}
    query = ns.Normalize(query or '')
    for _, phrases in pairs(ns.index or {}) do
        for _, phrase in ipairs(phrases) do
            if not seen[phrase] then seen[phrase] = true; values[#values+1] = phrase end
        end
    end
    table.sort(values)
    local matches = {}
    for _, phrase in ipairs(values) do
        if query == '' or phrase:find(query, 1, true) then matches[#matches+1] = phrase end
    end
    return matches, #values
end
function ns.TermChoices(query)
    local terms, total, enabled = {}, 0, 0
    query = ns.Normalize(query or '')
    for term, info in pairs(ns.termCatalog or {}) do
        total=total+1
        if info.enabled then enabled=enabled+1 end
        if query=='' or term:find(query,1,true) then terms[#terms+1]=term end
    end
    table.sort(terms)
    return terms, total, enabled
end
function ns.SetTermEnabled(term, enabled)
    if not ns.termCatalog[term] then return end
    db.disabledTerms = db.disabledTerms or {}
    db.disabledTerms[term] = not enabled or nil
    db.enabledTerms = db.enabledTerms or {}
    local info = ns.termCatalog[term]
    if info.aggressive and not info.core then db.enabledTerms[term] = enabled or nil end
    if enabled then db.ignored[term] = nil end
    ns.Compile(db)
end
local deletedStack = {}
function ns.DeleteTerm(term)
    if not ns.termCatalog[term] then return false end
    deletedStack[#deletedStack+1]={term=term, custom=db.custom[term]}
    db.deletedTerms[term]=true; db.custom[term]=nil
    ns.Compile(db)
    return true
end
function ns.UndoDelete()
    local entry=table.remove(deletedStack)
    while entry and not db.deletedTerms[entry.term] do entry=table.remove(deletedStack) end
    if not entry then return end
    db.deletedTerms[entry.term]=nil
    db.custom[entry.term]=entry.custom
    ns.Compile(db)
    return entry.term
end
local function termBrowser(parent)
    local browser = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
    browser:SetPoint('TOPLEFT', 14, -108); browser:SetPoint('BOTTOMRIGHT', -14, 40)
    browser:SetFrameLevel(parent:GetFrameLevel()+10); browser:EnableMouse(true)
    skin(browser)
    label(browser, 'Manage filter terms', 16, -18, 'GameFontNormalLarge')
    action(browser, 'Back', 462, -12, 100, function() parent.ShowPage('settings') end)
    label(browser, 'Checked = filter this term. Unchecked = disable this rule. Changes apply now.', 16, -48, 'GameFontHighlightSmall')
    label(browser, 'Search:', 16, -80)
    local search = CreateFrame('EditBox', nil, browser, 'BackdropTemplate')
    inputStyle(search)
    search:SetPoint('TOPLEFT', 82, -72); search:SetSize(460,26); search:SetAutoFocus(false)
    search:SetScript('OnEscapePressed', function(self) self:ClearFocus(); parent.ShowPage('settings') end)
    local count = label(browser, '', 16, -111, 'GameFontHighlightSmall')
    local scroll = CreateFrame('ScrollFrame', nil, browser, 'UIPanelScrollFrameTemplate')
    scroll:SetPoint('TOPLEFT', 16, -139); scroll:SetPoint('BOTTOMRIGHT', -34, 90)
    local content = CreateFrame('Frame', nil, scroll)
    content:SetSize(510,1); scroll:SetScrollChild(content)
    local empty = label(content, 'No matching terms.', 0, 0, 'GameFontHighlight')
    local rows = {}
    local feedback=CreateFrame('Frame',nil,browser,'BackdropTemplate')
    feedback:SetPoint('TOPLEFT',12,-451); feedback:SetSize(550,44)
    skin(feedback)
    feedback:SetBackdropColor(0.04,0.24,0.06,1)
    local result=label(feedback,'',10,-8,'GameFontHighlight')
    result:SetWidth(395); result:SetJustifyH('LEFT'); result:SetTextColor(0.4,1,0.4)
    feedback:Hide()
    local function confirmation(message)
        result:SetText(#message>80 and message:sub(1,77)..'...' or message)
        feedback:Show()
    end
    local undo
    label(browser, 'Other matching rules can still hide a message.', 16, -500, 'GameFontHighlightSmall')
    local lastIndex, lastQuery, lastEnabled
    local update
    update = function()
        local query = search:GetText() or ''
        if lastIndex == ns.index and lastQuery == query and lastEnabled == db.enabled then return end
        local resetScroll = lastQuery ~= query
        lastIndex, lastQuery, lastEnabled = ns.index, query, db.enabled
        local terms, total, enabled = ns.TermChoices(query)
        count:SetText(string.format('%d shown / %d terms | %d checked | %s%s', #terms, total, enabled, db.mode,
            db.enabled and '' or ' | Filtering OFF'))
        empty:SetShown(#terms==0)
        for i, term in ipairs(terms) do
            local row=rows[i]
            if not row then
                row=CreateFrame('CheckButton', nil, content, 'UICheckButtonTemplate')
                row:SetSize(26,26); row:SetPoint('TOPLEFT',0,-(i-1)*28)
                row.caption=row:CreateFontString(nil,'OVERLAY','GameFontHighlight')
                row.caption:SetPoint('LEFT',row,'RIGHT',4,0); row.caption:SetWidth(374); row.caption:SetJustifyH('LEFT')
                row.caption:SetWordWrap(false)
                row:SetScript('OnEnter',function(self)
                    GameTooltip:SetOwner(self,'ANCHOR_RIGHT'); GameTooltip:AddLine(self.term,1,1,1,true); GameTooltip:Show()
                end)
                row:SetScript('OnLeave',function() GameTooltip:Hide() end)
                row:SetScript('OnClick',function(self)
                    ns.SetTermEnabled(self.term, not not self:GetChecked()); update()
                end)
                row.delete=action(row,'Delete',425,0,75,function()
                    local term=row.term
                    ns.DeleteTerm(term)
                    confirmation('Deleted: ' .. term); undo:Show(); update()
                end)
                rows[i]=row
            end
            local info=ns.termCatalog[term]
            row.term=term; row:SetChecked(info.enabled)
            row.caption:SetText(term .. (info.custom and '  (custom)' or (info.aggressive and not info.core and '  (aggressive)' or '')))
            row:Show()
        end
        for i=#terms+1,#rows do rows[i]:Hide() end
        content:SetHeight(math.max(28,#terms*28))
        if resetScroll then scroll:SetVerticalScroll(0) end
        scroll:UpdateScrollChildRect()
    end
    undo=action(feedback,'Undo delete',426,-10,110,function()
        local term=ns.UndoDelete()
        if term then confirmation('Restored: ' .. term); update() end
        undo:SetShown(#deletedStack>0)
    end)
    undo:SetShown(#deletedStack>0)
    search:SetScript('OnTextChanged', update)
    browser:SetScript('OnShow', update)
    local elapsed = 0
    browser:SetScript('OnUpdate', function(_, dt)
        elapsed=elapsed+dt
        if elapsed>=0.5 then elapsed=0; update() end
    end)
    browser:Hide()
    return browser
end
function ns.AddCustomTerm(value)
    local term=ns.Normalize(value)
    if term=='' then return false, 'Type a word or phrase first.' end
    if #term>120 then return false, 'Use a term of 120 bytes or fewer.' end
    local existing=ns.termCatalog[term]
    local wasEnabled=existing and existing.enabled
    db.custom[term]=true
    db.deletedTerms[term]=nil
    -- A deliberate re-add supersedes older undo records for this term.
    for i=#deletedStack,1,-1 do if deletedStack[i].term==term then table.remove(deletedStack,i) end end
    db.disabledTerms[term]=nil; db.ignored[term]=nil
    ns.Compile(db)
    return true, (wasEnabled and 'Already filtered: ' or existing and 'Enabled: ' or 'Added: ') .. term
end
local function performancePanel(parent)
    local view=CreateFrame('Frame',nil,parent,'BackdropTemplate')
    view:SetPoint('TOPLEFT',14,-108); view:SetPoint('BOTTOMRIGHT',-14,40)
    view:SetFrameLevel(parent:GetFrameLevel()+10); view:EnableMouse(true)
    skin(view)
    label(view,'Performance monitor',16,-18,'GameFontNormalLarge')
    action(view,'Back',462,-12,100,function() parent.ShowPage('settings') end)
    local metrics=label(view,'',20,-65,'GameFontHighlight')
    metrics:SetWidth(530); metrics:SetJustifyH('LEFT'); metrics:SetSpacing(8)
    local note=label(view,'Memory includes saved history and UI objects. Sampled every 5 seconds\nwhile this view is open; other values refresh every second.\n\nFilter timing includes matching and logging, not all addon activity.\nMultiple chat windows can cause multiple calls for one message.\nThese timings are not a system CPU percentage or an FPS measurement.\n\nNo global profiling settings are changed. Unavailable metrics are labeled.',20,-340,'GameFontHighlightSmall')
    note:SetWidth(530); note:SetJustifyH('LEFT')
    local function update() metrics:SetText(ns.PerformanceText()) end
    action(view,'Reset local measurements',20,-480,220,function() ns.ResetPerformance(); update() end)
    local elapsed=0
    view:SetScript('OnShow',function() elapsed=0; update() end)
    view:SetScript('OnUpdate',function(_,dt)
        elapsed=elapsed+dt
        if elapsed>=1 then elapsed=0; update() end
    end)
    view:Hide()
    return view
end
local function createPanel()
    panel=CreateFrame('Frame','PeaceAndQuietOptions',UIParent,'BackdropTemplate')
    panel:SetSize(610,680); panel:SetPoint('CENTER'); panel:SetFrameStrata('DIALOG')
    panel:SetClampedToScreen(true); panel:EnableMouse(true); panel:SetMovable(true)
    panel:RegisterForDrag('LeftButton')
    panel:SetScript('OnDragStart',panel.StartMoving)
    panel:SetScript('OnDragStop',panel.StopMovingOrSizing)
    skin(panel,0.035,0.045,0.055)
    -- Fit the window on small UI canvases without changing the user's global UI scale.
    local height=UIParent:GetHeight()
    if type(height)=='number' and height>0 then panel:SetScale(math.min(1,(height-30)/680)) end
    UISpecialFrames[#UISpecialFrames+1]='PeaceAndQuietOptions'
    label(panel,'PEACE & QUIET',22,-20,'GameFontNormalLarge')
    action(panel,'X',559,-16,30,function() panel:Hide() end)
    local stats=label(panel,'',22,-46,'GameFontHighlightSmall')
    local general=CreateFrame('Frame',nil,panel)
    general:SetPoint('TOPLEFT',0,-108); general:SetSize(610,530)
    local function card(title,y,height)
        local frame=CreateFrame('Frame',nil,general,'BackdropTemplate')
        frame:SetPoint('TOPLEFT',14,y); frame:SetSize(582,height); skin(frame)
        label(frame,title,14,-12)
        return frame
    end
    local behavior=card('FILTERING',0,123)
    local checks={}
    checks[#checks+1]=checkbox(behavior,'Enable filtering',12,-34,
        function() return db.enabled end,function(v) db.enabled=v end)
    checks[#checks+1]=checkbox(behavior,'Show minimap button',300,-34,
        function() return not db.minimap.hide end,function(v) db.minimap.hide=not v end)
    checks[#checks+1]=checkbox(behavior,'Aggressive filtering',12,-67,
        function() return db.mode=='aggressive' end,
        function(v) db.mode=v and 'aggressive' or 'strict'; ns.Compile(db) end)
    label(behavior,'Adds broader topics. Individual term choices are preserved.',18,-101,'GameFontHighlightSmall')
    local channels=card('CHAT GROUPS',-135,132)
    local scopes={{'public','Public / say / yell'},{'guild','Guild / officer'},
        {'group','Party / raid / instance'},{'whispers','Whispers / Battle.net'},{'community','Communities'}}
    for i,scope in ipairs(scopes) do
        local key=scope[1]
        checks[#checks+1]=checkbox(channels,scope[2],i%2==1 and 12 or 300,
            -35-math.floor((i-1)/2)*28,function() return db.scopes[key] end,
            function(v) db.scopes[key]=v end)
    end
    local terms=card('ADD A BLOCKED TERM',-279,163)
    local custom=CreateFrame('EditBox',nil,terms,'BackdropTemplate')
    inputStyle(custom)
    custom:SetPoint('TOPLEFT',20,-38); custom:SetSize(325,28); custom:SetAutoFocus(false)
    custom:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
    local feedback=CreateFrame('Frame',nil,terms,'BackdropTemplate')
    feedback:SetPoint('TOPLEFT',14,-78); feedback:SetSize(552,48); skin(feedback)
    local feedbackText=label(feedback,'',12,-10,'GameFontHighlight')
    feedbackText:SetWidth(526); feedbackText:SetJustifyH('LEFT'); feedback:Hide()
    label(terms,'Press Enter to save. Use Manage filter terms to toggle or delete rules.',18,-139,'GameFontHighlightSmall')
    local notice=label(general,'Changes apply immediately.',24,-514,'GameFontHighlightSmall')
    notice:SetWidth(560); notice:SetJustifyH('LEFT')
    local function submit()
        local ok,message=ns.AddCustomTerm(custom:GetText())
        feedback:SetBackdropColor(ok and 0.04 or 0.3,ok and 0.24 or 0.04,0.06,1)
        feedbackText:SetTextColor(ok and 0.4 or 1,ok and 1 or 0.4,0.4)
        feedbackText:SetText(#message>100 and message:sub(1,97)..'...' or message); feedback:Show()
        notice:SetText(ok and 'Saved. Your term is available in Manage filter terms.' or 'Term was not added.')
        if ok then custom:SetText(''); refresh() end
    end
    custom:SetScript('OnEnterPressed',submit)
    action(terms,'Add term',361,-40,100,submit)
    action(terms,'Clear input',469,-40,97,function() custom:SetText('') end)
    action(general,'Open filtered chat',14,-458,180,function() ns.RunCommand('log') end)
    action(general,'Clear history',205,-458,180,function()
        ns.ClearHistory(); notice:SetText('Saved history cleared.'); refresh()
    end)
    action(general,'Reset button position',396,-458,200,function()
        db.minimap.angle=225; db.minimap.hide=false; placeButton(); refresh()
    end)
    local pages={settings=general,terms=termBrowser(panel),performance=performancePanel(panel)}
    local tabs={}
    panel.ShowPage=function(key)
        if key=='guilds' and not pages.guilds then pages.guilds=ns.CreateGuildPanel(panel) end
        for name,page in pairs(pages) do page:SetShown(name==key) end
        for name,tab in pairs(tabs) do
            tab.selected=name==key
            tab:SetBackdropColor(tab.selected and 0.12 or 0.11,tab.selected and 0.27 or 0.14,tab.selected and 0.25 or 0.17,1)
            tab:SetBackdropBorderColor(tab.selected and 0.4 or 0.18,tab.selected and 0.88 or 0.22,tab.selected and 0.77 or 0.26,1)
        end
    end
    tabs.settings=action(panel,'Settings',14,-76,88,function() panel.ShowPage('settings') end)
    tabs.terms=action(panel,'Manage filter terms',110,-76,160,function() panel.ShowPage('terms') end)
    tabs.guilds=action(panel,'Guilds (Work in progress)',278,-76,188,function() panel.ShowPage('guilds') end)
    tabs.performance=action(panel,'Performance',474,-76,122,function() panel.ShowPage('performance') end)
    label(panel,'v1.9.3.1  |  Settings save on logout or /reload.',22,-654,'GameFontHighlightSmall')
    refresh=function()
        for _,check in ipairs(checks) do check.read() end
        stats:SetText(string.format('%s   /   %d checked   /   %d blocked   /   %d saved',
            db.enabled and 'FILTERING ON' or 'FILTERING OFF',ns.session.checked,ns.session.blocked,#db.history))
        ns.RefreshButton()
    end
    panel:SetScript('OnShow',function()
        custom:SetText(''); feedback:Hide(); notice:SetText('Changes apply immediately.'); refresh()
    end)
    local elapsed=0
    panel:SetScript('OnUpdate',function(_,dt)
        elapsed=elapsed+dt
        if elapsed>=0.5 then elapsed=0; refresh() end
    end)
    panel.ShowPage('settings'); panel:Hide()
end
function ns.ToggleOptions()
    if not db then return end
    if not panel then createPanel() end
    panel:SetShown(not panel:IsShown())
end
function ns.InitOptions(settings)
    db=settings
    if type(db.minimap)~='table' then db.minimap={} end
    if type(db.minimap.angle)~='number' then db.minimap.angle=225 end
    if type(db.minimap.hide)~='boolean' then db.minimap.hide=false end
    if button or not Minimap then return end
    button=CreateFrame('Button', 'PeaceAndQuietMinimapButton', Minimap)
    button:SetSize(32,32); button:SetFrameStrata('MEDIUM'); button:SetFrameLevel(Minimap:GetFrameLevel()+8)
    button:RegisterForClicks('LeftButtonUp','RightButtonUp'); button:RegisterForDrag('LeftButton')
    -- Transparent badge: collectors can supply their own circular frame without
    -- a square backdrop or border protruding beyond it.
    -- Native text stays sharp at UI scale; no spell artwork or image dependency.
    local icon=button:CreateFontString(nil,'OVERLAY','GameFontNormal')
    icon:SetFont(STANDARD_TEXT_FONT,13,'OUTLINE')
    -- Collectors reserve icon/Icon for textures and call GetTexCoord on them.
    icon:SetPoint('CENTER',0,0); icon:SetText('PQ'); button.pqLabel=icon
    button:SetScript('OnClick', function(_, click)
        if click=='RightButton' then ns.RunCommand('log') else ns.ToggleOptions() end
    end)
    button:SetScript('OnEnter', function(self)
        self.hovered=true; ns.RefreshButton()
        GameTooltip:SetOwner(self,'ANCHOR_LEFT'); GameTooltip:AddLine('Peace and Quiet')
        GameTooltip:AddLine(db.enabled and 'Filtering ON' or 'Filtering OFF',1,1,1)
        GameTooltip:AddLine('Left-click: settings\nRight-click: filtered chat\nDrag to reposition',1,1,1)
        GameTooltip:Show()
    end)
    button:SetScript('OnLeave', function(self) self.hovered=false; ns.RefreshButton(); GameTooltip:Hide() end)
    button:SetScript('OnDragStart', function(self)
        GameTooltip:Hide()
        self:SetScript('OnUpdate', function()
            local x,y=GetCursorPosition(); local cx,cy=Minimap:GetCenter(); local scale=Minimap:GetEffectiveScale()
            db.minimap.angle=math.deg(math.atan2(y/scale-cy,x/scale-cx)); placeButton()
        end)
    end)
    button:SetScript('OnDragStop', function(self) self:SetScript('OnUpdate',nil) end)
    placeButton(); ns.RefreshButton()
end
