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

--[[-----------------------------------
	Function: exsto.SendRankErrors
	Description: Sends the rank errors to the client.
    ----------------------------------- ]]
	function exsto.SendRankErrors( ply )
		for short, data in pairs( exsto.RankErrors ) do
			local sender = exsto.CreateSender( "ExRecRankErr", ply )
				sender:AddString( short )
				sender:AddString( data[2] )
				sender:Send()
		end
	end

--[[ -----------------------------------
	Function: exsto.SendFlags
	Description: Sends the flags table down to a client.
     ----------------------------------- ]]
	function exsto.SendFlags( ply )
		exsto.CreateSender( "ExClearFlags", ply ):Send()
		
		local sender = exsto.CreateSender( "ExRecFlags", ply )
			sender:AddShort( table.Count( exsto.Flags ) )
			for name, desc in pairs( exsto.Flags ) do
				sender:AddString( name )
				sender:AddString( desc )
			end
			sender:Send()
	end
	concommand.Add( "_ResendFlags", exsto.SendFlags )

--[[ -----------------------------------
	Function: exsto.SendRank
	Description: Sends a single rank down to the client.
     ----------------------------------- ]]
	function exsto.SendRank( ply, short )
		local rank = exsto.Ranks[ short ]
		
		local sender = exsto.CreateSender( "ExRecRank", ply )
			sender:AddString( short )
			sender:AddString( rank.Name )
			sender:AddString( rank.Derive )
			sender:AddString( rank.Desc )
			sender:AddShort( rank.Immunity )
			sender:AddBool( rank.CanRemove )
			sender:AddColor( rank.Color )
			
			sender:AddShort( #rank.Flags )
			for _, flag in ipairs( rank.Flags ) do
				sender:AddString( flag )
			end
			
			sender:AddShort( #rank.AllFlags )
			for _, flag in ipairs( rank.AllFlags ) do
				sender:AddString( flag )
			end
			
			sender:Send()
	end
	
--[[ -----------------------------------
	Function: exsto.SendRanks
	Description: Sends all ranks down to a player.
     ----------------------------------- ]]	
	function exsto.SendRanks( ply )
		exsto.CreateSender( "ExClearRanks", ply ):Send()
		for k,v in pairs( exsto.Ranks ) do
			exsto.SendRank( ply, k )
		end
		exsto.CreateSender( "ExRecievedRanks", ply ):Send()
	end
	
--[[ -----------------------------------
	Function: meta:Send
	Description: Sends data to a player object.
     ----------------------------------- ]]
	function _R.Player:Send( name, ... )
		local sender = exsto.CreateSender( name, self )
			for _, var in ipairs( {...} ) do
				sender:AddVariable( var )
			end
			sender:Send()
	end
	
--[[-----------------------------------
	Function: meta:QuickSend
	Description: Sends a usermessage to a player with no data.
    ----------------------------------- ]]
	function _R.Player:QuickSend( name )
		self:Send( name )
	end
	
--[[-----------------------------------
	Category: Client --> Server Sending.
    ----------------------------------- ]]
	
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
		
		if hook.Call( "ExClientData", nil, id, dataProcess[ id ].ply, decode ) == false then return end
		dataHooks[ id ]( dataProcess[ id ].ply, decode )
		dataProcess[ id ] = nil
	end
	concommand.Add( "_ExEndSend", exsto.EndClientReceive )
	
	function exsto.ClientHook( id, func )
		dataHooks[ id ] = func
	end
	
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
	
--[[ -----------------------------------
		Rank Receiving UMSGS
     ----------------------------------- ]]
	local function recieve( reader )
		local short = reader:ReadString()
		exsto.Ranks[ short ] = {
			Name = reader:ReadString(),
			Short = short,
			Derive = reader:ReadString(),
			Desc = reader:ReadString(),
			Immunity = reader:ReadShort(),
			CanRemove = reader:ReadBool(),
			Color = reader:ReadColor(),
		}
		
		exsto.Ranks[ short ].Flags = {}
		for I = 1, reader:ReadShort() do
			table.insert( exsto.Ranks[ short ].Flags, reader:ReadString() )
		end
		
		exsto.Ranks[ short ].AllFlags = {}
		for I = 1, reader:ReadShort() do
			table.insert( exsto.Ranks[ short ].AllFlags, reader:ReadString() )
		end
	end
	exsto.CreateReader( "ExRecRank", recieve )

	function exsto.ReceiveRankErrors( reader )
		if !exsto.RankErrors then exsto.RankErrors = {} end
		exsto.RankErrors[ reader:ReadString() ] = reader:ReadString()
	end
	exsto.CreateReader( "ExRecRankErr", exsto.ReceiveRankErrors )
	
	local function recieve()
		exsto.Ranks = {}
		exsto.LoadedRanks = {}
	end
	exsto.CreateReader( "ExClearRanks", recieve )
	
	function exsto.RecievedRanks()
	end
	exsto.CreateReader( "ExRecievedRanks", exsto.RecievedRanks )
	
--[[ -----------------------------------
	Function: receive
	Description: Receives flag data from the server.
     ----------------------------------- ]]
	local function receive( reader )
		for I = 1, reader:ReadShort() do
			exsto.Flags[ reader:ReadString() ] = reader:ReadString()
		end
	end
	exsto.CreateReader( "ExRecFlags", receive )
	
	local function clear()
		exsto.Flags = {}
	end
	exsto.CreateReader( "ExClearFlags", clear )
	
--[[ -----------------------------------
	Function: receive
	Description: Receives the command data from server.
     ----------------------------------- ]]
	local function receive( reader )
		local id = reader:ReadString()
		
		if !exsto.Commands then exsto.Commands = {} end
		
		exsto.Commands[ id ] = {
			ID = id,
			Desc = reader:ReadString(),
			Category = reader:ReadString(),
			QuickMenu = reader:ReadBool(),
			CallerID = reader:ReadString()
		}

		exsto.Commands[ id ].Args = {}
		for I = 1, reader:ReadShort() do
			exsto.Commands[ id ].Args[ reader:ReadString() ] = reader:ReadString()
		end
		
		exsto.Commands[ id ].ReturnOrder = {}
		for I = 1, reader:ReadShort() do
			table.insert( exsto.Commands[ id ].ReturnOrder, reader:ReadString() )
		end
		
		exsto.Commands[ id ].Optional = {}
		for I = 1, reader:ReadShort() do
			exsto.Commands[ id ].Optional[ reader:ReadString() ] = reader:ReadVariable()
		end
		
		exsto.Commands[ id ].Console = {}
		for I = 1, reader:ReadShort() do
			table.insert( exsto.Commands[ id ].Console, reader:ReadString() )
		end
		
		exsto.Commands[ id ].Chat = {}
		for I = 1, reader:ReadShort() do
			table.insert( exsto.Commands[ id ].Chat, reader:ReadString() )
		end
		
		exsto.Commands[ id ].ExtraOptionals = {}
		for I = 1, reader:ReadShort() do
			local name = reader:ReadString()
			exsto.Commands[ id ].ExtraOptionals[ name ] = {}
			for I = 1, reader:ReadShort() do
				table.insert( exsto.Commands[ id ].ExtraOptionals[ name ], { Display = reader:ReadString(), Data = reader:ReadVariable() } )
			end
		end
		
		-- Legacy
		hook.Call( "exsto_ReceivedCommands" )
	end
	exsto.CreateReader( "ExRecCommands", receive )

end


