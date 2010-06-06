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


-- Usermessage Control

require( "glon" )

if SERVER then

	function exsto.SendRankErrors( ply )
		exsto.UMStart( "ExRankErr", exsto.RankErrors )
	end

--[[ -----------------------------------
	Function: exsto.SendFlags
	Description: Sends the flags table down to a client.
     ----------------------------------- ]]
	function exsto.SendFlags( ply )
		-- Flag Index
		exsto.UMStart( "ExStartFlag", ply, "index" )
		for k,v in pairs( exsto.FlagIndex ) do
			exsto.UMStart( "ExRecFlag", ply, k, v )
		end
		exsto.UMStart( "ExEndFlag", ply )
		
		-- Flags
		exsto.UMStart( "ExStartFlag", ply, "flags" )
		for k,v in pairs( exsto.Flags ) do
			exsto.UMStart( "ExRecFlag", ply, k, v )
		end
		exsto.UMStart( "ExEndFlag", ply )

	end

--[[ -----------------------------------
	Function: exsto.SendRank
	Description: Sends a single rank down to the client.
     ----------------------------------- ]]
	function exsto.SendRank( ply, rank )
		local rank = exsto.Levels[rank]
		
		//if !rank then exsto.ErrorNoHalt( "UMSG --> Failure to send rank '" .. rank .. "' To " .. ply:Nick() .. ".  No rank exists!" ) return end
		
		exsto.UMStart( "exsto_RecieveRanks", ply, rank.Name, rank.Short, rank.Desc, rank.Derive, rank.Immunity, rank.Color, rank.CanRemove )
		exsto.UMStart( "exsto_RecieveRankNoDerive", ply, rank.Short, rank.Flags_NoDerive )
	end
	
--[[ -----------------------------------
	Function: exsto.SendRanks
	Description: Sends all ranks down to a player.
     ----------------------------------- ]]	
	function exsto.SendRanks( ply )
		exsto.UMStart( "ExClearRanks", ply )
		for k,v in pairs( exsto.Levels ) do
			exsto.SendRank( ply, k )
		end
		exsto.UMStart( "exsto_BuildRanks", ply )
	end
	
--[[ -----------------------------------
	Function: exsto.SendTable
	Description: Sends a table down to a player.
     ----------------------------------- ]]	
	local currentHandles = {}
	function exsto.SendTable( ply, tbl, id )
		if !tonumber( id ) then exsto.ErrorNoHalt( "UMSG --> Cannot create a table send action with a non-numeric ID!" ) return end
		
		exsto.UMStart( "ExTblBegin", ply, id )
		
		-- Lets try this with glon now.
		local encode = glon.encode( tbl )
		
		for k,v in pairs( string.split( encode, 128 ) ) do
			exsto.UMStart( "ExTblSend", ply, id, v )
		end
	
		--[[for k,v in pairs( tbl ) do
			exsto.UMStart( "ExTblSend", ply, id, k, v )
		end]]
		
		exsto.UMStart( "ExTblEnd", ply, id )
		currentHandles[id] = nil
	end
	
	concommand.Add( "_TestTableSend", function( ply, _, args )
		exsto.UMStart( "_TestUMSG", ply, "Heres a string bro.", Vector( 10, 10, 10 ), { 23, "I'm a table!" } )
		//exsto.SendTable( ply, { "String Test", 13, Vector( 100, 100, 100 ) }, 24 )
	end )
	
	function string.split(str,d)
		local t = {}
		local len = str:len()
		local i = 0
		while i*d < len do
				t[i+1] = str:sub(i*d+1,(i+1)*d)
				i=i+1
		end
		return t
	end
	
--[[ -----------------------------------
	Function: exsto.CreateTableID
	Description: Creates an ID handle for the table send in UMSG.
     ----------------------------------- ]]	
	function exsto.CreateTableID()
		
		local id
		local function create()
			id = math.random( -128, 128 )
			
			if id == 0 then create() end
			if id >= 0 and id <= #exsto.UMSG - 1 then create() end
			if currentHandles[id] then create() end
		end
		create()
		
		-- Insert his ID into the current handles list.
		currentHandles[id] = true
		return id
	end
	
--[[ -----------------------------------
	Function: exsto.ParseUMType
	Description: Parses data sent to exsto.UMStart and creates the correct data send.
     ----------------------------------- ]]	
	function exsto.ParseUMType( ply, data )
		local format = type( data )
		local id, tblInfo
		
		//exsto.Print( exsto_CONSOLE_DEBUG, "UMSG --> Creating UMSG package for data type '" .. format .. "'" )
		
		if format == "string" then
			umsg.Char( exsto.UMSG.STRING )
			umsg.String( data )
		elseif format == "Player" then
			umsg.Char( exsto.UMSG.ENTITY )
			umsg.Entity( data )
		elseif format == "boolean" then
			umsg.Char( exsto.UMSG.BOOLEAN )
			umsg.Bool( data )
		elseif format == "number" then
			
			-- Check if hes floating.
			if data % 1 != 0 then
				umsg.Char( exsto.UMSG.FLOAT )
				umsg.Float( data )
			else
				umsg.Char( exsto.UMSG.SHORT )
				umsg.Short( data )
			end
			
		elseif format == "Entity" then
			umsg.Char( exsto.UMSG.ENTITY )
			umsg.Entity( data )
		elseif format == "Angle" then
			umsg.Char( exsto.UMSG.ANGLE )
			umsg.Angle( data )
		elseif format == "Vector" then
			umsg.Char( exsto.UMSG.VECTOR )
			umsg.Vector( data )
		elseif format == "table" then
			if data.r then -- If we are a color, just simplify
				umsg.Char( exsto.UMSG.COLOR_BEGIN )
					umsg.Char( math.floor( data.r ) - 128 )
					umsg.Char( math.floor( data.g ) - 128 )
					umsg.Char( math.floor( data.b ) - 128 )
					umsg.Char( math.floor( data.a ) - 128 )
				umsg.Char( exsto.UMSG.COLOR_END )
			else
				umsg.Char( exsto.UMSG.TABLE_BEGIN )
				id = exsto.CreateTableID()
				umsg.Char( id )
					tblInfo = { ply, data, id }
			end
		elseif format == "nil" then
			umsg.Char( exsto.UMSG.NIL )
		else
			-- The format was used weird.
			exsto.Error( "UMSG --> Issue parsing data type '" .. format .. "'" )
		end
		
		if id then return tblInfo end
	end
	
--[[ -----------------------------------
	Function: exsto.UMStart
	Description: Sends a set of data to the client on a hook.
     ----------------------------------- ]]
	function exsto.UMStart( name, ply, ... )
		if type( name ) != "string" then exsto.ErrorNoHalt( "No name to send usermessage to!" ) return end
		if type( ply ) != "Player" and type( ply ) != "table" then exsto.ErrorNoHalt( "No player to send usermessage to!" ) return end
	
		local arg = {...}
		local nothing = false
		local tab, text, sendTable
		local num, players = exsto.MultiplePlayers( ply )
	
		if not arg then nothing = true end
		
		local function count( tbl )
			local num = 1
			for k,v in pairs( tbl ) do
				if type( v ) == "table" then num = num + count( v ) end
				num = num + 1
			end
			return num
		end
		
		for I = 1, num do
			ply = players[I]
			
			umsg.Start( name, ply )
				umsg.Char( #arg )
				
				if not nothing then
					for I = 1, #arg do			
						sendTable = exsto.ParseUMType( ply, arg[I] )
					end
				end
			umsg.End()
			
			if sendTable then
				exsto.SendTable( sendTable[1], sendTable[2], sendTable[3] )
			end
		end
	end
	
	local function UMSGQueue()
	
	end
	
end

if CLIENT then

--[[ -----------------------------------
	Function: exsto.UMHook
	Description: Hooks into a usermessage that recieves data.
     ----------------------------------- ]]
	function exsto.UMHook( name, func )
		if type( name ) != "string" then exsto.ErrorNoHalt( "No name specified for UM Hook!" ) return end
		if type( func ) != "function" then exsto.ErrorNoHalt( "No function callback for " .. name .. "!" ) return end

		local function um( um )
		
			local data = {}
			local ret, format, tblWait, tblID
			local num = um:ReadChar()
			
			for I = 1, num do
				
				format = um:ReadChar()
				
				if format == exsto.UMSG.STRING then
					ret = um:ReadString()
				elseif format == exsto.UMSG.FLOAT then
					ret = um:ReadFloat()
				elseif format == exsto.UMSG.SHORT then
					ret = um:ReadShort()
				elseif format == exsto.UMSG.LONG then
					ret = um:ReadLong()
				elseif format == exsto.UMSG.BOOLEAN then
					ret = um:ReadBool()
				elseif format == exsto.UMSG.ENTITY then
					ret = um:ReadEntity()
				elseif format == exsto.UMSG.VECTOR then
					ret = um:ReadVector()
				elseif format == exsto.UMSG.ANGLE then
					ret = um:ReadAngle()
				elseif format == exsto.UMSG.TABLE_BEGIN then
					tblID = um:ReadChar()
					ret = tblID
					tblWait = true
				elseif format == exsto.UMSG.COLOR_BEGIN then
					local r = um:ReadChar() + 128
					local g = um:ReadChar() + 128
					local b = um:ReadChar() + 128
					local a = um:ReadChar() + 128
					
					if um:ReadChar() == exsto.UMSG.COLOR_END then
						ret = Color( r, g, b, a )
					else
						ret = nil
					end
				elseif format == exsto.UMSG.NIL then
					ret = nil
				end
				
				table.insert( data, ret )
				
			end
			
			local function call()
				func( unpack( data ) )
				hook.Call( name )
			end
			
			if tblWait then
				-- We are waiting for a table.  Don't call our callback until we can peice togeather everything we need
				exsto.TableHook( tblID, function( tbl )

					for k,v in pairs( data ) do
						if v == tblID then data[k] = tbl break end
					end
					
					local function count( tbl )
						local num = 1
						for k,v in pairs( tbl ) do
							if type( v ) == "table" then num = num + count( v ) end
							num = num + 1
						end
						return num
					end
					
					call()
				end )
			else
				call()
			end
			
		end
		usermessage.Hook( name, um )
		
	end
	
	local dataProcess = {}
	local dataHooks = {}
	
	local noFunc = function() end
	
	function exsto.BeginTableRecieve( id )
		if !dataHooks[ id ] then
			dataHooks[ id ] = noFunc
		end
		dataProcess[id] = ""
	end
	exsto.UMHook( "ExTblBegin", exsto.BeginTableRecieve )
	
	function exsto.TableRecieve( id, encode )
		dataProcess[id] = dataProcess[id] .. encode
	end
	exsto.UMHook( "ExTblSend", exsto.TableRecieve )
	
	function exsto.EndTableRecieve( id )
		local decode = glon.decode( dataProcess[ id ] )
		dataHooks[ id ]( decode )
		dataProcess[ id ] = ""
	end
	exsto.UMHook( "ExTblEnd", exsto.EndTableRecieve )
	
	function exsto.TableHook( id, func )
		dataHooks[ id ] = func
	end
	
	exsto.UMHook( "_TestUMSG", function( str, vector, tbl )
		print( str, vector )
		PrintTable( tbl )
	end )
	
--[[ -----------------------------------
		Rank Recieving UMSGS
     ----------------------------------- ]]
	function exsto.ReceiveRanks( name, short, desc, derive, immunity, color, remove )
		exsto.LoadedLevels[short] = {
			Name = name,
			Desc = desc,
			Short = short,
			Color = color,
			Immunity = immunity,
			Flags = {},
			Flags_NoDerive = {},
			Derive = derive,
			CanRemove = remove,
		}
	end
	exsto.UMHook( "exsto_RecieveRanks", exsto.ReceiveRanks )
	
	function exsto.RecieveRankNoDerive( short, noderive )
		local rank = exsto.LoadedLevels[short]
		if !rank then print( "[EXSTO ERROR] UMSG --> Trying to insert flag data into unknown rank!" ) return end
		
		rank.Flags = noderive
	end
	exsto.UMHook( "exsto_RecieveRankNoDerive", exsto.RecieveRankNoDerive )
	
	local recieveType = ""
	local data = {}
	
	function exsto.StartFlagRecieve( type )
		if type == "flags" then
			exsto.Flags = {}
		elseif type == "index" then
			exsto.FlagIndex = {}
		end
		
		recieveType = type
	end
	exsto.UMHook( "ExStartFlag", exsto.StartFlagRecieve )
	
	function exsto.RecieveFlag( id, desc )
		data[ id ] = desc
	end
	exsto.UMHook( "ExRecFlag", exsto.RecieveFlag )
	
	function exsto.EndFlagRecieve()
		if recieveType == "flags" then
			exsto.Flags = data
		elseif recieveType == "index" then
			exsto.FlagIndex = data
		end
		
		data = {}
	end
	exsto.UMHook( "ExEndFlag", exsto.EndFlagRecieve )
	
	function exsto.RecieveRankErrors( errs )
		exsto.RankErrors = errs
	end
	exsto.UMHook( "ExRankErr", exsto.RecieveRankErrors )
	
	local function AddLevel( data )
		exsto.Levels[data.Short] = {
			Name = data.Name,
			Desc = data.Desc, -- lol
			Short = data.Short,
			Color = data.Color,
			Immunity = data.Immunity,
			Flags = data.Flags,
			Flags_NoDerive = data.Flags_NoDerive,
			Derive = data.Derive,
			CanRemove = data.CanRemove,
		}
	end
	
	local function RANK_Loaded( short )
		return exsto.Levels[short]
	end
	
	local function RANK_Derive( rank )
		local derive = exsto.LoadedLevels[rank]
		
		-- if for some reason he cant derive off of anything, lets just send back an empty table so he atleast exists.
		if !derive then return {} end
		
		//exsto.Print( exsto_CONSOLE, "RANKS --> DERIVE --> Deriving from " .. rank .. "!" )
		
		if !RANK_Loaded( rank ) then	
			local args = derive.Flags
			derive.Flags_NoDerive = table.Copy( args )
			local Derive = "NONE"
			
			if derive.Derive != "NONE" then
				Derive = derive.Derive
				local derive_flags = RANK_Derive( derive.Derive )
				
				for k,v in pairs( derive_flags ) do
					table.insert( args, v )
				end
				
			end
			
			derive.Flags = args

			AddLevel( derive )
			return exsto.Levels[derive.Short].Flags		

		else -- If we are loaded.
			return exsto.Levels[derive.Short].Flags
		end
	end
	
	// Builds the ranks after all data was recieved
	function exsto.BuildRanks()
		
		-- Loop through all ranks
		for k,v in pairs( exsto.LoadedLevels ) do
			
			local args = v.Flags
			v.Flags_NoDerive = table.Copy( args )
			local Derive = "NONE"
			
			if v.Derive != "NONE" then
				Derive = v.Derive
				local derive_flags = RANK_Derive( v.Derive )
				
				for k,v in pairs( derive_flags ) do
					table.insert( args, v )
				end

			end
			
			v.Flags = args
			
			AddLevel( v )
		end
		
	end
	exsto.UMHook( "exsto_BuildRanks", exsto.BuildRanks )
	
	function exsto.ClearRanks()
		exsto.Levels = {}
		exsto.LoadedLevels = {}
	end
	exsto.UMHook( "ExClearRanks", exsto.ClearRanks )
	
--[[ -----------------------------------
	Function: ReceiveCommands
	Description: Recieves the command data from server.
     ----------------------------------- ]]
	function exsto.RecieveCommands( commands )
		exsto.Commands = commands
		
		-- Legacy
		hook.Call( "exsto_ReceivedCommands" )
	end
	exsto.UMHook( "ExRecCommands", exsto.RecieveCommands )
	
end


