-- Exsto
-- Spectate Plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Spectate",
	ID = "spectate",
	Desc = "A plugin that allows spectating other players!",
	Owner = "Prefanatic",
} )

function PLUGIN:Spectate( owner, ply )

	if ply.Spectating then return end
	if owner.Spectating then return end
	
	owner.Weapons = {}
	
	for k,v in pairs( owner:GetWeapons() ) do
	
		table.insert( owner.Weapons, v:GetClass() )
		
	end
	
	owner:StripWeapons()

	owner:Spectate( OBS_MODE_CHASE )
	owner:SpectateEntity( ply )
	
	owner.Spectating = true
	
end
PLUGIN:AddCommand( "spectate", {
	Call = PLUGIN.Spectate,
	Desc = "Spectates a player",
	FlagDesc = "Allows users to spectate a person.",
	Console = { "spectate" },
	Chat = { "!spectate" },
	ReturnOrder = "Victim",
	Args = {Victim = "PLAYER"},
})

function PLUGIN:UnSpectate( owner )

	if not owner.Spectating then return end
	if not owner.Weapons then return end
	
	for k,v in pairs( owner.Weapons ) do
		owner:Give( tostring( v ) )
	end		

	owner:UnSpectate()
	
	owner.Spectating = false
	
end
PLUGIN:AddCommand( "unspectate", {
	Call = PLUGIN.UnSpectate,
	Desc = "Unspectates",
	FlagDesc = "Allows users to unspectate a person.",
	Console = { "unspectate" },
	Chat = { "!unspectate" },
	Args = {},
})

PLUGIN:Register()
