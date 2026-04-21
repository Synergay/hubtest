--[[
	LumenUI v2.1 — Modern Roblox Luau GUI Library (HTML-accurate)
	-----------------------------------------------------------
	Single-file ModuleScript / loadstring target.

	local ui = loadstring(game:HttpGet("..."))()
	local w  = ui:CreateWindow({
		Title="Lumen", Subtitle="v2.0",
		Size=UDim2.fromOffset(780,520),
		Theme="Amber", Font="Gotham",
		Keybind=Enum.KeyCode.RightShift,
		Scale=1,                 -- UI scale 0.5 .. 3
		ConfigFolder="Lumen/MyGame",
	})

	-- Full runtime customisation
	w:SetTheme("Mint")                         -- preset
	w:SetTheme({Bg=...,Accent=...,...})        -- full override
	w:Customize({Accent=Color3.fromRGB(...)})  -- partial merge
	w:SetAccent(c3)     w:SetBg(c3)     w:SetSurface(c3)   w:SetText(c3)
	w:SetFont("Inter")  w:SetFont({Display=..,Title=..,Body=..,Mono=..})
	w:SetScale(1.25)
	ui.Themes.MyPalette = {...}                -- register new theme
]]

local TS=game:GetService("TweenService")
local UIS=game:GetService("UserInputService")
local RS=game:GetService("RunService")
local Plrs=game:GetService("Players")
local HS=game:GetService("HttpService")

local LP=Plrs.LocalPlayer
local PG=LP and LP:FindFirstChildOfClass("PlayerGui")

local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end

local Themes={
	Amber={Bg=rgb(24,23,26),Surface=rgb(31,31,35),SurfaceAlt=rgb(38,38,43),Elevated=rgb(46,46,52),Text=rgb(238,238,242),TextMuted=rgb(160,160,168),TextDim=rgb(108,108,118),Stroke=rgb(56,56,62),StrokeSoft=rgb(44,44,50),Accent=rgb(245,168,54),AccentText=rgb(26,18,6),Danger=rgb(232,90,90)},
	Mint={Bg=rgb(23,27,25),Surface=rgb(30,35,33),SurfaceAlt=rgb(37,43,40),Elevated=rgb(45,52,48),Text=rgb(238,240,238),TextMuted=rgb(156,168,162),TextDim=rgb(104,116,110),Stroke=rgb(54,62,58),StrokeSoft=rgb(42,50,46),Accent=rgb(120,220,170),AccentText=rgb(6,22,16),Danger=rgb(232,90,90)},
	Iris={Bg=rgb(24,24,30),Surface=rgb(31,31,39),SurfaceAlt=rgb(38,38,47),Elevated=rgb(46,46,56),Text=rgb(238,236,246),TextMuted=rgb(160,156,176),TextDim=rgb(108,104,124),Stroke=rgb(58,54,72),StrokeSoft=rgb(46,42,58),Accent=rgb(168,144,255),AccentText=rgb(14,10,36),Danger=rgb(232,90,120)},
	Rose={Bg=rgb(28,23,25),Surface=rgb(35,29,31),SurfaceAlt=rgb(42,35,37),Elevated=rgb(50,42,45),Text=rgb(240,234,235),TextMuted=rgb(170,156,160),TextDim=rgb(120,106,110),Stroke=rgb(62,52,55),StrokeSoft=rgb(50,42,45),Accent=rgb(240,122,146),AccentText=rgb(32,10,16),Danger=rgb(232,90,90)},
	Mono={Bg=rgb(12,12,12),Surface=rgb(20,20,20),SurfaceAlt=rgb(26,26,26),Elevated=rgb(32,32,32),Text=rgb(240,240,240),TextMuted=rgb(150,150,150),TextDim=rgb(100,100,100),Stroke=rgb(42,42,42),StrokeSoft=rgb(28,28,28),Accent=rgb(240,240,240),AccentText=rgb(12,12,12),Danger=rgb(232,90,90)},
}

local Fonts={
	Gotham={Display=Enum.Font.GothamBold,Title=Enum.Font.GothamBold,Body=Enum.Font.Gotham,Mono=Enum.Font.Code},
	Inter={Display=Enum.Font.BuilderSansBold,Title=Enum.Font.BuilderSansBold,Body=Enum.Font.BuilderSans,Mono=Enum.Font.Code},
	Sans={Display=Enum.Font.SourceSansBold,Title=Enum.Font.SourceSansBold,Body=Enum.Font.SourceSans,Mono=Enum.Font.Code},
	Mono={Display=Enum.Font.Code,Title=Enum.Font.Code,Body=Enum.Font.Code,Mono=Enum.Font.Code},
}

local function mk(c,p,ch)
	local i=Instance.new(c)
	if p then for k,v in pairs(p) do i[k]=v end end
	if ch then for _,x in ipairs(ch) do x.Parent=i end end
	return i
end
local function cor(r) return mk("UICorner",{CornerRadius=UDim.new(0,r)}) end
local function strk(c,t) return mk("UIStroke",{Color=c,Thickness=t or 1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border}) end
local function pad(t,r,b,l) return mk("UIPadding",{PaddingTop=UDim.new(0,t or 0),PaddingRight=UDim.new(0,r or t or 0),PaddingBottom=UDim.new(0,b or t or 0),PaddingLeft=UDim.new(0,l or r or t or 0)}) end
local function lst(d,g) return mk("UIListLayout",{FillDirection=d or Enum.FillDirection.Vertical,Padding=UDim.new(0,g or 0),SortOrder=Enum.SortOrder.LayoutOrder}) end
local function tw(o,t,p) return TS:Create(o,TweenInfo.new(t,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),p):Play() end

local hasFS=(writefile and readfile and isfile and listfiles and makefolder and isfolder)~=nil
local function fs(fn,...) if not hasFS then return false end local ok,r=pcall(fn,...) return ok and r or nil end

local iconMap={
	sword="⚔",user="☺",eye="◎",grid="▦",shield="◈",cog="⚙",code="⟨⟩",folder="▣",
	bolt="⌁",sparkle="✦",cross="✕",list="☰",home="⌂",chart="▤",star="★",heart="♥",
}

local function toHex(c) return string.format("#%02X%02X%02X",math.floor(c.R*255+.5),math.floor(c.G*255+.5),math.floor(c.B*255+.5)) end

local LumenUI={Version="2.1.0",Flags={},_components={},_windows={},Themes=Themes,Fonts=Fonts}
LumenUI.__index=LumenUI
function LumenUI._bindFlag(f,o) if f then LumenUI.Flags[f]=o end end
function LumenUI:RegisterComponent(n,f) self._components[n]=f end

local Win={} Win.__index=Win
local Cat={} Cat.__index=Cat
local Tab={} Tab.__index=Tab
local Sec={} Sec.__index=Sec

local function regT(w,i,prop,tok)
	i[prop]=w.Theme[tok]
	table.insert(w._themed,{i=i,p=prop,t=tok})
	return i
end
local function regF(w,i,slot)
	i.Font=w.Font[slot]
	table.insert(w._fonted,{i=i,s=slot})
	return i
end

function Win:_mk(cls,props,tmap,fslot,children)
	local i=Instance.new(cls)
	if props then for k,v in pairs(props) do i[k]=v end end
	if tmap then for p,t in pairs(tmap) do regT(self,i,p,t) end end
	if fslot then regF(self,i,fslot) end
	if children then for _,c in ipairs(children) do c.Parent=i end end
	return i
end
function Win:_str(tok,t)
	local s=mk("UIStroke",{Thickness=t or 1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	regT(self,s,"Color",tok)
	return s
end

function Win:SetTheme(name)
	local t=type(name)=="table" and name or Themes[name]
	if not t then return end
	if type(name)=="string" then self.ThemeName=name end
	for k,v in pairs(t) do self.Theme[k]=v end
	for i=#self._themed,1,-1 do
		local e=self._themed[i]
		if not e.i or not e.i.Parent then table.remove(self._themed,i)
		else local c=self.Theme[e.t] if c then e.i[e.p]=c end end
	end
	for _,fn in ipairs(self._onTheme) do task.spawn(fn,self.Theme) end
end

function Win:Customize(tbl)
	if type(tbl)~="table" then return end
	for k,v in pairs(tbl) do self.Theme[k]=v end
	self:SetTheme(self.Theme)
end
function Win:SetAccent(c) self:Customize({Accent=c}) end
function Win:SetBg(c) self:Customize({Bg=c}) end
function Win:SetSurface(c) self:Customize({Surface=c}) end
function Win:SetText(c) self:Customize({Text=c}) end

function Win:SetFont(name)
	local f=type(name)=="table" and name or Fonts[name]
	if not f then return end
	if type(name)=="string" then self.FontName=name end
	self.Font=f
	for i=#self._fonted,1,-1 do
		local e=self._fonted[i]
		if not e.i or not e.i.Parent then table.remove(self._fonted,i)
		else e.i.Font=f[e.s] or e.i.Font end
	end
end

function Win:SetScale(s) if self.UIScale then self.UIScale.Scale=math.clamp(s or 1,0.5,3) end end

function Win:Destroy()
	for _,c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
	table.clear(self._conns)
	if self.Gui then self.Gui:Destroy() end
end

function Win:ToggleMinimize()
	self._minimized=not self._minimized
	self.Frame.Size=self._minimized and UDim2.fromOffset(self.Size.X.Offset,self.TitlebarHeight) or self.Size
end

function Win:_makeDraggable(fr,handle)
	local drag,si,sp
	table.insert(self._conns,handle.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
			drag=true si=i.Position sp=fr.Position
			table.insert(self._conns,i.Changed:Connect(function()
				if i.UserInputState==Enum.UserInputState.End then drag=false end
			end))
		end
	end))
	table.insert(self._conns,UIS.InputChanged:Connect(function(i)
		if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
			local d=i.Position-si
			fr.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
		end
	end))
end

local _cfgFactory

function LumenUI:CreateWindow(opts)
	opts=opts or {}
	local w=setmetatable({},Win)
	w.Title=opts.Title or "Lumen"
	w.Subtitle=opts.Subtitle or "v2.0"
	w.Size=opts.Size or UDim2.fromOffset(780,520)
	w.Theme=table.clone(Themes[opts.Theme or "Amber"] or Themes.Amber)
	w.ThemeName=opts.Theme or "Amber"
	w.Font=Fonts[opts.Font or "Gotham"] or Fonts.Gotham
	w.FontName=opts.Font or "Gotham"
	w.ToggleKey=opts.Keybind or Enum.KeyCode.RightShift
	w.ConfigFolder=opts.ConfigFolder or "Lumen/Default"
	w.Categories,w.Tabs={},{}
	w._themed,w._fonted,w._conns,w._onTheme={},{},{},{}
	w.SidebarWidth=opts.SidebarWidth or math.max(180,math.floor(w.Size.X.Offset*0.28))
	w.TitlebarHeight=opts.TitlebarHeight or 44

	local parent=opts.Parent or (gethui and gethui()) or PG or game:GetService("CoreGui")
	local gui=mk("ScreenGui",{Name="LumenUI_"..HS:GenerateGUID(false):sub(1,8),ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,IgnoreGuiInset=true,DisplayOrder=9999})
	if syn and syn.protect_gui then pcall(syn.protect_gui,gui) end
	gui.Parent=parent
	w.Gui=gui

	local fr=w:_mk("Frame",{Name="Window",Size=w.Size,Position=UDim2.new(0.5,-w.Size.X.Offset/2,0.5,-w.Size.Y.Offset/2),BorderSizePixel=0,ClipsDescendants=true},{BackgroundColor3="Bg"},nil,{cor(14)})
	w:_str("Stroke",1).Parent=fr
	fr.Parent=gui
	w.Frame=fr

	w.UIScale=mk("UIScale",{Scale=opts.Scale or 1})
	w.UIScale.Parent=fr

	local tbH=w.TitlebarHeight

	local tb=w:_mk("Frame",{Size=UDim2.new(1,0,0,tbH),BorderSizePixel=0},{BackgroundColor3="Surface"})
	tb.Parent=fr
	w:_mk("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BorderSizePixel=0},{BackgroundColor3="Stroke"}).Parent=tb
	w:_mk("TextLabel",{Size=UDim2.new(0,400,1,0),Position=UDim2.new(0,20,0,0),BackgroundTransparency=1,TextSize=12,Text=string.upper(w.Title),TextXAlignment=Enum.TextXAlignment.Left},{TextColor3="Text"},"Display").Parent=tb

	local wcGroup=mk("Frame",{Size=UDim2.new(0,90,1,0),Position=UDim2.new(1,-110,0,0),BackgroundTransparency=1},{lst(Enum.FillDirection.Horizontal,18)})
	wcGroup.Parent=tb
	mk("UIPadding",{PaddingTop=UDim.new(0,math.floor(tbH/2)-8)}).Parent=wcGroup
	local function wcBtn(lbl,cb)
		local b=w:_mk("TextButton",{Size=UDim2.new(0,16,0,16),BackgroundTransparency=1,AutoButtonColor=false,TextSize=14,Text=lbl},{TextColor3="TextMuted"},"Body")
		b.Parent=wcGroup
		b.MouseButton1Click:Connect(cb or function() end)
		return b
	end
	wcBtn("—",function() w:ToggleMinimize() end)
	wcBtn("◻",function() end)
	wcBtn("×",function() w:Destroy() end)

	w:_makeDraggable(fr,tb)

	local sbW=w.SidebarWidth
	local sb=w:_mk("Frame",{Size=UDim2.new(0,sbW,1,-tbH),Position=UDim2.new(0,0,0,tbH),BorderSizePixel=0},{BackgroundColor3="Surface"})
	sb.Parent=fr
	w:_mk("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(1,-1,0,0),BorderSizePixel=0},{BackgroundColor3="Stroke"}).Parent=sb

	local brand=mk("Frame",{Size=UDim2.new(1,0,0,48),BackgroundTransparency=1})
	brand.Parent=sb
	pad(12,12,12,16).Parent=brand
	local mark=w:_mk("Frame",{Size=UDim2.new(0,20,0,20),Position=UDim2.new(0,0,0.5,-10),BorderSizePixel=0},{BackgroundColor3="Accent"},nil,{cor(6)})
	mark.Parent=brand
	w:_mk("Frame",{Size=UDim2.new(0,8,0,8),Position=UDim2.new(0.5,-4,0.5,-4),BorderSizePixel=0},{BackgroundColor3="Surface"},nil,{cor(2)}).Parent=mark
	w:_mk("TextLabel",{Size=UDim2.new(1,-70,1,0),Position=UDim2.new(0,30,0,0),BackgroundTransparency=1,TextSize=13,Text=w.Title,TextXAlignment=Enum.TextXAlignment.Left},{TextColor3="Text"},"Title").Parent=brand
	w:_mk("TextLabel",{Size=UDim2.new(0,50,0,16),Position=UDim2.new(1,-54,0.5,-8),BackgroundTransparency=1,TextSize=10,Text=w.Subtitle,TextXAlignment=Enum.TextXAlignment.Right},{TextColor3="TextDim"},"Body").Parent=brand
	w:_mk("Frame",{Size=UDim2.new(1,-12,0,1),Position=UDim2.new(0,6,1,-1),BorderSizePixel=0},{BackgroundColor3="StrokeSoft"}).Parent=brand

	local sideList=mk("ScrollingFrame",{Size=UDim2.new(1,0,1,-48-28),Position=UDim2.new(0,0,0,48),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=0,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(0,0,0,0)},{pad(10,12,14,12),lst(Enum.FillDirection.Vertical,2)})
	sideList.Parent=sb
	w.SideList=sideList

	local sbFoot=mk("Frame",{Size=UDim2.new(1,0,0,28),Position=UDim2.new(0,0,1,-28),BackgroundTransparency=1})
	sbFoot.Parent=sb
	w:_mk("Frame",{Size=UDim2.new(1,-12,0,1),Position=UDim2.new(0,6,0,0),BorderSizePixel=0},{BackgroundColor3="StrokeSoft"}).Parent=sbFoot
	w:_mk("TextLabel",{Size=UDim2.new(0.7,0,1,0),Position=UDim2.new(0,16,0,0),BackgroundTransparency=1,TextSize=11,Text=(w.ToggleKey.Name or "RightShift").." · toggle",TextXAlignment=Enum.TextXAlignment.Left},{TextColor3="TextDim"},"Body").Parent=sbFoot
	w:_mk("TextLabel",{Size=UDim2.new(0.3,-16,1,0),Position=UDim2.new(0.7,0,0,0),BackgroundTransparency=1,TextSize=11,Text="● online",TextXAlignment=Enum.TextXAlignment.Right},{TextColor3="TextDim"},"Body").Parent=sbFoot

	local content=w:_mk("Frame",{Size=UDim2.new(1,-sbW,1,-tbH),Position=UDim2.new(0,sbW,0,tbH),BorderSizePixel=0},{BackgroundColor3="Bg"})
	content.Parent=fr
	w.Content=content

	table.insert(w._conns,UIS.InputBegan:Connect(function(input,gp)
		if gp then return end
		if input.KeyCode==w.ToggleKey then w.Gui.Enabled=not w.Gui.Enabled end
	end))

	w.Config=_cfgFactory(w)
	table.insert(LumenUI._windows,w)
	return w
end

function Win:AddCategory(name)
	local lbl=self:_mk("TextLabel",{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,TextSize=10,Text=string.upper(name),TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=#self.Categories*1000},{TextColor3="TextDim"},"Display",{pad(12,0,6,10)})
	lbl.Parent=self.SideList
	local c=setmetatable({Window=self,Name=name,Order=#self.Categories*1000,Tabs={}},Cat)
	table.insert(self.Categories,c)
	return c
end

function Cat:AddTab(name,icon)
	local w=self.Window
	local order=self.Order+#self.Tabs+1
	local btn=mk("TextButton",{Size=UDim2.new(1,0,0,34),BackgroundTransparency=1,AutoButtonColor=false,Text="",LayoutOrder=order,BorderSizePixel=0},{cor(8)})
	btn.Parent=w.SideList
	regT(w,btn,"BackgroundColor3","Elevated")
	local btnStroke=w:_str("Stroke",1)
	btnStroke.Enabled=false
	btnStroke.Parent=btn
	local ico=w:_mk("TextLabel",{Size=UDim2.new(0,18,0,18),Position=UDim2.new(0,10,0.5,-9),BackgroundTransparency=1,TextSize=14,Text=iconMap[icon] or icon or "•"},{TextColor3="TextMuted"},"Body")
	ico.Parent=btn
	local txt=w:_mk("TextLabel",{Size=UDim2.new(1,-40,1,0),Position=UDim2.new(0,36,0,0),BackgroundTransparency=1,TextSize=13,Text=name,TextXAlignment=Enum.TextXAlignment.Left},{TextColor3="TextMuted"},"Title")
	txt.Parent=btn

	local page=mk("ScrollingFrame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,Visible=false,ScrollBarThickness=4,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(0,0,0,0)},{pad(24,30,40,30),lst(Enum.FillDirection.Vertical,16)})
	regT(w,page,"ScrollBarImageColor3","Stroke")
	page.Parent=w.Content

	local tab=setmetatable({Window=w,Category=self,Name=name,Button=btn,Label=txt,Icon=ico,Stroke=btnStroke,Page=page,Sections={}},Tab)
	table.insert(self.Tabs,tab)
	table.insert(w.Tabs,tab)

	btn.MouseButton1Click:Connect(function() w:SelectTab(tab) end)
	btn.MouseEnter:Connect(function()
		if w.Active~=tab then
			tw(btn,0.1,{BackgroundTransparency=0.6})
			tw(txt,0.1,{TextColor3=w.Theme.Text})
			tw(ico,0.1,{TextColor3=w.Theme.Text})
		end
	end)
	btn.MouseLeave:Connect(function()
		if w.Active~=tab then
			tw(btn,0.1,{BackgroundTransparency=1})
			tw(txt,0.1,{TextColor3=w.Theme.TextMuted})
			tw(ico,0.1,{TextColor3=w.Theme.TextMuted})
		end
	end)
	if #w.Tabs==1 then w:SelectTab(tab) end
	return tab
end

function Win:SelectTab(tab)
	for _,t in ipairs(self.Tabs) do
		t.Page.Visible=false
		tw(t.Button,0.1,{BackgroundTransparency=1})
		tw(t.Label,0.1,{TextColor3=self.Theme.TextMuted})
		tw(t.Icon,0.1,{TextColor3=self.Theme.TextMuted})
		t.Stroke.Enabled=false
	end
	tab.Page.Visible=true
	tw(tab.Button,0.15,{BackgroundTransparency=0})
	tw(tab.Label,0.15,{TextColor3=self.Theme.Text})
	tw(tab.Icon,0.15,{TextColor3=self.Theme.Text})
	tab.Stroke.Enabled=true
	self.Active=tab
end

function Tab:AddSection(title)
	local w=self.Window
	local card=w:_mk("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BorderSizePixel=0,LayoutOrder=#self.Sections+1},{BackgroundColor3="Surface"},nil,{cor(12)})
	w:_str("StrokeSoft",1).Parent=card
	card.Parent=self.Page
	local inner=mk("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1},{pad(16,22,18,22),lst(Enum.FillDirection.Vertical,0)})
	inner.Parent=card
	w:_mk("TextLabel",{Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,TextSize=15,Text=title,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=0},{TextColor3="Text"},"Title").Parent=inner
	local s=setmetatable({Tab=self,Window=w,Card=card,Inner=inner,Rows={}},Sec)
	table.insert(self.Sections,s)
	return s
end

function Sec:_buildRow(name,desc,full,rightW)
	local w=self.Window
	local row=mk("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=#self.Rows+1},{lst(Enum.FillDirection.Vertical,0)})
	row.Parent=self.Inner
	if #self.Rows>0 then
		w:_mk("Frame",{Size=UDim2.new(1,0,0,1),BorderSizePixel=0,LayoutOrder=0},{BackgroundColor3="StrokeSoft"}).Parent=row
	end
	local body=mk("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=1},{pad(14,0,14,0)})
	body.Parent=row
	if full then lst(Enum.FillDirection.Vertical,10).Parent=body end
	rightW=rightW or 200
	local leftW=full and UDim2.new(1,0,0,0) or UDim2.new(1,-rightW-16,0,0)
	local left=mk("Frame",{Size=leftW,AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=0},{lst(Enum.FillDirection.Vertical,3)})
	left.Parent=body
	if name then
		w:_mk("TextLabel",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,TextSize=13,Text=name,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=0},{TextColor3="Text"},"Title").Parent=left
	end
	if desc and desc~="" then
		w:_mk("TextLabel",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,TextSize=12,Text=desc,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=1},{TextColor3="TextMuted"},"Body").Parent=left
	end
	local right
	if not full then
		right=mk("Frame",{Size=UDim2.new(0,rightW,0,32),Position=UDim2.new(1,-rightW,0,0),BackgroundTransparency=1})
		right.Parent=body
	end
	table.insert(self.Rows,row)
	return row,left,right,body
end

function Sec:AddToggle(opts)
	opts=opts or {}
	local w=self.Window
	local _,_,right=self:_buildRow(opts.Name or "Toggle",opts.Description,false,44)
	local state=opts.Default and true or false
	local track=mk("Frame",{Size=UDim2.new(0,40,0,22),Position=UDim2.new(1,-40,0.5,-11),BorderSizePixel=0},{cor(11)})
	track.Parent=right
	local trackStr=mk("UIStroke",{Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	trackStr.Parent=track
	local knob=mk("Frame",{Size=UDim2.new(0,16,0,16),BorderSizePixel=0},{cor(8)})
	knob.Parent=track
	local btn=mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",AutoButtonColor=false})
	btn.Parent=track

	local function paint(anim)
		local on=state
		local bg=on and w.Theme.Accent or w.Theme.Elevated
		local sc=on and w.Theme.Accent or w.Theme.Stroke
		local kp=on and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)
		local kc=on and Color3.new(1,1,1) or w.Theme.TextMuted
		if anim then
			tw(track,0.15,{BackgroundColor3=bg})
			tw(knob,0.15,{Position=kp,BackgroundColor3=kc})
		else
			track.BackgroundColor3=bg knob.Position=kp knob.BackgroundColor3=kc
		end
		trackStr.Color=sc
	end
	paint(false)
	table.insert(w._onTheme,function() paint(false) end)

	local api={}
	function api:Set(v,sil) state=v and true or false paint(true) if not sil and opts.Callback then task.spawn(opts.Callback,state) end end
	function api:Get() return state end
	function api:_serialize() return state end
	function api:_deserialize(v) api:Set(v,true) end
	btn.MouseButton1Click:Connect(function() api:Set(not state) end)
	LumenUI._bindFlag(opts.Flag,api)
	return api
end

function Sec:AddSlider(opts)
	opts=opts or {}
	local w=self.Window
	local _,left,_,body=self:_buildRow(opts.Name or "Slider",opts.Description,true)
	local min,max=opts.Min or 0,opts.Max or 100
	local step=opts.Step or 1
	local value=math.clamp(opts.Default or min,min,max)
	local valLbl=w:_mk("TextLabel",{Size=UDim2.new(0,120,0,16),Position=UDim2.new(1,0,0,0),AnchorPoint=Vector2.new(1,0),BackgroundTransparency=1,TextSize=12,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=3},{TextColor3="Accent"},"Mono")
	valLbl.Parent=left
	local wrap=mk("Frame",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,LayoutOrder=1})
	wrap.Parent=body
	local track=w:_mk("Frame",{Size=UDim2.new(1,0,0,4),Position=UDim2.new(0,0,0.5,-2),BorderSizePixel=0},{BackgroundColor3="Elevated"},nil,{cor(2)})
	track.Parent=wrap
	local fill=w:_mk("Frame",{Size=UDim2.new(0,0,1,0),BorderSizePixel=0},{BackgroundColor3="Accent"},nil,{cor(2)})
	fill.Parent=track
	local knob=w:_mk("Frame",{Size=UDim2.new(0,14,0,14),Position=UDim2.new(0,-7,0.5,-7),BorderSizePixel=0},{BackgroundColor3="Accent"},nil,{cor(7)})
	mk("UIStroke",{Thickness=2,Color=Color3.new(1,1,1),ApplyStrokeMode=Enum.ApplyStrokeMode.Border}).Parent=knob
	knob.Parent=track

	local function fmt(v) return (step<1) and string.format("%.2f",v) or tostring(math.floor(v+0.5)) end
	local function apply()
		local t=(value-min)/math.max(1e-9,(max-min))
		fill.Size=UDim2.new(t,0,1,0)
		knob.Position=UDim2.new(t,-7,0.5,-7)
		valLbl.Text=fmt(value)..(opts.Suffix or "")
	end
	apply()

	local drag=false
	local function setFromX(x,sil)
		local rel=math.clamp((x-track.AbsolutePosition.X)/math.max(1,track.AbsoluteSize.X),0,1)
		local raw=min+(max-min)*rel
		local snap=math.floor(raw/step+0.5)*step
		value=math.clamp(snap,min,max)
		apply()
		if not sil and opts.Callback then task.spawn(opts.Callback,value) end
	end
	track.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
			drag=true setFromX(i.Position.X)
		end
	end)
	knob.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=true end
	end)
	table.insert(w._conns,UIS.InputChanged:Connect(function(i)
		if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then setFromX(i.Position.X) end
	end))
	table.insert(w._conns,UIS.InputEnded:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end
	end))

	local api={}
	function api:Set(v,sil) value=math.clamp(v,min,max) apply() if not sil and opts.Callback then task.spawn(opts.Callback,value) end end
	function api:Get() return value end
	function api:SetRange(a,b) min,max=a,b value=math.clamp(value,min,max) apply() end
	function api:_serialize() return value end
	function api:_deserialize(v) api:Set(v,true) end
	LumenUI._bindFlag(opts.Flag,api)
	return api
end

function Sec:AddKeybind(opts)
	opts=opts or {}
	local w=self.Window
	local _,_,right=self:_buildRow(opts.Name or "Keybind",opts.Description,false,150)
	local bound=opts.Default or Enum.KeyCode.Unknown
	local listening=false
	local group=w:_mk("Frame",{Size=UDim2.new(0,150,0,30),Position=UDim2.new(1,-150,0.5,-15),BorderSizePixel=0},{BackgroundColor3="Elevated"},nil,{cor(8)})
	w:_str("Stroke",1).Parent=group
	group.Parent=right
	local chip=w:_mk("Frame",{Size=UDim2.new(0,30,1,-8),Position=UDim2.new(0,3,0,4),BorderSizePixel=0},{BackgroundColor3="SurfaceAlt"},nil,{cor(5)})
	w:_str("Stroke",1).Parent=chip
	chip.Parent=group
	w:_mk("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,TextSize=9,Text="KEY"},{TextColor3="TextMuted"},"Mono").Parent=chip
	local keyLbl=w:_mk("TextLabel",{Size=UDim2.new(0,58,1,0),Position=UDim2.new(0,36,0,0),BackgroundTransparency=1,TextSize=12,Text=bound==Enum.KeyCode.Unknown and "None" or bound.Name,TextXAlignment=Enum.TextXAlignment.Left},{TextColor3="Text"},"Body")
	keyLbl.Parent=group
	local edit=w:_mk("TextButton",{Size=UDim2.new(0,42,1,-8),Position=UDim2.new(1,-45,0,4),BorderSizePixel=0,AutoButtonColor=false,TextSize=11,Text="Edit"},{BackgroundColor3="SurfaceAlt",TextColor3="Text"},"Title",{cor(5)})
	w:_str("Stroke",1).Parent=edit
	edit.Parent=group
	edit.MouseButton1Click:Connect(function()
		listening=true keyLbl.Text="…" keyLbl.TextColor3=w.Theme.Accent
	end)
	table.insert(w._conns,UIS.InputBegan:Connect(function(input,gp)
		if listening and input.UserInputType==Enum.UserInputType.Keyboard then
			bound=(input.KeyCode==Enum.KeyCode.Escape) and Enum.KeyCode.Unknown or input.KeyCode
			keyLbl.Text=bound==Enum.KeyCode.Unknown and "None" or bound.Name
			keyLbl.TextColor3=w.Theme.Text
			listening=false
			if opts.Callback then task.spawn(opts.Callback,bound) end
		elseif not gp and not listening and input.UserInputType==Enum.UserInputType.Keyboard and input.KeyCode==bound and bound~=Enum.KeyCode.Unknown then
			if opts.OnPress then task.spawn(opts.OnPress) end
		end
	end))
	local api={}
	function api:Set(k,sil) bound=k or Enum.KeyCode.Unknown keyLbl.Text=bound==Enum.KeyCode.Unknown and "None" or bound.Name if not sil and opts.Callback then task.spawn(opts.Callback,bound) end end
	function api:Get() return bound end
	function api:_serialize() return bound.Name end
	function api:_deserialize(v) api:Set(Enum.KeyCode[v] or Enum.KeyCode.Unknown,true) end
	LumenUI._bindFlag(opts.Flag,api)
	return api
end

function Sec:AddDropdown(opts)
	opts=opts or {}
	local w=self.Window
	local _,_,right=self:_buildRow(opts.Name or "Dropdown",opts.Description,false,200)
	local options=opts.Options or {}
	local selected=opts.Default or options[1] or ""
	local btn=w:_mk("TextButton",{Size=UDim2.new(0,200,0,30),Position=UDim2.new(1,-200,0.5,-15),AutoButtonColor=false,BorderSizePixel=0,TextSize=12,Text=selected,TextXAlignment=Enum.TextXAlignment.Left},{BackgroundColor3="Elevated",TextColor3="Text"},"Body",{cor(8),pad(0,32,0,12)})
	w:_str("Stroke",1).Parent=btn
	btn.Parent=right
	w:_mk("TextLabel",{Size=UDim2.new(0,16,1,0),Position=UDim2.new(1,-20,0,0),BackgroundTransparency=1,TextSize=14,Text="v",Rotation=0},{TextColor3="TextMuted"},"Body").Parent=btn

	local open,menu=false,nil
	local function close() if menu then menu:Destroy() end menu=nil open=false end
	btn.MouseButton1Click:Connect(function()
		if open then close() return end
		open=true
		menu=w:_mk("Frame",{Size=UDim2.new(1,0,0,#options*26+8),Position=UDim2.new(0,0,1,6),BorderSizePixel=0,ZIndex=10},{BackgroundColor3="Elevated"},nil,{cor(8),pad(4,4,4,4),lst(Enum.FillDirection.Vertical,0)})
		w:_str("Stroke",1).Parent=menu
		menu.Parent=btn
		for _,o in ipairs(options) do
			local it=w:_mk("TextButton",{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,AutoButtonColor=false,TextSize=12,Text=" "..o,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=11},{TextColor3=o==selected and "Accent" or "Text"},"Body",{cor(6)})
			it.Parent=menu
			it.MouseButton1Click:Connect(function()
				selected=o btn.Text=selected
				if opts.Callback then task.spawn(opts.Callback,selected) end
				close()
			end)
		end
	end)
	local api={}
	function api:Set(v,sil) selected=v btn.Text=v if not sil and opts.Callback then task.spawn(opts.Callback,v) end end
	function api:Get() return selected end
	function api:SetOptions(l) options=l or {} if not table.find(options,selected) then api:Set(options[1] or "",true) end end
	function api:_serialize() return selected end
	function api:_deserialize(v) api:Set(v,true) end
	LumenUI._bindFlag(opts.Flag,api)
	return api
end

function Sec:AddInput(opts)
	opts=opts or {}
	local w=self.Window
	local _,_,right=self:_buildRow(opts.Name or "Input",opts.Description,false,200)
	local box=w:_mk("Frame",{Size=UDim2.new(0,200,0,30),Position=UDim2.new(1,-200,0.5,-15),BorderSizePixel=0},{BackgroundColor3="Elevated"},nil,{cor(8),pad(0,12,0,12)})
	w:_str("Stroke",1).Parent=box
	box.Parent=right
	local tb=w:_mk("TextBox",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,TextSize=12,PlaceholderText=opts.Placeholder or "",Text=opts.Default or "",ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Left},{TextColor3="Text",PlaceholderColor3="TextMuted"},"Body")
	tb.Parent=box
	local api={}
	function api:Set(v,sil) tb.Text=v or "" if not sil and opts.Callback then task.spawn(opts.Callback,tb.Text) end end
	function api:Get() return tb.Text end
	function api:_serialize() return tb.Text end
	function api:_deserialize(v) api:Set(v,true) end
	tb.FocusLost:Connect(function(enter) if opts.Callback then task.spawn(opts.Callback,tb.Text,enter) end end)
	LumenUI._bindFlag(opts.Flag,api)
	return api
end

function Sec:AddColorPicker(opts)
	opts=opts or {}
	local w=self.Window
	local _,_,right=self:_buildRow(opts.Name or "Color",opts.Description,false,130)
	local color=opts.Default or Color3.fromRGB(245,168,54)
	local hex=w:_mk("TextLabel",{Size=UDim2.new(0,80,1,0),Position=UDim2.new(1,-44,0,0),AnchorPoint=Vector2.new(1,0),BackgroundTransparency=1,TextSize=11,Text=toHex(color),TextXAlignment=Enum.TextXAlignment.Right},{TextColor3="TextMuted"},"Mono")
	hex.Parent=right
	local swatch=mk("TextButton",{Size=UDim2.new(0,30,0,30),Position=UDim2.new(1,-30,0.5,-15),BackgroundColor3=color,AutoButtonColor=false,Text="",BorderSizePixel=0},{cor(8)})
	w:_str("Stroke",1).Parent=swatch
	swatch.Parent=right
	local open,panel=false,nil
	local function closeP() if panel then panel:Destroy() end panel=nil open=false end
	swatch.MouseButton1Click:Connect(function()
		if open then closeP() return end
		open=true
		panel=w:_mk("Frame",{Size=UDim2.new(0,200,0,124),Position=UDim2.new(1,-200,1,8),BorderSizePixel=0,ZIndex=20},{BackgroundColor3="Elevated"},nil,{cor(10),pad(10,10,10,10),lst(Enum.FillDirection.Vertical,4)})
		w:_str("Stroke",1).Parent=panel
		panel.Parent=swatch
		local h,s,v=Color3.toHSV(color)
		local function rowS(lbl,get,set)
			local r=mk("Frame",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1})
			r.Parent=panel
			w:_mk("TextLabel",{Size=UDim2.new(0,16,1,0),BackgroundTransparency=1,TextSize=11,Text=lbl,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=21},{TextColor3="TextMuted"},"Mono").Parent=r
			local tr=w:_mk("Frame",{Size=UDim2.new(1,-24,0,4),Position=UDim2.new(0,20,0.5,-2),BorderSizePixel=0,ZIndex=21},{BackgroundColor3="SurfaceAlt"},nil,{cor(2)})
			tr.Parent=r
			local fl=w:_mk("Frame",{Size=UDim2.new(get(),0,1,0),BorderSizePixel=0,ZIndex=22},{BackgroundColor3="Accent"},nil,{cor(2)})
			fl.Parent=tr
			tr.InputBegan:Connect(function(i)
				if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
					local function upd(x)
						local rel=math.clamp((x-tr.AbsolutePosition.X)/math.max(1,tr.AbsoluteSize.X),0,1)
						fl.Size=UDim2.new(rel,0,1,0) set(rel)
						color=Color3.fromHSV(h,s,v) swatch.BackgroundColor3=color hex.Text=toHex(color)
						if opts.Callback then task.spawn(opts.Callback,color) end
					end
					upd(i.Position.X)
					local m,e
					m=UIS.InputChanged:Connect(function(mi) if mi.UserInputType==Enum.UserInputType.MouseMovement or mi.UserInputType==Enum.UserInputType.Touch then upd(mi.Position.X) end end)
					e=UIS.InputEnded:Connect(function(ei) if ei.UserInputType==Enum.UserInputType.MouseButton1 or ei.UserInputType==Enum.UserInputType.Touch then m:Disconnect() e:Disconnect() end end)
				end
			end)
		end
		rowS("H",function() return h end,function(x) h=x end)
		rowS("S",function() return s end,function(x) s=x end)
		rowS("V",function() return v end,function(x) v=x end)
	end)
	local api={}
	function api:Set(c,sil) color=c swatch.BackgroundColor3=c hex.Text=toHex(c) if not sil and opts.Callback then task.spawn(opts.Callback,c) end end
	function api:Get() return color end
	function api:_serialize() return {color.R,color.G,color.B} end
	function api:_deserialize(v) if typeof(v)=="table" then api:Set(Color3.new(v[1],v[2],v[3]),true) end end
	LumenUI._bindFlag(opts.Flag,api)
	return api
end

function Sec:AddButton(opts)
	opts=opts or {}
	local w=self.Window
	local _,_,right=self:_buildRow(opts.Name or "Button",opts.Description,false,110)
	local ghost=opts.Style=="ghost"
	local btn=mk("TextButton",{Size=UDim2.new(0,100,0,30),Position=UDim2.new(1,-100,0.5,-15),AutoButtonColor=false,BorderSizePixel=0,TextSize=12,Text=opts.ButtonText or "Run"},{cor(8)})
	btn.Parent=right
	if ghost then
		btn.BackgroundTransparency=1
		regT(w,btn,"TextColor3","Text")
		w:_str("Stroke",1).Parent=btn
	else
		regT(w,btn,"BackgroundColor3","Accent")
		regT(w,btn,"TextColor3","AccentText")
	end
	regF(w,btn,"Title")
	btn.MouseButton1Click:Connect(function() if opts.Callback then task.spawn(opts.Callback) end end)
	return {SetText=function(_,t) btn.Text=t end}
end

function Sec:AddLabel(text)
	local w=self.Window
	local row=mk("Frame",{Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,LayoutOrder=#self.Rows+1},{pad(10,14,4,14)})
	row.Parent=self.Inner
	local lbl=w:_mk("TextLabel",{Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,TextSize=11,Text=string.upper(text),TextXAlignment=Enum.TextXAlignment.Left},{TextColor3="TextDim"},"Mono")
	lbl.Parent=row
	table.insert(self.Rows,row)
	return {Set=function(_,t) lbl.Text=string.upper(t) end,Get=function() return lbl.Text end}
end

function Sec:AddParagraph(title,body)
	local w=self.Window
	local row=mk("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=#self.Rows+1},{lst(Enum.FillDirection.Vertical,4),pad(14,14,14,14)})
	row.Parent=self.Inner
	if #self.Rows>0 then
		w:_mk("Frame",{Size=UDim2.new(1,0,0,1),BorderSizePixel=0,LayoutOrder=-1},{BackgroundColor3="StrokeSoft"}).Parent=row
	end
	local tlbl=w:_mk("TextLabel",{Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,TextSize=13,Text=title or "",TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=1},{TextColor3="Text"},"Title")
	tlbl.Parent=row
	local blbl=w:_mk("TextLabel",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,TextSize=12,Text=body or "",TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=2},{TextColor3="TextMuted"},"Body")
	blbl.Parent=row
	table.insert(self.Rows,row)
	return {Set=function(_,t,b) if t then tlbl.Text=t end if b then blbl.Text=b end end}
end

function LumenUI:Notify(opts)
	opts=opts or {}
	local win=self._windows[1]
	local th=(win and win.Theme) or Themes.Amber
	local fn=(win and win.Font) or Fonts.Gotham
	local parent=(win and win.Gui)
	if not parent then
		parent=mk("ScreenGui",{Name="LumenNotify",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=99999})
		parent.Parent=(gethui and gethui()) or PG or game:GetService("CoreGui")
	end
	local container=parent:FindFirstChild("__LumenNotify")
	if not container then
		container=mk("Frame",{Name="__LumenNotify",AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-28,1,-28),Size=UDim2.fromOffset(300,1),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1},{lst(Enum.FillDirection.Vertical,8)})
		container.Parent=parent
	end
	local card=mk("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=th.Surface,BorderSizePixel=0},{cor(10),strk(th.Stroke,1),pad(12,14,12,22),lst(Enum.FillDirection.Vertical,3)})
	card.Parent=container
	mk("Frame",{Size=UDim2.new(0,3,1,-20),Position=UDim2.new(0,8,0,10),BackgroundColor3=th.Accent,BorderSizePixel=0,ZIndex=2},{cor(2)}).Parent=card
	mk("TextLabel",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,Font=fn.Title,TextSize=13,Text=opts.Title or "Notice",TextColor3=th.Text,TextXAlignment=Enum.TextXAlignment.Left}).Parent=card
	if opts.Content then
		mk("TextLabel",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Font=fn.Body,TextSize=12,Text=opts.Content,TextColor3=th.TextMuted,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true}).Parent=card
	end
	task.delay(opts.Duration or 4,function()
		if card and card.Parent then
			tw(card,0.3,{BackgroundTransparency=1})
			for _,d in ipairs(card:GetDescendants()) do if d:IsA("TextLabel") then tw(d,0.3,{TextTransparency=1}) end end
			task.wait(0.35) card:Destroy()
		end
	end)
end

_cfgFactory=function(win)
	local cfg={Window=win}
	local folder=win.ConfigFolder
	if hasFS and not fs(isfolder,folder) then
		local acc=""
		for p in string.gmatch(folder,"[^/]+") do
			acc=(acc=="" and p) or (acc.."/"..p)
			if not fs(isfolder,acc) then fs(makefolder,acc) end
		end
	end
	local function path(n) return folder.."/"..n..".json" end
	function cfg:Save(n)
		n=n or "default"
		local d={}
		for f,o in pairs(LumenUI.Flags) do
			if o._serialize then local ok,v=pcall(o._serialize,o) if ok then d[f]=v end end
		end
		local j=HS:JSONEncode(d)
		if hasFS then fs(writefile,path(n),j) end
		return j
	end
	function cfg:Load(n)
		n=n or "default"
		local j
		if hasFS and fs(isfile,path(n)) then j=fs(readfile,path(n)) end
		if not j then return false end
		local ok,d=pcall(HS.JSONDecode,HS,j)
		if not ok or type(d)~="table" then return false end
		for f,v in pairs(d) do
			local o=LumenUI.Flags[f]
			if o and o._deserialize then pcall(o._deserialize,o,v) end
		end
		return true
	end
	function cfg:Delete(n) if hasFS and fs(isfile,path(n)) then fs(delfile,path(n)) end end
	function cfg:List()
		local out={}
		if hasFS then
			local files=fs(listfiles,folder) or {}
			for _,f in ipairs(files) do local nm=f:match("([^/\\]+)%.json$") if nm then table.insert(out,nm) end end
		end
		return out
	end
	function cfg:Autoload(n) cfg:Load(n or "default") end
	function cfg:BuildUI(tab)
		local sec=tab:AddSection("Config Manager")
		local name="default"
		sec:AddInput({Name="Config name",Description="Name to save / load / delete.",Default="default",Placeholder="name",Callback=function(v) name=v~="" and v or "default" end})
		sec:AddButton({Name="Save",Description="Persist current flag values.",ButtonText="Save",Callback=function() cfg:Save(name) LumenUI:Notify({Title="Saved",Content="Saved as '"..name.."'"}) end})
		sec:AddButton({Name="Load",ButtonText="Load",Style="ghost",Callback=function() local ok=cfg:Load(name) LumenUI:Notify({Title=ok and "Loaded" or "Not found",Content="'"..name.."'"}) end})
		sec:AddButton({Name="Delete",ButtonText="Delete",Style="ghost",Callback=function() cfg:Delete(name) LumenUI:Notify({Title="Deleted",Content="'"..name.."'"}) end})
		sec:AddLabel("Files written to "..folder.." (executor only)")
	end
	return cfg
end

return LumenUI
