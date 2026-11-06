local _, ns = ...

-- No combat-log dependency. PLAYER_SWING supplies the real cycle duration.
-- Once ready, hold full until another swing; never invent repeating swings.
local Timer = {}
Timer.__index = Timer

function ns.NewTimer()
    return setmetatable({}, Timer)
end

function Timer:Reset()
    self.started, self.duration = nil, nil
end

function Timer:Start(duration, now)
    if issecretvalue and (issecretvalue(duration) or issecretvalue(now)) then
        return false
    end
    if type(duration) ~= "number" or type(now) ~= "number"
        or duration ~= duration or duration <= 0 or duration == math.huge then
        return false
    end
    self.started, self.duration = now, duration
    return true
end

function Timer:Progress(now)
    if not self.started then
        return 1, false
    end
    if now >= self.started + self.duration then
        self:Reset()
        return 1, false
    end
    local fraction = (now - self.started) / self.duration
    return math.max(0, fraction), true
end
