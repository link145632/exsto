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

local runningLocation = ""

--[[ -----------------------------------
	Function: exsto.RegisterPlugin
	Description: DEPRICATED: Registers a plugin into Exsto.
     ----------------------------------- ]]
function exsto.RegisterPlugin( plugin )
	if !plugin then exsto.ErrorNoHalt( "Trying to register nil plugin!" ) return end
	if !plugin.Enabled then exsto.Print( exsto_CONSOLE, "PLUGIN --> " .. plugin.Name .. " is not enabled!  Skipping!" ) return end
	
	plugin.Hooks = plugin.Hooks or {}
	
	exsto.Plugins[plugin.ID] = {
		ID = plugin.ID,
		Name = plugin.Name,
		Desc = plugin.Desc or plugin.Disc or "No Description",
		Owner = plugin.Owner,
		Experimental = plugin.Experimental or false,
		Enabled = plugin.Enabled or false,
		RunningLoc = runningLocation,
		Hooks = plugin.Hooks,
	}

	exsto.Print( exsto_CONSOLE, "PLUGIN --> Loading " .. plugin.Name .. " by " .. plugin.Owner .. "!" )
	
	for k,v in pairs( plugin.Hooks ) do
		exsto.AddHook( k, v, plugin )
	end
	
	-- Call the main!
	if plugin.Main then
		plugin:Main()
	end
	
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

	for k,v in pairs( exsto.PluginLocations ) do
		if !v then exsto.Error( "Issue initializing plugin, no location set!" ) return end
		runningLocation = v
		include( exsto.PlugLocation .. v )
		AddCSLuaFile( exsto.PlugLocation .. v )
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
	Function: exsto.AddHook
	Description: DEPRICATED: Adds a hook to a plugin.
     ----------------------------------- ]]
function exsto.AddHook( name, func, module )

	-- Construct the unique name.
	local id = module.ID .. "-" .. name
	
	exsto.Hooks[module.ID] = {}
	exsto.Hooks[module.ID]["Name"] = name
	exsto.Hooks[module.ID]["ID"] = id
	
	hook.Add( name, id, func )
	exsto.Print( exsto_CONSOLE_DEBUG, "PLUGIN --> " .. module.ID .. " --> Adding " .. name .. " hook!" )
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