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
	 
	exstoInclude( "exsto/cl_derma.lua" )
	exstoInclude( "exsto/sh_tables.lua" )
	exstoInclude( "exsto/sh_umsg.lua" )
	exstoInclude( "exsto/sh_print.lua" )
	exstoInclude( "exsto/sh_data.lua" )
	exstoInclude( "exsto/cl_menu_skin.lua" )
	exstoInclude( "exsto/cl_menu.lua" )
	exstoInclude( "exsto/sh_access.lua" )
	exstoInclude( "exsto/sh_plugins.lua" )
	
	-- Init clientside items.
	exsto.LoadPlugins()
	exsto.InitPlugins( launchInit )
	
	local seconds = SysTime() - exsto.StartTime
	print( "----------------------------------------------" )
	print( "Exsto started in " .. math.floor( seconds ) .. " seconds!" )
	print( "----------------------------------------------" )