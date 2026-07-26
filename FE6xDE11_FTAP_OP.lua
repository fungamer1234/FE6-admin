-- Hub brand (window + splash only — not stamped on every button)
local HUB_NAME      = "SKILZ HUB"
local WINDOW_TITLE  = "SKILZ HUB"
local SPLASH_TITLE  = "SKILZ HUB"
local CHAT_NAME     = "SKILZ HUB"
local CREDIT_TEXT   = "made by:XkID"
local LOAD_POPUP    = "ThEy dOnT sTaNd A cHaNcE"
local CHAT_MSG      = "NoBoDy sTaNdS a ChAnCe"
local FE6_BRAND     = "SKILZ HUB" -- title rebrand only
local BLOODY_URL    = "https://raw.githubusercontent.com/celestialteam/youhateme/refs/heads/main/BloodyPremiumCrack.lua"
local RAYFIELD_URL  = "https://sirius.menu/rayfield"
local CLOWN_IMG     = "126398109685987"
local CLOWN_SND     = "9085027122"

local THEME = {
    bg     = Color3.fromRGB(10, 6, 22),
    panel  = Color3.fromRGB(20, 12, 42),
    card   = Color3.fromRGB(30, 18, 58),
    accent = Color3.fromRGB(98, 56, 198),
    accentLight = Color3.fromRGB(130, 90, 220),
    accentSoft  = Color3.fromRGB(72, 44, 148),
}

local registeredHubGuis = {}
local registeredInventoryGuis = {}

local FTAP_PLACE_ID = 6961824067

local OUR_OVERLAY_NAMES = {
    FE6_SkyOverlay = true,
    FE6_ScaryOverlay = true,
    FE6_SpawnOverlay = true,
    FE6_SkyCursor = true,
    FE6_Splash = true,
    FE6_EliteSplash = true,
    FE6_ClownReplace = true,
    FE6_AimPoint = true,
}

-- Strict names only — avoid matching hub/game UI (prevents giant stuck inventory)
local INVENTORY_NAME_HINTS = {
    "backpack", "hotbar", "toolbar", "itembar", "toybar", "itemwheel", "toyinventory",
    "inventory", "toyinventory", "toys", "items", "equip", "held", "carry", "toolbox",
    "tools", "tool", "picker", "selector", "wheel", "storage", "bag",
}

local INVENTORY_TEXT_HINTS = {
    "toy", "toys", "inventory", "backpack", "tools", "tool", "equip", "items",
}

local function textHintsInventory(str)
    if type(str) ~= "string" then return false end
    local lower = str:lower()
    for _, hint in ipairs(INVENTORY_TEXT_HINTS) do
        if lower:find(hint, 1, true) then return true end
    end
    return false
end

local GAME_UI_EXCLUDE_HINTS = {
    "map", "minimap", "world", "hud", "leaderboard", "health", "mobile", "touch",
    "topbar", "emote", "menu", "shop", "store", "coin", "currency", "prompt",
    "teleport", "quest", "notify", "notification", "vote", "round", "timer",
    "score", "kill", "damage", "island", "spawn", "playergui", "gameui",
}

local INVENTORY_ITEM_HINTS = {
    "slot", "item", "toy", "icon", "thumb", "viewport", "gridcell", "grid",
    "cell", "toolicon", "equip", "template", "preview", "thumbnail",
}

local CHAT_GUI_NAMES = {
    Chat = true, BubbleChat = true, PlayerList = true, TouchGui = true, Health = true,
    EmotesMenu = true, TopBar = true, NotificationGui = true,
}

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")


local Lighting          = game:GetService("Lighting")
local GuiService        = game:GetService("GuiService")
local StarterGui        = game:GetService("StarterGui")
local TextChatService   = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser       = game:GetService("VirtualUser")
local HttpService       = game:GetService("HttpService")
local TweenService      = game:GetService("TweenService")
local Debris            = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local hubLoaded         = false
local splashActive      = false
local purpleSkyOn       = false
local skyShaderMode     = "off" -- off | day | night
local scaryShaderMode   = "off" -- off | day | night
local inventoryPurpleOn = true
local clownBlocked      = false
local savedLighting     = {}
local skyOverlay        = nil
local scaryOverlay      = nil
local scaryWorldFolder  = nil
local scaryNpcConn      = nil
local scaryFigures      = {}
local eliteSplashGui    = nil
local sweepToken        = 0
local inventoryToken    = 0
local devilArtifacts    = {}
local lastSweepAt       = 0
local SWEEP_MIN_INTERVAL = 0.25
local hubSweepScheduled = false
local hubEnforceConn    = nil
local hubPaintWatcherInstalled = false
local hubPainterAttached = {}
local lastHubEnforceAt  = 0
local lastRedFixAt      = 0
local HUB_RED_FIX_INTERVAL = 2
local lastInventoryEnforceAt = 0
local INVENTORY_ENFORCE_INTERVAL = 2.5
local splashRainConn    = nil
local bloodyLoadPhase   = true
local hooksInstalled    = false
local postBloodyReady   = false
local chatAnnounced     = false
local createSpawnOverlay
local destroyEliteSpawn
local skyCursorConn     = nil
local skyCursorDrawings = {}
local MOUSE_CURSOR_ICON = "rbxasset://textures/Cursors/KeyboardMouse/ArrowFarCursor.png"
local AIM_RING_SIZE     = 10
local AIM_DOT_SIZE      = 3
local aimPointGui       = nil
local aimPointConn      = nil
local trackedDrawings   = {}
local cachedThrowBeam   = nil
local lastAimUpdateAt   = 0
local lastDrawingMaintainAt = 0
local lastBeamStyleAt   = 0
local AIM_UPDATE_INTERVAL = 0.05
local DRAWING_MAINTAIN_INTERVAL = 0.5
local BEAM_STYLE_INTERVAL = 0.5
local TAB_WHITELIST = {
    ["Player"] = true, ["Fling"] = true, ["Misc"] = true, ["Visuals"] = true,
    ["Settings"] = true, ["Combat"] = true, ["Movement"] = true, ["Fun"] = true,
    ["Main"] = true, ["World"] = true, ["Teleport"] = true, ["Troll"] = true,
    ["UI"] = true, ["Configs"] = true, ["Credits"] = true, ["Keybinds"] = true,
    ["Search"] = true, ["Home"] = true, ["Exploits"] = true, ["Anti"] = true,
    ["Auras"] = true, ["Aura"] = true, ["Whitelist"] = true, ["Friends"] = true,
}

local COLOR_PROPS = {
    BackgroundColor3 = true, BorderColor3 = true, ImageColor3 = true,
    TextColor3 = true, PlaceholderColor3 = true, ScrollBarImageColor3 = true,
}

local SKY_EFFECT_NAMES = {
    "FE6_PurpleSky", "FE6_PurpleAtmo", "FE6_SunRays", "FE6_AmbientCC", "FE6_AmbientBloom",
}

local SCARY_EFFECT_NAMES = {
    "FE6_ScaryAtmo", "FE6_ScaryRays", "FE6_ScaryCC", "FE6_ScaryBloom", "FE6_ScaryBlur", "FE6_ScarySky",
}

local SCARY_NPC_COUNT = 10
local SCARY_NPC_MIN_DIST = 5
local SCARY_NPC_MAX_DIST = 22
local SCARY_BLOOD_POOL_COUNT = 28
local SCARY_HANDPRINT_COUNT = 12
local SCARY_CROSS_COUNT = 6
local SCARY_SKY_EYE_COUNT = 8
local SCARY_MAP_RANGE = 220
local SCARY_FIRE_MAX = 35
local SCARY_FIRE_PILLAR_MAX = 18
local SCARY_FIRE_NAME_HINTS = {
    "tree", "trunk", "branch", "leaf", "leaves", "bush", "shrub", "wood", "log",
    "stump", "pine", "palm", "grass", "plant", "foliage", "hedge", "crate",
    "barrel", "hay", "stick", "fence", "lamp", "post", "pole", "sign", "bench",
    "nature", "forest", "prop", "decor", "model", "mesh", "rock", "stone",
    "house", "roof", "wall", "floor", "platform", "map", "island", "spawn",
}
local scaryPlayerBackup = {}
local scaryPlayerConns = {}
local scaryFireHosts = {}

local THROW_NAME_HINTS = {
    "trajectory", "throw", "arc", "aim", "path", "indicator",
    "preview", "sling", "fling",
}

local GRAB_ROPE_NAME_HINTS = {
    "rope", "string", "grab",
}

local AURA_EXCLUDE_HINTS = {
    "aura", "whitelist", "wl_", "friend", "kick", "esp", "highlight", "silent",
    "fov", "range", "hitbox", "orbit", "spin", "tornado", "decoy", "stdaura",
}

local function nameLooksLikeAuraContext(name)
    if type(name) ~= "string" then return false end
    local n = name:lower()
    for _, hint in ipairs(AURA_EXCLUDE_HINTS) do
        if n:find(hint, 1, true) then return true end
    end
    return false
end

local function isAuraVisual(inst)
    if not inst then return false end
    local p = inst
    for _ = 1, 14 do
        if not p then break end
        if nameLooksLikeAuraContext(p.Name) then return true end
        p = p.Parent
    end
    return false
end

local THROW_BEAM_FALLBACK = ColorSequence.new(THEME.accentLight)

local function beamAttachmentOnCharacter(beam, index)
    local char = LocalPlayer.Character
    if not char or not beam then return false end
    local att = beam["Attachment" .. tostring(index)]
    if not att or not att.Parent or not att.Parent:IsA("BasePart") then return false end
    return att.Parent:IsDescendantOf(char)
end

local function nameLooksLikeGrabRope(name)
    if type(name) ~= "string" then return false end
    local n = name:lower()
    for _, hint in ipairs(GRAB_ROPE_NAME_HINTS) do
        if n:find(hint, 1, true) then return true end
    end
    return false
end

local function isGrabRopeBeam(beam)
    if not beam or not beam:IsA("Beam") then return false end

    local cam = workspace.CurrentCamera
    if cam and beam:IsDescendantOf(cam) then return false end

    local char0 = beamAttachmentOnCharacter(beam, 0)
    local char1 = beamAttachmentOnCharacter(beam, 1)
    if char0 ~= char1 then return true end

    local char = LocalPlayer.Character
    if char and beam:IsDescendantOf(char) then
        if nameLooksLikeGrabRope(beam.Name) then return true end
    end

    return false
end

local function getAimAttachmentIndex(beam)
    local char0 = beamAttachmentOnCharacter(beam, 0)
    local char1 = beamAttachmentOnCharacter(beam, 1)
    if char0 and not char1 then return 1 end
    if char1 and not char0 then return 0 end
    return 1
end

local function getThrowBeamSequence(beam)
    local char0 = beamAttachmentOnCharacter(beam, 0)
    local char1 = beamAttachmentOnCharacter(beam, 1)
    if not char0 and not char1 then
        return THROW_BEAM_FALLBACK
    end
    local aimIndex = getAimAttachmentIndex(beam)
    if aimIndex == 0 then
        return ColorSequence.new({
            ColorSequenceKeypoint.new(0, THEME.accentLight),
            ColorSequenceKeypoint.new(0.5, THEME.accentSoft),
            ColorSequenceKeypoint.new(1, THEME.accent),
        })
    end
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, THEME.accent),
        ColorSequenceKeypoint.new(0.5, THEME.accentSoft),
        ColorSequenceKeypoint.new(1, THEME.accentLight),
    })
end

local function getAimWorldPosition(beam)
    if not beam or not beam:IsA("Beam") then return nil end
    local aimIndex = getAimAttachmentIndex(beam)
    local att = beam["Attachment" .. tostring(aimIndex)]
    if att and att.WorldPosition then
        return att.WorldPosition
    end
    return nil
end

local function isClownAsset(val)
    if type(val) ~= "string" then return false end
    return val:find(CLOWN_IMG, 1, true) ~= nil or val:find(CLOWN_SND, 1, true) ~= nil
end

-- True only for hub titles / credits — never for real feature buttons.
local function isHubTitleLike(str)
    if type(str) ~= "string" or str == "" then return false end
    if TAB_WHITELIST[str] then return false end
    local lower = str:lower()
    -- blood drop / skull + premium style titles
    local compact = lower:gsub("[%s%p]+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    compact = compact:gsub("[\128-\255]", ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    if compact == "premium" or compact == "bloody" or compact == "bloody premium"
        or compact == "bloody premium crack" or compact == "premium crack"
        or compact == "bloody hub" or compact == "bloodyv2" or compact == "bloody v2"
        or compact == "tokra" then
        return true
    end
    if lower:find("bloody premium", 1, true) or lower:find("premium crack", 1, true) then return true end
    if lower:find("bloody hub", 1, true) or lower:find("bloodyv2", 1, true) then return true end
    -- short title that is basically just premium (+ optional emoji bytes)
    if lower:find("premium", 1, true) and #str <= 28
        and not lower:find("kill", 1, true) and not lower:find("fling", 1, true)
        and not lower:find("player", 1, true) and not lower:find("speed", 1, true) then
        return true
    end
    return false
end

local function shouldRebrandText(str)
    if type(str) ~= "string" or str == "" then return false end
    if TAB_WHITELIST[str] then return false end
    local lower = str:lower()
    if lower:find("bloody", 1, true) then return true end
    if lower:find("tokra", 1, true) then return true end
    if lower:find("made by", 1, true) and lower:find("bloody", 1, true) then return true end
    if isHubTitleLike(str) then return true end
    return false
end

local function rebrandText(str)
    if type(str) ~= "string" then return str end
    local ok, result = pcall(function()
        if TAB_WHITELIST[str] then return str end
        if not shouldRebrandText(str) then return str end

        local lower = str:lower()
        if lower:find("made by", 1, true) or lower:match("^%s*by%s+bloody") then
            return CREDIT_TEXT
        end
        -- Window / loading titles only → clean brand once
        if isHubTitleLike(str) then
            return WINDOW_TITLE
        end

        -- Feature labels: strip brand words, KEEP the action name
        -- "Bloody Kill All" → "Kill All"   NOT "XkId Kill All"
        local out = str
        out = out:gsub("[Bb]loody%s*[Vv]2[%s%p%-:|]*", "")
        out = out:gsub("[Bb]loody%s*[Vv]%s*2[%s%p%-:|]*", "")
        out = out:gsub("[Bb]loody%s*[Pp]remium%s*[Cc]rack[%s%p%-:|]*", "")
        out = out:gsub("[Bb]loody%s*[Pp]remium[%s%p%-:|]*", "")
        out = out:gsub("[Bb]loody%s*[Hh]ub[%s%p%-:|]*", "")
        out = out:gsub("^[Bb]loody%s+", "")
        out = out:gsub("[Bb]loody[%s%p%-:|]+", " ")
        out = out:gsub("[Tt]okra[%s%p%-:|]+", " ")
        out = out:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
        out = out:gsub("^[%-%|:]+%s*", ""):gsub("%s*[%-%|:]+$", "")

        if out == "" or isHubTitleLike(out) then
            return WINDOW_TITLE
        end
        return out
    end)
    if ok and type(result) == "string" then return result end
    return str
end

local function stripBloodyFromText(str)
    if type(str) ~= "string" then return str end
    local lower = str:lower()
    if not lower:find("bloody", 1, true) and not lower:find("tokra", 1, true)
        and not lower:find("premium", 1, true) then
        return str
    end
    return rebrandText(str)
end

-- After hub loads, force-fix any leftover Premium/blood titles on the UI
local function scrubHubTitles()
    local function scrub(inst)
        if not (inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox")) then return end
        local ok, txt = pcall(function() return inst.Text end)
        if not ok or type(txt) ~= "string" or txt == "" then return end
        if TAB_WHITELIST[txt] then return end
        local lower = txt:lower()
        if isHubTitleLike(txt) or lower:find("bloody", 1, true) or lower:find("premium crack", 1, true) then
            pcall(function() inst.Text = rebrandText(txt) end)
        end
    end
    for _, root in ipairs({ PlayerGui, CoreGui }) do
        pcall(function()
            for _, d in ipairs(root:GetDescendants()) do scrub(d) end
        end)
    end
    pcall(function()
        if gethui then
            for _, d in ipairs(gethui():GetDescendants()) do scrub(d) end
        end
    end)
end


-- Scoped to avoid Luau 200-local limit (hub purple)
local aggressiveRecolor, aggressiveRecolorSequence, attachHubPainter, brutalPaintInstance, connectGuiRootChildAdded, discoverAndRegisterHubs, ensureBackpackEnabled, ensureHubVisible, findHubByTabButtons, findMainHubGui, fixTabTree, forceHubPurple, forceOpenRayfieldHub, guardHubElement, hijackRayfieldTheme, installHubPaintWatcher, installHubPurpleEnforcer, isBloodyUrl, isChatOrSystemGui, isGameInventoryGui, isHubGui, isInventoryGui, isInventoryShell, isLoadingOnlyGui, isOurOverlay, isToySlotFrame, isUnderInventoryGui, isUnderLikelyHub, looksLikeRayfieldSource, paintAllHubsPurple, patchRayfieldSource, preloadRayfield, pushRayfieldPurpleTheme, quickFixRedHubElements, refreshInventoryPurple, registerHubGui, registerInventoryGui, resolveWrapperHub, runInitialHubPasses, applyHubPurpleOnce, scheduleInventoryRefresh, schedulePurpleBurst, scheduleSweep, shouldPatchHttpUrl, suppressRayfieldLoading, sweepHubTheme
do -- hub purple scope
local function remapColor(color)
    if typeof(color) ~= "Color3" then return color end
    local r = math.floor(color.R * 255 + 0.5)
    local g = math.floor(color.G * 255 + 0.5)
    local b = math.floor(color.B * 255 + 0.5)

    if r > g + 4 and r > b + 4 and r >= 38 then
        return THEME.accent
    end
    if r > g + 5 and r > b + 5 and r > 60 then
        return THEME.accent
    end
    if r >= 180 and g <= 110 and b <= 110 and r > g + 10 then
        return THEME.accent
    end
    if r > 90 and g < 50 and b < 70 and r > g + 40 then
        return THEME.accent
    end
    if r >= 140 and g <= 90 and b <= 90 and r > g + 25 then
        return THEME.accent
    end
    if r >= 200 and g <= 120 and b <= 120 then
        return THEME.accentLight
    end
    if r <= 25 and g <= 25 and b <= 30 then
        return THEME.bg
    end
    if r <= 45 and g <= 35 and b <= 55 and r > 15 then
        return THEME.panel
    end
    if r <= 65 and g <= 50 and b <= 80 then
        return THEME.card
    end
    if r == 0 and g == 255 and b == 255 then
        return THEME.accent
    end
    if r >= 100 and g <= 80 and b >= 100 and r <= 160 then
        return THEME.accentSoft
    end
    if r >= 80 and b >= 80 and g <= 60 and r > g + 20 then
        return THEME.accent
    end
    if g >= 170 and b >= 170 and r <= 130 then
        return THEME.accent
    end
    if r >= 35 and g <= 20 and b <= 25 and r > g + 12 then
        return THEME.accent
    end
    if r == 255 and g == 255 and b == 255 then
        return color
    end
    if r >= 230 and g >= 230 and b >= 230 then
        return color
    end
    if r < 15 and g < 10 and b < 20 then
        return THEME.bg
    end

    return color
end

function isBloodyUrl(url)
    if type(url) ~= "string" then return false end
    local lower = url:lower()
    return lower:find("bloody", 1, true) ~= nil or lower:find("youhateme", 1, true) ~= nil
end

function shouldPatchHttpUrl(url)
    if type(url) ~= "string" then return false end
    if isBloodyUrl(url) then return false end
    local lower = url:lower()
    if lower:find(".luau", 1, true) or lower:find(".lua", 1, true) then
        if not lower:find("rayfield", 1, true) and not lower:find("sirius", 1, true) then
            return false
        end
    end
    return lower:find("rayfield", 1, true) ~= nil
        or lower:find("sirius.menu", 1, true) ~= nil
end

local PURPLE_RGB = {
    accent = "98, 56, 198",
    accentLight = "130, 90, 220",
    accentSoft = "72, 44, 148",
    bg = "10, 6, 22",
    panel = "20, 12, 42",
    card = "30, 18, 58",
}

local function patchColorLiterals(src)
    if type(src) ~= "string" then return src end
    local reps = {
        ["Color3.fromRGB(0, 255, 255)"]   = "Color3.fromRGB(" .. PURPLE_RGB.accent .. ")",
        ["Color3.fromRGB(0, 255, 255.0)"] = "Color3.fromRGB(" .. PURPLE_RGB.accent .. ")",
        ["Color3.fromRGB(25, 25, 25)"]    = "Color3.fromRGB(" .. PURPLE_RGB.bg .. ")",
        ["Color3.fromRGB(20, 20, 20)"]    = "Color3.fromRGB(" .. PURPLE_RGB.bg .. ")",
        ["Color3.fromRGB(30, 30, 30)"]    = "Color3.fromRGB(" .. PURPLE_RGB.panel .. ")",
        ["Color3.fromRGB(35, 35, 35)"]    = "Color3.fromRGB(" .. PURPLE_RGB.panel .. ")",
        ["Color3.fromRGB(40, 40, 40)"]    = "Color3.fromRGB(" .. PURPLE_RGB.card .. ")",
        ["Color3.fromRGB(45, 45, 45)"]    = "Color3.fromRGB(" .. PURPLE_RGB.card .. ")",
        ["Color3.fromRGB(255, 0, 0)"]     = "Color3.fromRGB(" .. PURPLE_RGB.accent .. ")",
        ["Color3.fromRGB(255,0,0)"]       = "Color3.fromRGB(" .. PURPLE_RGB.accent .. ")",
        ["Color3.fromRGB(200, 0, 0)"]     = "Color3.fromRGB(" .. PURPLE_RGB.accent .. ")",
        ["Color3.fromRGB(200,0,0)"]       = "Color3.fromRGB(" .. PURPLE_RGB.accent .. ")",
        ["Color3.fromRGB(180, 0, 0)"]     = "Color3.fromRGB(" .. PURPLE_RGB.accent .. ")",
        ["Color3.fromRGB(150, 0, 0)"]     = "Color3.fromRGB(" .. PURPLE_RGB.accent .. ")",
        ["Color3.fromRGB(255, 50, 50)"]   = "Color3.fromRGB(" .. PURPLE_RGB.accent .. ")",
        ["Color3.fromRGB(255, 70, 70)"]   = "Color3.fromRGB(" .. PURPLE_RGB.accentLight .. ")",
        ["Color3.fromRGB(255, 25, 25)"]   = "Color3.fromRGB(" .. PURPLE_RGB.accent .. ")",
        ["Color3.fromRGB(255, 40, 40)"]   = "Color3.fromRGB(" .. PURPLE_RGB.accent .. ")",
        ["Color3.fromRGB(220, 30, 30)"]   = "Color3.fromRGB(" .. PURPLE_RGB.accent .. ")",
        ["Color3.fromRGB(255, 85, 85)"]   = "Color3.fromRGB(" .. PURPLE_RGB.accent .. ")",
        ["Color3.fromRGB(230, 0, 0)"]     = "Color3.fromRGB(" .. PURPLE_RGB.accent .. ")",
        ["Color3.fromRGB(255, 10, 10)"]   = "Color3.fromRGB(" .. PURPLE_RGB.accent .. ")",
        ["ToggleEnabled = Color3.fromRGB(255, 0, 0)"] = "ToggleEnabled = Color3.fromRGB(" .. PURPLE_RGB.accent .. ")",
        ["TabBackgroundSelected = Color3.fromRGB(255, 0, 0)"] = "TabBackgroundSelected = Color3.fromRGB(" .. PURPLE_RGB.accent .. ")",
        ["TabBackgroundSelected = Color3.fromRGB(0, 255, 255)"] = "TabBackgroundSelected = Color3.fromRGB(" .. PURPLE_RGB.accent .. ")",
        ["AccentColor = Color3.fromRGB(255, 0, 0)"] = "AccentColor = Color3.fromRGB(" .. PURPLE_RGB.accent .. ")",
        ["SliderProgress = Color3.fromRGB(255, 0, 0)"] = "SliderProgress = Color3.fromRGB(" .. PURPLE_RGB.accent .. ")",
        ["Color3.new(1, 0, 0)"]           = "Color3.fromRGB(" .. PURPLE_RGB.accent .. ")",
        ["Color3.new(1,0,0)"]             = "Color3.fromRGB(" .. PURPLE_RGB.accent .. ")",
        ["Color3.new(0.8, 0, 0)"]         = "Color3.fromRGB(" .. PURPLE_RGB.accent .. ")",
        ["Color3.new(0.8,0,0)"]           = "Color3.fromRGB(" .. PURPLE_RGB.accent .. ")",
        ["Color3.fromRGB(255, 39, 39)"]   = "Color3.fromRGB(" .. PURPLE_RGB.accent .. ")",
        ["Color3.fromRGB(255, 60, 60)"]   = "Color3.fromRGB(" .. PURPLE_RGB.accent .. ")",
        ["Color3.fromRGB(255, 100, 100)"] = "Color3.fromRGB(" .. PURPLE_RGB.accentLight .. ")",
        ["Color3.fromRGB(255, 120, 120)"] = "Color3.fromRGB(" .. PURPLE_RGB.accentLight .. ")",
        ["Color3.fromRGB(10, 10, 10)"]    = "Color3.fromRGB(" .. PURPLE_RGB.bg .. ")",
        ["Color3.fromRGB(15, 15, 15)"]    = "Color3.fromRGB(" .. PURPLE_RGB.bg .. ")",
        ["Color3.fromRGB(0, 0, 0)"]       = "Color3.fromRGB(" .. PURPLE_RGB.bg .. ")",
        ["MainColor = Color3.fromRGB(255, 0, 0)"] = "MainColor = Color3.fromRGB(" .. PURPLE_RGB.accent .. ")",
        ["ToggleColor = Color3.fromRGB(255, 0, 0)"] = "ToggleColor = Color3.fromRGB(" .. PURPLE_RGB.accent .. ")",
        ["TopbarColor = Color3.fromRGB(25, 25, 25)"] = "TopbarColor = Color3.fromRGB(" .. PURPLE_RGB.panel .. ")",
    }
    for old, new in pairs(reps) do
        src = src:gsub(old, new)
    end
    src = src:gsub("Color3%.fromRGB%(%s*255%s*,%s*0%s*,%s*0%s*%)", "Color3.fromRGB(" .. PURPLE_RGB.accent .. ")")
    src = src:gsub("Color3%.fromRGB%(%s*2[0-9][0-9]%s*,%s*0%s*,%s*0%s*%)", "Color3.fromRGB(" .. PURPLE_RGB.accent .. ")")
    src = src:gsub("Color3%.fromRGB%(%s*1[0-9][0-9]%s*,%s*0%s*,%s*0%s*%)", "Color3.fromRGB(" .. PURPLE_RGB.accent .. ")")
    src = src:gsub("Color3%.fromRGB%(%s*255%s*,%s*[1-9][0-9]?%s*,%s*[1-9][0-9]?%s*%)", "Color3.fromRGB(" .. PURPLE_RGB.accent .. ")")
    src = src:gsub("Color3%.new%(%s*1%s*,%s*0%s*,%s*0%s*%)", "Color3.fromRGB(" .. PURPLE_RGB.accent .. ")")
    src = src:gsub("Color3%.new%(%s*0%.[89]%s*,%s*0%s*,%s*0%s*%)", "Color3.fromRGB(" .. PURPLE_RGB.accent .. ")")
    src = src:gsub("Color3%.new%(%s*0%.[67]%s*,%s*0%s*,%s*0%s*%)", "Color3.fromRGB(" .. PURPLE_RGB.accent .. ")")
    return src
end

function looksLikeRayfieldSource(src)
    if type(src) ~= "string" or #src < 8000 then return false end
    local lower = src:lower()
    return lower:find("tabbackgroundselected", 1, true) ~= nil
        or (lower:find("rayfield", 1, true) and lower:find("createwindow", 1, true))
        or lower:find("sirius", 1, true) ~= nil
end

function patchRayfieldSource(src)
    if type(src) ~= "string" then return src end
    if not looksLikeRayfieldSource(src) then return src end

    src = patchColorLiterals(src)

    -- Window titles only — never rewrite every "Bloody" in the whole library
    src = src:gsub('Title%s*=%s*"(.-)"', function(t)
        local low = t:lower()
        if low:find("bloody", 1, true) or low:find("premium", 1, true) or low:find("tokra", 1, true) then
            return 'Title = "' .. WINDOW_TITLE .. '"'
        end
        return 'Title = "' .. t .. '"'
    end)

    src = src:gsub(CLOWN_IMG, "0")
    src = src:gsub(CLOWN_SND, "0")

    src = src:gsub('LoadingTitle%s*=%s*"(.-)"', function(t)
        local low = t:lower()
        if low:find("bloody", 1, true) or low:find("premium", 1, true) then
            return 'LoadingTitle = "' .. SPLASH_TITLE .. '"'
        end
        return 'LoadingTitle = "' .. t .. '"'
    end)

    src = src:gsub('LoadingSubtitle%s*=%s*"(.-)"', function(t)
        local low = t:lower()
        if low:find("bloody", 1, true) or low:find("premium", 1, true) or low:find("made by", 1, true) then
            return 'LoadingSubtitle = "' .. CREDIT_TEXT .. '"'
        end
        return 'LoadingSubtitle = "' .. t .. '"'
    end)

    return src
end

-- Light-touch patch for the remote hub script (titles + button prefix only)
local function patchHubSource(src)
    if type(src) ~= "string" then return src end
    src = patchColorLiterals(src)
    src = src:gsub('Title%s*=%s*"(.-)"', function(t)
        local low = t:lower()
        if low:find("bloody", 1, true) or low:find("premium", 1, true) or low:find("tokra", 1, true) then
            return 'Title = "' .. WINDOW_TITLE .. '"'
        end
        return 'Title = "' .. t .. '"'
    end)
    src = src:gsub('Name%s*=%s*"(.-)"', function(t)
        local low = t:lower()
        if isHubTitleLike(t) then
            return 'Name = "' .. WINDOW_TITLE .. '"'
        end
        -- "Bloody Kill" → "Kill" inside string literals only
        if low:find("^bloody%s+") then
            local rest = t:gsub("^[Bb]loody%s+", "")
            if rest ~= "" then return 'Name = "' .. rest .. '"' end
        end
        return 'Name = "' .. t .. '"'
    end)
    src = src:gsub(CLOWN_IMG, "0")
    src = src:gsub(CLOWN_SND, "0")
    return src
end

function isOurOverlay(inst)
    if not inst or not inst:IsA("GuiObject") then return false end
    local p = inst
    while p do
        if p:IsA("ScreenGui") and OUR_OVERLAY_NAMES[p.Name] then
            return true
        end
        p = p.Parent
    end
    return false
end

function isChatOrSystemGui(gui)
    if not gui or not gui:IsA("ScreenGui") then return false end
    return CHAT_GUI_NAMES[gui.Name] == true
end

local function nameHintsInventory(name)
    local n = name:lower()
    for _, hint in ipairs(INVENTORY_NAME_HINTS) do
        if n:find(hint, 1, true) then return true end
    end
    return false
end

local function nameHintsExcludedGame(name)
    local n = name:lower()
    for _, hint in ipairs(GAME_UI_EXCLUDE_HINTS) do
        if n:find(hint, 1, true) then return true end
    end
    return false
end

local function isExcludedGameGui(gui)
    if not gui or not gui:IsA("ScreenGui") then return false end
    return nameHintsExcludedGame(gui.Name)
end

local function countHubWhitelistTabs(gui)
    if not gui then return 0 end
    local found = {}
    for _, d in ipairs(gui:GetDescendants()) do
        if d:IsA("TextButton") and TAB_WHITELIST[d.Text] then
            found[d.Text] = true
        elseif d:IsA("ImageButton") then
            local lbl = d:FindFirstChildWhichIsA("TextLabel") or d:FindFirstChildWhichIsA("TextButton")
            if lbl and TAB_WHITELIST[lbl.Text] then
                found[lbl.Text] = true
            end
        end
    end
    local count = 0
    for _ in pairs(found) do
        count = count + 1
    end
    return count
end

function isGameInventoryGui(gui)
    if not gui or not gui:IsA("ScreenGui") then return false end
    if isChatOrSystemGui(gui) or isOurOverlay(gui) then return true end
    return nameHintsInventory(gui.Name)
end

function ensureBackpackEnabled()
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
    end)
end

local function guiLooksLikeRayfield(gui)
    if not gui or not gui:IsA("ScreenGui") then return false end
    if gui:FindFirstChild("Main", true) or gui:FindFirstChild("MainFrame", true) then
        return true
    end
    if gui:FindFirstChild("Topbar", true) or gui:FindFirstChild("TopBar", true) then
        return true
    end
    return false
end

local function getGuiScanRoots()
    local roots = { PlayerGui }
    pcall(function()
        local cg = game:GetService("CoreGui")
        if cg then
            roots[#roots + 1] = cg
        end
    end)
    if gethui then
        pcall(function()
            local hui = gethui()
            if hui then
                for _, root in ipairs(roots) do
                    if root == hui then return end
                end
                roots[#roots + 1] = hui
            end
        end)
    end
    return roots
end

local function tabTextMatchesWhitelist(text)
    if type(text) ~= "string" or text == "" then return false end
    if TAB_WHITELIST[text] then return true end
    local stripped = text:gsub("^[^%w]*", ""):gsub("[^%w]*$", "")
    return TAB_WHITELIST[stripped] == true
end

local function guiHasHubTabs(gui)
    if not gui or not gui:IsA("ScreenGui") or isGameInventoryGui(gui) then return false end
    for _, d in ipairs(gui:GetDescendants()) do
        if d:IsA("TextButton") or d:IsA("TextLabel") then
            if tabTextMatchesWhitelist(d.Text) then return true end
        elseif d:IsA("ImageButton") then
            local lbl = d:FindFirstChildWhichIsA("TextLabel") or d:FindFirstChildWhichIsA("TextButton")
            if lbl and tabTextMatchesWhitelist(lbl.Text) then return true end
        end
    end
    return false
end

local function guiHasRayfieldMarkers(gui)
    if not gui then return false end
    local hasToggle, hasSlider, frames = false, false, 0
    for _, d in ipairs(gui:GetDescendants()) do
        if d:IsA("Frame") then
            frames = frames + 1
        end
        local dn = d.Name:lower()
        if dn:find("toggle", 1, true) then hasToggle = true end
        if dn:find("slider", 1, true) or dn:find("dropdown", 1, true) then hasSlider = true end
        if frames > 60 then break end
    end
    return frames >= 8 and (hasToggle or hasSlider)
end

function isLoadingOnlyGui(gui)
    if not gui or not gui:IsA("ScreenGui") then return false end
    local n = gui.Name:lower()
    if n == "rayfield loading" then return true end
    if n:find("loading", 1, true)
        and not gui:FindFirstChild("Main", true)
        and not gui:FindFirstChild("MainFrame", true) then
        return true
    end
    return false
end

local function looksLikeHubGui(gui)
    if not gui or not gui:IsA("ScreenGui") then return false end
    if OUR_OVERLAY_NAMES[gui.Name] or isChatOrSystemGui(gui) or isExcludedGameGui(gui)
        or isLoadingOnlyGui(gui) then
        return false
    end
    if isGameInventoryGui(gui) and not guiLooksLikeRayfield(gui) and not guiHasRayfieldMarkers(gui) then
        return false
    end
    local n = gui.Name:lower()
    if n:find("rayfield", 1, true) or n:find("bloody", 1, true) or n:find("sirius", 1, true) then
        return true
    end
    if guiLooksLikeRayfield(gui) or guiHasRayfieldMarkers(gui) or guiHasHubTabs(gui) then
        return true
    end
    if countHubWhitelistTabs(gui) >= 1 then
        return true
    end
    for _, d in ipairs(gui:GetDescendants()) do
        if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text then
            local t = d.Text
            if t == WINDOW_TITLE or t == HUB_NAME or t == SPLASH_TITLE then return true end
            if t:find("FE6xDE11", 1, true) then return true end
            if tabTextMatchesWhitelist(t) then return true end
        end
    end
    return false
end

local function isStrictRayfieldHub(gui)
    return looksLikeHubGui(gui)
end

local function screenGuiLooksLikeHub(gui)
    return isStrictRayfieldHub(gui)
end

function registerHubGui(gui)
    if not gui or not gui:IsA("ScreenGui") or isOurOverlay(gui) then return end
    if isGameInventoryGui(gui) or isExcludedGameGui(gui) then return end
    if isStrictRayfieldHub(gui) then
        registeredHubGuis[gui] = true
    else
        registeredHubGuis[gui] = nil
    end
end

local function getHubRoot(inst)
    if not inst or isOurOverlay(inst) then return nil end
    local p = inst
    while p do
        if p:IsA("ScreenGui") then
            if registeredHubGuis[p] then return p end
            registerHubGui(p)
            if registeredHubGuis[p] then return p end
            return nil
        end
        p = p.Parent
    end
    return nil
end

local function isHubElement(inst)
    if not inst or isOurOverlay(inst) then return false end
    return getHubRoot(inst) ~= nil
end

local cachedWrapperHub = nil

function resolveWrapperHub()
    if cachedWrapperHub and cachedWrapperHub.Parent then
        return cachedWrapperHub
    end
    cachedWrapperHub = nil

    local hub = findMainHubGui()
    if hub and hub.Parent then
        cachedWrapperHub = hub
        registeredHubGuis[hub] = true
        return hub
    end

    local best, bestScore = nil, 0
    for _, root in ipairs(getGuiScanRoots()) do
        for _, gui in ipairs(root:GetChildren()) do
            if gui:IsA("ScreenGui") and isStrictRayfieldHub(gui) and not isInventoryGui(gui) then
                local score = countHubWhitelistTabs(gui) * 120
                if guiLooksLikeRayfield(gui) then score = score + 500 end
                local n = gui.Name:lower()
                if n:find("rayfield", 1, true) or n:find("bloody", 1, true) then
                    score = score + 2000
                end
                if score > bestScore then
                    bestScore = score
                    best = gui
                end
            end
        end
    end

    if best then
        cachedWrapperHub = best
        registeredHubGuis[best] = true
        return best
    end

    local tabHub = findHubByTabButtons()
    if tabHub and tabHub.Parent then
        return tabHub
    end
    return nil
end

local function isHubScreenGui(gui)
    return gui and gui:IsA("ScreenGui") and isStrictRayfieldHub(gui)
end

local function isInsideHubTree(inst)
    if not inst or isOurOverlay(inst) then return false end
    local p = inst
    while p do
        if p:IsA("ScreenGui") then
            if registeredHubGuis[p] or isStrictRayfieldHub(p) then return true end
            if countHubWhitelistTabs(p) >= 1 and not isGameInventoryGui(p) then
                registeredHubGuis[p] = true
                return true
            end
            return false
        end
        p = p.Parent
    end
    return false
end

local function screenGuiFromInstance(inst)
    local p = inst
    while p do
        if p:IsA("ScreenGui") then return p end
        p = p.Parent
    end
    return nil
end

function findHubByTabButtons()
    local best, bestTabs = nil, 0
    for _, root in ipairs(getGuiScanRoots()) do
        for _, d in ipairs(root:GetDescendants()) do
            local tabText = nil
            if d:IsA("TextButton") or d:IsA("TextLabel") then
                tabText = d.Text
            elseif d:IsA("ImageButton") then
                local lbl = d:FindFirstChildWhichIsA("TextLabel") or d:FindFirstChildWhichIsA("TextButton")
                tabText = lbl and lbl.Text or nil
            end
            if tabText and tabTextMatchesWhitelist(tabText) then
                local sg = screenGuiFromInstance(d)
                if sg and not OUR_OVERLAY_NAMES[sg.Name] and not isChatOrSystemGui(sg) and not isGameInventoryGui(sg) then
                    local tabs = countHubWhitelistTabs(sg)
                    if tabs > bestTabs then
                        bestTabs = tabs
                        best = sg
                    elseif tabs == bestTabs and tabs == 0 then
                        best = best or sg
                    end
                end
            end
        end
    end
    if best then
        registeredHubGuis[best] = true
        cachedWrapperHub = best
    end
    return best
end

local function isInWrapperHub(inst)
    if not inst or isOurOverlay(inst) then return false end

    local hub = resolveWrapperHub()
    if hub and hub.Parent and (inst == hub or inst:IsDescendantOf(hub)) then
        return true
    end
    if isInsideHubTree(inst) then return true end

    local p = inst
    while p do
        if p:IsA("ScreenGui") and not OUR_OVERLAY_NAMES[p.Name] and not isChatOrSystemGui(p) then
            if registeredHubGuis[p] or looksLikeHubGui(p) or isStrictRayfieldHub(p) then
                registeredHubGuis[p] = true
                cachedWrapperHub = cachedWrapperHub or p
                return true
            end
            return false
        end
        if (p:IsA("TextButton") or p:IsA("TextLabel")) and tabTextMatchesWhitelist(p.Text) then
            local sg = screenGuiFromInstance(p)
            if sg and not OUR_OVERLAY_NAMES[sg.Name] and not isChatOrSystemGui(sg) then
                registeredHubGuis[sg] = true
                cachedWrapperHub = cachedWrapperHub or sg
                return inst == sg or inst:IsDescendantOf(sg)
            end
        end
        p = p.Parent
    end
    return false
end

function isUnderLikelyHub(inst)
    return isInWrapperHub(inst)
end

local function collectHubGuis()
    for _, root in ipairs(getGuiScanRoots()) do
        for _, gui in ipairs(root:GetChildren()) do
            if gui:IsA("ScreenGui") and not OUR_OVERLAY_NAMES[gui.Name] and not isChatOrSystemGui(gui) then
                registerHubGui(gui)
            end
        end
    end
    local wrapper = resolveWrapperHub()
    if wrapper and wrapper.Parent then
        return { wrapper }
    end
    return {}
end

function isHubGui(inst)
    if not inst or isOurOverlay(inst) then return false end
    if inst:IsA("GuiObject") then
        local n = inst.Name:lower()
        if n:find("rayfield", 1, true) or n:find("bloody", 1, true) then return true end
    end
    return isHubElement(inst)
end

function discoverAndRegisterHubs()
    for _, root in ipairs(getGuiScanRoots()) do
        for _, gui in ipairs(root:GetChildren()) do
            if gui:IsA("ScreenGui") and not OUR_OVERLAY_NAMES[gui.Name] and not isChatOrSystemGui(gui) then
                registerHubGui(gui)
                if not registeredHubGuis[gui] and not isGameInventoryGui(gui) and screenGuiLooksLikeHub(gui) then
                    registeredHubGuis[gui] = true
                end
            end
        end
    end
end

local function isReddishColor(color)
    if typeof(color) ~= "Color3" then return false end
    local r = math.floor(color.R * 255 + 0.5)
    local g = math.floor(color.G * 255 + 0.5)
    local b = math.floor(color.B * 255 + 0.5)
    if r > g + 8 and r > b + 8 and r >= 45 then return true end
    if r >= 160 and g <= 120 and b <= 120 and r > g + 15 then return true end
    if r >= 120 and g <= 80 and b <= 80 and r > g + 35 then return true end
    if r >= 90 and g <= 55 and b <= 55 and r > g + 25 then return true end
    if r >= 70 and g <= 40 and b <= 40 and r > g + 20 then return true end
    if g >= 180 and b >= 180 and r <= 120 then return true end
    return false
end

local function isRayfieldCyanAccent(color)
    if typeof(color) ~= "Color3" then return false end
    local r = math.floor(color.R * 255 + 0.5)
    local g = math.floor(color.G * 255 + 0.5)
    local b = math.floor(color.B * 255 + 0.5)
    return g >= 200 and b >= 200 and r <= 80
end

local function isHubTabElement(inst)
    if not inst or isOurOverlay(inst) then return false end

    local function nearTabControl(fromInst)
        local p = fromInst
        for _ = 1, 8 do
            if not p then return false end
            if p:IsA("TextButton") and TAB_WHITELIST[p.Text] and isHubGui(p) then
                return true
            end
            if (p:IsA("Frame") or p:IsA("ImageButton")) and isHubGui(p) then
                local lbl = p:FindFirstChildWhichIsA("TextLabel") or p:FindFirstChildWhichIsA("TextButton")
                if lbl and TAB_WHITELIST[lbl.Text] then return true end
            end
            p = p.Parent
        end
        return false
    end

    if inst:IsA("GuiObject") then
        if inst:IsA("TextButton") and TAB_WHITELIST[inst.Text] and isHubGui(inst) then
            return true
        end
        if nearTabControl(inst) then return true end
        local n = inst.Name:lower()
        if isHubGui(inst) and (n:find("tab", 1, true) or n:find("selected", 1, true) or n == "line" or n == "indicator") then
            return true
        end
        return false
    end

    if inst:IsA("UIStroke") or inst:IsA("UIGradient") then
        return nearTabControl(inst.Parent)
    end
    return false
end

local function forceTabPurpleOn(inst)
    pcall(function()
        if inst:IsA("GuiObject") then
            if isReddishColor(inst.BackgroundColor3) or isRayfieldCyanAccent(inst.BackgroundColor3) then
                inst.BackgroundColor3 = THEME.accent
            end
            if isReddishColor(inst.BorderColor3) or isRayfieldCyanAccent(inst.BorderColor3) then
                inst.BorderColor3 = THEME.accent
            end
            if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
                if isReddishColor(inst.TextColor3) or isRayfieldCyanAccent(inst.TextColor3) then
                    inst.TextColor3 = THEME.accentSoft
                end
            end
            if inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
                if isReddishColor(inst.ImageColor3) or isRayfieldCyanAccent(inst.ImageColor3) then
                    inst.ImageColor3 = THEME.accent
                end
            end
        end
        if inst:IsA("UIStroke") and (isReddishColor(inst.Color) or isRayfieldCyanAccent(inst.Color)) then
            inst.Color = THEME.accent
        end
        if inst:IsA("UIGradient") then
            inst.Color = remapColorSequence(inst.Color)
        end
    end)
end

local function guardTabColorProperty(inst, prop)
    pcall(function()
        if not inst.GetPropertyChangedSignal then return end
        inst:GetPropertyChangedSignal(prop):Connect(function()
            if not inst.Parent then return end
            local ok, val = pcall(function() return inst[prop] end)
            if ok and (isReddishColor(val) or isRayfieldCyanAccent(val)) then
                inst[prop] = THEME.accent
            end
        end)
    end)
end

local function guardTabElement(inst)
    if not inst or inst:GetAttribute("FE6_TabGuard") then return end
    inst:SetAttribute("FE6_TabGuard", true)
    forceTabPurpleOn(inst)
    if inst:IsA("GuiObject") then
        guardTabColorProperty(inst, "BackgroundColor3")
        guardTabColorProperty(inst, "BorderColor3")
        if inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
            guardTabColorProperty(inst, "ImageColor3")
        end
    end
    if inst:IsA("UIStroke") then
        guardTabColorProperty(inst, "Color")
    end
end

function fixTabTree(tabBtn)
    guardTabElement(tabBtn)
    local p = tabBtn.Parent
    for _ = 1, 3 do
        if not p or not p:IsA("GuiObject") then break end
        guardTabElement(p)
        forceTabPurpleOn(p)
        p = p.Parent
    end
    for _, d in ipairs(tabBtn:GetChildren()) do
        guardTabElement(d)
        forceTabPurpleOn(d)
    end
end

local function inventoryContainerScore(container)
    if not container or not container:IsA("GuiObject") then return 0 end
    local slots, viewports, buttons = 0, 0, 0
    for _, d in ipairs(container:GetDescendants()) do
        if d:IsA("ViewportFrame") then viewports = viewports + 1 end
        if d:IsA("ImageButton") then buttons = buttons + 1 end
        local dn = d.Name:lower()
        if dn:find("slot", 1, true) or dn:find("item", 1, true) or dn:find("toy", 1, true) then
            slots = slots + 1
        end
    end
    return slots + viewports * 2 + math.min(buttons, 6)
end

function isInventoryGui(gui)
    if not gui or not gui:IsA("ScreenGui") then return false end
    if isOurOverlay(gui) or isChatOrSystemGui(gui) or registeredHubGuis[gui] then return false end
    if isExcludedGameGui(gui) or isStrictRayfieldHub(gui) then return false end
    local n = gui.Name:lower()
    if n:find("rayfield", 1, true) or n:find("bloody", 1, true) then return false end
    if guiHasHubTabs(gui) or guiLooksLikeRayfield(gui) or guiHasRayfieldMarkers(gui) then return false end
    if nameHintsInventory(gui.Name) then return true end
    if inventoryContainerScore(gui) >= 4 then return true end
    for _, d in ipairs(gui:GetDescendants()) do
        if (d:IsA("TextLabel") or d:IsA("TextButton")) and textHintsInventory(d.Text) then
            return true
        end
    end
    return false
end

local function getScreenSize()
    local cam = workspace.CurrentCamera
    if cam then return cam.ViewportSize end
    return Vector2.new(1920, 1080)
end

local function frameScreenCoverage(frame)
    if not frame or not frame:IsA("GuiObject") then return 0 end
    local size = frame.AbsoluteSize
    local screen = getScreenSize()
    local denom = math.max(screen.X * screen.Y, 1)
    return (size.X * size.Y) / denom
end

local function getInventoryScanRoots()
    local roots = { PlayerGui }
    pcall(function()
        local cg = game:GetService("CoreGui")
        if cg then
            roots[#roots + 1] = cg
        end
    end)
    if gethui then
        pcall(function()
            local hui = gethui()
            if hui then
                for _, root in ipairs(roots) do
                    if root == hui then return end
                end
                roots[#roots + 1] = hui
            end
        end)
    end
    return roots
end

local function cleanupInventoryArtifacts()
    for _, inst in ipairs(PlayerGui:GetDescendants()) do
        if inst.Name == "FE6_InvStroke" then
            pcall(function() inst:Destroy() end)
        end
    end
end

local function registerInventoryShell(inst)
    if not inst or not (inst:IsA("Frame") or inst:IsA("ScrollingFrame") or inst:IsA("ImageLabel")) then return end
    if isOurOverlay(inst) or isInsideHubTree(inst) or isToySlotFrame(inst) then return end
    local sg = inst:FindFirstAncestorWhichIsA("ScreenGui")
    if sg and (isHubScreenGui(sg) or isStrictRayfieldHub(sg) or isExcludedGameGui(sg) or registeredHubGuis[sg]) then return end
    local size = inst.AbsoluteSize
    if size.X < 100 or size.Y < 36 then return end
    local coverage = frameScreenCoverage(inst)
    if coverage > 0.42 and not isBottomHotbar(inst) and not isLikelyToyBar(inst) then return end
    registeredInventoryGuis[inst] = true
end

function isToySlotFrame(inst)
    if not inst then return false end
    if inst:IsA("ViewportFrame") then
        local sz = inst.AbsoluteSize
        if sz.X <= 150 and sz.Y <= 150 then return true end
    end
    if inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
        local sz = inst.AbsoluteSize
        if sz.X <= 120 and sz.Y <= 120 then
            local n = inst.Name:lower()
            if n:find("slot", 1, true) or n:find("toy", 1, true) or n:find("item", 1, true)
                or n:find("icon", 1, true) or inst:FindFirstChildWhichIsA("ViewportFrame", true) then
                return true
            end
        end
    end
    if inst:FindFirstChildWhichIsA("ViewportFrame", true) and inst:IsA("GuiObject") then
        local n = inst.Name:lower()
        if n:find("slot", 1, true) or n:find("toy", 1, true) or n:find("item", 1, true)
            or n:find("cell", 1, true) or n:find("icon", 1, true) then
            return true
        end
        if inst:IsA("ImageButton") or (inst:IsA("Frame") and inst.AbsoluteSize.X < 120) then
            return true
        end
    end
    return false
end

local function isLikelyToyBar(frame)
    if not frame:IsA("GuiObject") then return false end
    if isInsideHubTree(frame) then return false end
    local pos = frame.AbsolutePosition
    local size = frame.AbsoluteSize
    local screen = getScreenSize()
    if size.X < 80 or size.Y < 28 or size.Y > 220 then return false end
    if (pos.Y + size.Y) < screen.Y * 0.82 then return false end
    local interactives = 0
    for _, d in ipairs(frame:GetDescendants()) do
        if d:IsA("ImageButton") or d:IsA("TextButton") or d:IsA("ViewportFrame") then
            interactives = interactives + 1
        end
    end
    return interactives >= 2
end

local function isBottomHotbar(frame)
    if isInsideHubTree(frame) then return false end
    if isLikelyToyBar(frame) then return true end
    if not frame:IsA("GuiObject") then return false end
    local pos = frame.AbsolutePosition
    local size = frame.AbsoluteSize
    local screen = getScreenSize()
    if size.Y > 200 or size.X < 120 then return false end
    if (pos.Y + size.Y) < screen.Y * 0.82 then return false end
    local btnCount = 0
    for _, d in ipairs(frame:GetDescendants()) do
        if d:IsA("ImageButton") or d:IsA("TextButton") or d:IsA("ViewportFrame") then
            btnCount = btnCount + 1
        end
    end
    return btnCount >= 2
end

local function isInventoryPanel(frame)
    if not frame:IsA("GuiObject") then return false end
    local size = frame.AbsoluteSize
    if size.X < 180 or size.Y < 100 then return false end
    local viewports, buttons = 0, 0
    for _, d in ipairs(frame:GetDescendants()) do
        if d:IsA("ViewportFrame") then viewports = viewports + 1 end
        if d:IsA("ImageButton") then buttons = buttons + 1 end
    end
    return viewports >= 1 or buttons >= 4 or inventoryContainerScore(frame) >= 4
end

local function findOuterInventoryFrame(gui)
    if not gui or not gui:IsA("ScreenGui") then return nil end
    local bestShell, bestArea = nil, 0
    for _, child in ipairs(gui:GetChildren()) do
        if (child:IsA("Frame") or child:IsA("ScrollingFrame") or child:IsA("ImageLabel"))
            and not isToySlotFrame(child) then
            local area = child.AbsoluteSize.X * child.AbsoluteSize.Y
            local coverage = frameScreenCoverage(child)
            if coverage <= 0.42 and area > bestArea then
                bestArea = area
                bestShell = child
            end
        end
    end
    return bestShell
end

local function purgeHubMistakenInventory()
    local hub = resolveWrapperHub()
    for root in pairs(registeredInventoryGuis) do
        if not root.Parent then
            registeredInventoryGuis[root] = nil
        elseif hub and (root == hub or root:IsDescendantOf(hub)) then
            registeredInventoryGuis[root] = nil
        elseif isInsideHubTree(root) then
            registeredInventoryGuis[root] = nil
        end
    end
end

local function discoverInventoryRoots()
    purgeHubMistakenInventory()
    cleanupInventoryArtifacts()

    for _, scanRoot in ipairs(getInventoryScanRoots()) do
        for _, inst in ipairs(scanRoot:GetDescendants()) do
            if (inst:IsA("Frame") or inst:IsA("ScrollingFrame") or inst:IsA("ImageLabel"))
                and not isInWrapperHub(inst) then
                if isBottomHotbar(inst) or isInventoryPanel(inst) then
                    registerInventoryShell(inst)
                end
            end
        end

        for _, gui in ipairs(scanRoot:GetChildren()) do
            if gui:IsA("ScreenGui") and isInventoryGui(gui) then
                registerInventoryGui(gui)
                local outer = findOuterInventoryFrame(gui)
                if outer then
                    registerInventoryShell(outer)
                end
                local bestShell, bestArea = nil, 0
                for _, child in ipairs(gui:GetDescendants()) do
                    if (child:IsA("Frame") or child:IsA("ScrollingFrame") or child:IsA("ImageLabel"))
                        and not isToySlotFrame(child)
                        and (isBottomHotbar(child) or isInventoryPanel(child)) then
                        local area = child.AbsoluteSize.X * child.AbsoluteSize.Y
                        if area > bestArea then
                            bestArea = area
                            bestShell = child
                        end
                    end
                end
                if bestShell then
                    registerInventoryShell(bestShell)
                end
            end
        end
    end
end

function isUnderInventoryGui(inst)
    if not inst or isOurOverlay(inst) or isInsideHubTree(inst) then return false end
    local p = inst
    while p do
        if p:IsA("ScreenGui") and (isHubScreenGui(p) or isStrictRayfieldHub(p) or registeredHubGuis[p]) then
            return false
        end
        if registeredInventoryGuis[p] then return true end
        if p:IsA("ScreenGui") then
            if isGameInventoryGui(p) or isInventoryGui(p) then return true end
            if registerInventoryGui(p) then return true end
            return false
        end
        p = p.Parent
    end
    return false
end

function registerInventoryGui(gui)
    if isInventoryGui(gui) then
        registeredInventoryGuis[gui] = true
        return true
    end
    return false
end

local function isInventoryElement(inst)
    if not inventoryPurpleOn or not inst or not inst:IsA("GuiObject") or isOurOverlay(inst) then
        return false
    end
    local p = inst.Parent
    while p do
        if p:IsA("ScreenGui") then
            if registeredInventoryGuis[p] then return true end
            if registerInventoryGui(p) then return true end
            return false
        end
        p = p.Parent
    end
    return false
end

local RAYFIELD_PURPLE = {
    TextColor = Color3.fromRGB(205, 200, 215),
    Background = THEME.bg,
    Topbar = THEME.panel,
    TabBackground = THEME.card,
    TabBackgroundSelected = THEME.accent,
    TabTextColor = Color3.fromRGB(155, 150, 175),
    SelectedTabTextColor = Color3.fromRGB(230, 228, 240),
    ElementBackground = THEME.panel,
    ElementBackgroundHover = THEME.card,
    ToggleEnabled = THEME.accent,
    ToggleDisabled = THEME.accentSoft,
    SliderProgress = THEME.accent,
    SliderBackground = THEME.accentSoft,
    SliderStroke = THEME.accentSoft,
    Accent = THEME.accent,
    AccentColor = THEME.accent,
    AccentColor1 = THEME.accent,
    AccentColor2 = THEME.accentSoft,
    AccentColor3 = THEME.accentSoft,
    ToggleColor = THEME.accent,
    ToggleBackground = THEME.panel,
    ToggleBackgroundHover = THEME.card,
    InputBackground = THEME.panel,
    InputBackgroundHover = THEME.card,
    DropdownBackground = THEME.panel,
    DropdownSelected = THEME.accent,
    DropdownUnselected = THEME.card,
    NotificationBackground = THEME.panel,
    NotificationActionsBackground = THEME.card,
    MainColor = THEME.accent,
    TopbarColor = THEME.panel,
    BackgroundColor = THEME.bg,
}

local function remapColorSequence(seq)
    if typeof(seq) ~= "ColorSequence" then return seq end
    local keypoints = {}
    for _, kp in ipairs(seq.Keypoints) do
        keypoints[#keypoints + 1] = ColorSequenceKeypoint.new(kp.Time, remapColor(kp.Value))
    end
    return ColorSequence.new(keypoints)
end

local function applyPurpleThemeTable(themeTable)
    if type(themeTable) ~= "table" then return end
    for k, v in pairs(RAYFIELD_PURPLE) do
        themeTable[k] = v
    end
end

local function getRayfield()
    if getgenv then
        if type(getgenv().Rayfield) == "table" then return getgenv().Rayfield end
        if type(getgenv().RayfieldLibrary) == "table" then return getgenv().RayfieldLibrary end
    end
    if type(_G.Rayfield) == "table" then return _G.Rayfield end
    if type(_G.RayfieldLibrary) == "table" then return _G.RayfieldLibrary end
    if type(Rayfield) == "table" then return Rayfield end
    return nil
end

local function hijackRayfieldLib(lib)
    if type(lib) ~= "table" then return end
    if type(lib.Theme) == "table" then
        for _, themeTable in pairs(lib.Theme) do
            applyPurpleThemeTable(themeTable)
        end
        applyPurpleThemeTable(lib.Theme)
    end
    if type(lib.DefaultTheme) == "table" then
        applyPurpleThemeTable(lib.DefaultTheme)
    end
    if type(lib.DesignTheme) == "table" then
        applyPurpleThemeTable(lib.DesignTheme)
    end
    lib.AccentColor = THEME.accent
    lib.Accent = THEME.accent
    lib.ToggleColor = THEME.accent
    lib.MainColor = THEME.accent
    lib.BackgroundColor = THEME.bg
    lib.TopbarColor = THEME.panel
    if type(lib.SetTheme) == "function" and not lib._FE6SetTheme then
        local oldSetTheme = lib.SetTheme
        lib._FE6SetTheme = true
        lib.SetTheme = function(self, themeTable)
            themeTable = themeTable or {}
            applyPurpleThemeTable(themeTable)
            return oldSetTheme(self, themeTable)
        end
    end
    if type(lib.CreateWindow) == "function" and not lib._FE6Wrap then
        local oldCreate = lib.CreateWindow
        lib._FE6Wrap = true
        lib.CreateWindow = function(self, cfg)
            cfg = cfg or {}
            cfg.Name = WINDOW_TITLE
            cfg.Title = WINDOW_TITLE
            cfg.LoadingTitle = SPLASH_TITLE
            cfg.LoadingSubtitle = CREDIT_TEXT
            cfg.Subtitle = CREDIT_TEXT
            cfg.DisableRayfieldPrompts = true
            cfg.IntroEnabled = true
            cfg.LoadingDuration = 2.5
            cfg.Theme = cfg.Theme or {}
            applyPurpleThemeTable(cfg.Theme)
            local win = oldCreate(self, cfg)
            pcall(function()
                if type(lib.SetTheme) == "function" then
                    local theme = {}
                    applyPurpleThemeTable(theme)
                    lib:SetTheme(theme)
                end
            end)
            task.defer(applyHubPurpleOnce)
            task.delay(0.35, applyHubPurpleOnce)
            task.delay(1, applyHubPurpleOnce)
            return win
        end
    end
end

function hijackRayfieldTheme()
    pcall(function()
        local lib = getRayfield()
        if lib then hijackRayfieldLib(lib) end

        local roots = {}
        if getgenv then roots[#roots + 1] = getgenv() end
        roots[#roots + 1] = _G
        for _, root in ipairs(roots) do
            for _, key in ipairs({ "Rayfield", "RayfieldLibrary", "Library" }) do
                hijackRayfieldLib(root[key])
            end
        end
    end)
end

local function classifyHubColor(color)
    if typeof(color) ~= "Color3" then return nil end
    local r = math.floor(color.R * 255 + 0.5)
    local g = math.floor(color.G * 255 + 0.5)
    local b = math.floor(color.B * 255 + 0.5)
    if r >= 230 and g >= 230 and b >= 230 then return "keep" end
    if r > g + 4 and r > b + 4 and r >= 38 then return "accent" end
    if r >= 45 and r > g + 8 and r > b + 8 then return "accent" end
    if g >= 180 and b >= 180 and r <= 140 then return "accent" end
    if g >= 200 and b >= 200 and r <= 80 then return "accent" end
    if r >= 120 and g <= 120 and b <= 120 and r > g + 10 then return "accent" end
    if r < 18 and g < 14 and b < 22 then return "bg" end
    if r < 48 and g < 38 and b < 62 then return "panel" end
    if r < 72 and g < 55 and b < 88 then return "card" end
    return nil
end

local function hubColorTarget(kind)
    if kind == "accent" then return THEME.accent end
    if kind == "bg" then return THEME.bg end
    if kind == "panel" then return THEME.panel end
    if kind == "card" then return THEME.card end
    return nil
end

local function hubColorNeedsPaint(color)
    if typeof(color) ~= "Color3" then return false end
    return isReddishColor(color) or isRayfieldCyanAccent(color)
end

local function isRayfieldNeutralBg(color)
    if typeof(color) ~= "Color3" then return false end
    local r = math.floor(color.R * 255 + 0.5)
    local g = math.floor(color.G * 255 + 0.5)
    local b = math.floor(color.B * 255 + 0.5)
    if r >= 90 or g >= 90 or b >= 90 then return false end
    if math.abs(r - g) > 12 or math.abs(r - b) > 16 then return false end
    return r <= 55 and g <= 55 and b <= 65
end

local function isHubChromeElement(inst)
    if not inst or not inst:IsA("GuiObject") then return false end
    local n = inst.Name:lower()
    if n == "main" or n == "mainframe" then return true end
    if n:find("topbar", 1, true) or n:find("top bar", 1, true) then return true end
    if n:find("tab", 1, true) then return true end
    return false
end

local function nameHintsInventoryItem(name)
    local n = name:lower()
    for _, hint in ipairs(INVENTORY_ITEM_HINTS) do
        if n:find(hint, 1, true) then return true end
    end
    return false
end

local function isInventoryItemElement(inst)
    return isToySlotFrame(inst)
end

function isInventoryShell(inst)
    return inst and registeredInventoryGuis[inst]
        and (inst:IsA("Frame") or inst:IsA("ScrollingFrame") or inst:IsA("ImageLabel"))
end

local function paintInventoryShell(inst)
    if not isInventoryShell(inst) or isOurOverlay(inst) or isInWrapperHub(inst) then return end
    pcall(function()
        inst.Active = false
        if inst.BackgroundTransparency < 1 then
            inst.BackgroundColor3 = THEME.panel
        elseif inst:IsA("ImageLabel") and inst.ImageTransparency < 1 then
            inst.ImageColor3 = THEME.panel
        end
        inst.BorderSizePixel = 0
        local stroke = inst:FindFirstChild("FE6_InvStroke")
        if stroke then stroke:Destroy() end
    end)
end

local function paintHubObject(inst)
    pcall(function()
        if inst:IsA("GuiObject") then
            local n = inst.Name:lower()
            local chrome = isHubChromeElement(inst)

            if inst.BackgroundTransparency < 1 then
                if isReddishColor(inst.BackgroundColor3) or isRayfieldCyanAccent(inst.BackgroundColor3) then
                    inst.BackgroundColor3 = THEME.accent
                elseif n:find("topbar", 1, true) or n:find("top bar", 1, true) then
                    inst.BackgroundColor3 = THEME.panel
                elseif n == "main" or n == "mainframe" then
                    inst.BackgroundColor3 = THEME.bg
                elseif n:find("tab", 1, true) and (n:find("selected", 1, true) or n:find("active", 1, true)) then
                    if isReddishColor(inst.BackgroundColor3) or isRayfieldCyanAccent(inst.BackgroundColor3) then
                        inst.BackgroundColor3 = THEME.accent
                    end
                elseif chrome and isRayfieldNeutralBg(inst.BackgroundColor3) then
                    local kind = classifyHubColor(inst.BackgroundColor3)
                    local target = hubColorTarget(kind)
                    if target then inst.BackgroundColor3 = target end
                end
            end

            if isReddishColor(inst.BorderColor3) or isRayfieldCyanAccent(inst.BorderColor3) then
                inst.BorderColor3 = THEME.accent
            end

            if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
                if isReddishColor(inst.TextColor3) or isRayfieldCyanAccent(inst.TextColor3) then
                    inst.TextColor3 = THEME.accentSoft
                end
            end

            if inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
                if isReddishColor(inst.ImageColor3) or isRayfieldCyanAccent(inst.ImageColor3) then
                    inst.ImageColor3 = THEME.accent
                end
            end
        end

        if inst:IsA("UIStroke") then
            if isReddishColor(inst.Color) or isRayfieldCyanAccent(inst.Color) then
                inst.Color = THEME.accent
            end
        end

        if inst:IsA("UIGradient") then
            local seq = inst.Color
            if typeof(seq) == "ColorSequence" then
                for _, kp in ipairs(seq.Keypoints) do
                    if isReddishColor(kp.Value) or isRayfieldCyanAccent(kp.Value) then
                        inst.Color = aggressiveRecolorSequence(seq)
                        break
                    end
                end
            end
        end
    end)
end

function quickFixRedHubElements()
    local hub = resolveWrapperHub() or findHubByTabButtons()
    if not hub or not hub.Parent then return end
    registeredHubGuis[hub] = true
    cachedWrapperHub = hub
    for _, inst in ipairs(hub:GetDescendants()) do
        if isOurOverlay(inst) then
            -- skip overlays
        else
        pcall(function()
            if inst:IsA("GuiObject") then
                if inst.BackgroundTransparency < 1 and (isReddishColor(inst.BackgroundColor3) or isRayfieldCyanAccent(inst.BackgroundColor3)) then
                    inst.BackgroundColor3 = THEME.accent
                end
                if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
                    if isReddishColor(inst.TextColor3) or isRayfieldCyanAccent(inst.TextColor3) then
                        inst.TextColor3 = THEME.accentSoft
                    end
                end
                if inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
                    if isReddishColor(inst.ImageColor3) or isRayfieldCyanAccent(inst.ImageColor3) then
                        inst.ImageColor3 = THEME.accent
                    end
                end
            end
            if inst:IsA("UIStroke") and (isReddishColor(inst.Color) or isRayfieldCyanAccent(inst.Color)) then
                inst.Color = THEME.accent
            end
            if inst:IsA("UIGradient") then
                local seq = inst.Color
                if typeof(seq) == "ColorSequence" then
                    for _, kp in ipairs(seq.Keypoints) do
                        if isReddishColor(kp.Value) or isRayfieldCyanAccent(kp.Value) then
                            inst.Color = aggressiveRecolorSequence(seq)
                            break
                        end
                    end
                end
            end
        end)
        end
    end
end

function attachHubPainter(hub)
    if not hub or not hub.Parent or hubPainterAttached[hub] then return end
    hubPainterAttached[hub] = true
    hub.DescendantAdded:Connect(function(inst)
        if isOurOverlay(inst) then return end
        task.defer(function()
            if inst.Parent and isUnderLikelyHub(inst) and not isUnderInventoryGui(inst) then
                paintHubObject(inst)
            end
        end)
    end)
end

function pushRayfieldPurpleTheme()
    pcall(function()
        hijackRayfieldTheme()
        local lib = getRayfield()
        if lib and type(lib.SetTheme) == "function" then
            local theme = {}
            applyPurpleThemeTable(theme)
            lib:SetTheme(theme)
        end
    end)
end

function applyHubPurpleOnce()
    hijackRayfieldTheme()
    pushRayfieldPurpleTheme()
    discoverAndRegisterHubs()
    purgeHubMistakenInventory()

    local hubs = {}
    local seen = {}

    local function addHub(gui)
        if not gui or not gui.Parent or seen[gui] or isInventoryGui(gui) then return end
        if not (registeredHubGuis[gui] or looksLikeHubGui(gui)) then return end
        registeredHubGuis[gui] = true
        seen[gui] = true
        hubs[#hubs + 1] = gui
    end

    addHub(resolveWrapperHub())
    addHub(findHubByTabButtons())
    for _, root in ipairs(getGuiScanRoots()) do
        for _, gui in ipairs(root:GetChildren()) do
            if gui:IsA("ScreenGui") then
                registerHubGui(gui)
                addHub(gui)
            end
        end
    end

    if #hubs == 0 then return end

    for _, hub in ipairs(hubs) do
        cachedWrapperHub = cachedWrapperHub or hub
        attachHubPainter(hub)
        pcall(function()
            paintHubObject(hub)
            for _, inst in ipairs(hub:GetDescendants()) do
                if not isOurOverlay(inst) and not isUnderInventoryGui(inst) then
                    paintHubObject(inst)
                end
            end
        end)
    end
    quickFixRedHubElements()
end

function forceHubPurple(inst)
    if not inst or isOurOverlay(inst) or not isInWrapperHub(inst) then return end
    paintHubObject(inst)
end

function aggressiveRecolor(color)
    if typeof(color) ~= "Color3" then return color end
    if isReddishColor(color) or isRayfieldCyanAccent(color) then
        return THEME.accent
    end
    return color
end

function aggressiveRecolorSequence(seq)
    if typeof(seq) ~= "ColorSequence" then return seq end
    local keypoints = {}
    for _, kp in ipairs(seq.Keypoints) do
        keypoints[#keypoints + 1] = ColorSequenceKeypoint.new(kp.Time, aggressiveRecolor(kp.Value))
    end
    return ColorSequence.new(keypoints)
end

function brutalPaintInstance(inst)
    if not inst or isOurOverlay(inst) or isUnderInventoryGui(inst) or not isInWrapperHub(inst) then return end
    paintHubObject(inst)
end

local function brutalPaintGui(gui)
    if not gui or not gui.Parent or isInventoryGui(gui) then return end
    paintHubObject(gui)
    for _, inst in ipairs(gui:GetDescendants()) do
        if not isUnderInventoryGui(inst) then
            paintHubObject(inst)
        end
    end
end

local function paintHubGui(gui)
    if not gui or not gui.Parent then return end
    registeredHubGuis[gui] = true
    cachedWrapperHub = cachedWrapperHub or gui
    brutalPaintGui(gui)
end

local function paintInventoryRoot(root)
    if not root or not root.Parent then return end
    paintInventoryShell(root)
end

local function paintHubInstance(inst)
    if not inst or isOurOverlay(inst) or isUnderInventoryGui(inst) or not isInWrapperHub(inst) then return end
    paintHubObject(inst)
end

local function guardHubColorProperty(inst, prop)
    pcall(function()
        if not inst.GetPropertyChangedSignal then return end
        local attr = "FE6_HubGuard_" .. prop
        if inst:GetAttribute(attr) then return end
        inst:SetAttribute(attr, true)
        inst:GetPropertyChangedSignal(prop):Connect(function()
            if not inst.Parent or isOurOverlay(inst) or not isUnderLikelyHub(inst) then return end
            local ok, val = pcall(function() return inst[prop] end)
            if ok and (isReddishColor(val) or isRayfieldCyanAccent(val)) then
                if inst[prop] ~= THEME.accent and inst[prop] ~= THEME.accentSoft then
                    inst[prop] = THEME.accent
                end
            end
        end)
    end)
end

function guardHubElement(inst)
    if not inst or isOurOverlay(inst) or not isUnderLikelyHub(inst) then return end
    if inst:GetAttribute("FE6_HubGuard") then return end
    inst:SetAttribute("FE6_HubGuard", true)
    paintHubInstance(inst)
    if inst:IsA("GuiObject") then
        for prop in pairs(COLOR_PROPS) do
            guardHubColorProperty(inst, prop)
        end
    end
    if inst:IsA("UIStroke") then
        guardHubColorProperty(inst, "Color")
    end
    if inst:IsA("UIGradient") then
        guardHubColorProperty(inst, "Color")
    end
end

function sweepHubTheme(force)
    if not force and tick() - lastSweepAt < SWEEP_MIN_INTERVAL then
        return
    end
    lastSweepAt = tick()
    applyHubPurpleOnce()
end

local purpleBurstToken = 0

function paintAllHubsPurple()
    applyHubPurpleOnce()
end

function schedulePurpleBurst(count, interval)
    purpleBurstToken = purpleBurstToken + 1
    local token = purpleBurstToken
    local passes = math.min(count or 3, 3)
    for i = 1, passes do
        task.delay((interval or 1) * i, function()
            if token == purpleBurstToken then
                applyHubPurpleOnce()
            end
        end)
    end
end

function preloadRayfield()
    if getRayfield() then
        hijackRayfieldTheme()
        return true
    end
    local ok = pcall(function()
        local src = patchRayfieldSource(httpGet(RAYFIELD_URL))
        local fn, compileErr = loadstring(src)
        if not fn then
            error("Rayfield compile: " .. tostring(compileErr))
        end
        fn()
    end)
    if ok then
        hijackRayfieldTheme()
    end
    return ok
end

function connectGuiRootChildAdded(callback)
    for _, root in ipairs(getGuiScanRoots()) do
        root.ChildAdded:Connect(callback)
    end
end

function installHubPaintWatcher()
    if hubPaintWatcherInstalled then return end
    hubPaintWatcherInstalled = true
    connectGuiRootChildAdded(function(child)
        if not child:IsA("ScreenGui") or OUR_OVERLAY_NAMES[child.Name] or isChatOrSystemGui(child) then
            return
        end
        registerHubGui(child)
        if registeredHubGuis[child] or looksLikeHubGui(child) then
            registeredHubGuis[child] = true
            scheduleSweep(0.25, true)
        end
    end)
end

function installHubPurpleEnforcer()
    if hubEnforceConn then return end
    installHubPaintWatcher()
    hubEnforceConn = RunService.Heartbeat:Connect(function()
        if tick() - lastRedFixAt >= HUB_RED_FIX_INTERVAL then
            lastRedFixAt = tick()
            quickFixRedHubElements()
        end
        if inventoryPurpleOn and tick() - lastInventoryEnforceAt >= INVENTORY_ENFORCE_INTERVAL then
            lastInventoryEnforceAt = tick()
            refreshInventoryPurple()
        end
    end)
end

function refreshInventoryPurple()
    if not inventoryPurpleOn then return end
    discoverInventoryRoots()
    local painted = {}
    for root in pairs(registeredInventoryGuis) do
        if root.Parent and not painted[root] then
            painted[root] = true
            paintInventoryRoot(root)
        elseif not root.Parent then
            registeredInventoryGuis[root] = nil
        end
    end
end

function scheduleSweep(delay, force)
    sweepToken = sweepToken + 1
    local token = sweepToken
    task.delay(delay or 0.25, function()
        if token ~= sweepToken then return end
        sweepHubTheme(force == true)
    end)
end

function scheduleInventoryRefresh(delay)
    inventoryToken = inventoryToken + 1
    local token = inventoryToken
    task.delay(delay or 0.35, function()
        if token ~= inventoryToken or not inventoryPurpleOn then return end
        refreshInventoryPurple()
    end)
end

function runInitialHubPasses()
    task.delay(1.2, function()
        applyHubPurpleOnce()
        ensureHubVisible()
    end)
end

function forceOpenRayfieldHub()
    pcall(function()
        discoverAndRegisterHubs()
        for _, root in ipairs(getGuiScanRoots()) do
            for _, gui in ipairs(root:GetChildren()) do
                if gui:IsA("ScreenGui") and not OUR_OVERLAY_NAMES[gui.Name] and not isChatOrSystemGui(gui) then
                    if isLoadingOnlyGui(gui) then
                        gui:Destroy()
                    elseif screenGuiLooksLikeHub(gui) then
                        registeredHubGuis[gui] = true
                        gui.Enabled = true
                        for _, childName in ipairs({ "Main", "MainFrame", "MainWindow" }) do
                            local main = gui:FindFirstChild(childName, true)
                            if main and main:IsA("GuiObject") then
                                main.Visible = true
                            end
                        end
                    end
                end
            end
        end
        local lib = getRayfield()
        if lib and type(lib.LoadConfiguration) == "function" then
            pcall(function() lib:LoadConfiguration() end)
        end
        ensureBackpackEnabled()
    end)
end

function ensureHubVisible()
    forceOpenRayfieldHub()
end
function findMainHubGui()
    for _, root in ipairs(getGuiScanRoots()) do
        for _, gui in ipairs(root:GetChildren()) do
            if gui:IsA("ScreenGui") and not OUR_OVERLAY_NAMES[gui.Name] and not isGameInventoryGui(gui) then
                if registeredHubGuis[gui] then
                    return gui
                end
            end
        end
    end
    for _, root in ipairs(getGuiScanRoots()) do
        for _, gui in ipairs(root:GetChildren()) do
            if gui:IsA("ScreenGui") and not OUR_OVERLAY_NAMES[gui.Name] and not isGameInventoryGui(gui) then
                if screenGuiLooksLikeHub(gui) then
                    registeredHubGuis[gui] = true
                    return gui
                end
            end
        end
    end
    return nil
end

function suppressRayfieldLoading()
    pcall(function()
        for _, gui in ipairs(PlayerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and isLoadingOnlyGui(gui) then
                gui:Destroy()
            end
        end
    end)
end

end -- hub purple scope


local cleanupDevilArtifacts
local createEliteSplash

local function stopSplashRain()
    if splashRainConn then
        splashRainConn:Disconnect()
        splashRainConn = nil
    end
end

local function showBriefEliteSplash()
    if splashActive then return end
    splashActive = true
    pcall(function() if createEliteSplash then createEliteSplash() end end)
end

-- Classic full-screen splash: dark + purple, big skull, SKILZ HUB, skull rain
local function startSkullRain(parent)
    stopSplashRain()
    if not parent then return end
    local rainFolder = Instance.new("Folder")
    rainFolder.Name = "FE6_SkullRain"
    rainFolder.Parent = parent
    table.insert(devilArtifacts, rainFolder)
    -- seed many skulls at once (looks like BloodyV2 load)
    for i = 1, 28 do
        local skull = Instance.new("TextLabel")
        skull.BackgroundTransparency = 1
        local sz = math.random(20, 42)
        skull.Size = UDim2.new(0, sz, 0, sz)
        skull.Position = UDim2.new(math.random() * 0.92, 0, math.random() * -0.4 - 0.05, 0)
        skull.Font = Enum.Font.GothamBold
        skull.TextSize = sz
        skull.Text = "\u{1F480}"
        skull.TextColor3 = Color3.fromRGB(math.random(90, 140), math.random(50, 90), math.random(160, 230))
        skull.TextTransparency = math.random() * 0.25
        skull.Rotation = math.random(-30, 30)
        skull.ZIndex = 2
        skull.Parent = rainFolder
        local dur = 1.4 + math.random() * 1.2
        local xDrift = (math.random() - 0.5) * 0.15
        TweenService:Create(skull, TweenInfo.new(dur, Enum.EasingStyle.Linear), {
            Position = UDim2.new(math.clamp(skull.Position.X.Scale + xDrift, 0, 0.95), 0, 1.12, 0),
            TextTransparency = 1,
            Rotation = skull.Rotation + math.random(-50, 50),
        }):Play()
        Debris:AddItem(skull, dur + 0.1)
    end
    local t0 = tick()
    splashRainConn = RunService.Heartbeat:Connect(function()
        if not parent.Parent or tick() - t0 > 2.5 then
            stopSplashRain()
            return
        end
        if math.random() > 0.55 then return end
        local skull = Instance.new("TextLabel")
        skull.BackgroundTransparency = 1
        local sz = math.random(16, 34)
        skull.Size = UDim2.new(0, sz, 0, sz)
        skull.Position = UDim2.new(math.random() * 0.95, 0, -0.1, 0)
        skull.Font = Enum.Font.GothamBold
        skull.TextSize = sz
        skull.Text = "\u{1F480}"
        skull.TextColor3 = THEME.accentLight
        skull.TextTransparency = 0.1
        skull.ZIndex = 2
        skull.Parent = rainFolder
        local dur = 1.2 + math.random() * 0.8
        TweenService:Create(skull, TweenInfo.new(dur, Enum.EasingStyle.Linear), {
            Position = UDim2.new(skull.Position.X.Scale, 0, 1.1, 0),
            TextTransparency = 1,
        }):Play()
        Debris:AddItem(skull, dur + 0.05)
    end)
end

createEliteSplash = function()
    stopSplashRain()
    devilArtifacts = {}
    if eliteSplashGui and eliteSplashGui.Parent then
        pcall(function() eliteSplashGui:Destroy() end)
    end
    eliteSplashGui = nil
    splashActive = true

    local gui = Instance.new("ScreenGui")
    gui.Name = "FE6_EliteSplash"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 100000
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local parented = false
    pcall(function()
        if gethui then gui.Parent = gethui(); parented = gui.Parent ~= nil end
    end)
    if not parented then
        pcall(function()
            gui.Parent = game:GetService("CoreGui")
            parented = gui.Parent ~= nil
        end)
    end
    if not parented then gui.Parent = PlayerGui end
    eliteSplashGui = gui
    table.insert(devilArtifacts, gui)

    -- full black/purple backdrop
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(8, 4, 16)
    bg.BackgroundTransparency = 0
    bg.BorderSizePixel = 0
    bg.ZIndex = 0
    bg.Parent = gui
    table.insert(devilArtifacts, bg)

    local vignette = Instance.new("Frame")
    vignette.Size = UDim2.new(1, 0, 1, 0)
    vignette.BackgroundColor3 = Color3.fromRGB(40, 10, 70)
    vignette.BackgroundTransparency = 0.55
    vignette.BorderSizePixel = 0
    vignette.ZIndex = 1
    vignette.Parent = gui
    table.insert(devilArtifacts, vignette)

    startSkullRain(gui)

    -- center branding (classic hub load screen, not a small card)
    local heroSkull = Instance.new("TextLabel")
    heroSkull.Size = UDim2.new(1, 0, 0, 90)
    heroSkull.Position = UDim2.new(0, 0, 0.38, -70)
    heroSkull.BackgroundTransparency = 1
    heroSkull.Font = Enum.Font.GothamBold
    heroSkull.TextSize = 72
    heroSkull.Text = "\u{1F480}"
    heroSkull.TextColor3 = THEME.accent
    heroSkull.ZIndex = 10
    heroSkull.Parent = gui
    table.insert(devilArtifacts, heroSkull)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 48)
    title.Position = UDim2.new(0, 0, 0.38, 30)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 42
    title.Text = "SKILZ HUB"
    title.TextColor3 = Color3.fromRGB(245, 240, 255)
    title.ZIndex = 10
    title.Parent = gui
    table.insert(devilArtifacts, title)

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, 0, 0, 28)
    sub.Position = UDim2.new(0, 0, 0.38, 78)
    sub.BackgroundTransparency = 1
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 16
    sub.Text = CREDIT_TEXT
    sub.TextColor3 = THEME.accentSoft
    sub.ZIndex = 10
    sub.Parent = gui
    table.insert(devilArtifacts, sub)

    local tag = Instance.new("TextLabel")
    tag.Size = UDim2.new(1, 0, 0, 24)
    tag.Position = UDim2.new(0, 0, 0.38, 108)
    tag.BackgroundTransparency = 1
    tag.Font = Enum.Font.GothamBold
    tag.TextSize = 14
    tag.Text = "\u{1F480}  " .. CHAT_MSG .. "  \u{1F480}"
    tag.TextColor3 = THEME.accentLight
    tag.ZIndex = 10
    tag.Parent = gui
    table.insert(devilArtifacts, tag)

    task.delay(2.8, function()
        if not gui.Parent then return end
        stopSplashRain()
        local fade = TweenInfo.new(0.5, Enum.EasingStyle.Quad)
        for _, ch in ipairs(gui:GetDescendants()) do
            if ch:IsA("TextLabel") then
                TweenService:Create(ch, fade, { TextTransparency = 1 }):Play()
            elseif ch:IsA("Frame") then
                TweenService:Create(ch, fade, { BackgroundTransparency = 1 }):Play()
            end
        end
        TweenService:Create(bg, fade, { BackgroundTransparency = 1 }):Play()
    end)

    task.delay(3.4, function()
        stopSplashRain()
        if gui and gui.Parent then pcall(function() gui:Destroy() end) end
        if eliteSplashGui == gui then
            eliteSplashGui = nil
            splashActive = false
        end
    end)

    return gui
end

cleanupDevilArtifacts = function()
    splashActive = false
    stopSplashRain()
    for _, obj in ipairs(devilArtifacts) do
        pcall(function()
            if obj and obj.Parent then
                obj:Destroy()
            end
        end)
    end
    devilArtifacts = {}
    pcall(function()
        if eliteSplashGui and eliteSplashGui.Parent then
            eliteSplashGui:Destroy()
        end
        for _, child in ipairs(PlayerGui:GetChildren()) do
            if child.Name == "FE6_Splash" or child.Name == "FE6_EliteSplash" or child.Name == "FE6_ClownReplace" then
                child:Destroy()
            end
        end
    end)
    eliteSplashGui = nil
end

local function saveLightingState()
    savedLighting = {
        Ambient          = Lighting.Ambient,
        OutdoorAmbient   = Lighting.OutdoorAmbient,
        ColorShift_Top   = Lighting.ColorShift_Top,
        ColorShift_Bottom = Lighting.ColorShift_Bottom,
        Brightness       = Lighting.Brightness,
        ClockTime        = Lighting.ClockTime,
        GeographicLatitude = Lighting.GeographicLatitude,
        GlobalShadows    = Lighting.GlobalShadows,
        FogColor         = Lighting.FogColor,
        FogEnd           = Lighting.FogEnd,
        FogStart         = Lighting.FogStart,
    }
end

local function restoreLightingState()
    for k, v in pairs(savedLighting) do
        pcall(function() Lighting[k] = v end)
    end
end

local function destroySkyEffects()
    for _, name in ipairs(SKY_EFFECT_NAMES) do
        local obj = Lighting:FindFirstChild(name)
        if obj then obj:Destroy() end
    end
end

local function destroyScaryEffects()
    for _, name in ipairs(SCARY_EFFECT_NAMES) do
        local obj = Lighting:FindFirstChild(name)
        if obj then obj:Destroy() end
    end
end

local function restoreAllPlayerHorror()
    for part, data in pairs(scaryPlayerBackup) do
        pcall(function()
            if part and part.Parent then
                part.Color = data.Color
                part.Material = data.Material
                part.Transparency = data.Transparency
                if data.TextureID ~= nil and part:IsA("MeshPart") then
                    part.TextureID = data.TextureID
                end
            end
        end)
    end
    scaryPlayerBackup = {}

    for _, conn in ipairs(scaryPlayerConns) do
        pcall(function() conn:Disconnect() end)
    end
    scaryPlayerConns = {}

    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        if char then
            for _, inst in ipairs(char:GetDescendants()) do
                if type(inst.Name) == "string" and inst.Name:find("FE6_Scary", 1, true) then
                    inst:Destroy()
                end
            end
            local hl = char:FindFirstChild("FE6_ScaryHighlight")
            if hl then hl:Destroy() end
        end
    end
end

local function clearScaryMapFires()
    for _, entry in ipairs(scaryFireHosts) do
        pcall(function()
            if entry.fire and entry.fire.Parent then entry.fire:Destroy() end
            if entry.smoke and entry.smoke.Parent then entry.smoke:Destroy() end
            if entry.owned and entry.part and entry.part.Parent then
                entry.part:Destroy()
            elseif entry.part and entry.part.Parent and entry.oldColor then
                entry.part.Color = entry.oldColor
            end
        end)
    end
    for i = #scaryFireHosts, 1, -1 do
        scaryFireHosts[i] = nil
    end
end

local function clearSavedLightingIfIdle()
    if skyShaderMode == "off" and scaryShaderMode == "off" then
        savedLighting = {}
    end
end

local function styleOverlayButton(btn, accentColor)
    btn.BackgroundColor3 = accentColor
    btn.BackgroundTransparency = 0.44
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(245, 245, 245)
    btn.TextTransparency = 0.08
    btn.AutoButtonColor = true
    btn.Active = true
    btn.Selectable = true
    btn.ZIndex = 5

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = accentColor
    stroke.Thickness = 1.5
    stroke.Transparency = 0.55
    stroke.Parent = btn
end

local function destroySkyCursor()
    if skyCursorConn then
        skyCursorConn:Disconnect()
        skyCursorConn = nil
    end
    for _, entry in ipairs(skyCursorDrawings) do
        pcall(function()
            entry.obj.Visible = false
            entry.obj:Remove()
        end)
    end
    for i = #skyCursorDrawings, 1, -1 do
        skyCursorDrawings[i] = nil
    end
    local stale = PlayerGui:FindFirstChild("FE6_SkyCursor")
    if stale then stale:Destroy() end
end

local function isMouseUnlocked()
    return UserInputService.MouseIconEnabled == true
end

local function refreshUnlockedCursor()
    if not purpleSkyOn or not isMouseUnlocked() then
        return
    end
    pcall(function()
        local mouse = LocalPlayer:GetMouse()
        if mouse then
            local icon = tostring(mouse.Icon or "")
            if icon == "" or icon == "rbxassetid://0" then
                mouse.Icon = MOUSE_CURSOR_ICON
            end
        end
    end)
end

local function setSkyCursorDrawingsVisible(visible)
    for _, entry in ipairs(skyCursorDrawings) do
        if entry.obj then
            entry.obj.Visible = visible
        end
    end
end

local function addSkyCursorDrawing(role, kind, props)
    if not Drawing or type(Drawing.new) ~= "function" then
        return nil
    end
    local drawing = Drawing.new(kind)
    for key, value in pairs(props) do
        drawing[key] = value
    end
    drawing.Visible = true
    drawing.Transparency = 0
    skyCursorDrawings[#skyCursorDrawings + 1] = { role = role, obj = drawing }
    return drawing
end

local function createSkyCursor()
    destroySkyCursor()
    if not purpleSkyOn then return end

    addSkyCursorDrawing("ring", "Circle", {
        Radius = 8,
        Filled = false,
        Thickness = 2,
        Color = THEME.accentLight,
    })
    addSkyCursorDrawing("dot", "Circle", {
        Radius = 3.5,
        Filled = true,
        Thickness = 1,
        Color = Color3.fromRGB(255, 255, 255),
    })
    addSkyCursorDrawing("hline", "Line", {
        Thickness = 2,
        Color = Color3.fromRGB(255, 255, 255),
    })
    addSkyCursorDrawing("vline", "Line", {
        Thickness = 2,
        Color = Color3.fromRGB(255, 255, 255),
    })

    skyCursorConn = RunService.RenderStepped:Connect(function()
        if not purpleSkyOn then
            destroySkyCursor()
            return
        end
        if not isMouseUnlocked() then
            setSkyCursorDrawingsVisible(false)
            return
        end
        refreshUnlockedCursor()
        local pos = UserInputService:GetMouseLocation()
        local center = Vector2.new(pos.X, pos.Y)
        for _, entry in ipairs(skyCursorDrawings) do
            local drawing = entry.obj
            if drawing then
                drawing.Visible = true
                if entry.role == "ring" or entry.role == "dot" then
                    drawing.Position = center
                elseif entry.role == "hline" then
                    drawing.From = center + Vector2.new(-10, 0)
                    drawing.To = center + Vector2.new(10, 0)
                elseif entry.role == "vline" then
                    drawing.From = center + Vector2.new(0, -10)
                    drawing.To = center + Vector2.new(0, 10)
                end
            end
        end
    end)
end

local function restoreDefaultMouse()
    if purpleSkyOn then return end
    pcall(function()
        local stale = PlayerGui:FindFirstChild("FE6_Cursor")
        if stale then stale:Destroy() end
        UserInputService.MouseIconEnabled = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        if Enum.OverrideMouseIconBehavior then
            UserInputService.OverrideMouseIconBehavior = Enum.OverrideMouseIconBehavior.None
        end
        local mouse = LocalPlayer:GetMouse()
        if mouse then
            mouse.Icon = ""
        end
    end)
end

local function setSkyCursorActive(active)
    if active then
        createSkyCursor()
    else
        destroySkyCursor()
        restoreDefaultMouse()
    end
end

local function cleanupWorldEffects()
    purpleSkyOn = false
    skyShaderMode = "off"
    scaryShaderMode = "off"
    destroySkyCursor()
    destroySkyEffects()
    destroyScaryEffects()
    restoreAllPlayerHorror()
    clearScaryMapFires()
    if scaryNpcConn then
        scaryNpcConn:Disconnect()
        scaryNpcConn = nil
    end
    for i = #scaryFigures, 1, -1 do
        scaryFigures[i] = nil
    end
    if scaryWorldFolder and scaryWorldFolder.Parent then
        scaryWorldFolder:Destroy()
    end
    scaryWorldFolder = nil
    if savedLighting.Ambient then
        restoreLightingState()
        savedLighting = {}
    end
    destroyEliteSpawn()
    restoreDefaultMouse()
end

local setSkyShader
local setScaryShader
local cycleScaryShader

local function updateSkyShaderLabels()
    local overlayText = "💜 Sky: OFF"
    local miscText = "  Purple Sky Shader"

    if skyShaderMode == "day" then
        overlayText = "☀️ Day Sky"
        miscText = "  ☀️ Purple Day Sky"
    elseif skyShaderMode == "night" then
        overlayText = "🌙 Night Sky"
        miscText = "  🌙 Purple Night Sky"
    end

    if skyOverlay then
        local btn = skyOverlay:FindFirstChild("ToggleBtn", true)
        if btn and btn:IsA("TextButton") then
            btn.Text = overlayText
            btn.BackgroundColor3 = purpleSkyOn and THEME.accent or THEME.panel
        end
    end

    for _, inst in ipairs(PlayerGui:GetDescendants()) do
        if inst.Name == "FE6_PurpleSkyToggle" and inst:IsA("TextButton") then
            inst.Text = miscText
            break
        end
    end
end

local function buildSkyEffects(mode)
    destroySkyEffects()

    local atmo = Instance.new("Atmosphere")
    atmo.Name = "FE6_PurpleAtmo"
    atmo.Parent = Lighting

    local sunRays = Instance.new("SunRaysEffect")
    sunRays.Name = "FE6_SunRays"
    sunRays.Parent = Lighting

    local cc = Instance.new("ColorCorrectionEffect")
    cc.Name = "FE6_AmbientCC"
    cc.Parent = Lighting

    local bloom = Instance.new("BloomEffect")
    bloom.Name = "FE6_AmbientBloom"
    bloom.Parent = Lighting

    if mode == "day" then
        -- Cozy-house fog: soft hazy purple daylight
        Lighting.Ambient            = Color3.fromRGB(148, 132, 182)
        Lighting.OutdoorAmbient     = Color3.fromRGB(168, 148, 202)
        Lighting.ColorShift_Top     = Color3.fromRGB(228, 210, 248)
        Lighting.ColorShift_Bottom  = Color3.fromRGB(186, 168, 218)
        Lighting.Brightness         = 2.15
        Lighting.ClockTime          = 14.2
        Lighting.GeographicLatitude = 28
        Lighting.FogColor           = Color3.fromRGB(196, 178, 226)
        Lighting.FogEnd             = 260
        Lighting.FogStart           = 0
        Lighting.GlobalShadows      = true

        atmo.Density = 0.52
        atmo.Offset = 0.12
        atmo.Color = Color3.fromRGB(214, 198, 236)
        atmo.Decay = Color3.fromRGB(148, 128, 182)
        atmo.Glare = 0.12
        atmo.Haze = 2.55

        sunRays.Intensity = 0.07
        sunRays.Spread = 0.42

        cc.Brightness = 0.08
        cc.Contrast = -0.14
        cc.Saturation = -0.04
        cc.TintColor = Color3.fromRGB(202, 186, 228)

        bloom.Intensity = 0.38
        bloom.Size = 26
        bloom.Threshold = 0.92
    else
        -- Purple sunset: sun dipping, dusk haze, deep violet shadows
        Lighting.Ambient            = Color3.fromRGB(88, 68, 118)
        Lighting.OutdoorAmbient     = Color3.fromRGB(102, 78, 136)
        Lighting.ColorShift_Top     = Color3.fromRGB(255, 168, 228)
        Lighting.ColorShift_Bottom  = Color3.fromRGB(38, 16, 58)
        Lighting.Brightness         = 1.28
        Lighting.ClockTime          = 18.45
        Lighting.GeographicLatitude = 14
        Lighting.FogColor           = Color3.fromRGB(128, 98, 162)
        Lighting.FogEnd             = 340
        Lighting.FogStart           = 14
        Lighting.GlobalShadows      = true

        atmo.Density = 0.46
        atmo.Offset = 0.2
        atmo.Color = Color3.fromRGB(198, 152, 218)
        atmo.Decay = Color3.fromRGB(72, 42, 108)
        atmo.Glare = 0.36
        atmo.Haze = 2.15

        sunRays.Intensity = 0.3
        sunRays.Spread = 0.74

        cc.Brightness = -0.03
        cc.Contrast = 0.04
        cc.Saturation = 0.14
        cc.TintColor = Color3.fromRGB(188, 142, 212)

        bloom.Intensity = 0.34
        bloom.Size = 24
        bloom.Threshold = 0.98
    end
end

setSkyShader = function(mode, skipScaryDisable)
    if mode ~= "off" and mode ~= "day" and mode ~= "night" then
        mode = "off"
    end

    if mode ~= "off" and not skipScaryDisable and setScaryShader then
        setScaryShader("off", true)
    end

    skyShaderMode = mode
    purpleSkyOn = mode ~= "off"

    if purpleSkyOn then
        if not savedLighting.Ambient then saveLightingState() end
        buildSkyEffects(mode)
    else
        destroySkyEffects()
        if scaryShaderMode == "off" then
            restoreLightingState()
            Lighting.FogStart = 0
        end
        clearSavedLightingIfIdle()
    end

    updateSkyShaderLabels()
    setSkyCursorActive(false)
end

local function cycleSkyShader()
    if skyShaderMode == "off" then
        setSkyShader("day")
    elseif skyShaderMode == "day" then
        setSkyShader("night")
    else
        setSkyShader("off")
    end
end

local function setPurpleSky(enabled)
    if enabled then
        setSkyShader(skyShaderMode == "off" and "day" or skyShaderMode)
    else
        setSkyShader("off")
    end
end

local spawnScaryWorld
local destroyScaryWorld

do
local function getScaryAnchor()
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then return hrp.Position end
    end
    local cam = workspace.CurrentCamera
    if cam then return cam.CFrame.Position end
    return Vector3.new(0, 8, 0)
end

local function getScaryRaycastParams()
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local exclude = {}
    if scaryWorldFolder then table.insert(exclude, scaryWorldFolder) end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then table.insert(exclude, plr.Character) end
    end
    params.FilterDescendantsInstances = exclude
    return params
end

local function findScaryGroundPos(origin, radius, angle)
    local flat = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
    local start = origin + flat + Vector3.new(0, 90, 0)
    local hit = workspace:Raycast(start, Vector3.new(0, -220, 0), getScaryRaycastParams())
    if hit then
        return hit.Position + Vector3.new(0, 0.2, 0), hit.Normal
    end
    return origin + flat, Vector3.new(0, 1, 0)
end

local function getHorrorWorldParent()
    return workspace:FindFirstChild("Map")
        or workspace:FindFirstChild("World")
        or workspace:FindFirstChild("GAME")
        or workspace:FindFirstChild("Game")
        or workspace:FindFirstChild("Workspace")
        or workspace
end

local function findRandomMapGroundPos(center)
    local x = center.X + math.random(-SCARY_MAP_RANGE, SCARY_MAP_RANGE)
    local z = center.Z + math.random(-SCARY_MAP_RANGE, SCARY_MAP_RANGE)
    local y = center.Y + 120
    local hit = workspace:Raycast(Vector3.new(x, y, z), Vector3.new(0, -280, 0), getScaryRaycastParams())
    if hit and hit.Instance then
        if scaryWorldFolder and hit.Instance:IsDescendantOf(scaryWorldFolder) then
            return nil
        end
        return hit.Position + Vector3.new(0, 0.15, 0)
    end
    return nil
end

local function makeScaryPart(props)
    local part = Instance.new("Part")
    part.Anchored = true
    part.CanCollide = false
    part.CastShadow = false
    part.Material = props.Material or Enum.Material.SmoothPlastic
    part.Color = props.Color or Color3.fromRGB(25, 25, 25)
    part.Size = props.Size or Vector3.new(1, 1, 1)
    part.Transparency = props.Transparency or 0
    part.Name = props.Name or "Part"
    if props.Shape then part.Shape = props.Shape end
    if props.CFrame then part.CFrame = props.CFrame end
    part.Parent = props.Parent
    return part
end

local function buildScaryFigure(rootPos, lookAt, mode)
    local model = Instance.new("Model")
    model.Name = "FE6_ScaryFigure"
    model.Parent = scaryWorldFolder

    local faceDir = (lookAt - rootPos) * Vector3.new(1, 0, 1)
    if faceDir.Magnitude < 0.1 then
        faceDir = Vector3.new(0, 0, -1)
    else
        faceDir = faceDir.Unit
    end

    local rootCF = CFrame.lookAt(
        rootPos + Vector3.new(0, 3.5, 0),
        rootPos + Vector3.new(0, 3.5, 0) + faceDir
    ) * CFrame.Angles(math.rad(8), math.rad(math.random(-35, 35)), 0)

    local function partAt(name, size, color, offset, material, transparency)
        return makeScaryPart({
            Name = name,
            Parent = model,
            Size = size,
            Color = color,
            Material = material or Enum.Material.Slate,
            Transparency = transparency or 0,
            CFrame = rootCF * offset,
        })
    end

    local torso = partAt("Torso", Vector3.new(2.1, 3.4, 1), Color3.fromRGB(8, 8, 8), CFrame.new())
    local head = partAt("Head", Vector3.new(1.5, 1.7, 1.5), Color3.fromRGB(6, 6, 6), CFrame.new(0, 2.55, 0.15))
    partAt("Jaw", Vector3.new(1.1, 0.35, 0.9), Color3.fromRGB(4, 4, 4), CFrame.new(0, 1.75, 0.55) * CFrame.Angles(math.rad(25), 0, 0))
    partAt("LeftArm", Vector3.new(0.55, 3.2, 0.55), Color3.fromRGB(10, 10, 10), CFrame.new(-1.35, 0.1, 0.35) * CFrame.Angles(math.rad(-35), 0, math.rad(18)))
    partAt("RightArm", Vector3.new(0.55, 3.2, 0.55), Color3.fromRGB(10, 10, 10), CFrame.new(1.35, 0.05, 0.35) * CFrame.Angles(math.rad(-40), 0, math.rad(-22)))
    partAt("ReachArm", Vector3.new(0.45, 2.4, 0.45), Color3.fromRGB(12, 12, 12), CFrame.new(0.15, 0.35, 1.05) * CFrame.Angles(math.rad(-78), 0, 0))
    partAt("LeftLeg", Vector3.new(0.75, 3, 0.75), Color3.fromRGB(6, 6, 6), CFrame.new(-0.5, -3.1, 0))
    partAt("RightLeg", Vector3.new(0.75, 3, 0.75), Color3.fromRGB(6, 6, 6), CFrame.new(0.5, -3.1, 0))
    partAt("BloodChest", Vector3.new(1.5, 1.8, 0.14), Color3.fromRGB(170, 0, 0), CFrame.new(0, 0.15, 0.58), Enum.Material.Neon, 0)
    partAt("BloodFace", Vector3.new(1, 0.65, 0.1), Color3.fromRGB(150, 0, 0), CFrame.new(0, -0.15, 0.82), Enum.Material.Neon, 0)
    partAt("BloodDripHead", Vector3.new(0.2, 1.4, 0.2), Color3.fromRGB(130, 0, 0), CFrame.new(0.25, 1.55, 0.78), Enum.Material.Neon, 0.05)

    for _, side in ipairs({-0.32, 0.32}) do
        partAt(
            side < 0 and "LeftEyeOuter" or "RightEyeOuter",
            Vector3.new(0.38, 0.38, 0.12),
            Color3.fromRGB(0, 0, 0),
            CFrame.new(side, 2.62, 0.78),
            Enum.Material.SmoothPlastic,
            0
        )
        partAt(
            side < 0 and "LeftEye" or "RightEye",
            Vector3.new(0.16, 0.16, 0.16),
            Color3.fromRGB(255, 0, 0),
            CFrame.new(side, 2.62, 0.86),
            Enum.Material.Neon,
            mode == "night" and 0 or 0.1
        )
    end

    local mouth = partAt("MouthVoid", Vector3.new(0.75, 0.18, 0.12), Color3.fromRGB(0, 0, 0), CFrame.new(0, 2.15, 0.8), Enum.Material.Neon, 0)

    local glow = Instance.new("PointLight")
    glow.Name = "FE6_ScaryNpcGlow"
    glow.Color = Color3.fromRGB(255, 40, 40)
    glow.Brightness = mode == "night" and 2.5 or 1.2
    glow.Range = 14
    glow.Parent = head

    model.PrimaryPart = torso

    table.insert(scaryFigures, {
        model = model,
        head = head,
        phase = math.random() * math.pi * 2,
        sway = math.random(12, 24),
        lean = faceDir,
    })
end

local function buildScaryBloodPool(pos)
    if not scaryWorldFolder then return end
    local radius = math.random(55, 160) / 10
    local rot = math.random(0, 360)
    local baseCF = CFrame.new(pos + Vector3.new(0, 0.11, 0)) * CFrame.Angles(0, rot, math.rad(90))

    makeScaryPart({
        Name = "FE6_BloodPoolOuter",
        Parent = scaryWorldFolder,
        Shape = Enum.PartType.Cylinder,
        Size = Vector3.new(0.18, radius * 2.15, radius * 2.15),
        Color = Color3.fromRGB(45, 0, 0),
        Transparency = 0.08,
        Material = Enum.Material.Glass,
        CFrame = baseCF,
    })

    makeScaryPart({
        Name = "FE6_BloodPool",
        Parent = scaryWorldFolder,
        Shape = Enum.PartType.Cylinder,
        Size = Vector3.new(0.24, radius * 1.65, radius * 1.65),
        Color = Color3.fromRGB(185, 0, 0),
        Transparency = 0,
        Material = Enum.Material.Neon,
        CFrame = baseCF * CFrame.new(0, 0.02, 0),
    })

    makeScaryPart({
        Name = "FE6_BloodPoolCore",
        Parent = scaryWorldFolder,
        Shape = Enum.PartType.Cylinder,
        Size = Vector3.new(0.28, radius * 0.85, radius * 0.85),
        Color = Color3.fromRGB(255, 45, 45),
        Transparency = 0.05,
        Material = Enum.Material.Neon,
        CFrame = baseCF * CFrame.new(0, 0.04, 0),
    })

    makeScaryPart({
        Name = "FE6_BloodPoolShine",
        Parent = scaryWorldFolder,
        Shape = Enum.PartType.Cylinder,
        Size = Vector3.new(0.12, radius * 0.45, radius * 0.45),
        Color = Color3.fromRGB(255, 120, 120),
        Transparency = 0.35,
        Material = Enum.Material.Glass,
        CFrame = baseCF * CFrame.new(radius * 0.22, 0.06, radius * 0.1),
    })

    for _ = 1, math.random(5, 10) do
        local splatAngle = math.random() * math.pi * 2
        local splatDist = math.random(12, 65) / 10
        local splatPos = pos + Vector3.new(math.cos(splatAngle) * splatDist, 0.06, math.sin(splatAngle) * splatDist)
        makeScaryPart({
            Name = "FE6_BloodSplat",
            Parent = scaryWorldFolder,
            Size = Vector3.new(math.random(14, 50) / 10, 0.1, math.random(12, 40) / 10),
            Color = Color3.fromRGB(math.random(90, 150), 0, 0),
            Transparency = math.random(0, 12) / 100,
            Material = math.random() < 0.5 and Enum.Material.Neon or Enum.Material.Glass,
            CFrame = CFrame.new(splatPos) * CFrame.Angles(0, splatAngle, math.rad(math.random(-6, 6))),
        })
    end

    for _ = 1, math.random(2, 4) do
        makeScaryPart({
            Name = "FE6_BloodDrip",
            Parent = scaryWorldFolder,
            Size = Vector3.new(0.18, math.random(25, 75) / 10, 0.18),
            Color = Color3.fromRGB(140, 0, 0),
            Transparency = 0.02,
            Material = Enum.Material.Neon,
            CFrame = CFrame.new(pos + Vector3.new(math.random(-25, 25) / 10, math.random(6, 14) / 10, math.random(-25, 25) / 10)),
        })
    end

    if math.random() < 0.55 then
        makeScaryPart({
            Name = "FE6_BloodBubble",
            Parent = scaryWorldFolder,
            Shape = Enum.PartType.Ball,
            Size = Vector3.new(0.35, 0.35, 0.35),
            Color = Color3.fromRGB(200, 20, 20),
            Transparency = 0.25,
            Material = Enum.Material.Glass,
            CFrame = CFrame.new(pos + Vector3.new(math.random(-8, 8) / 10, 0.2, math.random(-8, 8) / 10)),
        })
    end
end

local function buildScaryHandprint(pos)
    makeScaryPart({
        Name = "FE6_BloodHand",
        Parent = scaryWorldFolder,
        Size = Vector3.new(1.4, 0.07, 1.6),
        Color = Color3.fromRGB(95, 0, 0),
        Transparency = 0.08,
        Material = Enum.Material.Neon,
        CFrame = CFrame.new(pos + Vector3.new(0, 0.12, 0)) * CFrame.Angles(math.rad(90), math.random(0, 360), 0),
    })
end

local function buildScaryCross(pos)
    local folder = scaryWorldFolder
    local post = makeScaryPart({
        Name = "FE6_CrossPost",
        Parent = folder,
        Size = Vector3.new(0.45, 5.5, 0.45),
        Color = Color3.fromRGB(18, 12, 12),
        Material = Enum.Material.Wood,
        CFrame = CFrame.new(pos + Vector3.new(0, 2.75, 0)),
    })
    makeScaryPart({
        Name = "FE6_CrossBeam",
        Parent = folder,
        Size = Vector3.new(3.2, 0.4, 0.4),
        Color = Color3.fromRGB(18, 12, 12),
        Material = Enum.Material.Wood,
        CFrame = post.CFrame * CFrame.new(0, 1.2, 0),
    })
    makeScaryPart({
        Name = "FE6_CrossBlood",
        Parent = folder,
        Size = Vector3.new(0.8, 1.1, 0.1),
        Color = Color3.fromRGB(120, 0, 0),
        Transparency = 0.1,
        Material = Enum.Material.Neon,
        CFrame = post.CFrame * CFrame.new(0, 1.2, 0.28),
    })
end

local function buildScarySkyEye(origin, offset, mode)
    local pos = origin + offset
    local eye = makeScaryPart({
        Name = "FE6_SkyEye",
        Parent = scaryWorldFolder,
        Shape = Enum.PartType.Ball,
        Size = Vector3.new(3.2, 3.2, 3.2),
        Color = Color3.fromRGB(255, 40, 40),
        Transparency = mode == "night" and 0.05 or 0.25,
        Material = Enum.Material.Neon,
        CFrame = CFrame.new(pos),
    })

    table.insert(scaryFigures, {
        skyEye = eye,
        baseOffset = offset,
        originFn = getScaryAnchor,
        phase = math.random() * math.pi * 2,
        drift = math.random(8, 18),
        kind = "sky",
    })
end

local function spawnScarySky(mode, anchor)
    if mode == "day" then
        return
    end

    local sky = Instance.new("Sky")
    sky.Name = "FE6_ScarySky"
    sky.SunAngularSize = mode == "night" and 9 or 14
    sky.MoonAngularSize = mode == "night" and 16 or 8
    sky.StarCount = mode == "night" and 2800 or 300
    sky.SunTextureId = "rbxasset://sky/sun.jpg"
    sky.MoonTextureId = "rbxasset://sky/moon.jpg"
    sky.SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex"
    sky.SkyboxDn = "rbxasset://textures/sky/sky512_dn.tex"
    sky.SkyboxFt = "rbxasset://textures/sky/sky512_ft.tex"
    sky.SkyboxLf = "rbxasset://textures/sky/sky512_lf.tex"
    sky.SkyboxRt = "rbxasset://textures/sky/sky512_rt.tex"
    sky.SkyboxUp = "rbxasset://textures/sky/sky512_up.tex"
    sky.Parent = Lighting

    local moon = makeScaryPart({
        Name = "FE6_BloodMoon",
        Parent = scaryWorldFolder,
        Shape = Enum.PartType.Ball,
        Size = Vector3.new(48, 48, 48),
        Color = Color3.fromRGB(185, 18, 32),
        Transparency = mode == "night" and 0.08 or 0.65,
        Material = Enum.Material.Neon,
        CFrame = CFrame.new(anchor + Vector3.new(140, 175, -210)),
    })

    table.insert(scaryFigures, {
        skyEye = moon,
        baseOffset = Vector3.new(140, 175, -210),
        originFn = getScaryAnchor,
        phase = math.random() * math.pi * 2,
        drift = 4,
        kind = "moon",
    })

    local eyeCount = mode == "night" and SCARY_SKY_EYE_COUNT or math.floor(SCARY_SKY_EYE_COUNT * 0.45)
    for i = 1, eyeCount do
        local offset = Vector3.new(
            math.random(-240, 240),
            math.random(95, 210),
            math.random(-240, 240)
        )
        buildScarySkyEye(anchor, offset, mode)
    end

    local cloudCount = mode == "night" and 8 or 3
    for _ = 1, cloudCount do
        local cloudPos = anchor + Vector3.new(math.random(-180, 180), math.random(110, 190), math.random(-180, 180))
        makeScaryPart({
            Name = "FE6_BloodCloud",
            Parent = scaryWorldFolder,
            Shape = Enum.PartType.Ball,
            Size = Vector3.new(math.random(30, 60), math.random(12, 22), math.random(28, 55)),
            Color = Color3.fromRGB(95, 20, 28),
            Transparency = mode == "night" and 0.55 or 0.75,
            Material = Enum.Material.Smoke,
            CFrame = CFrame.new(cloudPos),
        })
    end
end

local function weldScaryPart(part0, part1, c0)
    local weld = Instance.new("Weld")
    weld.Part0 = part0
    weld.Part1 = part1
    weld.C0 = c0 or CFrame.new()
    weld.Parent = part1
end

local function applyHorrorToCharacter(character)
    if not character or scaryShaderMode == "off" then return end
    if Players:GetPlayerFromCharacter(character) ~= LocalPlayer then return end

    if not character:FindFirstChild("FE6_ScaryHighlight") then
        local highlight = Instance.new("Highlight")
        highlight.Name = "FE6_ScaryHighlight"
        highlight.FillColor = Color3.fromRGB(70, 0, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 40, 40)
        highlight.FillTransparency = 0.28
        highlight.OutlineTransparency = 0
        pcall(function()
            if Enum.HighlightDepthMode and Enum.HighlightDepthMode.AlwaysOnTop then
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            end
        end)
        highlight.Parent = character
    end

    local head = character:FindFirstChild("Head")
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and not part.Name:find("FE6_Scary", 1, true) then
            if not scaryPlayerBackup[part] then
                scaryPlayerBackup[part] = {
                    Color = part.Color,
                    Material = part.Material,
                    Transparency = part.Transparency,
                    TextureID = part:IsA("MeshPart") and part.TextureID or nil,
                }
            end

            if part:IsA("MeshPart") then
                part.TextureID = ""
            end

            local n = part.Name:lower()
            if n == "head" then
                part.Color = Color3.fromRGB(45, 35, 35)
                part.Material = Enum.Material.Slate
            elseif n:find("torso", 1, true) or n:find("upper", 1, true) or n:find("lower", 1, true) then
                part.Color = Color3.fromRGB(55, 10, 10)
                part.Material = Enum.Material.Slate
            elseif n:find("arm", 1, true) or n:find("leg", 1, true) or n:find("hand", 1, true) or n:find("foot", 1, true) then
                part.Color = Color3.fromRGB(18, 12, 12)
                part.Material = Enum.Material.Slate
            else
                part.Color = Color3.fromRGB(28, 10, 10)
                part.Material = Enum.Material.Slate
            end
        end
    end

    if head then
        if not head:FindFirstChild("FE6_ScaryLeftEye") then
            for _, side in ipairs({-0.22, 0.22}) do
                local eye = Instance.new("Part")
                eye.Name = side < 0 and "FE6_ScaryLeftEye" or "FE6_ScaryRightEye"
                eye.Size = Vector3.new(0.22, 0.22, 0.22)
                eye.Color = Color3.fromRGB(255, 20, 20)
                eye.Material = Enum.Material.Neon
                eye.Anchored = false
                eye.CanCollide = false
                eye.Parent = head
                weldScaryPart(head, eye, CFrame.new(side, 0.1, -0.48))
            end

            local mouth = Instance.new("Part")
            mouth.Name = "FE6_ScaryMouth"
            mouth.Size = Vector3.new(0.65, 0.1, 0.1)
            mouth.Color = Color3.fromRGB(5, 0, 0)
            mouth.Material = Enum.Material.Neon
            mouth.Anchored = false
            mouth.CanCollide = false
            mouth.Parent = head
            weldScaryPart(head, mouth, CFrame.new(0, -0.38, -0.48))

            local stain = Instance.new("Part")
            stain.Name = "FE6_ScaryBloodStain"
            stain.Size = Vector3.new(0.85, 0.6, 0.12)
            stain.Color = Color3.fromRGB(130, 0, 0)
            stain.Material = Enum.Material.Neon
            stain.Transparency = 0.05
            stain.Anchored = false
            stain.CanCollide = false
            stain.Parent = head
            weldScaryPart(head, stain, CFrame.new(0, 0.05, -0.5))

            local glow = Instance.new("PointLight")
            glow.Name = "FE6_ScaryEyeGlow"
            glow.Color = Color3.fromRGB(255, 40, 40)
            glow.Brightness = scaryShaderMode == "night" and 2.2 or 1.2
            glow.Range = 10
            glow.Parent = head
        end
    end

    local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    if torso and not torso:FindFirstChild("FE6_ScaryChestBlood") then
        local chest = Instance.new("Part")
        chest.Name = "FE6_ScaryChestBlood"
        chest.Size = Vector3.new(1.3, 1.4, 0.14)
        chest.Color = Color3.fromRGB(140, 0, 0)
        chest.Material = Enum.Material.Neon
        chest.Transparency = 0.04
        chest.Anchored = false
        chest.CanCollide = false
        chest.Parent = torso
        weldScaryPart(torso, chest, CFrame.new(0, 0.1, -0.58))
    end
end

local function bindPlayerHorror(plr)
    if plr ~= LocalPlayer then return end
    table.insert(scaryPlayerConns, plr.CharacterAdded:Connect(function(char)
        task.wait(0.35)
        if scaryShaderMode ~= "off" then
            applyHorrorToCharacter(char)
        end
    end))
    if plr.Character then
        applyHorrorToCharacter(plr.Character)
    end
end

local function installPlayerHorror()
    restoreAllPlayerHorror()
    bindPlayerHorror(LocalPlayer)
    table.insert(scaryPlayerConns, Players.PlayerAdded:Connect(function(plr)
        bindPlayerHorror(plr)
    end))
end

local function isPlayerCharacterPart(part)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character and part:IsDescendantOf(plr.Character) then
            return true
        end
    end
    return false
end

local function nameHasFireHint(name)
    if type(name) ~= "string" then return false end
    local n = name:lower()
    for _, hint in ipairs(SCARY_FIRE_NAME_HINTS) do
        if n:find(hint, 1, true) then
            return true
        end
    end
    return false
end

local function isFlammableMapPart(part, anchor)
    if not (part:IsA("BasePart") or part:IsA("MeshPart")) then return false end
    if scaryWorldFolder and part:IsDescendantOf(scaryWorldFolder) then return false end
    if isPlayerCharacterPart(part) then return false end
    if part.Transparency >= 0.92 then return false end

    local nameMatch = nameHasFireHint(part.Name)
    if not nameMatch then
        local model = part:FindFirstAncestorOfClass("Model")
        if model then
            nameMatch = nameHasFireHint(model.Name)
        end
    end

    local material = part.Material
    local materialMatch = material == Enum.Material.Wood
        or material == Enum.Material.Grass
        or material == Enum.Material.LeafyGrass
        or material == Enum.Material.Fabric
        or material == Enum.Material.Ground
        or material == Enum.Material.Mud

    local size = part.Size
    local maxSize = math.max(size.X, size.Y, size.Z)
    local minSize = math.min(size.X, size.Y, size.Z)
    local tallProp = size.Y >= 2.8 and size.Y > size.X * 1.1 and size.Y > size.Z * 1.1
    local color = part.Color
    local greenish = color.G > color.R and color.G > 0.22

    if not nameMatch and not materialMatch and not tallProp and not greenish then
        return false
    end

    if maxSize > 120 or minSize < 0.15 or size.Magnitude < 0.8 then
        return false
    end

    if anchor then
        local flat = part.Position - anchor
        local flatDist = Vector3.new(flat.X, 0, flat.Z).Magnitude
        if flatDist > SCARY_MAP_RANGE + 80 then
            return false
        end
    end

    return true
end

local function spawnFirePillar(pos, mode, height)
    if not scaryWorldFolder then return end
    height = height or math.random(35, 65) / 10

    local host = makeScaryPart({
        Name = "FE6_FireHost",
        Parent = scaryWorldFolder,
        Size = Vector3.new(2, height, 2),
        Transparency = 1,
        CanCollide = false,
        CFrame = CFrame.new(pos + Vector3.new(0, height * 0.5, 0)),
    })

    local fire = Instance.new("Fire")
    fire.Name = "FE6_ScaryFire"
    fire.Size = math.clamp(height * 2.2, 8, 24)
    fire.Heat = mode == "night" and 16 or 11
    fire.Color = Color3.fromRGB(255, 120, 0)
    fire.SecondaryColor = Color3.fromRGB(200, 0, 0)
    fire.TimeScale = 1.2
    fire.Parent = host

    local smoke = Instance.new("Smoke")
    smoke.Name = "FE6_ScarySmoke"
    smoke.Size = fire.Size * 0.9
    smoke.Opacity = mode == "night" and 0.45 or 0.32
    smoke.RiseVelocity = 8
    smoke.Color = Color3.fromRGB(40, 40, 40)
    smoke.Parent = host

    scaryFireHosts[#scaryFireHosts + 1] = {
        part = host,
        fire = fire,
        smoke = smoke,
        owned = true,
    }
end

local function attachFireToPart(part, mode)
    if part:FindFirstChild("FE6_ScaryFire") or part:FindFirstChild("FE6_ScarySmoke") then
        return
    end

    local fire = Instance.new("Fire")
    fire.Name = "FE6_ScaryFire"
    local flameSize = math.clamp(math.max(part.Size.X, part.Size.Y, part.Size.Z) * 0.4, 5, 20)
    fire.Size = flameSize
    fire.Heat = mode == "night" and 14 or 9
    fire.Color = Color3.fromRGB(255, 118, 0)
    fire.SecondaryColor = Color3.fromRGB(190, 0, 0)
    fire.TimeScale = 1.15
    fire.Parent = part

    local smoke = Instance.new("Smoke")
    smoke.Name = "FE6_ScarySmoke"
    smoke.Size = flameSize * 0.85
    smoke.Opacity = mode == "night" and 0.42 or 0.3
    smoke.RiseVelocity = 7
    smoke.Color = Color3.fromRGB(45, 45, 45)
    smoke.Parent = part

    local oldColor = part.Color
    part.Color = Color3.new(
        math.max(oldColor.R * 0.45, 0.08),
        math.max(oldColor.G * 0.2, 0.04),
        math.max(oldColor.B * 0.2, 0.04)
    )

    scaryFireHosts[#scaryFireHosts + 1] = {
        part = part,
        fire = fire,
        smoke = smoke,
        oldColor = oldColor,
    }
end

local function igniteScaryMap(mode, anchor)
    clearScaryMapFires()
    if not scaryWorldFolder then return end

    for i = 1, 18 do
        local angle = (i / 18) * math.pi * 2 + math.random() * 0.5
        local radius = math.random(10, SCARY_MAP_RANGE)
        local groundPos = findScaryGroundPos(anchor, radius, angle)
        spawnFirePillar(groundPos, mode, math.random(55, 110) / 10)
    end

    local root = getHorrorWorldParent()
    local checked, lit = 0, 0
    for _, inst in ipairs(root:GetDescendants()) do
        checked = checked + 1
        if checked > 1200 or lit >= 22 then break end
        if isFlammableMapPart(inst, anchor) then
            lit = lit + 1
            pcall(function()
                local top = inst.Position + Vector3.new(0, inst.Size.Y * 0.45, 0)
                spawnFirePillar(top, mode, math.clamp(inst.Size.Y * 0.42, 4, 14))
                attachFireToPart(inst, mode)
            end)
        end
    end
end

local function spawnFallbackBloodRing(anchor, count)
    if not scaryWorldFolder then return end
    for i = 1, count do
        local angle = (i / count) * math.pi * 2 + math.random() * 0.4
        local radius = math.random(SCARY_NPC_MIN_DIST, SCARY_NPC_MAX_DIST + 8)
        local groundPos = findScaryGroundPos(anchor, radius, angle)
        buildScaryBloodPool(groundPos)
    end
end

destroyScaryWorld = function()
    restoreAllPlayerHorror()
    clearScaryMapFires()
    if scaryNpcConn then
        scaryNpcConn:Disconnect()
        scaryNpcConn = nil
    end
    for i = #scaryFigures, 1, -1 do
        scaryFigures[i] = nil
    end
    if scaryWorldFolder and scaryWorldFolder.Parent then
        scaryWorldFolder:Destroy()
    end
    scaryWorldFolder = nil
end

spawnScaryWorld = function(mode)
    destroyScaryWorld()

    scaryWorldFolder = Instance.new("Folder")
    scaryWorldFolder.Name = "FE6_ScaryHorror"
    scaryWorldFolder.Parent = getHorrorWorldParent()

    local anchor = getScaryAnchor()
    spawnFallbackBloodRing(anchor, 10)

    pcall(function() spawnScarySky(mode, anchor) end)

    for i = 1, SCARY_NPC_COUNT do
        local angle = (i / SCARY_NPC_COUNT) * math.pi * 2 + math.random() * 0.9
        local radius = math.random(SCARY_NPC_MIN_DIST, SCARY_NPC_MAX_DIST)
        local groundPos = findScaryGroundPos(anchor, radius, angle)
        pcall(function() buildScaryFigure(groundPos, anchor, mode) end)
    end

    local placedPools = 0
    local attempts = 0
    while placedPools < SCARY_BLOOD_POOL_COUNT and attempts < SCARY_BLOOD_POOL_COUNT * 5 do
        attempts = attempts + 1
        local groundPos = findRandomMapGroundPos(anchor)
        if groundPos then
            buildScaryBloodPool(groundPos)
            placedPools = placedPools + 1
        end
    end
    if placedPools < 8 then
        spawnFallbackBloodRing(anchor, 14)
    end

    for _ = 1, SCARY_HANDPRINT_COUNT do
        local groundPos = findRandomMapGroundPos(anchor)
        if groundPos then
            pcall(function() buildScaryHandprint(groundPos) end)
        end
    end

    for _ = 1, SCARY_CROSS_COUNT do
        local groundPos = findRandomMapGroundPos(anchor)
        if groundPos then
            pcall(function() buildScaryCross(groundPos) end)
        end
    end

    pcall(function() installPlayerHorror() end)
    pcall(function() igniteScaryMap(mode, anchor) end)

    local lastPlayerHorrorRefresh = 0
    local lastHorrorAnimAt = 0
    scaryNpcConn = RunService.Heartbeat:Connect(function()
        if scaryShaderMode == "off" then return end
        local t = os.clock()
        if t - lastHorrorAnimAt < 0.2 then return end
        lastHorrorAnimAt = t
        local liveAnchor = getScaryAnchor()

        for idx, entry in ipairs(scaryFigures) do
            if entry.kind == "sky" or entry.kind == "moon" then
                local eye = entry.skyEye
                if eye and eye.Parent and entry.baseOffset then
                    local drift = Vector3.new(
                        math.sin(t * 0.35 + entry.phase) * entry.drift,
                        math.sin(t * 0.5 + entry.phase) * (entry.drift * 0.35),
                        math.cos(t * 0.3 + entry.phase) * entry.drift
                    )
                    eye.CFrame = CFrame.new(liveAnchor + entry.baseOffset + drift)
                end
            elseif entry.model and entry.model.Parent and idx % 2 == (math.floor(t * 5) % 2) then
                local sway = math.sin(t * 1.4 + entry.phase) * math.rad(entry.sway or 10)
                local base = entry.model:GetPivot()
                if (base.Position - liveAnchor).Magnitude < 90 then
                    entry.model:PivotTo(base * CFrame.Angles(0, sway * 0.08, math.sin(t * 2 + entry.phase) * 0.03))
                end
            end
        end

        if t - lastPlayerHorrorRefresh > 2.5 then
            lastPlayerHorrorRefresh = t
            if LocalPlayer.Character then
                pcall(function() applyHorrorToCharacter(LocalPlayer.Character) end)
            end
        end
    end)
end


local function updateScaryShaderLabels()
    local text = "Horror: OFF"
    local accent = Color3.fromRGB(42, 10, 10)

    if scaryShaderMode == "day" then
        text = "Scary Day"
        accent = Color3.fromRGB(92, 18, 18)
    elseif scaryShaderMode == "night" then
        text = "Scary Night"
        accent = Color3.fromRGB(58, 8, 18)
    end

    if scaryOverlay then
        local btn = scaryOverlay:FindFirstChild("ToggleBtn", true)
        if btn and btn:IsA("TextButton") then
            btn.Text = text
            btn.BackgroundColor3 = accent
        end
    end
end

local function buildScaryEffects(mode)
    destroyScaryEffects()

    if mode == "day" then
        -- Normal game daylight; horror is map props only (blood, fire, NPCs)
        restoreLightingState()
        return
    end

    local atmo = Instance.new("Atmosphere")
    atmo.Name = "FE6_ScaryAtmo"
    atmo.Parent = Lighting

    local sunRays = Instance.new("SunRaysEffect")
    sunRays.Name = "FE6_ScaryRays"
    sunRays.Parent = Lighting

    local cc = Instance.new("ColorCorrectionEffect")
    cc.Name = "FE6_ScaryCC"
    cc.Parent = Lighting

    local bloom = Instance.new("BloomEffect")
    bloom.Name = "FE6_ScaryBloom"
    bloom.Parent = Lighting

    local blur = Instance.new("BlurEffect")
    blur.Name = "FE6_ScaryBlur"
    blur.Parent = Lighting

    do
        -- Scary night: foggy blood-drenched dusk (previous day look)
        Lighting.Ambient            = Color3.fromRGB(72, 58, 58)
        Lighting.OutdoorAmbient     = Color3.fromRGB(88, 62, 62)
        Lighting.ColorShift_Top     = Color3.fromRGB(168, 92, 92)
        Lighting.ColorShift_Bottom  = Color3.fromRGB(58, 18, 18)
        Lighting.Brightness         = 1.05
        Lighting.ClockTime          = 11.2
        Lighting.GeographicLatitude = 12
        Lighting.FogColor           = Color3.fromRGB(112, 58, 58)
        Lighting.FogEnd             = 185
        Lighting.FogStart           = 0
        Lighting.GlobalShadows      = true

        atmo.Density = 0.62
        atmo.Offset = 0.08
        atmo.Color = Color3.fromRGB(148, 78, 78)
        atmo.Decay = Color3.fromRGB(72, 18, 18)
        atmo.Glare = 0.08
        atmo.Haze = 2.85

        sunRays.Intensity = 0.04
        sunRays.Spread = 0.3

        cc.Brightness = -0.06
        cc.Contrast = 0.18
        cc.Saturation = 0.22
        cc.TintColor = Color3.fromRGB(255, 168, 168)

        bloom.Intensity = 0.22
        bloom.Size = 18
        bloom.Threshold = 1.08

        blur.Size = 2.2
    end
end


function cycleScaryShader()
    if scaryShaderMode == "off" then
        setScaryShader("day")
    elseif scaryShaderMode == "day" then
        setScaryShader("night")
    else
        setScaryShader("off")
    end
end

setScaryShader = function(mode, skipPurpleDisable)
    if mode ~= "off" and mode ~= "day" and mode ~= "night" then
        mode = "off"
    end

    if mode ~= "off" and not skipPurpleDisable then
        setSkyShader("off", true)
    end

    scaryShaderMode = mode

    if mode ~= "off" then
        if not savedLighting.Ambient then saveLightingState() end
        buildScaryEffects(mode)
        task.spawn(function()
            local ok, err = pcall(function()
                spawnScaryWorld(mode)
            end)
            if not ok then
                warn("[FE6 x DE11] Horror world failed:", err)
            end
        end)
    else
        destroyScaryEffects()
        destroyScaryWorld()
        restoreAllPlayerHorror()
        if skyShaderMode == "off" then
            restoreLightingState()
            Lighting.FogStart = 0
        elseif skyShaderMode == "day" or skyShaderMode == "night" then
            buildSkyEffects(skyShaderMode)
        end
        clearSavedLightingIfIdle()
    end

    updateScaryShaderLabels()
end

end -- horror world scope

local isThrowVisual
local installThrowVisuals
local installAimPointDebug
local throwBeamBelongsToLocalPlayer -- must be outer: installRuntimeHooks calls it

do
local function getPlayerFromPart(part)
    if not part or not part:IsA("BasePart") then return nil end
    local model = part:FindFirstAncestorOfClass("Model")
    if model then
        return Players:GetPlayerFromCharacter(model)
    end
    return nil
end

local function belongsToLocalCharacter(inst)
    local char = LocalPlayer.Character
    if not char or not inst then return false end
    return inst:IsDescendantOf(char)
end

local function isBodyPartName(name)
    if type(name) ~= "string" then return false end
    local n = name:lower()
    return n == "humanoidrootpart"
        or n:find("arm", 1, true) ~= nil
        or n:find("leg", 1, true) ~= nil
        or n:find("hand", 1, true) ~= nil
        or n:find("foot", 1, true) ~= nil
        or n:find("torso", 1, true) ~= nil
        or n:find("head", 1, true) ~= nil
        or n:find("upper", 1, true) ~= nil
        or n:find("lower", 1, true) ~= nil
        or n:find("neck", 1, true) ~= nil
        or n:find("body", 1, true) ~= nil
        or n:find("blob", 1, true) ~= nil
end

throwBeamBelongsToLocalPlayer = function(beam)
    if not beam or not beam:IsA("Beam") then return false end
    local char = LocalPlayer.Character
    if not char then return false end
    if beam:IsDescendantOf(char) then return true end

    local cam = workspace.CurrentCamera
    if cam and beam:IsDescendantOf(cam) then return true end

    local hasLocal = false
    for _, attName in ipairs({ "Attachment0", "Attachment1" }) do
        local att = beam[attName]
        if att and att.Parent and att.Parent:IsA("BasePart") then
            local owner = getPlayerFromPart(att.Parent)
            if owner == LocalPlayer then
                hasLocal = true
            elseif owner and owner ~= LocalPlayer then
                return false
            end
        end
    end
    return hasLocal
end

local function nameLooksLikeThrow(name)
    if type(name) ~= "string" then return false end
    local n = name:lower()
    for _, hint in ipairs(THROW_NAME_HINTS) do
        if n:find(hint, 1, true) then return true end
    end
    return false
end

local function isFlingThrowBeam(beam)
    if not beam or not beam:IsA("Beam") then return false end
    if isAuraVisual(beam) then return false end
    if isGrabRopeBeam(beam) then return false end
    if not throwBeamBelongsToLocalPlayer(beam) then return false end

    local cam = workspace.CurrentCamera
    if cam and beam:IsDescendantOf(cam) then return true end
    if nameLooksLikeThrow(beam.Name) then return true end

    local att0 = beam.Attachment0
    local att1 = beam.Attachment1
    if att0 and att1 and att0.Parent and att1.Parent then
        if nameLooksLikeThrow(att0.Parent.Name) or nameLooksLikeThrow(att1.Parent.Name) then
            return true
        end
    end

    return false
end

isThrowVisual = function(inst)
    if not inst then return false end
    if isOurOverlay(inst) or isHubGui(inst) or isAuraVisual(inst) then return false end

    if inst:IsA("Beam") then
        return isFlingThrowBeam(inst)
    end

    if inst:IsA("Trail") then
        local parent = inst.Parent
        if parent and parent:IsA("BasePart") then
            if isBodyPartName(parent.Name) then return false end
            if not (nameLooksLikeThrow(inst.Name) or nameLooksLikeThrow(parent.Name)) then
                return false
            end
            local owner = getPlayerFromPart(parent)
            if owner == LocalPlayer then return true end
            if owner and owner ~= LocalPlayer then return false end
            return belongsToLocalCharacter(parent)
        end
        return false
    end

    if inst:IsA("BasePart") then
        if not belongsToLocalCharacter(inst) then return false end
        if isBodyPartName(inst.Name) then return false end
        return nameLooksLikeThrow(inst.Name)
    end

    return false
end

local AIM_GUI_NAME_HINTS = {
    "aim", "cross", "fov", "dot", "reticle", "target", "scope",
}

local function nameLooksLikeAimGui(name)
    if type(name) ~= "string" then return false end
    local n = name:lower()
    for _, hint in ipairs(AIM_GUI_NAME_HINTS) do
        if n:find(hint, 1, true) then return true end
    end
    return false
end

local function protectAimGui(inst)
    if not inst or not inst:IsA("GuiObject") then return end
    if isOurOverlay(inst) or isHubGui(inst) then return end
    if not nameLooksLikeAimGui(inst.Name) then return end
    pcall(function()
        if not inst.Visible then
            inst.Visible = true
        end
        if inst:GetAttribute("FE6_AimStyled") then return end
        inst:SetAttribute("FE6_AimStyled", true)
        inst.Size = UDim2.fromOffset(AIM_RING_SIZE, AIM_RING_SIZE)
        if inst:IsA("Frame") or inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
            if inst.BackgroundTransparency >= 0.99 and not (inst:IsA("ImageLabel") or inst:IsA("ImageButton")) then
                inst.BackgroundTransparency = 0.5
            end
            inst.BackgroundColor3 = THEME.accent
            if inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
                inst.ImageColor3 = THEME.accentLight
                inst.ImageTransparency = math.min(inst.ImageTransparency, 0.15)
            end
        end
    end)
end

local function maintainTrackedDrawings()
    for i = #trackedDrawings, 1, -1 do
        local drawing = trackedDrawings[i]
        if not drawing then
            table.remove(trackedDrawings, i)
        else
            pcall(function()
                if drawing.Visible == false then
                    drawing.Visible = true
                end
                if drawing.Radius and drawing.Radius > AIM_RING_SIZE * 0.5 then
                    drawing.Radius = AIM_RING_SIZE * 0.5
                end
                if drawing.Thickness and drawing.Thickness > 1.5 then
                    drawing.Thickness = 1.2
                end
                if drawing.Color and isReddishColor(drawing.Color) then
                    drawing.Color = THEME.accentLight
                end
                if drawing.Transparency and drawing.Transparency > 0.5 then
                    drawing.Transparency = 0
                end
            end)
        end
    end
end

local function bindThrowBeam(beam)
    if not isFlingThrowBeam(beam) then
        return
    end
    cachedThrowBeam = beam
    applyThrowBeamStyle(beam)
    if beam:GetAttribute("FE6_BeamBound") then return end
    beam:SetAttribute("FE6_BeamBound", true)
    beam.AncestryChanged:Connect(function(_, parent)
        if not parent and cachedThrowBeam == beam then
            cachedThrowBeam = nil
        end
    end)
end

local function findActiveThrowBeam()
    if cachedThrowBeam and cachedThrowBeam.Parent and isFlingThrowBeam(cachedThrowBeam) then
        return cachedThrowBeam
    end
    cachedThrowBeam = nil

    local cam = workspace.CurrentCamera
    if cam then
        for _, inst in ipairs(cam:GetDescendants()) do
            if isFlingThrowBeam(inst) then
                bindThrowBeam(inst)
                return inst
            end
        end
    end

    local char = LocalPlayer.Character
    if char then
        for _, inst in ipairs(char:GetDescendants()) do
            if isFlingThrowBeam(inst) then
                bindThrowBeam(inst)
                return inst
            end
        end
    end

    return nil
end

local function setGuiClickThrough(inst)
    if not inst then return end
    if inst:IsA("GuiObject") then
        inst.Active = false
    end
    for _, child in ipairs(inst:GetChildren()) do
        setGuiClickThrough(child)
    end
end

local function createAimPointGui()
    if aimPointGui and aimPointGui.Parent then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "FE6_AimPoint"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 99989
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = PlayerGui
    aimPointGui = gui

    local center = Instance.new("Frame")
    center.Name = "CenterReticle"
    center.AnchorPoint = Vector2.new(0.5, 0.5)
    center.Position = UDim2.fromScale(0.5, 0.5)
    center.Size = UDim2.fromOffset(AIM_RING_SIZE, AIM_RING_SIZE)
    center.BackgroundTransparency = 1
    center.BorderSizePixel = 0
    center.Active = false
    center.Parent = gui

    local ringStroke = Instance.new("UIStroke")
    ringStroke.Color = THEME.accentLight
    ringStroke.Thickness = 1
    ringStroke.Transparency = 0.3
    ringStroke.Parent = center

    local ringCorner = Instance.new("UICorner")
    ringCorner.CornerRadius = UDim.new(1, 0)
    ringCorner.Parent = center

    local centerDot = Instance.new("Frame")
    centerDot.Name = "Dot"
    centerDot.AnchorPoint = Vector2.new(0.5, 0.5)
    centerDot.Position = UDim2.fromScale(0.5, 0.5)
    centerDot.Size = UDim2.fromOffset(AIM_DOT_SIZE, AIM_DOT_SIZE)
    centerDot.BackgroundColor3 = THEME.accentLight
    centerDot.BorderSizePixel = 0
    centerDot.Parent = center

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = centerDot

    local worldDot = Instance.new("Frame")
    worldDot.Name = "WorldDot"
    worldDot.AnchorPoint = Vector2.new(0.5, 0.5)
    worldDot.Position = UDim2.fromScale(0.5, 0.5)
    worldDot.Size = UDim2.fromOffset(AIM_RING_SIZE, AIM_RING_SIZE)
    worldDot.BackgroundTransparency = 1
    worldDot.BorderSizePixel = 0
    worldDot.Visible = false
    worldDot.Parent = gui

    local worldStroke = Instance.new("UIStroke")
    worldStroke.Color = THEME.accentLight
    worldStroke.Thickness = 1.2
    worldStroke.Transparency = 0.15
    worldStroke.Parent = worldDot

    local worldCorner = Instance.new("UICorner")
    worldCorner.CornerRadius = UDim.new(1, 0)
    worldCorner.Parent = worldDot

    local worldInner = Instance.new("Frame")
    worldInner.Name = "Inner"
    worldInner.AnchorPoint = Vector2.new(0.5, 0.5)
    worldInner.Position = UDim2.fromScale(0.5, 0.5)
    worldInner.Size = UDim2.fromOffset(AIM_DOT_SIZE + 1, AIM_DOT_SIZE + 1)
    worldInner.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    worldInner.BorderSizePixel = 0
    worldInner.Parent = worldDot

    local worldInnerCorner = Instance.new("UICorner")
    worldInnerCorner.CornerRadius = UDim.new(1, 0)
    worldInnerCorner.Parent = worldInner

    setGuiClickThrough(gui)
end

local function updateAimPointDisplay()
    if not aimPointGui or not aimPointGui.Parent then
        createAimPointGui()
    end
    if not aimPointGui then return end

    local center = aimPointGui:FindFirstChild("CenterReticle")
    local worldDot = aimPointGui:FindFirstChild("WorldDot")
    local showCenter = not isMouseUnlocked()

    local beam = findActiveThrowBeam()
    local hasWorldAim = false
    if beam and worldDot then
        local now = os.clock()
        if now - lastBeamStyleAt >= BEAM_STYLE_INTERVAL then
            lastBeamStyleAt = now
            applyThrowBeamStyle(beam)
        end
        local worldPos = getAimWorldPosition(beam)
        local cam = workspace.CurrentCamera
        if worldPos and cam then
            local screenPos, onScreen = cam:WorldToViewportPoint(worldPos)
            if onScreen and screenPos.Z > 0 then
                worldDot.Position = UDim2.fromOffset(screenPos.X, screenPos.Y)
                worldDot.Visible = true
                hasWorldAim = true
            else
                worldDot.Visible = false
            end
        else
            worldDot.Visible = false
        end
    elseif worldDot then
        worldDot.Visible = false
    end

    if center then
        center.Visible = showCenter or not hasWorldAim
    end
end

local function applyThrowBeamStyle(beam)
    if isGrabRopeBeam(beam) then return end
    pcall(function()
        beam.Enabled = true
        beam.Color = getThrowBeamSequence(beam)
        beam.LightEmission = math.max(beam.LightEmission or 0, 0.4)
        beam.LightInfluence = 0
    end)
end

local function tintThrowVisual(inst)
    pcall(function()
        if inst:IsA("Beam") then
            applyThrowBeamStyle(inst)
        elseif inst:IsA("Trail") then
            inst.Color = ColorSequence.new(THEME.accentLight, THEME.accent)
        elseif inst:IsA("BasePart") then
            inst.Color = THEME.accentLight
            if inst.Transparency >= 0.95 then
                inst.Transparency = 0
            end
        end
    end)
end

installThrowVisuals = function()
    local watchedRoots = {}

    local function onThrowInst(inst)
        if not (inst:IsA("Beam") or inst:IsA("Trail")) then return end
        if not isThrowVisual(inst) then return end
        tintThrowVisual(inst)
        if inst:IsA("Beam") then
            bindThrowBeam(inst)
        end
    end

    local function watchThrowRoot(root)
        if not root or watchedRoots[root] then return end
        watchedRoots[root] = true
        for _, inst in ipairs(root:GetDescendants()) do
            onThrowInst(inst)
        end
        root.DescendantAdded:Connect(function(inst)
            if inst:IsA("Beam") or inst:IsA("Trail") then
                onThrowInst(inst)
            end
        end)
    end

    local function onCharacter(char)
        task.wait(0.35)
        watchThrowRoot(char)
    end

    LocalPlayer.CharacterAdded:Connect(onCharacter)
    if LocalPlayer.Character then
        task.spawn(onCharacter, LocalPlayer.Character)
    end

    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        watchThrowRoot(workspace.CurrentCamera)
    end)
    watchThrowRoot(workspace.CurrentCamera)
end

local function installAimPointKeeper()
    createAimPointGui()

    if aimPointConn then
        aimPointConn:Disconnect()
    end
    aimPointConn = RunService.Heartbeat:Connect(function()
        local now = os.clock()
        if now - lastAimUpdateAt < AIM_UPDATE_INTERVAL then
            return
        end
        lastAimUpdateAt = now
        updateAimPointDisplay()
        if #trackedDrawings > 0 and now - lastDrawingMaintainAt >= DRAWING_MAINTAIN_INTERVAL then
            lastDrawingMaintainAt = now
            maintainTrackedDrawings()
        end
    end)

    PlayerGui.ChildRemoved:Connect(function(child)
        if child == aimPointGui then
            aimPointGui = nil
            task.defer(createAimPointGui)
        end
    end)

    PlayerGui.DescendantAdded:Connect(function(inst)
        if inst:IsA("GuiObject") and nameLooksLikeAimGui(inst.Name) then
            protectAimGui(inst)
        end
    end)

    task.defer(function()
        for _, inst in ipairs(PlayerGui:GetDescendants()) do
            if inst:IsA("GuiObject") and nameLooksLikeAimGui(inst.Name) then
                protectAimGui(inst)
            end
        end
    end)

    if Drawing and type(Drawing.new) == "function" and not Drawing.__FE6_AimHooked then
        Drawing.__FE6_AimHooked = true
        local oldDrawingNew = Drawing.new
        Drawing.new = function(kind)
            local obj = oldDrawingNew(kind)
            if kind == "Circle" or kind == "Square" or kind == "Triangle" then
                trackedDrawings[#trackedDrawings + 1] = obj
                pcall(function()
                    if obj.Radius and obj.Radius > AIM_RING_SIZE * 0.5 then
                        obj.Radius = AIM_RING_SIZE * 0.5
                    end
                    if obj.Thickness and obj.Thickness > 1.5 then
                        obj.Thickness = 1.2
                    end
                    if obj.Color and isReddishColor(obj.Color) then
                        obj.Color = THEME.accentLight
                    end
                    obj.Visible = true
                end)
            end
            return obj
        end
    end
end

installAimPointDebug = function()
    if not getgenv or not getgenv().FE6_AimDebug then return end

    local lastLog = 0
    RunService.RenderStepped:Connect(function()
        local now = tick()
        if now - lastLog < 1.5 then return end

        local hits = {}
        local function checkBeam(beam)
            if not isThrowVisual(beam) then return end
            local pos = getAimWorldPosition(beam)
            if pos then
                hits[#hits + 1] = string.format(
                    "Beam %s aim@%s (att%d)",
                    beam:GetFullName(),
                    tostring(pos),
                    getAimAttachmentIndex(beam)
                )
            end
        end

        local char = LocalPlayer.Character
        if char then
            for _, inst in ipairs(char:GetDescendants()) do
                if inst:IsA("Beam") then checkBeam(inst) end
            end
        end
        for _, inst in ipairs(workspace:GetDescendants()) do
            if inst:IsA("Beam") then checkBeam(inst) end
        end

        if #hits > 0 then
            lastLog = now
            print("[FE6 x DE11] Aim point trace:")
            for _, line in ipairs(hits) do
                print("  " .. line)
            end
        end
    end)
end

end -- throw visuals scope

local function safeCycleSkyShader()
    local ok, err = pcall(cycleSkyShader)
    if not ok then
        warn("[FE6 x DE11] Sky button error:", err)
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = CHAT_NAME,
                Text = "Sky toggle error",
                Duration = 3,
            })
        end)
    end
    task.defer(ensureBackpackEnabled)
end

local function safeCycleScaryShader()
    local ok, err = pcall(cycleScaryShader)
    if not ok then
        warn("[FE6 x DE11] Horror button error:", err)
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = CHAT_NAME,
                Text = "Horror toggle error",
                Duration = 3,
            })
        end)
    end
    task.defer(ensureBackpackEnabled)
end

destroyEliteSpawn = function() end
createSpawnOverlay = function() end


local function createSkyOverlay()
    local stale = PlayerGui:FindFirstChild("FE6_SkyOverlay")
    if stale then stale:Destroy() end
    skyOverlay = nil

    local gui = Instance.new("ScreenGui")
    gui.Name = "FE6_SkyOverlay"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 99990
    gui.Parent = PlayerGui
    skyOverlay = gui

    local btn = Instance.new("TextButton")
    btn.Name = "ToggleBtn"
    btn.Size = UDim2.new(0, 142, 0, 34)
    btn.Position = UDim2.new(0, 12, 1, -48)
    btn.Text = "💜 Sky: OFF"
    styleOverlayButton(btn, THEME.panel)
    btn.Parent = gui

    btn.MouseButton1Click:Connect(function()
        safeCycleSkyShader()
    end)
end

local function createScaryOverlay()
    local stale = PlayerGui:FindFirstChild("FE6_ScaryOverlay")
    if stale then stale:Destroy() end
    scaryOverlay = nil

    local gui = Instance.new("ScreenGui")
    gui.Name = "FE6_ScaryOverlay"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 99991
    gui.Parent = PlayerGui
    scaryOverlay = gui

    local btn = Instance.new("TextButton")
    btn.Name = "ToggleBtn"
    btn.Size = UDim2.new(0, 148, 0, 34)
    btn.Position = UDim2.new(1, -160, 1, -48)
    btn.Text = "Horror: OFF"
    styleOverlayButton(btn, Color3.fromRGB(42, 10, 10))
    btn.Parent = gui

    btn.MouseButton1Click:Connect(function()
        safeCycleScaryShader()
    end)
end

local function toggleHubMenu()
    local hub = findMainHubGui()
    if not hub or isGameInventoryGui(hub) then
        return false
    end
    hub.Enabled = not hub.Enabled
    if hub.Enabled then
        local main = hub:FindFirstChild("Main", true) or hub:FindFirstChild("MainFrame", true)
        if main and main:IsA("GuiObject") then
            main.Visible = true
        end
    end
    return true
end

local function instanceUnderRayfieldHub(inst)
    return isUnderLikelyHub(inst)
end

local function installPremiumBypass()
    if not getgenv then return end
    getgenv().Premium      = true
    getgenv().IsPremium    = true
    getgenv().Paid         = true
    getgenv().Key          = true
    getgenv().Whitelisted  = true
    getgenv().HasPremium   = true
    getgenv().BloodyPremium = true
end

local function installRuntimeHooks()
    if not hookmetamethod or hooksInstalled then return end
    hooksInstalled = true

    local oldNewIndex
    oldNewIndex = hookmetamethod(game, "__newindex", function(self, key, value)
        if typeof(self) ~= "Instance" then
            return oldNewIndex(self, key, value)
        end

        if bloodyLoadPhase then
            if key == "Image" and isClownAsset(tostring(value)) then
                return oldNewIndex(self, key, "rbxassetid://0")
            elseif key == "SoundId" and isClownAsset(tostring(value)) then
                return oldNewIndex(self, key, "")
            elseif key == "Text" and type(value) == "string" then
                if isClownAsset(value) or value == "🤡" or value:find("clown", 1, true) then
                    return oldNewIndex(self, key, "X")
                end
                local sn = ""
                pcall(function() sn = self.Name or "" end)
                if not sn:find("Splash", 1, true) and shouldRebrandText(value) then
                    local okR, branded = pcall(rebrandText, value)
                    if okR and type(branded) == "string" then value = branded end
                end
                return oldNewIndex(self, key, value)
            end
        end

        if key == "Image" then
            if isClownAsset(tostring(value)) then
                return oldNewIndex(self, key, "rbxassetid://0")
            end
        elseif key == "SoundId" then
            if isClownAsset(tostring(value)) then
                return oldNewIndex(self, key, "")
            end
        elseif key == "Text" and type(value) == "string" then
            if isClownAsset(value) or value == "🤡" or value:find("clown", 1, true) then
                return oldNewIndex(self, key, "X")
            end
            local sn = ""
            pcall(function() sn = self.Name or "" end)
            if not sn:find("Splash", 1, true) and not sn:find("FE6_Splash", 1, true)
                and not sn:find("FE6_Hero", 1, true) then
                local lower = value:lower()
                if lower:find("bloody", 1, true) or lower:find("tokra", 1, true)
                    or lower:find("premium", 1, true) or isHubTitleLike(value) then
                    local okR, branded = pcall(rebrandText, value)
                    if okR and type(branded) == "string" then value = branded end
                end
            end
        elseif key == "Color" then
            local className = self.ClassName
            if className == "Beam" and not isAuraVisual(self) and not isGrabRopeBeam(self) then
                local belongs = false
                if type(throwBeamBelongsToLocalPlayer) == "function" then
                    local okB, resB = pcall(throwBeamBelongsToLocalPlayer, self)
                    belongs = okB and resB == true
                end
                if belongs and type(getThrowBeamSequence) == "function" then
                    value = getThrowBeamSequence(self)
                end
            elseif not isOurOverlay(self) and instanceUnderRayfieldHub(self) then
                if className == "UIGradient" then
                    if type(aggressiveRecolorSequence) == "function" then
                        value = aggressiveRecolorSequence(value)
                    end
                elseif typeof(value) == "Color3" and type(aggressiveRecolor) == "function" then
                    value = aggressiveRecolor(value)
                end
            end
        elseif COLOR_PROPS[key] and typeof(value) == "Color3" and not isOurOverlay(self)
            and instanceUnderRayfieldHub(self) then
            if type(aggressiveRecolor) == "function" then
                value = aggressiveRecolor(value)
            end
        elseif COLOR_PROPS[key] and typeof(value) == "Color3" and not isOurOverlay(self)
            and inventoryPurpleOn and isInventoryShell(self) and key == "BackgroundColor3" then
            local ok, trans = pcall(function() return self.BackgroundTransparency end)
            if ok and trans and trans < 1 then
                value = THEME.panel
            end
        end

        return oldNewIndex(self, key, value)
    end)

    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if method == "UserOwnsGamePassAsync" then
            return true
        end

        if method == "HttpGet" or method == "HttpGetAsync" then
            local url = args[1]
            local result = oldNamecall(self, ...)
            if type(result) == "string" and not isBloodyUrl(url) then
                if shouldPatchHttpUrl(url) or looksLikeRayfieldSource(result) then
                    result = patchRayfieldSource(result)
                end
            end
            return result
        end

        if bloodyLoadPhase then
            return oldNamecall(self, ...)
        end

        if method == "SetCore" and self == StarterGui then
            local coreType = args[1]
            local data = args[2]
            if coreType == "SendNotification" and type(data) == "table" then
                local title = tostring(data.Title or "")
                local text  = tostring(data.Text or "")
                local body    = (title .. " " .. text):lower()
                if body:find("bloody", 1, true) or body:find("tokra", 1, true)
                    or body:find("premium", 1, true) or body:find("loaded", 1, true)
                    or body:find("crack", 1, true) then
                    data.Title = CHAT_NAME
                    data.Text  = LOAD_POPUP
                end
                if title:lower():find("bloody", 1, true) then
                    data.Title = stripBloodyFromText(title)
                end
                if text:lower():find("bloody", 1, true) then
                    data.Text = stripBloodyFromText(text)
                end
            elseif coreType == "ChatMakeSystemMessage" and type(data) == "table" then
                local text = tostring(data.Text or "")
                local lower = text:lower()
                if lower:find("bloody", 1, true) or lower:find("tokra", 1, true)
                    or lower:find("free beta", 1, true) or lower:find("premium", 1, true) then
                    data.Text = CHAT_MSG
                end
            end
        end

        if method == "FireServer" then
            local msg = args[1]
            if type(msg) == "string" then
                local lower = msg:lower()
                if lower:find("free beta", 1, true) or lower:find("tokra", 1, true)
                    or lower:find("bloody", 1, true) or lower:find("premium", 1, true)
                    or lower:find("crack", 1, true) or lower:find("loaded!", 1, true) then
                    args[1] = CHAT_MSG
                    return oldNamecall(self, table.unpack(args))
                end
            end
        end

        if method == "SendAsync" or method == "DisplaySystemMessage" then
            local msg = args[1]
            if type(msg) == "string" then
                local lower = msg:lower()
                if lower:find("free beta", 1, true) or lower:find("tokra", 1, true)
                    or lower:find("bloody", 1, true) or lower:find("premium", 1, true) then
                    args[1] = CHAT_MSG
                    return oldNamecall(self, table.unpack(args))
                end
            end
        end

        if method == "PlayLocalSound" or method == "Play" then
            local snd = args[1]
            if snd and typeof(snd) == "Instance" and snd:IsA("Sound") then
                if isClownAsset(snd.SoundId) then
                    return nil
                end
            end
        end

        return oldNamecall(self, ...)
    end)
end

local function installAntiAFK()
    local conn
    conn = LocalPlayer.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end)
    return conn
end

local function scheduleHubClickRecolor()
    task.defer(quickFixRedHubElements)
    task.delay(0.06, quickFixRedHubElements)
    task.delay(0.2, quickFixRedHubElements)
end

local function bindHubInteractFix(inst)
    if not (inst:IsA("TextButton") or inst:IsA("ImageButton")) then return end
    if not isUnderLikelyHub(inst) and not isHubGui(inst) then return end
    if inst:GetAttribute("FE6_HubInteractBound") then return end
    inst:SetAttribute("FE6_HubInteractBound", true)

    if inst:IsA("TextButton") and tabTextMatchesWhitelist(inst.Text) then
        fixTabTree(inst)
    else
        guardHubElement(inst)
    end

    inst.MouseButton1Click:Connect(function()
        scheduleHubClickRecolor()
        if inst:IsA("TextButton") and tabTextMatchesWhitelist(inst.Text) then
            task.delay(0.12, function()
                fixTabTree(inst)
            end)
        end
    end)
end

local function bindTabPurpleFix(inst)
    bindHubInteractFix(inst)
end

local hubTabFixInstalled = false

local function installHubTabFix()
    if hubTabFixInstalled then return end
    hubTabFixInstalled = true
    local function onDescendant(inst)
        if inst:IsA("TextButton") or inst:IsA("ImageButton") then
            bindHubInteractFix(inst)
        end
    end
    for _, root in ipairs({ PlayerGui }) do
        root.DescendantAdded:Connect(onDescendant)
    end
    pcall(function()
        local cg = game:GetService("CoreGui")
        if cg then cg.DescendantAdded:Connect(onDescendant) end
    end)
    if gethui then
        pcall(function()
            local hui = gethui()
            if hui then hui.DescendantAdded:Connect(onDescendant) end
        end)
    end
end

local function installKeybinds()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.RightShift then
            toggleHubMenu()
        end
    end)
end

local function installInventoryGuard()
    ensureBackpackEnabled()
end

local function watchForHubLoad()
    local function onDescendant(inst)
        if not hubLoaded and (inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox")) then
            local ok, txt = pcall(function() return inst.Text end)
            if ok and txt and (txt:lower():find("bloody", 1, true) or txt:lower():find("fling", 1, true) or txt == "Player") then
                hubLoaded = true
                task.delay(0.6, cleanupDevilArtifacts)
            end
        end
        if inst:IsA("ScreenGui") and not OUR_OVERLAY_NAMES[inst.Name] then
            registerHubGui(inst)
            local n = inst.Name:lower()
            if n:find("rayfield", 1, true) or n:find("bloody", 1, true) or registeredHubGuis[inst] then
                hubLoaded = true
                if not hubSweepScheduled then
                    hubSweepScheduled = true
                    scheduleSweep(1.2, true)
                end
                task.delay(0.6, cleanupDevilArtifacts)
            end
        end
    end

    for _, root in ipairs({ PlayerGui }) do
        root.DescendantAdded:Connect(onDescendant)
    end
    pcall(function()
        local cg = game:GetService("CoreGui")
        if cg then cg.DescendantAdded:Connect(onDescendant) end
    end)
    if gethui then
        pcall(function()
            local hui = gethui()
            if hui then hui.DescendantAdded:Connect(onDescendant) end
        end)
    end
    connectGuiRootChildAdded(function(child)
        if not child:IsA("ScreenGui") then return end
        registerHubGui(child)
        if registeredHubGuis[child] then
            if not hubSweepScheduled then
                hubSweepScheduled = true
                scheduleSweep(1.2, true)
            end
        elseif inventoryPurpleOn and isInventoryGui(child) then
            registerInventoryGui(child)
            scheduleInventoryRefresh(0.15)
        end
    end)
    for _, d in ipairs(PlayerGui:GetDescendants()) do
        onDescendant(d)
    end

    task.delay(2.5, function()
        if splashActive then
            cleanupDevilArtifacts()
        end
    end)
end

local function injectMiscToggle()
    task.spawn(function()
        for _ = 1, 60 do
            if hubLoaded then break end
            task.wait(0.5)
        end
        task.wait(1)

        for _, inst in ipairs(PlayerGui:GetDescendants()) do
            if (inst:IsA("TextLabel") or inst:IsA("TextButton")) and inst.Text == "Misc" and isHubGui(inst) then
                local parent = inst.Parent
                if parent then
                    local section = parent.Parent
                    if section and isHubGui(section) and not section:FindFirstChild("FE6_PurpleSkyToggle") then
                        local row = Instance.new("TextButton")
                        row.Name = "FE6_PurpleSkyToggle"
                        row.Size = UDim2.new(1, -16, 0, 32)
                        row.BackgroundColor3 = THEME.card
                        row.BorderSizePixel = 0
                        row.Font = Enum.Font.Gotham
                        row.TextSize = 14
                        row.TextColor3 = Color3.fromRGB(255, 255, 255)
                        row.Text = "  Purple Sky Shader"
                        row.TextXAlignment = Enum.TextXAlignment.Left
                        row.AutoButtonColor = true
                        row.Parent = section

                        local corner = Instance.new("UICorner")
                        corner.CornerRadius = UDim.new(0, 6)
                        corner.Parent = row

                        row.MouseButton1Click:Connect(function()
                            safeCycleSkyShader()
                        end)

                        local invRow = Instance.new("TextButton")
                        invRow.Name = "FE6_InventoryPurpleToggle"
                        invRow.Size = UDim2.new(1, -16, 0, 32)
                        invRow.Position = UDim2.new(0, 0, 0, 36)
                        invRow.BackgroundColor3 = THEME.card
                        invRow.BorderSizePixel = 0
                        invRow.Font = Enum.Font.Gotham
                        invRow.TextSize = 14
                        invRow.TextColor3 = Color3.fromRGB(255, 255, 255)
                        invRow.Text = inventoryPurpleOn and "  💜 Purple Inventory: ON" or "  💜 Purple Inventory: OFF"
                        invRow.TextXAlignment = Enum.TextXAlignment.Left
                        invRow.AutoButtonColor = true
                        invRow.Parent = section

                        local invCorner = Instance.new("UICorner")
                        invCorner.CornerRadius = UDim.new(0, 6)
                        invCorner.Parent = invRow

                        invRow.MouseButton1Click:Connect(function()
                            inventoryPurpleOn = not inventoryPurpleOn
                            invRow.Text = inventoryPurpleOn and "  💜 Purple Inventory: ON" or "  💜 Purple Inventory: OFF"
                            if inventoryPurpleOn then
                                scheduleInventoryRefresh(0.05)
                            end
                        end)
                        break
                    end
                end
            end
        end
    end)
end

local function httpGet(url)
    local function finish(body)
        if not isBloodyUrl(url) and (shouldPatchHttpUrl(url) or looksLikeRayfieldSource(body)) then
            return patchRayfieldSource(body)
        end
        return body
    end
    if syn and syn.request then
        local ok, res = pcall(syn.request, {Url = url, Method = "GET"})
        if ok and res and res.Body and #res.Body > 100 then
            return finish(res.Body)
        end
    end
    if http and http.request then
        local ok, res = pcall(http.request, {Url = url, Method = "GET"})
        if ok and res and res.Body and #res.Body > 100 then
            return finish(res.Body)
        end
    end
    local ok, body = pcall(function() return game:HttpGet(url) end)
    if ok and type(body) == "string" and #body > 100 then
        return finish(body)
    end
    error("Could not HttpGet — use MacSploit")
end

local function downloadBloodySource()
    installPremiumBypass()
    local src
    local ok, err = pcall(function()
        src = game:HttpGet(BLOODY_URL)
    end)
    if ok and type(src) == "string" and #src >= 8000 then
        return patchHubSource(src)
    end
    if syn and syn.request then
        local reqOk, res = pcall(syn.request, { Url = BLOODY_URL, Method = "GET" })
        if reqOk and res and type(res.Body) == "string" and #res.Body >= 8000 then
            return patchHubSource(res.Body)
        end
    end
    if http and http.request then
        local reqOk, res = pcall(http.request, { Url = BLOODY_URL, Method = "GET" })
        if reqOk and res and type(res.Body) == "string" and #res.Body >= 8000 then
            return patchHubSource(res.Body)
        end
    end
    error("Hub download failed: " .. tostring(err))
end

local function sendFe6ChatMessage(text)
    text = text or CHAT_MSG

    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
    end)

    task.wait(0.1)

    local delivered = false

    -- Public server chat (like tokra "free beta") — visible to other players
    pcall(function()
        local events = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            or ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents", 6)
        if events then
            local say = events:FindFirstChild("SayMessageRequest")
            if say then
                say:FireServer(text, "All")
                delivered = true
            end
        end
    end)

    pcall(function()
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local channels = TextChatService:FindFirstChild("TextChannels")
                or TextChatService:WaitForChild("TextChannels", 8)
            if channels then
                local channel = channels:FindFirstChild("RBXGeneral")
                    or channels:FindFirstChildWhichIsA("TextChannel")
                if channel and channel.SendAsync then
                    channel:SendAsync(text)
                    delivered = true
                end
            end
        end
    end)

    if not delivered then
        pcall(function()
            LocalPlayer:Chat(text)
            delivered = true
        end)
    end

    pcall(function()
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local channels = TextChatService:FindFirstChild("TextChannels")
            if channels then
                for _, channelName in ipairs({ "RBXSystem", "RBXGeneral" }) do
                    local channel = channels:FindFirstChild(channelName)
                    if channel and channel.DisplaySystemMessage then
                        channel:DisplaySystemMessage(text)
                    end
                end
            end
        else
            StarterGui:SetCore("ChatMakeSystemMessage", {
                Text = text,
                Color = THEME.accent,
                Font = Enum.Font.GothamBold,
                FontSize = Enum.FontSize.Size24,
            })
        end
    end)

    return delivered
end

local function isHubLoadingVisible()
    for _, gui in ipairs(PlayerGui:GetChildren()) do
        if isLoadingOnlyGui(gui) then
            return true
        end
    end
    return false
end

local function hubHasPurpleApplied()
    local hub = resolveWrapperHub()
    if not hub or not hub.Parent then return false end
    local accent = THEME.accent
    for _, d in ipairs(hub:GetDescendants()) do
        if d:IsA("GuiObject") then
            local c = d.BackgroundColor3
            if math.abs(c.R - accent.R) < 0.06
                and math.abs(c.G - accent.G) < 0.06
                and math.abs(c.B - accent.B) < 0.06 then
                return true
            end
        elseif d:IsA("UIStroke") then
            local c = d.Color
            if math.abs(c.R - accent.R) < 0.06
                and math.abs(c.G - accent.G) < 0.06
                and math.abs(c.B - accent.B) < 0.06 then
                return true
            end
        end
    end
    return false
end

local function scheduleChatAnnounceOnce()
    if chatAnnounced then return end
    task.spawn(function()
        pcall(function()
            TextChatService:WaitForChild("TextChannels", 25)
        end)

        local ready = false
        for _ = 1, 60 do
            if hubLoaded and not isHubLoadingVisible() and resolveWrapperHub() then
                ready = true
                break
            end
            task.wait(0.5)
        end

        if ready then
            for _ = 1, 20 do
                if hubHasPurpleApplied() then break end
                task.wait(0.5)
            end
        end

        task.wait(1.5)

        if not chatAnnounced and hubLoaded then
            chatAnnounced = true
            sendFe6ChatMessage(CHAT_MSG)
            pcall(function()
                StarterGui:SetCore("SendNotification", {
                    Title = CHAT_NAME,
                    Text = CHAT_MSG,
                    Duration = 5,
                })
            end)
        end
    end)
end

local function compileAndRunBloody(src)
    local loader = loadstring or load
    if not loader then
        error("No loadstring available")
    end
    local fn, compileErr = loader(src)
    if not fn then
        error("Failed to compile FE6 hub: " .. tostring(compileErr))
    end
    local runOk, runErr = pcall(fn)
    if not runOk then
        error("FE6 hub runtime error: " .. tostring(runErr))
    end
end

local function installPostBloodySystems()
    if postBloodyReady then return end
    postBloodyReady = true
    bloodyLoadPhase = false
    installHubTabFix()
    installHubPurpleEnforcer()
    hijackRayfieldTheme()
    ensureHubVisible()
    ensureBackpackEnabled()
    applyHubPurpleOnce()
    for _, delay in ipairs({ 0.5, 1.5, 3, 6, 10 }) do
        task.delay(delay, function()
            hijackRayfieldTheme()
            applyHubPurpleOnce()
        end)
    end
    if inventoryPurpleOn then
        scheduleInventoryRefresh(0.35)
        task.delay(3, refreshInventoryPurple)
    end
end

local function loadBloodyHub(attempt)
    attempt = attempt or 1
    local ok, err = pcall(function()
        local src = downloadBloodySource()
        compileAndRunBloody(src)
    end)
    if not ok then
        warn("[FE6 x DE11] FE6 hub load failed (attempt " .. attempt .. "):", err)
        if attempt < 3 then
            task.wait(2)
            return loadBloodyHub(attempt + 1)
        end
        local errMsg = tostring(err):gsub("\n", " "):sub(1, 80)
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = CHAT_NAME,
                Text = "Load failed: " .. errMsg,
                Duration = 8,
            })
        end)
        cleanupDevilArtifacts()
        ensureHubVisible()
    else
        hubLoaded = true
        installPostBloodySystems()
        for _, gui in ipairs(PlayerGui:GetChildren()) do registerHubGui(gui) end
        pcall(scrubHubTitles)
        task.delay(0.5, scrubHubTitles)
        task.delay(1.5, scrubHubTitles)
        task.delay(3.5, function()
            if not splashActive then cleanupDevilArtifacts() end
        end)
        forceOpenRayfieldHub()
        task.delay(2.5, suppressRayfieldLoading)
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = CHAT_NAME,
                Text = LOAD_POPUP,
                Duration = 6,
            })
        end)
        scheduleChatAnnounceOnce()
    end
    return ok
end

local function main()
    installPremiumBypass()

    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = CHAT_NAME,
            Text = "Starting load...",
            Duration = 3,
        })
    end)

    if game.PlaceId ~= FTAP_PLACE_ID then
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = CHAT_NAME,
                Text = "Not FTAP - loading anyway",
                Duration = 3,
            })
        end)
    end

    cleanupDevilArtifacts()
    cleanupWorldEffects()
    restoreDefaultMouse()
    installRuntimeHooks()
    installAntiAFK()
    installKeybinds()
    installInventoryGuard()
    createSkyOverlay()
    createScaryOverlay()
    watchForHubLoad()

    -- splash first so it actually shows
    pcall(showBriefEliteSplash)

    task.spawn(function()
        preloadRayfield()
        hijackRayfieldTheme()
        local loaded = loadBloodyHub()
        if loaded then
            installThrowVisuals()
            installAimPointDebug()
            injectMiscToggle()
            task.delay(0.3, scrubHubTitles)
            task.delay(1, function()
                hijackRayfieldTheme()
                forceOpenRayfieldHub()
                applyHubPurpleOnce()
                scrubHubTitles()
            end)
        end
    end)

    if getgenv then
        getgenv().FE6_Loaded = true
    end

    task.delay(12, function()
        if not chatAnnounced and hubLoaded then
            chatAnnounced = true
            sendFe6ChatMessage(CHAT_MSG)
            pcall(function()
                StarterGui:SetCore("SendNotification", {
                    Title = CHAT_NAME,
                    Text = CHAT_MSG,
                    Duration = 5,
                })
            end)
        end
    end)
end

local bootOk, bootErr = pcall(main)
if not bootOk then
    warn("[FE6 x DE11] Fatal boot error:", bootErr)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = CHAT_NAME,
            Text = "Boot failed: " .. tostring(bootErr):sub(1, 100),
            Duration = 8,
        })
    end)
end