local checks = 0
local function check(value, label)
    checks = checks + 1
    assert(value, "FAILED: " .. label)
end
local function equal(actual, expected, label)
    check(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function near(actual, expected, label)
    check(math.abs(actual - expected) < 0.00001, label)
end

-- Execute actual addon code with a small, explicit WoW API / LibEditMode contract.
-- These tests cannot certify rendering, template compatibility, or live combat.
unpack = table.unpack
local secret = {}
issecretvalue = function(value) return value == secret end
local model = {}
LoadSource("Timer.lua", model)
local timer = model.NewTimer()
equal(timer:Progress(0), 1, "idle is ready")
check(timer:Start(2.8, 100), "start real swing")
near(timer:Progress(100), 0, "swing starts empty")
near(timer:Progress(101.4), 0.5, "halfway")
equal(timer:Progress(99), 0, "clock rewind clamped")
local progress, running = timer:Progress(102.8)
equal(progress, 1, "swing completes")
equal(running, false, "updates stop when ready")
equal(timer:Progress(200), 1, "does not invent another swing")
check(not timer:Start(0, 0), "reject zero duration")
check(not timer:Start(-1, 0), "reject negative duration")
check(not timer:Start(0/0, 0), "reject NaN duration")
check(not timer:Start(math.huge, 0), "reject infinite duration")
check(not timer:Start(secret, 0), "reject secret duration without arithmetic")
check(not timer:Start(2, secret), "reject secret start")
check(not timer:Start("2", 0), "reject wrong type")

local now, frames, callbacks, settings, move, bar, layout, editing, combat
local createdFonts, main, off, offSpeed, coords, selection
local function frame(kind, name)
    local f = { kind = kind, name = name, scripts = {}, events = {} }
    function f:SetScript(event, callback) self.scripts[event] = callback end
    function f:RegisterEvent(event) self.events[event] = true end
    function f:UnregisterEvent(event) self.events[event] = nil end
    function f:RegisterUnitEvent(event, unit) self.events[event] = unit end
    function f:SetSize(width, height) self.width, self.height = width, height end
    function f:ClearAllPoints() self.point = nil end
    function f:SetPoint(point, parent, relative, x, y) self.point = {point, x, y} end
    function f:SetAllPoints(parent) self.allPoints = parent end
    function f:SetFrameStrata(value) self.strata = value end
    function f:SetClampedToScreen(value) self.clamped = value end
    function f:SetDontSavePosition(value) self.dontSave = value end
    function f:EnableMouse(value) self.mouse = value end
    function f:SetStatusBarTexture(value) self.texture = value end
    function f:SetMinMaxValues(low, high) self.low, self.high = low, high end
    function f:SetValue(value) self.value = value end
    function f:SetShown(value) self.shown = not not value end
    function f:SetStatusBarColor(...) self.color = {...} end
    function f:SetColorTexture(...) self.color = {...} end
    function f:CreateTexture() return frame("Texture") end
    function f:CreateFontString()
        if self == bar or self == main or self == off then createdFonts = createdFonts + 1 end
        return frame("FontString")
    end
    function f:SetHeight(value) self.height = value end
    function f:SetWidth(value) self.width = value end
    function f:SetFrameLevel(value) self.level = value end
    function f:Hide() self.shown = false end
    function f:Show() self.shown = true end
    function f:SetText(value) self.text = tostring(value) end
    function f:GetText() return self.text end
    function f:SetAutoFocus() end
    function f:SetJustifyH() end
    function f:HighlightText() end
    function f:ClearFocus() end
    function f:SetNormalAtlas() end
    function f:SetPushedAtlas() end
    function f:SetHighlightAtlas() end
    function f:GetParent() return self.parent end
    return f
end

local function emit(event, ...)
    -- Snapshot: initialization can create a new event frame during PLAYER_LOGIN.
    local listeners = {}
    for _, f in ipairs(frames) do
        if f.events[event] then listeners[#listeners + 1] = f end
    end
    for _, f in ipairs(listeners) do f.scripts.OnEvent(f, event, ...) end
end

local function boot(saved, class, initialLayout, inCombat, equippedOffSpeed)
    frames, callbacks, settings, now, createdFonts = {}, {}, {}, 100, 0
    layout, editing = initialLayout or "My Layout", false
    combat = not not inCombat
    offSpeed = equippedOffSpeed
    SimpleSwingDB = saved
    UIParent = frame("Frame")
    Enum = { PlayerSwingType = { MainHand = 0, OffHand = 1, Ranged = 2 } }
    C_SwingTimer = {}
    UnitAttackSpeed = function() return 2, offSpeed end
    GetTime = function() return now end
    UnitAffectingCombat = function(unit) assert(unit == "player"); return combat end
    UnitClass = function() return class or "Hunter", class or "HUNTER" end
    CreateColor = function(r,g,b,a)
        return {GetRGBA = function() return r,g,b,a or 1 end}
    end
    CreateFrame = function(kind, name, parent)
        local f = frame(kind, name)
        f.parent = parent
        frames[#frames + 1] = f
        if name == "SimpleSwingBar" then bar = f end
        if name == "SimpleSwingPrimaryBar" then main = f end
        if name == "SimpleSwingOffHandBar" then off = f end
        return f
    end
    Mixin = function(target, mixin)
        for key, value in pairs(mixin) do target[key] = value end
        return target
    end
    hooksecurefunc = function(target, key, after)
        local original = target[key]
        target[key] = function(...)
            original(...)
            after(...)
        end
    end
    HEADER_COLON = ":"
    local lib = {SettingType = {Slider=1, ColorPicker=10, Dropdown=0}, internal = {}}
    function lib.internal:CalculateParentPosition(s)
        return s.parent.point[1], s.parent.point[2] - 0.00006103515625, s.parent.point[3]
    end
    function lib.internal:MoveParentToPoint(s, point, x, y)
        move(s.parent, layout, point, x - 0.00006103515625, y)
        coords:Update(s, point, x - 0.00006103515625, y)
    end
    function lib:GetActiveLayoutName() return layout end
    function lib:IsInEditMode() return editing end
    function lib:AddFrame(f, callback, defaults, name)
        equal(f, bar, "Edit Mode registers the actual bar")
        equal(name, "Simple Swing", "Edit Mode selection label")
        move = callback
        selection = {parent = f}
        coords = lib.internal:CreateCoords(UIParent)
        lib.internal.dialog = {Coords = coords}
    end
    function lib:AddFrameSettings(f, list)
        for _, setting in ipairs(list) do settings[setting.name] = setting end
    end
    function lib:RegisterCallback(event, callback)
        callbacks[event] = callback
        if event == "layout" then callback(layout, 1) end
    end
    local ns = {LibEditMode = lib}
    LoadSource("Timer.lua", ns)
    LoadSource("Libs/LibEditMode/widgets/coords.lua", ns)
    LoadSource("SimpleSwing.lua", ns)
    emit("PLAYER_LOGIN")
end

boot()
equal(bar.shown, false, "hidden on login outside combat")
emit("PLAYER_SWING", 3, 2)
combat = true
emit("PLAYER_IN_COMBAT_CHANGED")
equal(bar.shown, true, "visible when entering combat")
equal(main.value, 0, "combat entry preserves opening swing")
check(bar.scripts.OnUpdate ~= nil, "opening swing continues after combat entry")
equal(createdFonts, 0, "no text created on the bar")
equal(bar.mouse, false, "click-through outside Edit Mode")
equal(bar.width, 240, "default width")
equal(bar.height, 12, "default height")
equal(settings.Attack.get(layout), 3, "hunter defaults to automatic")
equal(main.texture, "Interface\\Buttons\\WHITE8X8", "flat untextured fill")
equal(main.Background.allPoints, main, "background covers the whole bar")
emit("PLAYER_SWING", 3, 2)
now = 101
bar.scripts.OnUpdate()
near(main.value, 1/3, "automatic begins with ranged timing")
emit("PLAYER_SWING", 2, 0)
equal(main.value, 0, "automatic switches to melee on melee swing")
now = 102
bar.scripts.OnUpdate()
near(main.value, 0.5, "automatic uses melee duration")
emit("PLAYER_SWING", 1.5, 1)
near(main.value, 0.5, "off-hand swing preserves main-hand progress")
equal(off.value, 0, "off-hand starts independently")
now = 102.75
bar.scripts.OnUpdate()
near(off.value, 0.5, "off-hand uses its own duration")
near(main.value, 0.875, "main-hand keeps its own duration")
emit("PLAYER_SWING", 4, 2)
equal(main.value, 0, "automatic switches back to Auto Shot")
now = 103.75
bar.scripts.OnUpdate()
near(main.value, 0.25, "automatic uses new ranged duration")
emit("PLAYER_SWING", 2, 99)
near(main.value, 0.25, "unknown swing types ignored")
settings.Attack.set(layout, 2)
equal(bar.scripts.OnUpdate, nil, "changing attack mode clears previous cycle")
now = 100
emit("PLAYER_SWING", 3, 0)
equal(bar.scripts.OnUpdate, nil, "melee does not reset hunter ranged bar")
emit("PLAYER_SWING", 3, 2)
equal(main.value, 0, "ranged event starts bar")
now = 101.5
bar.scripts.OnUpdate()
near(main.value, 0.5, "ranged tick")
emit("PLAYER_SWING", 4, 1)
near(main.value, 0.5, "off-hand event ignored")
now = 103
bar.scripts.OnUpdate()
equal(main.value, 1, "ready bar full")
equal(bar.scripts.OnUpdate, nil, "no permanent update loop")
emit("PLAYER_SWING", secret, 2)
emit("PLAYER_SWING", 3, secret)
equal(bar.scripts.OnUpdate, nil, "secret events do not start a fake timer")

editing = true
combat = false
emit("PLAYER_REGEN_ENABLED")
equal(bar.shown, false, "hidden on leaving combat")
equal(bar.scripts.OnUpdate, nil, "combat exit stops timer updates")
callbacks.enter()
equal(bar.shown, true, "Edit Mode reveals out-of-combat bar")
equal(main.value, 0.65, "Edit Mode exposes both colors")
emit("PLAYER_SWING", 3, 2)
equal(main.value, 0.65, "preview is stable during events")
settings.Width.set(layout, 360)
settings.Height.set(layout, 18)
equal(bar.width, 360, "width updates immediately")
equal(bar.height, 18, "height updates immediately")
settings["Primary Color"].set(layout, CreateColor(1, 0.2, 0.3, 0.9))
settings["Background Color"].set(layout, CreateColor(0.2, 0.3, 0.4, 0.5))
near(main.color[1], 1, "primary RGB")
near(main.color[4], 0.9, "primary opacity")
near(main.Background.color[3], 0.4, "background RGB")
near(main.Background.color[4], 0.5, "background opacity")
check(settings["Primary Color"].hasOpacity, "primary opacity control")
check(settings["Background Color"].hasOpacity, "background opacity control")
move(bar, layout, "BOTTOM", 20, 220)
equal(bar.point[1], "BOTTOM", "drag anchor saved")
equal(bar.point[2], 20, "drag x saved")
equal(bar.point[3], 220, "drag y saved")
editing = false
callbacks.exit()
equal(bar.shown, false, "closing Edit Mode hides out-of-combat bar")
equal(main.value, 1, "exit leaves ready state")
equal(bar.scripts.OnUpdate, nil, "preview does not run after edit mode")

local saved = SimpleSwingDB
boot(saved)
equal(bar.width, 360, "width survives addon reload")
equal(bar.height, 18, "height survives addon reload")
equal(bar.point[1], "BOTTOM", "position survives addon reload")
near(main.color[2], 0.2, "primary survives addon reload")
near(main.Background.color[4], 0.5, "background survives addon reload")

callbacks.create("Copy", 2, layout)
layout = "Copy"
callbacks.layout(layout)
equal(bar.width, 360, "new layout inherits source")
settings.Width.set(layout, 450)
equal(SimpleSwingDB.layouts["My Layout"].width, 360, "copied layout is independent")
settings["Primary Color"].set(layout, CreateColor(0, 1, 0, 1))
equal(SimpleSwingDB.layouts["My Layout"].primary[1], 1, "copied colors independent")
callbacks.rename("Copy", "Renamed")
layout = "Renamed"
callbacks.layout(layout)
equal(bar.width, 450, "layout rename retains settings")
equal(SimpleSwingDB.layouts.Copy, nil, "old layout key removed")
layout = "My Layout"
callbacks.layout(layout)
equal(bar.width, 360, "switch layout restores settings")
callbacks.delete("Renamed")
equal(SimpleSwingDB.layouts.Renamed, nil, "deleted layout cleaned up")

settings.Width.set(layout, 2000)
settings.Height.set(layout, -20)
equal(bar.width, 1000, "width upper bound")
equal(bar.height, 2, "height lower bound")
settings.Width.set(layout, settings.Width.default, true)
settings.Height.set(layout, settings.Height.default, true)
equal(bar.width, 240, "reset width")
equal(bar.height, 12, "reset height")
settings.Attack.set(layout, 0)
emit("PLAYER_SWING", 2, 0)
equal(main.value, 0, "main-hand source can be selected")
emit("PLAYER_DEAD")
equal(main.value, 1, "death clears stale timer")
equal(bar.scripts.OnUpdate, nil, "death stops updates")
emit("PLAYER_SWING", 2, 0)
emit("WEAPON_SLOT_CHANGED")
equal(bar.scripts.OnUpdate, nil, "weapon change clears stale timer")
emit("PLAYER_SWING", 2, 0)
emit("PLAYER_ENTERING_WORLD")
equal(bar.scripts.OnUpdate, nil, "loading screen clears timer")
emit("PLAYER_SWING", 2, 0)
emit("UNIT_INVENTORY_CHANGED", "player")
check(bar.scripts.OnUpdate ~= nil, "ordinary inventory updates preserve melee timer")

-- Ammo consumption is an inventory update, not a weapon swap. It must not
-- turn a just-fired ranged swing into a ready/full bar.
settings.Attack.set(layout, 3)
now = 200
emit("PLAYER_SWING", 3, 2)
now = 200.01
emit("UNIT_INVENTORY_CHANGED", "player")
equal(main.value, 0, "ammo update does not snap ranged bar full")
check(bar.scripts.OnUpdate ~= nil, "ammo update keeps ranged timer running")
now = 200.75
bar.scripts.OnUpdate()
near(main.value, 0.25, "ranged quarter-cycle after ammo update")
emit("UNIT_INVENTORY_CHANGED", "player")
emit("UNIT_INVENTORY_CHANGED", "pet")
now = 201.5
bar.scripts.OnUpdate()
near(main.value, 0.5, "repeated inventory updates preserve ranged deadline")
now = 202.99
bar.scripts.OnUpdate()
check(main.value < 1, "ranged remains unready until full swing elapsed")
now = 203
bar.scripts.OnUpdate()
equal(main.value, 1, "ranged completes at real swing deadline")
equal(bar.scripts.OnUpdate, nil, "completed ranged cycle stops updates")
emit("UNIT_INVENTORY_CHANGED", "player")
emit("PLAYER_SWING", 3, 2)
equal(main.value, 0, "inventory before shot does not block next ranged cycle")
emit("WEAPON_SLOT_CHANGED")
equal(bar.scripts.OnUpdate, nil, "actual weapon swap still clears ranged timer")

boot(nil, "WARRIOR")
equal(settings.Attack.get(layout), 0, "other classes default to combined melee")
boot({layouts = {["My Layout"] = {width = -2, height = "bad", point = "INVALID", primary = {2, -1}}}})
equal(bar.width, 40, "damaged width sanitized")
equal(bar.height, 12, "damaged height sanitized")
equal(bar.point[1], "CENTER", "damaged anchor sanitized")
equal(main.color[1], 1, "damaged color clamped high")
equal(main.color[2], 0, "damaged color clamped low")
equal(main.color[4], 1, "missing alpha restored")

boot()
saved = SimpleSwingDB
boot(saved)
equal(settings.Attack.get(layout), 3, "automatic mode persists across reload")

boot(nil, nil, nil, true)
equal(bar.shown, true, "reload during combat starts visible")
callbacks.enter()
callbacks.exit()
equal(bar.shown, true, "closing Edit Mode during combat stays visible")
combat = false
emit("PLAYER_IN_COMBAT_CHANGED")
equal(bar.shown, false, "native combat event hides bar")
combat = true
emit("PLAYER_REGEN_DISABLED")
equal(bar.shown, true, "regen-disabled event shows bar")
combat = false
emit("PLAYER_ENTERING_WORLD")
equal(bar.shown, false, "world entry refreshes visibility")

-- Independent stacked timers: neither hand resets or replaces the other.
boot(nil, "WARRIOR", nil, true, 1.5)
equal(#settings.Attack.values, 3, "only Automatic, Ranged and Melee choices")
equal(settings.Attack.values[3].text, "Melee", "combined melee option")
check(off.shown, "equipped off-hand shows second row before first swing")
equal(main.point[1], "TOPLEFT", "main hand on top")
equal(off.point[1], "BOTTOMLEFT", "off hand underneath")
equal(main.height + off.height + 2, bar.height, "two rows fit configured total height")
emit("PLAYER_SWING", 3, 0)
now = 100.5
emit("PLAYER_SWING", 1.5, 1)
near(main.value, 1/6, "off-hand event does not restart main-hand")
equal(off.value, 0, "off-hand event empties only off-hand")
now = 101.25
bar.scripts.OnUpdate()
near(main.value, 1.25/3, "main-hand independent deadline")
near(off.value, 0.5, "off-hand independent deadline")
emit("PLAYER_SWING", 3, 0)
near(off.value, 0.5, "main-hand event preserves off-hand progress")
now = 102
bar.scripts.OnUpdate()
equal(off.value, 1, "off-hand fills at its own deadline")
check(bar.scripts.OnUpdate ~= nil, "updates continue for unfinished main hand")
now = 104.25
bar.scripts.OnUpdate()
equal(main.value, 1, "main-hand fills at its own deadline")
equal(bar.scripts.OnUpdate, nil, "both ready stops update loop")
settings.Attack.set(layout, 3)
emit("PLAYER_SWING", 3, 2)
equal(off.shown, false, "ranged mode collapses to one bar")
equal(main.height, bar.height, "ranged uses full height")
emit("PLAYER_SWING", 3, 0)
equal(off.shown, true, "automatic melee restores stacked rows")
settings.Height.set(layout, 2)
equal(main.height, 1, "minimum height gives main-hand one unit")
equal(off.height, 1, "minimum height gives off-hand one unit")
settings["Primary Color"].set(layout, CreateColor(0.8, 0.2, 0.3, 0.7))
near(off.color[1], 0.8, "both rows share fill color")
settings["Background Color"].set(layout, CreateColor(0.4, 0.3, 0.2, 0.6))
near(off.Background.color[4], 0.6, "both rows share background opacity")
emit("PLAYER_SWING", 3, 0)
emit("PLAYER_SWING", 1.5, 1)
now = 105
offSpeed = 1.2
emit("UNIT_ATTACK_SPEED", "player")
bar.scripts.OnUpdate()
near(main.value, 0.25, "speed notifications do not reset main-hand timer")
near(off.value, 0.5, "speed notifications do not reset off-hand timer")
offSpeed = nil
emit("WEAPON_SLOT_CHANGED")
equal(off.shown, false, "removing off-hand weapon hides second row")
equal(main.value, 1, "weapon swap resets main-hand")
equal(off.value, 1, "weapon swap resets off-hand")
offSpeed = secret
emit("UNIT_ATTACK_SPEED", "player")
equal(off.shown, false, "restricted speed value is not inspected")
emit("PLAYER_SWING", 1.5, 1)
equal(off.shown, true, "real off-hand swing reveals second row with restricted speed")
combat = false
emit("PLAYER_REGEN_ENABLED")
equal(bar.shown, false, "both rows hidden outside combat through parent")
callbacks.enter()
near(main.value, 0.65, "main preview")
near(off.value, 0.4, "off-hand preview")

boot({layouts = {["My Layout"] = {attack = 1, x = 15, width = 330}}}, "WARRIOR", nil, false, 1.5)
equal(settings.Attack.get(layout), 0, "old off-hand selection migrates to Melee")
equal(bar.width, 330, "migration preserves size")
equal(bar.point[2], 15, "migration preserves position")
check(off.shown, "migrated profile has both hands")
equal(createdFonts, 0, "neither gameplay row has text")

-- Exercise the actual vendored coordinate widget (including focus/submit/reset),
-- with the same fractional drift seen in the user's screenshot.
coords:Update(selection, "CENTER", -6.103515625e-05, -167.49989318848)
equal(coords.XEditBox:GetText(), "0", "near-zero coordinate displays exactly zero")
equal(tonumber(coords.YEditBox:GetText()), -167.5, "Y display rounded to two decimals")
equal(coords.XEditBox.value, 0, "focus/reset value also cleaned")
coords.XEditBox.scripts.OnEditFocusGained(coords.XEditBox)
equal(coords.XEditBox:GetText(), "0", "focus does not restore scientific notation")
coords.XEditBox:SetText("0")
coords.XEditBox.scripts.OnEnterPressed(coords.XEditBox)
equal(SimpleSwingDB.layouts[layout].x, 0, "typing zero persists exactly zero")
equal(bar.point[2], 0, "zero anchor applied exactly")
equal(coords.XEditBox:GetText(), "0", "typing zero remains zero after widget recalculation")
coords.XEditBox:SetText("123.456")
coords.XEditBox.scripts.OnEnterPressed(coords.XEditBox)
equal(SimpleSwingDB.layouts[layout].x, 123.46, "fractional position retains hundredth precision")
coords.XEditBox.scripts.OnEditFocusLost(coords.XEditBox)
equal(tonumber(coords.XEditBox:GetText()), 123.46, "blur preserves formatted number")
move(bar, layout, "CENTER", -0.00006103515625, -167.49989318848)
coords:Update(selection)
equal(coords.XEditBox:GetText(), "0", "drag/reopen path also suppresses float noise")
equal(SimpleSwingDB.layouts[layout].y, -167.5, "saved Y coordinate is cleaned")
coords:Update({parent = frame("Frame")}, "CENTER", -0.00006103515625, 10)
equal(coords.x, -0.00006103515625, "formatter only affects Simple Swing selection")

return tostring(checks) .. " assertions passed. Mocked timing, Edit Mode callbacks, colors, dimensions, layout lifecycle, persistence, and invalid data. Live game rendering/combat not tested."
