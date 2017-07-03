AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

CreateConVar("ttt_df_allow_role_change", "0")
cvars.AddChangeCallback("ttt_df_allow_role_change", function(cvar, old, new)
    SetGlobalBool("deathfaker_allow_role_change", tobool(new))
end)

function SWEP:Equip(ply)
    self:SetRole(ply:GetRole())
end

-- Get a random weapon!
local WeaponTable
local WeaponTableCount = 0
local function GetRandomWeapon()
    if not WeaponTable then
        local weptable = {}
        local i = 0
        for k,v in ipairs(weapons.GetList()) do
            if (v.Kind == WEAPON_HEAVY or v.Kind == WEAPON_PISTOL) and v.Base ~= "weapon_ghost_base" then -- Don't use SpecDM Weapons. They're not translated.
                table.insert(weptable, v.ClassName)
                i = i + 1
            end
        end

        WeaponTable = weptable
        WeaponTableCount = i
    end

    return WeaponTable[math.random(1, WeaponTableCount)]
end

-- Remove ragdoll
local function RemoveRagdoll(ply)
    local rag = ply:GetNWEntity("fakerag", NULL)
    if IsValid(rag) then
        local ragpos = rag:GetPos()
        -- Explosion effect.
        local effect = EffectData()
        effect:SetStart(ragpos)
        effect:SetOrigin(ragpos)
        effect:SetScale(50)
        effect:SetRadius(50)
        effect:SetMagnitude(50)
        util.Effect("Explosion", effect, true, true)

        SafeRemoveEntity(rag)
    end
    ply:SetNWEntity("fakerag", nil)
end

local function RemoveRagdolls()
    for k,v in ipairs(player.GetAll()) do
        RemoveRagdoll(v)
    end
end

-- Define our function that is used to create the ragdoll.
function SWEP:FakeDeath(ply)
    if IsValid(ply:GetNWEntity("fakerag", NULL)) then RemoveRagdoll(ply) end

    local rag = CORPSE.Create(ply, ply, DamageInfo()) -- Dummy damage info.

    -- We have to modify some things on our ragdoll.
    CORPSE.SetCredits(rag, 0) -- No Credits

    local dmgtype = self:GetDMGType()
    rag.was_role = self:GetRole()
    rag.dmgtype = dmgtype -- Add our Damage Type.
    rag.was_headshot = dmgtype == DMG_BULLET -- Bullet Damage is always a headshot.
    rag.dmgwep = dmgtype == DMG_BULLET and GetRandomWeapon() or "" -- Give it a random weapon if needed

    rag:SetNWString("ragowner_sid", ply:SteamID()) -- Need this to "fix" something.

    ply:SetNWEntity("fakerag", rag)

    util.StartBleeding(rag, math.Rand(1, ply:GetMaxHealth()), 15) -- Make blood around the ragdoll
    hook.Call("FakedDeath", nil, ply, self:GetRole()) -- A hook that is useful for example for DamageLog Addons
end

hook.Add("TTTPrepareRound", "DeathFaker.RemoveRagdolls", RemoveRagdolls) -- Remove them on preparing
hook.Add("TTTEndRound", "DeathFaker.RemoveRagdolls", RemoveRagdolls) -- Remove them on end
hook.Add("TTTBeginRound", "DeathFaker.RemoveRagdolls", RemoveRagdolls) -- Remove them on beginning

hook.Add("DoPlayerDeath", "DeathFaker.RemoveRagdoll", RemoveRagdoll) -- Remove them on death
