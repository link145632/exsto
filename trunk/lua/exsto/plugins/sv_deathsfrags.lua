--Created for Exsto by Shank - http://steamcommunity.com/nicatronTg

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	ID = "exsto-deathsfrags",
	Name = "Frag and Death editor",
	Disc = "Change a player's frags and deaths!",
	Owner = "Shank",
})

if !SERVER then return end

function PLUGIN.Frags(self, ply, target, frags)
	target:SetFrags(frags)
	return {
		Activator = ply,
		Player = target,
		Wording = " set ",
		Secondary = "'s kills to "..frags
	}
end

function PLUGIN.Deaths(self, ply, target, deaths)
	target:SetDeaths(deaths)
	return {
		Activator = ply,
		Player = target,
		Wording = " set ",
		Secondary = "'s deaths to "..deaths
	}
end

PLUGIN:AddCommand( "setfrags", {
	Call = PLUGIN.Frags,
	Desc = "Set's a player's frags",
	FlagDesc = "Allows a player to set someone's frags",
	Console = { "exsto_setfrags", },
	Chat = { "!setfrags" },
	ReturnOrder = "Target-Kills",
	Args = {Target="PLAYER", Kills="NUMBER"},
	--The above is formated like Variable=Type, Args = { Variable1 = "PLAYER", Variable2 = "NUMBER" },
	--Also, you need a ReturnOrder, like ReturnOrder = "Variable1-Variable2-Variable3",
})
PLUGIN:AddCommand( "setdeaths", {
	Call = PLUGIN.Deaths,
	Desc = "Set's a player's deaths",
	FlagDesc = "Allows a player to set someone's deaths",
	Console = { "exsto_setdeaths", },
	Chat = { "!setdeaths" },
	ReturnOrder = "Target-DeathCount",
	Args = {Target="PLAYER", DeathCount="NUMBER"},
	--The above is formated like Variable=Type, Args = { Variable1 = "PLAYER", Variable2 = "NUMBER" },
	--Also, you need a ReturnOrder, like ReturnOrder = "Variable1-Variable2-Variable3",
})
PLUGIN:Register()