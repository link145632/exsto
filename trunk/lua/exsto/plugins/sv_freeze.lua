
local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Freezer",
	ID = "freeze",
	Desc = "A plugin that allows freezing of other players!",
	Owner = "Prefanatic",
} )

function PLUGIN.Freeze( self, ply )

	local cur_movetype = ply:GetMoveType()
	
	if cur_movetype == MOVETYPE_WALK then
		ply:SetMoveType( MOVETYPE_NONE )
		return {
			Activator = self,
			Player = ply,
			Wording = " has frozen ",
		}
	else
		ply:SetMoveType( MOVETYPE_WALK )
		return {
			Activator = self,
			Player = ply,
			Wording = " has unfrozen ",
		}
	end
	
end
PLUGIN:AddCommand( "freeze", {
	Call = PLUGIN.Freeze,
	Desc = "Freezes a player",
	FlagDesc = "Allows users to freeze other players.",
	Console = { "freeze" },
	Chat = { "!freeze", "!unfreeze" },
	ReturnOrder = "Victim",
	Args = {Victim = "PLAYER"},
})

PLUGIN:Register()