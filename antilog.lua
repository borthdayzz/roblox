--[[
    Antilog.lua
    Blocks Discord webhook logging, keyloggers, fake key systems,
    malware redirects, and other threats in free/leaked Roblox scripts.
    Usage: Paste and execute BEFORE running any untrusted script.
]]

local blocked = 0
local log = {}

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local executorName = "Unknown"
pcall(function()
    if identifyexecutor then
        executorName = identifyexecutor()
    end
end)

local hasHookfunction  = type(hookfunction)       == "function"
local hasNewcclosure   = type(newcclosure)        == "function"
local hasGetrawmeta    = type(getrawmetatable)    == "function"
local hasSetreadonly   = type(setreadonly)        == "function"
local hasNamecallMethod= type(getnamecallmethod)  == "function"

local isLowEnd = not hasHookfunction or not hasGetrawmeta or not hasSetreadonly or not hasNamecallMethod

local function safeNewcclosure(fn)
    if hasNewcclosure then
        local ok, result = pcall(newcclosure, fn)
        if ok then return result end
    end
    return fn
end

-- ── UI ──

local AntiLogGui = Instance.new("ScreenGui")
AntiLogGui.Name = "AntiLogNotifications"
AntiLogGui.ResetOnSpawn = false
AntiLogGui.DisplayOrder = 9999
AntiLogGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
AntiLogGui.Parent = PlayerGui

local Container = Instance.new("Frame")
Container.Name = "Container"
Container.BackgroundTransparency = 1
Container.AnchorPoint = Vector2.new(1, 1)
Container.Position = UDim2.new(1, -10, 1, -10)
Container.Size = UDim2.new(0, 340, 0, 0)
Container.Parent = AntiLogGui

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.Parent = Container

UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Container.Size = UDim2.new(0, 340, 0, UIListLayout.AbsoluteContentSize.Y)
end)

local NOTIF_TYPES = {
    block  = { icon = "🚫", color = Color3.fromRGB(220, 50, 50),  label = "BLOCKED"  },
    warn   = { icon = "⚠️",  color = Color3.fromRGB(220, 170, 30), label = "WARNING"  },
    info   = { icon = "✓",  color = Color3.fromRGB(40, 180, 80),  label = "ACTIVE"   },
    detect = { icon = "🔍", color = Color3.fromRGB(200, 80, 220), label = "DETECTED" },
}

local notifCount = 0

local function showNotif(notifType, title, body, duration)
    duration = duration or 5
    local cfg = NOTIF_TYPES[notifType] or NOTIF_TYPES.info
    notifCount = notifCount + 1

    local card = Instance.new("Frame")
    card.Name = "Notif_" .. notifCount
    card.Size = UDim2.new(1, 0, 0, 64)
    card.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
    card.BorderSizePixel = 0
    card.BackgroundTransparency = 1
    card.LayoutOrder = notifCount
    card.ClipsDescendants = true
    card.Parent = Container

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = card

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 1, 0)
    accent.BackgroundColor3 = cfg.color
    accent.BorderSizePixel = 0
    accent.Parent = card
    Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 3)

    local labelRow = Instance.new("Frame")
    labelRow.Size = UDim2.new(1, -16, 0, 18)
    labelRow.Position = UDim2.new(0, 12, 0, 8)
    labelRow.BackgroundTransparency = 1
    labelRow.Parent = card

    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 20, 1, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = cfg.icon
    iconLabel.TextSize = 13
    iconLabel.Font = Enum.Font.Code
    iconLabel.TextColor3 = cfg.color
    iconLabel.TextXAlignment = Enum.TextXAlignment.Left
    iconLabel.Parent = labelRow

    local typeLabel = Instance.new("TextLabel")
    typeLabel.Size = UDim2.new(0, 80, 1, 0)
    typeLabel.Position = UDim2.new(0, 22, 0, 0)
    typeLabel.BackgroundTransparency = 1
    typeLabel.Text = cfg.label
    typeLabel.TextSize = 10
    typeLabel.Font = Enum.Font.Code
    typeLabel.TextColor3 = cfg.color
    typeLabel.TextXAlignment = Enum.TextXAlignment.Left
    typeLabel.Parent = labelRow

    local sourceLabel = Instance.new("TextLabel")
    sourceLabel.Size = UDim2.new(1, -110, 1, 0)
    sourceLabel.Position = UDim2.new(0, 108, 0, 0)
    sourceLabel.BackgroundTransparency = 1
    sourceLabel.Text = "AntiLog v3"
    sourceLabel.TextSize = 9
    sourceLabel.Font = Enum.Font.Code
    sourceLabel.TextColor3 = Color3.fromRGB(65, 65, 80)
    sourceLabel.TextXAlignment = Enum.TextXAlignment.Right
    sourceLabel.Parent = labelRow

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -16, 0, 16)
    titleLabel.Position = UDim2.new(0, 12, 0, 28)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextSize = 12
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    titleLabel.Parent = card

    if body and body ~= "" then
        card.Size = UDim2.new(1, 0, 0, 82)
        local bodyLabel = Instance.new("TextLabel")
        bodyLabel.Size = UDim2.new(1, -16, 0, 24)
        bodyLabel.Position = UDim2.new(0, 12, 0, 46)
        bodyLabel.BackgroundTransparency = 1
        bodyLabel.Text = body
        bodyLabel.TextSize = 10
        bodyLabel.Font = Enum.Font.Code
        bodyLabel.TextColor3 = Color3.fromRGB(130, 130, 150)
        bodyLabel.TextXAlignment = Enum.TextXAlignment.Left
        bodyLabel.TextWrapped = true
        bodyLabel.TextTruncate = Enum.TextTruncate.AtEnd
        bodyLabel.Parent = card
    end

    local progressBg = Instance.new("Frame")
    progressBg.Size = UDim2.new(1, 0, 0, 2)
    progressBg.Position = UDim2.new(0, 0, 1, -2)
    progressBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    progressBg.BorderSizePixel = 0
    progressBg.Parent = card

    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(1, 0, 1, 0)
    progressBar.BackgroundColor3 = cfg.color
    progressBar.BorderSizePixel = 0
    progressBar.Parent = progressBg

    TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
        BackgroundTransparency = 0.08,
    }):Play()
    TweenService:Create(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 1, 0),
    }):Play()

    task.delay(duration, function()
        if card and card.Parent then
            TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                BackgroundTransparency = 1,
            }):Play()
            task.wait(0.35)
            if card and card.Parent then card:Destroy() end
        end
    end)

    return card
end

-- ── Logging ──

local function record(reason, url)
    blocked = blocked + 1
    local entry = string.format("[#%d] Blocked (%s): %s", blocked, reason, url or "unknown")
    table.insert(log, entry)
    local notifType = "block"
    if reason:find("WARNING") or reason:find("suspicious") then
        notifType = "warn"
    elseif reason:find("DETECTED") or reason:find("KeySystem") then
        notifType = "detect"
    end
    local shortUrl = url and (#url > 50 and url:sub(1, 47) .. "..." or url) or "unknown"
    showNotif(notifType, reason:sub(1, 45), shortUrl, 6)
end

-- ── Blocklists ──

local BLOCKED_DOMAINS = {}
local BLOCKED_URLS = {}
local BLOCKED_PATTERNS = {}
local KEYSYSTEM_GUI_NAMES = {}
local KEYSYSTEM_KEYWORDS = {}
local CLIPBOARD_BLOCKED_KEYWORDS = {}

local FALLBACK = {
    domains = {
        "discord.com/api/webhooks","discordapp.com/api/webhooks","discord.gg",
        "webhook.site","requestbin","pipedream.net","hookbin.com","beeceptor.com",
        "hastebin.com","scriptix.live","keygenpro","keygenplus",
        "getkey.pw","kingtools.top","globalcheats.cc","lootdest.org","flux.li",
        "trigon.is","rentry.co"
        "controlc.com","ghostbin.com","webhook.express","ngrok.io","serveo.net",
        "burpcollaborator.net","requestcatcher.com","127.0.0.1","localhost",
        "0.0.0.0","192.168.","10.0.","172.16.",
    },
    urls = {
        "https://raw.githubusercontent.com/gangrankburn/Run-For-Brainrots/main/Run-For-Brainrots.lua",
        "https://raw.githubusercontent.com/GraspPhysician30/Raft-101-Survival/main/Raft-101-Survival.lua",
        "https://raw.githubusercontent.com/Shinetenmanor/SMASH-Walls-For-Brainrots/main/SMASH-Walls-For-Brainrots.lua",
        "https://raw.githubusercontent.com/curvecatbirdappraise/Squid-Game-X/main/Squid-Game-X.lua",
        "https://raw.githubusercontent.com/SenseiStationLook/SpongeBob-Tower-Defense/main/SpongeBob-Tower-Defense.lua",
        "https://raw.githubusercontent.com/Cablecludisclose/Spin-a-Soccer-Card/main/Spin-a-Soccer-Card.lua",
        "https://raw.githubusercontent.com/GraspPhysician30/Spin-a-Baddie/main/Spin-a-Baddie.lua",
        "https://raw.githubusercontent.com/TealHornetLiberate/Spider/main/Spider.lua",
        "https://raw.githubusercontent.com/Glazesispigot/Spear-Training/main/Spear-Training.lua",
        "https://raw.githubusercontent.com/Glazesispigot/Sols-RNG-BOSS-RAID-2/main/Sols-RNG-BOSS-RAID-2.lua",
        "https://raw.githubusercontent.com/modulemidwifeaxe/something-evil-will-happen/main/something-evil-will-happen.lua",
        "https://raw.githubusercontent.com/Burrowvonpeace/SNIPER-DUELS/main/SNIPER-DUELS.lua",
        "https://raw.githubusercontent.com/GradeLawyerPop/Slap-DUELS-UPD/main/Slap-DUELS-UPD.lua",
        "https://raw.githubusercontent.com/Shinetenmanor/Shrink-Hide-Seek/main/Shrink-Hide-Seek.lua",
        "https://raw.githubusercontent.com/Harborgrureflect/SHARP/main/SHARP.lua",
        "https://raw.githubusercontent.com/HeartDetectiveMarvel/Scary-Grocery-The-Night-Shift-HORROR/main/Scary-Grocery-The-Night-Shift-HORROR.lua",
        "https://raw.githubusercontent.com/TitanSurgeonRob/Scary-Shawarma-Kiosk-the-ANOMALY-horror/main/Scary-Shawarma-Kiosk-the-ANOMALY-horror.lua",
        "https://raw.githubusercontent.com/LeviathanPrivate/Secret-Staycation/main/Secret-Staycation.lua",
        "https://raw.githubusercontent.com/driftpaladintrough/Save-Brainrots-from-LAVA/main/Save-Brainrots-from-LAVA.lua",
        "https://kingtools.top/fiiii22j2j2jdelete.lua",
        "https://globalcheats.cc/config.php",
    },
    patterns = {
        "%.exe$","%.exe%?","%.bat$","%.cmd$","%.ps1$","%.vbs$","%.dll$",
        "keygen","scriptix","kingtools","globalcheats","getkey","freekey",
        "free%-key","key%-gen","key%-system","bypasskey","bypass%-key",
        ":%d%d%d%d/",":%d%d%d%d%d/",":%d%d%d/",
        ":8080",":8484",":4444",":1337",":3000",":5000",":6969",":9999",
    },
    keysystem_gui_names = {
        "PhantomKeySystem",
    },
    keysystem_keywords = {
        "phantom","scriptix","kingtools","globalcheats",
    },
    clipboard_blocked_keywords = {
        "scriptix","keygen","getkey","kingtools","globalcheats",
        "flux%.li","trigon%.is",
    },
}

local function textMatchesKeySystem(text)
    if type(text) ~= "string" then return false end
    local lower = text:lower()
    for _, kw in ipairs(KEYSYSTEM_KEYWORDS) do
        if lower:find(kw, 1, true) then return true, kw end
    end
    return false
end

local function scanGuiForKeySystem(gui)
    for _, name in ipairs(KEYSYSTEM_GUI_NAMES) do
        if gui.Name == name then return true end
    end
    local lowerName = gui.Name:lower()
    if lowerName:find("key") and (lowerName:find("system") or lowerName:find("auth") or lowerName:find("gui") or lowerName:find("verify")) then
        return true
    end
    if lowerName:find("phantom") or lowerName:find("scriptix") or lowerName:find("kingtools") then
        return true
    end
    local matchCount = 0
    local matchedKeywords = {}
    for _, obj in ipairs(gui:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            local hit, kw = textMatchesKeySystem(obj.Text)
            if hit and not matchedKeywords[kw] then
                matchCount = matchCount + 1
                matchedKeywords[kw] = true
            end
        end
    end
    return matchCount >= 2
end

local function isDomainBlocked(url)
    if type(url) ~= "string" then return false end
    local lower = url:lower()
    for _, domain in ipairs(BLOCKED_DOMAINS) do
        if lower:find(domain, 1, true) then return true, domain end
    end
    return false
end

local function isUrlBlocked(url)
    if type(url) ~= "string" then return false end
    local lower = url:lower()
    for _, blocked_url in ipairs(BLOCKED_URLS) do
        if lower == blocked_url then return true, blocked_url end
    end
    return false
end

local function isPatternBlocked(url)
    if type(url) ~= "string" then return false end
    local lower = url:lower()
    for _, pattern in ipairs(BLOCKED_PATTERNS) do
        if lower:find(pattern) then return true, pattern end
    end
    return false
end

local function checkUrl(url, source)
    if isUrlBlocked(url) then
        record(source .. " [blocked URL]", url)
        return true
    end
    if isDomainBlocked(url) then
        record(source .. " [blocked domain]", url)
        return true
    end
    if isPatternBlocked(url) then
        record(source .. " [suspicious pattern]", url)
        return true
    end
    return false
end

local function getExistingGuis()
    local existing = {}
    for _, v in ipairs(PlayerGui:GetChildren()) do existing[v] = true end
    pcall(function()
        for _, v in ipairs(game:GetService("CoreGui"):GetChildren()) do existing[v] = true end
    end)
    return existing
end

local bypassHook = false
local snapshotBeforeFetch = nil

if hasGetrawmeta and hasSetreadonly and hasNamecallMethod and hasNewcclosure then
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall

    local BLOCKED_NAMECALLS = {
        TeleportService = {
            "Teleport","TeleportToSpawnByName","TeleportAsync",
            "TeleportToPlaceInstance","TeleportPartyAsync",
            "TeleportToPrivateServer","ReserveServer",
        },
        MarketplaceService = {
            "PromptProductPurchase","PromptPurchase","PromptGamePassPurchase",
            "PromptBundlePurchase","PromptPremiumPurchase",
            "PromptSubscriptionPurchase","PromptNativePurchase",
        },
        StarterGui = { "SetCoreGuiEnabled","SetCore" },
        GuiService  = { "SetMenuIsOpen" },
    }

    local blockedServiceInstances = {}
    task.spawn(function()
        for serviceName in pairs(BLOCKED_NAMECALLS) do
            pcall(function()
                blockedServiceInstances[game:GetService(serviceName)] = serviceName
            end)
        end
    end)

    setreadonly(mt, false)
    mt.__namecall = safeNewcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if bypassHook then
            return oldNamecall(self, ...)
        end

        local serviceName = blockedServiceInstances[self]
        if serviceName then
            local methods = BLOCKED_NAMECALLS[serviceName]
            if methods then
                for _, m in ipairs(methods) do
                    if method == m then
                        record("Blocked: " .. serviceName .. "." .. method, method)
                        showNotif("block", "Malicious Call Blocked",
                            serviceName .. ":" .. method .. " blocked.", 7)
                        return nil
                    end
                end
            end
        end

        if self == HttpService then
            if method == "RequestAsync" then
                local url = (type(args[1]) == "table" and args[1].Url) or ""
                if checkUrl(url, "RequestAsync") then
                    return { Success = false, StatusCode = 403, StatusMessage = "Blocked by AntiLog", Body = "" }
                end
            elseif method == "GetAsync" then
                local url = type(args[1]) == "string" and args[1] or ""
                if checkUrl(url, "GetAsync") then return "" end
            elseif method == "PostAsync" then
                local url = type(args[1]) == "string" and args[1] or ""
                if checkUrl(url, "PostAsync") then return "" end
            end
        end

        if method == "HttpGet" then
            local url = type(args[1]) == "string" and args[1] or ""
            if checkUrl(url, "HttpGet") then
                snapshotBeforeFetch = getExistingGuis()
                task.delay(1.5, function()
                    if snapshotBeforeFetch then
                        for _, v in ipairs(PlayerGui:GetChildren()) do
                            if not snapshotBeforeFetch[v] and v.Name ~= "AntiLogNotifications" then
                                v:Destroy()
                                showNotif("block", "GUI Removed", "Destroyed: " .. v.Name, 6)
                            end
                        end
                        pcall(function()
                            for _, v in ipairs(game:GetService("CoreGui"):GetChildren()) do
                                if not snapshotBeforeFetch[v] and v.Name ~= "AntiLogNotifications" and v.Name ~= "RobloxGui" then
                                    if v:IsA("ScreenGui") and scanGuiForKeySystem(v) then
                                        v:Destroy()
                                        showNotif("block", "CoreGui GUI Removed", "Destroyed: " .. v.Name, 6)
                                    end
                                end
                            end
                        end)
                        snapshotBeforeFetch = nil
                    end
                end)
                return ""
            end
        end

        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
else
    task.spawn(function()
        task.wait(1)
        showNotif("warn", "Limited Protection",
            (executorName ~= "Unknown" and executorName or "Your executor") ..
            " has limited UNC — HTTP hooks disabled.", 8)
    end)
end

local function hookRequestFn(fn, name)
    if not fn or not hasHookfunction or not hasNewcclosure then return end
    local original = fn
    pcall(function()
        hookfunction(fn, safeNewcclosure(function(options)
            if not bypassHook then
                local url = (type(options) == "table" and options.Url) or ""
                if checkUrl(url, name) then
                    return { Success = false, StatusCode = 403,
                             StatusMessage = "Blocked by AntiLog", Body = "", Headers = {} }
                end
            end
            return original(options)
        end))
    end)
end

hookRequestFn(request,      "request()")
hookRequestFn(http_request, "http_request()")
if syn  then hookRequestFn(syn.request,  "syn.request()")  end
if http then hookRequestFn(http.request, "http.request()") end

local function applyBlocklists(data)
    BLOCKED_DOMAINS = {}
    BLOCKED_URLS = {}
    BLOCKED_PATTERNS = {}
    KEYSYSTEM_GUI_NAMES = {}
    KEYSYSTEM_KEYWORDS = {}
    CLIPBOARD_BLOCKED_KEYWORDS = {}

    if type(data.domains) == "table" then
        for _, v in ipairs(data.domains) do table.insert(BLOCKED_DOMAINS, v:lower()) end
    end
    if type(data.urls) == "table" then
        for _, v in ipairs(data.urls) do table.insert(BLOCKED_URLS, v:lower()) end
    end
    if type(data.patterns) == "table" then
        for _, v in ipairs(data.patterns) do table.insert(BLOCKED_PATTERNS, v) end
    end
    if type(data.keysystem_gui_names) == "table" then
        for _, v in ipairs(data.keysystem_gui_names) do table.insert(KEYSYSTEM_GUI_NAMES, v) end
    end
    if type(data.keysystem_keywords) == "table" then
        for _, v in ipairs(data.keysystem_keywords) do table.insert(KEYSYSTEM_KEYWORDS, v:lower()) end
    end
    if type(data.clipboard_blocked_keywords) == "table" then
        for _, v in ipairs(data.clipboard_blocked_keywords) do table.insert(CLIPBOARD_BLOCKED_KEYWORDS, v:lower()) end
    end
end

local function fetchBlocklistRaw()
    local BLOCKLIST_URL = "https://raw.githubusercontent.com/borthdayzz/roblox/refs/heads/main/blocked_urls.json"

    if http and http.request then
        local ok, res = pcall(http.request, { Url = BLOCKLIST_URL, Method = "GET" })
        if ok and res and type(res.Body) == "string" and #res.Body > 10 then
            return res.Body
        end
    end

    if request then
        local result = nil
        local done = false
        task.spawn(function()
            local ok, res = pcall(request, { Url = BLOCKLIST_URL, Method = "GET" })
            if ok and res and type(res.Body) == "string" and #res.Body > 10 then
                result = res.Body
            end
            done = true
        end)
        local t = 0
        repeat task.wait(0.1); t = t + 0.1 until done or t >= 10
        if result then return result end
    end

    if http_request then
        local result = nil
        local done = false
        task.spawn(function()
            local ok, res = pcall(http_request, { Url = BLOCKLIST_URL, Method = "GET" })
            if ok and res and type(res.Body) == "string" and #res.Body > 10 then
                result = res.Body
            end
            done = true
        end)
        local t = 0
        repeat task.wait(0.1); t = t + 0.1 until done or t >= 10
        if result then return result end
    end

    local ok, raw = pcall(game.HttpGet, game, BLOCKLIST_URL)
    if ok and raw and #raw > 10 then return raw end

    return nil
end

local function loadBlocklists()
    bypassHook = true
    local raw = fetchBlocklistRaw()
    
    local ok, result = false, nil
    if raw then
        ok, result = pcall(HttpService.JSONDecode, HttpService, raw)
    end
    
    bypassHook = false

    if ok and result and type(result) == "table" then
        applyBlocklists(result)
        showNotif("info", "Blocklists Loaded",
            #BLOCKED_DOMAINS .. " domains · " .. #BLOCKED_URLS .. " URLs · " .. #BLOCKED_PATTERNS .. " patterns", 4)
    else
        applyBlocklists(FALLBACK)
        showNotif("warn", "Using fallback blocklist", "GitHub fetch failed — built-in list active.", 6)
    end
end

loadBlocklists()

-- ── Sandbox service metatables ──

local protectedServices = { "Players", "UserInputService", "TextChatService", "Chat" }
for _, svcName in ipairs(protectedServices) do
    pcall(function()
        local svc = game:GetService(svcName)
        local svcMt = getrawmetatable and getrawmetatable(svc)
        if svcMt and setreadonly then setreadonly(svcMt, true) end
    end)
end

local function checkClipboard(text)
    if type(text) ~= "string" then return false end
    if text:find("_|WARNING") or text:find("ey[A-Za-z0-9%-_]+%.ey") then
        record("setclipboard — cookie/token detected", text:sub(1, 60))
        return true
    end
    local lower = text:lower()
    for _, kw in ipairs(CLIPBOARD_BLOCKED_KEYWORDS) do
        if lower:find(kw) then
            record("setclipboard BLOCKED — malicious URL", text:sub(1, 80))
            showNotif("block", "Clipboard Hijack Blocked", "Blocked: " .. text:sub(1, 60), 8)
            return true
        end
    end
    if text:len() > 200 and lower:find("https?://") then
        record("setclipboard — long URL copied", text:sub(1, 80))
        showNotif("warn", "Clipboard: Long URL Copied", text:sub(1, 60) .. "...", 5)
    end
    return false
end

if hasHookfunction and hasNewcclosure and setclipboard then
    local origClipboard = setclipboard
    pcall(function()
        hookfunction(setclipboard, safeNewcclosure(function(text)
            if checkClipboard(text) then return end
            return origClipboard(text)
        end))
    end)
elseif setclipboard then
    local realSetClipboard = setclipboard
    setclipboard = function(text)
        if checkClipboard(text) then return end
        return realSetClipboard(text)
    end
end

-- ── Key System Detector ──

local function handleDetected(gui, location)
    record("FakeKeySystem DETECTED [" .. location .. "]: " .. gui.Name, gui.Name)
    showNotif("detect", "Key System Destroyed!", "[" .. location .. "] " .. gui.Name .. " removed.", 10)
    pcall(function() gui:Destroy() end)
end

local function scanContainer(container, location)
    if not container then return end
    for _, gui in ipairs(container:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Name ~= "AntiLogNotifications" then
            if scanGuiForKeySystem(gui) then handleDetected(gui, location) end
        end
    end
end

local function scanAllGuis()
    local lp = Players.LocalPlayer
    if lp then
        local pg = lp:FindFirstChild("PlayerGui")
        if pg then scanContainer(pg, "PlayerGui") end
    end
    pcall(function() scanContainer(game:GetService("CoreGui"), "CoreGui") end)
end

task.spawn(function()
    task.wait(0.5)
    scanAllGuis()
    task.wait(3)
    scanAllGuis()
end)

task.spawn(function()
    PlayerGui.ChildAdded:Connect(function(child)
        if child:IsA("ScreenGui") and child.Name ~= "AntiLogNotifications" then
            task.wait(0.3)
            if scanGuiForKeySystem(child) then handleDetected(child, "PlayerGui") end
        end
    end)
end)

task.spawn(function()
    local ok, coreGui = pcall(function() return game:GetService("CoreGui") end)
    if not ok then return end
    coreGui.ChildAdded:Connect(function(child)
        if child:IsA("ScreenGui") and child.Name ~= "AntiLogNotifications" then
            task.wait(0.3)
            if scanGuiForKeySystem(child) then handleDetected(child, "CoreGui") end
        end
    end)
end)

-- ── Startup ──

task.wait(0.5)
showNotif("info", "AntiLog v3 Active",
    #BLOCKED_DOMAINS .. " domains · " .. #BLOCKED_URLS .. " URLs · " .. #BLOCKED_PATTERNS .. " patterns", 5)

-- ── Public API ──

_G.AntiLog = {
    getLog = function() return log end,
    summary = function()
        if #log == 0 then
            showNotif("info", "AntiLog Summary", "Nothing blocked yet.", 4)
        else
            showNotif("info", "AntiLog Summary", blocked .. " request(s) blocked total.", 5)
            for _, entry in ipairs(log) do print(entry) end
        end
    end,
    addDomain = function(domain)
        table.insert(BLOCKED_DOMAINS, domain:lower())
        showNotif("info", "Domain Added", domain, 3)
    end,
    blockUrl = function(url)
        table.insert(BLOCKED_URLS, url:lower())
        showNotif("info", "URL Blocked", url:sub(1, 60), 3)
    end,
    addKeyword = function(keyword)
        table.insert(KEYSYSTEM_KEYWORDS, keyword:lower())
        showNotif("info", "Keyword Added", keyword, 3)
    end,
    addGuiName = function(name)
        table.insert(KEYSYSTEM_GUI_NAMES, name)
        showNotif("info", "GUI Name Added", name, 3)
    end,
    scanNow = function()
        scanAllGuis()
        showNotif("info", "Manual Scan Complete", "Check for any detections above.", 3)
    end,
    reloadBlocklists = function()
        loadBlocklists()
    end,
    executorInfo = function()
        showNotif(isLowEnd and "warn" or "info",
            "Executor: " .. executorName,
            isLowEnd and "Limited protection mode" or "Full protection active", 5)
    end,
}