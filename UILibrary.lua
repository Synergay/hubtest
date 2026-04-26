--[[
    UILibrary — Clean Roblox UI Library
    
    Usage:
        local UILib = require(path.to.UILibrary)
        local Window = UILib:CreateWindow("My Script", "Working Example")
        local Tab = Window:AddTab("Buttons")
        
        Tab:AddButton("Simple Button", function()
            print("Button clicked!")
        end)
        
        Tab:AddToggle("Enable ESP", false, function(value)
            print("Toggle:", value)
        end)
]]

local UILibrary = {}
UILibrary.__index = UILibrary

-- ── Services ──────────────────────────────────────────────────────────────
local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")
local CoreGui        = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ── Utility ───────────────────────────────────────────────────────────────
local function Tween(obj, props, duration, style, direction)
    local info = TweenInfo.new(
        duration or 0.2,
        style or Enum.EasingStyle.Quart,
        direction or Enum.EasingDirection.Out
    )
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function Create(class, props, children)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    for _, child in ipairs(children or {}) do
        child.Parent = obj
    end
    return obj
end

local function MakeCorner(radius)
    return Create("UICorner", { CornerRadius = UDim.new(0, radius or 6) })
end

local function MakePadding(top, right, bottom, left)
    return Create("UIPadding", {
        PaddingTop    = UDim.new(0, top    or 8),
        PaddingRight  = UDim.new(0, right  or 12),
        PaddingBottom = UDim.new(0, bottom or 8),
        PaddingLeft   = UDim.new(0, left   or 12),
    })
end

-- ── Theme ─────────────────────────────────────────────────────────────────
local Theme = {
    Base        = Color3.fromHex("07070a"),
    Panel       = Color3.fromHex("0b0b0e"),
    Raised      = Color3.fromHex("0f0f13"),
    Hover       = Color3.fromHex("141418"),
    Active      = Color3.fromHex("18181d"),
    Border      = Color3.fromHex("ffffff"), -- use with transparency
    Text        = Color3.fromHex("dddde8"),
    TextMuted   = Color3.fromHex("52526a"),
    TextDim     = Color3.fromHex("2e2e3a"),
    Accent      = Color3.fromHex("5865f2"),
    AccentLight = Color3.fromHex("6875f5"),
    Green       = Color3.fromHex("22c55e"),
    Red         = Color3.fromHex("ef4444"),
    Yellow      = Color3.fromHex("eab308"),
}

-- ── Notification System ───────────────────────────────────────────────────
local NotifContainer

local function InitNotifs(gui)
    NotifContainer = Create("Frame", {
        Name = "Notifications",
        Parent = gui,
        Size = UDim2.new(0, 300, 1, 0),
        Position = UDim2.new(0.5, -150, 0, 12),
        BackgroundTransparency = 1,
        ZIndex = 100,
    }, {
        Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Padding = UDim.new(0, 6),
        })
    })
end

local function Notify(message, notifType, duration)
    notifType = notifType or "info"
    duration  = duration  or 4

    local dotColor = ({
        info    = Theme.Accent,
        success = Theme.Green,
        warning = Theme.Yellow,
        error   = Theme.Red,
    })[notifType] or Theme.Accent

    local frame = Create("Frame", {
        Parent = NotifContainer,
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Theme.Raised,
        BackgroundTransparency = 0.05,
        ClipsDescendants = true,
    }, {
        MakeCorner(20),
        Create("UIStroke", { Color = Theme.Border, Transparency = 0.88, Thickness = 1 }),
        MakePadding(0, 14, 0, 10),
        Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8),
        }),
        Create("Frame", {
            Name = "Dot",
            Size = UDim2.new(0, 6, 0, 6),
            BackgroundColor3 = dotColor,
            ZIndex = 2,
        }, { MakeCorner(99) }),
        Create("TextLabel", {
            Name = "Message",
            Text = message,
            TextColor3 = Theme.Text,
            TextSize = 12,
            Font = Enum.Font.GothamMedium,
            Size = UDim2.new(1, -30, 1, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
        }),
    })

    -- slide in
    frame.Position = UDim2.new(0, 0, 0, -40)
    Tween(frame, { Position = UDim2.new(0, 0, 0, 0) }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    -- auto dismiss
    task.delay(duration, function()
        Tween(frame, { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 }, 0.2)
        task.wait(0.2)
        frame:Destroy()
    end)

    return frame
end

-- ── Window ────────────────────────────────────────────────────────────────
function UILibrary:CreateWindow(title, subtitle)
    title    = title    or "UI Library"
    subtitle = subtitle or "Working Example"

    -- ScreenGui
    local gui = Create("ScreenGui", {
        Name = title .. "_UILib",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        Parent = (pcall(function() return CoreGui end) and CoreGui) or LocalPlayer.PlayerGui,
    })

    InitNotifs(gui)

    -- ── Main Frame
    local PANEL_W, PANEL_H = 540, 520
    local main = Create("Frame", {
        Name = "MainPanel",
        Parent = gui,
        Size = UDim2.new(0, PANEL_W, 0, PANEL_H),
        Position = UDim2.new(0.5, -PANEL_W/2, 0.5, -PANEL_H/2),
        BackgroundColor3 = Theme.Panel,
    }, {
        MakeCorner(10),
        Create("UIStroke", { Color = Theme.Border, Transparency = 0.88, Thickness = 1 }),
    })

    -- open animation
    main.Size = UDim2.new(0, 0, 0, 0)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Tween(main, {
        Size = UDim2.new(0, PANEL_W, 0, PANEL_H),
        Position = UDim2.new(0.5, -PANEL_W/2, 0.5, -PANEL_H/2),
    }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    -- ── Title Bar
    local titleBar = Create("Frame", {
        Name = "TitleBar",
        Parent = main,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Color3.fromHex("ffffff"),
        BackgroundTransparency = 0.98,
        ZIndex = 2,
    }, {
        Create("UIStroke", { Color = Theme.Border, Transparency = 0.92, Thickness = 1 }),
        -- accent dot
        Create("Frame", {
            Name = "Dot",
            Size = UDim2.new(0, 7, 0, 7),
            Position = UDim2.new(0, 14, 0.5, -3.5),
            BackgroundColor3 = Theme.Accent,
        }, { MakeCorner(99) }),
        -- title
        Create("TextLabel", {
            Name = "Title",
            Text = title,
            TextColor3 = Theme.Text,
            TextSize = 13,
            Font = Enum.Font.GothamBold,
            Size = UDim2.new(0, 200, 1, 0),
            Position = UDim2.new(0, 28, 0, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
        }),
        -- subtitle
        Create("TextLabel", {
            Name = "Subtitle",
            Text = subtitle,
            TextColor3 = Theme.TextMuted,
            TextSize = 11,
            Font = Enum.Font.Gotham,
            Size = UDim2.new(0, 200, 1, 0),
            Position = UDim2.new(0, 120, 0, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
        }),
        -- close button
        Create("TextButton", {
            Name = "CloseBtn",
            Text = "×",
            TextColor3 = Theme.TextMuted,
            TextSize = 16,
            Font = Enum.Font.Gotham,
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(1, -32, 0.5, -12),
            BackgroundColor3 = Theme.Hover,
            BackgroundTransparency = 1,
        }, { MakeCorner(5) }),
    })

    -- drag
    local dragging, dragStart, startPos = false, nil, nil
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    -- close
    local closeBtn = titleBar:FindFirstChild("CloseBtn")
    closeBtn.MouseEnter:Connect(function()
        Tween(closeBtn, { BackgroundTransparency = 0.85, TextColor3 = Theme.Red }, 0.1)
    end)
    closeBtn.MouseLeave:Connect(function()
        Tween(closeBtn, { BackgroundTransparency = 1, TextColor3 = Theme.TextMuted }, 0.1)
    end)
    closeBtn.MouseButton1Click:Connect(function()
        Tween(main, { Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0) }, 0.25)
        task.wait(0.25)
        gui:Destroy()
    end)

    -- ── Sidebar
    local sidebar = Create("Frame", {
        Name = "Sidebar",
        Parent = main,
        Size = UDim2.new(0, 110, 1, -40),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundColor3 = Color3.fromHex("000000"),
        BackgroundTransparency = 0.85,
    }, {
        Create("UIStroke", { Color = Theme.Border, Transparency = 0.92, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
    })

    local tabList = Create("Frame", {
        Name = "TabList",
        Parent = sidebar,
        Size = UDim2.new(1, 0, 0, 400),
        Position = UDim2.new(0, 0, 0, 36),
        BackgroundTransparency = 1,
    }, {
        Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 1),
        })
    })

    -- home icon
    Create("TextLabel", {
        Parent = sidebar,
        Text = "⌂",
        TextColor3 = Theme.TextMuted,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 4),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Padding = UDim.new(0, 16),
    })

    -- user at bottom
    local userFrame = Create("Frame", {
        Name = "User",
        Parent = sidebar,
        Size = UDim2.new(1, 0, 0, 46),
        Position = UDim2.new(0, 0, 1, -46),
        BackgroundTransparency = 1,
    }, {
        Create("UIStroke", { Color = Theme.Border, Transparency = 0.92, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
        MakePadding(8, 14, 8, 14),
        Create("TextLabel", {
            Name = "Username",
            Text = LocalPlayer.DisplayName,
            TextColor3 = Theme.Text,
            TextSize = 10,
            Font = Enum.Font.GothamBold,
            Size = UDim2.new(1, 0, 0, 13),
            Position = UDim2.new(0, 30, 0, 10),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
        }),
        Create("TextLabel", {
            Name = "Handle",
            Text = "@" .. LocalPlayer.Name,
            TextColor3 = Theme.TextMuted,
            TextSize = 9,
            Font = Enum.Font.Gotham,
            Size = UDim2.new(1, 0, 0, 11),
            Position = UDim2.new(0, 30, 0, 24),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
        }),
    })

    -- ── Content Area
    local contentOuter = Create("Frame", {
        Name = "ContentOuter",
        Parent = main,
        Size = UDim2.new(1, -110, 1, -50),
        Position = UDim2.new(0, 110, 0, 40),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
    })

    local content = Create("ScrollingFrame", {
        Name = "Content",
        Parent = contentOuter,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Color3.fromHex("ffffff"),
        ScrollBarImageTransparency = 0.85,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, {
        MakePadding(14, 16, 14, 0),
        Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 3),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })

    -- status bar
    Create("Frame", {
        Name = "StatusBar",
        Parent = main,
        Size = UDim2.new(1, 0, 0, 22),
        Position = UDim2.new(0, 0, 1, -22),
        BackgroundColor3 = Color3.fromHex("000000"),
        BackgroundTransparency = 0.8,
    }, {
        Create("UIStroke", { Color = Theme.Border, Transparency = 0.92, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
        Create("TextLabel", {
            Text = "v1.0.0 · MIT License",
            TextColor3 = Theme.TextDim,
            TextSize = 9,
            Font = Enum.Font.Gotham,
            Size = UDim2.new(1, -20, 1, 0),
            Position = UDim2.new(0, 14, 0, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
        }),
    })

    -- ── Window API
    local Window = {}
    Window._gui       = gui
    Window._tabs      = {}
    Window._activeTab = nil
    Window._notify    = Notify
    Window._content   = content
    Window._tabList   = tabList

    function Window:Notify(msg, notifType, duration)
        Notify(msg, notifType, duration)
    end

    function Window:AddTab(name)
        -- sidebar button
        local tabBtn = Create("TextButton", {
            Name = name .. "Tab",
            Parent = tabList,
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
        })

        local indicator = Create("Frame", {
            Name = "Indicator",
            Parent = tabBtn,
            Size = UDim2.new(0, 2, 0.6, 0),
            Position = UDim2.new(0, 0, 0.2, 0),
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 1,
        }, { MakeCorner(2) })

        local dot = Create("Frame", {
            Name = "Dot",
            Parent = tabBtn,
            Size = UDim2.new(0, 4, 0, 4),
            Position = UDim2.new(1, -16, 0.5, -2),
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 1,
        }, { MakeCorner(99) })

        local label = Create("TextLabel", {
            Name = "Label",
            Parent = tabBtn,
            Text = name,
            TextColor3 = Theme.TextMuted,
            TextSize = 12,
            Font = Enum.Font.Gotham,
            Size = UDim2.new(1, -24, 1, 0),
            Position = UDim2.new(0, 12, 0, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
        })

        -- tab content frame
        local tabFrame = Create("Frame", {
            Name = name .. "Content",
            Parent = content,
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y,
            Visible = false,
        }, {
            Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                Padding = UDim.new(0, 3),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
        })

        local Tab = {}
        Tab._frame  = tabFrame
        Tab._btn    = tabBtn
        Tab._order  = 0
        Tab._window = Window

        local function activate()
            -- deactivate others
            for _, t in pairs(Window._tabs) do
                Tween(t._btn:FindFirstChild("Label"), { TextColor3 = Theme.TextMuted, Font = Enum.Font.Gotham }, 0.12)
                Tween(t._btn:FindFirstChild("Indicator"), { BackgroundTransparency = 1 }, 0.12)
                Tween(t._btn:FindFirstChild("Dot"), { BackgroundTransparency = 1 }, 0.12)
                t._btn.BackgroundTransparency = 1
                t._frame.Visible = false
            end
            -- activate this
            Tween(label, { TextColor3 = Theme.Text, Font = Enum.Font.GothamBold }, 0.12)
            Tween(indicator, { BackgroundTransparency = 0 }, 0.15)
            Tween(dot, { BackgroundTransparency = 0 }, 0.15)
            tabBtn.BackgroundColor3 = Theme.Accent
            tabBtn.BackgroundTransparency = 0.88
            tabFrame.Visible = true
            Window._activeTab = Tab
        end

        tabBtn.MouseButton1Click:Connect(activate)
        tabBtn.MouseEnter:Connect(function()
            if Window._activeTab ~= Tab then
                Tween(tabBtn, { BackgroundTransparency = 0.94 }, 0.1)
                tabBtn.BackgroundColor3 = Color3.fromHex("ffffff")
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if Window._activeTab ~= Tab then
                Tween(tabBtn, { BackgroundTransparency = 1 }, 0.1)
            end
        end)

        table.insert(Window._tabs, Tab)

        -- activate first tab automatically
        if #Window._tabs == 1 then
            task.defer(activate)
        end

        -- ── Tab Element Helpers ────────────────────────────────────────────

        local function SectionLabel(text)
            Tab._order += 1
            Create("TextLabel", {
                Name = "Section_" .. text,
                Parent = tabFrame,
                Text = text:upper(),
                TextColor3 = Theme.TextMuted,
                TextSize = 10,
                Font = Enum.Font.GothamBold,
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = Tab._order,
            }, { MakePadding(6, 0, 2, 0) })

            Create("Frame", {
                Name = "Divider",
                Parent = tabFrame,
                Size = UDim2.new(1, -16, 0, 1),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundColor3 = Theme.Border,
                BackgroundTransparency = 0.94,
                BorderSizePixel = 0,
                LayoutOrder = Tab._order,
            })
        end

        -- ── Button ────────────────────────────────────────────────────────
        function Tab:AddButton(text, sub, callback)
            if type(sub) == "function" then callback = sub; sub = nil end
            self._order += 1
            local row = Create("TextButton", {
                Name = "Button_" .. text,
                Parent = tabFrame,
                Size = UDim2.new(1, -16, 0, sub and 46 or 34),
                BackgroundColor3 = Theme.Raised,
                BackgroundTransparency = 0,
                Text = "",
                AutoButtonColor = false,
                LayoutOrder = self._order,
            }, {
                MakeCorner(6),
                Create("UIStroke", { Color = Theme.Border, Transparency = 0.92, Thickness = 1 }),
                Create("TextLabel", {
                    Name = "Label",
                    Text = text,
                    TextColor3 = Theme.Text,
                    TextSize = 12.5,
                    Font = Enum.Font.GothamMedium,
                    Size = UDim2.new(1, -30, 0, 18),
                    Position = UDim2.new(0, 12, 0, sub and 8 or 8),
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }),
            })

            if sub then
                Create("TextLabel", {
                    Parent = row,
                    Text = sub,
                    TextColor3 = Theme.TextMuted,
                    TextSize = 10.5,
                    Font = Enum.Font.Gotham,
                    Size = UDim2.new(1, -30, 0, 14),
                    Position = UDim2.new(0, 12, 0, 26),
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
            end

            row.MouseEnter:Connect(function() Tween(row, { BackgroundColor3 = Theme.Hover }, 0.1) end)
            row.MouseLeave:Connect(function() Tween(row, { BackgroundColor3 = Theme.Raised }, 0.1) end)
            row.MouseButton1Down:Connect(function() Tween(row, { BackgroundColor3 = Theme.Active }, 0.08) end)
            row.MouseButton1Up:Connect(function()
                Tween(row, { BackgroundColor3 = Theme.Hover }, 0.1)
                if callback then task.spawn(callback) end
            end)

            return row
        end

        -- ── Hold Button ───────────────────────────────────────────────────
        function Tab:AddHoldButton(text, sub, duration, callback)
            if type(sub) == "function" then callback = sub; sub = nil; duration = sub end
            duration = duration or 2
            self._order += 1

            local row = Create("TextButton", {
                Name = "HoldBtn_" .. text,
                Parent = tabFrame,
                Size = UDim2.new(1, -16, 0, sub and 46 or 34),
                BackgroundColor3 = Theme.Raised,
                Text = "",
                AutoButtonColor = false,
                ClipsDescendants = true,
                LayoutOrder = self._order,
            }, {
                MakeCorner(6),
                Create("UIStroke", { Color = Theme.Border, Transparency = 0.92, Thickness = 1 }),
            })

            local fill = Create("Frame", {
                Name = "Fill",
                Parent = row,
                Size = UDim2.new(0, 0, 1, 0),
                BackgroundColor3 = Theme.Accent,
                BackgroundTransparency = 0.85,
                BorderSizePixel = 0,
            })

            Create("TextLabel", {
                Parent = row,
                Text = text,
                TextColor3 = Theme.Text,
                TextSize = 12.5,
                Font = Enum.Font.GothamMedium,
                Size = UDim2.new(1, -60, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
            })

            local pctLabel = Create("TextLabel", {
                Parent = row,
                Text = "hold",
                TextColor3 = Theme.TextMuted,
                TextSize = 10,
                Font = Enum.Font.GothamBold,
                Size = UDim2.new(0, 50, 1, 0),
                Position = UDim2.new(1, -60, 0, 0),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Right,
            })

            local holding = false
            local connection

            row.MouseButton1Down:Connect(function()
                holding = true
                local startT = tick()
                connection = RunService.Heartbeat:Connect(function()
                    if not holding then connection:Disconnect(); return end
                    local elapsed = tick() - startT
                    local pct = math.min(elapsed / duration, 1)
                    fill.Size = UDim2.new(pct, 0, 1, 0)
                    pctLabel.Text = math.floor(pct * 100) .. "%"
                    if pct >= 1 then
                        connection:Disconnect()
                        holding = false
                        pctLabel.Text = "✓"
                        Tween(fill, { BackgroundColor3 = Theme.Green }, 0.2)
                        if callback then task.spawn(callback) end
                        task.wait(1.2)
                        Tween(fill, { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Accent }, 0.3)
                        pctLabel.Text = "hold"
                    end
                end)
            end)

            row.MouseButton1Up:Connect(function()
                if not holding then return end
                holding = false
                if connection then connection:Disconnect() end
                Tween(fill, { Size = UDim2.new(0, 0, 1, 0) }, 0.2)
                pctLabel.Text = "hold"
            end)

            return row
        end

        -- ── Toggle ────────────────────────────────────────────────────────
        function Tab:AddToggle(text, sub, default, callback)
            if type(sub) == "boolean" then callback = default; default = sub; sub = nil end
            default = default or false
            self._order += 1

            local state = default
            local row = Create("TextButton", {
                Name = "Toggle_" .. text,
                Parent = tabFrame,
                Size = UDim2.new(1, -16, 0, sub and 46 or 34),
                BackgroundColor3 = Theme.Panel,
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                LayoutOrder = self._order,
            }, { MakeCorner(6) })

            Create("TextLabel", {
                Parent = row,
                Text = text,
                TextColor3 = Theme.Text,
                TextSize = 12.5,
                Font = Enum.Font.GothamMedium,
                Size = UDim2.new(1, -60, 0, 18),
                Position = UDim2.new(0, 12, 0, sub and 8 or 8),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
            })

            -- pill
            local pill = Create("Frame", {
                Name = "Pill",
                Parent = row,
                Size = UDim2.new(0, 32, 0, 17),
                Position = UDim2.new(1, -44, 0.5, -8.5),
                BackgroundColor3 = state and Theme.Accent or Color3.fromHex("2e2e3a"),
            }, { MakeCorner(99) })

            local thumb = Create("Frame", {
                Name = "Thumb",
                Parent = pill,
                Size = UDim2.new(0, 11, 0, 11),
                Position = state
                    and UDim2.new(1, -13, 0.5, -5.5)
                    or  UDim2.new(0, 2,   0.5, -5.5),
                BackgroundColor3 = state and Color3.fromHex("ffffff") or Theme.TextMuted,
            }, { MakeCorner(99) })

            local function setToggle(newState)
                state = newState
                Tween(pill,  { BackgroundColor3 = state and Theme.Accent or Color3.fromHex("2e2e3a") }, 0.2)
                Tween(thumb, { BackgroundColor3 = state and Color3.fromHex("ffffff") or Theme.TextMuted }, 0.2)
                Tween(thumb, {
                    Position = state
                        and UDim2.new(1, -13, 0.5, -5.5)
                        or  UDim2.new(0, 2,   0.5, -5.5)
                }, 0.2, Enum.EasingStyle.Quart)
                if callback then task.spawn(callback, state) end
            end

            row.MouseEnter:Connect(function() Tween(row, { BackgroundTransparency = 0.94 }, 0.1); row.BackgroundColor3 = Color3.fromHex("ffffff") end)
            row.MouseLeave:Connect(function() Tween(row, { BackgroundTransparency = 1 }, 0.1) end)
            row.MouseButton1Click:Connect(function() setToggle(not state) end)

            return { SetValue = setToggle, GetValue = function() return state end }
        end

        -- ── Slider ────────────────────────────────────────────────────────
        function Tab:AddSlider(text, min, max, default, step, callback)
            min = min or 0; max = max or 100; default = default or min; step = step or 1
            self._order += 1

            local value = default
            local dragging = false

            local row = Create("Frame", {
                Name = "Slider_" .. text,
                Parent = tabFrame,
                Size = UDim2.new(1, -16, 0, 50),
                BackgroundColor3 = Theme.Panel,
                BackgroundTransparency = 1,
                LayoutOrder = self._order,
            }, { MakeCorner(6) })

            local labelEl = Create("TextLabel", {
                Parent = row,
                Text = text,
                TextColor3 = Theme.Text,
                TextSize = 12.5,
                Font = Enum.Font.GothamMedium,
                Size = UDim2.new(1, -60, 0, 18),
                Position = UDim2.new(0, 12, 0, 8),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
            })

            local valueLabel = Create("TextLabel", {
                Parent = row,
                Text = tostring(value),
                TextColor3 = Theme.Accent,
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                Size = UDim2.new(0, 50, 0, 18),
                Position = UDim2.new(1, -60, 0, 8),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Right,
            })

            local track = Create("Frame", {
                Name = "Track",
                Parent = row,
                Size = UDim2.new(1, -24, 0, 3),
                Position = UDim2.new(0, 12, 0, 36),
                BackgroundColor3 = Color3.fromHex("2e2e3a"),
            }, { MakeCorner(2) })

            local fill = Create("Frame", {
                Parent = track,
                Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
                BackgroundColor3 = Theme.Accent,
            }, { MakeCorner(2) })

            local thumb = Create("Frame", {
                Name = "Thumb",
                Parent = track,
                Size = UDim2.new(0, 11, 0, 11),
                Position = UDim2.new((value - min) / (max - min), -5.5, 0.5, -5.5),
                BackgroundColor3 = Color3.fromHex("ffffff"),
            }, {
                MakeCorner(99),
                Create("UIStroke", { Color = Theme.Accent, Thickness = 2 }),
            })

            local function updateSlider(inputPos)
                local trackPos = track.AbsolutePosition
                local trackSize = track.AbsoluteSize
                local pct = math.clamp((inputPos.X - trackPos.X) / trackSize.X, 0, 1)
                local raw = min + pct * (max - min)
                local stepped = math.round(raw / step) * step
                value = math.clamp(stepped, min, max)

                local newPct = (value - min) / (max - min)
                fill.Size = UDim2.new(newPct, 0, 1, 0)
                thumb.Position = UDim2.new(newPct, -5.5, 0.5, -5.5)
                valueLabel.Text = tostring(math.round(value * 100) / 100)
                if callback then task.spawn(callback, value) end
            end

            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    updateSlider(input.Position)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    updateSlider(input.Position)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            return {
                SetValue = function(v)
                    value = math.clamp(v, min, max)
                    local pct = (value - min) / (max - min)
                    fill.Size = UDim2.new(pct, 0, 1, 0)
                    thumb.Position = UDim2.new(pct, -5.5, 0.5, -5.5)
                    valueLabel.Text = tostring(value)
                end,
                GetValue = function() return value end,
            }
        end

        -- ── Dropdown ──────────────────────────────────────────────────────
        function Tab:AddDropdown(text, options, default, callback)
            self._order += 1
            local selected = default or options[1]

            local wrapper = Create("Frame", {
                Name = "Dropdown_" .. text,
                Parent = tabFrame,
                Size = UDim2.new(1, -16, 0, 56),
                BackgroundTransparency = 1,
                LayoutOrder = self._order,
                ClipsDescendants = false,
                ZIndex = 10,
            })

            Create("TextLabel", {
                Parent = wrapper,
                Text = text,
                TextColor3 = Theme.TextMuted,
                TextSize = 11,
                Font = Enum.Font.GothamMedium,
                Size = UDim2.new(1, 0, 0, 16),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
            })

            local btn = Create("TextButton", {
                Parent = wrapper,
                Size = UDim2.new(1, 0, 0, 34),
                Position = UDim2.new(0, 0, 0, 20),
                BackgroundColor3 = Theme.Raised,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 11,
            }, {
                MakeCorner(6),
                Create("UIStroke", { Color = Theme.Border, Transparency = 0.92, Thickness = 1 }),
                Create("TextLabel", {
                    Name = "SelLabel",
                    Text = selected,
                    TextColor3 = Theme.Text,
                    TextSize = 12.5,
                    Font = Enum.Font.GothamMedium,
                    Size = UDim2.new(1, -30, 1, 0),
                    Position = UDim2.new(0, 12, 0, 0),
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }),
                Create("TextLabel", {
                    Text = "▾",
                    TextColor3 = Theme.TextMuted,
                    TextSize = 12,
                    Font = Enum.Font.Gotham,
                    Size = UDim2.new(0, 20, 1, 0),
                    Position = UDim2.new(1, -24, 0, 0),
                    BackgroundTransparency = 1,
                }),
            })

            local dropList = nil
            local open = false

            btn.MouseButton1Click:Connect(function()
                if dropList then dropList:Destroy(); dropList = nil; open = false; return end
                open = true
                dropList = Create("Frame", {
                    Parent = wrapper,
                    Size = UDim2.new(1, 0, 0, #options * 32),
                    Position = UDim2.new(0, 0, 0, 54),
                    BackgroundColor3 = Theme.Raised,
                    ZIndex = 20,
                }, {
                    MakeCorner(6),
                    Create("UIStroke", { Color = Theme.Accent, Transparency = 0, Thickness = 1 }),
                    Create("UIListLayout", { FillDirection = Enum.FillDirection.Vertical }),
                })

                for _, opt in ipairs(options) do
                    local optBtn = Create("TextButton", {
                        Parent = dropList,
                        Size = UDim2.new(1, 0, 0, 32),
                        BackgroundColor3 = opt == selected and Theme.Accent or Theme.Raised,
                        BackgroundTransparency = opt == selected and 0.85 or 1,
                        Text = opt,
                        TextColor3 = opt == selected and Theme.Accent or Theme.Text,
                        TextSize = 12.5,
                        Font = Enum.Font.GothamMedium,
                        AutoButtonColor = false,
                        ZIndex = 21,
                    })
                    optBtn.MouseButton1Click:Connect(function()
                        selected = opt
                        btn:FindFirstChild("SelLabel").Text = selected
                        dropList:Destroy(); dropList = nil; open = false
                        if callback then task.spawn(callback, selected) end
                    end)
                end
            end)

            return {
                SetValue = function(v) selected = v; btn:FindFirstChild("SelLabel").Text = v end,
                GetValue = function() return selected end,
            }
        end

        -- ── TextBox ───────────────────────────────────────────────────────
        function Tab:AddTextBox(text, placeholder, callback)
            self._order += 1
            local wrapper = Create("Frame", {
                Name = "TextBox_" .. text,
                Parent = tabFrame,
                Size = UDim2.new(1, -16, 0, 56),
                BackgroundTransparency = 1,
                LayoutOrder = self._order,
            })

            Create("TextLabel", {
                Parent = wrapper,
                Text = text,
                TextColor3 = Theme.TextMuted,
                TextSize = 11,
                Font = Enum.Font.GothamMedium,
                Size = UDim2.new(1, 0, 0, 16),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
            })

            local box = Create("TextBox", {
                Parent = wrapper,
                Size = UDim2.new(1, 0, 0, 34),
                Position = UDim2.new(0, 0, 0, 20),
                BackgroundColor3 = Theme.Raised,
                Text = "",
                PlaceholderText = placeholder or "Enter value…",
                PlaceholderColor3 = Theme.TextMuted,
                TextColor3 = Theme.Text,
                TextSize = 12.5,
                Font = Enum.Font.GothamMedium,
                ClearTextOnFocus = false,
            }, {
                MakeCorner(6),
                Create("UIStroke", { Name="BoxStroke", Color = Theme.Border, Transparency = 0.92, Thickness = 1 }),
                MakePadding(0, 12, 0, 12),
            })

            box.Focused:Connect(function()
                Tween(box:FindFirstChild("BoxStroke"), { Color = Theme.Accent, Transparency = 0 }, 0.15)
            end)
            box.FocusLost:Connect(function(enter)
                Tween(box:FindFirstChild("BoxStroke"), { Color = Theme.Border, Transparency = 0.92 }, 0.15)
                if enter and callback then task.spawn(callback, box.Text) end
            end)

            return {
                SetValue = function(v) box.Text = v end,
                GetValue = function() return box.Text end,
            }
        end

        -- ── Section Label ─────────────────────────────────────────────────
        function Tab:AddSection(text)
            SectionLabel(text)
        end

        -- ── Separator ─────────────────────────────────────────────────────
        function Tab:AddSeparator()
            self._order += 1
            Create("Frame", {
                Parent = tabFrame,
                Size = UDim2.new(1, -16, 0, 1),
                BackgroundColor3 = Theme.Border,
                BackgroundTransparency = 0.92,
                BorderSizePixel = 0,
                LayoutOrder = self._order,
            })
        end

        return Tab
    end

    -- ── Toggle window visibility with keybind
    function Window:SetKeybind(keyCode)
        UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == keyCode then
                main.Visible = not main.Visible
            end
        end)
    end

    function Window:Destroy()
        gui:Destroy()
    end

    return Window
end

return UILibrary


--[[
═══════════════════════════════════════════════════════════
  USAGE EXAMPLE — paste into a LocalScript
═══════════════════════════════════════════════════════════

local UILib = require(game.ReplicatedStorage.UILibrary)
local Win   = UILib:CreateWindow("My Script", "v1.0.0")

Win:SetKeybind(Enum.KeyCode.RightShift)  -- toggle visibility

-- ── Buttons Tab ───────────────────────────────────────
local Buttons = Win:AddTab("Buttons")

Buttons:AddSection("Basic")

Buttons:AddButton("Simple Button", "Click to fire", function()
    print("Clicked!")
    Win:Notify("Button pressed", "info")
end)

Buttons:AddButton("Danger Button", function()
    Win:Notify("Danger triggered!", "error")
end)

Buttons:AddSeparator()
Buttons:AddSection("Hold")

Buttons:AddHoldButton("Hold Button", "Hold for 2 seconds", 2, function()
    print("Hold complete!")
    Win:Notify("Activated!", "success")
end)

-- ── Inputs Tab ────────────────────────────────────────
local Inputs = Win:AddTab("Inputs")

local speedToggle = Inputs:AddToggle("Speed Hack", "Enable walk speed modifier", false, function(val)
    if val then
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 100
    else
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 16
    end
end)

local speedSlider = Inputs:AddSlider("Walk Speed", 16, 100, 16, 1, function(val)
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = val
end)

Inputs:AddSeparator()

Inputs:AddDropdown("Game Mode", {"Default","Creative","Spectate"}, "Default", function(val)
    print("Mode:", val)
end)

Inputs:AddTextBox("Custom Message", "Type here…", function(text)
    print("Entered:", text)
end)

-- ── Visuals Tab ───────────────────────────────────────
local Visuals = Win:AddTab("Visuals")

Visuals:AddToggle("ESP", "Show player boxes", false, function(val)
    print("ESP:", val)
end)

Visuals:AddToggle("Fullbright", nil, false, function(val)
    game:GetService("Lighting").Brightness = val and 5 or 1
end)

-- ── Advanced Tab ──────────────────────────────────────
local Advanced = Win:AddTab("Advanced")

Advanced:AddSection("Danger Zone")
Advanced:AddToggle("Noclip", nil, false, function(val)
    print("Noclip:", val)
end)
Advanced:AddToggle("Infinite Jump", nil, false, function(val)
    print("InfJump:", val)
end)

Win:Notify("Script loaded!", "success", 3)

═══════════════════════════════════════════════════════════
]]
