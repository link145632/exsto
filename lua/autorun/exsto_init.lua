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

AddCSLuaFile( "autorun/exsto_init.lua" )

local function PrintLoading()

	print( "-----------------------------" )
	print( "Exsto Loading" )
	print( "Created by Prefanatic" )
	print( "Revision " .. tostring( exsto.VERSION ) )
	print( "Please ignore all errors about modules unless you have that module installed." )
	print( "-----------------------------" )

end

local function LoadVariables()

	exsto = {}
	exsto.DebugEnabled = true
	exsto.StartTime = SysTime()
	
	exsto.VERSION = 54
end

function exstoInit()
	if exsto then
		if exsto.Print then
			exsto.Print( exsto_CHAT_ALL, COLOR.NORM, "Exsto is reloading the core!" )
		end
		if exsto.Plugins and exsto.RemoveChatCommand then
			exsto.UnloadAllPlugins()
		end
	end			

	LoadVariables()
	PrintLoading()
	
	if SERVER then
		include( "exsto/sv_init.lua" )
		AddCSLuaFile( "exsto/cl_init.lua" )
	elseif CLIENT then
		include( "exsto/cl_init.lua" )
	end
end

exsto_HOOKCALL = exsto_HOOKCALL or hook.Call
hook.Call = function( name, gm, ... )
	if !exsto or !exsto.Plugins or !exsto.HookCall then
		return exsto_HOOKCALL( name, gm, ... )
	end
	
	return exsto.HookCall( name, gm, ... )
end

if SERVER then
	exstoInit()
	
	concommand.Add( "exsto_cl_load", function( ply, _, args )
		umsg.Start( "clexsto_load", ply )
		umsg.End()
	end )
	
elseif CLIENT then

	local function init( UM )
		exstoInit()
		hook.Call( "ExInitialized" )
	end
	usermessage.Hook( "clexsto_load", init )

	function onEntCreated( ent )
		if LocalPlayer():IsValid() then
			LocalPlayer():ConCommand( "exsto_cl_load\n" )
			hook.Remove( "OnEntityCreated", "ExSystemLoad" )
		end
	end
	hook.Add( "OnEntityCreated", "ExSystemLoad", onEntCreated )
end