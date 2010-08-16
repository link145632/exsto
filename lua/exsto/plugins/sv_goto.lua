-- Prefan Access Controller
-- Goto and Bring

-- FURST PLUGIN TO USE NEW COMMAND SYSTEM

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Bring Commands",
	ID = "goto-bring",
	Desc = "A plugin that allows bringing and goto player commands!",
	Owner = "Prefanatic",
} )

function PLUGIN:SendPlayer( ply, victim, force )

	local isvec = false
	if type( victim ) == "Vector" then isvec = true end

	if !isvec and !victim:IsInWorld() and !force then return false end
	
	local pos
	local forward
	if isvec then
		forward = 0
		pos = victim
	else
		forward = victim:EyeAngles().yaw
		pos = victim:GetPos()
	end
	
	local locations = {
		math.NormalizeAngle( forward - 180 ),
		math.NormalizeAngle( forward + 90 ),
		math.NormalizeAngle( forward - 90 ),
		forward,
	}

	local trace = {}
	trace.start = pos + Vector( 0, 0, 32 )
	trace.filter = { victim, ply }

	local TraceData
	for I = 1, #locations do
		trace.endpos = pos + Angle( 0, locations[ I ], 0 ):Forward() * 47
		TraceData = util.TraceEntity( trace, victim )
		if !TraceData.Hit then return TraceData.HitPos end
	end
	
	if force then
		return pos + Angle( 0, locations[ 1 ], 0 ):Forward() * 47
	end
	
end


function PLUGIN:Teleport( owner )
	local pos = self:SendPlayer( owner, owner:GetEyeTrace().HitPos )
	if !pos then exsto.Print( exsto_CHAT, owner, COLOR.NORM, "Not enough room to teleport to that ", COLOR.NAME, "position", COLOR.NORM, "!" ) return end
	
	owner:SetPos( pos )
end
PLUGIN:AddCommand( "teleport", {
	Call = PLUGIN.Teleport,
	Desc = "Allows users to teleport to their cursor.",
	Console = { "teleport", "tp" },
	Chat = { "!tp", "!teleport" },
	Args = {},
	Category = "Teleportation",
})

function PLUGIN:Send( owner, victim, to, force )
    victim = victim[1]  -- Victim seems to be returning a table, so just take the player out.
	if owner:GetMoveType() == MOVETYPE_NOCLIP then force = true end
	
	local pos = self:SendPlayer( victim, to, force )
	
	if !pos then exsto.Print( exsto_CHAT, owner, COLOR.NORM, "Not enough room to goto ", COLOR.NAME, to:Nick(), COLOR.NORM, "!" ) return end
	
	victim:SetPos( pos )
	
	return {
		COLOR.NAME, owner:Nick(), COLOR.NORM, " has sent ", COLOR.NAME, victim:Nick(), COLOR.NORM, " to ", COLOR.NAME, to:Nick(), COLOR.NORM, "!"
	}
	
end
PLUGIN:AddCommand( "send", {
	Call = PLUGIN.Send,
	Desc = "Allows users to send other players to places.",
	Console = { "send" },
	Chat = { "!send" },
	ReturnOrder = "Victim-To-Force",
	Args = { Victim = "PLAYER", To = "PLAYER", Force = "BOOLEAN" },
	Optional = { Force = false },
	Category = "Teleportation",
})

function PLUGIN:Goto( owner, ply, force )
	
	if owner:GetMoveType() == MOVETYPE_NOCLIP then force = true end
	
	local pos = self:SendPlayer( owner, ply, force )
	
	if !pos then exsto.Print( exsto_CHAT, owner, COLOR.NORM, "Not enough room to goto ", COLOR.NAME, ply:Nick(), COLOR.NORM, "!" ) return end
	
	owner:SetPos( pos )
	
	return {
		Activator = owner,
		Player = ply,
		Wording = " has gone to "
	}
	
end
PLUGIN:AddCommand( "goto", {
	Call = PLUGIN.Goto,
	Desc = "Allows users to teleport to a player.",
	Console = { "goto" },
	Chat = { "!goto" },
	ReturnOrder = "Victim-Force",
	Args = {Victim = "PLAYER", Force = "BOOLEAN"},
	Optional = { Force = false },
	Category = "Teleportation",
})
PLUGIN:RequestQuickmenuSlot( "goto", {
	Force = {
		{ Display = "Force Teleport", Data = true },
	},
} )

function PLUGIN:Bring( owner, ply, force )
		
	if owner:GetMoveType() == MOVETYPE_NOCLIP then force = true end
	
	local pos = self:SendPlayer( ply, owner, force )

	if !pos then return { owner, COLOR.NORM, "Not enough space to bring ", COLOR.NAME, ply:Nick() } end
	
	ply:SetPos( pos )
	return {
		Activator = owner,
		Player = ply,
		Wording = " has brought ",
		Secondary = " to himself"
	}
	
end
PLUGIN:AddCommand( "bring", {
	Call = PLUGIN.Bring,
	Desc = "Allows users to bring other players.",
	Console = { "bring" },
	Chat = { "!bring" },
	ReturnOrder = "Victim-Force",
	Args = {Victim = "PLAYER", Force = "BOOLEAN"},
	Optional = { Force = false },
	Category = "Teleportation",
})
PLUGIN:RequestQuickmenuSlot( "bring", {
	Force = {
		{ Display = "Force Teleport", Data = true },
	},
} )

PLUGIN:Register()