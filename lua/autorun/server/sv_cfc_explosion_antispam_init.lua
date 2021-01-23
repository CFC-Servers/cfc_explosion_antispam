CFC_ExplosionAntispam = CFC_ExplosionAntispam or {}

CFC_ExplosionAntispam.NEAR_DIST = math.pow( 250, 2 ) --How close explosive damage events have to be for limitations to apply
CFC_ExplosionAntispam.MAX_NEAR = 10 --The max number of explosive damage events allowed in an area
CFC_ExplosionAntispam.EXPLOSION_TIMEOUT = 1 --How long explosive damage events stay logged for
CFC_ExplosionAntispam.BARREL_TIMOUT = 2 --Base timeout duration for explosive barrels
CFC_ExplosionAntispam.BARREL_TIMOUT_OFFSET_MAX = 1 --Adds random extra timeout duration from 0 to this value to barrels to look more natural
CFC_ExplosionAntispam.STOP_ALL_DAMAGE_TIMEOUT = 10 --Default time that stopAllDamage() lasts for

local stopAllDamage = false
local recentDamagePositions = {}
local uniqueKey = 0

--Prevents all explosive damage events from dealing damage for a time. Useful for if the server is lagging heavily.
function CFC_ExplosionAntispam.stopAllDamage( duration )
    stopAllDamage = true
    duration = duration or CFC_ExplosionAntispam.STOP_ALL_DAMAGE_TIMEOUT

    timer.Simple( duration, function() stopAllDamage = false end )

    for _, ent in pairs( ents.GetAll() ) do
        if IsValid( ent ) then
            ent:Extinguish()
        end
    end
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

    local pos = dmg:GetDamagePosition()

    if not pos then return end
    if not dmg:GetAttacker() then return end
    if pos == Vector( 0, 0, 0 ) then
        pos = ent:GetPos()
    end

    local isExplosion = dmg:IsDamageType( DMG_BLAST ) or dmg:IsDamageType( DMG_BLAST_SURFACE )
    local isDirectBurn = dmg:IsDamageType( DMG_BURN ) and dmg:IsDamageType( DMG_DIRECT )

    if not isExplosion and not isDirectBurn then return end

    local nearCount = 0
    local clearTime = CFC_ExplosionAntispam.EXPLOSION_TIMEOUT

    for _, oldPos in pairs( recentDamagePositions ) do
        if oldPos:DistToSqr( pos ) <= CFC_ExplosionAntispam.NEAR_DIST then
            nearCount = nearCount + 1
        end

        if nearCount >= CFC_ExplosionAntispam.MAX_NEAR then
            return true
        elseif isDirectBurn then
            clearTime = CFC_ExplosionAntispam.BARREL_TIMOUT + math.Rand( 0, CFC_ExplosionAntispam.BARREL_TIMOUT_OFFSET_MAX )
            timer.Simple( clearTime, function()
                if not IsValid( ent ) then return end

                ent:TakeDamage( 100, nil, nil )
            end )
        end
    end

    logDamage( pos, clearTime )
end )

hook.Add( "z_anticrash_LagEvent_FoundOffender", "CFC_ExplosionAntispam_StopAllDamage", function() CFC_ExplosionAntispam.stopAllDamage() end )
