local DeathFaker = {}

if SERVER then
    -- Get a random weapon!
    function DeathFaker:GetRandomWeapon()
        local weptable = {}
        for k,v in pairs(weapons.GetList()) do
            if not "weapon_ghost_base" and (v.Kind == WEAPON_HEAVY or v.Kind == WEAPON_PISTOL) then -- Don't use SpecDM Weapons. They're not translated.
                table.insert(weptable, v.ClassName)
            end
        end

        return table.Random(weptable)
    end

    -- Remove ragdoll
    function DeathFaker.RemoveRagdoll(ply)
        local rag = ply:GetNWEntity("fakerag", nil)
        if IsValid(rag) then
            -- Explosion effect.
            local effect = EffectData()
            effect:SetStart(rag:GetPos())
            effect:SetOrigin(rag:GetPos())
            effect:SetScale(50)
            effect:SetRadius(50)
            effect:SetMagnitude(50)
            util.Effect("Explosion", effect, true, true)

            SafeRemoveEntity(rag)
        end
        ply:SetNWEntity("fakerag", nil)
    end

    function DeathFaker.RemoveRagdolls()
        for k,v in pairs(player.GetAll()) do
            DeathFaker.RemoveRagdoll(v)
        end
    end

    hook.Add("TTTPrepareRound", "DeathFaker.RemoveRagdolls", DeathFaker.RemoveRagdolls) -- Remove them on preparing
    hook.Add("TTTEndRound", "DeathFaker.RemoveRagdolls", DeathFaker.RemoveRagdolls) -- Remove them on end
    hook.Add("TTTBeginRound", "DeathFaker.RemoveRagdolls", DeathFaker.RemoveRagdolls) -- Remove them on beginning

    -- Remove them on death
    hook.Add("DoPlayerDeath", "DeathFaker.RemoveRagdoll", DeathFaker.RemoveRagdoll)

    -- Define our function that is used to create the ragdoll.
    function Enable_TTT_DeathFaker(ply, dmgtype) -- Give it a unique name to prevent collisions with other addons. (I'm sure that nobody uses this name.)
        local rag = CORPSE.Create(ply, ply, DamageInfo()) -- Dummy damage info.

        -- We have to modify some things on our ragdoll.
        CORPSE.SetCredits(rag, 0)

        rag.dmgtype = dmgtype -- Add our Damage Type.
        rag.was_headshot = dmgtype == DMG_BULLET -- Bullet Damage is always a headshot.
        rag.wep = dmgtype == DMG_BULLET and DeathFaker:GetRandomWeapon() or "" -- Give it a random weapon if needed

        rag:SetNWString("ragowner_sid", ply:SteamID()) -- Need this to "fix" something.

        ply:SetNWEntity("fakerag", rag)

        util.StartBleeding(rag, math.Rand(1, ply:GetMaxHealth()), 15) -- Make blood around the ragdoll
    end
else
    -- Show it correctly on tab.
    function DeathFaker.ScoreGroup(p)
        local test = p:GetNWEntity("fakerag", false)
        if IsValid(test) and p:IsTerror() then
            if p:GetNWBool("body_found", false) then
                return GROUP_FOUND
            else
                if LocalPlayer():IsSpec() or LocalPlayer():IsActiveTraitor() or ((GAMEMODE.round_state != ROUND_ACTIVE) and LocalPlayer():IsTerror()) then
                    return GROUP_NOTFOUND
                else
                    return GROUP_TERROR
                end
            end
        end
    end
    hook.Add("TTTScoreGroup", "DeathFaker.Group", DeathFaker.ScoreGroup)

    -- Just a "fix" for the player avatar. TTT kills search.owner 
    hook.Add("TTTBodySearchEquipment", "DeathFaker.TTTBodySearchFix", function(search, eq)
        local rag = Entity(search.eidx)
        local plysid = rag:GetNWString("ragowner_sid", nil)

        if plysid then
            local ply = player.GetBySteamID(plysid)
            search.owner = ply
        end
    end)
end


--[[
This is used to check if there is a custom addon that overrides ScoreGroup.
If you're 100% sure that the TTTScoreGroup-Hook will be executed then you can remove that.
I know that this code is shit.
]]

if CLIENT then
    local SGroup -- Here we store ScoreGroup

    hook.Add("OnGamemodeLoaded", "DeathFaker.GetScoreGroup", function()
        SGroup = ScoreGroup -- Store it.
    end)

    hook.Add("InitPostEntity", "DeathFaker.FixScoreGroup", function()
        if SGroup != ScoreGroup then -- Check ScoreGroup
            local tester -- var to hold the old function

            -- If so then check if the old function is called.
            for i = 1, 5 do
                local test1, test2 = debug.getupvalue(ScoreGroup, i) -- This doesn't work for every case. But it should be enough.

                if test1 then
                    tester = test2 -- If we got a function then pack it into our var.
                    break
                end
            end

            if not tester then -- if the function is completly overwritten then we add a own hook
                local old_sgroup = ScoreGroup

                function ScoreGroup(p)
                    local group = hook.Call("DeathFakerScoreGroup", nil, p) -- Just using a unique name to make sure that the hook isn't called twice.

                    if group then
                        return group
                    end

                    return old_sgroup(p)
                end

                hook.Add("DeathFakerScoreGroup", "DeathFaker.Group", DeathFaker.ScoreGroup) -- change the event name
                hook.Remove("TTTScoreGroup", "DeathFaker.Group") -- Remove the old one to be sure that the function isn't called twice.
            end
        end
    end)
end