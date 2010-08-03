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

--[[ -----------------------------------
	Category:  Script Loading/Resources
     ----------------------------------- ]]
	resource.AddFile( "materials/exstoLogo.vmt" )
	resource.AddFile( "materials/exstoGradient.vmt" )
	resource.AddFile( "materials/exstoGenericAnim.vmt" )
	resource.AddFile( "materials/exstoErrorAnim.vmt" )
	resource.AddFile( "materials/exstoButtonGlow.vmt" )
	resource.AddFile( "materials/icon_locked.vmt" )
	resource.AddFile( "materials/icon_on.vmt" )
	resource.AddFile( "materials/icon_off.vmt" )

	exstoInclude( "exsto/sh_tables.lua" )
	exstoInclude( "exsto/sh_umsg.lua" )
	exstoInclude( "exsto/sh_print.lua" )
	exstoInclude( "exsto/sh_data.lua" )
	exstoInclude( "exsto/sv_variables.lua" )
	exstoInclude( "exsto/sv_commands.lua" )
	exstoInclude( "exsto/sh_access.lua" )
	exstoInclude( "exsto/sh_plugins.lua" )
	
	exstoAddCSLuaFile( "exsto/sh_tables.lua" )
	exstoAddCSLuaFile( "exsto/cl_derma.lua" )
	exstoAddCSLuaFile( "exsto/sh_data.lua" )
	exstoAddCSLuaFile( "exsto/sh_umsg.lua" )
	exstoAddCSLuaFile( "exsto/cl_menu_skin.lua" )
	exstoAddCSLuaFile( "exsto/cl_menu.lua" )
	exstoAddCSLuaFile( "exsto/sh_access.lua" )
	exstoAddCSLuaFile( "exsto/sh_print.lua" )
	exstoAddCSLuaFile( "exsto/sh_plugins.lua" )

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
	return exsto.FindPlayers( ply )[1] or nil
end

function exsto.FindPlayers( data, ply )

	local players = {}
	
	if data == "*" then return player.GetAll() end
	if data == "*-" and ply then
		players = player.GetAll()
		for _, _ply in ipairs( players ) do
			if _ply == ply then table.remove( players, _ ) break end
		end
	end
	if data == "[ALL]" then return player.GetAll() end
	
	-- Check rank styles
	for short, info in pairs( exsto.Ranks ) do
		if data:Replace( "%", "" ) == short then
			for _, ply in ipairs( player.GetAll() ) do
				if ply:GetRank() == short then table.insert( players, ply ) end
			end
		end
	end
	
	local splits = string.Explode( "-", data ) or 1
	for I = 1, #splits do
		data = splits[I]
		for _, ply in ipairs( player.GetAll() ) do
			if ply:EntIndex() == tonumber( data ) then table.insert( players, ply ) end
			if ply:UserID() == tostring( data ) then table.insert( players, ply ) end
			if string.find( ply:Nick():lower(), data:lower(), 1, true ) then table.insert( players, ply ) end
		end
	end
	
	return players
	
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

-- Init some items.
	exsto.LoadPlugins()
	exsto.InitPlugins()

	exsto.LoadFlags()
	exsto.CreateFlagIndex()
	
	local seconds = SysTime() - exsto.StartTime
	print( "----------------------------------------------" )
	print( "Exsto started in " .. math.floor( seconds ) .. " seconds!" )
	print( "----------------------------------------------" )