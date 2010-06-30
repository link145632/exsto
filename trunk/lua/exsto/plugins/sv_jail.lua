-- Prefan Access Controller
-- Jail

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Jail",
	ID = "jail",
	Desc = "A plugin that adds the !jail command.",
	Owner = "Prefanatic",
} )

function PLUGIN:Init()

	self.Model1 = Model( "models/props_c17/fence01b.mdl" )
	self.Model2 = Model( "models/props_c17/fence02b.mdl" )
	self.WallPositions = {
		{ pos = Vector( 35, 0, 60 ), ang = Angle( 0, 0, 0 ), mdl = self.Model2 },
		{ pos = Vector( -35, 0, 60 ), ang = Angle( 0, 0, 0 ), mdl = self.Model2 },
		{ pos = Vector( 0, 35, 60 ), ang = Angle( 0, 90, 0 ), mdl = self.Model2 },
		{ pos = Vector( 0, -35, 60 ), ang = Angle( 0, 90, 0 ), mdl = self.Model2 },
		{ pos = Vector( 0, 0, 110 ), ang = Angle( 90, 0, 0 ), mdl = self.Model1 },
		{ pos = Vector( 0, 0, -5 ), ang = Angle( 90, 0, 0 ), mdl = self.Model1 },
	}
	
	self.JailedLeavers = {}
	
end

function PLUGIN:PlayerNoClip( ply )
	return !ply:Jailed()
end

function PLUGIN:CanTool( ply, tr, tool )
	if tr.Entity.IsJailWall then return false end
	return !ply:Jailed()
end

function PLUGIN:PlayerGiveSWEP( ply )
	return !ply:Jailed()
end

function PLUGIN:PlayerSpawnProp( ply )
	return !ply:Jailed()
end

function PLUGIN:PlayerSpawnSENT( ply )
	return !ply:Jailed()
end

function PLUGIN:PlayerSpawnVehicle( ply )
	return !ply:Jailed()
end

function PLUGIN:PlayerSpawnNPC( ply )
	return !ply:Jailed()
end

function PLUGIN:PlayerSpawnEffect( ply )
	return !ply:Jailed()
end

function PLUGIN:PlayerSpawnRagdoll( ply )
	return !ply:Jailed()
end

function PLUGIN:PlayerUse( ply )
	return !ply:Jailed()
end

function PLUGIN:PlayerSpawn( ply )
	if ply:Jailed() then
		ply:MoveToJail()
		timer.Create( "stripSweps"..ply:EntIndex(), 0.1, 1, _R.Player.StripWeapons, ply )
	end
end

function PLUGIN:PlayerDisconnected( ply )
	if ply:Jailed() then
		table.insert( self.JailedLeavers, { SteamID = ply:SteamID(), JailPos = ply.JailedPos, JailWalls = ply.JailWalls, OldWeapons = ply.Weapons } )
	end
end

function PLUGIN:PlayerInitialSpawn( ply )
	PrintTable( self.JailedLeavers )
	for _, obj in ipairs( self.JailedLeavers ) do
		if ply:SteamID() == obj.SteamID then
			ply.IsJailed = true
			ply:SetPos( obj.JailPos )
			
			ply.Weapons = obj.OldWeapons
			ply:StripWeapons()
			
			ply.JailWalls = obj.JailWalls
			
			table.remove( self.JailedLeavers, _ )
			break
		end
	end
end

function PLUGIN:PhysgunPickup( ply, ent )
	if ent.IsJailWall then return false end
end

local removeoncommand = function( ply, callargs )
	if callargs[1]:Jailed() then
		callargs[1]:RemoveJail()
	end
end

function _R.Player:Jailed()
	return self.IsJailed
end

function _R.Player:MoveToJail()
	if self.JailedPos then
		self:SetPos( self.JailedPos )
	end
end

function _R.Player:JailStrip()
	self.Weapons = {}
	for k,v in pairs( self:GetWeapons() ) do
		table.insert( self.Weapons, v:GetClass() )
	end
	self:StripWeapons()
end

function _R.Player:JailReturn()
	if type( self.Weapons ) == "table" then
		for k,v in pairs( self.Weapons ) do
			self:Give( tostring( v ) )
		end		
	end
end

function _R.Player:CreateJail()
	self:JailStrip()

	if self:InVehicle() then
		local vehicle = self:GetParent()
		self:ExitVehicle()
		vehicle:Remove()
	end
		
	self:SetMoveType( MOVETYPE_WALK )

	local pos = self:GetPos()
	local ent, text
	self.JailWalls = {}
	for _, item in ipairs( PLUGIN.WallPositions ) do
		ent = ents.Create( "prop_physics" )
			ent:SetModel( item.mdl )
			ent:SetPos( pos + item.pos )
			ent:SetAngles( item.ang )
			ent:Spawn()
			ent:GetPhysicsObject():EnableMotion( false )
			ent:SetMoveType( MOVETYPE_NONE )
			ent.IsJailWall = true
			table.insert( self.JailWalls, ent )
	end
	
	text = ents.Create( "3dtext" )
		text:SetPos( pos + Vector( 35, 0, 60 ) )
		text:SetAngles( Angle( 0, 0, 0 ) )
		text:Spawn()
		text:SetPlaceObject( self.JailWalls[1] )
		text:SetText( self:Nick() .. "'s Jail" )
		text:SetScale( 0.1 )
		table.insert( self.JailWalls, text )
	
	self.IsJailed = true
	self.JailedPos = pos
	
end

function _R.Player:RemoveJail()
	if type( self.JailWalls ) == "table" then
		for _, ent in ipairs( self.JailWalls ) do
			if ent:IsValid() then ent:Remove() end
		end
	end
	
	self:JailReturn()

	self.IsJailed = false
end
	
function PLUGIN:Jail( owner, ply )

	if !ply.IsJailed then
		ply:CreateJail()
		return {
			Activator = owner,
			Player = ply,
			Wording = " has jailed ",
		}
	else
		ply:RemoveJail()
		return {
			Activator = owner,
			Player = ply,
			Wording = " has un-jailed ",
		}
	end
	
end
PLUGIN:AddCommand( "jail", {
	Call = PLUGIN.Jail,
	Desc = "Jails a player.",
	FlagDesc = "Allows users to put other users in jail.",
	Console = { "jail", "unjail" },
	Chat = { "!jail", "!unjail" },
	ReturnOrder = "Victim",
	Args = {Victim = "PLAYER"},
})

PLUGIN:Register()