-- Exsto
-- Console Chat Commands

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Chat Console",
	ID = "console",
	Desc = "A plugin that allows running console commands in chat!",
	Owner = "Prefanatic",
} )
 
if not SERVER then return end

function PLUGIN.LuaRun( owner, lua )
	RunString( lua )
	
	return {
		COLOR.NAME, owner, COLOR.NORM, " has run lua - ", COLOR.NAME, lua, COLOR.NORM, "!"
	}
end
PLUGIN:AddCommand( "luarun", {
	Call = PLUGIN.LuaRun,
	Desc = "Runs lua code on the server.",
	FlagDesc = "Allows users to execute lua on the server.",
	Console = { "luarun" },
	Chat = { "!lua" },
	ReturnOrder = "Command",
	Args = {Command = "STRING"}
} )

function PLUGIN.CExec( owner, ply, command )
	ply:ConCommand( command )
	
	return {
		Activator = owner,
		Player = ply,
		Wording = " has run a command on ",
	}
end
PLUGIN:AddCommand( "cexec", {
	Call = PLUGIN.CExec,
	Desc = "Runs a command on the client.",
	FlagDesc = "Allows users to run commands on the client.",
	Console = { "cexec" },
	Chat = { "!cexec" },
	ReturnOrder = "Player-Command",
	Args = {Player = "PLAYER", Command = "STRING"}
} )

function PLUGIN.RunCommand( owner, command )
	
	game.ConsoleCommand( command .. "\n" )
	
	return {
		Activator = owner,
		Player = command,
		Wording = " has ran the command ",
	}
	
end
PLUGIN:AddCommand( "command", {
	Call = PLUGIN.RunCommand,
	Desc = "Runs console command",
	FlagDesc = "Allows users to run console commands.",
	Console = { "command" },
	Chat = { "!command" },
	ReturnOrder = "Command",
	Args = {Command = "STRING"},
})

PLUGIN:Register()