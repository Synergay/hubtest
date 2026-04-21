local lib = {};
lib.__index = lib;
lib.flags = {};
lib.callbacks = {};
lib.components = {};
lib.windows = {};

local tws = game:GetService("TweenService");
local uis = game:GetService("UserInputService");
local rs = game:GetService("RunService");
local plyrs = game:GetService("Players");
local http = game:GetService("HttpService");
local lplr = plyrs.LocalPlayer;

local themes = {
    amber = {bg=Color3.fromRGB(38,38,42),surf=Color3.fromRGB(49,49,53),surf2=Color3.fromRGB(57,57,61),elev=Color3.fromRGB(67,67,71),text=Color3.fromRGB(242,242,243),mute=Color3.fromRGB(170,170,174),dim=Color3.fromRGB(117,117,121),stroke=Color3.fromRGB(69,69,73),strokes=Color3.fromRGB(59,59,63),acc=Color3.fromRGB(245,168,54),acct=Color3.fromRGB(26,18,6)};
    mint  = {bg=Color3.fromRGB(38,42,40),surf=Color3.fromRGB(49,53,51),surf2=Color3.fromRGB(57,61,59),elev=Color3.fromRGB(67,71,69),text=Color3.fromRGB(242,243,242),mute=Color3.fromRGB(170,174,172),dim=Color3.fromRGB(117,121,119),stroke=Color3.fromRGB(69,73,71),strokes=Color3.fromRGB(59,63,61),acc=Color3.fromRGB(90,220,180),acct=Color3.fromRGB(6,22,16)};
    iris  = {bg=Color3.fromRGB(40,38,44),surf=Color3.fromRGB(51,49,55),surf2=Color3.fromRGB(59,57,63),elev=Color3.fromRGB(69,67,73),text=Color3.fromRGB(243,242,244),mute=Color3.fromRGB(172,170,175),dim=Color3.fromRGB(119,117,122),stroke=Color3.fromRGB(71,69,75),strokes=Color3.fromRGB(61,59,65),acc=Color3.fromRGB(155,140,230),acct=Color3.fromRGB(14,10,36)};
    rose  = {bg=Color3.fromRGB(42,38,39),surf=Color3.fromRGB(53,49,50),surf2=Color3.fromRGB(61,57,58),elev=Color3.fromRGB(71,67,68),text=Color3.fromRGB(243,242,242),mute=Color3.fromRGB(174,170,170),dim=Color3.fromRGB(121,117,117),stroke=Color3.fromRGB(73,69,69),strokes=Color3.fromRGB(63,59,59),acc=Color3.fromRGB(230,110,130),acct=Color3.fromRGB(32,10,16)};
    mono  = {bg=Color3.fromRGB(12,12,12),surf=Color3.fromRGB(20,20,20),surf2=Color3.fromRGB(26,26,26),elev=Color3.fromRGB(32,32,32),text=Color3.fromRGB(240,240,240),mute=Color3.fromRGB(150,150,150),dim=Color3.fromRGB(100,100,100),stroke=Color3.fromRGB(42,42,42),strokes=Color3.fromRGB(28,28,28),acc=Color3.fromRGB(240,240,240),acct=Color3.fromRGB(12,12,12)};
};

local fontmap = {
    gotham = Enum.Font.Gotham;
    inter  = Enum.Font.GothamMedium;
    sans   = Enum.Font.SourceSans;
    mono   = Enum.Font.Code;
};

local function mk(class, props)
    local i = Instance.new(class);
    for k, v in next, props do
        if k ~= "Parent" then i[k] = v; end;
    end;
    if props.Parent then i.Parent = props.Parent; end;
    return i;
end;

local function stroke(parent, color, thick)
    return mk("UIStroke", {Parent=parent, Color=color or Color3.fromRGB(69,69,73), Thickness=thick or 1, ApplyStrokeMode=Enum.ApplyStrokeMode.Border});
end;

local function corner(parent, r)
    return mk("UICorner", {Parent=parent, CornerRadius=UDim.new(0, r or 8)});
end;

local function pad(parent, a, b, c, d)
    return mk("UIPadding", {Parent=parent, PaddingTop=UDim.new(0,a or 0), PaddingRight=UDim.new(0,b or 0), PaddingBottom=UDim.new(0,c or 0), PaddingLeft=UDim.new(0,d or 0)});
end;

local function tween(o, t, p)
    return tws:Create(o, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p):Play();
end;

local function drag(handle, target)
    local s, sp, ip;
    local drg, mvd;
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            s = true; sp = i.Position; ip = target.Position;
            local c; c = i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then s=false; c:Disconnect(); end;
            end);
        end;
    end);
    mvd = uis.InputChanged:Connect(function(i)
        if s and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - sp;
            target.Position = UDim2.new(ip.X.Scale, ip.X.Offset+d.X, ip.Y.Scale, ip.Y.Offset+d.Y);
        end;
    end);
    return mvd;
end;

local function getparent()
    if gethui then return gethui(); end;
    return game:GetService("CoreGui");
end;

local function rgbtohex(c)
    return string.format("#%02X%02X%02X", c.R*255, c.G*255, c.B*255);
end;

local function hsvbox(parent, onchange)
    local box = mk("Frame", {Parent=parent, Size=UDim2.new(1,0,0,140), BackgroundColor3=Color3.fromRGB(255,0,0), BorderSizePixel=0});
    corner(box, 6);
    local sat = mk("Frame", {Parent=box, Size=UDim2.new(1,0,1,0), BackgroundColor3=Color3.fromRGB(255,255,255), BorderSizePixel=0, ZIndex=2});
    corner(sat, 6);
    mk("UIGradient", {Parent=sat, Color=ColorSequence.new(Color3.new(1,1,1), Color3.new(1,1,1)), Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)})});
    local val = mk("Frame", {Parent=box, Size=UDim2.new(1,0,1,0), BackgroundColor3=Color3.fromRGB(0,0,0), BorderSizePixel=0, ZIndex=3});
    corner(val, 6);
    mk("UIGradient", {Parent=val, Rotation=90, Color=ColorSequence.new(Color3.new(0,0,0), Color3.new(0,0,0)), Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0)})});
    return box;
end;

function lib:new(opts)
    opts = opts or {};
    local self = setmetatable({}, lib);
    self.name = opts.name or "Lumen";
    self.folder = opts.folder or "Lumen";
    self.theme = themes[opts.theme or "amber"];
    self.themekey = opts.theme or "amber";
    self.font = fontmap[opts.font or "gotham"];
    self.fontkey = opts.font or "gotham";
    self.togglekey = opts.togglekey or Enum.KeyCode.RightShift;
    self.tabs = {};
    self.activetab = nil;
    self.conns = {};
    self.elems = {};

    local old = getparent():FindFirstChild("lumen_"..self.name);
    if old then old:Destroy(); end;

    self.gui = mk("ScreenGui", {Parent=getparent(), Name="lumen_"..self.name, ZIndexBehavior=Enum.ZIndexBehavior.Sibling, ResetOnSpawn=false});
    pcall(function() self.gui.IgnoreGuiInset = true; end);

    self.root = mk("Frame", {Parent=self.gui, Size=UDim2.new(0,580,0,420), Position=UDim2.new(0.5,-290,0.5,-210), BackgroundColor3=self.theme.bg, BorderSizePixel=0});
    corner(self.root, 10);
    self.rootstroke = stroke(self.root, self.theme.stroke, 1);

    self.titlebar = mk("Frame", {Parent=self.root, Size=UDim2.new(1,0,0,36), BackgroundColor3=self.theme.surf, BorderSizePixel=0});
    corner(self.titlebar, 10);
    mk("Frame", {Parent=self.titlebar, Size=UDim2.new(1,0,0,18), Position=UDim2.new(0,0,1,-18), BackgroundColor3=self.theme.surf, BorderSizePixel=0, ZIndex=1});
    self.tbstroke = mk("Frame", {Parent=self.titlebar, Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1), BackgroundColor3=self.theme.stroke, BorderSizePixel=0});

    self.title = mk("TextLabel", {Parent=self.titlebar, Size=UDim2.new(0,200,1,0), Position=UDim2.new(0,18,0,0), BackgroundTransparency=1, Text=string.upper(self.name), TextColor3=self.theme.text, Font=self.font, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left});

    local wc = mk("Frame", {Parent=self.titlebar, Size=UDim2.new(0,60,1,0), Position=UDim2.new(1,-78,0,0), BackgroundTransparency=1});
    mk("UIListLayout", {Parent=wc, FillDirection=Enum.FillDirection.Horizontal, HorizontalAlignment=Enum.HorizontalAlignment.Right, Padding=UDim.new(0,10), SortOrder=Enum.SortOrder.LayoutOrder, VerticalAlignment=Enum.VerticalAlignment.Center});
    for idx, sym in next, {"—","◻","×"} do
        local b = mk("TextButton", {Parent=wc, LayoutOrder=idx, Size=UDim2.new(0,14,0,14), BackgroundTransparency=1, Text=sym, TextColor3=self.theme.mute, Font=self.font, TextSize=13, AutoButtonColor=false});
        if sym == "×" then
            b.MouseButton1Click:Connect(function() self:toggle(); end);
        end;
    end;

    self.sidebar = mk("Frame", {Parent=self.root, Size=UDim2.new(0,150,1,-36), Position=UDim2.new(0,0,0,36), BackgroundColor3=self.theme.surf, BorderSizePixel=0});
    mk("Frame", {Parent=self.sidebar, Size=UDim2.new(0,1,1,0), Position=UDim2.new(1,-1,0,0), BackgroundColor3=self.theme.stroke, BorderSizePixel=0});

    local sbbrand = mk("Frame", {Parent=self.sidebar, Size=UDim2.new(1,0,0,38), BackgroundTransparency=1});
    pad(sbbrand, 0, 12, 0, 14);
    local mark = mk("Frame", {Parent=sbbrand, Size=UDim2.new(0,16,0,16), Position=UDim2.new(0,0,0.5,-8), BackgroundColor3=self.theme.acc, BorderSizePixel=0});
    corner(mark, 4);
    mk("TextLabel", {Parent=sbbrand, Size=UDim2.new(1,-24),Position=UDim2.new(0,22,0,0), BackgroundTransparency=1, Text=self.name, TextColor3=self.theme.text, Font=self.font, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left});

    self.navlist = mk("ScrollingFrame", {Parent=self.sidebar, Size=UDim2.new(1,0,1,-76), Position=UDim2.new(0,0,0,38), BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=2, ScrollBarImageColor3=self.theme.stroke, CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y});
    pad(self.navlist, 6, 10, 6, 10);
    mk("UIListLayout", {Parent=self.navlist, Padding=UDim.new(0,2), SortOrder=Enum.SortOrder.LayoutOrder});

    local sbfoot = mk("Frame", {Parent=self.sidebar, Size=UDim2.new(1,0,0,34), Position=UDim2.new(0,0,1,-34), BackgroundTransparency=1});
    mk("Frame", {Parent=sbfoot, Size=UDim2.new(1,-28,0,1), Position=UDim2.new(0,14,0,0), BackgroundColor3=self.theme.strokes, BorderSizePixel=0});
    self.footleft = mk("TextLabel", {Parent=sbfoot, Size=UDim2.new(0.5,-14,1,0), Position=UDim2.new(0,14,0,0), BackgroundTransparency=1, Text="RShift · toggle", TextColor3=self.theme.dim, Font=self.font, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left});
    self.footright = mk("TextLabel", {Parent=sbfoot, Size=UDim2.new(0.5,-14,1,0), Position=UDim2.new(0.5,0,0,0), BackgroundTransparency=1, Text="● online", TextColor3=self.theme.dim, Font=self.font, TextSize=10, TextXAlignment=Enum.TextXAlignment.Right});

    self.content = mk("ScrollingFrame", {Parent=self.root, Size=UDim2.new(1,-150,1,-36), Position=UDim2.new(0,150,0,36), BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=4, ScrollBarImageColor3=self.theme.stroke, CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y});
    pad(self.content, 16, 22, 24, 22);
    mk("UIListLayout", {Parent=self.content, Padding=UDim.new(0,12), SortOrder=Enum.SortOrder.LayoutOrder});

    self.toaststack = mk("Frame", {Parent=self.gui, Size=UDim2.new(0,300,1,-56), Position=UDim2.new(1,-320,0,28), BackgroundTransparency=1});
    mk("UIListLayout", {Parent=self.toaststack, VerticalAlignment=Enum.VerticalAlignment.Bottom, HorizontalAlignment=Enum.HorizontalAlignment.Right, Padding=UDim.new(0,8), SortOrder=Enum.SortOrder.LayoutOrder});

    table.insert(self.conns, drag(self.titlebar, self.root));

    table.insert(self.conns, uis.InputBegan:Connect(function(i, gp)
        if gp then return; end;
        if i.KeyCode == self.togglekey then self:toggle(); end;
    end));

    self.config = self:buildconfig();

    table.insert(lib.windows, self);
    return self;
end;

function lib:toggle()
    self.root.Visible = not self.root.Visible;
end;

function lib:applytheme(key)
    if not themes[key] then return; end;
    self.theme = themes[key];
    self.themekey = key;
    local t = self.theme;
    self.root.BackgroundColor3 = t.bg;
    self.rootstroke.Color = t.stroke;
    self.titlebar.BackgroundColor3 = t.surf;
    self.tbstroke.BackgroundColor3 = t.stroke;
    self.title.TextColor3 = t.text;
    self.sidebar.BackgroundColor3 = t.surf;
    self.navlist.ScrollBarImageColor3 = t.stroke;
    self.content.ScrollBarImageColor3 = t.stroke;
    for _, e in next, self.elems do
        if e.theme then e.theme(t); end;
    end;
end;

function lib:applyfont(key)
    if not fontmap[key] then return; end;
    self.font = fontmap[key];
    self.fontkey = key;
    for _, d in next, self.gui:GetDescendants() do
        if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
            d.Font = self.font;
        end;
    end;
end;

function lib:addtab(name, icon)
    local tab = {name=name, sections={}, window=self};

    tab.btn = mk("TextButton", {Parent=self.navlist, Size=UDim2.new(1,0,0,32), BackgroundColor3=self.theme.elev, BackgroundTransparency=1, Text="", AutoButtonColor=false});
    corner(tab.btn, 6);
    tab.btnstroke = stroke(tab.btn, self.theme.stroke, 1);
    tab.btnstroke.Transparency = 1;
    pad(tab.btn, 0, 10, 0, 10);

    tab.label = mk("TextLabel", {Parent=tab.btn, Size=UDim2.new(1,-4,1,0), Position=UDim2.new(0,4,0,0), BackgroundTransparency=1, Text=name, TextColor3=self.theme.mute, Font=self.font, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left});

    tab.page = mk("Frame", {Parent=self.content, Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, Visible=false});
    mk("UIListLayout", {Parent=tab.page, Padding=UDim.new(0,12), SortOrder=Enum.SortOrder.LayoutOrder});

    tab.btn.MouseButton1Click:Connect(function()
        self:selecttab(tab);
    end);

    tab.btn.MouseEnter:Connect(function()
        if self.activetab ~= tab then tween(tab.btn, 0.1, {BackgroundTransparency=0.5}); tween(tab.label, 0.1, {TextColor3=self.theme.text}); end;
    end);
    tab.btn.MouseLeave:Connect(function()
        if self.activetab ~= tab then tween(tab.btn, 0.1, {BackgroundTransparency=1}); tween(tab.label, 0.1, {TextColor3=self.theme.mute}); end;
    end);

    function tab:addsection(title)
        return self.window:_addsection(self, title);
    end;

    table.insert(self.elems, {theme=function(t)
        tab.btnstroke.Color = t.stroke;
        if self.activetab == tab then
            tab.btn.BackgroundColor3 = t.elev;
            tab.label.TextColor3 = t.text;
        else
            tab.label.TextColor3 = t.mute;
        end;
    end});

    table.insert(self.tabs, tab);
    if not self.activetab then self:selecttab(tab); end;
    return tab;
end;

function lib:selecttab(tab)
    if self.activetab == tab then return; end;
    for _, t in next, self.tabs do
        t.page.Visible = false;
        tween(t.btn, 0.12, {BackgroundTransparency=1});
        tween(t.label, 0.12, {TextColor3=self.theme.mute});
        t.btnstroke.Transparency = 1;
    end;
    tab.page.Visible = true;
    tab.btn.BackgroundTransparency = 0;
    tween(tab.btn, 0.12, {BackgroundColor3=self.theme.elev});
    tween(tab.label, 0.12, {TextColor3=self.theme.text});
    tab.btnstroke.Transparency = 0;
    self.activetab = tab;
end;

function lib:_addsection(tab, title)
    local sec = {title=title, window=self, tab=tab, rows={}};

    sec.frame = mk("Frame", {Parent=tab.page, Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, BackgroundColor3=self.theme.surf, BorderSizePixel=0});
    corner(sec.frame, 10);
    sec.fstroke = stroke(sec.frame, self.theme.strokes, 1);
    pad(sec.frame, 14, 18, 16, 18);

    sec.container = mk("Frame", {Parent=sec.frame, Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1});
    mk("UIListLayout", {Parent=sec.container, Padding=UDim.new(0,0), SortOrder=Enum.SortOrder.LayoutOrder});

    sec.title = mk("TextLabel", {Parent=sec.container, Size=UDim2.new(1,0,0,22), BackgroundTransparency=1, Text=title, TextColor3=self.theme.text, Font=self.font, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=0});

    table.insert(self.elems, {theme=function(t)
        sec.frame.BackgroundColor3 = t.surf;
        sec.fstroke.Color = t.strokes;
        sec.title.TextColor3 = t.text;
    end});

    function sec:addtoggle(o) return self.window:_toggle(self, o); end;
    function sec:addslider(o) return self.window:_slider(self, o); end;
    function sec:addkeybind(o) return self.window:_keybind(self, o); end;
    function sec:adddropdown(o) return self.window:_dropdown(self, o); end;
    function sec:addinput(o) return self.window:_input(self, o); end;
    function sec:addcolorpicker(o) return self.window:_color(self, o); end;
    function sec:addbutton(o) return self.window:_button(self, o); end;
    function sec:addlabel(t) return self.window:_label(self, t); end;
    function sec:addparagraph(title, body) return self.window:_paragraph(self, title, body); end;
    function sec:addcustom(name, opts) return self.window:_custom(self, name, opts); end;

    return sec;
end;

local function newrow(sec, t, first)
    local r = mk("Frame", {Parent=sec.container, Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, LayoutOrder=#sec.container:GetChildren()});
    pad(r, first and 8 or 12, 0, 12, 0);
    local sep;
    if not first then
        sep = mk("Frame", {Parent=r, Size=UDim2.new(1,0,0,1), BackgroundColor3=t.strokes, BorderSizePixel=0});
    end;
    local inner = mk("Frame", {Parent=r, Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,0,first and 0 or 1), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1});
    return r, inner, sep;
end;

local function rowhead(parent, t, name, desc, font)
    local left = mk("Frame", {Parent=parent, Size=UDim2.new(0.6,0,1,0), BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y});
    local nm = mk("TextLabel", {Parent=left, Size=UDim2.new(1,0,0,16), BackgroundTransparency=1, Text=name, TextColor3=t.text, Font=font, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left});
    local ds;
    if desc then
        ds = mk("TextLabel", {Parent=left, Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,0,18), BackgroundTransparency=1, Text=desc, TextColor3=t.mute, Font=font, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true});
    end;
    return left, nm, ds;
end;

function lib:_toggle(sec, o)
    o = o or {};
    local t = self.theme;
    local first = #sec.container:GetChildren() <= 1;
    local r, inner = newrow(sec, t, first);
    mk("Frame", {Parent=inner, Size=UDim2.new(1,0,0,44), BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.None});
    local row = mk("Frame", {Parent=inner, Size=UDim2.new(1,0,0,44), BackgroundTransparency=1});
    local left, nm, ds = rowhead(row, t, o.text or "Toggle", o.desc, self.font);

    local sw = mk("TextButton", {Parent=row, Size=UDim2.new(0,40,0,22), Position=UDim2.new(1,-40,0.5,-11), BackgroundColor3=t.elev, AutoButtonColor=false, Text=""});
    corner(sw, 11);
    local swstroke = stroke(sw, t.stroke, 1);
    local knob = mk("Frame", {Parent=sw, Size=UDim2.new(0,16,0,16), Position=UDim2.new(0,2,0.5,-8), BackgroundColor3=t.mute, BorderSizePixel=0});
    corner(knob, 8);

    local state = o.def == true;
    local flag = o.flag;
    local cb = o.cb or function() end;

    local function set(v)
        state = v;
        if flag then lib.flags[flag] = v; end;
        if v then
            tween(sw, 0.15, {BackgroundColor3=t.acc});
            swstroke.Color = t.acc;
            tween(knob, 0.15, {Position=UDim2.new(0,20,0.5,-8), BackgroundColor3=Color3.fromRGB(255,255,255)});
        else
            tween(sw, 0.15, {BackgroundColor3=t.elev});
            swstroke.Color = t.stroke;
            tween(knob, 0.15, {Position=UDim2.new(0,2,0.5,-8), BackgroundColor3=t.mute});
        end;
        cb(v);
    end;

    sw.MouseButton1Click:Connect(function() set(not state); end);
    set(state);
    if flag then lib.callbacks[flag] = set; end;

    table.insert(self.elems, {theme=function(tt)
        nm.TextColor3 = tt.text;
        if ds then ds.TextColor3 = tt.mute; end;
        if state then sw.BackgroundColor3 = tt.acc; swstroke.Color = tt.acc; else sw.BackgroundColor3 = tt.elev; swstroke.Color = tt.stroke; knob.BackgroundColor3 = tt.mute; end;
    end});

    return {set=set, get=function() return state; end};
end;

function lib:_slider(sec, o)
    o = o or {};
    local t = self.theme;
    local first = #sec.container:GetChildren() <= 1;
    local r, inner = newrow(sec, t, first);
    local row = mk("Frame", {Parent=inner, Size=UDim2.new(1,0,0,60), BackgroundTransparency=1});
    local top = mk("Frame", {Parent=row, Size=UDim2.new(1,0,0,34), BackgroundTransparency=1});
    local left, nm, ds = rowhead(top, t, o.text or "Slider", o.desc, self.font);

    local min, max, def = o.min or 0, o.max or 100, o.def or o.min or 0;
    local dec = o.dec or 0;
    local suffix = o.suffix or "";

    local val = mk("TextLabel", {Parent=top, Size=UDim2.new(0.4,0,1,0), Position=UDim2.new(0.6,0,0,0), BackgroundTransparency=1, Text=string.format("%."..dec.."f", def)..suffix, TextColor3=t.acc, Font=Enum.Font.Code, TextSize=12, TextXAlignment=Enum.TextXAlignment.Right});

    local track = mk("Frame", {Parent=row, Size=UDim2.new(1,0,0,4), Position=UDim2.new(0,0,0,44), BackgroundColor3=t.elev, BorderSizePixel=0});
    corner(track, 2);
    local fill = mk("Frame", {Parent=track, Size=UDim2.new(0,0,1,0), BackgroundColor3=t.acc, BorderSizePixel=0});
    corner(fill, 2);
    local knob = mk("Frame", {Parent=track, Size=UDim2.new(0,14,0,14), Position=UDim2.new(0,-7,0.5,-7), BackgroundColor3=t.acc, BorderSizePixel=0});
    corner(knob, 7);
    stroke(knob, Color3.fromRGB(255,255,255), 2);

    local flag = o.flag;
    local cb = o.cb or function() end;
    local state = def;
    local dragging = false;

    local function set(v, silent)
        v = math.clamp(v, min, max);
        local r2 = dec == 0 and math.floor(v + 0.5) or tonumber(string.format("%."..dec.."f", v));
        state = r2;
        local t2 = (r2 - min) / (max - min);
        fill.Size = UDim2.new(t2, 0, 1, 0);
        knob.Position = UDim2.new(t2, -7, 0.5, -7);
        val.Text = string.format("%."..dec.."f", r2)..suffix;
        if flag then lib.flags[flag] = r2; end;
        if not silent then cb(r2); end;
    end;

    local moveconn;
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true;
            local abs = track.AbsolutePosition.X;
            local w = track.AbsoluteSize.X;
            set(min + (max - min) * math.clamp((i.Position.X - abs) / w, 0, 1));
        end;
    end);
    track.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false; end;
    end);
    moveconn = uis.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local abs = track.AbsolutePosition.X;
            local w = track.AbsoluteSize.X;
            set(min + (max - min) * math.clamp((i.Position.X - abs) / w, 0, 1));
        end;
    end);
    table.insert(self.conns, moveconn);

    set(def, true);
    if flag then lib.flags[flag] = def; lib.callbacks[flag] = set; end;

    table.insert(self.elems, {theme=function(tt)
        nm.TextColor3 = tt.text;
        if ds then ds.TextColor3 = tt.mute; end;
        val.TextColor3 = tt.acc;
        track.BackgroundColor3 = tt.elev;
        fill.BackgroundColor3 = tt.acc;
        knob.BackgroundColor3 = tt.acc;
    end});

    return {set=set, get=function() return state; end};
end;

function lib:_keybind(sec, o)
    o = o or {};
    local t = self.theme;
    local first = #sec.container:GetChildren() <= 1;
    local r, inner = newrow(sec, t, first);
    local row = mk("Frame", {Parent=inner, Size=UDim2.new(1,0,0,44), BackgroundTransparency=1});
    local left, nm, ds = rowhead(row, t, o.text or "Keybind", o.desc, self.font);

    local holder = mk("Frame", {Parent=row, Size=UDim2.new(0,140,0,30), Position=UDim2.new(1,-140,0.5,-15), BackgroundColor3=t.elev, BorderSizePixel=0});
    corner(holder, 8);
    local hstroke = stroke(holder, t.stroke, 1);
    pad(holder, 0, 3, 0, 3);

    local kc = mk("TextLabel", {Parent=holder, Size=UDim2.new(0,30,1,-6), Position=UDim2.new(0,0,0,3), BackgroundColor3=t.surf2, BorderSizePixel=0, Text="KEY", TextColor3=t.mute, Font=Enum.Font.Code, TextSize=9});
    corner(kc, 5);
    stroke(kc, t.stroke, 1);

    local key = o.def or Enum.KeyCode.V;
    local keyname = typeof(key) == "EnumItem" and key.Name or tostring(key);

    local valt = mk("TextLabel", {Parent=holder, Size=UDim2.new(0,60,1,0), Position=UDim2.new(0,36,0,0), BackgroundTransparency=1, Text=keyname, TextColor3=t.text, Font=self.font, TextSize=11});

    local edit = mk("TextButton", {Parent=holder, Size=UDim2.new(0,44,1,-6), Position=UDim2.new(1,-44,0,3), BackgroundColor3=t.surf2, BorderSizePixel=0, Text="Edit", TextColor3=t.text, Font=self.font, TextSize=10, AutoButtonColor=false});
    corner(edit, 5);
    stroke(edit, t.stroke, 1);

    local flag = o.flag;
    local cb = o.cb or function() end;
    local listening = false;
    local listenconn;

    local function set(k)
        key = k;
        keyname = typeof(k) == "EnumItem" and k.Name or tostring(k);
        valt.Text = keyname;
        if flag then lib.flags[flag] = keyname; end;
        cb(k);
    end;

    edit.MouseButton1Click:Connect(function()
        if listening then return; end;
        listening = true;
        valt.Text = "...";
        listenconn = uis.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Keyboard then
                set(i.KeyCode);
                listening = false;
                listenconn:Disconnect();
            end;
        end);
    end);

    if flag then lib.flags[flag] = keyname; lib.callbacks[flag] = set; end;

    if o.mode then
        uis.InputBegan:Connect(function(i, gp)
            if gp or listening then return; end;
            if i.KeyCode == key then cb(key); end;
        end);
    end;

    table.insert(self.elems, {theme=function(tt)
        nm.TextColor3 = tt.text;
        if ds then ds.TextColor3 = tt.mute; end;
        holder.BackgroundColor3 = tt.elev;
        hstroke.Color = tt.stroke;
        kc.BackgroundColor3 = tt.surf2; kc.TextColor3 = tt.mute;
        valt.TextColor3 = tt.text;
        edit.BackgroundColor3 = tt.surf2; edit.TextColor3 = tt.text;
    end});

    return {set=set, get=function() return key; end};
end;

function lib:_dropdown(sec, o)
    o = o or {};
    local t = self.theme;
    local first = #sec.container:GetChildren() <= 1;
    local r, inner = newrow(sec, t, first);
    local row = mk("Frame", {Parent=inner, Size=UDim2.new(1,0,0,44), BackgroundTransparency=1});
    local left, nm, ds = rowhead(row, t, o.text or "Dropdown", o.desc, self.font);

    local items = o.items or {};
    local selected = o.def or items[1] or "";
    local flag = o.flag;
    local cb = o.cb or function() end;

    local dd = mk("TextButton", {Parent=row, Size=UDim2.new(0,180,0,30), Position=UDim2.new(1,-180,0.5,-15), BackgroundColor3=t.elev, BorderSizePixel=0, Text="", AutoButtonColor=false});
    corner(dd, 8);
    local ddstroke = stroke(dd, t.stroke, 1);

    local selt = mk("TextLabel", {Parent=dd, Size=UDim2.new(1,-28,1,0), Position=UDim2.new(0,12,0,0), BackgroundTransparency=1, Text=tostring(selected), TextColor3=t.text, Font=self.font, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left});
    local chev = mk("TextLabel", {Parent=dd, Size=UDim2.new(0,16,1,0), Position=UDim2.new(1,-18,0,0), BackgroundTransparency=1, Text="▾", TextColor3=t.mute, Font=self.font, TextSize=11});

    local open = false;
    local list = mk("Frame", {Parent=row, Size=UDim2.new(0,180,0,0), Position=UDim2.new(1,-180,0,46), BackgroundColor3=t.elev, BorderSizePixel=0, Visible=false, ZIndex=10, ClipsDescendants=true});
    corner(list, 8);
    local liststroke = stroke(list, t.stroke, 1);
    local ll = mk("UIListLayout", {Parent=list, SortOrder=Enum.SortOrder.LayoutOrder});
    pad(list, 4, 4, 4, 4);

    local function set(v)
        selected = v;
        selt.Text = tostring(v);
        if flag then lib.flags[flag] = v; end;
        cb(v);
    end;

    local function rebuild()
        for _, c in next, list:GetChildren() do
            if c:IsA("TextButton") then c:Destroy(); end;
        end;
        for _, it in next, items do
            local b = mk("TextButton", {Parent=list, Size=UDim2.new(1,0,0,26), BackgroundColor3=t.elev, BackgroundTransparency=1, Text="  "..tostring(it), TextColor3=t.mute, Font=self.font, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=11, AutoButtonColor=false});
            corner(b, 5);
            b.MouseEnter:Connect(function() tween(b, 0.08, {BackgroundTransparency=0.5, TextColor3=t.text}); end);
            b.MouseLeave:Connect(function() tween(b, 0.08, {BackgroundTransparency=1, TextColor3=t.mute}); end);
            b.MouseButton1Click:Connect(function()
                set(it);
                open = false;
                list.Visible = false;
                tween(chev, 0.1, {Rotation=0});
            end);
        end;
        list.Size = UDim2.new(0, 180, 0, math.min(#items, 6) * 26 + 8);
    end;

    dd.MouseButton1Click:Connect(function()
        open = not open;
        list.Visible = open;
        tween(chev, 0.1, {Rotation=open and 180 or 0});
    end);

    rebuild();
    set(selected);
    if flag then lib.callbacks[flag] = set; end;

    table.insert(self.elems, {theme=function(tt)
        nm.TextColor3 = tt.text;
        if ds then ds.TextColor3 = tt.mute; end;
        dd.BackgroundColor3 = tt.elev; ddstroke.Color = tt.stroke;
        selt.TextColor3 = tt.text; chev.TextColor3 = tt.mute;
        list.BackgroundColor3 = tt.elev; liststroke.Color = tt.stroke;
    end});

    local api = {};
    function api.set(v) set(v); end;
    function api.get() return selected; end;
    function api.setitems(n) items = n; rebuild(); end;
    return api;
end;

function lib:_input(sec, o)
    o = o or {};
    local t = self.theme;
    local first = #sec.container:GetChildren() <= 1;
    local r, inner = newrow(sec, t, first);
    local row = mk("Frame", {Parent=inner, Size=UDim2.new(1,0,0,44), BackgroundTransparency=1});
    local left, nm, ds = rowhead(row, t, o.text or "Input", o.desc, self.font);

    local holder = mk("Frame", {Parent=row, Size=UDim2.new(0,200,0,30), Position=UDim2.new(1,-200,0.5,-15), BackgroundColor3=t.elev, BorderSizePixel=0});
    corner(holder, 8);
    local hstroke = stroke(holder, t.stroke, 1);

    local box = mk("TextBox", {Parent=holder, Size=UDim2.new(1,-24,1,0), Position=UDim2.new(0,12,0,0), BackgroundTransparency=1, Text=o.def or "", PlaceholderText=o.placeholder or "", PlaceholderColor3=t.dim, TextColor3=t.text, Font=self.font, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, ClearTextOnFocus=false});

    local flag = o.flag;
    local cb = o.cb or function() end;
    local state = o.def or "";

    local function set(v)
        state = v;
        box.Text = v;
        if flag then lib.flags[flag] = v; end;
        cb(v);
    end;

    box.FocusLost:Connect(function(enter)
        state = box.Text;
        if flag then lib.flags[flag] = state; end;
        cb(state, enter);
    end);
    box.Focused:Connect(function() tween(hstroke, 0.1, {Color=t.acc}); end);
    box.FocusLost:Connect(function() tween(hstroke, 0.1, {Color=t.stroke}); end);

    if flag then lib.flags[flag] = state; lib.callbacks[flag] = set; end;

    table.insert(self.elems, {theme=function(tt)
        nm.TextColor3 = tt.text;
        if ds then ds.TextColor3 = tt.mute; end;
        holder.BackgroundColor3 = tt.elev; hstroke.Color = tt.stroke;
        box.TextColor3 = tt.text; box.PlaceholderColor3 = tt.dim;
    end});

    return {set=set, get=function() return state; end};
end;

function lib:_color(sec, o)
    o = o or {};
    local t = self.theme;
    local first = #sec.container:GetChildren() <= 1;
    local r, inner = newrow(sec, t, first);
    local row = mk("Frame", {Parent=inner, Size=UDim2.new(1,0,0,44), BackgroundTransparency=1});
    local left, nm, ds = rowhead(row, t, o.text or "Color", o.desc, self.font);

    local state = o.def or t.acc;
    local flag = o.flag;
    local cb = o.cb or function() end;

    local group = mk("Frame", {Parent=row, Size=UDim2.new(0,120,0,30), Position=UDim2.new(1,-120,0.5,-15), BackgroundTransparency=1});
    local hex = mk("TextLabel", {Parent=group, Size=UDim2.new(0,80,1,0), Position=UDim2.new(0,0,0,0), BackgroundTransparency=1, Text=rgbtohex(state), TextColor3=t.mute, Font=Enum.Font.Code, TextSize=11, TextXAlignment=Enum.TextXAlignment.Right});
    local sw = mk("TextButton", {Parent=group, Size=UDim2.new(0,30,0,30), Position=UDim2.new(1,-30,0,0), BackgroundColor3=state, BorderSizePixel=0, Text="", AutoButtonColor=false});
    corner(sw, 8);
    local swstroke = stroke(sw, t.stroke, 1);

    local picker = mk("Frame", {Parent=row, Size=UDim2.new(0,200,0,220), Position=UDim2.new(1,-200,0,46), BackgroundColor3=t.elev, BorderSizePixel=0, Visible=false, ZIndex=10});
    corner(picker, 8);
    stroke(picker, t.stroke, 1);
    pad(picker, 10, 10, 10, 10);

    local h, s, v = Color3.toHSV(state);

    local svbox = mk("TextButton", {Parent=picker, Size=UDim2.new(1,0,0,140), BackgroundColor3=Color3.fromHSV(h,1,1), BorderSizePixel=0, Text="", AutoButtonColor=false, ZIndex=11});
    corner(svbox, 6);
    local wg = mk("Frame", {Parent=svbox, Size=UDim2.new(1,0,1,0), BackgroundColor3=Color3.fromRGB(255,255,255), BorderSizePixel=0, ZIndex=12});
    corner(wg, 6);
    mk("UIGradient", {Parent=wg, Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)})});
    local bg = mk("Frame", {Parent=svbox, Size=UDim2.new(1,0,1,0), BackgroundColor3=Color3.fromRGB(0,0,0), BorderSizePixel=0, ZIndex=13});
    corner(bg, 6);
    mk("UIGradient", {Parent=bg, Rotation=90, Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0)})});
    local svknob = mk("Frame", {Parent=svbox, Size=UDim2.new(0,8,0,8), BackgroundColor3=Color3.fromRGB(255,255,255), BorderSizePixel=0, ZIndex=14});
    corner(svknob, 4);
    stroke(svknob, Color3.fromRGB(0,0,0), 1);

    local hueb = mk("Frame", {Parent=picker, Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,0,150), BackgroundColor3=Color3.fromRGB(255,255,255), BorderSizePixel=0, ZIndex=11});
    corner(hueb, 4);
    local huegrad = mk("UIGradient", {Parent=hueb, Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0));
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0));
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0));
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,255));
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255));
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255));
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0));
    })});
    local hueknob = mk("Frame", {Parent=hueb, Size=UDim2.new(0,3,1,4), Position=UDim2.new(h,-1,0,-2), BackgroundColor3=Color3.fromRGB(255,255,255), BorderSizePixel=0, ZIndex=12});
    stroke(hueknob, Color3.fromRGB(0,0,0), 1);

    local hexinput = mk("TextBox", {Parent=picker, Size=UDim2.new(1,0,0,26), Position=UDim2.new(0,0,0,172), BackgroundColor3=t.surf2, BorderSizePixel=0, Text=rgbtohex(state), TextColor3=t.text, Font=Enum.Font.Code, TextSize=11, ClearTextOnFocus=false, ZIndex=11});
    corner(hexinput, 6);
    stroke(hexinput, t.stroke, 1);

    local function refresh()
        local c = Color3.fromHSV(h, s, v);
        state = c;
        svbox.BackgroundColor3 = Color3.fromHSV(h, 1, 1);
        svknob.Position = UDim2.new(s, -4, 1-v, -4);
        hueknob.Position = UDim2.new(h, -1, 0, -2);
        sw.BackgroundColor3 = c;
        hex.Text = rgbtohex(c);
        hexinput.Text = rgbtohex(c);
        if flag then lib.flags[flag] = c; end;
        cb(c);
    end;

    local svd, hd;
    svbox.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then svd = true; end;
    end);
    svbox.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then svd = false; end;
    end);
    hueb.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then hd = true; end;
    end);
    hueb.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then hd = false; end;
    end);

    local mvconn;
    mvconn = uis.InputChanged:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return; end;
        if svd then
            local ap, sz = svbox.AbsolutePosition, svbox.AbsoluteSize;
            s = math.clamp((i.Position.X - ap.X) / sz.X, 0, 1);
            v = 1 - math.clamp((i.Position.Y - ap.Y) / sz.Y, 0, 1);
            refresh();
        elseif hd then
            local ap, sz = hueb.AbsolutePosition, hueb.AbsoluteSize;
            h = math.clamp((i.Position.X - ap.X) / sz.X, 0, 1);
            refresh();
        end;
    end);
    table.insert(self.conns, mvconn);

    hexinput.FocusLost:Connect(function()
        local txt = hexinput.Text:gsub("#","");
        if #txt == 6 then
            local r2 = tonumber(txt:sub(1,2),16);
            local g2 = tonumber(txt:sub(3,4),16);
            local b2 = tonumber(txt:sub(5,6),16);
            if r2 and g2 and b2 then
                h, s, v = Color3.toHSV(Color3.fromRGB(r2,g2,b2));
                refresh();
            end;
        end;
        hexinput.Text = rgbtohex(state);
    end);

    sw.MouseButton1Click:Connect(function()
        picker.Visible = not picker.Visible;
    end);

    refresh();
    if flag then lib.flags[flag] = state; lib.callbacks[flag] = function(c) h,s,v = Color3.toHSV(c); refresh(); end; end;

    table.insert(self.elems, {theme=function(tt)
        nm.TextColor3 = tt.text;
        if ds then ds.TextColor3 = tt.mute; end;
        hex.TextColor3 = tt.mute;
        swstroke.Color = tt.stroke;
        picker.BackgroundColor3 = tt.elev;
        hexinput.BackgroundColor3 = tt.surf2; hexinput.TextColor3 = tt.text;
    end});

    return {set=function(c) h,s,v = Color3.toHSV(c); refresh(); end, get=function() return state; end};
end;

function lib:_button(sec, o)
    o = o or {};
    local t = self.theme;
    local first = #sec.container:GetChildren() <= 1;
    local r, inner = newrow(sec, t, first);
    local row = mk("Frame", {Parent=inner, Size=UDim2.new(1,0,0,44), BackgroundTransparency=1});
    local left, nm, ds = rowhead(row, t, o.text or "Button", o.desc, self.font);

    local btn = mk("TextButton", {Parent=row, Size=UDim2.new(0,90,0,30), Position=UDim2.new(1,-90,0.5,-15), BackgroundColor3=t.acc, BorderSizePixel=0, Text=o.label or "Run", TextColor3=t.acct, Font=self.font, TextSize=11, AutoButtonColor=false});
    corner(btn, 8);

    btn.MouseEnter:Connect(function() tween(btn, 0.1, {BackgroundTransparency=0.15}); end);
    btn.MouseLeave:Connect(function() tween(btn, 0.1, {BackgroundTransparency=0}); end);
    btn.MouseButton1Click:Connect(function() if o.cb then o.cb(); end; end);

    table.insert(self.elems, {theme=function(tt)
        nm.TextColor3 = tt.text;
        if ds then ds.TextColor3 = tt.mute; end;
        btn.BackgroundColor3 = tt.acc; btn.TextColor3 = tt.acct;
    end});

    return {click=function() if o.cb then o.cb(); end; end};
end;

function lib:_label(sec, text)
    local t = self.theme;
    local l = mk("TextLabel", {Parent=sec.container, Size=UDim2.new(1,0,0,24), BackgroundTransparency=1, Text=string.upper(text or ""), TextColor3=t.dim, Font=Enum.Font.Code, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=#sec.container:GetChildren()});
    pad(l, 10, 0, 4, 0);

    table.insert(self.elems, {theme=function(tt) l.TextColor3 = tt.dim; end});

    return {set=function(v) l.Text = string.upper(v); end};
end;

function lib:_paragraph(sec, title, body)
    local t = self.theme;
    local first = #sec.container:GetChildren() <= 1;
    local r = mk("Frame", {Parent=sec.container, Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, LayoutOrder=#sec.container:GetChildren()});
    pad(r, 14, 0, 4, 0);
    if not first then
        mk("Frame", {Parent=r, Size=UDim2.new(1,0,0,1), BackgroundColor3=t.strokes, BorderSizePixel=0});
    end;
    local tt = mk("TextLabel", {Parent=r, Size=UDim2.new(1,0,0,16), Position=UDim2.new(0,0,0,first and 0 or 8), BackgroundTransparency=1, Text=title or "", TextColor3=t.text, Font=self.font, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left});
    local bb = mk("TextLabel", {Parent=r, Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,0,24+(first and 0 or 8)), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, Text=body or "", TextColor3=t.mute, Font=self.font, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top, TextWrapped=true});

    table.insert(self.elems, {theme=function(th) tt.TextColor3 = th.text; bb.TextColor3 = th.mute; end});

    return {set=function(a, b) tt.Text = a; bb.Text = b; end};
end;

function lib:_custom(sec, name, opts)
    local fac = lib.components[name];
    if not fac then warn("[lumen] unknown component: "..tostring(name)); return; end;
    local first = #sec.container:GetChildren() <= 1;
    local r, inner = newrow(sec, self.theme, first);
    return fac(self, sec, inner, opts or {});
end;

function lib:registercomponent(name, builder)
    lib.components[name] = builder;
end;

function lib:notify(o)
    o = o or {};
    local t = self.theme;
    local dur = o.duration or 4;

    local n = mk("Frame", {Parent=self.toaststack, Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, BackgroundColor3=t.surf, BorderSizePixel=0});
    corner(n, 10);
    stroke(n, t.stroke, 1);
    pad(n, 12, 14, 12, 22);

    mk("Frame", {Parent=n, Size=UDim2.new(0,3,1,-16), Position=UDim2.new(0,8,0,8), BackgroundColor3=t.acc, BorderSizePixel=0});

    local tt = mk("TextLabel", {Parent=n, Size=UDim2.new(1,0,0,16), BackgroundTransparency=1, Text=o.title or "Lumen", TextColor3=t.text, Font=self.font, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left});
    mk("TextLabel", {Parent=n, Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,0,18), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, Text=o.text or "", TextColor3=t.mute, Font=self.font, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top, TextWrapped=true});

    n.BackgroundTransparency = 1;
    tt.TextTransparency = 1;
    tween(n, 0.2, {BackgroundTransparency=0});

    task.delay(dur, function()
        if n and n.Parent then
            tween(n, 0.25, {BackgroundTransparency=1});
            for _, d in next, n:GetDescendants() do
                if d:IsA("TextLabel") then tween(d, 0.25, {TextTransparency=1}); end;
                if d:IsA("Frame") then tween(d, 0.25, {BackgroundTransparency=1}); end;
                if d:IsA("UIStroke") then tween(d, 0.25, {Transparency=1}); end;
            end;
            task.wait(0.3);
            n:Destroy();
        end;
    end);
end;

function lib:buildconfig()
    local cfg = {window=self, folder=self.folder};

    if makefolder and not (isfolder and isfolder(self.folder)) then
        pcall(makefolder, self.folder);
    end;

    function cfg:path(name)
        return self.folder.."/"..name..".json";
    end;

    function cfg:save(name)
        if not writefile then return false, "no executor"; end;
        local data = {flags = {}};
        for k, v in next, lib.flags do
            if typeof(v) == "Color3" then
                data.flags[k] = {__t="c3", r=v.R, g=v.G, b=v.B};
            elseif typeof(v) == "EnumItem" then
                data.flags[k] = {__t="e", n=v.Name};
            else
                data.flags[k] = v;
            end;
        end;
        data.theme = self.window.themekey;
        data.font = self.window.fontkey;
        local ok, enc = pcall(http.JSONEncode, http, data);
        if not ok then return false, enc; end;
        pcall(writefile, self:path(name), enc);
        return true;
    end;

    function cfg:load(name)
        if not readfile or not (isfile and isfile(self:path(name))) then return false, "no file"; end;
        local ok, raw = pcall(readfile, self:path(name));
        if not ok then return false, raw; end;
        local ok2, data = pcall(http.JSONDecode, http, raw);
        if not ok2 then return false, data; end;
        for k, v in next, data.flags or {} do
            local val = v;
            if type(v) == "table" and v.__t == "c3" then val = Color3.new(v.r, v.g, v.b); end;
            if type(v) == "table" and v.__t == "e" then val = Enum.KeyCode[v.n]; end;
            lib.flags[k] = val;
            if lib.callbacks[k] then pcall(lib.callbacks[k], val); end;
        end;
        if data.theme then self.window:applytheme(data.theme); end;
        if data.font then self.window:applyfont(data.font); end;
        return true;
    end;

    function cfg:delete(name)
        if delfile and isfile and isfile(self:path(name)) then pcall(delfile, self:path(name)); return true; end;
        return false;
    end;

    function cfg:list()
        local out = {};
        if not listfiles or not (isfolder and isfolder(self.folder)) then return out; end;
        local ok, files = pcall(listfiles, self.folder);
        if not ok then return out; end;
        for _, f in next, files do
            local n = f:match("([^/\\]+)%.json$");
            if n then table.insert(out, n); end;
        end;
        return out;
    end;

    return cfg;
end;

function lib:destroy()
    for _, c in next, self.conns do pcall(function() c:Disconnect(); end); end;
    if self.gui then self.gui:Destroy(); end;
end;

return lib;
