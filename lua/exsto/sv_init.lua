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


-- Server Access
-- Pretty much Misc.

--[[ -----------------------------------
	Category:  Console Utils
     ----------------------------------- ]]
local console = _R.Entity

function console:Nick() if !self:IsValid() then return "Console" end end
function console:IsAllowed() if !self:IsValid() then return true end end
function console:IsSuperAdmin() if !self:IsValid() then return true end end
function console:IsAdmin() if !self:IsValid() then return true end end

--[[ -----------------------------------
	Category:  Player Extras
     ----------------------------------- ]]

function exsto.FindPlayer( ply )

	local ply = string.lower( ply )
	
	for k,v in pairs( player.GetAll() ) do
	
		local nick = string.lower( v:Nick() )
		
		print( nick, ply )
	
		if string.find( nick, ply, 1, true ) or nick == ply then
		
			return v 
			
		end
		
	end
	
	return -1
	
end

timer.Create( "Exsto_TagCheck", 1, 0, function()
	if ( !string.find( GetConVar( "sv_tags" ):GetString(), "Exsto" ) ) then
		RunConsoleCommand( "sv_tags", GetConVar( "sv_tags" ):GetString() .. ",Exsto" )
	end
end )
