AddCSLuaFile()

SWEP.HoldType            = "slam"
SWEP.PrintName           = "Death Faker"

if CLIENT then
    SWEP.Slot            = 6

    SWEP.ViewModelFlip   = false
    SWEP.ViewModelFOV    = 54

    SWEP.EquipMenuData   = {
        type = "item_weapon",
        desc = "Fake your death!"
    }

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

SWEP.DMGType             = DMG_BULLET
SWEP.NextDMGChange       = 0

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    self:BodyDrop()
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
    self:BodyDrop()
end

local throwsound = Sound("physics/body/body_medium_impact_soft2.wav")
function SWEP:BodyDrop()
    if SERVER then
        Enable_TTT_DeathFaker(self:GetOwner(), self.DMGType)

        self:Remove()

        self:GetOwner():SetAnimation(PLAYER_ATTACK1)
    end

    self:EmitSound(throwsound)
    self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
end

function SWEP:Reload()
    local nextchange = self.NextDMGChange

    if CurTime() < nextchange then return false end

    local owner = self:GetOwner()

    if SERVER then
        if self.DMGType == DMG_BULLET then
            self.DMGType = DMG_FALL
            owner:PrintMessage(HUD_PRINTTALK, "Fall Damage selected.")
        elseif self.DMGType == DMG_FALL then
            self.DMGType = DMG_CRUSH
            owner:PrintMessage(HUD_PRINTTALK, "Crush Damage selected.")
        elseif self.DMGType == DMG_CRUSH then
            self.DMGType = DMG_BURN
            owner:PrintMessage(HUD_PRINTTALK, "Fire Damage selected.")
        elseif self.DMGType == DMG_BURN then
            self.DMGType = DMG_BLAST
            owner:PrintMessage(HUD_PRINTTALK, "Blast Damage selected.")
        elseif self.DMGType == DMG_BLAST then
            self.DMGType = DMG_BULLET
            owner:PrintMessage(HUD_PRINTTALK, "Bullet Damage selected.")
        end
    end

    self.NextDMGChange = CurTime() + 1

    return false
end

function SWEP:OnRemove()
    if CLIENT and IsValid(self:GetOwner()) and self:GetOwner() == LocalPlayer() and self:GetOwner():IsTerror() then
        RunConsoleCommand("lastinv")
    end
end

function SWEP:OnDrop()
    self:Remove()
end