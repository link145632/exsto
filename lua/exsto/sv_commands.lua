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

local function AddArg( style, type, func ) table.insert( exsto.Arguments, {Style = style, Type = type, Func = func} ) end
AddArg( "PLAYER", "Player", function( nick ) if nick == "" then return -1 else return exsto.FindPlayer( nick ) end end )
AddArg( "NUMBER", "number", function( num ) return tonumber( num ) end )
AddArg( "STRING", "string", function( string ) return tostring( string ) end )
AddArg( "NIL", "nil", function( object ) return "" end )

-- Functions

-- TODO: I don't want commands to be shown if someone doesn't have the flag to actually use it.  It's stupid.
function exsto.AddChatCommand( ID, info )

	if !ID or !info then exsto.Error( "No valid ID or Information for a chat command requesting initialization!" ) return end
	--if exsto.Commands[ID] then exsto.Error( "There is already another name registered from " .. ID .. "!  If it helps, the other entry is using " .. exsto.Commands[ID].Chat[1] .. " as one of its chat commands, this one is using " .. info.Chat[1] .. "!" ) return end
	
	local returnOrder = {}
	if type( info.ReturnOrder ) == "string" then
		returnOrder = string.Explode( "-", info.ReturnOrder )
	end
	
	exsto.Commands[ID] = {
		ID = ID,
		Call = info.Call,
		Desc = info.Desc or "None Provided",
		FlagDesc = info.FlagDesc or "None Provided",
		ReturnOrder = returnOrder,
		Args = info.Args,
		Optional = info.Optional or {},
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

function exsto.AddChat( ID, Look )
	if !ID or !Look then exsto.Error( "No valid ID or Information for a chat command requesting initialization!" ) return end
	
	local tab = exsto.Commands[ID]
	Look = Look:lower():Trim()
	
	table.insert( tab.Chat, Look )	
	
	--print( "Adding chat to " .. ID .. " " .. Look )
end

-- TODO: Add descriptions to commands.
function exsto.AddConsole( ID, Look )
	if !ID or !Look then exsto.Error( "No valid ID or Information for a console command requesting initialization!" ) return end
	
	local tab = exsto.Commands[ID]
	
	table.insert( tab.Console, Look )
	//concommand.Add( Look, exsto.CommandCall )
end

function exsto.RemoveChatCommand( ID )
	exsto.Commands[ID] = nil
end

-- Flag creation + other stuff
function exsto.CreateFlag( ID, Desc )

	exsto.Flags[ID] = Desc
	
end

function exsto.LoadFlags()

	for k,v in pairs( exsto.Commands ) do
	
		exsto.Flags[v.ID] = v.FlagDesc
		
	end
	
end

function exsto.GetArgumentKey( style )

	for k,v in pairs( exsto.Arguments ) do
	
		if v.Style == style then return k end
		
	end
	
end

function exsto.NiceArgs( args, info )

	local args = string.Explode( "|", args )
	
	local data = {}
	
	for k,v in pairs( args ) do
	
		v = string.lower( v )
		first = string.sub( v, 0, 1 )
		first = string.upper( first )
		v = string.sub( v, 2 )
		v = first .. v
		
		table.insert( data, Color( 255, 0, 0 ) )
		table.insert( data, v );
		
	end
	
	//PrintTable( info );
	
	return data
	
end

function exsto.CommandCompatible( data )

	--print( type( data.Call ), type( data.Args ), type( data.Optional ) )

	if type( data.Call ) != "function"  then return end
	if type( data.Args ) != "table" then return end
	if type( data.Optional ) != "table" then return end
	if type( data.ReturnOrder ) != "table" then return end
	
	return true
	
end
	
function exsto.ParseStrings( text )

	--[[-- Pattern look for string.
	local stringStart, stringEnd, content = string.find( text, "[\"\'](.-)[\"\']" )
	
	-- If theres no strings, lets see if we atleast have the start of one.
	if !stringStart then
		local stringStart, stringEnd, content = string.find( text, "[\"\']([.^\"^\']-)" )
		
		local data = {}
		local firstSection = text
		if stringStart then -- We have one, return the sub rest.
			firstSection = string.sub( text, 1, stringStart - 1 ):Trim()
			local str = string.sub( text, stringStart - 1 ):Trim():gsub( "\'", "" ):gsub( "\"", "" ) 
			table.insert( data, str )
		end
		
		local rest = string.Explode( " ", firstSection )
		table.Add( rest, data )
		
		return rest
	end
	
	-- Sub out the first part with no strings.
	local firstSection = string.sub( text, 1, stringStart - 1 ):Trim()
	
	local args = string.Explode( " ", firstSection )
	if firstSection:len() < 1 then
		args = {}
	end
	
	-- Put string into the argument table as one argument
	table.insert( args, content )
	
	-- Look at the end of the string to check for another section of string
	local lastSection = string.sub( text, stringEnd + 1 ):Trim()
	
	while lastSection != "" do
	
		local stringStart, stringEnd, content = string.find( lastSection, "[\"](.-)[\"]" )
		
		if stringStart then
			-- Theres another string after our first...
			local firstSection = string.sub( lastSection, 1, stringStart - 1):Trim()
			local newArgs = string.Explode( " ", firstSection )
			
			table.insert( newArgs, content )
			table.Add( args, newArgs )
			
			lastSection = string.sub( lastSection, stringEnd + 1 ):Trim()
			
		else
			
			-- If theres no strings, lets see if we atleast have the start of one.
			local stringStart, stringEnd, content = string.find( lastSection, "[\"\']([.^\"^\']-)" )

			if stringStart then -- We have one, return the sub rest.
			
				local firstSection = string.sub( lastSection, 1, stringStart - 1 ):Trim()
				local str = string.sub( lastSection, stringStart - 1 ):Trim()

				local rest = string.Explode( " ", firstSection )
				table.insert( rest, str )
				table.Add( args, rest )
				
				lastSection = ""
				
				break
				
			else

				-- Theres no more string.  Just put it in.
				local newArgs = string.Explode( " ", lastSection )
				table.Add( args, newArgs )
				
				lastSelection = ""
				
				break
				
			end
			
		end
		
	end
	
	-- Do a final cleaning.
	for k,v in pairs( args ) do
		args[k] = v:Trim():gsub( "\'", "" ):gsub( "\"", "" )
	end
	
	return args]]
	
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

function exsto.ParseArguments( ply, text, data, alreadyString )

	local Return = {}
	Return[1] = ply or "Console"
	
	local args = data.Args
	local returnOrder = data.ReturnOrder
	local optional = data.Optional
	
	-- Compatibility checks, woop.
	if !exsto.CommandCompatible( data ) and ply then
		exsto.Print( exsto_CHAT, ply, COLOR.NORM, "The command you tried to run is not compatible with Exsto!" )
		exsto.Print( exsto_CONSOLE_DEBUG, "COMMANDS --> Command \"" .. data.ID .. "\" could not be parsed due to incompatibilities with Exsto.  Please contact plugin coder." )
		return
	end

	local text_args = text
	if !alreadyString then
		text_args = exsto.ParseStrings( text:Trim() )
	end

	for I = 1, #returnOrder do
	
		local curArg = args[returnOrder[I]]
		local argName = returnOrder[I]
	
		local argkey = exsto.GetArgumentKey( curArg )
		if not argkey then exsto.Error( "Invalid argument is being used!" ) return end
		
		-- Easy thing.
		local argTable = exsto.Arguments[argkey]
		
		-- Lets look at the first text slot we have, and *assume* its going to be our first argument.
		local textSlot = text_args[I]

		-- Now hang on, if we have gone over the number of text slots, then we need to start placing optionals.
		if !textSlot then
		
			//print( argName, optional[argName] )
		
			if optional[argName] then -- If an optional exists for this argument slot then continue
				table.insert( Return, optional[argName] )
				exsto.Print( exsto_CONSOLE_DEBUG, "COMMANDS --> Optional value \"" .. argName .. "\" is being inserted with a value of " .. tostring( optional[argName] ) ) 
			else
				-- Lets see what hes trying to access.  If he is trying to access a PLAYER with no value, substitue himself.
				if curArg == "PLAYER" then
					table.insert( Return, ply )
					exsto.Print( exsto_CONSOLE_DEBUG, "COMMANDS --> Adding in caller value for \"" .. argName .. "\'!" )
				else
					-- If it doesn't exist, the chat maker did not properly code the command.  Send debug data.
					exsto.Print( exsto_CHAT, ply, COLOR.NORM, "The command you tried to run is missing an optional value!" )
					exsto.Print( exsto_CONSOLE_DEBUG, "COMMANDS --> Command \"" .. data.ID .. "\" could not be parsed due to incompatibilities with Exsto.  The optional values did not match up with the required." )
					return
				end
			end
			
		else
			-- Run the text slot through the data type the argument is, see if it works.
			local data = argTable.Func( textSlot )
			
			if argTable.Type != type( data ) then -- If its not the value type we need, panic and end.
			
				local form = type( data );
					
				if form == "number" and exsto.Arguments[argkey].Type == "Player" then form = "nobody! (Couldn't find player!)" end		
				// Temp String Fix-- HACK
				if form == "nil" and exsto.Arguments[argkey].Type == "number" then form = "string!" end
				
				exsto.Print( exsto_CHAT, ply, COLOR.NORM, "Argument ", COLOR.NAME, argName .. " (" .. exsto.Arguments[argkey].Type .. ")", COLOR.NORM, " is needed!  You put ", COLOR.NAME, form )
				
				return nil
				
			else -- Add it to the return table, its fine.
				table.insert( Return, data )
			end
			
		end

	end

	return Return
end

function exsto.ChatMonitor( ply, text )
	if !ply or !text then exsto.Error( "No player or text exists in this hook, call the doctor!" ) return end
	
	--text = text:lower()
	
	local args = string.Explode( " ", text )
	local Command = args[1]:lower()
	
	-- Make the strings nicer.
	for k,v in pairs( args ) do
		--args[k] = v:lower():Trim()
		args[k] = v:Trim()
	end
	
	local Found = false
	for k,v in pairs( exsto.Commands ) do
		if table.HasValue( v.Chat, Command ) then
			Found = v
		end
	end
	
	if Found then
		
		table.remove( args, 1 )
		local args = string.Implode( " ", args )
		
		if Found.Args != "" then 
			args = exsto.ParseArguments( ply, args, Found )
		else
			args = {ply}
		end
		
		if not args then return end
		
		local allowed = ply:IsAllowed( Found.ID )
		local onPlayer = false
		for k,v in pairs( Found.ReturnOrder ) do
			if Found.Args[v] == "PLAYER" then
				allowed = ply:IsAllowed( Found.ID, args[k] )
				break
			end
		end
		
		if !allowed then exsto.Print( exsto_CHAT, ply, COLOR.NORM, "You are not allowed to run ", COLOR.NAME, Command, COLOR.NORM, "!" ) return end
		
		local status, data = pcall( Found.Call, unpack( args ) )
		
		if !status then
			exsto.Print( exsto_CHAT, ply, COLOR.NORM, "Something went wrong while executing that command.  Check your console for more details." )
			exsto.Print( exsto_CLIENT, ply, "The function call associated with " .. Command .. " is broken.  Debug information will be printed to your console.\n ** Error: " .. data .. "\n Please use this information and report it as a bug at http://code.google.com/p/exsto/issues/list" )
			exsto.ErrorNoHalt( "COMMAND --> " .. Command .. " --> " .. data )
			return ""
		end

		local style = { exsto_CHAT_ALL }
		if type( data ) == "table" and type( data[1] ) == "Player" then style = { exsto_CHAT, data[1] } end
		
		if type( data ) == "table" and (data.Activator and data.Wording) then
		
			local activator = data.Activator
			local ply = nil
			if data.Player then
				ply = data.Player
				if type( ply ) == "Player" then
					ply = ply:Name()
				else
					ply = tostring( ply )
				end
			end
			
			-- Lets pull some patterns into this, shall we?
			data.Wording = string.gsub( data.Wording, "%[self%]%", data.Activator:Nick() )
			
			if data.Secondary and data.Player then
				data.Secondary = string.gsub( data.Secondary, "%[self%]", data.Activator:Nick() )
				//local ply = data.Player
				exsto.Print( unpack( style ), COLOR.NAME, activator:Name(), COLOR.NORM, data.Wording, COLOR.NAME, ply, COLOR.NORM, data.Secondary, "!" )
			elseif !data.Secondary and data.Player then
				//local ply = data.Player
				exsto.Print( unpack( style ), COLOR.NAME, activator:Name(), COLOR.NORM, data.Wording, COLOR.NAME, ply, COLOR.NORM, "!" )
			elseif !data.Secondary and !data.Player then
				exsto.Print( unpack( style ), COLOR.NAME, activator:Name(), COLOR.NORM, data.Wording, COLOR.NORM, "!" )
			end
			
		elseif type( data ) == "table" then exsto.Print( unpack( style ), unpack( data ) ) end
		
		return ""
		
	elseif !Found and string.find( string.sub( text, 0, 1 ), "!" ) then
	
		local data = { Max = 100, Com = "" } // Will a command ever be more than 100 chars?
		text = string.Explode( " ", text )[1]
		// Apparently we didn't find anything...
		for k,v in pairs( exsto.Commands ) do
			
			for k,v in pairs( v.Chat ) do
				local dist = exsto.StringDist( Command, v )
			
				if dist < data.Max then data.Max = dist; data.Com = v end
			end
			
		end

		exsto.Print( exsto_CHAT, ply, COLOR.NAME, text, COLOR.NORM, " is not a valid command.  Maybe you want ", COLOR.NAME, data.Com, COLOR.NORM, "?" )
	
	end
	
end
hook.Add( "PlayerSay", "exsto_ChatMonitor", exsto.ChatMonitor )

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

function exsto.CommandCall( ply, _, args )
	if #args == 0 then exsto.Print( exsto_CLIENT, ply, "No command recieved!  Type 'exsto Commands' for the command list!" ) return end
	
	-- Copy the table so we can edit it clean.
	local args = table.Copy( args )
	local command = args[1]
	
	-- Remove the command, we don't need it.  It should leave us with the function arguments.
	table.remove( args, 1 )

	local finished = exsto.RunCommand( ply, command, args )
	
	if !finished then
		exsto.Print( exsto_CLIENT, ply, "Error running command 'exsto " .. command .. "'" )
		return
	end
end
concommand.Add( "exsto", exsto.CommandCall, exsto.ParseCommands )

function exsto.RunCommand( ply, command, args )
	
	local IsConsole = false
	if ply:EntIndex() == 0 then IsConsole = true ply = nil print( "Oh god hes console!" ) end -- If hes a console, make sure the rest of us know.

	-- Make the strings nicer.
	for k,v in pairs( args ) do
		args[k] = v:lower():Trim()
	end
	
	local Found = false
	for k,v in pairs( exsto.Commands ) do
		if table.HasValue( v.Console, command:lower() ) then
			Found = v
		end
	end
	
	if Found then
		
		//local args = string.Implode( " ", args )
		
		if Found.Args != "" then 
			args = exsto.ParseArguments( ply, args, Found, true )
		else
			args = {ply}
		end
		
		if not args then return end
		
		if !IsConsole then
			local allowed = ply:IsAllowed( Found.ID )
			local onPlayer = false
			for k,v in pairs( Found.ReturnOrder ) do
				if Found.Args[v] == "PLAYER" then
					allowed = ply:IsAllowed( Found.ID, args[k] )
					break
				end
			end
		end
		
		if !IsConsole and !allowed then exsto.Print( exsto_CHAT, ply, COLOR.NORM, "You are not allowed to run ", COLOR.NAME, Command, COLOR.NORM, "!" ) return end
		
		local status, data = pcall( Found.Call, unpack( args ) )
		
		if !status and !IsConsole then
			exsto.Print( exsto_CLIENT, ply, "The function call associated with " .. command .. " is broken.  Debug information will be printed to your console.\n ** Error: " .. data .. "\n Please use this information and report it as a bug at http://code.google.com/p/exsto/issues/list" )
			exsto.ErrorNoHalt( "COMMAND --> " .. command .. " --> " .. data )
			return
		end
		
		local style = { exsto_CHAT_ALL }
		if !IsConsole and type( data ) == "table" and type( data[1] ) == "Player" then style = { exsto_CHAT, data[1] } end
		
		if type( data ) == "table" and (data.Activator and data.Wording) then
		
			local activator = data.Activator
			local ply = nil
			if data.Player then
				ply = data.Player
				if type( ply ) == "Player" then
					ply = ply:Name()
				else
					ply = tostring( ply )
				end
			end
			
			-- Lets pull some patterns into this, shall we?
			data.Wording = string.gsub( data.Wording, "%[self%]%", data.Activator:Nick() )
			
			if data.Secondary and data.Player then
				//local ply = data.Player
				data.Secondary = string.gsub( data.Secondary, "%[self%]", data.Activator:Nick() )
				exsto.Print( unpack( style ), COLOR.NAME, activator:Name(), COLOR.NORM, data.Wording, COLOR.NAME, ply, COLOR.NORM, data.Secondary, "!" )
			elseif !data.Secondary and data.Player then
				//local ply = data.Player
				exsto.Print( unpack( style ), COLOR.NAME, activator:Name(), COLOR.NORM, data.Wording, COLOR.NAME, ply, COLOR.NORM, "!" )
			elseif !data.Secondary and !data.Player then
				exsto.Print( unpack( style ), COLOR.NAME, activator:Name(), COLOR.NORM, data.Wording, COLOR.NORM, "!" )
			end
			
		elseif type( data ) == "table" then exsto.Print( unpack( style ), unpack( data ) ) end
		
		return ""
		
	end
	
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
	
	exsto.UMStart( "exsto_Menu", ply, menuAuthKey )
	
end
exsto.AddChatCommand( "menu", {
	Call = exsto.OpenMenu,
	Desc = "Opens the Exsto Menu",
	Console = { "menu" },
	Chat = { "!menu" },
	Args = {},
})