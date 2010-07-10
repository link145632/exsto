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

if !glon then require( "glon" ) end

local function split(str,d)
	local t = {}
	local len = str:len()
	local i = 0
	while i*d < len do
			t[i+1] = str:sub(i*d+1,(i+1)*d)
			i=i+1
	end
	return t
end

if SERVER then

	function exsto.SendRankErrors( ply )
		exsto.UMStart( "ExRankErr", exsto.RankErrors )
	end

--[[ -----------------------------------
	Function: exsto.SendFlags
	Description: Sends the flags table down to a client.
     ----------------------------------- ]]
	function exsto.SendFlags( ply )
		exsto.UMStart( "ExRecFlags", ply, exsto.Flags )
	end
	concommand.Add( "ll", exsto.SendFlags )

--[[ -----------------------------------
	Function: exsto.SendRank
	Description: Sends a single rank down to the client.
     ----------------------------------- ]]
	function exsto.SendRank( ply, short )
		local rank = exsto.Ranks[ short ]

		exsto.UMStart( "exsto_ReceiveRanks", ply, rank.Name, rank.Short, rank.Desc, rank.Derive, rank.Immunity, rank.Color, rank.CanRemove )
		exsto.UMStart( "exsto_ReceiveRankNoDerive", ply, rank.Short, rank.Flags )
		exsto.UMStart( "ExRecFlagRank", ply, rank.Short, rank.AllFlags )
	end
	
--[[ -----------------------------------
	Function: exsto.SendRanks
	Description: Sends all ranks down to a player.
     ----------------------------------- ]]	
	function exsto.SendRanks( ply )
		exsto.UMStart( "ExClearRanks", ply )
		for k,v in pairs( exsto.Ranks ) do
			exsto.SendRank( ply, k )
		end
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
		
		for k,v in pairs( split( encode, 128 ) ) do
			exsto.UMStart( "ExTblSend", ply, id, v )
		end

		exsto.UMStart( "ExTblEnd", ply, id )
		currentHandles[id] = nil
	end
	
--[[ -----------------------------------
	Function: exsto.CreateTableID
	Description: Creates an ID handle for the table send in UMSG.
     ----------------------------------- ]]	
	local function create()
		local id = math.random( -128, 128 )
		
		if id == 0 then create() end
		if id >= 0 and id <= #exsto.UMSG - 1 then create() end
		if currentHandles[id] then create() end
		
		return id
	end
	
	function exsto.CreateTableID()
		local id = create()
		
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
	Function: meta:Send
	Description: Sends data to a player object.
     ----------------------------------- ]]
	function _R.Player:Send( name, ... )
		exsto.UMStart( name, self, ... )
	end
	
--[[ -----------------------------------
	Function: exsto.UMStart
	Description: Sends a set of data to the client on a hook.
     ----------------------------------- ]]
	function exsto.UMStart( name, ply, ... )
		if type( name ) != "string" then exsto.ErrorNoHalt( "No name to send usermessage to!" ) return end
		if type( ply ) != "Player" and type( ply ) != "table" and type( ply ) != "CRecipientFilter" then exsto.ErrorNoHalt( "No player to send usermessage to!" ) return end
		
		hook.Call( "ExDataSend", nil, name, ply )

		local nothing = false
		local sendTable
		if not arg then nothing = true end
		
		local rp = RecipientFilter()
		if type( ply ) == "CRecipientFilter" then
			rp = ply
		elseif type( ply ) == "Player" then
			rp:AddPlayer( ply )
		elseif type( ply ) == "table" then
			for _, ply in ipairs( ply ) do
				rp:AddPlayer( ply )
			end
		end

		umsg.Start( name, rp )
			umsg.Char( #arg )
		
			if not nothing then
				for I = 1, #arg do			
					sendTable = exsto.ParseUMType( rp, arg[I] )
				end
			end
		umsg.End()
		
		if sendTable then
			exsto.SendTable( sendTable[1], sendTable[2], sendTable[3] )
		end
	end
	
	local dataProcess = {}
	local dataHooks = {}
	local id
	
	local noFunc = function() end
	
	function exsto.BeginClientReceive( _ply, _, args )
		id = args[1]
		if !dataHooks[ id ] then
			dataHooks[ id ] = noFunc
		end
		dataProcess[id] = { ply = _ply, data = "" }
	end
	concommand.Add( "_ExBeginSend", exsto.BeginClientReceive )
	
	function exsto.ClientReceive( ply, _, args )
		id = args[1]
		dataProcess[id].data = dataProcess[id].data .. args[2]
	end
	concommand.Add( "_ExSend", exsto.ClientReceive )
	
	function exsto.EndClientReceive( ply, _, args )
		id = args[1]
		local decode = glon.decode( dataProcess[ id ].data )
		dataHooks[ id ]( dataProcess[ id ].ply, decode )
		dataProcess[ id ] = nil
	end
	concommand.Add( "_ExEndSend", exsto.EndClientReceive )
	
	function exsto.ClientHook( id, func )
		dataHooks[ id ] = func
	end
	
	exsto.ClientHook( "TestHook", function( data )
		PrintTable( data )
	end )
	
end

if CLIENT then

--[[ -----------------------------------
	 Category: Client --> Server Sending.
	----------------------------------- ]]
	function exsto.SendToServer( hook, ... )
		RunConsoleCommand( "_ExBeginSend", hook )
		
		local encode = glon.encode( {...} )
		
		for _, splice in ipairs( split( encode, 128 ) ) do
			RunConsoleCommand( "_ExSend", hook, splice )
		end
		
		RunConsoleCommand( "_ExEndSend", hook )
	end
	
	concommand.Add( "testSend", function()
		exsto.SendToServer( "TestHook", "Hello Everyone!", { "I am", 1, true } )
	end )
	
--[[ -----------------------------------
	Function: exsto.UMHook
	Description: Hooks into a usermessage that Receives data.
     ----------------------------------- ]]
	local function call( data, name, func )
		func( unpack( data ) )
		hook.Call( name )
	end
	
	function exsto.UMHook( name, func )
		if type( name ) != "string" then exsto.ErrorNoHalt( "No name specified for UM Hook!" ) return end
		if type( func ) != "function" then exsto.ErrorNoHalt( "No function callback for " .. name .. "!" ) return end

		local function um( um )
		
			local data = {}
			local ret, format, tblWait, tblID, r, g, b, a
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
					r = um:ReadChar() + 128
					g = um:ReadChar() + 128
					b = um:ReadChar() + 128
					a = um:ReadChar() + 128
					
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
			
			if tblWait then
				-- We are waiting for a table.  Don't call our callback until we can peice togeather everything we need
				exsto.TableHook( tblID, function( tbl )

					for k,v in pairs( data ) do
						if v == tblID then data[k] = tbl break end
					end

					call( data, name, func )
				end )
			else
				call( data, name, func )
			end
			
		end
		usermessage.Hook( name, um )
		
	end
	
--[[ -----------------------------------
	 Category: Data Table Receiving
     ----------------------------------- ]]
	local dataProcess = {}
	local dataHooks = {}
	
	local noFunc = function() end
	
	function exsto.BeginTableReceive( id )
		if !dataHooks[ id ] then
			dataHooks[ id ] = noFunc
		end
		dataProcess[id] = ""
	end
	exsto.UMHook( "ExTblBegin", exsto.BeginTableReceive )
	
	function exsto.TableReceive( id, encode )
		dataProcess[id] = dataProcess[id] .. encode
	end
	exsto.UMHook( "ExTblSend", exsto.TableReceive )
	
	function exsto.EndTableReceive( id )
		local decode = glon.decode( dataProcess[ id ] )
		dataHooks[ id ]( decode )
		dataProcess[ id ] = ""
	end
	exsto.UMHook( "ExTblEnd", exsto.EndTableReceive )
	
	function exsto.TableHook( id, func )
		dataHooks[ id ] = func
	end
	
--[[ -----------------------------------
		Rank Receiving UMSGS
     ----------------------------------- ]]
	function exsto.ReceiveRanks( name, short, desc, derive, immunity, color, remove )
		exsto.Ranks[short] = {
			Name = name,
			Desc = desc,
			Short = short,
			Color = color,
			Immunity = immunity,
			Flags = {},
			AllFlags = {},
			Derive = derive,
			CanRemove = remove,
		}
	end
	exsto.UMHook( "exsto_ReceiveRanks", exsto.ReceiveRanks )
	
	function exsto.ReceiveRankFlags( short, flags )
		local rank = exsto.Ranks[short]
		if !rank then print( "[EXSTO ERROR] UMSG --> Trying to insert flag data into unknown rank!" ) return end
		
		rank.Flags = flags
	end
	exsto.UMHook( "exsto_ReceiveRankNoDerive", exsto.ReceiveRankFlags )
	
	function exsto.ReceiveRankAllFlags( short, flags )
		local rank = exsto.Ranks[short]
		if !rank then print( "[EXSTO ERROR] UMSG --> Trying to insert flag data into unknown rank!" ) return end
		
		rank.AllFlags = flags
	end
	exsto.UMHook( "ExRecFlagRank", exsto.ReceiveRankAllFlags )

	function exsto.ReceiveRankErrors( errs )
		exsto.RankErrors = errs
	end
	exsto.UMHook( "ExRankErr", exsto.ReceiveRankErrors )
	
	function exsto.ClearRanks()
		exsto.Ranks = {}
		exsto.LoadedRanks = {}
	end
	exsto.UMHook( "ExClearRanks", exsto.ClearRanks )
	
--[[ -----------------------------------
	Function: receive
	Description: Receives flag data from the server.
     ----------------------------------- ]]
	local function receive( flags )
		exsto.Flags = flags
	end
	exsto.UMHook( "ExRecFlags", receive )
	
--[[ -----------------------------------
	Function: receive
	Description: Receives the command data from server.
     ----------------------------------- ]]
	local function receive( commands )
		exsto.Commands = commands
		
		-- Legacy
		hook.Call( "exsto_ReceivedCommands" )
	end
	exsto.UMHook( "ExRecCommands", receive )
	
end


