--[[
	Exsto
	Copyright (C) 2010  Prefanatic

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

-- Chat Commands

-- Variables

exsto.Commands = {}
exsto.Arguments = {}
exsto.Flags = {}
exsto.FlagIndex = {}

local function AddArg( style, type, func ) table.insert( exsto.Arguments, {Style = style, Type = type, Func = func} ) end
AddArg( "PLAYER", "Player", function( nick, caller ) if nick == "" then return -1 else return exsto.FindPlayers( nick, caller ) end end )
AddArg( "NUMBER", "number", function( num ) return tonumber( num ) end )
AddArg( "STRING", "string", function( string ) return tostring( string ) end )
AddArg( "BOOLEAN", "boolean", function( bool ) return tobool( bool ) end )
AddArg( "NIL", "nil", function( object ) return "" end )

exsto.AddVariable({
	Pretty = "Enable Chat Spelling Suggestion",
	Dirty = "spellingcorrect",
	Default = true,
	Description = "Enable to have Exsto tell you if you mis-spell a command.",
	Possible = { true, false },
})

--[[ -----------------------------------
	Function: exsto.SendCommandList
	Description: Sends the Exsto command list to players on join.
     ----------------------------------- ]]
function exsto.SendCommandList( ply, format )

	local Send = {}
	for k,v in pairs( exsto.Commands ) do
		
		Send[v.ID] = {
			ID = v.ID,
			Desc = v.Desc,
			Args = v.Args,
			Chat = v.Chat,
			Console = v.Console,
			FlagDesc = v.FlagDesc,
			ReturnOrder = v.ReturnOrder,
			Optional = v.Optional,
			QuickMenu = v.QuickMenu,
			CallerID = v.CallerID,
			ExtraOptionals = v.ExtraOptionals or {},
			Category = v.Category
		}
		
	end
	if !ply and format == "format" then return Send end
	
	exsto.Print( exsto_CONSOLE_DEBUG, "COMMANDS --> Streaming command list to " .. ply:Nick() )
	
	exsto.UMStart( "ExRecCommands", ply, Send )
end
hook.Add( "exsto_InitSpawn", "exsto_StreamCommandList", exsto.SendCommandList )
concommand.Add( "_ResendCommands", exsto.SendCommandList )

--[[ -----------------------------------
	Function: exsto.ResendCommands
	Description: Resends the command list to everyone in the server.
     ----------------------------------- ]]
function exsto.ResendCommands()
	local send = exsto.SendCommandList( nil, "format" )
	
	exsto.UMStart( "ExRecCommands", player.GetAll(), send )
end

--[[ -----------------------------------
	Function: exsto.AddChatCommand
	Description: Adds chat commands into the Exsto list.
     ----------------------------------- ]]
function exsto.AddChatCommand( ID, info )

	if !ID or !info then exsto.Error( "No valid ID or Information for a chat command requesting initialization!" ) return end
	
	local returnOrder = {}
	if type( info.ReturnOrder ) == "string" then
		returnOrder = string.Explode( "-", info.ReturnOrder )
	end
	
	exsto.Commands[ID] = {
		ID = ID,
		Call = info.Call,
		Desc = info.Desc or "None Provided",
		FlagDesc = info.Desc or "None Provided",
		ReturnOrder = returnOrder,
		Args = info.Args,
		Optional = info.Optional or {},
		Plugin = info.Plugin or nil,
		Category = info.Category or "Unknown",
		DisallowCaller = info.DisallowCaller or false
	}
	
	exsto.Commands[ID].Chat = {}
	if !info.Chat then exsto.Error( ID .. " contains invalid chat commands!  Cannot continue register!" ) return end
	for k,v in pairs( info.Chat ) do
		exsto.AddChat( ID, v )
	end
	
	exsto.Commands[ID].Console = {}
	for k,v in pairs( info.Console ) do
		exsto.AddConsole( ID, v )
	end
	
end

--[[ -----------------------------------
	Function: exsto.AddChat
	Description: Cleans and categorises chat commands.
     ----------------------------------- ]]
function exsto.AddChat( ID, Look )
	if !ID or !Look then exsto.Error( "No valid ID or Information for a chat command requesting initialization!" ) return end
	
	local tab = exsto.Commands[ID]
	Look = Look:lower():Trim()
	
	table.insert( tab.Chat, Look )	
end

--[[ -----------------------------------
	Function: exsto.AddConsole
	Description: Cleans and categorises console commands.
     ----------------------------------- ]]
function exsto.AddConsole( ID, Look )
	if !ID or !Look then exsto.Error( "No valid ID or Information for a console command requesting initialization!" ) return end
	
	local tab = exsto.Commands[ID]
	
	table.insert( tab.Console, Look )
end

--[[ -----------------------------------
	Function: exsto.RemoveChatCommand
	Description: Removes a command ID from the Exsto list.
     ----------------------------------- ]]
function exsto.RemoveChatCommand( ID )
	exsto.Commands[ID] = nil
end

--[[ -----------------------------------
	Function: exsto.CreateFlag
	Description: Adds a flag to the Exsto flag table.
     ----------------------------------- ]]
function exsto.CreateFlag( ID, Desc )
	if exsto.Flags[ID] then return end
	exsto.Flags[ID] = Desc or "None Provided"
end

--[[ -----------------------------------
	Function: exsto.LoadFlags
	Description: Inserst all flags from commands into the exsto.Flag table.
     ----------------------------------- ]]
function exsto.LoadFlags()
	for k,v in pairs( exsto.Commands ) do
		exsto.CreateFlag( v.ID, v.FlagDesc )
	end
	
	for k,v in pairs( exsto.DefaultRanks ) do
		for I = 1, table.Count( v.Flags ) do
			exsto.CreateFlag( v.Flags[I] )
		end
	end
end

--[[ -----------------------------------
	Function: exsto.CreateFlagIndex
	Description: Creates a table filled with flags indexed by numbers
     ----------------------------------- ]]
function exsto.CreateFlagIndex()
	local index = {}
	for k,v in pairs( exsto.Flags ) do
		table.insert( exsto.FlagIndex, k )
	end
end

--[[ -----------------------------------
	Function: exsto.GetArgumentKey
	Description: Grabs the index of an argument type.
     ----------------------------------- ]]
function exsto.GetArgumentKey( style )
	for k,v in pairs( exsto.Arguments ) do
		if v.Style == style then return k end
	end
end

--[[ -----------------------------------
	Function: exsto.CommandCompatible
	Description: Checks to see if a command is compatible with Exsto.
     ----------------------------------- ]]
function exsto.CommandCompatible( data )
	if type( data.Call ) != "function"  then return end
	if type( data.Args ) != "table" then return end
	if type( data.Optional ) != "table" then return end
	if type( data.ReturnOrder ) != "table" then return end
	
	return true
end

--[[ -----------------------------------
	Function: exsto.CommandRequiresImmunity
	Description: Checks if a command handles players in any way
     ----------------------------------- ]]
function exsto.CommandRequiresImmunity( data )
	for _, argument in ipairs( data.ReturnOrder ) do
		if data.Args[ argument ] == "PLAYER" then return _ end
	end
	return false
end

--[[ -----------------------------------
	Function: exsto.PrintReturns
	Description: Does a format print of the return values given by plugins.
     ----------------------------------- ]]
function exsto.PrintReturns( data, I, multiplePeople )

	local style = { exsto_CHAT_ALL }
	
	-- Check if we can do this.
	if type( data ) == "table" then
	
		-- Check if he only wants it printing to the caller.
		if type( data[1] ) == "Player" or type( data[1] ) == "Entity" and data[1]:CanPrint() then
			style = { exsto_CHAT, data[1] }
		end
		
		-- Continue if he set us up to format his data.
		if data.Activator and data.Activator:IsValid() and data.Wording then
		
			local ply = data.Player
			if data.Player and type( data.Player ) == "Player" then ply = data.Player:Nick() end
			
			-- Change to himself if the acting player is the victim
			if ply == data.Activator:Nick() then ply = "him/herself" end
			
			-- Format any [self] requests.
			data.Wording = data.Wording:gsub( "%[self%]%", data.Activator:Nick() )
			
			local talk = { unpack( style ), COLOR.NAME, data.Activator:Name(), COLOR.NORM, data.Wording }
			
			if ply then 
				table.insert( talk, COLOR.NAME )
				table.insert( talk, ply )
			end
			
			if data.Secondary then
				table.insert( talk, COLOR.NORM )
				table.insert( talk, data.Secondary )
			end
			
			table.insert( talk, COLOR.NORM )
			table.insert( talk, "!" )
			
			exsto.Print( unpack( style ), unpack( talk ) )
			
		-- He is returning custom data.
		else exsto.Print( unpack( style ), unpack( data ) ) end
		
	end
	
end

--[[ -----------------------------------
	Function: exsto.ParseStrings
	Description: Parses text, then returns a table with items split by spaces, except stringed items.
     ----------------------------------- ]]
function exsto.ParseStrings( text )
	
	-- Code from raBBish, which is from Lexi, that completely lit up my string finding pattern on fire.
	-- http://www.facepunch.com/showthread.php?t=827179
	
	local quote = string.sub( text, 1, 1 ) ~= '"'
	local data = {}
	
	for chunk in string.gmatch( text, '[^"]+' ) do
		quote = not quote
		
		if quote then
			table.insert( data, chunk )
		else
			for chunk in string.gmatch( chunk, "%S+" ) do
				table.insert( data, chunk )
			end
		end
	end
	
	return data
end

--[[ -----------------------------------
	Function: exsto.ParseArguments
	Description: Parses text and returns formatted and normal typed variables.
     ----------------------------------- ]]
function exsto.ParseArguments( ply, data, args )

	-- Create return data.
	local cleanedArguments = {} -- Our cleaned argument table
	local activePlayers = { 1 } -- We put a 1 here for those commands who don't use this.
	local playersSlot = 0 -- The slot where the multiple players are
	
	-- Check and see if the arguments need to be cleaned and table'ed
	if type( args ) == "string" then
		args = exsto.ParseStrings( args )
	end
	
	-- See if we can compile the excess text that we have to match the return order.
	if #args > #data.ReturnOrder then
		local compile = ""
		for I = #data.ReturnOrder, #args do
			compile = compile .. args[ I ] .. " "
			args[ I ] = nil
		end
		
		args[ #data.ReturnOrder ] = compile
	end
	
	-- Check and loop through our arguments if he contains any environment variable.
	for I = 1, #args do
		for slice in string.gmatch( args[ I ], "\#(%w+)" ) do
			local data = exsto.GetVar( slice )
			if data then
				args[ I ] = string.gsub( args[ I ], "#" .. slice, data.Value )
			end
		end
	end
	
	-- Time to loop through our requested return orders and place items
	for I = 1, #data.ReturnOrder do
	
		-- Create local variables so we can call back
		local currentArgument = data.ReturnOrder[ I ]
		local currentType = data.Args[ currentArgument ]
		local currentSplice = args[ I ]
		local currentArgumentData = exsto.Arguments[ exsto.GetArgumentKey( currentType ) ]
		
		-- Check if we contain the splice, then convert that splice into the requested type.
		if currentSplice then
			local converted = currentArgumentData.Func( currentSplice, ply )
			
			-- See if we can catch our acting players variable and store it
			if currentArgumentData.Type == "Player" and type( converted ) == "table" and #converted >= 1 then
				activePlayers = converted
				playersSlot = #cleanedArguments + 1
				table.insert( cleanedArguments, converted )
			
			-- If we didn't get the correct value back, then something is wrong.  Lets check it out
			elseif currentArgumentData.Type != type( converted ) then
			
				-- See if it is a player that we were looking for.  Maybe we can give a suggestion!
				if type( converted ) == "table" and currentArgumentData.Type == "Player" and #converted == 0 then
					exsto.GetClosestString( currentSplice, exsto.BuildPlayerNicks(), nil, ply, "Unknown player" )
					return nil
				end
				
				-- Format some issues with Lua
				if type( converted ) == "nil" and currentArgumentData.Type == "number" then converted = "" end
				
				-- Finally notify us.
				ply:Print( exsto_CHAT, COLOR.NORM, "Argument: ", COLOR.NAME, currentArgument .. " (" .. currentArgumentData.Type .. ")", COLOR.NORM, " is needed!  You put ", COLOR.NAME, type( converted ) )
				
				return nil
				
			-- If our data type matches, celebrate!
			elseif currentArgumentData.Type == type( converted ) then
				table.insert( cleanedArguments, converted )
			end
			
		-- We ran out of splices to check; this is where we request optionals.
		else
		
			-- If the optional exists at all; insert his data in place of our own.
			if type( data.Optional[ currentArgument ] ) != "nil" then
				table.insert( cleanedArguments, data.Optional[ currentArgument ] )
			
			-- If the coder never supplied an optional value for the command, try and substitute things in.
			else
			
				-- See if we can substitute ourselves in if he asks for a PLAYER value.
				if currentType == "PLAYER" and I == 1 and ply:IsPlayer() and data.DisallowCaller == false then
					table.insert( cleanedArguments, { ply } )
					activePlayers = { ply }
					playersSlot = #cleanedArguments
					
				-- We can't do anything else.  Tell the caller.
				else
					ply:Print( exsto_CHAT, COLOR.NORM, "Argument ", COLOR.NAME, currentArgument .. " (" .. currentArgumentData.Type .. ")", COLOR.NORM, " is needed!" )
					return nil
				end
			end
		end
	end
	
	return cleanedArguments, activePlayers, playersSlot
	
end

--[[ -----------------------------------
	Function: ExstoParseCommand
	Description: Main thread that parses commands and runs them.
     ----------------------------------- ]]
local function ExstoParseCommand( ply, command, args, style )

	for _, splice in ipairs( args ) do
		args[ _ ] = splice:Trim()
	end
	
	for k, data in pairs( exsto.Commands ) do
		if ( style == "chat" and table.HasValue( data.Chat, command ) ) or ( style == "console" and table.HasValue( data.Console, command ) ) then
		
			-- We found our command, continue.
			hook.Call( "ExCommandCalled" )
			
			-- First, parse the text for the arguments.
			if style == "chat" then args = string.Implode( " ", args ) end
			local argTable, activePlayers, playersSlot = exsto.ParseArguments( ply, data, args )
			
			if !argTable then return "" end
			
			-- Check if we are allowed to perform this active command.
			local allowed, reason = ply:IsAllowed( data.ID )
			
			-- If the command requires an immunity check, update our allowance
			local slot = exsto.CommandRequiresImmunity( data )
			if slot then
				for I = 1, #activePlayers do
					allowed, reason = ply:IsAllowed( data.ID, argTable[ slot ][I] )
				end
			end
			
			if !allowed then
				-- Check our reason
				if reason == "immunity" then
					ply:Print( exsto_CHAT, COLOR.NORM, "Cannot run ", COLOR.NAME, command, COLOR.NORM, ", due to a player(s) involved having higher immunity!" )
				else
					ply:Print( exsto_CHAT, COLOR.NORM, "You are not allowed to run ", COLOR.NAME, command, COLOR.NORM, "!" )
				end
				return ""
			end

			-- Run this command on a loop through all active player participents.
			local newArgs, status, sentback, multiplePeopleToggle, alreadySaid
			
			if #activePlayers >= 3 then multiplePeopleToggle = true end
			for I = 1, #activePlayers do
				
				-- Create a copy of the arg table so we can edit it.
				newArgs = table.Copy( argTable )
				
				-- Now that we passed the immunity and allowance checks, insert what we need into the arg table
				local requiredAdditions = 1
				table.insert( newArgs, 1, ply )
				if data.Plugin then
					requiredAdditions = 2
					table.insert( newArgs, 1, data.Plugin )
				end

				-- Set our multiple player slot to contain only one we currently are on right now.
				if playersSlot != 0 then
					newArgs[ playersSlot + requiredAdditions ] = activePlayers[ I ]
				end

				-- Finally, call the function
				status, sentback = pcall( data.Call, unpack( newArgs ) )
				
				-- If we didn't make it, oh god.
				if !status then
					ply:Print( exsto_CHAT, COLOR.NORM, "Something went wrong while executing that command!" )
					exsto.ErrorNoHalt( "COMMAND --> " .. command .. " --> " .. sentback )
					return ""
				end
				
				-- Call our hook!
				hook.Call( "ExCommand-" .. data.ID, nil, newArgs )
				
				-- Print the return values.
				exsto.PrintReturns( sentback, I, multiplePeopleToggle )

			end
			
			return ""
		end
	end
	
	-- I don't think we found anything?
	if string.sub( command, 0, 1 ) == "!" and exsto.GetVar( "spellingcorrect" ).Value and style != "console" then
		local data = { Max = 100, Com = "" } // Will a command ever be more than 100 chars?
		local dist
		// Apparently we didn't find anything...
		for k,v in pairs( exsto.Commands ) do
			
			for k,v in pairs( v.Chat ) do
				dist = exsto.StringDist( command, v )
			
				if dist < data.Max then data.Max = dist; data.Com = v end
			end
			
		end

		ply:Print( exsto_CHAT, COLOR.NAME, command, COLOR.NORM, " is not a valid command.  Maybe you want ", COLOR.NAME, data.Com, COLOR.NORM, "?" )
	end
	
end

--[[ -----------------------------------
	Function: exsto.ChatMonitor
	Description: Monitors the chat, and checks to see if commands are run.
     ----------------------------------- ]]
function exsto.ChatMonitor( ply, text )
	local args = string.Explode( " ", text )
	local command = ""
	if args[1] then command = args[1]:lower() end
	
	table.remove( args, 1 )

	return ExstoParseCommand( ply, command, args, "chat" )
end
hook.Add( "PlayerSay", "exsto_ChatMonitor", exsto.ChatMonitor )

--[[ -----------------------------------
	Function: exsto.ParseCommands
	Description: Run on console command typing, creates a auto-complete list for console.
     ----------------------------------- ]]
function exsto.ParseCommands( com, args )
	
	-- Split the arguments up.
	args = args:Trim()
	local split = string.Explode( " ", args )
	local command = split[1] -- Convinence.

	if command == "" then return {} end -- Its not a command D:
	if !command then return {} end
	if string.len( command ) <= 0 then return {} end
	
	local niceargs = exsto.ParseStrings( args )

	local possible = {}
	local ID = ""
	local predictedCom = ""
	
	-- Loop through the possible commands!
	for id,v in pairs( exsto.Commands ) do
		-- Loop through all possible console commands.
		for k,v in pairs( v.Console ) do
			-- Find the string
			if string.find( v:lower(), command:lower() ) then
				-- add it
				ID = id
				predictedCom = v
				table.insert( possible, v )
			end
		end
	end
	
	-- Add our command root to the begining
	for k,v in pairs( possible ) do
		possible[k] = com .. " " .. v
	end
	
	if #possible > 1 then return possible end
	
	-- Check to see our arguments availible, and what one we are on right now.
	local comData = exsto.Commands[ID]
	local comArgs = {}
	local comOptional = {}
	local comOrder = {}
	
	if comData then -- We have an ID match.
		comData = table.Copy( comData )
		comArgs = comData.Args
		comOptional = comData.Optional
		comOrder = comData.ReturnOrder
		command = predictedCom
	end
	
	if !comData then return possible end
	
	-- Check to see what arg we are typing in on
	local curArg = args[#args]
	
	-- Grab the associated command argument
	local curComArg = comOrder[#args]
	
	-- Make nice arguments
	for k,v in pairs( comArgs ) do
		table.insert( comArgs, k )
		comArgs[k] = nil
	end
	
	-- Order the args
	local newArgs = ""
	for I = 1, #comOrder do
		local item = comOrder[I]
		
		newArgs = newArgs .. item .. " "
	end		
	
	-- Add his known arguments
	for k,v in pairs( possible ) do
		possible[k] = com .. " " .. command .. " " .. newArgs
	end
	
	return possible
end

--[[ -----------------------------------
	Function: exsto.SetQuickmenuSlot
	Description: Modifies an existing command to work with the quickmenu
     ----------------------------------- ]]
function exsto.SetQuickmenuSlot( id, data )
	if !exsto.Commands[ id ] then return end
	
	-- We have our data, now add to it.
	-- Create a special caller function for it for the client to call us with.
	local randID = "_ExPlugCaller_" .. math.random( -1000, 1000 )
	
	concommand.Add( randID, function( ply, _, args )
		return ExstoParseCommand( ply, exsto.Commands[ id ].Console[ 1 ], args, "console" )
	end )
	
	exsto.Commands[ id ].QuickMenu = true
	exsto.Commands[ id ].CallerID = randID
	exsto.Commands[ id ].ExtraOptionals = data
end

--[[ -----------------------------------
	Function: exsto.CommandCall
	Description: Run on the 'exsto' command.  It re-directs to a new command.
     ----------------------------------- ]]
function exsto.CommandCall( ply, _, args )
	if #args == 0 then ply:Print( exsto_CLIENT, "No command recieved!  Type 'exsto Commands' for the command list!" ) return end
	
	-- Copy the table so we can edit it clean.
	local command = args[1]
	
	-- Remove the command, we don't need it.  It should leave us with the function arguments.
	table.remove( args, 1 )

	local finished = exsto.RunCommand( ply, command, args )
	
	if !finished then
		ply:Print( exsto_CLIENT, "Error running command 'exsto " .. command .. "'" )
		return
	end
end
concommand.Add( "exsto", exsto.CommandCall, exsto.ParseCommands )

--[[ -----------------------------------
	Function: exsto.RunCommand
	Description: Adds chat commands into the Exsto list.
     ----------------------------------- ]]
function exsto.RunCommand( ply, command, args )
	return ExstoParseCommand( ply, command, args, "console" )
end

// Stolen from lua-users.org
function exsto.StringDist( s, t )
	local d, sn, tn = {}, #s, #t
		local byte, min = string.byte, math.min
		for i = 0, sn do d[i * tn] = i end
		for j = 0, tn do d[j] = j end
		for i = 1, sn do
			local si = byte(s, i)
			for j = 1, tn do
				d[i*tn+j] = min(d[(i-1)*tn+j]+1, d[i*tn+j-1]+1, d[(i-1)*tn+j-1]+(si == byte(t,j) and 0 or 1))
			end
		end
		return d[#d]
end

function exsto.OpenMenu( ply )

	local menuAuthKey = math.random( -1000, 1000 )
	ply.MenuAuthKey = menuAuthKey
	
	exsto.UMStart( "exsto_Menu", ply, menuAuthKey, ply:GetRank(), #exsto.GetRankData( ply:GetRank() ).Flags )
	
end
exsto.AddChatCommand( "menu", {
	Call = exsto.OpenMenu,
	Desc = "Opens the Exsto Menu",
	Console = { "menu" },
	Chat = { "!menu" },
	Args = {},
})