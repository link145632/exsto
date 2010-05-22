-- Prefan Access Controller
-- Color'or Plugin

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Color Changer",
	ID = "color",
	Desc = "A plugin that allows changing color of players!",
	Owner = "Prefanatic",
} )

if not SERVER then return end 

function PLUGIN.Color( self, ply, r, g, b, a )

	ply:SetColor( r, g, b, a )
	
	return {
		Activator = self,
		Player = ply,
		Wording = " has colored ",
		Secondary = " with " .. r .. ", " .. g .. ", " .. b .. ", " .. a
	}
	
end
PLUGIN:AddCommand( "color", {
	Call = PLUGIN.Color,
	Desc = "Colors a player",
	FlagDesc = "Allows users to search for commands.",
	Console = { "color" },
	Chat = { "!color" },
	ReturnOrder = "Victim-Red-Green-Blue-Alpha",
	Args = {Victim = "PLAYER", Red = "NUMBER", Green = "NUMBER", Blue = "NUMBER", Alpha = "NUMBER"},
	Optional = {Red = 255, Green = 255, Blue = 255, Alpha = 255},
})

PLUGIN:Register()
