--Created for Exsto by Shank - http://steamcommunity.com/nicatronTg

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	ID = "exsto-decalsandsounds",
	Name = "Decals and sounds",
	Disc = "Clear decals, stop sounds.",
	Owner = "Shank",
})

if !SERVER then 
usermessage.Hook("exsto_cleardecals", function()
	RunConsoleCommand("r_ClearDecals")
end)

usermessage.Hook("exsto_stopsounds", function()
	RunConsoleCommand("stopsounds")
end)
end

function PLUGIN.ClearDecals(self, ply)
	local rp = RecipientFilter()
	rp:AddAllPlayers()
	umsg.Start("exsto_cleardecals", rp)
	umsg.End()
	
	return {
		Activator = ply,
		Player = "all players'",
		Wording = " cleared ",
		Secondary = " decals"
	}
end

function PLUGIN.StopSounds(self, ply)
	local rp = RecipientFilter()
	rp:AddAllPlayers()
	umsg.Start("exsto_stopsounds", rp)
	umsg.End()
	
	return {
		Activator = ply,
		Player = "all players'",
		Wording = " stopped ",
		Secondary = " sounds"
	}
end

PLUGIN:AddCommand( "decals", {
	Call = PLUGIN.ClearDecals,
	Desc = "Clears all player's decals",
	FlagDesc = "Allows a player to clear all player's decals",
	Console = { "exsto_decals", },
	Chat = { "!decals" },
	Args = {},
	--The above is formated like Variable=Type, Args = { Variable1 = "PLAYER", Variable2 = "NUMBER" },
	--Also, you need a ReturnOrder, like ReturnOrder = "Variable1-Variable2-Variable3",
})

PLUGIN:AddCommand( "stopsounds", {
	Call = PLUGIN.StopSounds,
	Desc = "Stops all server sounds",
	FlagDesc = "Allows a player to stop all sounds on the server",
	Console = { "exsto_sounds", },
	Chat = { "!stopsounds" },
	Args = {},
	--The above is formated like Variable=Type, Args = { Variable1 = "PLAYER", Variable2 = "NUMBER" },
	--Also, you need a ReturnOrder, like ReturnOrder = "Variable1-Variable2-Variable3",
})

PLUGIN:Register()