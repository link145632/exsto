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

local plugin = {}

--[[ -----------------------------------
	Function: exsto.CreatePlugin
	Description: Creates a metatable plugin.
     ----------------------------------- ]]
function exsto.CreatePlugin()
	local obj = {}
	
	setmetatable( obj, plugin )
	plugin.__index = plugin
	
	plugin.Info = {}
	plugin.Commands = {}
	plugin.Hooks = {}
	plugin.HookID = {}
	plugin.FEL = {}
	plugin.FEL.CreateTable = {}
	plugin.FEL.AddData = {}
	plugin.Variables = {}
	
	-- Set defaults for info.
	plugin.Info = {
		Name = "Unknown",
		Desc = "None Provided",
		Owner = "Unknown",
		Experimental = false,
		Enabled = true,
	}
	
	return obj
end

--[[ -----------------------------------
	Function: plugin:SetInfo
	Description: Sets the information of a plugin.
     ----------------------------------- ]]
function plugin:SetInfo( tbl )
	self.Info = tbl
	self:CreateGamemodeHooks()
end

--[[ -----------------------------------
	Function: plugin:Register
	Description: Registers the plugin with Exsto.
     ----------------------------------- ]]
function plugin:Register()
	
	-- Check and see if we exist in the saved plugin table.
	if !exsto.PluginSaved( self ) or ( self.Info.Enabled != exsto.PluginStatus( self ) ) then
		exsto.NeedSaved[self.Info.ID] = self.Info.Enabled
	else
		
		-- We are saved, so lets check and see if we are disabled.
		if exsto.PluginDisabled( self ) or !self.Info.Enabled then
			exsto.Print( exsto_CONSOLE, "PLUGIN --> Skipping loading plugin " .. self.Info.ID .. ".  Not Enabled." )
			
			-- Remove all of our hooks
			for k,v in pairs( self.Hooks ) do
				local id = self.HookID[k]
				//print( "Removing ID " .. id )
				hook.Remove( k, id )
			end
	
			return
		end
		
	end
	
	-- Tell Exsto we exist!
	exsto.Plugins[self.Info.ID] = {
		Name = self.Info.Name,
		Desc = self.Info.Desc,
		ID = self.Info.ID,
		Owner = self.Info.Owner,
		Experimental = self.Info.Experimental or false,
		Object = self,
	}
	
	-- Construct the commands we requested.
	for k,v in pairs( self.Commands ) do
		exsto.AddChatCommand( k, v )
	end
	
	-- Construct FEL tables.
	for k,v in pairs( self.FEL.CreateTable ) do
		FEL.MakeTable( k, v )
	end 
	
	-- Insert requested FEL.AddData
	for k,v in pairs( self.FEL.AddData ) do
		FEL.AddData( k, v )
	end
	
	-- Create variables requested
	for k,v in pairs( self.Variables ) do
		exsto.AddVariable( v )
	end
	
	exsto.Print( exsto_CONSOLE, "PLUGIN --> Loading " .. self.Info.Name .. " by " .. self.Info.Owner .. "!" )
	
	self:Init()
end

--[[ -----------------------------------
	Function: plugin:Unload
	Description: Unloads the plugin
     ----------------------------------- ]]
function plugin:Unload()

	-- Remove all of our hooks
	for k,v in pairs( self.Hooks ) do
		local id = self.HookID[k]
		hook.Remove( k, id )
	end
	
	-- Remove chat commands
	for k,v in pairs( self.Commands ) do
		exsto.RemoveChatCommand( k )
	end
	
end

--[[ -----------------------------------
	Function: plugin:Reload
	Description: Reloads a plugin
     ----------------------------------- ]]
function plugin:Reload()

	-- Re-add our hooks.
	self:CreateGamemodeHooks()
	
	-- Re-create our chat commands.
	for k,v in pairs( self.Commands ) do
		exsto.AddChatCommand( k, v )
	end
	
end

--[[ -----------------------------------
		Plugin Helper Functions
     ----------------------------------- ]]
function plugin:AddVariable( tbl )
	table.insert( self.Variables, tbl )
end

function plugin:CreateTable( id, tbl )
	self.FEL.CreateTable[id] = tbl
end

function plugin:AddData( id, tbl )
	self.FEL.AddData[id] = tbl
end

function plugin:AddCommand( id, tbl )
	self.Commands[id] = tbl
end

--[[ -----------------------------------
	Function: plugin:AddHook
	Description: Adds a hook to a plugin
     ----------------------------------- ]]
function plugin:AddHook( name, func )
	-- Construct the unique name.
	local id = self.Info.ID .. "-" .. name
	
	exsto.Hooks[self.Info.ID] = {}
	exsto.Hooks[self.Info.ID]["Name"] = name
	exsto.Hooks[self.Info.ID]["ID"] = id
	
	hook.Add( name, id, func )
	exsto.Print( exsto_CONSOLE_DEBUG, "PLUGIN --> " .. self.Info.ID .. " --> Adding " .. name .. " hook!" )
end

--[[ -----------------------------------
	Function: plugin:CreateGamemodeHooks
	Description: Creates a collection of pre-determined hooks for the plugin based on gamemode hooks.
     ----------------------------------- ]]
function plugin:CreateGamemodeHooks()
	for k,v in pairs( exsto.GMHooks ) do
		local function plugHook( ... )
			if !self["On"..v] then
				self["On"..v] = function( ... ) end
			end
			return self["On"..v]( self, ... )
		end
		self.Hooks[v] = plugHook
		self.HookID[v] = exsto.NumberHooks
		hook.Add( v, self.HookID[v], self.Hooks[v] )
		exsto.NumberHooks = exsto.NumberHooks + 1
	end
end

function plugin:Init()
end

	
	
