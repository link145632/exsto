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
	if !victim:IsInWorld() and !force then return false end
	if !ply:IsInWorld() and !force then return false end
	
	local pos = ply:GetPos() + Vector( 36, 0, 0 )
	
	if !util.IsInWorld( pos ) and !force then return false end
	
	return pos

end

function PLUGIN:Send( owner, victim, to, force )
	
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
	Desc = "Sends a player",
	FlagDesc = "Allows users to send other players to places.",
	Console = { "send" },
	Chat = { "!send" },
	ReturnOrder = "Victim-To-Force",
	Args = { Victim = "PLAYER", To = "PLAYER", Force = "BOOLEAN" },
	Optional = { Force = false },
})

function PLUGIN:Goto( owner, ply, force )
	
	if owner:GetMoveType() == MOVETYPE_NOCLIP then force = true end
	
	local pos = self:SendPlayer( ply, owner, force )
	
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
	Desc = "Goto a player",
	FlagDesc = "Allows users to teleport to a player.",
	Console = { "goto" },
	Chat = { "!goto" },
	ReturnOrder = "Victim-Force",
	Args = {Victim = "PLAYER", Force = "BOOLEAN"},
	Optional = { Force = false },
})

function PLUGIN:Bring( owner, ply, force )
		
	if owner:GetMoveType() == MOVETYPE_NOCLIP then force = true end
	
	local pos = self:SendPlayer( owner, ply, force )

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
	Desc = "Bring a player to your location!",
	FlagDesc = "Allows users to bring other players.",
	Console = { "bring" },
	Chat = { "!bring" },
	ReturnOrder = "Victim-Force",
	Args = {Victim = "PLAYER", Force = "BOOLEAN"},
	Optional = { Force = false },
})

PLUGIN:Register()