AddCSLuaFile()

SWEP.HoldType            = "slam"

if CLIENT then
    SWEP.PrintName       = "Death Faker"
    SWEP.Slot            = 6

    SWEP.ViewModelFlip   = false
    SWEP.ViewModelFOV    = 54

    SWEP.EquipMenuData   = {
        type  = "item_weapon",
        desc  = "Fake your death!"
    };

    SWEP.Icon            = "vgui/ttt/icon_foot"
end

SWEP.Base                = "weapon_tttbase"

SWEP.Kind                = WEAPON_EQUIP1
SWEP.CanBuy              = {ROLE_TRAITOR}
SWEP.LimitedStock        = true
SWEP.AllowDrop           = false

SWEP.Primary.ClipSize    = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic   = true
SWEP.Primary.Ammo        = "none"
SWEP.Primary.Delay       = 10

SWEP.UseHands            = true
SWEP.ViewModel           = "models/weapons/cstrike/c_c4.mdl"
SWEP.WorldModel          = "models/weapons/w_c4.mdl"

SWEP.dmgtype             = DMG_BULLET

local DeathFaker = {}
local throwsound = Sound("physics/body/body_medium_impact_soft2.wav")

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    self:BodyDrop()
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
    self:BodyDrop()
end

function SWEP:BodyDrop()
    if SERVER then
        DeathFaker:Enable(self.Owner, self.dmgtype)

        self:Remove()

        self.Owner:SetAnimation(PLAYER_ATTACK1)
    end

    self:EmitSound(throwsound)
    self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
end

function SWEP:Reload()
    if wait then return false end

    if SERVER then
        if self.dmgtype == DMG_BULLET then
            self.dmgtype = DMG_FALL
            self.Owner:PrintMessage(HUD_PRINTTALK, "Fall Damage selected.")
        elseif self.dmgtype == DMG_FALL then
            self.dmgtype = DMG_CRUSH
            self.Owner:PrintMessage(HUD_PRINTTALK, "Crush Damage selected.")
        elseif self.dmgtype == DMG_CRUSH then
            self.dmgtype = DMG_BURN
            self.Owner:PrintMessage(HUD_PRINTTALK, "Fire Damage selected.")
        elseif self.dmgtype == DMG_BURN then
            self.dmgtype = DMG_BLAST
            self.Owner:PrintMessage(HUD_PRINTTALK, "Blast Damage selected.")
        elseif self.dmgtype == DMG_BLAST then
            self.dmgtype = DMG_BULLET
            self.Owner:PrintMessage(HUD_PRINTTALK, "Bullet Damage selected.")
        end
    end

    wait = true

    timer.Simple(1, function()
        wait = false
    end)

    return false
end

function SWEP:OnRemove()
    if CLIENT and IsValid(self.Owner) and self.Owner == LocalPlayer() and self.Owner:IsTerror() then
        RunConsoleCommand("lastinv")
    end
end

function SWEP:OnDrop()
    self:Remove()
end

if SERVER then
    -- Get a random weapon!
    function DeathFaker:GetRandomWeapon()
        local weptable = {}
        for k,v in pairs(weapons.GetList()) do
            if v.Base == "weapon_tttbase" and (v.Kind == WEAPON_HEAVY or v.Kind == WEAPON_PISTOL) then
                table.insert(weptable, v.ClassName)
            end
        end

        return table.Random(weptable)
    end

    -- Create the fake ragdoll. Mainly copied from TTT.
    function DeathFaker:CreateFakeCorpse(ply, dmgtype, weapon)
        if not IsValid(ply) then return end

        local rag = ents.Create("prop_ragdoll")
        if not IsValid(rag) then return nil end

        rag:SetPos(ply:GetPos())
        rag:SetModel(ply:GetModel())
        rag:SetAngles(ply:GetAngles())
        rag:SetColor(ply:GetColor())

        rag:Spawn()
        rag:Activate()

        -- nonsolid to players, but can be picked up and shot
        rag:SetCollisionGroup(GetConVar("ttt_ragdoll_collide"):GetBool() and COLLISION_GROUP_WEAPON or COLLISION_GROUP_DEBRIS_TRIGGER)
        timer.Simple(1, function() if IsValid(rag) then rag:CollisionRulesChanged() end end)

        -- flag this ragdoll as being a player's
        rag.player_ragdoll = true
        rag.sid = ply:SteamID()

        rag.uqid = ply:UniqueID() -- backwards compatibility; use rag.sid instead

        rag:SetNWString("ragowner_sid", ply:SteamID()) -- Need this to "fix" something.

        -- network data
        CORPSE.SetPlayerNick(rag, ply)
        CORPSE.SetFound(rag, false)
        CORPSE.SetCredits(rag, 0)

        -- if someone searches this body they can find info on the victim and the
        -- death circumstances
        rag.equipment = ply:GetEquipmentItems()
        rag.was_role = ply:GetRole()
        rag.bomb_wire = ply.bomb_wire
        rag.dmgtype = dmgtype

        rag.dmgwep = weapon

        rag.was_headshot = dmgtype == DMG_BULLET -- Let it be a headshot if it is bullet damage.
        rag.time = CurTime()
        rag.kills = table.Copy(ply.kills)

        rag.killer_sample = nil -- No DNA.

        -- crime scene data
        rag.scene = nil -- No crime scene.

        -- position the bones
        local num = rag:GetPhysicsObjectCount() - 1
        local v = ply:GetVelocity()

        -- bullets have a lot of force, which feels better when shooting props,
        -- but makes bodies fly, so dampen that here
        if dmgtype == DMG_BULLET then
            v = v / 5
        end

        for i=0, num do
            local bone = rag:GetPhysicsObjectNum(i)
            if IsValid(bone) then
                local bp, ba = ply:GetBonePosition(rag:TranslatePhysBoneToBone(i))
                if bp and ba then
                    bone:SetPos(bp)
                    bone:SetAngles(ba)
                end

                -- not sure if this will work:
                bone:SetVelocity(v)
            end
        end

        return rag -- we'll be speccing this
    end

    function DeathFaker:Enable(ply, dmgtype)
        local weapon
        if dmgtype == DMG_BULLET then
            weapon = self:GetRandomWeapon() -- Bullet Damage -> We use a random weapon.
        end

        local rag = self:CreateFakeCorpse(ply, dmgtype, weapon) -- Create our ragdoll
        ply:SetNWEntity("fakerag", rag)

        util.StartBleeding(rag, math.Rand(1, ply:GetMaxHealth()), 15) -- Make blood around the ragdoll
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
    hook.Add("InitPostEntity", "DeathFaker.FixScoreGroup", function()
        if debug.getinfo(ScoreGroup).short_src != "gamemodes/terrortown/gamemode/vgui/sb_main.lua" then -- Check if this function is defined in another file.
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