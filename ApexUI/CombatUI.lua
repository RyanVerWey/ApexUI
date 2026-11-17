local _,A=...
A.Suite.Register('combat','CombatUI.lua',function(_,M)
local FONT='Fonts\\FRIZQT__.TTF'
local gold={.89,.74,.47};local text={.93,.90,.83};local muted={.73,.70,.64}
local function label(parent,x,y,w,size,value,color)
 local f=parent:CreateFontString(nil,'OVERLAY');f:SetFont(FONT,size,'')
 f:SetPoint('TOPLEFT',x,y);f:SetWidth(w);f:SetJustifyH('LEFT');f:SetWordWrap(false)
 f:SetTextColor(unpack(color or text));f:SetText(value or '');return f
end
local function button(parent,x,y,w,value,fn)
 local b=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate');b:SetPoint('TOPLEFT',x,y)
 b:SetSize(w,28);b:SetText(value);b:GetFontString():SetFont(FONT,14,'');b:SetScript('OnClick',fn);return b
end
local function panel(name,w,h)
 local f=A.Suite.CreateFrame('combat','Frame',name,UIParent,'BackdropTemplate')
 f:SetSize(w,h);f:SetClampedToScreen(true);f:EnableMouse(true);f:SetMovable(true)
 f:RegisterForDrag('LeftButton');f:SetScript('OnDragStart',function(self) self:StartMoving() end)
 f:SetScript('OnDragStop',function(self) self:StopMovingOrSizing() end)
 f:SetBackdrop({edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=20})
 f:SetBackdropBorderColor(.58,.46,.29,1)
 local bg=f:CreateTexture(nil,'BACKGROUND');bg:SetPoint('TOPLEFT',5,-5);bg:SetPoint('BOTTOMRIGHT',-5,5)
 bg:SetColorTexture(.045,.036,.026,1);f:Hide()
 if A.Theme then A.Theme.Attach(f) end
 return f
end
local function fmt(n) return string.format('%.0f',n or 0) end
local function rate(d,t) return t and t>0 and d/t or 0 end
local function timer(t) return string.format('%d:%02d',math.floor((t or 0)/60),math.floor((t or 0)%60)) end
local function sink(f,value,suffix)
 -- Pass secret numbers directly to the engine. Never concatenate or calculate them.
 if M.Number(value) or not M.Plain(value) then f:SetFormattedText('%.0f'..(suffix or ''),value)
 else f:SetText('0'..(suffix or '')) end
end
function M.CreateUI()
 if M.frame or not M.db then return end
 local f=panel('ApexCombatMeter',322,242);M.frame=f
 f:SetPoint('BOTTOMLEFT',UIParent,'BOTTOMLEFT',22,300)
 if M.db.position then local p=M.db.position;f:ClearAllPoints();f:SetPoint(p[1],UIParent,p[2],p[3],p[4]) end
 f:HookScript('OnDragStop',function(self)
  local p,_,rp,x,y=self:GetPoint();M.db.position={p,rp,x,y}
 end)
 local heading=label(f,18,-17,220,19,'Apex Combat',gold)
 local close=CreateFrame('Button',nil,f,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',-4,-4)
 close:SetScript('OnClick',function() M.db.hidden=true;f:Hide() end)
 if A.Theme then A.Theme.Header(f,heading,close,{compact=true,top=12,dividerY=38,icon='Ability_DualWield'}) end
 f.caption=label(f,18,-50,280,14,'READY',muted)
 f.dps=label(f,18,-70,280,31,'0 DPS',gold)
 f.fight=label(f,18,-109,286,17,'Fight damage: 0')
 f.total=label(f,18,-140,286,17,'Since reset: 0')
 f.average=label(f,18,-166,286,14,'Average 0 DPS | 0:00 combat',muted)
 button(f,18,-200,134,'Dungeon report',function() M.ShowReport() end)
 f.reset=button(f,166,-200,138,'Reset totals',function()
  if M.Restricted() then return end
  if M.resetConfirm and GetTime()<M.resetConfirm then M.Reset();M.resetConfirm=nil
  else M.resetConfirm=GetTime()+5 end
  M.Render()
 end)
 f:SetScript('OnEnter',function(self)
  GameTooltip:SetOwner(self,'ANCHOR_TOP');GameTooltip:AddLine('Apex Combat',unpack(gold))
  GameTooltip:AddLine('Drag to move. Native combat data includes pet damage attributed to you.',1,1,1,true)
  GameTooltip:AddLine('Saved totals update after combat. Reset affects only your Apex totals.',1,1,1,true)
  GameTooltip:Show()
 end)
 f:SetScript('OnLeave',function() GameTooltip:Hide() end)
 f:SetShown(not M.db.hidden);M.Render()
end
function M.Render()
 local f=M.frame;if not f or not f:IsShown() or not M.db then return end
 local current=M.Current();local fighting=InCombatLockdown()
 f.caption:SetText(not M.Available() and 'COMBAT DATA UNAVAILABLE' or fighting and 'LIVE FIGHT' or current and 'LAST FIGHT' or 'READY FOR YOUR NEXT FIGHT')
 sink(f.dps,current and current.amountPerSecond,' DPS')
 if current then
  if M.Number(current.totalAmount) or not M.Plain(current.totalAmount) then f.fight:SetFormattedText('Fight damage: %.0f',current.totalAmount)
  else f.fight:SetText('Fight damage: 0') end
 else f.fight:SetText('Fight damage: 0') end
 f.total:SetText('Since reset: '..fmt(M.db.total.damage))
 f.average:SetText('Average '..fmt(rate(M.db.total.damage,M.db.total.seconds))..' DPS | '..timer(M.db.total.seconds)..' combat')
 f.reset:SetEnabled(not M.Restricted())
 f.reset:SetText(M.resetConfirm and GetTime()<M.resetConfirm and 'Confirm reset' or 'Reset totals')
end
local function makeReport()
 if M.report then return M.report end
 local f=panel('ApexCombatReport',930,500);M.report=f
 f:SetPoint('CENTER');table.insert(UISpecialFrames,'ApexCombatReport')
 local heading=label(f,24,-23,650,25,'Dungeon Report',gold)
 local close=CreateFrame('Button',nil,f,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',-6,-6)
 if A.Theme then A.Theme.Header(f,heading,close,{icon='Ability_DualWield'}) end
 f.title=label(f,24,-62,878,21,'')
 f.note=label(f,24,-93,878,15,'',muted)
 label(f,28,-140,280,15,'PARTY MEMBER',gold)
 local cols={{'AVG DPS',310,125},{'DAMAGE DONE',440,145},{'HEALING DONE',590,145},{'DAMAGE TAKEN',740,155}}
 for _,c in ipairs(cols) do local t=label(f,c[2],-140,c[3],15,c[1],gold);t:SetJustifyH('RIGHT') end
 f.scroll=CreateFrame('ScrollFrame',nil,f,'UIPanelScrollFrameTemplate');f.scroll:SetPoint('TOPLEFT',24,-170);f.scroll:SetSize(870,210)
 f.child=CreateFrame('Frame',nil,f.scroll);f.child:SetSize(870,1);f.scroll:SetScrollChild(f.child);f.rows={}
 f.footer=label(f,24,-393,878,15,'',muted)
 button(f,24,-436,145,'Current / last',function() M.previousView=false;M.ShowReport() end)
 button(f,180,-436,145,'Previous run',function() M.previousView=true;M.ShowReport() end)
 f.finish=button(f,650,-436,248,'Finish run manually',function()
  if M.Restricted() then return end
  if M.finishConfirm and GetTime()<M.finishConfirm then M.Finish('Finished manually');M.finishConfirm=nil
  else M.finishConfirm=GetTime()+5;f.finish:SetText('Confirm finished run') end
 end)
 return f
end
function M.ShowReport()
 if not M.db then return end
 if M.Restricted() then print('|cffe3bd78Apex Combat:|r Dungeon report is available after combat.');return end
 local f=makeReport();local run=M.previousView and M.db.previous or M.db.run
 f.title:SetText(run and run.name or 'No dungeon recorded yet')
 f.note:SetText(run and (run.status..' | '..timer(run.seconds)..' combat time') or 'Recording starts automatically when you enter a 5-player dungeon.')
 for _,r in ipairs(f.rows) do r:Hide() end
 local rows={}
 if run then for _,r in pairs(run.rows) do rows[#rows+1]=r end end
 table.sort(rows,function(a,b) if a.damage==b.damage then return (a.name or '')<(b.name or '') end;return a.damage>b.damage end)
 for i,data in ipairs(rows) do
  local row=f.rows[i]
  if not row then
   row=CreateFrame('Frame',nil,f.child);row:SetSize(870,35);row:SetPoint('TOPLEFT',0,-(i-1)*36)
   row.name=label(row,4,-7,280,17,'')
   row.values={}
   for j,c in ipairs({{286,125},{416,145},{566,145},{716,155}}) do
    row.values[j]=label(row,c[1],-7,c[2],17,'');row.values[j]:SetJustifyH('RIGHT')
   end
   if i%2==1 then local bg=row:CreateTexture(nil,'BACKGROUND');bg:SetAllPoints();bg:SetColorTexture(.14,.11,.07,.7) end
   f.rows[i]=row
  end
  row.name:SetText(data.name or 'Unknown member')
  local color=RAID_CLASS_COLORS and RAID_CLASS_COLORS[data.class]
  row.name:SetTextColor(color and color.r or .93,color and color.g or .90,color and color.b or .83)
  local values={rate(data.damage,run.seconds),data.damage,data.healing,data.taken}
  for j,v in ipairs(values) do row.values[j]:SetText(fmt(v)) end
  row:Show()
 end
 f.child:SetHeight(math.max(1,#rows*36))
 f.footer:SetText('Average DPS = damage / recorded combat time. Travel and downtime excluded. Leavers retained.')
 f.finish:SetEnabled(run==M.db.run and run~=nil and not run.closed and M.inDungeon and not M.Restricted())
 f.finish:SetText('Finish run manually');f:Show()
end
SLASH_APEXCOMBAT1='/apexcombat';SLASH_APEXCOMBAT2='/adps'
SlashCmdList.APEXCOMBAT=function(msg)
 if not M.db then return end
 if msg=='report' then M.ShowReport()
 elseif msg=='reset' then M.Reset()
 else
  M.CreateUI()
  if msg=='show' then M.db.hidden=false else M.db.hidden=not M.db.hidden end
  M.frame:SetShown(not M.db.hidden);M.Render()
 end
end
end)
