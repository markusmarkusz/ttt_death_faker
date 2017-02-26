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
    self.BaseClass.SetupDataTables(self)
end

function SWEP:Initialize()
    self:SetDMGType(DMG_BULLET)
    self:SetNextDMGChange(0)
    self:SetLastIndex(0)
    self.BaseClass.Initialize(self)
end

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