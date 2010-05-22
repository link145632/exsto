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

if CLIENT then return end

function PLUGIN.SendPlayer( ply, victim, force )
	if !victim:IsInWorld() and !force then return false end
	
	local forward = victim:EyeAngles().yaw
	
	-- Create our trace
	local trace = {}
	trace.start = victim:GetPos()
	trace.filter = { ply, victim }
	trace.endpos = victim:GetPos() + Angle( 0, forward, 0 ):Forward() * 47
	
	local ent = util.TraceEntity( trace, ply )
	
	if !ent.HitPos then return victim:GetPos() + Angle( 0, forward, 0 ):Forward() * 47 end
	return ent.HitPos
end

function PLUGIN.Send( owner, victim, to )
	
	local force = false
	if owner:GetMoveType() == MOVETYPE_NOCLIP then force = true end
	
	local pos = PLUGIN.SendPlayer( victim, to, force )
	
	if !pos then exsto.Print( exsto_CHAT, owner, COLOR.NORM, "Not enough room to goto ", COLOR.NAME, ply , COLOR.NORM, "!" ) return end
	
	victim:SetPos( pos )
	
	return {
		COLOR.NAME, owner:Nick(), COLOR.NORM, " has sent ", COLOR.NAME, victim:Nick(), COLOR.NORM, " to ", COLOR.NAME, to:Nick(), COLOR.NORM, "!"
	}
	
end
PLUGIN:AddCommand( "send", {
	Call = PLUGIN.Send,
	Desc = "Sends a player",
	FlagDesc = "Allows users to send other players to places.",
	Console = { "send" },
	Chat = { "!send" },
	ReturnOrder = "Victim-To",
	Args = {Victim = "PLAYER", To = "PLAYER"},
})

function PLUGIN.Goto( owner, ply )
	
	local force = false
	if owner:GetMoveType() == MOVETYPE_NOCLIP then force = true end
	
	local pos = PLUGIN.SendPlayer( owner, ply, force )
	
	if !pos then exsto.Print( exsto_CHAT, owner, COLOR.NORM, "Not enough room to goto ", COLOR.NAME, ply , COLOR.NORM, "!" ) return end
	
	owner:SetPos( pos )
	
	return {
		Activator = owner,
		Player = ply,
		Wording = " has gone to "
	}
	
end
PLUGIN:AddCommand( "goto", {
	Call = PLUGIN.Goto,
	Desc = "Goto a player",
	FlagDesc = "Allows users to teleport to a player.",
	Console = { "goto" },
	Chat = { "!goto" },
	ReturnOrder = "Victim",
	Args = {Victim = "PLAYER"},
})

function PLUGIN.Bring( owner, ply )
		
	local force = false
	if owner:GetMoveType() == MOVETYPE_NOCLIP then force = true end
	
	local pos = PLUGIN.SendPlayer( owner, ply, force )

	if !pos then return { COLOR.NORM, "Not enough space to bring ", ply } end
	
	ply:SetPos( pos  )
	return {
		Activator = owner,
		Player = ply,
		Wording = " has brought ",
		Secondary = " to himself"
	}
	
end
PLUGIN:AddCommand( "bring", {
	Call = PLUGIN.Bring,
	Desc = "Bring a player to your location!",
	FlagDesc = "Allows users to bring other players.",
	Console = { "bring" },
	Chat = { "!bring" },
	ReturnOrder = "Victim",
	Args = {Victim = "PLAYER"},
})

PLUGIN:Register()