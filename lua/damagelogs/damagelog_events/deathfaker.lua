if SERVER then
    Damagelog:EventHook("FakedDeath")
else
    Damagelog:AddFilter("Show Fake Deaths", DAMAGELOG_FILTER_BOOL, true)
    Damagelog:AddColor("Fake Death", Color(63, 79, 127))
end

local event = {}

event.Type = "DF"

function event:FakedDeath(ply, role)
    self.CallEvent({
        [1] = (IsValid(ply) and ply:Nick() or "<Disconnected>"),
        [2] = role,
        [3] = (IsValid(ply) and ply:SteamID() or "<Disconnected>")
    })
end

function event:ToString(data)
    local msg = "%s [%s] has faked his death by placed a fake corpse."
    return Format(msg, data[1], Damagelog:StrRole(data[2]))
end

function event:IsAllowed(tbl)
    return Damagelog.filter_settings["Show Fake Deaths"]
end

function event:Highlight(line, tbl, text)
    return table.HasValue(Damagelog.Highlighted, tbl[1])
end

function event:GetColor(tbl)
    return Damagelog:GetColor("Fake Death")
end

function event:RightClick(line, tbl, text)
    line:ShowTooLong(true)
    line:ShowCopy(true, {tbl[1], tbl[3]})
end

Damagelog:AddEvent(event)