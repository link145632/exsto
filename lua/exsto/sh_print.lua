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


-- Printing Utilities.

-- Variables

exsto.PrintStyles = {}
exsto.TextStart = "[Exsto] "
exsto.ErrorStart = "[EXSTO ERROR]"

--[[ -----------------------------------
	Function: AddPrint
	Description: Adds printing styles.
     ----------------------------------- ]]
local function AddPrint( func, ply ) -- Func args depend on called.
	table.insert( exsto.PrintStyles, { enum = #exsto.PrintStyles + 1, func = func, meta = ply } )
	return #exsto.PrintStyles
end

exsto_CHAT = AddPrint( 
	function( ply, ... )
		if CLIENT then return end
		if {...} == nil then return end
		local arg = {...}
		if type( ply ) == "Entity" then -- It seems like we are going console.
			local str = ""
			for I = 1, #arg do
				if type( arg[I] ) == "string" then str = str .. arg[I] end
			end
			exsto.Print( exsto_CONSOLE, str )
			return
		end

		local sender = exsto.CreateSender( "ExChatPrint", ply )
			sender:AddShort( #arg )
			for I = 1, #arg do
				sender:AddVariable( arg[ I ] )
			end
			sender:Send()
	end, true
)
exsto_CHAT_NOLOGO = exsto_CHAT
	
exsto_CHAT_LOGO = AddPrint( 
	function( ply, ... )
		if CLIENT then return end
		
		exsto.Print( exsto_CHAT, ply, "[Exsto] ", unpack( {...} ) )
	end, true
)
	
exsto_CHAT_ALL = AddPrint( 
	function( ... )
		if CLIENT then return end
		exsto.Print( exsto_CHAT, "all", unpack( {...} ) )
	end
)

exsto_CHAT_ALL_LOGO = AddPrint(
	function( ... )
		if CLIENT then return end
		exsto.Print( exsto_CHAT_LOGO, "all", unpack( ... ) )
	end
)
	
exsto_CONSOLE = AddPrint( 
	function( msg, extra )
		print( msg )
	end
)
exsto_CONSOLE_NOLOGO = exsto_CONSOLE

exsto_CONSOLE_LOGO = AddPrint(
	function( msg, extra )
		print( exsto.TextStart .. msg )
	end
)
	
exsto_CONSOLE_DEBUG = exsto_CONSOLE
	
exsto_ERROR = AddPrint( 
	function( msg )
		local send = exsto.ErrorStart .. " " .. msg .. "\n" 

		if SERVER then
			for k,v in pairs( player.GetAll() ) do
				if v:IsSuperAdmin() then
					local sender = exsto.CreateSender( "ExClientErr", v )
						sender:AddString( send )
						sender:Send()
				end
			end
		end
		
		--debug.Trace()
		Error( send )
	end
)

exsto_ERRORNOHALT = AddPrint( 
	function( msg )
		local send = exsto.ErrorStart .. " " .. msg .. "\n" 

		if SERVER then
			for k,v in pairs( player.GetAll() ) do
				if v:IsSuperAdmin() then
				local sender = exsto.CreateSender( "ExClientErrNoHalt", v )
						sender:AddString( send )
						sender:Send()
					end
			end
		end
		
		--debug.Trace()
		ErrorNoHalt( send )
	end
)
	
exsto_CLIENT = AddPrint( 
	function( ply, msg )
		if CLIENT then return end
		if type( ply ) != "Player" and type( ply ) != "table" then -- It seems like we are going console.
			local str = ""
			for I = 1, #arg do
				str = str .. arg[I]
			end
			exsto.Print( exsto_CONSOLE, str )
			return
		end

		ply:PrintMessage( HUD_PRINTCONSOLE, msg )
	end, true
)
exsto_CLIENT_NOLOGO = exsto_CLIENT
	
exsto_CLIENT_LOGO = AddPrint( 
	function( ply, msg )
		if CLIENT then return end
		exsto.Print( exsto_CLIENT, ply, exsto.TextStart .. " " .. msg .. "\n" )
	end, true
)

exsto_CLIENT_ALL = AddPrint( 
	function( msg )
		if CLIENT then return end
		for _, ply in ipairs( player.GetAll() ) do
			exsto.Print( exsto_CLIENT, ply, msg )
		end
	end
)

exsto_CLIENT_ALL_LOGO = AddPrint( 
	function( msg )
		if CLIENT then return end
		for _, ply in ipairs( player.GetAll() ) do
			exsto.Print( exsto_CLIENT_LOGO, ply, msg )
		end
	end
)
	
--[[ -----------------------------------
	Function: exsto.Print
	Description: Prints a specific style.
     ----------------------------------- ]]
function exsto.Print( style, ... )
	if exsto.Ignore_Prints then return true end
	if style == nil then return end
	for k,v in pairs( exsto.PrintStyles ) do
		if style == v.enum then	
			//hook.Call( "ExPrintCalled", nil, style, {...} )
			return v.func( ... )		
		end	
	end
end

function _R.Entity.Print( self, style, ... )
	if style == exsto_CLIENT then
		print( {...} )
	elseif style == exsto_CHAT or style == exsto_CHAT_ALL or style == exsto_CHAT_NOLOGO then
		local build = ""
		for k,v in pairs( {...} ) do
			if type( v ) == "string" then
				build = build .. v .. " "
			elseif type( v ) == "Player" then
				build = build .. v:Name() .. " "
			end
		end
		print( build )
	end
end

function _R.Player.Print( ply, style, ... )

	for k,v in pairs( exsto.PrintStyles ) do
		if style == v.enum and v.meta then
			return v.func( ply, ... )
		end
	end
	
end

--[[ -----------------------------------
	Function: meta:CanPrint
	Description: Returns true if the object is a valid printing device.
     ----------------------------------- ]]
	function _R.Player.CanPrint( self ) return true end
	function _R.Entity.CanPrint( self ) return true end

--[[ -----------------------------------
	Function: exsto.IgnorePrints
	Description: Makes all prints ignored as a toggle.
     ----------------------------------- ]]
function exsto.IgnorePrints( ignore )
	exsto.Ignore_Prints = ignore
end

-- Helper Functions
function exsto.Error( msg )
	exsto.Print( exsto_ERROR, msg )
end

function exsto.ErrorNoHalt( msg )
	exsto.Print( exsto_ERRORNOHALT, msg )
end

if CLIENT then

--[[ -----------------------------------
		Printing Helpers
     ----------------------------------- ]]
	local function chatprint( reader )
		local data = {}
		for I = 1, reader:ReadShort() do
			table.insert( data, reader:ReadVariable() )
		end
		chat.AddText( unpack( data ) )
	end
	exsto.CreateReader( "ExChatPrint", chatprint )

	local function err( reader )
		Error( reader:ReadString()  )
	end
	exsto.CreateReader( "ExClientErr", err )
	
	local function err( reader )
		ErrorNoHalt( reader:ReadString() )
	end
	exsto.CreateReader( "ExClientErrNoHalt", err )
	
end
