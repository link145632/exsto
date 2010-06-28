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

function PLUGIN:IsJailed( ply )
	if ply.IsJailed then return true end
end

function PLUGIN:PlayerNoClip( ply )
	return !self:IsJailed( ply )
end

function PLUGIN:CanTool( ply, tr, tool )
	if tr.Entity.IsJailWall then return false end
	return !self:IsJailed( ply )
end

function PLUGIN:PlayerGiveSWEP( ply )
	return !self:IsJailed( ply )
end

function PLUGIN:PlayerSpawnProp( ply )
	return !self:IsJailed( ply )
end

function PLUGIN:PlayerSpawnSENT( ply )
	return !self:IsJailed( ply )
end

function PLUGIN:PlayerSpawnVehicle( ply )
	return !self:IsJailed( ply )
end

function PLUGIN:PlayerSpawn( ply )
	if self:IsJailed( ply ) then
		ply:SetPos( ply.JailedPos )
	end
end

function PLUGIN:PlayerDisconnected( ply )
	if self:IsJailed( ply ) then
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

function PLUGIN:Jail( owner, ply )

	if !ply.IsJailed then
	
		ply.Weapons = {}
	
		for k,v in pairs( ply:GetWeapons() ) do
			table.insert( ply.Weapons, v:GetClass() )
		end
		ply:StripWeapons()
	
		if ply:InVehicle() then
			local vehicle = ply:GetParent()
			ply:ExitVehicle()
			vehicle:Remove()
		end
			
		ply:SetMoveType( MOVETYPE_WALK )

		local pos = ply:GetPos()
		local ent, text
		ply.JailWalls = {}
		for _, item in ipairs( PLUGIN.WallPositions ) do
			ent = ents.Create( "prop_physics" )
				ent:SetModel( item.mdl )
				ent:SetPos( pos + item.pos )
				ent:SetAngles( item.ang )
				ent:Spawn()
				ent:GetPhysicsObject():EnableMotion( false )
				ent:SetMoveType( MOVETYPE_NONE )
				ent.IsJailWall = true
				table.insert( ply.JailWalls, ent )
		end
		
		text = ents.Create( "3dtext" )
			text:SetPos( pos + Vector( 35, 0, 60 ) )
			text:SetAngles( Angle( 0, 0, 0 ) )
			text:Spawn()
			text:SetPlaceObject( ply.JailWalls[1] )
			text:SetText( ply:Nick() .. "'s Jail" )
			text:SetScale( 0.1 )
			table.insert( ply.JailWalls, text )
		
		ply.IsJailed = true
		ply.JailedPos = pos
		return {
			Activator = owner,
			Player = ply,
			Wording = " has jailed ",
		}
		
	else
	
		if type( ply.JailWalls ) == "table" then
			for _, ent in ipairs( ply.JailWalls ) do
				if ent:IsValid() then ent:Remove() end
			end
		end
		
		if type( ply.Weapons ) == "table" then
			for k,v in pairs( ply.Weapons ) do
				ply:Give( tostring( v ) )
			end		
		end
	
		ply.IsJailed = false
		
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