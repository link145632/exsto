 -- Exsto
 -- Reload Plugin Plugin (lol)

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Plugin Controls",
	ID = "plugcontrols",
	Desc = "A plugin that provides reloading support for plugins, and a plugin menu!",
	Owner = "Prefanatic",
} )

require( "datastream" )
 
if SERVER then

	function PLUGIN.ReloadPlug( ply, plugname )
		local plug = exsto.Plugins[plugname]
		if !plug then return { ply, COLOR.NORM, "Could not find plugin ", COLOR.NAME, plugname, COLOR.NORM, ".  It doesn't exist!" } end
		
		plug.Object:Reload()
		
		return { COLOR.NORM, "Reloading plugin ", COLOR.NAME, plug.Name, COLOR.NORM, "!" }
	end
	PLUGIN:AddCommand( "reloadplug", {
		Call = PLUGIN.ReloadPlug,
		Desc = "Reloads a plugin",
		FlagDesc = "Allows users to reload plugins.",
		Console = { "reloadplug" },
		Chat = { "!reloadplug" },
		ReturnOrder = "Plug",
		Args = { Plug = "STRING" },
	})
	
	exsto.CreateFlag( "plugindisable", "Allows users to disable or enable plugins in the Plugin List page." )

	function PLUGIN.SendServerPlugins( ply )
	
		local plugins = {}
		for k,v in pairs( exsto.Plugins ) do
			plugins[k] = {
				Name = v.Name,
				ID = k,
				Desc = v.Desc,
				Owner = v.Owner,
				Experimental = v.Experimental,
			}
		end
		
		local send = { exsto.PluginSettings, plugins }
		
		datastream.StreamToClients( ply, "exsto_SendPlugins", send )
	end
	concommand.Add( "_SendPluginList", PLUGIN.SendServerPlugins )
	
	function PLUGIN.TogglePlugin( ply, _, args )

		if !ply:IsAllowed( "pluginlist" ) then return end
		if math.Round( tostring( args[1] ) ) != ply.MenuAuthKey then return end

		local style = tobool( args[2] )
		local short = args[3]
		
		local plugin = exsto.Plugins[short]
		if !plugin then return end
		
		if !ply.PlugChange then ply.PlugChange = CurTime() end
		if CurTime() < ply.PlugChange then return end
		
		ply.PlugChange = CurTime() + 1
		
		local settings = exsto.PluginSettings

		if style then 
			-- We are trying to enable him.
			exsto.EnablePlugin( plugin.Object )
			exsto.Print( exsto_CHAT_ALL, COLOR.NORM, "Enabling plugin ", COLOR.NAME, plugin.Name, COLOR.NORM, "!"  )
		else
			-- He needs to die.
			exsto.DisablePlugin( plugin.Object )
			exsto.Print( exsto_CHAT_ALL, COLOR.NORM, "Disabling plugin ", COLOR.NAME, plugin.Name, COLOR.NORM, "!"  )
		end	
		
		exsto.ResendCommands()

	end
	concommand.Add( "_TogglePlugin", PLUGIN.TogglePlugin )
	
elseif CLIENT then

	local settings = {}
	local plugins = {}
	
	local function IncommingHook( handler, id, encoded, decoded )
		settings = decoded[1]
		plugins = decoded[2]
		Menu.EndLoad()
	end
	datastream.Hook( "exsto_SendPlugins", IncommingHook )
	
	function PLUGIN.ReloadData( panel )
	
		settings = {}
		plugins = {}
		RunConsoleCommand( "_SendPluginList" )
		
		local function Ping()
			if table.Count( settings ) >= 1 then
				PLUGIN.Build( panel )
			else
				timer.Simple( 0.1, Ping )
			end
		end
		Ping()
		
	end
	
	function PLUGIN.SetButton( button, enabled )
		if enabled then
			button.Text = "Disable"
			button.Color = Color( 155, 228, 255, 255 )
			button.HoverCol = Color( 136, 199, 255, 255 )
			button.DepressedCol = Color( 156, 179, 255, 255 )
		else
			button.Text = "Enable"
			button.Color = Color( 255, 155, 155, 255 )
			button.HoverCol = Color( 255, 126, 126, 255 )
			button.DepressedCol = Color( 255, 106, 106, 255 )
		end
	end
	
	function PLUGIN.Build( panel )
	
		-- List view of the plugins.
		PLUGIN.PluginList = exsto.CreatePanelList( 10, 10, panel:GetWide() - 20, panel:GetTall() - 70, 5, false, true, panel )
		
		for k,v in pairs( plugins ) do
		
			-- Background panel for the layout
			local panel = exsto.CreatePanel( 0, 0, PLUGIN.PluginList:GetWide(), 35, Color( 224, 224, 224, 255 ) )
				panel.Paint = function( self )
					draw.RoundedBox( 4, 0, 0, self:GetWide(), self:GetTall(), Color( 224, 224, 224, 255 ) )
				end
			
			-- The label for the plugin name.
			local label = exsto.CreateLabel( 5, 5, v.Name, "exstoPlyColumn", panel )
				label:SetTextColor( Color( 0, 0, 0, 255 ) )
			
			if LocalPlayer():IsSuperAdmin() then
				-- Create the button for enabling
				local button = exsto.CreateButton( panel:GetWide() - 90, ( 35 - 27 ) / 2, 60, 27, "Disable", panel )
					PLUGIN.SetButton( button, settings[k] )
					
					button.DoClick = function( self )
						if !LocalPlayer().PlugChange then LocalPlayer().PlugChange = CurTime() end
						if CurTime() < LocalPlayer().PlugChange then Menu.PushError( "Slow down, you are toggling plugins too fast!" ) return end
						
						LocalPlayer().PlugChange = CurTime() + 1
						
						if settings[k] then
							-- We are trying to disable the plugin.
							
							settings[k] = false
							
							Menu.CallServer( "_TogglePlugin", "false", k )
							PLUGIN.SetButton( self, false )
						else
							-- Trying to enable it.
							
							settings[k] = true

							Menu.CallServer( "_TogglePlugin", "true", k )
							PLUGIN.SetButton( self, true )
						end
					end
			end
			
			-- Add the plugin into the list
			PLUGIN.PluginList:AddItem( panel )
		
		end
		
	end

	Menu.CreatePage( {
		Title = "Plugin List",
		Short = "pluginlist",
		Flag = "pluginlist",
		},
		function( panel )
			PLUGIN.ReloadData( panel )
		end
	)
	
end

PLUGIN:Register()