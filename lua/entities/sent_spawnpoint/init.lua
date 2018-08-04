AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

-- Chat command config
spawnPointCommands = {
    ["unlinkSpawnPoint"] = { 
        ["!unlinkspawn"] = true, 
        ["!unlinkspawnpoint"] = true 
    },
    ["unlinkThisSpawnPoint"] = { 
        ["!unlinkthis"] = true 
    }
}

-- Helper Functions
function createPlayerList( players )
    local playerList = {}
    for _, player in pairs( players ) do
        playerList[player] = true
    end

    return playerList
end

function linkPlayerToSpawnPoint( player, spawnPoint )
    player.LinkedSpawnPoint = spawnPoint
    spawnPoint.LinkedPlayers[player] = "Linked"
end

function unlinkPlayerFromSpawnPoint( player, spawnPoint )
    player.LinkedSpawnPoint = nil
    spawnPoint.LinkedPlayers[player] = nil
end

function unlinkAllPlayersFromSpawnPoint( spawnPoint, excludedPlayers )
    if not IsValid( spawnPoint ) then return end

    local linkedPlayers = spawnPoint.LinkedPlayers
    local spawnPointOwner = spawnPoint:CPPIGetOwner()
    
    for player, _ in pairs( linkedPlayers ) do
        local playerIsExcluded = excludedPlayers[player]
        local playerOwnsSpawnPoint = spawnPointOwner == player          
    
        if not playerIsExcluded and not playerOwnsSpawnPoint then
            unlinkPlayerFromSpawnPoint( player, spawnPoint )
            player:PrintMessage(4, "You've been unlinked from a Spawn Point!")
        end
    end
end

-- Chat commands
function unlinkSpawnPointCommand( player, text, _, _ )
    local text = string.lower( text ):gsub("%s+", "")
    local unlinkSpawnCommands = spawnPointCommands.unlinkSpawnPoint

    if not unlinkSpawnCommands[text] then return end

    local linkedSpawnPoint = player.LinkedSpawnPoint
    unlinkPlayerFromSpawnPoint( player, linkedSpawnPoint )
    player:PrintMessage(4, "Spawn Point unlinked")
end
hook.Remove( "PlayerSay", "UnlinkSpawnPointCommand" )
hook.Add( "PlayerSay", "UnlinkSpawnPointCommand", unlinkSpawnPointCommand )

function unlinkThisSpawnPointCommand( player, text, _, _ )
    local text = string.lower( text ):gsub("%s+", "")
    local unlinkThisSpawnCommands = spawnPointCommands.unlinkThisSpawnPoint

    if not unlinkThisSpawnCommands[text] then return end

    local targetedEntity = player:GetEyeTraceNoCursor().Entity
    if not targetedEntity or not targedtedEntity:IsValid() then return end

    local isSpawnPoint = targetedEntity:GetClass() == "sent_spawnpoint"
    if not isSpawnPoint then 
        player:PrintMessage(4, "You must be looking at a Spawn Point to use this command")
        return
    end
    
    local spawnPoint = targetedEntity
    local spawnPointOwner = spawnPoint:CPPIGetOwner()
    local playerOwnsSpawnPoint = spawnPointOwner == player
    local playerIsAdmin = player:IsAdmin()

    if playerOwnsSpawnPoint or playerIsAdmin then
        local excludedPlayers = createPlayerList( { spawnPointOwner } )
        unlinkAllPlayersFromSpawnPoint(spawnPoint, excludedPlayers)
        player:PrintMessage(4, "All players except the owner have been unlinked from this Spawn Point")
    else
        player:PrintMessage(4, "That's not yours! You can't unlink others from this Spawn Point")
    end
end

hook.Remove( "PlayerSay", "UnlinkThisSpawnPointCommand" )
hook.Add( "PlayerSay", "UnlinkThisSpawnPointCommand", unlinkThisSpawnPointCommand )


local function unlinkPlayerOnDisconnect( player )
    local linkedSpawnPoint = player.linkedSpawnPoint
    if not linkedSpawnPoint then return end

    unlinkPlayerFromSpawnPoint( player, linkedSpawnPoint )
end
hook.Remove( "PlayerDisconnected", "UnlinkPlayerOnDisconnect" )
hook.Add( "PlayerDisconnected", "UnlinkPlayerOnDisconnect", unlinkPlayerOnDisconnect )

-- Entity Methods
function ENT:SpawnFunction( ply, tr )
    if not tr.Hit then return end
    local SpawnPos = tr.HitPos
    local ent = ents.Create( "sent_spawnpoint" )
    ent:SetPos( SpawnPos )
    ent:Spawn()
    ent:Activate()

    return ent
end

function ENT:Initialize()
    local effectdata1 = EffectData()
    effectdata1:SetOrigin( self.Entity:GetPos() )
    util.Effect( "spawnpoint_start", effectdata1, true, true )

    self.Entity:SetModel("models/props_combine/combine_mine01.mdl")
    self.Entity:PhysicsInit( SOLID_VPHYSICS )
    self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
    self.Entity:SetSolid( SOLID_VPHYSICS )
    self:SetUseType( SIMPLE_USE )
    self.Entity.LinkedPlayers = {}

    local phys = self.Entity:GetPhysicsObject()
    if not phys:IsValid() then return end
    
    phys:Wake()
    phys:EnableDrag(true)
    phys:EnableMotion(false)
end

function ENT:OnRemove()
    local effectdata1 = EffectData()
    effectdata1:SetOrigin( self.Entity:GetPos() )
    util.Effect( "spawnpoint_start", effectdata1, true, true )

    unlinkAllPlayersFromSpawnPoint(self.Entity, {})
end

function ENT:Use( player, caller )
    local msg = ""
    if player.LinkedSpawnPoint and player.LinkedSpawnPoint == self.Entity then
        unlinkPlayerFromSpawnPoint( player, self.Entity )
        msg = "Spawn Point unlinked"
    else
        linkPlayerToSpawnPoint( player, self.Entity )
        msg = "Spawn Point set. Say !unlinkspawn to unlink"
    end

    player:PrintMessage(4, msg)
end

local function SpawnPointHook( player )
    local spawnPoint = player.LinkedSpawnPoint
    if not spawnPoint or not spawnPoint:IsValid() then return end
    
    local spawnPos = spawnPoint:GetPos() + Vector(0,0,16)
    player:SetPos(spawnPos)
end
hook.Remove("PlayerSpawn", "SpawnPointHook")
hook.Add("PlayerSpawn", "SpawnPointHook", SpawnPointHook)

-- Stubs from here on

function ENT:Think() end

function ENT:OnTakeDamage( dmginfo ) end

function ENT:PhysicsUpdate() end

function ENT:PhysicsCollide( data, physobj ) end
