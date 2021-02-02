CFCExplosionAntispam = CFCExplosionAntispam or {}

CFCExplosionAntispam.SETTINGS = {
    NEAR_DIST = math.pow( 250, 2 ) -- How close explosive damage events have to be for limitations to apply
    MAX_NEAR = 10 -- The max number of explosive damage events allowed in an area
    EXPLOSION_TIMEOUT = 1 -- How long explosive damage events stay logged for
    BARREL_TIMOUT = 2 -- Base timeout duration for explosive barrels
    BARREL_TIMOUT_OFFSET_MAX = 1 -- Adds random extra timeout duration from 0 to this value to barrels to look more natural
    STOP_ALL_DAMAGE_TIMEOUT = 10 -- Default time that stopAllDamage() lasts for
}

local stopAllDamage = false
local recentDamagePositions = {}
local uniqueKey = 0

-- Prevents all explosive damage events from dealing damage for a time. Useful for if the server is lagging heavily.
function CFCExplosionAntispam.stopAllDamage( duration )
    stopAllDamage = true
    duration = duration or CFCExplosionAntispam.SETTINGS.STOP_ALL_DAMAGE_TIMEOUT

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
    local clearTime = CFCExplosionAntispam.SETTINGS.EXPLOSION_TIMEOUT

    for _, oldPos in pairs( recentDamagePositions ) do
        if oldPos:DistToSqr( pos ) <= CFCExplosionAntispam.SETTINGS.NEAR_DIST then
            nearCount = nearCount + 1
        end

        if nearCount >= CFCExplosionAntispam.SETTINGS.MAX_NEAR then
            return true
        elseif isDirectBurn then
            clearTime = CFCExplosionAntispam.SETTINGS.BARREL_TIMOUT + math.Rand( 0, CFCExplosionAntispam.SETTINGS.BARREL_TIMOUT_OFFSET_MAX )
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
    if stopAllDamage then return true end
    if not IsValid( ent ) then return end
    if ent:IsPlayer() then return end

    local pos, isDirectBurn = validateExplosion(  )
    if not pos then return end

    local clearTime = restrictDamage( ent, pos, isDirectBurn )
    if clearTime == true then return true end

    logDamage( pos, clearTime )
end )

hook.Add( "z_anticrash_LagEvent_FoundOffender", "CFC_ExplosionAntispam_StopAllDamage", function() CFCExplosionAntispam.stopAllDamage() end )
