--Created for Exsto by Shank - http://steamcommunity.com/nicatronTg

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	ID = "exsto-respawn",
	Name = "Respawn Players",
	Disc = "Respawn players who think they're big jobs and can't be killed",
	Owner = "Shank",
})

if !SERVER then return end

function PLUGIN.Respawn(self, ply, target)
	target:Spawn()
	
	return {
		Activator = ply,
		Player = target,
		Wording = " respawned ",
		Secondary = ""
	}
end

PLUGIN:AddCommand( "respawn", {
	Call = PLUGIN.Respawn,
	Desc = "Respawns a selected player",
	FlagDesc = "Allows a player to respawn a dead player",
	Console = { "exsto_respawn", },
	Chat = { "!respawn" },
	ReturnOrder = "Target",
	Args = {Target="PLAYER"},
	--The above is formated like Variable=Type, Args = { Variable1 = "PLAYER", Variable2 = "NUMBER" },
	--Also, you need a ReturnOrder, like ReturnOrder = "Variable1-Variable2-Variable3",
})

PLUGIN:Register()