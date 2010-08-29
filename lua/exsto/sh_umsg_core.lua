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

if SERVER then

	-- Data sender stuff.
	local sender = {}
		sender.__index = sender

--[[ -----------------------------------
	Function: exsto.CreateSender
	Description: Creates a sender object to work and send data to a client.
     ----------------------------------- ]]	
	function exsto.CreateSender( id, filter )
		local obj = {}
		setmetatable( obj, sender )
		
		obj:SetFilter( filter )
		obj.id = id or ""
		obj.buffer = {}
		obj.byteLimit = 200
		
		return obj
	end
	
	function sender:SetID( id )
		self.id = id
	end
	
	function sender:SetLimit( lim )
		self.byteLimit = lim
	end
	
	function sender:SetFilter( filter )
		local t = type( filter )
		if t == "CRecipientFilter" then
			self.filter = filter -- Our work is done for us.
		else
			local rp = RecipientFilter()
			if t == "Player" and filter:IsValid() then
				rp:AddPlayer( filter )
			elseif t == "table" then
				for _, ply in ipairs( filter ) do
					if type( ply ) == "Player" then rp:AddPlayer( ply ) end
				end
			elseif t == "string" and filter == "all" then
				rp:AddAllPlayers()
			end
			
			self.filter = rp
		end
	end
	
	function sender:AddChar( char )
		table.insert( self.buffer, char )
		if #self.buffer == self.byteLimit then
			self:Flush()
		end
	end
	
	function sender:AddString( str )
		for I = 1, str:len() do
			self:AddChar( str:sub( I, I ):byte() - 128 )
		end
		self:AddChar( 0 ) -- We need to know where to end
	end
	
	function sender:AddLong( num )
		num = num + 2147483648
		local a = math.modf( num / 16777216 ) num = num - a * 16777216
		local b = math.modf( num / 65536 ) num = num - b * 65536
		local c = math.modf( num / 256 ) num = num - c * 256
		local d = num

		self:AddChar( a - 128 )
		self:AddChar( b - 128 )
		self:AddChar( c - 128 )
		self:AddChar( d - 128 )
	end
	
	function sender:AddShort( num )
		num = ( num or 0 ) + 32768
		local int = math.modf( num / 256 )
		
		self:AddChar( int - 128 )
		self:AddChar( num - int * 256 - 128 )
	end
	
	function sender:AddBoolean( bool )
		self:AddChar( tobool( bool ) and 1 or 0 )
	end
	sender.AddBool = sender.AddBoolean
	
	function sender:AddEntity( ent )
		self:AddShort( ent:EntIndex() )
	end
	
	function sender:AddColor( col )
		self:AddChar( col.r - 128 )
		self:AddChar( col.g - 128 )
		self:AddChar( col.b - 128 )
		self:AddChar( col.a - 128 )
	end
	
	function sender:AddVariable( var )
		local t = type( var )
		if t == "number" then
			self:AddChar( 1 )
			self:AddShort( var )
		elseif t == "string" then
			self:AddChar( 2 )
			self:AddString( var )
		elseif t == "boolean" then
			self:AddChar( 3 )
			self:AddBool( var )
		elseif t == "table" and var.r and var.g and var.b then
			self:AddChar( 4 )
			self:AddColor( var )
		elseif t == "Entity" or t == "Player" then
			self:AddChar( 5 )
			self:AddEntity( var )
		elseif t == "nil" then
			self:AddChar( 0 )
		end
	end
	
	function sender:Flush()
		if #self.buffer == 0 then return end		
		local num = #self.buffer == self.byteLimit and self.byteLimit or #self.buffer

		umsg.Start( "ExBufferFlush", self.filter )
			umsg.Char( num - 128 )
			for I = 1, num do
				umsg.Char( self.buffer[ I ] )
			end
		umsg.End()
		
		self.buffer = {}
	end
	
	function sender:Send()
		if !self.filter then exsto.ErrorNoHalt( "UMSG --> Attempting to send without a filter!" ) return end
		if !self.id then exsto.ErrorNoHalt( "UMSG --> Attempting to send without ID!" ) return end

		self:Flush()
		
		umsg.Start( "ExBufferClear", self.filter )
			umsg.String( self.id )
		umsg.End()
		
		hook.Call( "ExDataSend", nil, self.id, self.filter )
	end
	
elseif CLIENT then

	-- Clientside buffer storage.
	local buffer = {}
	local reader_hooks = {}
	
	local reader = {}
		reader.__index = reader
	function exsto.CreateReader( id, func )
		local obj = {}
		
		setmetatable( obj, reader )
		obj.id = id
		obj.index = 0
		
		if type( func ) != "function" then return end
		obj.callback = function()
			local success, err = pcall( func, obj )
			if !success then
				exsto.ErrorNoHalt( "UMSG --> Error with umsg parse: " .. err )
			end
			obj:Cleanup()
		end
		
		if !reader_hooks[ id ] then reader_hooks[ id ] = {} end
		table.insert( reader_hooks[ id ], obj )
		
		return obj
	end

	function reader:ReadChar()
		self.index = self.index + 1
		return self.buffer[ self.index ]
	end
	
	function reader:ReadBoolean()
		return self:ReadChar() == 1
	end
	reader.ReadBool = reader.ReadBoolean
	
	function reader:ReadLong()
		local a = self:ReadChar() + 128
		local b = self:ReadChar() + 128
		local c = self:ReadChar() + 128
		local d = self:ReadChar() + 128
		
        return a * 16777216 + b * 65536 + c * 256 + d - 2147483648
	end
	
	function reader:ReadShort()
		return ( self:ReadChar() + 128 ) * 256 + self:ReadChar() + 128 - 32768
	end
	
	function reader:ReadString()
		local str = ""
		local byte = self:ReadChar()
		
		while byte != 0 do -- Baha never-ending.
			str = str .. string.char( byte + 128 )
			byte = self:ReadChar()
		end
		return str
	end
	
	function reader:ReadColor()
		return Color( self:ReadChar() + 128, self:ReadChar() + 128, self:ReadChar() + 128, self:ReadChar() + 128 )
	end
	
	function reader:ReadVariable()
		local t = self:ReadChar()
		if t == 1 then -- short
			return self:ReadShort()
		elseif t == 2 then -- string
			return self:ReadString()
		elseif t == 3 then -- bool
			return self:ReadBool()
		elseif t == 4 then -- color
			return self:ReadColor()
		elseif t == 5 then -- ent
			return Entity( self:ReadShort() )
		elseif t == 0 then -- nil
			return nil
		end
	end
	
	function reader:SetBuffer( buffer )
		self.buffer = buffer
	end
	
	function reader:Cleanup()
		self.buffer = {}
		self.index = 0
	end
	
	function reader:SetCallback( func )
		if type( func ) != "function" then return end
		self.callback = function()
			func( self )
			self:Cleanup()
		end
	end
	
	function reader:Callback()
		self.callback()
	end
	
	usermessage.Hook( "ExBufferFlush", function( um )
		for I = 1, um:ReadChar() + 128 do
			table.insert( buffer, um:ReadChar() )
		end
	end )
	
	usermessage.Hook( "ExBufferClear", function( um )
		local id = um:ReadString()
		if !reader_hooks[ id ] then exsto.ErrorNoHalt( "UMSG --> No usermessage exists for " .. id ) return end

		local readers = reader_hooks[ id ]
		for _, reader in ipairs( readers ) do
			reader:SetBuffer( buffer )
			reader:Callback()
		end
		
		hook.Call( id ) -- Call our lovelies
		
		buffer = {}
	end )
	
end
	
	