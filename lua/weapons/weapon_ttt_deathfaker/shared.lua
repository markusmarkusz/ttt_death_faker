SWEP.Base                = "weapon_tttbase"

SWEP.PrintName           = "Death Faker"
SWEP.Slot                = 6

SWEP.Primary.ClipSize    = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic   = true
SWEP.Primary.Ammo        = "none"
SWEP.Primary.Delay       = 10

SWEP.HoldType            = "slam"
SWEP.ViewModel           = "models/weapons/cstrike/c_c4.mdl"
SWEP.WorldModel          = "models/weapons/w_c4.mdl"

SWEP.Kind                = WEAPON_EQUIP1
SWEP.CanBuy              = {ROLE_TRAITOR}
SWEP.LimitedStock        = true

-- Networking some stuff
function SWEP:SetupDataTables()
    self:NetworkVar("Float", 0, "NextDMGChange")
    self:NetworkVar("Int", 0, "DMGType")
    self:NetworkVar("Int", 1, "LastIndex")

    self:NetworkVar("Int", 2, "Role")
    self:NetworkVar("Int", 3, "LastRolesIndex")

    self.BaseClass.SetupDataTables(self)
end

function SWEP:Initialize()
    self:SetDMGType(DMG_BULLET)
    self:SetNextDMGChange(0)
    self:SetLastIndex(0)

    self:SetLastRolesIndex(0)
    self:SetRole(ROLE_INNOCENT)

    self.BaseClass.Initialize(self)
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    self:BodyDrop()
end

local Roles = {
    {ROLE_INNOCENT, "innocent", Color(20, 250, 20)}, 
    {ROLE_TRAITOR, "traitor", Color(250, 20, 20)}
}
local red = Color(200, 20, 20)
local white = Color(250, 250, 250)
function SWEP:SecondaryAttack()
    if not GetGlobalBool("deathfaker_allow_role_change") then
        self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
        self:BodyDrop()
        return
    end

    self:SetNextSecondaryFire(CurTime() + 1)

    local owner = self:GetOwner()
    local index, tab = next(Roles, self:GetLastRolesIndex())

    if index == nil then
        index, tab = next(Roles, 0)
    end

    self:SetLastRolesIndex(index)
    self:SetRole(tab[1])

    if CLIENT then
        chat.AddText(red, "[Death Faker] ", white, "Your body's role will be ", tab[3], LANG.GetTranslation(tab[2]))
    end
end

local throwsound = Sound("physics/body/body_medium_impact_soft2.wav")
function SWEP:BodyDrop()
    if SERVER then
        local owner = self:GetOwner()
        self:FakeDeath(owner)

        self:Remove()

        owner:SetAnimation(PLAYER_ATTACK1)
    end

    self:EmitSound(throwsound)
    self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
end

local DMGTypes = {
    {DMG_FALL, "Fall Damage selected."},
    {DMG_CRUSH, "Crush Damage selected."},
    {DMG_BURN, "Fire Damage selected."},
    {DMG_BLAST, "Blast Damage selected."},
    {DMG_BULLET, "Bullet Damage selected."}
}

function SWEP:Reload()
    if CurTime() < self:GetNextDMGChange() then return false end

    if SERVER then
        local owner = self:GetOwner()
        local index, tab = next(DMGTypes, self:GetLastIndex())

        if index == nil then
            index, tab = next(DMGTypes, 0)
        end

        self:SetLastIndex(index)
        self:SetDMGType(tab[1])
        owner:PrintMessage(HUD_PRINTTALK, tab[2])
    end

    self:SetNextDMGChange(CurTime() + 1)

    return false
end