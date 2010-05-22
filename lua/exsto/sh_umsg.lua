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

concommand.Add( "_PerformanceTest", function()
	for I = 1, 200 do
		exsto.Print( exsto_CHAT_ALL, COLOR.NORM, "We are testing some ", COLOR.EXSTO, "networking performance ", COLOR.RED, "!" )
	end
end )

	function exsto.UMStart( name, ply, ... )
		if type( name ) != "string" then exsto.Error( "No name to send usermessage to!" ) return end
		if type( ply ) != "Player" then exsto.Error( "No player to send usermessage to!" ) return end
	
		local arg = {...}
		local nothing = false
	
		if not arg then nothing = true end

		exsto.Print( exsto_CONSOLE, "Usermessage Parse " .. name .. " to " .. ply:Nick() .. " with " .. tostring( unpack( {...} ) or "nothing" ) )
	
		umsg.Start( name, ply )
		
			umsg.Short( #arg )
			
			if not nothing then
		
				for I = 1, #arg do
				
					-- Color to Text support.
					if type( arg[I] ) == "table" and arg[I].r then
						local text = exsto.ColorToText( arg[I] )
						
						if type( text ) == "string" then
							text = "[color." .. text .. "]"
						end
						
						arg[I] = text
					end
					
					local tab = glon.encode( arg[I] )
					
					umsg.String( tab )
					
				end
				
			end
			
		umsg.End()
		
	end
	
end

if CLIENT then

	function exsto.UMHook( name, func )
		if type( name ) != "string" then exsto.Error( "No name specified for UM Hook!" ) return end
		if type( func ) != "function" then exsto.Error( "No function callback for " .. name .. "!" ) return end

		local function um( UMSG )
		
			local data = {}
		
			local num = UMSG:ReadShort()
			
			for I = 1, num do
			
				local tab = glon.decode( UMSG:ReadString() )
				
				if type( tab ) == "string" then
					local colStart, colEnd, color = string.find( tab, "%[color%.([%a]-)%]" )
					if colStart and colEnd and color then
						tab = exsto.TextToColor( color )
					end
				end
				
				table.insert( data, tab )
				
			end
			
			func( unpack( data ) )
			
		end
		usermessage.Hook( name, um )
		
	end
	
end
