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
	print( "Created by " .. exsto.Info.Author )
	print( "Version " .. exsto.Info.Version )
	print( "-----------------------------" )

end

local function LoadVariables()

	exsto = {}
	exsto.Info = {}
		exsto.Info.Author = "Prefanatic"
		exsto.Info.Version = "PRIVATE 1.0"
	exsto.DebugEnabled = true
	
end

-- Is this smart?
local oldError = Error
local oldNoHalt = ErrorNoHalt

function Error( msg )
	if FEL then table.insert( FEL.ErrorTable, msg ) end
	return oldError( msg )
end

function ErrorNoHalt( msg )
	if FEL then table.insert( FEL.ErrorTable, msg ) end
	return oldNoHalt( msg )
end

function exstoInit()

	if exsto then
	
		exsto.Print( exsto_CHAT_ALL, COLOR.NORM, "Exsto is reloading the core!" )
		
		if exsto.Plugins then
			exsto.UnloadAllPlugins()
		end
		
	end			

	resource.AddFile("materials/exstoLogo.vmt")
	resource.AddFile("materials/exstoGradient.vmt" )
	resource.AddFile("materials/exstoGenericAnim.vmt" )
	resource.AddFile("materials/exstoErrorAnim.vmt" )

	LoadVariables()
	PrintLoading()
	
	include( "exsto/sh_tables.lua" )
	include( "exsto/sh_umsg.lua" )
	include( "exsto/sh_print.lua" )
	include( "exsto/sh_data.lua" )
	include( "exsto/sh_variables.lua" )
	
	if SERVER then
	
		include( "exsto/sv_init.lua" )
		include( "exsto/sv_commands.lua" )
		
		AddCSLuaFile( "exsto/sh_tables.lua" )
		AddCSLuaFile( "exsto/cl_derma.lua" )
		AddCSLuaFile( "exsto/sh_data.lua" )
		AddCSLuaFile( "exsto/sh_variables.lua" )
		AddCSLuaFile( "exsto/sh_umsg.lua" )
		AddCSLuaFile( "exsto/cl_menu.lua" )
		AddCSLuaFile( "exsto/sh_access.lua" )
		AddCSLuaFile( "exsto/sh_print.lua" )
		AddCSLuaFile( "exsto/sh_plugins.lua" )
		
	elseif CLIENT then
	
		include( "exsto/cl_derma.lua" )
		include( "exsto/cl_menu.lua" )
		
	end
	
	include( "exsto/sh_access.lua" )
	include( "exsto/sh_plugins.lua" )
	
	exsto.LoadPlugins()
	exsto.InitPlugins()
	if SERVER then exsto.LoadFlags() end
	
	
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
		
	end
	usermessage.Hook( "clexsto_load", init )

	local function ClientPreLoad()

		if LocalPlayer():IsValid() then
		
			LocalPlayer():ConCommand( "exsto_cl_load\n" )
			hook.Remove( "Think", "EXSTOCLIENTTHINK" )
			
		end
		
	end
	hook.Add( "Think", "EXSTOCLIENTTHINK", ClientPreLoad )

end

