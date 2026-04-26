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
    Accent      = Color3.fromHex("d946ef"),
    AccentLight = Color3.fromHex("e879f9"),
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
    local PANEL_W, PANEL_H = 620, 540
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
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = Color3.fromHex("ffffff"),
        BackgroundTransparency = 0.98,
        ZIndex = 2,
    }, {
        Create("UIStroke", { Color = Theme.Border, Transparency = 0.92, Thickness = 1 }),
        Create("TextLabel", {
            Name = "Title",
            Text = title,
            TextColor3 = Theme.Text,
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            Size = UDim2.new(0, 200, 1, 0),
            Position = UDim2.new(0, 16, 0, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
        }),
        Create("TextLabel", {
            Name = "Subtitle",
            Text = subtitle,
            TextColor3 = Theme.TextMuted,
            TextSize = 11,
            Font = Enum.Font.Gotham,
            Size = UDim2.new(0, 200, 1, 0),
            Position = UDim2.new(0, 16 + (#title * 8) + 8, 0, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
        }),
    })

    local iconRow = Create("Frame", {
        Name = "IconRow",
        Parent = titleBar,
        Size = UDim2.new(0, 188, 0, 28),
        Position = UDim2.new(1, -200, 0.5, -14),
        BackgroundTransparency = 1,
    }, {
        Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 4),
        })
    })

    local function makeIconBtn(name, glyph, glyphSize)
        return Create("TextButton", {
            Name = name,
            Parent = iconRow,
            Size = UDim2.new(0, 30, 0, 28),
            BackgroundColor3 = Color3.fromHex("ffffff"),
            BackgroundTransparency = 0.95,
            Text = glyph,
            TextColor3 = Theme.TextMuted,
            TextSize = glyphSize or 13,
            Font = Enum.Font.GothamBold,
            AutoButtonColor = false,
        }, {
            MakeCorner(7),
            Create("UIStroke", { Color = Theme.Border, Transparency = 0.92, Thickness = 1 }),
        })
    end

    local searchBtn   = makeIconBtn("SearchBtn",   "⌕", 14)
    local sparkleBtn  = makeIconBtn("SparkleBtn",  "✦", 12)
    local settingsBtn = makeIconBtn("SettingsBtn", "⚙", 13)
    local minBtn      = makeIconBtn("MinBtn",      "—", 11)
    local closeBtn    = makeIconBtn("CloseBtn",    "✕", 11)

    for _, b in ipairs({searchBtn, sparkleBtn, settingsBtn, minBtn, closeBtn}) do
        b.MouseEnter:Connect(function() Tween(b, { BackgroundTransparency = 0.88 }, 0.1); b.TextColor3 = Theme.Text end)
        b.MouseLeave:Connect(function() Tween(b, { BackgroundTransparency = 0.95 }, 0.1); b.TextColor3 = Theme.TextMuted end)
    end

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

    closeBtn.MouseButton1Click:Connect(function()
        Tween(main, { Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0) }, 0.25)
        task.wait(0.25)
        gui:Destroy()
    end)
    minBtn.MouseButton1Click:Connect(function()
        main.Visible = false
    end)

    -- ── Sidebar
    local SIDEBAR_W = 130
    local sidebar = Create("Frame", {
        Name = "Sidebar",
        Parent = main,
        Size = UDim2.new(0, SIDEBAR_W, 1, -44),
        Position = UDim2.new(0, 0, 0, 44),
        BackgroundColor3 = Color3.fromHex("000000"),
        BackgroundTransparency = 0.85,
    }, {
        Create("UIStroke", { Color = Theme.Border, Transparency = 0.92, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
    })

    -- home icon
    Create("TextLabel", {
        Parent = sidebar,
        Text = "⌂",
        TextColor3 = Theme.TextMuted,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        Size = UDim2.new(1, -28, 0, 30),
        Position = UDim2.new(0, 14, 0, 8),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local tabList = Create("Frame", {
        Name = "TabList",
        Parent = sidebar,
        Size = UDim2.new(1, -16, 1, -120),
        Position = UDim2.new(0, 8, 0, 50),
        BackgroundTransparency = 1,
    }, {
        Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 4),
        })
    })

    -- user at bottom (with avatar)
    local avatarUrl = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=60&h=60"
    local userFrame = Create("Frame", {
        Name = "User",
        Parent = sidebar,
        Size = UDim2.new(1, -16, 0, 50),
        Position = UDim2.new(0, 8, 1, -58),
        BackgroundTransparency = 1,
    }, {
        Create("ImageLabel", {
            Name = "Avatar",
            Image = avatarUrl,
            Size = UDim2.new(0, 32, 0, 32),
            Position = UDim2.new(0, 0, 0.5, -16),
            BackgroundColor3 = Theme.Raised,
            BorderSizePixel = 0,
        }, {
            MakeCorner(99),
            Create("UIStroke", { Color = Theme.Border, Transparency = 0.85, Thickness = 1 }),
            Create("Frame", {
                Name = "Status",
                Size = UDim2.new(0, 9, 0, 9),
                Position = UDim2.new(1, -9, 0, 0),
                BackgroundColor3 = Theme.Red,
                BorderSizePixel = 0,
                ZIndex = 3,
            }, {
                MakeCorner(99),
                Create("UIStroke", { Color = Theme.Panel, Thickness = 2 }),
            }),
        }),
        Create("TextLabel", {
            Name = "Username",
            Text = LocalPlayer.DisplayName,
            TextColor3 = Theme.Text,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            Size = UDim2.new(1, -40, 0, 14),
            Position = UDim2.new(0, 40, 0.5, -14),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }),
        Create("TextLabel", {
            Name = "Handle",
            Text = "@" .. LocalPlayer.Name,
            TextColor3 = Theme.TextMuted,
            TextSize = 10,
            Font = Enum.Font.Gotham,
            Size = UDim2.new(1, -40, 0, 12),
            Position = UDim2.new(0, 40, 0.5, 2),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }),
    })

    -- ── Content Area
    local contentOuter = Create("Frame", {
        Name = "ContentOuter",
        Parent = main,
        Size = UDim2.new(1, -SIDEBAR_W, 1, -44),
        Position = UDim2.new(0, SIDEBAR_W, 0, 44),
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
        MakePadding(16, 18, 44, 18),
        Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })

    -- floating clock + FPS pill (top-left of content)
    local statusPill = Create("Frame", {
        Name = "StatusPill",
        Parent = main,
        Size = UDim2.new(0, 116, 0, 24),
        Position = UDim2.new(0, SIDEBAR_W + 16, 1, -32),
        BackgroundColor3 = Theme.Raised,
        BackgroundTransparency = 0.1,
        ZIndex = 5,
    }, {
        MakeCorner(99),
        Create("UIStroke", { Color = Theme.Border, Transparency = 0.88, Thickness = 1 }),
        Create("TextLabel", {
            Name = "Clock",
            Text = "0:00",
            TextColor3 = Theme.TextMuted,
            TextSize = 10,
            Font = Enum.Font.GothamMedium,
            Size = UDim2.new(0, 36, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
        }),
        Create("Frame", {
            Size = UDim2.new(0, 1, 0, 10),
            Position = UDim2.new(0, 46, 0.5, -5),
            BackgroundColor3 = Theme.Border,
            BackgroundTransparency = 0.85,
            BorderSizePixel = 0,
        }),
        Create("TextLabel", {
            Name = "FPS",
            Text = "0 FPS",
            TextColor3 = Theme.Text,
            TextSize = 10,
            Font = Enum.Font.GothamBold,
            Size = UDim2.new(0, 50, 1, 0),
            Position = UDim2.new(0, 52, 0, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
        }),
        Create("Frame", {
            Size = UDim2.new(0, 6, 0, 6),
            Position = UDim2.new(1, -14, 0.5, -3),
            BackgroundColor3 = Theme.Green,
            BorderSizePixel = 0,
        }, { MakeCorner(99) }),
    })

    do
        local fpsCount, fpsAcc, fpsConn = 0, 0, nil
        local clockLbl = statusPill:FindFirstChild("Clock")
        local fpsLbl = statusPill:FindFirstChild("FPS")
        fpsConn = RunService.Heartbeat:Connect(function(dt)
            fpsAcc += dt; fpsCount += 1
            if fpsAcc >= 0.5 then
                fpsLbl.Text = math.floor(fpsCount / fpsAcc) .. " FPS"
                fpsAcc, fpsCount = 0, 0
                local h, m = math.floor(tick() % 86400 / 3600), math.floor(tick() % 3600 / 60)
                clockLbl.Text = string.format("%d:%02d", (h % 12 == 0) and 12 or h % 12, m)
            end
        end)
        gui.Destroying:Connect(function() if fpsConn then fpsConn:Disconnect() end end)
    end

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
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = Color3.fromHex("ffffff"),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
        }, {
            MakeCorner(7),
            Create("UIStroke", { Name = "TabStroke", Color = Theme.Border, Transparency = 1, Thickness = 1 }),
        })

        local dot = Create("Frame", {
            Name = "Dot",
            Parent = tabBtn,
            Size = UDim2.new(0, 6, 0, 6),
            Position = UDim2.new(1, -14, 0.5, -3),
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 1,
        }, { MakeCorner(99) })

        local label = Create("TextLabel", {
            Name = "Label",
            Parent = tabBtn,
            Text = name,
            TextColor3 = Theme.TextMuted,
            TextSize = 12,
            Font = Enum.Font.GothamMedium,
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
            for _, t in pairs(Window._tabs) do
                local lbl = t._btn:FindFirstChild("Label")
                lbl.Font = Enum.Font.GothamMedium
                Tween(lbl, { TextColor3 = Theme.TextMuted }, 0.12)
                Tween(t._btn:FindFirstChild("Dot"), { BackgroundTransparency = 1 }, 0.12)
                Tween(t._btn:FindFirstChild("TabStroke"), { Transparency = 1 }, 0.12)
                Tween(t._btn, { BackgroundTransparency = 1 }, 0.12)
                t._frame.Visible = false
            end
            label.Font = Enum.Font.GothamBold
            Tween(label, { TextColor3 = Theme.Text }, 0.12)
            Tween(dot, { BackgroundTransparency = 0 }, 0.15)
            Tween(tabBtn:FindFirstChild("TabStroke"), { Transparency = 0.85 }, 0.15)
            Tween(tabBtn, { BackgroundTransparency = 0.92 }, 0.15)
            tabFrame.Visible = true
            Window._activeTab = Tab
        end

        tabBtn.MouseButton1Click:Connect(activate)
        tabBtn.MouseEnter:Connect(function()
            if Window._activeTab ~= Tab then
                Tween(tabBtn, { BackgroundTransparency = 0.96 }, 0.1)
                Tween(tabBtn:FindFirstChild("Label"), { TextColor3 = Theme.Text }, 0.1)
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if Window._activeTab ~= Tab then
                Tween(tabBtn, { BackgroundTransparency = 1 }, 0.1)
                Tween(tabBtn:FindFirstChild("Label"), { TextColor3 = Theme.TextMuted }, 0.1)
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
                Text = text,
                TextColor3 = Theme.Text,
                TextSize = 16,
                Font = Enum.Font.GothamBold,
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
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
                Size = UDim2.new(1, 0, 0, sub and 56 or 44),
                BackgroundColor3 = Theme.Raised,
                BackgroundTransparency = 0,
                Text = "",
                AutoButtonColor = false,
                LayoutOrder = self._order,
            }, {
                MakeCorner(8),
                Create("UIStroke", { Color = Theme.Border, Transparency = 0.92, Thickness = 1 }),
                Create("TextLabel", {
                    Name = "Label",
                    Text = text,
                    TextColor3 = Theme.Text,
                    TextSize = 13,
                    Font = Enum.Font.GothamMedium,
                    Size = UDim2.new(1, -40, 0, 18),
                    Position = UDim2.new(0, 14, 0, sub and 10 or 13),
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }),
                Create("TextLabel", {
                    Name = "Chevron",
                    Text = "›",
                    TextColor3 = Theme.TextMuted,
                    TextSize = 18,
                    Font = Enum.Font.GothamBold,
                    Size = UDim2.new(0, 18, 1, 0),
                    Position = UDim2.new(1, -22, 0, -1),
                    BackgroundTransparency = 1,
                }),
            })

            if sub then
                Create("TextLabel", {
                    Parent = row,
                    Text = sub,
                    TextColor3 = Theme.TextMuted,
                    TextSize = 11,
                    Font = Enum.Font.Gotham,
                    Size = UDim2.new(1, -40, 0, 14),
                    Position = UDim2.new(0, 14, 0, 30),
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
            if type(sub) == "function" then callback = sub; sub = nil; duration = nil end
            if type(duration) == "function" then callback = duration; duration = nil end
            duration = duration or 2
            self._order += 1

            local row = Create("TextButton", {
                Name = "HoldBtn_" .. text,
                Parent = tabFrame,
                Size = UDim2.new(1, 0, 0, sub and 56 or 44),
                BackgroundColor3 = Theme.Raised,
                Text = "",
                AutoButtonColor = false,
                ClipsDescendants = true,
                LayoutOrder = self._order,
            }, {
                MakeCorner(8),
                Create("UIStroke", { Color = Theme.Border, Transparency = 0.92, Thickness = 1 }),
            })

            local fill = Create("Frame", {
                Name = "Fill",
                Parent = row,
                Size = UDim2.new(0, 0, 1, 0),
                BackgroundColor3 = Theme.Accent,
                BackgroundTransparency = 0.78,
                BorderSizePixel = 0,
            })

            Create("TextLabel", {
                Parent = row,
                Text = text,
                TextColor3 = Theme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                Size = UDim2.new(1, -60, 0, 18),
                Position = UDim2.new(0, 14, 0, sub and 10 or 13),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
            })

            if sub then
                Create("TextLabel", {
                    Parent = row,
                    Text = sub,
                    TextColor3 = Theme.TextMuted,
                    TextSize = 11,
                    Font = Enum.Font.Gotham,
                    Size = UDim2.new(1, -60, 0, 14),
                    Position = UDim2.new(0, 14, 0, 30),
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
            end

            local pctLabel = Create("TextLabel", {
                Parent = row,
                Text = "⊙",
                TextColor3 = Theme.TextMuted,
                TextSize = 16,
                Font = Enum.Font.GothamBold,
                Size = UDim2.new(0, 30, 1, 0),
                Position = UDim2.new(1, -36, 0, 0),
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
                    pctLabel.Text = pct < 1 and (math.floor(pct * 100) .. "%") or "✓"
                    if pct >= 1 then
                        connection:Disconnect()
                        holding = false
                        Tween(fill, { BackgroundColor3 = Theme.Green }, 0.2)
                        if callback then task.spawn(callback) end
                        task.wait(1.2)
                        Tween(fill, { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Accent }, 0.3)
                        pctLabel.Text = "⊙"
                    end
                end)
            end)

            row.MouseButton1Up:Connect(function()
                if not holding then return end
                holding = false
                if connection then connection:Disconnect() end
                Tween(fill, { Size = UDim2.new(0, 0, 1, 0) }, 0.2)
                pctLabel.Text = "⊙"
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
                Size = UDim2.new(1, 0, 0, sub and 56 or 44),
                BackgroundColor3 = Theme.Raised,
                BackgroundTransparency = 0,
                Text = "",
                AutoButtonColor = false,
                LayoutOrder = self._order,
            }, {
                MakeCorner(8),
                Create("UIStroke", { Color = Theme.Border, Transparency = 0.92, Thickness = 1 }),
            })

            Create("TextLabel", {
                Parent = row,
                Text = text,
                TextColor3 = Theme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                Size = UDim2.new(1, -60, 0, 18),
                Position = UDim2.new(0, 14, 0, sub and 10 or 13),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
            })

            if sub then
                Create("TextLabel", {
                    Parent = row,
                    Text = sub,
                    TextColor3 = Theme.TextMuted,
                    TextSize = 11,
                    Font = Enum.Font.Gotham,
                    Size = UDim2.new(1, -60, 0, 14),
                    Position = UDim2.new(0, 14, 0, 30),
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
            end

            local pill = Create("Frame", {
                Name = "Pill",
                Parent = row,
                Size = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new(1, -28, 0.5, -7),
                BackgroundColor3 = state and Theme.Accent or Color3.fromHex("2e2e3a"),
                BackgroundTransparency = state and 0 or 0,
            }, {
                MakeCorner(99),
                Create("UIStroke", { Name = "PillStroke", Color = state and Theme.Accent or Theme.TextMuted, Transparency = state and 0 or 0.4, Thickness = 1 }),
            })

            local thumb = Create("Frame", {
                Name = "Thumb",
                Parent = pill,
                Size = UDim2.new(0, 6, 0, 6),
                Position = UDim2.new(0.5, -3, 0.5, -3),
                BackgroundColor3 = state and Color3.fromHex("ffffff") or Theme.TextMuted,
                BackgroundTransparency = state and 0 or 1,
            }, { MakeCorner(99) })

            local function setToggle(newState)
                state = newState
                Tween(pill, { BackgroundColor3 = state and Theme.Accent or Color3.fromHex("2e2e3a") }, 0.2)
                Tween(pill:FindFirstChild("PillStroke"), { Color = state and Theme.Accent or Theme.TextMuted, Transparency = state and 0 or 0.4 }, 0.2)
                Tween(thumb, { BackgroundTransparency = state and 0 or 1 }, 0.2)
                if callback then task.spawn(callback, state) end
            end

            row.MouseEnter:Connect(function() Tween(row, { BackgroundColor3 = Theme.Hover }, 0.1) end)
            row.MouseLeave:Connect(function() Tween(row, { BackgroundColor3 = Theme.Raised }, 0.1) end)
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
                Size = UDim2.new(1, 0, 0, 60),
                BackgroundColor3 = Theme.Raised,
                BackgroundTransparency = 0,
                LayoutOrder = self._order,
            }, {
                MakeCorner(8),
                Create("UIStroke", { Color = Theme.Border, Transparency = 0.92, Thickness = 1 }),
            })

            local _ = Create("TextLabel", {
                Parent = row,
                Text = text,
                TextColor3 = Theme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                Size = UDim2.new(1, -70, 0, 18),
                Position = UDim2.new(0, 14, 0, 10),
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
                Position = UDim2.new(1, -60, 0, 10),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Right,
            })

            local track = Create("Frame", {
                Name = "Track",
                Parent = row,
                Size = UDim2.new(1, -28, 0, 3),
                Position = UDim2.new(0, 14, 0, 42),
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

        -- ── Dropdown ─────────────────────────────────────────────────────
        local function buildDropdown(text, options, default, multi, placeholder, callback)
            Tab._order += 1
            local selected = multi and (type(default) == "table" and default or {}) or (default or nil)
            local function display()
                if multi then
                    if #selected == 0 then return placeholder or "Pick many..." end
                    return table.concat(selected, ", ")
                end
                return selected or (placeholder or "Pick one...")
            end

            local wrapper = Create("Frame", {
                Name = "Dropdown_" .. text,
                Parent = tabFrame,
                Size = UDim2.new(1, 0, 0, 70),
                BackgroundColor3 = Theme.Raised,
                BackgroundTransparency = 0,
                LayoutOrder = Tab._order,
                ClipsDescendants = false,
                ZIndex = 10,
            }, {
                MakeCorner(8),
                Create("UIStroke", { Color = Theme.Border, Transparency = 0.92, Thickness = 1 }),
            })

            Create("TextLabel", {
                Parent = wrapper,
                Text = text,
                TextColor3 = Theme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                Size = UDim2.new(1, -28, 0, 18),
                Position = UDim2.new(0, 14, 0, 10),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
            })

            local btn = Create("TextButton", {
                Parent = wrapper,
                Size = UDim2.new(1, -20, 0, 30),
                Position = UDim2.new(0, 10, 0, 32),
                BackgroundColor3 = Theme.Hover,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 11,
            }, {
                MakeCorner(6),
                Create("UIStroke", { Color = Theme.Border, Transparency = 0.92, Thickness = 1 }),
                Create("TextLabel", {
                    Name = "SelLabel",
                    Text = display(),
                    TextColor3 = (multi and #selected == 0) or (not multi and not selected) and Theme.TextMuted or Theme.Text,
                    TextSize = 12,
                    Font = Enum.Font.GothamMedium,
                    Size = UDim2.new(1, -34, 1, 0),
                    Position = UDim2.new(0, 12, 0, 0),
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                }),
                Create("TextLabel", {
                    Name = "Arrow",
                    Text = "▾",
                    TextColor3 = Theme.TextMuted,
                    TextSize = 12,
                    Font = Enum.Font.GothamBold,
                    Size = UDim2.new(0, 20, 1, 0),
                    Position = UDim2.new(1, -26, 0, 0),
                    BackgroundTransparency = 1,
                }),
            })

            local function refreshLabel()
                local lbl = btn:FindFirstChild("SelLabel")
                lbl.Text = display()
                local empty = (multi and #selected == 0) or (not multi and not selected)
                lbl.TextColor3 = empty and Theme.TextMuted or Theme.Text
            end

            local dropList
            local function close()
                if dropList then dropList:Destroy(); dropList = nil end
                Tween(btn:FindFirstChild("Arrow"), { Rotation = 0 }, 0.15)
            end

            btn.MouseButton1Click:Connect(function()
                if dropList then close(); return end
                Tween(btn:FindFirstChild("Arrow"), { Rotation = 180 }, 0.15)
                local h = math.min(#options, 6) * 30 + 8
                dropList = Create("Frame", {
                    Parent = wrapper,
                    Size = UDim2.new(1, -20, 0, h),
                    Position = UDim2.new(0, 10, 0, 68),
                    BackgroundColor3 = Theme.Raised,
                    ZIndex = 30,
                }, {
                    MakeCorner(8),
                    Create("UIStroke", { Color = Theme.Accent, Transparency = 0.4, Thickness = 1 }),
                    MakePadding(4, 4, 4, 4),
                })
                local scroll = Create("ScrollingFrame", {
                    Parent = dropList,
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ScrollBarThickness = 2,
                    ScrollBarImageColor3 = Theme.TextMuted,
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ZIndex = 31,
                }, { Create("UIListLayout", { Padding = UDim.new(0, 2) }) })

                for _, opt in ipairs(options) do
                    local isSel = multi and table.find(selected, opt) ~= nil or (not multi and selected == opt)
                    local optBtn = Create("TextButton", {
                        Parent = scroll,
                        Size = UDim2.new(1, -2, 0, 28),
                        BackgroundColor3 = isSel and Theme.Accent or Theme.Hover,
                        BackgroundTransparency = isSel and 0.8 or 1,
                        Text = opt,
                        TextColor3 = isSel and Theme.Accent or Theme.Text,
                        TextSize = 12,
                        Font = Enum.Font.GothamMedium,
                        AutoButtonColor = false,
                        ZIndex = 32,
                    }, { MakeCorner(6) })
                    optBtn.MouseEnter:Connect(function() if not isSel then Tween(optBtn, { BackgroundTransparency = 0 }, 0.08) end end)
                    optBtn.MouseLeave:Connect(function() if not isSel then Tween(optBtn, { BackgroundTransparency = 1 }, 0.08) end end)
                    optBtn.MouseButton1Click:Connect(function()
                        if multi then
                            local idx = table.find(selected, opt)
                            if idx then table.remove(selected, idx) else table.insert(selected, opt) end
                            isSel = not isSel
                            optBtn.BackgroundColor3 = isSel and Theme.Accent or Theme.Hover
                            optBtn.BackgroundTransparency = isSel and 0.8 or 1
                            optBtn.TextColor3 = isSel and Theme.Accent or Theme.Text
                            refreshLabel()
                            if callback then task.spawn(callback, selected) end
                        else
                            selected = opt
                            refreshLabel()
                            close()
                            if callback then task.spawn(callback, selected) end
                        end
                    end)
                end
            end)

            return {
                SetValue = function(v) selected = v; refreshLabel() end,
                GetValue = function() return selected end,
                Close = close,
            }
        end

        function Tab:AddDropdown(text, options, default, callback)
            return buildDropdown(text, options, default, false, nil, callback)
        end

        function Tab:AddMultiDropdown(text, options, default, callback)
            return buildDropdown(text, options, default, true, nil, callback)
        end

        -- ── TextBox ──────────────────────────────────────────────────────
        function Tab:AddTextBox(text, placeholder, callback)
            self._order += 1
            local wrapper = Create("Frame", {
                Name = "TextBox_" .. text,
                Parent = tabFrame,
                Size = UDim2.new(1, 0, 0, 70),
                BackgroundColor3 = Theme.Raised,
                BackgroundTransparency = 0,
                LayoutOrder = self._order,
            }, {
                MakeCorner(8),
                Create("UIStroke", { Color = Theme.Border, Transparency = 0.92, Thickness = 1 }),
            })

            Create("TextLabel", {
                Parent = wrapper,
                Text = text,
                TextColor3 = Theme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                Size = UDim2.new(1, -28, 0, 18),
                Position = UDim2.new(0, 14, 0, 10),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
            })

            local box = Create("TextBox", {
                Parent = wrapper,
                Size = UDim2.new(1, -20, 0, 30),
                Position = UDim2.new(0, 10, 0, 32),
                BackgroundColor3 = Theme.Hover,
                Text = "",
                PlaceholderText = placeholder or "Enter value...",
                PlaceholderColor3 = Theme.TextMuted,
                TextColor3 = Theme.Text,
                TextSize = 12,
                Font = Enum.Font.GothamMedium,
                ClearTextOnFocus = false,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, {
                MakeCorner(6),
                Create("UIStroke", { Name = "BoxStroke", Color = Theme.Border, Transparency = 0.92, Thickness = 1 }),
                MakePadding(0, 50, 0, 12),
                Create("TextLabel", {
                    Name = "EnterHint",
                    Text = "Enter",
                    TextColor3 = Theme.TextMuted,
                    TextSize = 11,
                    Font = Enum.Font.GothamMedium,
                    Size = UDim2.new(0, 40, 1, 0),
                    Position = UDim2.new(1, -44, 0, 0),
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Right,
                }),
            })

            box.Focused:Connect(function()
                Tween(box:FindFirstChild("BoxStroke"), { Color = Theme.Accent, Transparency = 0.2 }, 0.15)
                Tween(box:FindFirstChild("EnterHint"), { TextColor3 = Theme.Accent }, 0.15)
            end)
            box.FocusLost:Connect(function(enter)
                Tween(box:FindFirstChild("BoxStroke"), { Color = Theme.Border, Transparency = 0.92 }, 0.15)
                Tween(box:FindFirstChild("EnterHint"), { TextColor3 = Theme.TextMuted }, 0.15)
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

        -- ── Separator ────────────────────────────────────────────────────
        function Tab:AddSeparator()
            self._order += 1
            Create("Frame", {
                Parent = tabFrame,
                Size = UDim2.new(1, 0, 0, 1),
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
