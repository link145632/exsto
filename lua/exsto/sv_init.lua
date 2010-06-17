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
	Category:  Player Utils
     ----------------------------------- ]]
local ply = _R.Player

function ply:IsConsole() if !self:IsValid() then return false end end 

--[[ -----------------------------------
	Category:  Console Utils
     ----------------------------------- ]]
local console = _R.Entity

function console:Name() if !self:IsValid() then return "Console" end end
function console:Nick() if !self:IsValid() then return "Console" end end
function console:IsAllowed() if !self:IsValid() then return true end end
function console:IsSuperAdmin() if !self:IsValid() then return true end end
function console:IsAdmin() if !self:IsValid() then return true end end
function console:IsConsole() if !self:IsValid() then return true end end
function console:IsPlayer() if !self:IsValid() then return false end end

--[[ -----------------------------------
	Category:  Player Extras
     ----------------------------------- ]]
function exsto.MenuCall( id, func )
	concommand.Add( id, function( ply, command, args )
		if tonumber( ply.MenuAuthKey ) != tonumber( args[1] ) then return end
		table.remove( args, 1 )
		
		func( ply, command, args )
	end )
end

function exsto.BuildPlayerNicks()
	local tbl = {}
	
	for k,v in ipairs( player.GetAll() ) do
		table.insert( tbl, v:Nick() )
	end
	return tbl
end

function exsto.FindPlayer( ply )

	local newply = string.lower( ply )
	local nick
	
	for k,v in ipairs( player.GetAll() ) do
		nick = string.lower( v:Nick() )
		if v:UserID() == tonumber( ply  )then return v end
		if string.find( nick, newply, 1, true ) or nick == newply then
			return v 
		end
	end
	return ply
end

function exsto.GetPlayerByID( id )
	for k,v in ipairs( player.GetAll() ) do
		if v:SteamID() == id then return v end
	end
	return nil
end

timer.Create( "Exsto_TagCheck", 1, 0, function()
	if ( !string.find( GetConVar( "sv_tags" ):GetString(), "Exsto" ) ) then
		RunConsoleCommand( "sv_tags", GetConVar( "sv_tags" ):GetString() .. ",Exsto" )
	end
end )
