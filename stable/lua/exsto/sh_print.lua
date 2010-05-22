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

exsto_CHAT = 1
exsto_CONSOLE = 2
exsto_CONSOLE_DEBUG = 3
exsto_CHAT_ALL = 4
exsto_LOG = 5
exsto_LOG_ALL = 6
exsto_ERROR = 7
exsto_CHAT_NOLOGO = 8
exsto_CLIENT_ALL = 9
exsto_CLIENT = 10
exsto_ERRORNOHALT = 11
exsto_CLIENT_NOLOGO = 12

local function AddPrint( enum, func ) -- Func args depend on called.

	table.insert( exsto.PrintStyles, {enum = enum, func = func} )
	
end

AddPrint( exsto_LOG, function( ply, ... )
					if CLIENT then return end
					exsto.UMStart( "exsto_LogPrint", ply, unpack( {...} ) )
				end
		)
		
AddPrint( exsto_LOG_ALL, function( ... )
						if CLIENT then return end
						for k,v in pairs( player.GetAll() ) do
							exsto.Print( exsto_LOG, v, unpack( {...} ) )
						end
					end
		)

AddPrint( exsto_CHAT, function( ply, ... )
						if CLIENT then return end
						if type( ply ) != "Player" then return end
						exsto.UMStart( "exsto_ChatPrint", ply, COLOR.EXSTO, "[Exsto] ", unpack( {...} ) )
					end
		)
		
AddPrint( exsto_CHAT_NOLOGO, function( ply, ... )
						if CLIENT then return end
						if type( ply ) != "Player" then return end
						exsto.UMStart( "exsto_ChatPrint", ply, unpack( {...} ) )
					end
		)
		
AddPrint( exsto_CHAT_ALL, function( ... )
						if CLIENT then return end
						for k,v in pairs( player.GetAll() ) do
							exsto.Print( exsto_CHAT, v, unpack( {...} ) )
						end
					end
		)
		
AddPrint( exsto_CONSOLE,	function( msg )
								print( exsto.TextStart .. msg )
							end
		)
		
AddPrint( exsto_CONSOLE_DEBUG,	function( msg )
									if exsto.DebugEnabled then print( exsto.TextStart .. msg ) end
								end
		)
		
AddPrint( exsto_ERROR,	function( msg )
							local send = exsto.ErrorStart .. " " .. msg .. "\n" 
							
							if SERVER then
								for k,v in pairs( player.GetAll() ) do
									if v:IsSuperAdmin() then exsto.UMStart( "exsto_ClientERROR", v, send ) end
								end
							end
							
							//FEL.ErrorTable[ os.date( "%T -- %D" ) ] = msg
							
							Error( send )
						end
		)
		
AddPrint( exsto_ERRORNOHALT,	function( msg )
						local send = exsto.ErrorStart .. " " .. msg .. "\n" 
						
						if SERVER then
							for k,v in pairs( player.GetAll() ) do
								if v:IsSuperAdmin() then exsto.UMStart( "exsto_ClientERRORNoHalt", v, send ) end
							end
						end
						
						//FEL.ErrorTable[ os.date( "%T -- %D" ) ] = msg
						
						ErrorNoHalt( send )
					end
	)
		
AddPrint( exsto_CLIENT_ALL,	function( msg )
						if CLIENT then return end
						local send = exsto.TextStart .. " " .. msg .. "\n" 
						
						for k,v in pairs( player.GetAll() ) do
							if v:IsSuperAdmin() then exsto.UMStart( "exsto_ClientMSG", v, send ) end
						end
						
						print( send )
					end
	)
	
AddPrint( exsto_CLIENT,	function( ply, msg )
					if CLIENT then return end
							local send = exsto.TextStart .. " " .. msg .. "\n" 
							exsto.UMStart( "exsto_ClientMSG", ply, send )
					end
	)
	
AddPrint( exsto_CLIENT_NOLOGO,	function( ply, msg )
					if CLIENT then return end
							local send = msg .. "\n" 
							exsto.UMStart( "exsto_ClientMSG", ply, send )
					end
	)
		
concommand.Add( "_TestLog", function( ply, _, args ) exsto.Print( exsto_LOG_ALL, ply, Color( 100, 100, 100 ), " is a test!" ) end )
		
function exsto.Print( style, ... )

	if style == nil then exsto.Error( "Issue creating print command!" ) return end -- Weird bug?

	for k,v in pairs( exsto.PrintStyles ) do
	
		if style == v.enum then
		
			v.func( unpack( {...} ) )
			
		end
		
	end
	
end

concommand.Add( "_ChatTest", function( ply, _, args ) exsto.Print( exsto_CHAT, ply, Color( 255, 0, 0 ), "exsto", Color( 0, 255, 0 ), " is very ", Color( 0, 0, 255 ), "amazing!" ) end )

-- Helper Functions
function exsto.Error( msg )
	exsto.Print( exsto_ERROR, msg )
end

function exsto.ErrorNoHalt( msg )
	exsto.Print( exsto_ERRORNOHALT, msg )
end

if CLIENT then

	function exsto.ChatPrint( ... )

		chat.AddText( unpack( {...} ) )
		
	end
	exsto.UMHook( "exsto_ChatPrint", exsto.ChatPrint )
	
	local function msg( str )
		
		Msg( str )
		
	end
	exsto.UMHook( "exsto_ClientMSG", msg )
	
	local function err( str )
	
		Error( str )
		
	end
	exsto.UMHook( "exsto_ClientERROR", msg )
	
	local function err( str )
	
		ErrorNoHalt( str )
		
	end
	exsto.UMHook( "exsto_ClientERRORNoHalt", msg )
	
end
