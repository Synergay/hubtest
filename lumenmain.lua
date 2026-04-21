--[[
	LumenUI v2.0 — Modern Roblox Luau GUI Library for Executors
	-----------------------------------------------------------
	Single-file ModuleScript / loadstring target.

	Quick start (executor):

		local LumenUI = loadstring(game:HttpGet("<your-url>/LumenUI.lua"))()

		local Window = LumenUI:CreateWindow({
			Title = "Lumen",
			Subtitle = "v2.0",
			Size = UDim2.fromOffset(780, 520),
			ConfigFolder = "Lumen/MyGame",   -- writefile/readfile persistence
			Theme = "Amber",                 -- built-in theme
			Font  = "Gotham",                -- Gotham | Inter | Mono | Sans
			Keybind = Enum.KeyCode.RightShift,
		})

		local Combat   = Window:AddCategory("Combat")
		local CombatT  = Combat:AddTab("Combat", "sword")
		local Damage   = CombatT:AddSection("Damage Multiplier")

		Damage:AddToggle({ Flag = "dmg_enable", Name = "Enable", Default = false,
			Description = "Multiply your damage output.", Callback = function(v) end })
		Damage:AddSlider({ Flag = "dmg_mult", Name = "Multiplier", Min = 1, Max = 10, Default = 5, Step = 0.1 })
		Damage:AddKeybind({ Flag = "dmg_key", Name = "Keybind", Default = Enum.KeyCode.V })
		Damage:AddDropdown({ Flag = "dmg_target", Name = "Target Priority",
			Options = {"Closest","Lowest HP","Highest Threat"}, Default = "Closest" })
		Damage:AddInput({ Flag = "dmg_note", Name = "Note", Placeholder = "Type…" })
		Damage:AddColorPicker({ Flag = "dmg_col", Name = "Highlight", Default = Color3.fromRGB(245,168,54) })
		Damage:AddButton({ Name = "Reset", ButtonText = "Run", Callback = function() end })
		Damage:AddLabel("Labels are small eyebrow text.")
		Damage:AddParagraph("Title", "Longer paragraph for instructions or warnings.")

		LumenUI:Notify({ Title = "Loaded", Content = "Lumen is ready.", Duration = 4 })

		-- Save manager
		Window.Config:Save("default")
		Window.Config:Load("default")
		Window.Config:List()         -- returns {names…}
		Window.Config:Delete("foo")

		-- Extend with a custom component
		LumenUI:RegisterComponent("Stepper", function(section, opts)
			-- build row using section:_buildRow(name, desc) and return {Set=..., Get=...}
		end)
--]]

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")

----------------------------------------------------------------
-- Utilities
----------------------------------------------------------------
local function make(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do inst[k] = v end
	for _, c in ipairs(children or {}) do c.Parent = inst end
	return inst
end
local function corner(r) return make("UICorner", {CornerRadius = UDim.new(0, r)}) end
local function stroke(c, t)
	return make("UIStroke", {Color = c, Thickness = t or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
end
local function padding(t,r,b,l)
	return make("UIPadding", {
		PaddingTop=UDim.new(0,t or 0), PaddingRight=UDim.new(0,r or t or 0),
		PaddingBottom=UDim.new(0,b or t or 0), PaddingLeft=UDim.new(0,l or r or t or 0),
	})
end
local function list(dir, gap)
	return make("UIListLayout", {
		FillDirection=dir or Enum.FillDirection.Vertical,
		Padding=UDim.new(0, gap or 0), SortOrder=Enum.SortOrder.LayoutOrder,
	})
end
local function tween(o, t, p)
	return TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p):Play()
end

-- Executor FS shims (guarded)
local hasFS = (writefile and readfile and isfile and listfiles and makefolder and isfolder) ~= nil
local function fsSafe(fn, ...)
	if not hasFS then return false end
	local ok, res = pcall(fn, ...)
	if ok then return res else return nil end
end

----------------------------------------------------------------
-- Themes + Fonts
----------------------------------------------------------------
local Themes = {
	Amber = {
		Bg=Color3.fromRGB(14,15,18), Surface=Color3.fromRGB(20,22,26),
		SurfaceAlt=Color3.fromRGB(26,28,33), Elevated=Color3.fromRGB(32,35,41),
		Text=Color3.fromRGB(235,236,240), TextMuted=Color3.fromRGB(148,152,162),
		TextDim=Color3.fromRGB(98,102,112), Stroke=Color3.fromRGB(38,41,48),
		StrokeSoft=Color3.fromRGB(30,33,39), Accent=Color3.fromRGB(245,168,54),
		AccentText=Color3.fromRGB(22,16,4), Danger=Color3.fromRGB(232,90,90),
	},
	Mint = {
		Bg=Color3.fromRGB(12,16,15), Surface=Color3.fromRGB(18,22,21),
		SurfaceAlt=Color3.fromRGB(24,29,28), Elevated=Color3.fromRGB(30,36,34),
		Text=Color3.fromRGB(233,240,237), TextMuted=Color3.fromRGB(142,160,154),
		TextDim=Color3.fromRGB(92,108,102), Stroke=Color3.fromRGB(38,46,43),
		StrokeSoft=Color3.fromRGB(28,34,32), Accent=Color3.fromRGB(120,220,170),
		AccentText=Color3.fromRGB(6,22,16), Danger=Color3.fromRGB(232,90,90),
	},
	Iris = {
		Bg=Color3.fromRGB(14,14,20), Surface=Color3.fromRGB(20,20,28),
		SurfaceAlt=Color3.fromRGB(26,26,36), Elevated=Color3.fromRGB(34,33,46),
		Text=Color3.fromRGB(235,235,244), TextMuted=Color3.fromRGB(150,148,170),
		TextDim=Color3.fromRGB(100,98,118), Stroke=Color3.fromRGB(42,40,56),
		StrokeSoft=Color3.fromRGB(30,28,42), Accent=Color3.fromRGB(160,140,255),
		AccentText=Color3.fromRGB(14,10,36), Danger=Color3.fromRGB(232,90,120),
	},
	Rose = {
		Bg=Color3.fromRGB(18,14,15), Surface=Color3.fromRGB(24,19,21),
		SurfaceAlt=Color3.fromRGB(30,24,26), Elevated=Color3.fromRGB(38,30,33),
		Text=Color3.fromRGB(240,233,234), TextMuted=Color3.fromRGB(168,150,154),
		TextDim=Color3.fromRGB(118,100,104), Stroke=Color3.fromRGB(50,40,43),
		StrokeSoft=Color3.fromRGB(36,28,31), Accent=Color3.fromRGB(240,120,140),
		AccentText=Color3.fromRGB(32,10,16), Danger=Color3.fromRGB(232,90,90),
	},
	Mono = {
		Bg=Color3.fromRGB(12,12,12), Surface=Color3.fromRGB(18,18,18),
		SurfaceAlt=Color3.fromRGB(24,24,24), Elevated=Color3.fromRGB(32,32,32),
		Text=Color3.fromRGB(240,240,240), TextMuted=Color3.fromRGB(150,150,150),
		TextDim=Color3.fromRGB(100,100,100), Stroke=Color3.fromRGB(40,40,40),
		StrokeSoft=Color3.fromRGB(28,28,28), Accent=Color3.fromRGB(240,240,240),
		AccentText=Color3.fromRGB(12,12,12), Danger=Color3.fromRGB(232,90,90),
	},
}

local Fonts = {
	Gotham = { Display=Enum.Font.GothamBold, Title=Enum.Font.GothamBold, Body=Enum.Font.Gotham, Mono=Enum.Font.Code },
	Inter  = { Display=Enum.Font.BuilderSansBold, Title=Enum.Font.BuilderSansBold, Body=Enum.Font.BuilderSans, Mono=Enum.Font.Code },
	Sans   = { Display=Enum.Font.SourceSansBold, Title=Enum.Font.SourceSansBold, Body=Enum.Font.SourceSans, Mono=Enum.Font.Code },
	Mono   = { Display=Enum.Font.Code, Title=Enum.Font.Code, Body=Enum.Font.Code, Mono=Enum.Font.Code },
}

local Radius = {Window=12, Card=10, Pill=8, Chip=6}

----------------------------------------------------------------
-- Root library
----------------------------------------------------------------
local LumenUI = {}
LumenUI.__index = LumenUI
LumenUI.Version = "2.0.0"
LumenUI.Flags = {}             -- global flag registry
LumenUI._components = {}       -- custom component registry
LumenUI._windows = {}

-- Event bus
function LumenUI._bindFlag(flag, obj)
	if flag then LumenUI.Flags[flag] = obj end
end

-- Register custom component factory
function LumenUI:RegisterComponent(name, factory)
	self._components[name] = factory
end

----------------------------------------------------------------
-- Window
----------------------------------------------------------------
local Window = {}
Window.__index = Window

function LumenUI:CreateWindow(opts)
	opts = opts or {}
	local self2 = setmetatable({}, Window)
	self2.Title    = opts.Title or "Lumen"
	self2.Subtitle = opts.Subtitle or ""
	self2.Size     = opts.Size or UDim2.fromOffset(780, 520)
	self2.Theme    = Themes[opts.Theme or "Amber"] or Themes.Amber
	self2.ThemeName = opts.Theme or "Amber"
	self2.Font     = Fonts[opts.Font or "Gotham"] or Fonts.Gotham
	self2.FontName = opts.Font or "Gotham"
	self2.ToggleKey = opts.Keybind or Enum.KeyCode.RightShift
	self2.ConfigFolder = opts.ConfigFolder or "Lumen/Default"
	self2.Categories, self2.Tabs = {}, {}

	-- ScreenGui (guard executor vs. regular)
	local parent = opts.Parent
		or (gethui and gethui())
		or (syn and syn.protect_gui and PlayerGui)
		or PlayerGui
		or game:GetService("CoreGui")
	local gui = make("ScreenGui", {
		Name = "LumenUI_"..HttpService:GenerateGUID(false):sub(1,8),
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		DisplayOrder = 9999,
	})
	if syn and syn.protect_gui then pcall(syn.protect_gui, gui) end
	gui.Parent = parent
	self2.Gui = gui

	-- Window frame
	local win = make("Frame", {
		Name = "Window",
		Size = self2.Size,
		Position = UDim2.new(0.5, -self2.Size.X.Offset/2, 0.5, -self2.Size.Y.Offset/2),
		BackgroundColor3 = self2.Theme.Bg, BorderSizePixel = 0,
		ClipsDescendants = true,
	}, {corner(Radius.Window), stroke(self2.Theme.Stroke, 1)})
	win.Parent = gui
	self2.Frame = win

	-- Titlebar
	local tb = make("Frame", {
		Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = self2.Theme.Surface, BorderSizePixel = 0,
	}, {
		make("Frame", {Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1), BackgroundColor3=self2.Theme.Stroke, BorderSizePixel=0}),
		make("TextLabel", {Size=UDim2.new(0,400,1,0), Position=UDim2.new(0,20,0,0), BackgroundTransparency=1,
			Font=self2.Font.Display, TextSize=13, Text=string.upper(self2.Title), TextColor3=self2.Theme.Text,
			TextXAlignment=Enum.TextXAlignment.Left}),
	})
	tb.Parent = win
	self2.Titlebar = tb

	-- Window controls
	local closeBtn = make("TextButton", {
		Size=UDim2.new(0,16,0,16), Position=UDim2.new(1,-24,0.5,-8),
		BackgroundTransparency=1, AutoButtonColor=false,
		Font=self2.Font.Body, TextSize=16, Text="×", TextColor3=self2.Theme.TextMuted,
	}) closeBtn.Parent = tb
	closeBtn.MouseButton1Click:Connect(function() self2:Destroy() end)

	local minBtn = make("TextButton", {
		Size=UDim2.new(0,16,0,16), Position=UDim2.new(1,-52,0.5,-8),
		BackgroundTransparency=1, AutoButtonColor=false,
		Font=self2.Font.Body, TextSize=14, Text="—", TextColor3=self2.Theme.TextMuted,
	}) minBtn.Parent = tb

	local minimized = false
	local origSize = self2.Size
	minBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		win.Size = minimized and UDim2.fromOffset(origSize.X.Offset, 44) or origSize
	end)

	-- Dragging
	self2:_makeDraggable(win, tb)

	-- Sidebar
	local sidebar = make("Frame", {
		Size=UDim2.new(0,200,1,-44), Position=UDim2.new(0,0,0,44),
		BackgroundColor3=self2.Theme.Surface, BorderSizePixel=0,
	}, {
		make("Frame", {Size=UDim2.new(0,1,1,0), Position=UDim2.new(1,-1,0,0), BackgroundColor3=self2.Theme.Stroke, BorderSizePixel=0}),
	})
	sidebar.Parent = win

	-- Brand row at top of sidebar
	local brand = make("Frame", {Size=UDim2.new(1,0,0,44), BackgroundTransparency=1}, {padding(12,12,0,16)})
	brand.Parent = sidebar
	local mark = make("Frame", {Size=UDim2.new(0,20,0,20), Position=UDim2.new(0,0,0.5,-10),
		BackgroundColor3=self2.Theme.Accent, BorderSizePixel=0}, {corner(6)})
	mark.Parent = brand
	make("Frame", {Size=UDim2.new(0,8,0,8), Position=UDim2.new(0.5,-4,0.5,-4),
		BackgroundColor3=self2.Theme.Surface, BorderSizePixel=0}, {corner(2)}).Parent = mark
	make("TextLabel", {Size=UDim2.new(1,-36,1,0), Position=UDim2.new(0,30,0,0),
		BackgroundTransparency=1, Font=self2.Font.Title, TextSize=13, Text=self2.Title,
		TextColor3=self2.Theme.Text, TextXAlignment=Enum.TextXAlignment.Left}).Parent = brand

	local sideList = make("ScrollingFrame", {
		Size=UDim2.new(1,0,1,-44), Position=UDim2.new(0,0,0,44),
		BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=0,
		AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new(0,0,0,0),
	}, {padding(8,14,14,14), list(Enum.FillDirection.Vertical, 2)})
	sideList.Parent = sidebar
	self2.SideList = sideList

	-- Content area
	local content = make("Frame", {
		Size=UDim2.new(1,-200,1,-44), Position=UDim2.new(0,200,0,44),
		BackgroundColor3=self2.Theme.Bg, BorderSizePixel=0,
	}) content.Parent = win
	self2.Content = content

	-- Global toggle keybind
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == self2.ToggleKey then
			self2.Gui.Enabled = not self2.Gui.Enabled
		end
	end)

	-- Config manager
	self2.Config = require_config(self2)

	table.insert(LumenUI._windows, self2)
	return self2
end

function Window:_makeDraggable(frame, handle)
	local dragging, startInput, startPos
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; startInput = input.Position; startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - startInput
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end

function Window:Destroy()
	if self.Gui then self.Gui:Destroy() end
end

function Window:SetTheme(name)
	if not Themes[name] then return end
	-- Soft reload: destroy and re-create is expensive; we just swap token refs and rebuild styles where possible.
	-- For simplicity: document that SetTheme requires rebuilding the window.
	self.Theme = Themes[name]; self.ThemeName = name
	-- Consumers should re-create the window for a full recolor, OR iterate all descendants (kept simple).
	for _, d in ipairs(self.Frame:GetDescendants()) do
		if d:IsA("UIStroke") then
			if d.Color == Themes.Amber.Stroke or d.Color == Themes.Mint.Stroke or d.Color == Themes.Iris.Stroke or d.Color == Themes.Rose.Stroke or d.Color == Themes.Mono.Stroke then
				d.Color = self.Theme.Stroke
			end
		end
	end
end

----------------------------------------------------------------
-- Category + Tab + Section
----------------------------------------------------------------
local Category = {} Category.__index = Category
local Tab      = {} Tab.__index      = Tab
local Section  = {} Section.__index  = Section

function Window:AddCategory(name)
	local label = make("TextLabel", {
		Size=UDim2.new(1,0,0,24), BackgroundTransparency=1,
		Font=self.Font.Display, TextSize=10, Text=string.upper(name),
		TextColor3=self.Theme.TextDim, TextXAlignment=Enum.TextXAlignment.Left,
		LayoutOrder=#self.Categories*1000,
	}, {padding(10,0,4,4)})
	label.Parent = self.SideList
	local cat = setmetatable({Window=self, Name=name, Order=#self.Categories*1000, Tabs={}}, Category)
	table.insert(self.Categories, cat)
	return cat
end

local iconMap = {
	sword="⚔", user="☺", eye="◎", grid="▦", shield="◈", cog="⚙",
	code="⟨⟩", folder="▣", bolt="⌁", sparkle="✦", cross="✕", list="☰",
}

function Category:AddTab(name, icon)
	local win = self.Window
	local order = self.Order + #self.Tabs + 1

	local btn = make("TextButton", {
		Size=UDim2.new(1,0,0,34), BackgroundColor3=win.Theme.Elevated,
		BackgroundTransparency=1, AutoButtonColor=false, Text="", LayoutOrder=order,
	}, {corner(Radius.Pill)})
	btn.Parent = win.SideList

	make("TextLabel", {
		Size=UDim2.new(0,18,0,18), Position=UDim2.new(0,10,0.5,-9),
		BackgroundTransparency=1, Font=win.Font.Body, TextSize=14,
		Text=iconMap[icon] or icon or "•", TextColor3=win.Theme.TextMuted,
	}).Parent = btn
	local txt = make("TextLabel", {
		Size=UDim2.new(1,-40,1,0), Position=UDim2.new(0,36,0,0),
		BackgroundTransparency=1, Font=win.Font.Title, TextSize=13, Text=name,
		TextColor3=win.Theme.TextMuted, TextXAlignment=Enum.TextXAlignment.Left,
	}) txt.Parent = btn

	local page = make("ScrollingFrame", {
		Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, BorderSizePixel=0,
		Visible=false, ScrollBarThickness=3, ScrollBarImageColor3=win.Theme.Stroke,
		AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new(0,0,0,0),
	}, {padding(24,36,28,36), list(Enum.FillDirection.Vertical, 16)})
	page.Parent = win.Content

	local tab = setmetatable({Window=win, Category=self, Name=name,
		Button=btn, Label=txt, Page=page, Sections={}}, Tab)
	table.insert(self.Tabs, tab); table.insert(win.Tabs, tab)

	btn.MouseButton1Click:Connect(function() win:SelectTab(tab) end)
	btn.MouseEnter:Connect(function()
		if win.Active ~= tab then
			tween(btn, 0.1, {BackgroundTransparency=0.6})
			tween(txt, 0.1, {TextColor3=win.Theme.Text})
		end
	end)
	btn.MouseLeave:Connect(function()
		if win.Active ~= tab then
			tween(btn, 0.1, {BackgroundTransparency=1})
			tween(txt, 0.1, {TextColor3=win.Theme.TextMuted})
		end
	end)

	if #win.Tabs == 1 then win:SelectTab(tab) end
	return tab
end

function Window:SelectTab(tab)
	for _, t in ipairs(self.Tabs) do
		t.Page.Visible = false
		tween(t.Button, 0.1, {BackgroundTransparency=1})
		tween(t.Label, 0.1, {TextColor3=self.Theme.TextMuted})
	end
	tab.Page.Visible = true
	tab.Button.BackgroundColor3 = self.Theme.Elevated
	tween(tab.Button, 0.15, {BackgroundTransparency=0})
	tween(tab.Label, 0.15, {TextColor3=self.Theme.Text})
	self.Active = tab
end

function Tab:AddSection(title)
	local win = self.Window
	local card = make("Frame", {
		Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundColor3=win.Theme.Surface, BorderSizePixel=0, LayoutOrder=#self.Sections+1,
	}, {corner(Radius.Card), stroke(win.Theme.StrokeSoft, 1)})
	card.Parent = self.Page

	local inner = make("Frame", {Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundTransparency=1}, {padding(18,24,20,24), list(Enum.FillDirection.Vertical, 0)})
	inner.Parent = card

	make("TextLabel", {Size=UDim2.new(1,0,0,24), BackgroundTransparency=1,
		Font=win.Font.Title, TextSize=16, Text=title, TextColor3=win.Theme.Text,
		TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=0,
	}, {padding(0,0,12,0)}).Parent = inner

	local s = setmetatable({Tab=self, Window=win, Card=card, Inner=inner, Rows={}}, Section)
	table.insert(self.Sections, s)
	return s
end

----------------------------------------------------------------
-- Row scaffold (used by all components)
----------------------------------------------------------------
function Section:_buildRow(name, description, fullWidth)
	local win = self.Window
	local row = make("Frame", {
		Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundTransparency=1, LayoutOrder=#self.Rows+1,
	}, {padding(14,0,14,0)})
	row.Parent = self.Inner

	if #self.Rows > 0 then
		make("Frame", {Size=UDim2.new(1,0,0,1), BackgroundColor3=win.Theme.StrokeSoft,
			BorderSizePixel=0, LayoutOrder=0}).Parent = row
	end

	local body = make("Frame", {Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundTransparency=1, LayoutOrder=1}, {padding(14,0,0,0)})
	body.Parent = row

	local leftW = fullWidth and UDim2.new(1,0,0,0) or UDim2.new(1,-200,0,0)
	local left = make("Frame", {Size=leftW, AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundTransparency=1}, {list(Enum.FillDirection.Vertical, 4)})
	left.Parent = body

	if name then
		make("TextLabel", {Size=UDim2.new(1,0,0,18), BackgroundTransparency=1,
			Font=win.Font.Title, TextSize=14, Text=name, TextColor3=win.Theme.Text,
			TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=0}).Parent = left
	end
	if description and description ~= "" then
		make("TextLabel", {Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
			BackgroundTransparency=1, Font=win.Font.Body, TextSize=12, Text=description,
			TextColor3=win.Theme.TextMuted, TextXAlignment=Enum.TextXAlignment.Left,
			TextWrapped=true, LayoutOrder=1}).Parent = left
	end

	local right
	if not fullWidth then
		right = make("Frame", {Size=UDim2.new(0,200,0,32),
			Position=UDim2.new(1,-200,0,0), BackgroundTransparency=1})
		right.Parent = body
	end
	table.insert(self.Rows, row)
	return row, left, right, body
end

----------------------------------------------------------------
-- Components: Toggle, Slider, Keybind, Dropdown, Input,
--             ColorPicker, Button, Label, Paragraph
----------------------------------------------------------------
function Section:AddToggle(opts)
	opts = opts or {}
	local win = self.Window
	local _, _, right = self:_buildRow(opts.Name or "Toggle", opts.Description)
	local state = opts.Default and true or false

	local track = make("Frame", {Size=UDim2.new(0,40,0,22), Position=UDim2.new(1,-40,0.5,-11),
		BackgroundColor3=state and win.Theme.Accent or win.Theme.Elevated, BorderSizePixel=0,
	}, {corner(11), stroke(state and win.Theme.Accent or win.Theme.Stroke, 1)})
	track.Parent = right
	local knob = make("Frame", {
		Size=UDim2.new(0,16,0,16),
		Position=state and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8),
		BackgroundColor3=state and Color3.new(1,1,1) or win.Theme.TextMuted, BorderSizePixel=0,
	}, {corner(8)})
	knob.Parent = track
	local btn = make("TextButton", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text=""})
	btn.Parent = track

	local api = {}
	function api:Set(v, silent)
		state = v and true or false
		tween(track, 0.15, {BackgroundColor3=state and win.Theme.Accent or win.Theme.Elevated})
		tween(knob, 0.15, {
			Position = state and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8),
			BackgroundColor3 = state and Color3.new(1,1,1) or win.Theme.TextMuted,
		})
		if not silent and opts.Callback then task.spawn(opts.Callback, state) end
	end
	function api:Get() return state end
	function api:_serialize() return state end
	function api:_deserialize(v) api:Set(v, true) end
	btn.MouseButton1Click:Connect(function() api:Set(not state) end)

	LumenUI._bindFlag(opts.Flag, api)
	return api
end

function Section:AddSlider(opts)
	opts = opts or {}
	local win = self.Window
	local _, left, _, body = self:_buildRow(opts.Name or "Slider", opts.Description, true)
	local min, max = opts.Min or 0, opts.Max or 100
	local step = opts.Step or 1
	local value = math.clamp(opts.Default or min, min, max)

	local valueLbl = make("TextLabel", {
		Size=UDim2.new(0,80,0,16), Position=UDim2.new(1,-80,0,0), AnchorPoint=Vector2.new(0,0),
		BackgroundTransparency=1, Font=win.Font.Mono, TextSize=12,
		Text=tostring(value), TextColor3=win.Theme.Accent, TextXAlignment=Enum.TextXAlignment.Right,
	}) valueLbl.Parent = left

	local wrap = make("Frame", {Size=UDim2.new(1,0,0,28), BackgroundTransparency=1,
		LayoutOrder=3}, {padding(10,0,0,0)})
	wrap.Parent = body
	local track = make("Frame", {Size=UDim2.new(1,0,0,4), Position=UDim2.new(0,0,0.5,-2),
		BackgroundColor3=win.Theme.Elevated, BorderSizePixel=0}, {corner(2)})
	track.Parent = wrap
	local t0 = (value-min)/(max-min)
	local fill = make("Frame", {Size=UDim2.new(t0,0,1,0), BackgroundColor3=win.Theme.Accent,
		BorderSizePixel=0}, {corner(2)})
	fill.Parent = track
	local knob = make("Frame", {Size=UDim2.new(0,14,0,14), Position=UDim2.new(t0,-7,0.5,-7),
		BackgroundColor3=win.Theme.Accent, BorderSizePixel=0
	}, {corner(7), stroke(Color3.new(1,1,1), 2)})
	knob.Parent = track

	local function format(v)
		return (step < 1) and string.format("%.2f", v) or tostring(math.floor(v + 0.5))
	end
	valueLbl.Text = format(value)..(opts.Suffix or "")

	local dragging=false
	local function setFromX(x, silent)
		local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		local raw = min + (max - min) * rel
		local snap = math.floor(raw/step + 0.5)*step
		value = math.clamp(snap, min, max)
		local t = (value-min)/(max-min)
		fill.Size = UDim2.new(t,0,1,0); knob.Position = UDim2.new(t,-7,0.5,-7)
		valueLbl.Text = format(value)..(opts.Suffix or "")
		if not silent and opts.Callback then task.spawn(opts.Callback, value) end
	end

	track.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true; setFromX(i.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			setFromX(i.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	local api = {}
	function api:Set(v, silent)
		value = math.clamp(v, min, max)
		local t = (value-min)/(max-min)
		fill.Size = UDim2.new(t,0,1,0); knob.Position = UDim2.new(t,-7,0.5,-7)
		valueLbl.Text = format(value)..(opts.Suffix or "")
		if not silent and opts.Callback then task.spawn(opts.Callback, value) end
	end
	function api:Get() return value end
	function api:_serialize() return value end
	function api:_deserialize(v) api:Set(v, true) end
	LumenUI._bindFlag(opts.Flag, api)
	return api
end

function Section:AddKeybind(opts)
	opts = opts or {}
	local win = self.Window
	local _, _, right = self:_buildRow(opts.Name or "Keybind", opts.Description)
	local bound = opts.Default or Enum.KeyCode.None
	local listening = false

	local group = make("Frame", {Size=UDim2.new(0,144,0,30), Position=UDim2.new(1,-144,0.5,-15),
		BackgroundColor3=win.Theme.Elevated, BorderSizePixel=0,
	}, {corner(Radius.Pill), stroke(win.Theme.Stroke, 1)})
	group.Parent = right

	make("TextLabel", {Size=UDim2.new(0,32,1,-8), Position=UDim2.new(0,4,0,4),
		BackgroundColor3=win.Theme.SurfaceAlt, BorderSizePixel=0,
		Font=win.Font.Mono, TextSize=10, Text="KEY", TextColor3=win.Theme.TextMuted,
	}, {corner(4), stroke(win.Theme.Stroke, 1)}).Parent = group
	local keyLbl = make("TextLabel", {Size=UDim2.new(0,60,1,0), Position=UDim2.new(0,40,0,0),
		BackgroundTransparency=1, Font=win.Font.Title, TextSize=12,
		Text=bound==Enum.KeyCode.None and "None" or bound.Name, TextColor3=win.Theme.Text})
	keyLbl.Parent = group
	local editBtn = make("TextButton", {Size=UDim2.new(0,36,1,-8), Position=UDim2.new(1,-40,0,4),
		BackgroundColor3=win.Theme.SurfaceAlt, BorderSizePixel=0, AutoButtonColor=false,
		Font=win.Font.Title, TextSize=11, Text="Edit", TextColor3=win.Theme.Text,
	}, {corner(4), stroke(win.Theme.Stroke, 1)})
	editBtn.Parent = group

	editBtn.MouseButton1Click:Connect(function()
		listening = true; keyLbl.Text = "…"; keyLbl.TextColor3 = win.Theme.Accent
	end)

	UserInputService.InputBegan:Connect(function(input, gp)
		if listening and input.UserInputType == Enum.UserInputType.Keyboard then
			bound = (input.KeyCode == Enum.KeyCode.Escape) and Enum.KeyCode.None or input.KeyCode
			keyLbl.Text = bound==Enum.KeyCode.None and "None" or bound.Name
			keyLbl.TextColor3 = win.Theme.Text; listening = false
			if opts.Callback then task.spawn(opts.Callback, bound) end
		elseif not gp and not listening and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == bound and bound ~= Enum.KeyCode.None then
			if opts.OnPress then task.spawn(opts.OnPress) end
		end
	end)

	local api = {}
	function api:Set(k, silent)
		bound = k or Enum.KeyCode.None
		keyLbl.Text = bound==Enum.KeyCode.None and "None" or bound.Name
		if not silent and opts.Callback then task.spawn(opts.Callback, bound) end
	end
	function api:Get() return bound end
	function api:_serialize() return bound.Name end
	function api:_deserialize(v)
		api:Set(Enum.KeyCode[v] or Enum.KeyCode.None, true)
	end
	LumenUI._bindFlag(opts.Flag, api)
	return api
end

function Section:AddDropdown(opts)
	opts = opts or {}
	local win = self.Window
	local _, _, right = self:_buildRow(opts.Name or "Dropdown", opts.Description)
	local options = opts.Options or {}
	local selected = opts.Default or options[1] or ""

	local btn = make("TextButton", {Size=UDim2.new(0,160,0,30),
		Position=UDim2.new(1,-160,0.5,-15), BackgroundColor3=win.Theme.Elevated,
		AutoButtonColor=false, BorderSizePixel=0, Font=win.Font.Title, TextSize=12,
		Text=selected.."   ▾", TextColor3=win.Theme.Text, TextXAlignment=Enum.TextXAlignment.Left,
	}, {corner(Radius.Pill), stroke(win.Theme.Stroke, 1), padding(0,12,0,12)})
	btn.Parent = right

	local open, menu = false, nil
	local function close() if menu then menu:Destroy() end; menu=nil; open=false end
	btn.MouseButton1Click:Connect(function()
		if open then close(); return end
		open = true
		menu = make("Frame", {Size=UDim2.new(1,0,0,#options*26+8), Position=UDim2.new(0,0,1,6),
			BackgroundColor3=win.Theme.Elevated, BorderSizePixel=0, ZIndex=10,
		}, {corner(Radius.Pill), stroke(win.Theme.Stroke, 1), padding(4,4,4,4), list(Enum.FillDirection.Vertical, 0)})
		menu.Parent = btn
		for _, o in ipairs(options) do
			local item = make("TextButton", {Size=UDim2.new(1,0,0,24), BackgroundTransparency=1,
				AutoButtonColor=false, Font=win.Font.Body, TextSize=12, Text="  "..o,
				TextColor3=o==selected and win.Theme.Accent or win.Theme.Text,
				TextXAlignment=Enum.TextXAlignment.Left, ZIndex=11,
			}, {corner(6)})
			item.Parent = menu
			item.MouseButton1Click:Connect(function()
				selected = o; btn.Text = selected.."   ▾"
				if opts.Callback then task.spawn(opts.Callback, selected) end
				close()
			end)
		end
	end)

	local api = {}
	function api:Set(v, silent)
		selected = v; btn.Text = v.."   ▾"
		if not silent and opts.Callback then task.spawn(opts.Callback, v) end
	end
	function api:Get() return selected end
	function api:SetOptions(list)
		options = list or {}
		if not table.find(options, selected) then api:Set(options[1] or "", true) end
	end
	function api:_serialize() return selected end
	function api:_deserialize(v) api:Set(v, true) end
	LumenUI._bindFlag(opts.Flag, api)
	return api
end

function Section:AddInput(opts)
	opts = opts or {}
	local win = self.Window
	local _, _, right = self:_buildRow(opts.Name or "Input", opts.Description)
	local box = make("Frame", {Size=UDim2.new(0,200,0,30), Position=UDim2.new(1,-200,0.5,-15),
		BackgroundColor3=win.Theme.Elevated, BorderSizePixel=0,
	}, {corner(Radius.Pill), stroke(win.Theme.Stroke, 1), padding(0,10,0,10)})
	box.Parent = right
	local tb = make("TextBox", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
		Font=win.Font.Body, TextSize=12, TextColor3=win.Theme.Text,
		PlaceholderText=opts.Placeholder or "", PlaceholderColor3=win.Theme.TextMuted,
		Text=opts.Default or "", ClearTextOnFocus=false, TextXAlignment=Enum.TextXAlignment.Left})
	tb.Parent = box

	local api = {}
	function api:Set(v, silent) tb.Text = v or ""
		if not silent and opts.Callback then task.spawn(opts.Callback, tb.Text) end end
	function api:Get() return tb.Text end
	function api:_serialize() return tb.Text end
	function api:_deserialize(v) api:Set(v, true) end
	tb.FocusLost:Connect(function(enter)
		if opts.Callback then task.spawn(opts.Callback, tb.Text, enter) end
	end)
	LumenUI._bindFlag(opts.Flag, api)
	return api
end

function Section:AddColorPicker(opts)
	opts = opts or {}
	local win = self.Window
	local _, _, right = self:_buildRow(opts.Name or "Color", opts.Description)
	local color = opts.Default or Color3.fromRGB(245,168,54)

	local swatch = make("TextButton", {
		Size=UDim2.new(0,30,0,30), Position=UDim2.new(1,-30,0.5,-15),
		BackgroundColor3=color, AutoButtonColor=false, Text="", BorderSizePixel=0,
	}, {corner(Radius.Pill), stroke(win.Theme.Stroke, 1)})
	swatch.Parent = right

	local open, panel = false, nil
	local function closePanel() if panel then panel:Destroy() end; panel=nil; open=false end

	swatch.MouseButton1Click:Connect(function()
		if open then closePanel(); return end
		open = true
		panel = make("Frame", {Size=UDim2.new(0,180,0,120), Position=UDim2.new(1,-180,1,6),
			BackgroundColor3=win.Theme.Elevated, BorderSizePixel=0, ZIndex=10,
		}, {corner(Radius.Pill), stroke(win.Theme.Stroke, 1), padding(10,10,10,10)})
		panel.Parent = swatch
		-- Simple HSV sliders (3 sliders)
		local h,s,v = Color3.toHSV(color)
		local function row(label, get, set)
			local r = make("Frame", {Size=UDim2.new(1,0,0,28), BackgroundTransparency=1,
				LayoutOrder=#panel:GetChildren()})
			r.Parent = panel
			make("TextLabel", {Size=UDim2.new(0,16,1,0), BackgroundTransparency=1,
				Font=win.Font.Mono, TextSize=11, Text=label, TextColor3=win.Theme.TextMuted,
				TextXAlignment=Enum.TextXAlignment.Left, ZIndex=11}).Parent = r
			local tr = make("Frame", {Size=UDim2.new(1,-24,0,4), Position=UDim2.new(0,20,0.5,-2),
				BackgroundColor3=win.Theme.SurfaceAlt, BorderSizePixel=0, ZIndex=11}, {corner(2)})
			tr.Parent = r
			local fl = make("Frame", {Size=UDim2.new(get(),0,1,0), BackgroundColor3=win.Theme.Accent,
				BorderSizePixel=0, ZIndex=12}, {corner(2)})
			fl.Parent = tr
			tr.InputBegan:Connect(function(i)
				if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
					local function update(x)
						local rel = math.clamp((x - tr.AbsolutePosition.X)/tr.AbsoluteSize.X, 0, 1)
						fl.Size = UDim2.new(rel,0,1,0); set(rel)
						color = Color3.fromHSV(h,s,v); swatch.BackgroundColor3 = color
						if opts.Callback then task.spawn(opts.Callback, color) end
					end
					update(i.Position.X)
					local m; m = UserInputService.InputChanged:Connect(function(mi)
						if mi.UserInputType==Enum.UserInputType.MouseMovement or mi.UserInputType==Enum.UserInputType.Touch then
							update(mi.Position.X)
						end
					end)
					local e; e = UserInputService.InputEnded:Connect(function(ei)
						if ei.UserInputType==Enum.UserInputType.MouseButton1 or ei.UserInputType==Enum.UserInputType.Touch then
							m:Disconnect(); e:Disconnect()
						end
					end)
				end
			end)
		end
		make("UIListLayout", {Padding=UDim.new(0,4), SortOrder=Enum.SortOrder.LayoutOrder}).Parent = panel
		row("H", function() return h end, function(x) h=x end)
		row("S", function() return s end, function(x) s=x end)
		row("V", function() return v end, function(x) v=x end)
	end)

	local api = {}
	function api:Set(c, silent)
		color = c; swatch.BackgroundColor3 = c
		if not silent and opts.Callback then task.spawn(opts.Callback, c) end
	end
	function api:Get() return color end
	function api:_serialize() return {color.R, color.G, color.B} end
	function api:_deserialize(v)
		if typeof(v) == "table" then api:Set(Color3.new(v[1], v[2], v[3]), true) end
	end
	LumenUI._bindFlag(opts.Flag, api)
	return api
end

function Section:AddButton(opts)
	opts = opts or {}
	local win = self.Window
	local _, _, right = self:_buildRow(opts.Name or "Button", opts.Description)
	local btn = make("TextButton", {Size=UDim2.new(0,100,0,30), Position=UDim2.new(1,-100,0.5,-15),
		BackgroundColor3=win.Theme.Accent, AutoButtonColor=false, BorderSizePixel=0,
		Font=win.Font.Title, TextSize=12, Text=opts.ButtonText or "Run",
		TextColor3=win.Theme.AccentText}, {corner(Radius.Pill)})
	btn.Parent = right
	btn.MouseButton1Click:Connect(function()
		if opts.Callback then task.spawn(opts.Callback) end
	end)
	return {}
end

function Section:AddLabel(text)
	local win = self.Window
	local row = make("Frame", {Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundTransparency=1, LayoutOrder=#self.Rows+1}, {padding(10,0,4,0)})
	row.Parent = self.Inner
	local lbl = make("TextLabel", {Size=UDim2.new(1,0,0,16), BackgroundTransparency=1,
		Font=win.Font.Mono, TextSize=11, Text=string.upper(text),
		TextColor3=win.Theme.TextDim, TextXAlignment=Enum.TextXAlignment.Left})
	lbl.Parent = row
	table.insert(self.Rows, row)
	return {Set=function(_,t) lbl.Text=string.upper(t) end, Get=function() return lbl.Text end}
end

function Section:AddParagraph(title, body)
	local win = self.Window
	local row, left = self:_buildRow(title, body, true)
	return {Set=function(_,t,b)
		left:FindFirstChildOfClass("TextLabel").Text = t or title
	end}
end

----------------------------------------------------------------
-- Notifications
----------------------------------------------------------------
function LumenUI:Notify(opts)
	opts = opts or {}
	local theme = (LumenUI._windows[1] and LumenUI._windows[1].Theme) or Themes.Amber
	local font  = (LumenUI._windows[1] and LumenUI._windows[1].Font) or Fonts.Gotham
	local parent = (LumenUI._windows[1] and LumenUI._windows[1].Gui)
	if not parent then
		parent = make("ScreenGui", {Name="LumenNotify", ResetOnSpawn=false,
			IgnoreGuiInset=true, DisplayOrder=99999})
		parent.Parent = (gethui and gethui()) or PlayerGui or game:GetService("CoreGui")
	end

	-- Container (reuse)
	local container = parent:FindFirstChild("__LumenNotify")
	if not container then
		container = make("Frame", {Name="__LumenNotify", AnchorPoint=Vector2.new(1,1),
			Position=UDim2.new(1,-20,1,-20), Size=UDim2.fromOffset(320,1),
			AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1,
		}, {list(Enum.FillDirection.Vertical, 8)})
		container.Parent = parent
	end

	local card = make("Frame", {Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
		BackgroundColor3=theme.Surface, BorderSizePixel=0,
	}, {corner(10), stroke(theme.Stroke, 1), padding(14,16,14,16), list(Enum.FillDirection.Vertical, 4)})
	card.Parent = container
	-- accent bar
	make("Frame", {Size=UDim2.new(0,3,1,-20), Position=UDim2.new(0,6,0,10),
		BackgroundColor3=theme.Accent, BorderSizePixel=0}, {corner(2)}).Parent = card

	make("TextLabel", {Size=UDim2.new(1,0,0,18), BackgroundTransparency=1,
		Font=font.Title, TextSize=13, Text=opts.Title or "Notice",
		TextColor3=theme.Text, TextXAlignment=Enum.TextXAlignment.Left}).Parent = card
	if opts.Content then
		make("TextLabel", {Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
			BackgroundTransparency=1, Font=font.Body, TextSize=12, Text=opts.Content,
			TextColor3=theme.TextMuted, TextXAlignment=Enum.TextXAlignment.Left,
			TextWrapped=true}).Parent = card
	end

	task.delay(opts.Duration or 4, function()
		if card and card.Parent then
			tween(card, 0.3, {BackgroundTransparency=1})
			task.wait(0.3); card:Destroy()
		end
	end)
end

----------------------------------------------------------------
-- Config / Save manager
----------------------------------------------------------------
function require_config(win)
	local cfg = {}
	cfg.Window = win

	local folder = win.ConfigFolder
	if hasFS and not fsSafe(isfolder, folder) then
		-- makefolder is not recursive; split path
		local parts, acc = {}, ""
		for p in string.gmatch(folder, "[^/]+") do table.insert(parts, p) end
		for _, p in ipairs(parts) do
			acc = (acc == "" and p) or (acc.."/"..p)
			if not fsSafe(isfolder, acc) then fsSafe(makefolder, acc) end
		end
	end

	local function path(name) return folder.."/"..name..".json" end

	function cfg:Save(name)
		name = name or "default"
		local data = {}
		for flag, obj in pairs(LumenUI.Flags) do
			if obj._serialize then
				local ok, v = pcall(obj._serialize, obj)
				if ok then data[flag] = v end
			end
		end
		local json = HttpService:JSONEncode(data)
		if hasFS then fsSafe(writefile, path(name), json) end
		return json
	end

	function cfg:Load(name)
		name = name or "default"
		local json
		if hasFS and fsSafe(isfile, path(name)) then
			json = fsSafe(readfile, path(name))
		end
		if not json then return false end
		local ok, data = pcall(HttpService.JSONDecode, HttpService, json)
		if not ok or type(data) ~= "table" then return false end
		for flag, v in pairs(data) do
			local obj = LumenUI.Flags[flag]
			if obj and obj._deserialize then pcall(obj._deserialize, obj, v) end
		end
		return true
	end

	function cfg:Delete(name)
		if hasFS and fsSafe(isfile, path(name)) then fsSafe(delfile, path(name)) end
	end

	function cfg:List()
		local out = {}
		if hasFS then
			local files = fsSafe(listfiles, folder) or {}
			for _, f in ipairs(files) do
				local n = f:match("([^/\\]+)%.json$")
				if n then table.insert(out, n) end
			end
		end
		return out
	end

	function cfg:Autoload(name)
		cfg:Load(name or "default")
	end

	-- Build a mini UI for it if tab provided
	function cfg:BuildUI(tab)
		local sec = tab:AddSection("Config Manager")
		local name = "default"
		sec:AddInput({Name="Config name", Default="default", Placeholder="name",
			Callback=function(v) name = v ~= "" and v or "default" end})
		sec:AddButton({Name="Save", ButtonText="Save", Callback=function() cfg:Save(name)
			LumenUI:Notify({Title="Saved", Content="Saved as '"..name.."'"}) end})
		sec:AddButton({Name="Load", ButtonText="Load", Callback=function()
			local ok = cfg:Load(name)
			LumenUI:Notify({Title=ok and "Loaded" or "Not found", Content="'"..name.."'"})
		end})
		sec:AddButton({Name="Delete", ButtonText="Delete", Callback=function() cfg:Delete(name)
			LumenUI:Notify({Title="Deleted", Content="'"..name.."'"}) end})
		sec:AddLabel("Files are written to "..folder.." (executor only)")
	end

	return cfg
end

return LumenUI
