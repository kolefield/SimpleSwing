local ADDON, ns = ...
local edit = ns.LibEditMode
local bar, primaryBar, offBar, db, activeLayout, preview
local timers = { [0] = ns.NewTimer(), [1] = ns.NewTimer(), [2] = ns.NewTimer() }
local activeAttack, dualWield = 0, false
local AUTO_ATTACK = 3 -- Addon option; the game's actual swing types are 0, 1, 2.
local defaults = {
    point = "CENTER", x = 0, y = -160,
    width = 240, height = 12,
    primary = { 0.25, 0.78, 1, 1 },
    background = { 0.06, 0.06, 0.08, 0.8 },
    attack = AUTO_ATTACK,
}

local function Copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = Copy(item) end
    return result
end

local function Clamp(value, low, high, fallback)
    if type(value) ~= "number" or value ~= value then return fallback end
    return math.min(high, math.max(low, value))
end

local function Coordinate(value)
    value = math.floor(Clamp(value, -10000, 10000, 0) * 100 + 0.5) / 100
    return value == 0 and 0 or value
end

local anchors = {
    CENTER = true, TOP = true, BOTTOM = true, LEFT = true, RIGHT = true,
    TOPLEFT = true, TOPRIGHT = true, BOTTOMLEFT = true, BOTTOMRIGHT = true,
}

local function Normalize(profile)
    if type(profile) ~= "table" then profile = {} end
    if not anchors[profile.point] then profile.point = defaults.point end
    profile.x = Coordinate(Clamp(profile.x, -10000, 10000, defaults.x))
    profile.y = Coordinate(Clamp(profile.y, -10000, 10000, defaults.y))
    profile.width = math.floor(Clamp(profile.width, 40, 1000, defaults.width) + 0.5)
    profile.height = math.floor(Clamp(profile.height, 2, 100, defaults.height) + 0.5)
    -- Old Main Hand and Off Hand selections both migrate to combined Melee.
    if profile.attack == 1 then profile.attack = 0 end
    if profile.attack ~= 0 and profile.attack ~= 2 and profile.attack ~= AUTO_ATTACK then
        profile.attack = defaults.attack
    end
    for _, key in ipairs({ "primary", "background" }) do
        if type(profile[key]) ~= "table" then profile[key] = {} end
        for i = 1, 4 do
            profile[key][i] = Clamp(profile[key][i], 0, 1, defaults[key][i])
        end
    end
    return profile
end

local function Profile(layoutName)
    local key = layoutName or activeLayout or "Default"
    db.layouts[key] = Normalize(db.layouts[key])
    return db.layouts[key]
end

local function ResetTimer()
    for _, timer in pairs(timers) do timer:Reset() end
    if bar then
        primaryBar:SetValue(preview and 0.65 or 1)
        offBar:SetValue(preview and 0.4 or 1)
        bar:SetScript("OnUpdate", nil)
    end
end

local function Tick()
    local now = GetTime()
    local fraction, running = timers[activeAttack]:Progress(now)
    primaryBar:SetValue(fraction)
    local offRunning = false
    if activeAttack == 0 and dualWield then
        fraction, offRunning = timers[1]:Progress(now)
        offBar:SetValue(fraction)
    end
    if not running and not offRunning then bar:SetScript("OnUpdate", nil) end
end

local function RefreshWeapons()
    local _, speed = UnitAttackSpeed("player")
    if issecretvalue and issecretvalue(speed) then return end
    dualWield = type(speed) == "number" and speed > 0
end

local function UpdateVisibility()
    if not bar then return end
    bar:SetShown(preview or UnitAffectingCombat("player"))
end

local function Apply()
    if not bar then return end
    local profile = Profile()
    bar:SetSize(profile.width, profile.height)
    bar:ClearAllPoints()
    bar:SetPoint(profile.point, UIParent, profile.point, profile.x, profile.y)
    local mode = profile.attack
    if mode ~= AUTO_ATTACK then activeAttack = mode end
    local stacked = dualWield and activeAttack == 0
    -- Height is the total footprint, so enabling the second hand does not move
    -- the saved anchor or change the size of the Edit Mode selection.
    local gap = stacked and profile.height >= 6 and 2 or 0
    local rowHeight = stacked and (profile.height - gap) / 2 or profile.height
    primaryBar:ClearAllPoints()
    primaryBar:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
    primaryBar:SetSize(profile.width, rowHeight)
    offBar:ClearAllPoints()
    offBar:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
    offBar:SetSize(profile.width, rowHeight)
    offBar:SetShown(stacked)
    for _, fill in ipairs({ primaryBar, offBar }) do
        fill:SetStatusBarColor(unpack(profile.primary))
        fill.Background:SetColorTexture(unpack(profile.background))
    end
    if preview then
        primaryBar:SetValue(0.65)
        offBar:SetValue(0.4)
        bar:SetScript("OnUpdate", nil)
    end
    UpdateVisibility()
end

local function CleanCoordinateFields()
    -- The private, pinned LibEditMode copy is kept unmodified on disk. Clean up
    -- its coordinate widget after its normal positioning calculation.
    local coords = edit.internal and edit.internal.dialog and edit.internal.dialog.Coords
    if not coords then return end
    hooksecurefunc(coords, "Update", function(self, selection)
        if selection.parent ~= bar then return end
        self.x, self.y = Coordinate(self.x), Coordinate(self.y)
        self.XEditBox.value, self.YEditBox.value = self.x, self.y
        self.XEditBox:SetText(self.x)
        self.YEditBox:SetText(self.y)
    end)
end

local function CreateBar(name)
    local fill = CreateFrame("StatusBar", name, bar)
    fill:EnableMouse(false)
    fill:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    fill:SetMinMaxValues(0, 1)
    fill:SetValue(1)
    fill.Background = fill:CreateTexture(nil, "BACKGROUND")
    fill.Background:SetAllPoints(fill)
    return fill
end

local function Slider(key, name, low, high)
    return {
        kind = edit.SettingType.Slider, name = name,
        default = defaults[key], minValue = low, maxValue = high, valueStep = 1,
        get = function(layout) return Profile(layout)[key] end,
        set = function(layout, value)
            Profile(layout)[key] = math.floor(Clamp(value, low, high, defaults[key]) + 0.5)
            Apply()
        end,
    }
end

local function Color(key, name)
    return {
        kind = edit.SettingType.ColorPicker, name = name, hasOpacity = true,
        default = CreateColor(unpack(defaults[key])),
        get = function(layout) return CreateColor(unpack(Profile(layout)[key])) end,
        set = function(layout, color)
            Profile(layout)[key] = { color:GetRGBA() }
            Apply()
        end,
    }
end

local function Initialize()
    if bar then return end
    if not Enum.PlayerSwingType or not C_SwingTimer then
        print("Simple Swing requires WoW: Forever's swing-timer API.")
        return
    end

    local _, class = UnitClass("player")
    defaults.attack = class == "HUNTER" and AUTO_ATTACK or Enum.PlayerSwingType.MainHand
    SimpleSwingDB = type(SimpleSwingDB) == "table" and SimpleSwingDB or {}
    db = SimpleSwingDB
    db.version = 2
    db.layouts = type(db.layouts) == "table" and db.layouts or {}
    activeLayout = edit:GetActiveLayoutName() or "Default"

    bar = CreateFrame("Frame", "SimpleSwingBar", UIParent)
    bar:SetFrameStrata("MEDIUM")
    bar:SetClampedToScreen(true)
    bar:SetDontSavePosition(true)
    bar:EnableMouse(false)
    primaryBar = CreateBar("SimpleSwingPrimaryBar")
    offBar = CreateBar("SimpleSwingOffHandBar")
    RefreshWeapons()
    -- Deliberately no FontStrings, icons, border, spark, tooltip, or mouse capture.
    Apply()

    edit:AddFrame(bar, function(_, layoutName, point, x, y)
        local profile = Profile(layoutName)
        profile.point, profile.x, profile.y = point, x, y
        Apply()
    end, { point = defaults.point, x = defaults.x, y = defaults.y }, "Simple Swing")
    CleanCoordinateFields()

    edit:AddFrameSettings(bar, {
        Slider("width", "Width", 40, 1000),
        Slider("height", "Height", 2, 100),
        Color("primary", "Primary Color"),
        Color("background", "Background Color"),
        {
            kind = edit.SettingType.Dropdown, name = "Attack",
            default = defaults.attack,
            values = {
                { text = "Automatic (melee / ranged)", value = AUTO_ATTACK },
                { text = "Ranged / Auto Shot", value = Enum.PlayerSwingType.Ranged },
                { text = "Melee", value = Enum.PlayerSwingType.MainHand },
            },
            get = function(layout) return Profile(layout).attack end,
            set = function(layout, value)
                if value == 0 or value == 2 or value == AUTO_ATTACK then
                    Profile(layout).attack = value
                    ResetTimer()
                    Apply()
                end
            end,
        },
    })

    edit:RegisterCallback("enter", function()
        preview = true
        RefreshWeapons()
        if Profile().attack == AUTO_ATTACK then activeAttack = 0 end
        ResetTimer()
        Apply()
    end)
    edit:RegisterCallback("exit", function()
        preview = false
        ResetTimer()
        Apply()
    end)
    edit:RegisterCallback("layout", function(name)
        if not name then return end
        -- Migrate the startup fallback only once the server has sent layout names.
        if not db.layouts[name] and activeLayout == "Default" and db.layouts.Default then
            db.layouts[name] = Copy(db.layouts.Default)
        end
        activeLayout = name
        ResetTimer()
        Apply()
    end)
    edit:RegisterCallback("create", function(name, _, source)
        db.layouts[name] = Copy(Profile(source or activeLayout))
    end)
    edit:RegisterCallback("rename", function(oldName, newName)
        if db.layouts[oldName] then
            db.layouts[newName] = db.layouts[oldName]
            db.layouts[oldName] = nil
        end
        if activeLayout == oldName then activeLayout = newName end
    end)
    edit:RegisterCallback("delete", function(name)
        db.layouts[name] = nil
    end)

    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_SWING")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("PLAYER_DEAD")
    events:RegisterEvent("PLAYER_IN_COMBAT_CHANGED")
    events:RegisterEvent("PLAYER_REGEN_DISABLED")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:RegisterEvent("WEAPON_SLOT_CHANGED")
    events:RegisterUnitEvent("UNIT_ATTACK_SPEED", "player")
    -- Do not reset for UNIT_INVENTORY_CHANGED: ammunition use and other
    -- inventory updates do not mean the weapon or its swing cycle changed.
    -- Actual weapon swaps and world entry have their own reset events above.
    events:SetScript("OnEvent", function(_, event, first, second)
        if event == "PLAYER_SWING" then
            if preview then return end
            if issecretvalue and issecretvalue(second) then return end
            if second ~= 0 and second ~= 1 and second ~= 2 then return end
            local attack = Profile().attack
            local family = second == 2 and 2 or 0
            if (attack == AUTO_ATTACK or family == attack) and timers[second]:Start(first, GetTime()) then
                activeAttack = family
                -- An observed off-hand swing is authoritative even when the
                -- equipped-speed API is temporarily restricted.
                if second == 1 then dualWield = true end
                Apply()
                Tick()
                bar:SetScript("OnUpdate", Tick)
            end
        elseif event == "PLAYER_IN_COMBAT_CHANGED" or event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
            -- Keep an opening swing captured before the combat-state event.
            if not UnitAffectingCombat("player") then ResetTimer() end
            UpdateVisibility()
        elseif event == "UNIT_ATTACK_SPEED" then
            if first ~= "player" then return end
            RefreshWeapons()
            Apply()
        else
            RefreshWeapons()
            ResetTimer()
            Apply()
        end
    end)
    preview = edit:IsInEditMode()
    Apply()
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    Initialize()
end)
