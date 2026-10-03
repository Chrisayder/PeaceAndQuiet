local _, ns = ...
function ns.CreateGuildPanel(parent)
    local label,action=ns.UI.label,ns.UI.action
    local view=CreateFrame('Frame',nil,parent,'BackdropTemplate')
    view:SetPoint('TOPLEFT',14,-108); view:SetPoint('BOTTOMRIGHT',-14,40)
    view:SetFrameLevel(parent:GetFrameLevel()+15); view:EnableMouse(true)
    ns.UI.skin(view)
    label(view,'Guild blocking - Work in progress',16,-18,'GameFontNormalLarge')
    action(view,'Back',462,-12,100,function() parent.ShowPage('settings') end)
    label(view,'Exact guild name (as the game displays it)',20,-52)
    local input=CreateFrame('EditBox',nil,view,'BackdropTemplate')
    ns.UI.inputStyle(input)
    input:SetPoint('TOPLEFT',24,-75); input:SetSize(380,26); input:SetAutoFocus(false)
    input:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
    local banner=CreateFrame('Frame',nil,view,'BackdropTemplate')
    banner:SetPoint('TOPLEFT',16,-110); banner:SetSize(545,40)
    ns.UI.skin(banner)
    local feedback=label(banner,'',10,-8,'GameFontHighlight')
    feedback:SetWidth(525); feedback:SetJustifyH('LEFT'); banner:Hide()
    local function message(ok,value)
        banner:SetBackdropColor(ok and 0.04 or 0.3,ok and 0.24 or 0.04,0.06,1)
        feedback:SetText(#value>80 and value:sub(1,77)..'...' or value); banner:Show()
    end
    label(view,'Search:',20,-170)
    local search=CreateFrame('EditBox',nil,view,'BackdropTemplate')
    ns.UI.inputStyle(search)
    search:SetPoint('TOPLEFT',84,-161); search:SetSize(455,26); search:SetAutoFocus(false)
    local stats=label(view,'',20,-197,'GameFontHighlightSmall')
    local scroll=CreateFrame('ScrollFrame',nil,view,'UIPanelScrollFrameTemplate')
    scroll:SetPoint('TOPLEFT',16,-220); scroll:SetPoint('BOTTOMRIGHT',-34,130)
    local content=CreateFrame('Frame',nil,scroll); content:SetSize(510,1); scroll:SetScrollChild(content)
    local empty=label(content,'No blocked guilds. Add one above.',0,0,'GameFontHighlight')
    local rows={}
    local function update()
        local keys,rules=ns.GuildEntries(search:GetText() or '')
        stats:SetText(#keys..' guilds shown | '..ns.GuildCacheCount()..' recently identified players')
        empty:SetShown(#keys==0)
        for i,key in ipairs(keys) do
            local row=rows[i]
            if not row then
                row=CreateFrame('CheckButton',nil,content,'UICheckButtonTemplate')
                row:SetPoint('TOPLEFT',0,-(i-1)*28); row:SetSize(26,26)
                row.caption=label(row,'',30,-6,'GameFontHighlight')
                row.caption:SetWidth(375); row.caption:SetJustifyH('LEFT'); row.caption:SetWordWrap(false)
                row:SetScript('OnClick',function(self) ns.SetGuildEnabled(self.key,not not self:GetChecked()) end)
                row.delete=action(row,'Delete',425,0,75,function()
                    local old=ns.DeleteGuild(row.key); if old then message(true,'Deleted guild: '..old.name) end
                    update()
                end)
                rows[i]=row
            end
            row.key=key; row:SetChecked(rules[key].enabled); row.caption:SetText(rules[key].name); row:Show()
        end
        for i=#keys+1,#rows do rows[i]:Hide() end
        content:SetHeight(math.max(28,#keys*28)); scroll:UpdateScrollChildRect()
    end
    local function submit()
        local ok,value=ns.AddBlockedGuild(input:GetText()); message(ok,value)
        if ok then input:SetText(''); search:SetText(''); update() end
    end
    input:SetScript('OnEnterPressed',submit)
    action(view,'Block guild',420,-76,125,submit)
    search:SetScript('OnTextChanged',function() scroll:SetVerticalScroll(0); update() end)
    local note=label(view,'WORK IN PROGRESS: guild detection is unreliable; blocks may be missed.\nOnly known guild members can be blocked. Unknown senders pass guild checks.\nTarget/hover players or view /who results to learn membership.\nNames match exactly. Battle.net is excluded. Membership expires in 10 minutes.\nUses the main enable switch and selected chat groups.',20,-406,'GameFontHighlightSmall')
    note:SetTextColor(1,0.75,0.35)
    note:SetWidth(535); note:SetJustifyH('LEFT')
    action(view,'Clear learned membership',20,-487,220,function() ns.ClearGuildCache(); update(); message(true,'Learned membership cleared.') end)
    view:SetScript('OnShow',update)
    local elapsed=0
    view:SetScript('OnUpdate',function(_,dt) elapsed=elapsed+dt; if elapsed>=1 then elapsed=0; update() end end)
    view:Hide()
    return view
end
