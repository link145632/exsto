-- Exsto
-- Slay Plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Slay",
	ID = "slay",
	Desc = "A plugin that allows slaying players!",
	Owner = "Prefanatic",
} )

function PLUGIN:Slay( owner, ply )
	
	ply:Kill()
	
	return {
		Activator = owner,
		Player = ply,
		Wording = " has slayed "
	}
	
end
PLUGIN:AddCommand( "slay", {
	Call = PLUGIN.Slay,
	Desc = "Slays a player",
	FlagDesc = "Allows users to slay a player.",
	Console = { "slay" },
	Chat = { "!slay" },
	ReturnOrder = "Victim",
	Args = {Victim = "PLAYER"},
})

PLUGIN:Register()