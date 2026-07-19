--[[
    ADONIS BYPASS MODULE (Standalone & Stable)
]]

local AdonisBypass = {}
AdonisBypass.Active = false

local function resolveAdonisEnv()
    local gc = getgc or (debug and debug.getgc)
    local hookf = hookfunction
    local env = getrenv
    local renv = nil
    if type(env) == "function" then
        pcall(function() renv = env() end)
    end
    local dbgInfo = (type(renv) == "table" and renv.debug and renv.debug.info) or (debug and debug.info)
    local newcc = newcclosure or function(fn) return fn end
    local typeOf = typeof or function(value) return type(value) end

    if not (type(gc) == "function" and type(hookf) == "function") then
        warn("[AdonisBypass] Missing required exploit funcs")
        return nil
    end

    return {
        gc = gc,
        hookf = hookf,
        env = env,
        dbgInfo = dbgInfo,
        newcc = newcc,
        typeOf = typeOf
    }
end

local function eachAdonisGc(env, fn)
    local ok, list = pcall(env.gc, true)
    if not ok or type(list) ~= "table" then return false end
    for _, value in next, list do
        if fn(value) then return true end
    end
    return false
end

local function detectAdonis(env)
    local found = false
    eachAdonisGc(env, function(value)
        if env.typeOf(value) == "table" then
            local hasDetected = env.typeOf(rawget(value, "Detected")) == "function"
            local hasKill = env.typeOf(rawget(value, "Kill")) == "function"
            local hasVars = rawget(value, "Variables") ~= nil
            local hasProcess = rawget(value, "Process") ~= nil
            if hasDetected or (hasKill and hasVars and hasProcess) then
                found = true
                return true
            end
        end
    end)
    return found
end

local function bypassAdonis(env)
    local DetectedMeth, KillMeth
    eachAdonisGc(env, function(value)
        if env.typeOf(value) == "table" then
            local detected = rawget(value, "Detected")
            local kill = rawget(value, "Kill")
            if env.typeOf(detected) == "function" and not DetectedMeth then
                DetectedMeth = detected
                pcall(function()
                    env.hookf(DetectedMeth, function()
                        return true
                    end)
                end)
            end
            if rawget(value, "Variables") and rawget(value, "Process") and env.typeOf(kill) == "function" and not KillMeth then
                KillMeth = kill
                pcall(function()
                    env.hookf(KillMeth, function()
                    end)
                end)
            end
            if DetectedMeth and KillMeth then return true end
        end
    end)

    if DetectedMeth and env.dbgInfo then
        local oldDbgInfo
        pcall(function()
            oldDbgInfo = env.hookf(env.dbgInfo, env.newcc(function(...)
                local functionName = ...
                if functionName == DetectedMeth then
                    return coroutine.yield(coroutine.running())
                end
                return oldDbgInfo(...)
            end))
        end)
    end
    return DetectedMeth ~= nil
end

function AdonisBypass.Run(force)
    if AdonisBypass.Active and not force then return true end
    local env = resolveAdonisEnv()
    if not env then return false end
    local ok, detected = pcall(detectAdonis, env)
    if ok and detected then
        local bypassOk = pcall(bypassAdonis, env)
        if bypassOk then
            AdonisBypass.Active = true
            _G.RakeAdonisBypassed = true
            print("[AdonisBypass] Successfully bypassed")
            return true
        end
    end
    return false
end

task.defer(AdonisBypass.Run)

--// ============================================================
--// Rake Remastered | Floppa HUB — Full Build
--// ============================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local plr = Players.LocalPlayer
local pg = plr:WaitForChild("PlayerGui")

if pg:FindFirstChild("RakeUI") then
    return
end

local T = {
    Bg = Color3.fromRGB(20, 20, 25),
    Surf = Color3.fromRGB(30, 30, 38),
    SurfH = Color3.fromRGB(40, 40, 50),
    Acc = Color3.fromRGB(130, 80, 255),
    Acc2 = Color3.fromRGB(170, 110, 255),
    Txt = Color3.fromRGB(235, 235, 240),
    Dim = Color3.fromRGB(140, 140, 150),
    Bord = Color3.fromRGB(50, 50, 60),
    Suc = Color3.fromRGB(70, 210, 110),
    Dan = Color3.fromRGB(230, 70, 70)
}

local function new(c, p, a)
    local o = Instance.new(c, p)
    for k, v in pairs(a or {}) do o[k] = v end
    return o
end

local function tw(o, t, p)
    local tween = TweenService:Create(o, TweenInfo.new(t[1], t[2] or Enum.EasingStyle.Quad, t[3] or Enum.EasingDirection.Out), p)
    tween:Play()
    return tween
end

local sg = new("ScreenGui", pg, {Name = "RakeUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})

local savedW, savedH = 420, 280
local savedPos = UDim2.new(0.5, -210, 0.5, -140)
local open = false
local currentTween = nil

local tb = new("Frame", sg, {
    Name = "ToggleBtn",
    Size = UDim2.new(0, 50, 0, 28),
    Position = UDim2.new(0, 15, 0.5, -14),
    BackgroundColor3 = T.Acc,
    BorderSizePixel = 0,
    ZIndex = 100,
    Active = true
})
new("UICorner", tb, {CornerRadius = UDim.new(0, 6)})

new("TextLabel", tb, {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "Menu",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    ZIndex = 101
})

tb.MouseEnter:Connect(function() tw(tb, {0.2}, {BackgroundColor3 = T.Acc2}) end)
tb.MouseLeave:Connect(function() tw(tb, {0.2}, {BackgroundColor3 = T.Acc}) end)

local mf = new("CanvasGroup", sg, {
    Name = "MainFrame",
    Size = UDim2.new(0, savedW, 0, savedH),
    Position = savedPos,
    BackgroundColor3 = T.Bg,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 50
})
new("UICorner", mf, {CornerRadius = UDim.new(0, 10)})
new("UIStroke", mf, {Color = T.Bord, Thickness = 1})

local tbar = new("Frame", mf, {
    Size = UDim2.new(1, 0, 0, 32),
    BackgroundColor3 = T.Surf,
    BorderSizePixel = 0,
    ZIndex = 51
})

new("TextLabel", tbar, {
    Size = UDim2.new(1, -70, 1, 0),
    Position = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    Text = "Rake Remastered | Floppa HUB",
    TextColor3 = T.Txt,
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 52
})

local closeBtn = new("TextButton", tbar, {
    Size = UDim2.new(0, 26, 0, 26),
    Position = UDim2.new(1, -32, 0, 3),
    BackgroundColor3 = T.Dan,
    Text = "X",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    ZIndex = 52
})
new("UICorner", closeBtn, {CornerRadius = UDim.new(0, 6)})

local rh = new("TextButton", mf, {
    Name = "ResizeHandle",
    Size = UDim2.new(0, 24, 0, 24),
    Position = UDim2.new(1, -24, 1, -24),
    BackgroundColor3 = T.Acc,
    Text = "↘",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    ZIndex = 100,
    AutoButtonColor = false
})
new("UICorner", rh, {CornerRadius = UDim.new(0, 6)})

local lp = new("Frame", mf, {
    Size = UDim2.new(0, 120, 1, -32),
    Position = UDim2.new(0, 0, 0, 32),
    BackgroundColor3 = T.Surf,
    BorderSizePixel = 0,
    ZIndex = 51
})

local ls = new("ScrollingFrame", lp, {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = T.Acc,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollingDirection = Enum.ScrollingDirection.Y,
    ZIndex = 52
})
new("UIPadding", ls, {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6)})
local ll = new("UIListLayout", ls, {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder})

local rp = new("Frame", mf, {
    Size = UDim2.new(1, -120, 1, -32),
    Position = UDim2.new(0, 120, 0, 32),
    BackgroundColor3 = T.Bg,
    BorderSizePixel = 0,
    ZIndex = 51
})

local rs = new("ScrollingFrame", rp, {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = T.Acc,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollingDirection = Enum.ScrollingDirection.Y,
    ZIndex = 52
})
new("UIPadding", rs, {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10)})
local rl = new("UIListLayout", rs, {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder})

local tabs = {}
local curTab = nil

local function mkTab(name)
    local btn = new("TextButton", ls, {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = T.Surf,
        Text = "",
        LayoutOrder = #tabs + 1,
        ZIndex = 53
    })
    new("UICorner", btn, {CornerRadius = UDim.new(0, 6)})

    local lbl = new("TextLabel", btn, {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = T.Dim,
        TextSize = 12,
        Font = Enum.Font.GothamSemibold,
        ZIndex = 54
    })

    local cnt = new("Frame", rs, {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        LayoutOrder = #tabs + 1,
        ZIndex = 53,
        Visible = false
    })
    local cl = new("UIListLayout", cnt, {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder})

    cl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        cnt.Size = UDim2.new(1, 0, 0, cl.AbsoluteContentSize.Y + 10)
    end)

    local function activate()
        if curTab == cnt then return end
        if curTab then curTab.Visible = false end
        for _, v in ipairs(tabs) do
            tw(v.btn, {0.2}, {BackgroundColor3 = T.Surf})
            v.lbl.TextColor3 = T.Dim
        end
        curTab = cnt
        cnt.Visible = true
        tw(btn, {0.2}, {BackgroundColor3 = T.Acc})
        lbl.TextColor3 = Color3.new(1, 1, 1)
    end

    btn.MouseButton1Click:Connect(activate)
    btn.MouseEnter:Connect(function() if curTab ~= cnt then tw(btn, {0.15}, {BackgroundColor3 = T.SurfH}) end end)
    btn.MouseLeave:Connect(function() if curTab ~= cnt then tw(btn, {0.15}, {BackgroundColor3 = T.Surf}) end end)

    table.insert(tabs, {btn = btn, cnt = cnt, lbl = lbl})
    if #tabs == 1 then task.delay(0.1, activate) end
    return cnt
end

local function mkTog(p, text, def, cb)
    local f = new("Frame", p, {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, ZIndex = 55})
    new("TextLabel", f, {Size = UDim2.new(1, -50, 1, 0), BackgroundTransparency = 1, Text = text, TextColor3 = T.Txt, TextSize = 12, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 56})

    local bg = new("Frame", f, {Size = UDim2.new(0, 38, 0, 18), Position = UDim2.new(1, -44, 0.5, -9), BackgroundColor3 = def and T.Suc or T.Bord, BorderSizePixel = 0, ZIndex = 56})
    new("UICorner", bg, {CornerRadius = UDim.new(1, 0)})
    local kn = new("Frame", bg, {Size = UDim2.new(0, 14, 0, 14), Position = def and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 57})
    new("UICorner", kn, {CornerRadius = UDim.new(1, 0)})

    local en = def
    bg.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            en = not en
            tw(bg, {0.2}, {BackgroundColor3 = en and T.Suc or T.Bord})
            tw(kn, {0.2}, {Position = en and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)})
            if cb then pcall(cb, en) end
        end
    end)
end

local function mkBtn(p, text, cb)
    local b = new("TextButton", p, {Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = T.Acc, Text = text, TextColor3 = Color3.new(1, 1, 1), TextSize = 12, Font = Enum.Font.GothamBold, ZIndex = 55})
    new("UICorner", b, {CornerRadius = UDim.new(0, 6)})
    b.MouseEnter:Connect(function() tw(b, {0.15}, {BackgroundColor3 = T.Acc2}) end)
    b.MouseLeave:Connect(function() tw(b, {0.15}, {BackgroundColor3 = T.Acc}) end)
    b.MouseButton1Click:Connect(function() if cb then pcall(cb) end end)
end

--// ============================================================
--// CONTENT
--// ============================================================

--// === TAB: ESP ===
local t1 = mkTab("ESP")

local espData = {
    flags = {},
    ec = {},
    items = {scrap={}, flare={}, supply={}, locs={}, traps={}},
    lastS = 0,
    conn = nil
}

local function espClr(o)
    if espData.ec[o] then
        if espData.ec[o].bb then espData.ec[o].bb:Destroy() end
        espData.ec[o] = nil
    end
end

local function applyESP(o, col, txt, key)
    if not o or not espData.flags[key] then
        espClr(o)
        return
    end
    local tp = o:IsA("Model") and (o:FindFirstChild("Head") or o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart")) or (o:IsA("BasePart") and o)
    if not tp then return end
    local cc = espData.ec[o]
    if not cc then
        local b = Instance.new("BillboardGui")
        b.Name = "HubESP_Text"
        b.Size = UDim2.new(0, 140, 0, 25)
        b.AlwaysOnTop = true
        b.StudsOffset = Vector3.new(0, 2.5, 0)
        b.Parent = tp
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 1, 0)
        l.BackgroundTransparency = 1
        l.TextColor3 = col
        l.TextSize = 11
        l.Font = Enum.Font.SourceSansBold
        l.Parent = b
        cc = {bb = b, tl = l}
        espData.ec[o] = cc
    end
    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
        cc.tl.Text = txt .. " [" .. math.floor((plr.Character.HumanoidRootPart.Position - tp.Position).Magnitude) .. "m]"
    end
end

local function fullScan()
    local oldSupply = espData.items.supply or {}
    espData.items = {scrap={}, flare={}, supply={}, locs={}, traps={}}

    local WS = game:GetService("Workspace")
    local filter = WS:FindFirstChild("Filter")
    if filter then
        local ss = filter:FindFirstChild("ScrapSpawns")
        if ss then
            for _, spawn in ipairs(ss:GetChildren()) do
                for _, item in ipairs(spawn:GetChildren()) do
                    if item.Name:sub(1,5) == "Scrap" and item:IsA("Model") then
                        local lv = item:FindFirstChild("LevelVal")
                        local lvl = lv and lv.Value or "N/A"
                        table.insert(espData.items.scrap, {o=item, t="Scrap [Lvl: "..lvl.."]"})
                    end
                end
            end
        end
    end

    local deb = WS:FindFirstChild("Debris")
    local rawSupply = {}

    if deb then
        local scFolder = deb:FindFirstChild("SupplyCrates")
        if scFolder then
            for _, sc in ipairs(scFolder:GetChildren()) do
                if sc.Name == "SupplyCrate" then
                    local b = sc:FindFirstChild("Box") or sc:FindFirstChildWhichIsA("BasePart", true)
                    if b then table.insert(rawSupply, b) end
                elseif sc.Name == "Box" then
                    table.insert(rawSupply, sc)
                end
            end
        end
        local trapsFolder = deb:FindFirstChild("Traps")
        if trapsFolder then
            for _, trap in ipairs(trapsFolder:GetChildren()) do
                if trap.Name == "RakeTrapModel" or trap.Name:lower():match("trap") then
                    table.insert(espData.items.traps, {o=trap, t="Trap", c=Color3.fromRGB(255,140,0)})
                end
            end
        end
    end

    for _, o in ipairs(WS:GetChildren()) do
        if o.Name == "FlareGun" or (o.Name:lower():match("flare") and o.Name:lower():match("gun")) then
            table.insert(espData.items.flare, o)
        end
        if o.Name == "SupplyCrate" then
            local b = o:FindFirstChild("Box") or o:FindFirstChildWhichIsA("BasePart", true)
            if b then table.insert(rawSupply, b) end
        elseif o.Name == "Box" then
            table.insert(rawSupply, o)
        end
    end

    for _, o1 in ipairs(rawSupply) do
        local position1 = o1:IsA("Model") and (o1.PrimaryPart and o1.PrimaryPart.Position) or (o1:IsA("BasePart") and o1.Position)
        if position1 then
            local dup = false
            for _, o2 in ipairs(espData.items.supply) do
                local position2 = o2:IsA("Model") and (o2.PrimaryPart and o2.PrimaryPart.Position) or (o2:IsA("BasePart") and o2.Position)
                if position2 and (position1 - position2).Magnitude < 8 then
                    dup = true
                    break
                end
            end
            if not dup then
                table.insert(espData.items.supply, o1)
            else
                espClr(o1)
            end
        end
    end

    for _, oldObj in ipairs(oldSupply) do
        local stillExists = false
        for _, newObj in ipairs(espData.items.supply) do
            if newObj == oldObj then stillExists = true break end
        end
        if not stillExists then espClr(oldObj) end
    end

    local m = WS:FindFirstChild("Map")
    if m then
        local safe = m:FindFirstChild("SafeHouse")
        if safe then
            local b = safe:FindFirstChild("Base")
            if b then table.insert(espData.items.locs, {o=b, t="Safehouse"}) end
        end
        local tow = m:FindFirstChild("ObservationTower")
        if tow then
            local r = tow:FindFirstChild("Radar")
            local b = r and r:FindFirstChild("Base")
            if b then table.insert(espData.items.locs, {o=b, t="Tower"}) end
        end
        local shack = m:FindFirstChild("Shack")
        if shack then
            local sp = shack:FindFirstChild("ShopPart")
            if sp then table.insert(espData.items.locs, {o=sp, t="Shop"}) end
        end
        local power = m:FindFirstChild("PowerStation")
        if power then
            local sf = power:FindFirstChild("StationFolder")
            local sp = sf and sf:FindFirstChild("StationGUIPart")
            if sp then table.insert(espData.items.locs, {o=sp, t="Power St."}) end
        end
        local camp = m:FindFirstChild("BaseCamp")
        if camp then
            local p = camp:FindFirstChildWhichIsA("BasePart", true)
            if p then table.insert(espData.items.locs, {o=p, t="Base Camp"}) end
        end
    end
end

local function updateESP()
    local WS = game:GetService("Workspace")
    local PL = game:GetService("Players")
    local now = os.clock()
    if now - espData.lastS > 0.5 then
        fullScan()
        espData.lastS = now
    end

    if espData.flags.RakeESP then
        local r = WS:FindFirstChild("Rake")
        if r then applyESP(r, Color3.fromRGB(255,0,0), "RAKE", "RakeESP") end
    else
        local r = WS:FindFirstChild("Rake")
        if r then espClr(r) end
    end

    if espData.flags.PlayerESP then
        for _, p in ipairs(PL:GetPlayers()) do
            if p.Character then applyESP(p.Character, Color3.fromRGB(0,255,150), p.Name, "PlayerESP") end
        end
    else
        for _, p in ipairs(PL:GetPlayers()) do
            if p.Character then espClr(p.Character) end
        end
    end

    if espData.flags.ScrapESP then
        for _, data in ipairs(espData.items.scrap) do applyESP(data.o, Color3.fromRGB(255,215,0), data.t, "ScrapESP") end
    else
        for _, data in ipairs(espData.items.scrap) do espClr(data.o) end
    end

    if espData.flags.FlareESP then
        for _, o in ipairs(espData.items.flare) do applyESP(o, Color3.fromRGB(255,100,0), "Flare Gun", "FlareESP") end
    else
        for _, o in ipairs(espData.items.flare) do espClr(o) end
    end

    if espData.flags.SupplyESP then
        for _, o in ipairs(espData.items.supply) do applyESP(o, Color3.fromRGB(0,200,255), "Supply Crate", "SupplyESP") end
    else
        for _, o in ipairs(espData.items.supply) do espClr(o) end
    end

    if espData.flags.LocESP then
        for _, d in ipairs(espData.items.locs) do applyESP(d.o, Color3.fromRGB(200,0,255), d.t, "LocESP") end
    else
        for _, d in ipairs(espData.items.locs) do espClr(d.o) end
    end

    if espData.flags.TrapESP then
        for _, data in ipairs(espData.items.traps) do applyESP(data.o, data.c, data.t, "TrapESP") end
    else
        for _, data in ipairs(espData.items.traps) do espClr(data.o) end
    end
end

local function checkAnyESP()
    for _, v in pairs(espData.flags) do
        if v then return true end
    end
    return false
end

local function startESP()
    if espData.conn then return end
    espData.conn = game:GetService("RunService").RenderStepped:Connect(updateESP)
end

local function stopESP()
    if espData.conn then
        espData.conn:Disconnect()
        espData.conn = nil
    end
    for o, _ in pairs(espData.ec) do
        espClr(o)
    end
    espData.ec = {}
end

mkTog(t1, "Rake ESP", false, function(v)
    espData.flags.RakeESP = v
    if v then startESP() elseif not checkAnyESP() then stopESP() end
end)

mkTog(t1, "Player ESP", false, function(v)
    espData.flags.PlayerESP = v
    if v then startESP() elseif not checkAnyESP() then stopESP() end
end)

mkTog(t1, "Scrap ESP", false, function(v)
    espData.flags.ScrapESP = v
    if v then startESP() elseif not checkAnyESP() then stopESP() end
end)

mkTog(t1, "Flare ESP", false, function(v)
    espData.flags.FlareESP = v
    if v then startESP() elseif not checkAnyESP() then stopESP() end
end)

mkTog(t1, "Supply ESP", false, function(v)
    espData.flags.SupplyESP = v
    if v then startESP() elseif not checkAnyESP() then stopESP() end
end)

mkTog(t1, "Location ESP", false, function(v)
    espData.flags.LocESP = v
    if v then startESP() elseif not checkAnyESP() then stopESP() end
end)

mkTog(t1, "Trap ESP", false, function(v)
    espData.flags.TrapESP = v
    if v then startESP() elseif not checkAnyESP() then stopESP() end
end)

--// === TAB: Player ===
local t2 = mkTab("Player")

mkTog(t2, "Inf Stamina", false, function(v)
    if v then
        if not _G.FloppaHub_StaminaData then
            _G.FloppaHub_StaminaData = {}
            local data = _G.FloppaHub_StaminaData

            local function getStaminaModule()
                for _, obj in ipairs(getgc(true)) do
                    if typeof(obj) == "table" then
                        local st = rawget(obj, "stamina")
                        if typeof(st) == "number" then
                            return obj
                        end
                    end
                end
                return nil
            end

            data.mod = getStaminaModule()
            if not data.mod then
                warn("[Floppa HUB] Stamina module not found!")
                _G.FloppaHub_StaminaData = nil
                return
            end

            if typeof(data.mod.StaminaDrain) == "function" then
                data.oldStaminaDrain = data.mod.StaminaDrain
                hookfunction(data.mod.StaminaDrain, newcclosure(function() return end))
            end
            if typeof(data.mod.TakeStamina) == "function" then
                data.oldTakeStamina = data.mod.TakeStamina
                hookfunction(data.mod.TakeStamina, newcclosure(function() return end))
            end

            local guiTable = nil
            for _, obj in ipairs(getgc(true)) do
                if typeof(obj) == "table" then
                    local updateFn = rawget(obj, "Update")
                    if typeof(updateFn) == "function" then
                        local s, c = pcall(debug.getconstants, updateFn)
                        if s and c then
                            for _, const in ipairs(c) do
                                if const == "StaminaFrame" or const == "staminaFrame" then
                                    guiTable = obj
                                    break
                                end
                            end
                        end
                    end
                    if guiTable then break end
                end
            end

            if guiTable then
                data.guiTable = guiTable
                data.oldUpdate = guiTable.Update
                guiTable.Update = newcclosure(function(self, dt)
                    local result = data.oldUpdate(self, dt)
                    pcall(function()
                        local frames = rawget(self, "frames")
                        if frames then
                            local barFrames = rawget(frames, "barFrames")
                            if barFrames then
                                local stam = rawget(barFrames, "staminaFrame")
                                if stam and stam:IsA("GuiObject") then
                                    stam.Visible = false
                                end
                            end
                        end
                    end)
                    return result
                end)
            end
        end

        _G.FloppaHub_StaminaData.active = true
        task.spawn(function()
            while _G.FloppaHub_StaminaData and _G.FloppaHub_StaminaData.active do
                pcall(function()
                    local m = _G.FloppaHub_StaminaData.mod
                    if m then
                        m.stamina = math.huge
                        m.Vitamins = true
                        m.canSprint = true
                    end
                end)
                task.wait(0.5)
            end
        end)
    else
        if _G.FloppaHub_StaminaData then
            _G.FloppaHub_StaminaData.active = false
            pcall(function()
                local m = _G.FloppaHub_StaminaData.mod
                if m then
                    m.stamina = 100
                    m.Vitamins = false
                end
            end)
            pcall(function()
                local self = _G.FloppaHub_StaminaData.guiTable
                if self then
                    local frames = rawget(self, "frames")
                    if frames then
                        local barFrames = rawget(frames, "barFrames")
                        if barFrames then
                            local stam = rawget(barFrames, "staminaFrame")
                            if stam and stam:IsA("GuiObject") then
                                stam.Visible = true
                            end
                        end
                    end
                end
            end)
        end
    end
end)

mkTog(t2, "Anti Trap", false, function(v)
    if v then
        if not _G.FloppaHub_TrapData then
            _G.FloppaHub_TrapData = {}
            local data = _G.FloppaHub_TrapData

            local function bypassTrap(char)
                for _, obj in ipairs(char:GetDescendants()) do
                    pcall(function()
                        if obj:IsA("BasePart") then
                            obj.CanTouch = false
                        end
                    end)
                end
            end

            if plr.Character then
                bypassTrap(plr.Character)
            end

            data.charConn = plr.CharacterAdded:Connect(function(char)
                task.wait(0.5)
                bypassTrap(char)
            end)

            data.heartbeatConn = game:GetService("RunService").Heartbeat:Connect(function()
                local char = plr.Character
                if not char then return end
                for _, obj in ipairs(char:GetDescendants()) do
                    pcall(function()
                        if obj:IsA("BasePart") and obj.CanTouch ~= false then
                            obj.CanTouch = false
                        end
                    end)
                end
            end)
        end
        _G.FloppaHub_TrapData.active = true
    else
        if _G.FloppaHub_TrapData then
            if _G.FloppaHub_TrapData.heartbeatConn then
                _G.FloppaHub_TrapData.heartbeatConn:Disconnect()
            end
            if _G.FloppaHub_TrapData.charConn then
                _G.FloppaHub_TrapData.charConn:Disconnect()
            end
            local char = plr.Character
            if char then
                for _, obj in ipairs(char:GetDescendants()) do
                    pcall(function()
                        if obj:IsA("BasePart") then
                            obj.CanTouch = true
                        end
                    end)
                end
            end
            _G.FloppaHub_TrapData = nil
        end
    end
end)

mkTog(t2, "Anti Fall", false, function(v)
    if v then
        if _G.FloppaHub_AntiFallData then
            _G.FloppaHub_AntiFallData.active = true
            return
        end

        _G.FloppaHub_AntiFallData = {
            active = true,
            connections = {},
            charConn = nil
        }
        local data = _G.FloppaHub_AntiFallData

        local function disableFall(char)
            if not char then return end
            local h = char:WaitForChild("Humanoid", 5)
            if not h then return end

            for _, c in pairs(getconnections(h.FreeFalling)) do
                pcall(function()
                    c:Disable()
                    table.insert(data.connections, c)
                end)
            end
            for _, c in pairs(getconnections(h.Landed)) do
                pcall(function()
                    c:Disable()
                    table.insert(data.connections, c)
                end)
            end
        end

        if plr.Character then
            disableFall(plr.Character)
        end

        data.charConn = plr.CharacterAdded:Connect(disableFall)
    else
        if _G.FloppaHub_AntiFallData then
            if _G.FloppaHub_AntiFallData.charConn then
                _G.FloppaHub_AntiFallData.charConn:Disconnect()
            end
            for _, c in ipairs(_G.FloppaHub_AntiFallData.connections) do
                pcall(function() c:Enable() end)
            end
            _G.FloppaHub_AntiFallData = nil
        end
    end
end)

--// === TAB: Misc ===
local t3 = mkTab("Misc")

mkTog(t3, "Timer | Power Level", false, function(v)
    if v then
        if _G.FloppaHub_HUDData and _G.FloppaHub_HUDData.gui then
            _G.FloppaHub_HUDData.gui.Enabled = true
            return
        end

        _G.FloppaHub_HUDData = {}
        local data = _G.FloppaHub_HUDData
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local RunService = game:GetService("RunService")
        local StarterGui = game:GetService("StarterGui")

        local gameTimer = ReplicatedStorage:WaitForChild("Timer")
        local powerLevel = ReplicatedStorage:WaitForChild("PowerValues"):WaitForChild("PowerLevel")
        local stationPower = ReplicatedStorage:WaitForChild("StationPower")

        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "RakeHUD_Floppa"
        screenGui.ResetOnSpawn = false
        screenGui.Parent = pg
        data.gui = screenGui

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 220, 0, 90)
        frame.Position = UDim2.new(0.5, -110, 0.1, 0)
        frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        frame.BackgroundTransparency = 0.15
        frame.BorderSizePixel = 0
        frame.Active = true
        frame.Draggable = true
        frame.Parent = screenGui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = frame

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(255, 170, 0)
        stroke.Thickness = 2
        stroke.Parent = frame

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 22)
        title.BackgroundTransparency = 1
        title.TextColor3 = Color3.fromRGB(255, 170, 0)
        title.Text = "⚡ RAKE HUD"
        title.Font = Enum.Font.SourceSansBold
        title.TextSize = 14
        title.Parent = frame

        local timerLabel = Instance.new("TextLabel")
        timerLabel.Size = UDim2.new(1, -10, 0, 28)
        timerLabel.Position = UDim2.new(0, 5, 0, 24)
        timerLabel.BackgroundTransparency = 1
        timerLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
        timerLabel.Text = "⏱️ Игра: 00:00"
        timerLabel.Font = Enum.Font.SourceSansBold
        timerLabel.TextSize = 18
        timerLabel.TextXAlignment = Enum.TextXAlignment.Left
        timerLabel.Parent = frame

        local powerLabel = Instance.new("TextLabel")
        powerLabel.Size = UDim2.new(1, -10, 0, 28)
        powerLabel.Position = UDim2.new(0, 5, 0, 54)
        powerLabel.BackgroundTransparency = 1
        powerLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
        powerLabel.Text = "⚡ Станция: OFF"
        powerLabel.Font = Enum.Font.SourceSansBold
        powerLabel.TextSize = 18
        powerLabel.TextXAlignment = Enum.TextXAlignment.Left
        powerLabel.Parent = frame

        data.conn = RunService.Heartbeat:Connect(function()
            pcall(function()
                local timerVal = gameTimer.Value
                local minutes = math.floor(timerVal / 60)
                local seconds = timerVal % 60
                timerLabel.Text = string.format("⏱️ Игра: %02d:%02d", minutes, seconds)

                if timerVal > 120 then
                    timerLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
                elseif timerVal > 60 then
                    timerLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
                else
                    timerLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
                end

                local isOn = stationPower.Value
                if isOn then
                    local rawVal = powerLevel.Value
                    local percent = rawVal / 10
                    powerLabel.Text = string.format("⚡ Станция: %.1f%%", percent)
                    if percent > 50 then
                        powerLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
                    elseif percent > 20 then
                        powerLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
                    else
                        powerLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
                    end
                else
                    powerLabel.Text = "⚡ Станция: OFF"
                    powerLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
                end
            end)
        end)

        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "✅ HUD активирован",
                Text = "Перетаскивай рамку мышью/пальцем!",
                Duration = 5
            })
        end)
    else
        if _G.FloppaHub_HUDData then
            if _G.FloppaHub_HUDData.conn then
                _G.FloppaHub_HUDData.conn:Disconnect()
            end
            if _G.FloppaHub_HUDData.gui then
                _G.FloppaHub_HUDData.gui:Destroy()
            end
            _G.FloppaHub_HUDData = nil
        end
    end
end)

mkTog(t3, "Rake Kill", false, function(v)
    if v then
        if _G.FloppaHub_RakeKillData then
            _G.FloppaHub_RakeKillData.active = true
            _G.FloppaHub_RakeKillData.rakeKilled = false
            return
        end

        _G.FloppaHub_RakeKillData = {
            active = true,
            rakeKilled = false
        }
        local data = _G.FloppaHub_RakeKillData
        local WS = game:GetService("Workspace")
        local RS = game:GetService("RunService")
        local RSStorage = game:GetService("ReplicatedStorage")
        local LP = game:GetService("Players").LocalPlayer

        local function isRakeOnTrap()
            local rake = WS:FindFirstChild("Rake")
            if not rake then return false end
            local rhp = rake:FindFirstChild("HumanoidRootPart")
            if not rhp then return false end
            local d = WS:FindFirstChild("Debris")
            if not d then return false end
            local t = d:FindFirstChild("Traps")
            if not t then return false end
            for _, trap in ipairs(t:GetChildren()) do
                if trap.Name == "RakeTrapModel" and trap:FindFirstChild("HitBox") then
                    local hb = trap.HitBox
                    local dist = (rhp.Position - hb.Position).Magnitude
                    if dist < 5 then
                        return true, rake
                    end
                end
            end
            return false, nil
        end

        local function killRake(rake)
            if data.rakeKilled then return end
            data.rakeKilled = true
            local hum = rake:FindFirstChildOfClass("Humanoid")
            local hrp = rake:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp then return end

            local endTime = os.clock() + 1
            while os.clock() < endTime do
                pcall(function()
                    if setnetworkowner then setnetworkowner(hrp, LP) end
                    hum.Health = 0
                    hum.MaxHealth = 0
                    hum:ChangeState(16)
                    for _, obj in ipairs(rake:GetDescendants()) do
                        if obj:IsA("Motor6D") or obj:IsA("Weld") or obj:IsA("WeldConstraint") then
                            obj:Destroy()
                        end
                    end
                    local de = RSStorage:FindFirstChild("DeadEvent")
                    if de then
                        de:FireServer()
                        de:FireServer(rake)
                        de:FireServer(hum)
                        de:FireServer(hrp)
                        de:FireServer("Rake")
                    end
                end)
                task.wait(0.01)
            end

            local holdEnd = os.clock() + 5
            while os.clock() < holdEnd do
                pcall(function()
                    if hum.Health > 0 then
                        hum.Health = 0
                        hum.MaxHealth = 0
                    end
                    hum:ChangeState(16)
                    for _, obj in ipairs(rake:GetDescendants()) do
                        if obj:IsA("Motor6D") or obj:IsA("Weld") or obj:IsA("WeldConstraint") then
                            obj:Destroy()
                        end
                    end
                    if setnetworkowner then setnetworkowner(hrp, LP) end
                end)
                task.wait(0.05)
            end

            task.wait(1)
            data.rakeKilled = false
        end

        data.conn = RS.Heartbeat:Connect(function()
            if not data.active or data.rakeKilled then return end
            local onTrap, rake = isRakeOnTrap()
            if onTrap and rake then
                killRake(rake)
            end
        end)
    else
        if _G.FloppaHub_RakeKillData then
            _G.FloppaHub_RakeKillData.active = false
            if _G.FloppaHub_RakeKillData.conn then
                _G.FloppaHub_RakeKillData.conn:Disconnect()
            end
            _G.FloppaHub_RakeKillData = nil
        end
    end
end)

mkBtn(t3, "Rake on Trap", function()
    local WS = game:GetService("Workspace")
    local RS = game:GetService("RunService")
    local LP = game:GetService("Players").LocalPlayer

    local function getTrap()
        local d = WS:FindFirstChild("Debris")
        if not d then return nil end
        local t = d:FindFirstChild("Traps")
        if not t then return nil end
        local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not root then return nil end
        local closest, md = nil, math.huge
        for _, tr in ipairs(t:GetChildren()) do
            if tr.Name == "RakeTrapModel" then
                local hb = tr:FindFirstChild("HitBox")
                if hb and hb:IsA("BasePart") then
                    local dist = (hb.Position - root.Position).Magnitude
                    if dist < md then
                        md = dist
                        closest = tr
                    end
                end
            end
        end
        return closest
    end

    local function getRakeHRP()
        local rake = WS:FindFirstChild("Rake")
        if rake then
            return rake:FindFirstChild("HumanoidRootPart")
        end
        return nil
    end

    local trap = getTrap()
    local rakeHRP = getRakeHRP()

    if not trap then
        warn("[Floppa HUB] No trap found!")
        return
    end
    if not rakeHRP then
        warn("[Floppa HUB] No Rake found!")
        return
    end

    local hb = trap:FindFirstChild("HitBox")
    if not hb then
        warn("[Floppa HUB] Trap has no HitBox!")
        return
    end

    local pos = hb.Position
    local active = true

    rakeHRP.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)
    rakeHRP.AssemblyLinearVelocity = Vector3.new(0, -50, 0)

    local hold = 0
    local conn
    conn = RS.Heartbeat:Connect(function(dt)
        hold = hold + dt
        if hold >= 2.5 or not active then
            conn:Disconnect()
            return
        end
        if rakeHRP.Parent then
            local jx = (math.random() - 0.5) * 0.1
            local jz = (math.random() - 0.5) * 0.1
            rakeHRP.CFrame = CFrame.new(pos.X + jx, pos.Y + 0.5, pos.Z + jz)
            rakeHRP.AssemblyLinearVelocity = Vector3.new(jx * 10, -5, jz * 10)
        end
    end)

    print("[Floppa HUB] Rake on Trap activated!")
end)

mkBtn(t3, "Bring Flare Gun", function()
    local lp = game:GetService("Players").LocalPlayer
    local WS = game:GetService("Workspace")

    local function isFlare(o)
        if not o:IsA("BasePart") then return false end
        if o:IsDescendantOf(lp) then return false end
        if o.Name ~= "FlareGun" then return false end
        local path = o:GetFullName():lower()
        if path:find("safehouse") or path:find("door") or path:find("panel") then return false end
        return true
    end

    local function getFlares()
        local t = {}
        for _, o in ipairs(WS:GetDescendants()) do
            if isFlare(o) then
                table.insert(t, o)
            end
        end
        return t
    end

    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        warn("[Floppa HUB] No HRP")
        return
    end

    local pos = hrp.Position + hrp.CFrame.RightVector * 2.5 + Vector3.new(0, -1.5, 0)
    local flares = getFlares()
    local c = 0

    for _, fg in ipairs(flares) do
        if fg and fg.Parent then
            fg.CFrame = CFrame.new(pos)
            fg.AssemblyLinearVelocity = Vector3.zero
            fg.AssemblyAngularVelocity = Vector3.zero
            c = c + 1
        end
    end

    print("[Floppa HUB] Teleported " .. c .. " flare gun(s)")
end)

mkBtn(t3, "Bring Scrap", function()
    local lp = game:GetService("Players").LocalPlayer
    local WS = game:GetService("Workspace")

    local function isScrap(o)
        if not o:IsA("BasePart") then return false end
        if o:IsDescendantOf(lp) then return false end
        local n = o.Name
        if n ~= "Scrap" and n ~= "Metal" then return false end
        local path = o:GetFullName():lower()
        if path:find("safehouse") or path:find("door") or path:find("panel") or path:find("breaker") or path:find("supply") or path:find("crate") or path:find("box") then return false end
        local sz = o.Size.Magnitude
        if sz > 8 or sz < 0.3 then return false end
        return true
    end

    local function getScraps()
        local t = {}
        for _, o in ipairs(WS:GetDescendants()) do
            if isScrap(o) then
                table.insert(t, o)
            end
        end
        return t
    end

    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        warn("[Floppa HUB] No HRP")
        return
    end

    local pos = hrp.Position + hrp.CFrame.RightVector * 2.5 + Vector3.new(0, -2, 0)
    local scraps = getScraps()
    local c = 0

    for _, s in ipairs(scraps) do
        if s and s.Parent then
            s.CFrame = CFrame.new(pos)
            s.AssemblyLinearVelocity = Vector3.zero
            s.AssemblyAngularVelocity = Vector3.zero
            c = c + 1
        end
    end

    print("[Floppa HUB] Teleported " .. c .. " scrap(s)")
end)

mkTog(t3, "Insta Open Drop", false, function(v)
    if v then
        if _G.FloppaHub_InstaOpenData then
            _G.FloppaHub_InstaOpenData.active = true
            _G.FloppaHub_InstaOpenData.FC = {}
            return
        end

        _G.FloppaHub_InstaOpenData = {
            active = true,
            FC = {},
            LC = 0
        }
        local data = _G.FloppaHub_InstaOpenData
        local WS = game:GetService("Workspace")
        local RS = game:GetService("RunService")
        local RSs = game:GetService("ReplicatedStorage")
        local LP = game:GetService("Players").LocalPlayer
        local SE = RSs:WaitForChild("SupplyClientEvent")

        data.conn = RS.Heartbeat:Connect(function()
            if not data.active then return end
            local n = tick()
            if n - data.LC < 0.2 then return end
            data.LC = n

            pcall(function()
                local C = LP.Character
                if not C then return end
                local H = C:FindFirstChild("HumanoidRootPart")
                if not H then return end
                local D = WS:FindFirstChild("Debris")
                if not D then return end
                local CF = D:FindFirstChild("SupplyCrates")
                if not CF then return end

                for _, c in pairs(CF:GetChildren()) do
                    local P = c:FindFirstChildWhichIsA("BasePart", true)
                    if P then
                        local M = (P.Position - H.Position).Magnitude
                        if M <= 35 then
                            local O = c:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if O and O.Enabled and O.ActionText == "Open" and not data.FC[c] then
                                data.FC[c] = true
                                local U = c:FindFirstChild("UnlockValue")
                                if U then U.Value = U.MaxValue end
                                O.HoldDuration = 0
                                task.spawn(function()
                                    for i = 1, 20 do
                                        SE:FireServer("Open", true)
                                        task.wait(0.01)
                                    end
                                    SE:FireServer("Open", false)
                                end)
                            end
                        end
                    end
                end
            end)
        end)
    else
        if _G.FloppaHub_InstaOpenData then
            _G.FloppaHub_InstaOpenData.active = false
            if _G.FloppaHub_InstaOpenData.conn then
                _G.FloppaHub_InstaOpenData.conn:Disconnect()
            end
            _G.FloppaHub_InstaOpenData = nil
        end
    end
end)

mkTog(t3, "Fullbright", false, function(v)
    if v then
        if _G.FloppaHub_FullbrightData then return end

        _G.FloppaHub_FullbrightData = {}
        local data = _G.FloppaHub_FullbrightData
        local Lighting = game:GetService("Lighting")
        local Workspace = game:GetService("Workspace")
        local RunService = game:GetService("RunService")

        data.orig = {
            Brightness = Lighting.Brightness,
            ExposureCompensation = Lighting.ExposureCompensation,
            FogEnd = Lighting.FogEnd,
            GlobalShadows = Lighting.GlobalShadows,
            Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient
        }

        task.spawn(function()
            local terrain = Workspace:FindFirstChildOfClass("Terrain")
            if terrain then
                pcall(function()
                    if sethiddenproperty then
                        sethiddenproperty(terrain, "Decoration", false)
                    else
                        terrain.Decoration = false
                    end
                end)
            end
        end)

        local targetProperties = {
            Brightness = 2,
            ExposureCompensation = 0.3,
            FogEnd = 999999,
            GlobalShadows = false,
            Ambient = Color3.fromRGB(255, 255, 255),
            OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        }

        data.conn = RunService.RenderStepped:Connect(function()
            if not _G.FloppaHub_FullbrightData then return end
            for prop, val in pairs(targetProperties) do
                pcall(function() Lighting[prop] = val end)
            end
            for _, child in ipairs(Lighting:GetChildren()) do
                if child:IsA("BlurEffect") or child.Name:match("Enrage") or child.Name:match("Blood") or child:IsA("Atmosphere") then
                    pcall(function() child:Destroy() end)
                end
            end
        end)
    else
        if _G.FloppaHub_FullbrightData then
            if _G.FloppaHub_FullbrightData.conn then
                _G.FloppaHub_FullbrightData.conn:Disconnect()
            end
            local Lighting = game:GetService("Lighting")
            if _G.FloppaHub_FullbrightData.orig then
                for prop, val in pairs(_G.FloppaHub_FullbrightData.orig) do
                    pcall(function() Lighting[prop] = val end)
                end
            end
            _G.FloppaHub_FullbrightData = nil
        end
    end
end)

mkTog(t3, "Rake Kill Aura", false, function(v)
    if v then
        if _G.FloppaHub_KillAuraData then
            _G.FloppaHub_KillAuraData.active = true
            return
        end

        _G.FloppaHub_KillAuraData = {
            active = true,
            lastHit = 0
        }
        local data = _G.FloppaHub_KillAuraData

        data.thread = task.spawn(function()
            while data and data.active do
                local now = tick()
                if now - data.lastHit >= 0.6 then
                    pcall(function()
                        local WS = game:GetService("Workspace")
                        local LP = game:GetService("Players").LocalPlayer
                        local rake = WS:FindFirstChild("Rake")
                        local char = LP.Character

                        if rake and char then
                            local stick = char:FindFirstChild("StunStick")
                            if stick then
                                local stickEvent = stick:FindFirstChild("Event")
                                local rakeRoot = rake:FindFirstChild("HumanoidRootPart")
                                local myRoot = char:FindFirstChild("HumanoidRootPart")

                                if stickEvent and rakeRoot and myRoot then
                                    local dist = (myRoot.Position - rakeRoot.Position).Magnitude
                                    if dist <= 20 then
                                        local hostileVal = stick:FindFirstChild("HostileAllowed")
                                        if hostileVal and hostileVal.Value == false then
                                            hostileVal.Value = true
                                        end

                                        stickEvent:FireServer("S")
                                        task.wait(0.05)
                                        stickEvent:FireServer("H", rakeRoot)
                                        data.lastHit = tick()
                                    end
                                end
                            end
                        end
                    end)
                end
                task.wait(0.05)
            end
        end)
    else
        if _G.FloppaHub_KillAuraData then
            _G.FloppaHub_KillAuraData.active = false
            _G.FloppaHub_KillAuraData = nil
        end
    end
end)

--// === TAB: Fun ===
local tFun = mkTab("Fun")

mkTog(tFun, "Trap Troll", false, function(v)
    if v then
        if _G.FloppaHub_FunData and _G.FloppaHub_FunData.gui then
            _G.FloppaHub_FunData.gui.Enabled = true
            return
        end

        _G.FloppaHub_FunData = {}
        local data = _G.FloppaHub_FunData
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local UserInputService = game:GetService("UserInputService")
        local LocalPlayer = Players.LocalPlayer

        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "TrapTrollGui"
        ScreenGui.ResetOnSpawn = false
        ScreenGui.Parent = pg
        data.gui = ScreenGui

        local MainFrame = Instance.new("Frame")
        MainFrame.Size = UDim2.new(0, 300, 0, 400)
        MainFrame.Position = UDim2.new(0.5, -150, 0.1, 0)
        MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        MainFrame.BorderSizePixel = 2
        MainFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
        MainFrame.Active = true
        MainFrame.Parent = ScreenGui

        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(1, 0, 0, 30)
        Title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        Title.TextColor3 = Color3.fromRGB(255, 255, 255)
        Title.Text = "Trap Troll v3"
        Title.Font = Enum.Font.SourceSansBold
        Title.TextSize = 18
        Title.Parent = MainFrame

        local PlayerListFrame = Instance.new("Frame")
        PlayerListFrame.Size = UDim2.new(0.9, 0, 0, 120)
        PlayerListFrame.Position = UDim2.new(0.05, 0, 0.08, 0)
        PlayerListFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        PlayerListFrame.BorderSizePixel = 0
        PlayerListFrame.Parent = MainFrame
        Instance.new("UICorner", PlayerListFrame).CornerRadius = UDim.new(0, 6)

        local PlayerListScroll = Instance.new("ScrollingFrame")
        PlayerListScroll.Size = UDim2.new(1, -10, 1, -10)
        PlayerListScroll.Position = UDim2.new(0, 5, 0, 5)
        PlayerListScroll.BackgroundTransparency = 1
        PlayerListScroll.ScrollBarThickness = 4
        PlayerListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        PlayerListScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        PlayerListScroll.Parent = PlayerListFrame

        local PlayerListLayout = Instance.new("UIListLayout")
        PlayerListLayout.Padding = UDim.new(0, 3)
        PlayerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PlayerListLayout.Parent = PlayerListScroll

        local selectedPlayer = nil
        local playerButtons = {}

        local StatusText = Instance.new("TextLabel")
        StatusText.Size = UDim2.new(1, 0, 0, 20)
        StatusText.Position = UDim2.new(0, 0, 0.68, 0)
        StatusText.BackgroundTransparency = 1
        StatusText.TextColor3 = Color3.fromRGB(200, 200, 200)
        StatusText.Text = "Select a player"
        StatusText.Font = Enum.Font.SourceSans
        StatusText.TextSize = 13
        StatusText.Parent = MainFrame

        local function updatePlayerList()
            for _, btn in ipairs(playerButtons) do
                btn:Destroy()
            end
            playerButtons = {}

            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    local btn = Instance.new("TextButton")
                    btn.Size = UDim2.new(1, 0, 0, 24)
                    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    btn.Text = plr.Name .. " [" .. (plr.DisplayName or plr.Name) .. "]"
                    btn.Font = Enum.Font.SourceSans
                    btn.TextSize = 13
                    btn.Parent = PlayerListScroll
                    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

                    btn.MouseButton1Click:Connect(function()
                        selectedPlayer = plr
                        for _, b in ipairs(playerButtons) do
                            b.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                        end
                        btn.BackgroundColor3 = Color3.fromRGB(80, 120, 80)
                        StatusText.Text = "Target: " .. plr.Name
                        StatusText.TextColor3 = Color3.fromRGB(100, 255, 100)
                    end)

                    table.insert(playerButtons, btn)
                end
            end
        end

        data.plrAdded = Players.PlayerAdded:Connect(updatePlayerList)
        data.plrRemoving = Players.PlayerRemoving:Connect(updatePlayerList)

        local RefreshBtn = Instance.new("TextButton")
        RefreshBtn.Size = UDim2.new(0.9, 0, 0, 22)
        RefreshBtn.Position = UDim2.new(0.05, 0, 0.40, 0)
        RefreshBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        RefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        RefreshBtn.Text = "REFRESH LIST"
        RefreshBtn.Font = Enum.Font.SourceSansBold
        RefreshBtn.TextSize = 12
        RefreshBtn.Parent = MainFrame
        Instance.new("UICorner", RefreshBtn).CornerRadius = UDim.new(0, 4)

        RefreshBtn.MouseButton1Click:Connect(function()
            updatePlayerList()
            StatusText.Text = "List refreshed"
            StatusText.TextColor3 = Color3.fromRGB(200, 200, 200)
        end)

        local TrollBtn = Instance.new("TextButton")
        TrollBtn.Size = UDim2.new(0.9, 0, 0, 32)
        TrollBtn.Position = UDim2.new(0.05, 0, 0.48, 0)
        TrollBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
        TrollBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        TrollBtn.Text = "TROLL SELECTED"
        TrollBtn.Font = Enum.Font.SourceSansBold
        TrollBtn.TextSize = 15
        TrollBtn.Parent = MainFrame
        Instance.new("UICorner", TrollBtn).CornerRadius = UDim.new(0, 6)

        local AutoBtn = Instance.new("TextButton")
        AutoBtn.Size = UDim2.new(0.43, 0, 0, 28)
        AutoBtn.Position = UDim2.new(0.05, 0, 0.58, 0)
        AutoBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        AutoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        AutoBtn.Text = "AUTO: OFF"
        AutoBtn.Font = Enum.Font.SourceSansBold
        AutoBtn.TextSize = 13
        AutoBtn.Parent = MainFrame
        Instance.new("UICorner", AutoBtn).CornerRadius = UDim.new(0, 4)

        local AntiBtn = Instance.new("TextButton")
        AntiBtn.Size = UDim2.new(0.43, 0, 0, 28)
        AntiBtn.Position = UDim2.new(0.52, 0, 0.58, 0)
        AntiBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 120)
        AntiBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        AntiBtn.Text = "ANTI-BYPASS: OFF"
        AntiBtn.Font = Enum.Font.SourceSansBold
        AntiBtn.TextSize = 12
        AntiBtn.Parent = MainFrame
        Instance.new("UICorner", AntiBtn).CornerRadius = UDim.new(0, 4)

        local dragging, dragStart, startPos = false, nil, nil
        data.dragBegan = MainFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = MainFrame.Position
            end
        end)

        data.dragChanged = UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)

        data.dragEnded = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        local function getRootPart(char)
            return char and char:FindFirstChild("HumanoidRootPart")
        end

        local function getClosestTrap()
            local debris = workspace:FindFirstChild("Debris")
            if not debris then return nil end
            local traps = debris:FindFirstChild("Traps")
            if not traps then return nil end
            local root = getRootPart(LocalPlayer.Character)
            if not root then return nil end
            local closest, minDist = nil, math.huge
            for _, trap in ipairs(traps:GetChildren()) do
                if trap.Name == "RakeTrapModel" then
                    local hitbox = trap:FindFirstChild("HitBox")
                    if hitbox and hitbox:IsA("BasePart") then
                        local dist = (hitbox.Position - root.Position).Magnitude
                        if dist < minDist then
                            minDist = dist
                            closest = trap
                        end
                    end
                end
            end
            return closest
        end

        local function forceCanTouch(char)
            if not char then return 0 end
            local fixed = 0
            for _, obj in ipairs(char:GetDescendants()) do
                pcall(function()
                    if obj:IsA("BasePart") and obj.CanTouch == false then
                        obj.CanTouch = true
                        fixed = fixed + 1
                    end
                end)
            end
            return fixed
        end

        local activeTrolls = {}

        local function trollTrap(trapModel, targetChar)
            if not trapModel or not targetChar then return false end
            local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
            if not targetRoot then return false end
            local hitbox = trapModel:FindFirstChild("HitBox")
            if not hitbox then return false end

            activeTrolls[trapModel] = true
            local trapPos = hitbox.Position

            for i = 1, 10 do
                forceCanTouch(targetChar)
                task.wait(0.01)
            end

            targetRoot.CFrame = CFrame.new(trapPos.X, trapPos.Y + 3, trapPos.Z)
            targetRoot.AssemblyLinearVelocity = Vector3.zero
            targetRoot.AssemblyLinearVelocity = Vector3.new(0, -50, 0)

            local holdTime = 0
            local connection
            connection = RunService.Heartbeat:Connect(function(dt)
                holdTime = holdTime + dt
                if holdTime >= 2.5 or not activeTrolls[trapModel] then
                    connection:Disconnect()
                    activeTrolls[trapModel] = nil
                    return
                end
                if targetRoot.Parent then
                    forceCanTouch(targetChar)
                    local jx = (math.random() - 0.5) * 0.1
                    local jz = (math.random() - 0.5) * 0.1
                    targetRoot.CFrame = CFrame.new(trapPos.X + jx, trapPos.Y + 0.5, trapPos.Z + jz)
                    targetRoot.AssemblyLinearVelocity = Vector3.new(jx * 10, -5, jz * 10)
                end
            end)
            return true
        end

        TrollBtn.MouseButton1Click:Connect(function()
            if not selectedPlayer then
                StatusText.Text = "Select a player first!"
                StatusText.TextColor3 = Color3.fromRGB(255, 100, 100)
                task.delay(2, function() StatusText.Text = "Select a player"; StatusText.TextColor3 = Color3.fromRGB(200, 200, 200) end)
                return
            end

            local trapModel = getClosestTrap()
            local targetChar = selectedPlayer.Character

            if not trapModel then
                StatusText.Text = "No trap!"
                StatusText.TextColor3 = Color3.fromRGB(255, 100, 100)
                task.delay(2, function() StatusText.Text = "Select a player"; StatusText.TextColor3 = Color3.fromRGB(200, 200, 200) end)
                return
            end

            if not targetChar then
                StatusText.Text = selectedPlayer.Name .. " has no character!"
                StatusText.TextColor3 = Color3.fromRGB(255, 100, 100)
                task.delay(2, function() StatusText.Text = "Select a player"; StatusText.TextColor3 = Color3.fromRGB(200, 200, 200) end)
                return
            end

            StatusText.Text = "Trolling " .. selectedPlayer.Name .. "..."
            StatusText.TextColor3 = Color3.fromRGB(100, 255, 100)

            local success = trollTrap(trapModel, targetChar)
            if success then
                StatusText.Text = "Trapped " .. selectedPlayer.Name .. "!"
                TrollBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
                task.delay(1, function() TrollBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60) end)
            else
                StatusText.Text = "Failed!"
                StatusText.TextColor3 = Color3.fromRGB(255, 100, 100)
            end
            task.delay(2, function() StatusText.Text = "Select a player"; StatusText.TextColor3 = Color3.fromRGB(200, 200, 200) end)
        end)

        local autoTrollActive = false
        local autoThread = nil

        AutoBtn.MouseButton1Click:Connect(function()
            autoTrollActive = not autoTrollActive
            if autoTrollActive then
                if not selectedPlayer then
                    StatusText.Text = "Select a player first!"
                    StatusText.TextColor3 = Color3.fromRGB(255, 100, 100)
                    autoTrollActive = false
                    return
                end
                AutoBtn.Text = "AUTO: ON"
                AutoBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
                StatusText.Text = "Auto: " .. selectedPlayer.Name
                StatusText.TextColor3 = Color3.fromRGB(100, 255, 100)
                autoThread = task.spawn(function()
                    while autoTrollActive do
                        local trapModel = getClosestTrap()
                        local targetChar = selectedPlayer and selectedPlayer.Character
                        if trapModel and targetChar then
                            trollTrap(trapModel, targetChar)
                        end
                        task.wait(4)
                    end
                end)
            else
                AutoBtn.Text = "AUTO: OFF"
                AutoBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                StatusText.Text = "Select a player"
                StatusText.TextColor3 = Color3.fromRGB(200, 200, 200)
                autoTrollActive = false
                autoThread = nil
            end
        end)

        local antiBypassActive = false
        local antiBypassConn = nil

        AntiBtn.MouseButton1Click:Connect(function()
            antiBypassActive = not antiBypassActive
            if antiBypassActive then
                AntiBtn.Text = "ANTI-BYPASS: ON"
                AntiBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
                StatusText.Text = "Anti-bypass active"
                StatusText.TextColor3 = Color3.fromRGB(100, 255, 100)
                antiBypassConn = RunService.Heartbeat:Connect(function()
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer then
                            pcall(function()
                                local char = player.Character
                                if char then
                                    local fixed = forceCanTouch(char)
                                    if fixed > 0 then
                                        StatusText.Text = "Fixed " .. player.Name .. "!"
                                        StatusText.TextColor3 = Color3.fromRGB(255, 200, 100)
                                    end
                                end
                            end)
                        end
                    end
                end)
            else
                AntiBtn.Text = "ANTI-BYPASS: OFF"
                AntiBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 120)
                StatusText.Text = "Select a player"
                StatusText.TextColor3 = Color3.fromRGB(200, 200, 200)
                if antiBypassConn then
                    antiBypassConn:Disconnect()
                    antiBypassConn = nil
                end
            end
        end)

        data.antiAfkThread = task.spawn(function()
            while true do
                task.wait(300)
                if not _G.FloppaHub_FunData then break end
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:Move(Vector3.new(0.01, 0, 0), false)
                    task.wait(0.1)
                    hum:Move(Vector3.new(-0.01, 0, 0), false)
                end
            end
        end)

        updatePlayerList()
        print("Trap Troll v3 loaded!")

    else
        if _G.FloppaHub_FunData then
            local d = _G.FloppaHub_FunData
            if d.plrAdded then d.plrAdded:Disconnect() end
            if d.plrRemoving then d.plrRemoving:Disconnect() end
            if d.dragBegan then d.dragBegan:Disconnect() end
            if d.dragChanged then d.dragChanged:Disconnect() end
            if d.dragEnded then d.dragEnded:Disconnect() end
            if d.gui then d.gui:Destroy() end
            _G.FloppaHub_FunData = nil
        end
    end
end)

--// === TAB: Settings ===
local t4 = mkTab("Settings")

mkBtn(t4, "Destroy GUI", function() sg:Destroy() end)

--// SCROLL UPDATE
ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ls.CanvasSize = UDim2.new(0, 0, 0, ll.AbsoluteContentSize.Y + 12)
end)
rl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    rs.CanvasSize = UDim2.new(0, 0, 0, rl.AbsoluteContentSize.Y + 20)
end)

--// OPEN / CLOSE
local function getBtnCenter()
    local ap, as = tb.AbsolutePosition, tb.AbsoluteSize
    return UDim2.new(0, ap.X + as.X / 2, 0, ap.Y + as.Y / 2)
end

function openGui()
    if open then return end
    open = true
    if currentTween then currentTween:Cancel() currentTween = nil end
    mf.Visible = true
    local c = getBtnCenter()
    mf.Position = c
    mf.Size = UDim2.new(0, 0, 0, 0)
    currentTween = tw(mf, {0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out}, {
        Position = savedPos,
        Size = UDim2.new(0, savedW, 0, savedH)
    })
end

function closeGui()
    if not open then return end
    open = false
    if currentTween then currentTween:Cancel() currentTween = nil end
    local c = getBtnCenter()
    currentTween = tw(mf, {0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.In}, {
        Position = c,
        Size = UDim2.new(0, 0, 0, 0)
    })
    currentTween.Completed:Connect(function()
        if not open then mf.Visible = false currentTween = nil end
    end)
end

closeBtn.MouseButton1Click:Connect(closeGui)

--// DRAG & RESIZE
local dragType = nil
local dragStartPos = nil
local dragInputPos = nil
local hasMoved = false

local resizeActive = false
local resizeStartSize = nil
local resizeStartInput = nil

tb.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragType = "toggle"
        dragStartPos = tb.Position
        dragInputPos = input.Position
        hasMoved = false
    end
end)

tbar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragType = "gui"
        dragStartPos = mf.Position
        dragInputPos = input.Position
        hasMoved = false
    end
end)

rh.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizeActive = true
        resizeStartSize = mf.Size
        resizeStartInput = input.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
    if dragType then
        local delta = input.Position - dragInputPos
        if delta.Magnitude > 4 then hasMoved = true end
        if dragType == "toggle" then
            tb.Position = UDim2.new(dragStartPos.X.Scale, dragStartPos.X.Offset + delta.X, dragStartPos.Y.Scale, dragStartPos.Y.Offset + delta.Y)
        elseif dragType == "gui" then
            mf.Position = UDim2.new(dragStartPos.X.Scale, dragStartPos.X.Offset + delta.X, dragStartPos.Y.Scale, dragStartPos.Y.Offset + delta.Y)
            savedPos = mf.Position
        end
    elseif resizeActive then
        local delta = input.Position - resizeStartInput
        local newW = math.clamp(resizeStartSize.X.Offset + delta.X, 320, 700)
        local newH = math.clamp(resizeStartSize.Y.Offset + delta.Y, 200, 500)
        mf.Size = UDim2.new(0, newW, 0, newH)
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
    if dragType == "toggle" and not hasMoved then
        if open then closeGui() else openGui() end
    end
    if resizeActive then
        savedW = mf.Size.X.Offset
        savedH = mf.Size.Y.Offset
    end
    dragType = nil
    dragStartPos = nil
    dragInputPos = nil
    hasMoved = false
    resizeActive = false
    resizeStartSize = nil
    resizeStartInput = nil
end)

--// MOBILE
if UIS.TouchEnabled then
    tb.Size = UDim2.new(0, 60, 0, 34)
end

print("✅ Floppa HUB GUI Loaded!")
