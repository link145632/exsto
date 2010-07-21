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

-- Plugin Man
include( "exsto/sh_plugin_metatable.lua" )
if SERVER then AddCSLuaFile( "exsto/sh_plugin_metatable.lua" ) end

-- Variables
exsto.NumberHooks = 0
exsto.PluginSettings = {}
exsto.NeedSaved = {}
exsto.Plugins = {}
exsto.LoadedPlugins = {}
exsto.Hooks = {}
exsto.PlugLocation = "exsto/plugins/"

if SERVER then

--[[ -----------------------------------
	Function:  exsto.SendPluginSettings
	Description: Sends the plugin settings to a player.
     ----------------------------------- ]]
	function exsto.SendPluginSettings( ply )
		exsto.Print( exsto_CONSOLE_DEBUG, "PLUGINS --> Streaming plugin settings to " .. ply:Nick() )

		exsto.UMStart( "ExRecPlugSettings", ply, exsto.PluginSettings )
	end
	hook.Add( "exsto_InitSpawn", "exsto_StreamPluginSettingsList", exsto.SendPluginSettings )
	
elseif CLIENT then
	
--[[ -----------------------------------
	Function: IncommingHook
	Description: Recieves the server's plugin settings file.
     ----------------------------------- ]]
	function exsto.RecievePluginSettings( settings )
		exsto.ServerPlugSettings = settings
		
		-- Legacy
		hook.Call( "exsto_RecievedSettings" )
	end
	exsto.UMHook( "ExRecPlugSettings", exsto.RecievePluginSettings )

end

--[[ -----------------------------------
	Function: exsto.HookCall
	Description: Calls hooks for plugins.
     ----------------------------------- ]]
function exsto.HookCall( name, gm, ... )
	for _, plug in pairs( exsto.Plugins ) do
		if type( plug.Object[ name ] ) == "function" and !plug.Disabled and plug.Object.Info.Initialized then

			local data = { pcall( plug.Object[ name ], plug.Object, ... ) }
			
			-- data[1] == Status
			-- data[2] == Error or First Return
			-- data[3+] == Returns
			
			-- If we are returning something...

			if data[1] == true and data[2] != nil then
				table.remove( data, 1 )
				return unpack( data )
			elseif data[1] == false then -- It returned an error, catch it.
				exsto.ErrorNoHalt( "Hook '" .. name .. "' failed in plugin '" .. plug.ID .. "' error: " )
				exsto.ErrorNoHalt( data[2] )
				exsto.Plugins[ _ ].Disabled = true
			end
		end
	end
	
	return exsto_HOOKCALL( name, gm, ... )
end

--[[ -----------------------------------
	Function: exsto.LoadPlugins
	Description: Reads all the plugins from the plugin folder.
     ----------------------------------- ]]
function exsto.LoadPlugins()
	local plugins = file.FindInLua( exsto.PlugLocation .. "*.lua" )
	exsto.PluginLocations = plugins
end

--[[ -----------------------------------
	Function: exsto.InitPlugins
	Description: Initializes all the plugins that were loaded.
     ----------------------------------- ]]
function exsto.InitPlugins()

	exsto.PluginSettings = FEL.LoadSettingsFile( "exsto_plugin_settings" )

	local prefix, prefixFind
	for k,v in pairs( exsto.PluginLocations ) do
	
		prefixFind = string.find( v, "_" )
		
		if prefixFind then
		
			prefix = string.Left( v, prefixFind - 1 )
			
			-- If we are running as the client, only include plugins that are shared or clientside
			if CLIENT and ( prefix == "sh" or prefix == "cl" ) then
				include( exsto.PlugLocation .. v )
			elseif SERVER then
			
				-- If the prefix is shared, include and add please.
				if prefix == "sh" or prefix == "cl" then AddCSLuaFile( exsto.PlugLocation .. v ) end
				if prefix == "sh" or prefix == "sv" then include( exsto.PlugLocation .. v ) end
				
			end
			
		end
		
	end
	
	-- All are initialized.  Save the plugin table we have.
	if table.Count( exsto.NeedSaved ) >= 1 then
		table.Merge( exsto.PluginSettings, exsto.NeedSaved )
		FEL.CreateSettingsFile( "exsto_plugin_settings", exsto.PluginSettings )
		exsto.NeedSaved = {}
	end

end

--[[ -----------------------------------
	Function: exsto.UnloadAllPlugins
	Description: Unloads all hooks from plugins.
     ----------------------------------- ]]
function exsto.UnloadAllPlugins()
	exsto.NumberHooks = 0
	for k,v in pairs( exsto.Plugins ) do
		if v.Object then
			v.Object:Unload()
		else
			exsto.ErrorNoHalt( "PLUGIN --> " .. v.ID .. " --> This plugin is not up to date with the new plugin system!" )
		end
	end
end

--[[ -----------------------------------
	Function: exsto.EnablePlugin
	Description: Enables a plugin, then writes to the settings file.
     ----------------------------------- ]]
function exsto.EnablePlugin( plug )
	plug.Info.Disabled = false
	
	exsto.PluginSettings[plug.Info.ID] = true
	FEL.CreateSettingsFile( "exsto_plugin_settings", exsto.PluginSettings )
	
	plug:Register()
end

--[[ -----------------------------------
	Function: exsto.DisablePlugin
	Description: Disables a plugin, then writes to the settings file.
     ----------------------------------- ]]
function exsto.DisablePlugin( plug )
	plug.Info.Disabled = true
	
	exsto.PluginSettings[plug.Info.ID] = false
	FEL.CreateSettingsFile( "exsto_plugin_settings", exsto.PluginSettings )
	
	plug:Unload()
	plug:Register()
end

--[[ -----------------------------------
	Function: exsto.PluginStatus
	Description: Returns true if a plugin is disabled
     ----------------------------------- ]]
function exsto.PluginStatus( plug )
	for k,v in pairs( exsto.PluginSettings ) do
		if k == plug.Info.ID then return !v end
	end
	return false
end

--[[ -----------------------------------
	Function: exsto.PluginSaved
	Description: Returns true if a plugin has saved into the settings table.
     ----------------------------------- ]]
function exsto.PluginSaved( plug )
	for k,v in pairs( exsto.PluginSettings ) do
		if k == plug.Info.ID then return true end
	end
	return false
end

--[[ -----------------------------------
	Function: exsto.PluginDisabled
	Description: Returns true if a plugin is disabled.
     ----------------------------------- ]]
function exsto.PluginDisabled( plug )
	for k,v in pairs( exsto.PluginSettings ) do
		if k == plug.Info.ID and v == false then return true end
	end
	return false
end

--[[ -----------------------------------
	Function: exsto.GetPlugin
	Description: Returns the plugin's data object.
     ----------------------------------- ]]
function exsto.GetPlugin( id )
	for k,v in pairs( exsto.Plugins ) do
		if k == id then return v.Object end
	end
	return false
end

local function IsLoaded( ID )
	if exsto.GetPlugin( ID ) then return true end
end