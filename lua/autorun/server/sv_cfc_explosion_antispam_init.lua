CFCExplosionAntispam = CFCExplosionAntispam or {}

CFCExplosionAntispam.SETTINGS = {
    NEAR_DIST = CreateConVar( "cfc_explosion_antispam_near_dist", math.pow( 250, 2 ), FCVAR_NONE, "How close explosive damage events must be to get limited, to the power of 2 (default 250^2)", 1, 2^31 - 1 )
    MAX_NEAR = CreateConVar( "cfc_explosion_antispam_max_near", 10, FCVAR_NONE, "The max number of explosive damage events allowed in an area (default 10)", 1, 50000 )
    EXPLOSION_TIMEOUT = CreateConVar( "cfc_explosion_antispam_explosion_timeout", 1, FCVAR_NONE, "How long explosive damage events stay logged for, in seconds (default 1)", 0, 50000 )
    BARREL_TIMOUT = CreateConVar( "cfc_explosion_antispam_barrel_timeout", 2, FCVAR_NONE, "Base timeout duration for explosive props, overrides the standard explosion timeout (default 2)", 0, 50000 )
    BARREL_TIMOUT_OFFSET_MAX = CreateConVar( "cfc_explosion_antispam_barrel_timeout_offset_max", 1, FCVAR_NONE, "Adds random extra timeout duration (from 0 to this value) to explosive props so their explosions look more natural (default 1)", 0, 50000 )
    STOP_ALL_DAMAGE_TIMEOUT = CreateConVar( "cfc_explosion_antispam_stop_all_timeout", 10, FCVAR_NONE, "Default duration to forcefully stop all explosive damage if CFCExplosionAntispam.stopAllDamage() is called (default 10)", 0, 50000 )
}

local stopAllDamage = false
local recentDamagePositions = {}
local uniqueKey = 0

-- Prevents all explosive damage events from dealing damage for a time. Useful for if the server is lagging heavily.
function CFCExplosionAntispam.stopAllDamage( duration )
    stopAllDamage = true
    duration = duration or CFCExplosionAntispam.SETTINGS.STOP_ALL_DAMAGE_TIMEOUT:GetFloat()

    timer.Simple( duration, function() stopAllDamage = false end )

    for _, ent in pairs( ents.GetAll() ) do
        if IsValid( ent ) then
            ent:Extinguish()
        end
    end
end

local function validateExplosion( ent, dmg )
    local pos = dmg:GetDamagePosition()

    if not pos then return end
    if not dmg:GetAttacker() then return end
    if pos == Vector( 0, 0, 0 ) then
        pos = ent:GetPos()
    end

    local isExplosion = dmg:IsDamageType( DMG_BLAST ) or dmg:IsDamageType( DMG_BLAST_SURFACE )
    local isDirectBurn = dmg:IsDamageType( DMG_BURN ) and dmg:IsDamageType( DMG_DIRECT )

    if not ( isExplosion or isDirectBurn ) then return end

    return pos, isDirectBurn
end

local function restrictDamage( ent, pos, isDirectBurn )
    local nearCount = 0
    local clearTime = CFCExplosionAntispam.SETTINGS.EXPLOSION_TIMEOUT:GetFloat()

    for _, oldPos in pairs( recentDamagePositions ) do
        if oldPos:DistToSqr( pos ) <= CFCExplosionAntispam.SETTINGS.NEAR_DIST:GetFloat() then
            nearCount = nearCount + 1
        end

        if nearCount >= CFCExplosionAntispam.SETTINGS.MAX_NEAR:GetInt() then
            return true
        elseif isDirectBurn then
            clearTime = CFCExplosionAntispam.SETTINGS.BARREL_TIMOUT:GetFloat() + math.Rand( 0, CFCExplosionAntispam.SETTINGS.BARREL_TIMOUT_OFFSET_MAX:GetFloat() )
            timer.Simple( clearTime, function()
                if not IsValid( ent ) then return end

                ent:TakeDamage( 100, nil, nil )
            end )
        end
    end

    return clearTime
end

local function logDamage( pos, clearTime )
    uniqueKey = uniqueKey + 1
    local tempKey = uniqueKey
    recentDamagePositions[tempKey] = pos
    timer.Simple( clearTime, function() recentDamagePositions[tempKey] = nil end )
end

hook.Add( "EntityTakeDamage", "CFC_ExplosionAntispam_RestrictDamage", function( ent, dmg )
    if not IsValid( ent ) then return end
    if ent:IsPlayer() then return end

    local pos, isDirectBurn = validateExplosion( ent, dmg )
    if not pos then return end

    if stopAllDamage then return true end

    local clearTime = restrictDamage( ent, pos, isDirectBurn )
    if clearTime == true then return true end

    logDamage( pos, clearTime )
end )

hook.Add( "z_anticrash_LagEvent_FoundOffender", "CFC_ExplosionAntispam_StopAllDamage", function() CFCExplosionAntispam.stopAllDamage() end )
