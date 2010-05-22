 -- Exsto
 -- Reload Plugin Plugin (lol)

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Reload Plugin",
	ID = "reloadplug",
	Desc = "A plugin that allows reloading of other plugins!",
	Owner = "Prefanatic",
} )
 
if not SERVER then return end

function PLUGIN.ReloadPlug( ply, plugname )

	local done = false

	-- Check and see if the plugin is already loaded.
	if exsto.PluginExists( plugname ) then
		local location = exsto.PlugLocation .. exsto.Plugins[ plugname ].Location
		exsto.KillPlug( plugname )
		
		include( location )
		AddCSLuaFile( location )
		
		done = true
		
	elseif exsto.PluginExistsLoc( plugname ) then
		local location = exsto.PlugLocation .. exsto.PluginLocations[ plugname ]
		exsto.KillPlug( plugname )
		
		include( location )
		AddCSLuaFile( location )
		
		done = true
		
	end
	
	if done then
		exsto.Print( exsto_CHAT_ALL, COLOR.PAC, "The plugin ", COLOR.RED, plugname, COLOR.PAC, " has been reloaded!" )
	else
		exsto.Print( exsto_CHAT_ALL, COLOR.PAC, "The plugin ", COLOR.RED, plugname, COLOR.PAC, " was not found!" )
	end
	
end
PLUGIN:AddCommand( "reloadplug", {
	Call = PLUGIN.ReloadPlug,
	Desc = "Reloads a plugin",
	FlagDesc = "Allows users to reload plugins.",
	Console = { "reloadplug" },
	Chat = { "!reloadplug" },
	Args = "STRING",
})

function PLUGIN.RefreshLocations( ply )

	exsto.LoadPlugins()
	
	exsto.Print( exsto_CHAT, ply, COLOR.PAC, "All plugin locations have been refreshed!" )
	
end
PLUGIN:AddCommand( "refreshlocations", {
	Call = PLUGIN.RefreshLocations,
	Desc = "Refreshes plugin location",
	FlagDesc = "Allows users to update plugin locations.",
	Console = { "refreshpluglocations" },
	Chat = { "!refreshplugloc" },
	Args = "",
})

PLUGIN:Register()