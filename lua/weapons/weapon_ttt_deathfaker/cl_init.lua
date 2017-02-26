include("shared.lua")

SWEP.Icon          = "vgui/ttt/icon_foot"

SWEP.EquipMenuData = {
    type = "item_weapon",
    desc = "Fake your death!"
}

SWEP.UseHands      = true
SWEP.ViewModelFlip = false
SWEP.ViewModelFOV  = 54

function SWEP:OnRemove()
    local owner = self:GetOwner()
    if IsValid(owner) and owner == LocalPlayer() and owner:IsTerror() then
        RunConsoleCommand("lastinv")
    end
end


-- Show it correctly on tab.
local function DeathFakerScore(p)
    if IsValid(p:GetNWEntity("fakerag", NULL)) and p:IsTerror() then
        if p:GetNWBool("body_found", false) then
            return GROUP_FOUND
        else
            local lply = LocalPlayer()
            if lply:IsSpec() or lply:IsActiveTraitor() or ((GetRoundState() ~= ROUND_ACTIVE) and lply:IsTerror()) then
                return GROUP_NOTFOUND -- Maybe show them alive for traitors?
            else
                return GROUP_TERROR
            end
        end
    end
end
hook.Add("TTTScoreGroup", "DeathFaker.Group", DeathFakerScore)

-- Just a "fix" for the player avatar. TTT kills search.owner
hook.Add("TTTBodySearchEquipment", "DeathFaker.TTTBodySearchFix", function(search, eq)
    local rag = Entity(search.eidx)
    local plysid = rag:GetNWString("ragowner_sid", nil)

    if plysid then
        local ply = player.GetBySteamID(plysid)
        search.owner = ply
    end
end)


-- This is used to check if there is a custom addon that overrides ScoreGroup.
--If you're 100% sure that the TTTScoreGroup-Hook will be executed then you can remove that.

local SGroup -- Here we store ScoreGroup

hook.Add("OnGamemodeLoaded", "DeathFaker.GetScoreGroup", function()
    SGroup = ScoreGroup -- Store it.
end)

hook.Add("InitPostEntity", "DeathFaker.FixScoreGroup", function()
    if SGroup ~= ScoreGroup then -- Check ScoreGroup
        local tester -- var to hold the old function

        -- If so then check if the old function is called.
        for i = 1, 5 do
            local test1, test2 = debug.getupvalue(ScoreGroup, i) -- This doesn't work for every case. But it should be enough.

            if isfunction(test2) then
                tester = test2 -- If we got a function then pack it into our var.
                break
            end
        end

        if not isfunction(tester) then -- if the function is completly overwritten then we add a own hook
            local old_sgroup = ScoreGroup

            function ScoreGroup(p)
                local group = DeathFakerScore(p) -- Just using a unique name to make sure that the hook isn't called twice.

                if group then
                    return group
                end

                return old_sgroup(p)
            end

            hook.Remove("TTTScoreGroup", "DeathFaker.Group") -- Remove the old one to be sure that the function isn't called twice.
        end
    end
end)