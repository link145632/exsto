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
	
	obj.Info = {}
	obj.Commands = {}
	--obj.Hooks = {}
	--obj.HookID = {}
	obj.FEL = {}
	obj.FEL.CreateTable = {}
	obj.FEL.AddData = {}
	obj.Variables = {}
	obj.Overrides = {}
	
	-- Set defaults for info.
	obj.Info = {
		Name = "Unknown",
		Desc = "None Provided",
		Owner = "Unknown",
		Experimental = false,
		Disabled = false,
	}
	
	return obj
end

--[[ -----------------------------------
	Function: plugin:SetInfo
	Description: Sets the information of a plugin.
     ----------------------------------- ]]
function plugin:SetInfo( tbl )

	tbl.Name = tbl.Name or "Unknown"
	tbl.Desc = tbl.Desc or "None Provided"
	tbl.Experimental = tbl.Experimental or false
	tbl.Disabled = tbl.Disabled or false

	self.Info = tbl
end

--[[ -----------------------------------
	Function: plugin:Register
	Description: Registers the plugin with Exsto.
     ----------------------------------- ]]
local queuedPlugins = {}

hook.Add( "exsto_RecievedSettings", "exsto_CheckOnSettings", function()
	if table.Count( queuedPlugins ) >= 1 then	
		for k,v in pairs( queuedPlugins ) do v:Register() end	
	end
end )

function plugin:Register()

	-- Client checks, we need to make sure that the clientside plugin is enabled on the server.
	local clientEnd = false
	if CLIENT then
		if exsto.ServerPlugSettings then
			if exsto.ServerPlugSettings[self.Info.ID] == false then
				-- The server doesn't want this command to run, end it.
				clientEnd = true
			end
		else
			-- The settings seem to be non-existant.  Lets queue the plugins into a table, then enable them later.
			table.insert( queuedPlugins, self )
			return
		end
	end
	
	-- Check and see if we exist in the saved plugin table.
	if !exsto.PluginSaved( self ) then
		exsto.NeedSaved[self.Info.ID] = !self.Info.Disabled
	else
		
		-- We are saved, so lets check and see if we are disabled.
		if exsto.PluginDisabled( self ) or self.Info.Disabled or clientEnd then
			exsto.Print( exsto_CONSOLE, "PLUGIN --> Skipping loading plugin " .. self.Info.ID .. ".  Not Enabled." )
			
			-- We need to tell Exsto hes atleast disabled.
			exsto.Plugins[self.Info.ID] = {
				Name = self.Info.Name,
				Desc = self.Info.Desc,
				ID = self.Info.ID,
				Owner = self.Info.Owner,
				Experimental = self.Info.Experimental or false,
				Object = self,
				Disabled = true,
			}
	
			return
		end
		
	end
	
	--self:CreateGamemodeHooks()
	
	-- Tell Exsto we exist!
	exsto.Plugins[self.Info.ID] = {
		Name = self.Info.Name,
		Desc = self.Info.Desc,
		ID = self.Info.ID,
		Owner = self.Info.Owner,
		Experimental = self.Info.Experimental or false,
		Object = self,
		Disabled = false,
	}
	
	-- Construct the commands we requested.
	for k,v in pairs( self.Commands ) do
		if CLIENT then return end
		exsto.AddChatCommand( k, v )
	end
	
	-- Construct FEL tables.
	for k,v in pairs( self.FEL.CreateTable ) do
		if CLIENT then return end
		FEL.MakeTable( k, v )
	end 
	
	-- Insert requested FEL.AddData
	for k,v in pairs( self.FEL.AddData ) do
		if CLIENT then return end
		FEL.AddData( k, v )
	end
	
	-- Create variables requested
	for k,v in pairs( self.Variables ) do
		if CLIENT then return end
		exsto.AddVariable( v )
	end
	
	-- Init the overrides
	for k,v in pairs( self.Overrides ) do
		v.Table[v.Old] = self[v.New]
	end
	
	exsto.Print( exsto_CONSOLE, "PLUGIN --> Loading " .. self.Info.Name .. " by " .. self.Info.Owner .. "!" )
	
	self:Init()
	self.Info.Initialized = true
end

--[[ -----------------------------------
	Function: plugin:Unload
	Description: Unloads the plugin
     ----------------------------------- ]]
function plugin:Unload()

	exsto.Print( exsto_CONSOLE, "PLUGIN --> Unloading " .. self.Info.Name .. "!" )
	
	-- Remove the over-rides
	for k,v in pairs( self.Overrides ) do
		v.Table[v.Old] = v.Saved
	end
	
	-- Remove chat commands
	for k,v in pairs( self.Commands ) do
		exsto.RemoveChatCommand( k )
	end
	
	local info = self.Info
	info.Disabled = true
	
	self:SetInfo( info )
end

--[[ -----------------------------------
	Function: plugin:Reload
	Description: Reloads a plugin
     ----------------------------------- ]]
function plugin:Reload()
	self:Unload()
	self:Register()	
end

--[[ -----------------------------------
		Plugin Helper Functions
     ----------------------------------- ]]
function plugin:Print( enum, ... )
	exsto.Print( enum, ... )
end

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
	tbl.Plugin = self
	self.Commands[id] = tbl
end

function plugin:AddOverride( old, new, tbl )
	table.insert( self.Overrides, { Old = old, New = new, Table = tbl, Saved = tbl[old] } )
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
	local funcName = ""
	for k,v in pairs( self ) do
		if type( v ) == "function" and string.Left( k, 2 ) == "On" then
			-- Hopefully it is a hook.  He has that On prefix.
			funcName = string.sub( k, 3 )
			self.Hooks[ funcName ] = v
			self.HookID[ funcName ] = "ExPlug_" .. tostring( exsto.NumberHooks )
			hook.Add( funcName, self.HookID[ funcName ], self.Hooks[ funcName ] )
			exsto.NumberHooks = exsto.NumberHooks + 1
		end
	end
end

function plugin:Init()
end

	
	
