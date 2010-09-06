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
	Category:  Script Loading
     ----------------------------------- ]]
	 
	include( "exsto/cl_derma.lua" )
	include( "exsto/sh_tables.lua" )
	include( "exsto/sh_umsg_core.lua" )
	include( "exsto/sh_umsg.lua" )
	include( "exsto/sh_print.lua" )
	include( "exsto/fel.lua" )
	include( "exsto/cl_menu_skin.lua" )
	include( "exsto/cl_menu.lua" )
	include( "exsto/sh_access.lua" )
	include( "exsto/sh_plugins.lua" )
	
	-- Init clientside items.
	exsto.LoadPlugins()
	exsto.InitPlugins( launchInit )
	
	local seconds = SysTime() - exsto.StartTime
	print( "----------------------------------------------" )
	print( "Exsto started in " .. math.floor( seconds ) .. " seconds!" )
	print( "----------------------------------------------" )