--Created for Exsto by Shank - http://steamcommunity.com/nicatronTg

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	ID = "exsto-speed",
	Name = "Speed",
	Disc = "Set a player's run and walk speed, with the addition of jump power!",
	Owner = "Shank",
})

if !SERVER then return end

function PLUGIN.RunSpeed(self, ply, target, speed)
	local newspeed = math.Clamp(speed, 1, 10000000000000000000)
	target:SetRunSpeed(newspeed)
	
	return {
		Activator = ply,
		Player = target,
		Wording = " has changed the run speed of ",
		Secondary = " to "..newspeed
	}
end

function PLUGIN.WalkSpeed(self, ply, target, speed)
	local newspeed = math.Clamp(speed, 1, 10000000000000000000)
	target:SetWalkSpeed(newspeed)
	
	return {
		Activator = ply,
		Player = target,
		Wording = " has changed the walk speed of ",
		Secondary = " to "..newspeed
	}
end

function PLUGIN.JumpPower(self, ply, target, power)
	local newpower = math.Clamp(power, 1, 2000)
	target:SetJumpPower(newpower)
	
	return {
		Activator = ply,
		Player = target,
		Wording = " has changed the jump power for ",
		Secondary = " to "..newpower
	}
end
PLUGIN:AddCommand( "runspeed", {
	Call = PLUGIN.RunSpeed,
	Desc = "Sets a player's run speed(def 500)",
	FlagDesc = "Allows users to change player's run speed.",
	Console = { "exsto_runspeed", "scoin_runspeed" },
	Chat = { "!runspeed", "!scoin_runspeed" },
	ReturnOrder = "Target-Power",
	Args = { Target = "PLAYER", Power = "NUMBER" },
})
PLUGIN:AddCommand( "walkspeed", {
	Call = PLUGIN.WalkSpeed,
	Desc = "Sets a player's walk speed(def 250)",
	FlagDesc = "Allows users to change player's walk speed.",
	Console = { "exsto_walkspeed", "scoin_walkspeed" },
	Chat = { "!walkspeed", "!scoin_walkspeed" },
	ReturnOrder = "Target-Power",
	Args = { Target = "PLAYER", Power = "NUMBER" },
})
PLUGIN:AddCommand( "jumppower", {
	Call = PLUGIN.JumpPower,
	Desc = "Sets a player's jump power(max 2000)",
	FlagDesc = "Allows users to change player's jump power.",
	Console = { "exsto_jumppower", "scoin_jumppower" },
	Chat = { "!jumppower", "!scoin_jumppower" },
	ReturnOrder = "Target-Power",
	Args = { Target = "PLAYER", Power = "NUMBER" },
})

PLUGIN:Register()