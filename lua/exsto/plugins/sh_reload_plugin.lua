 -- Exsto
 -- Reload Plugin Plugin (lol)

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Plugin Controls",
	ID = "plugcontrols",
	Desc = "A plugin that provides reloading support for plugins, and a plugin menu!",
	Owner = "Prefanatic",
} )

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
		local commands = {}
		for k,v in pairs( exsto.Plugins ) do
			for k,v in pairs( v.Object.Commands ) do
				table.insert( commands, { Chat = v.Chat, ID = v.ID } )
			end
			table.insert( plugins, {
				Name = v.Name,
				ID = k,
				Desc = v.Desc,
				Owner = v.Owner,
				Experimental = v.Experimental,
				Commands = commands,
			} )
			commands = {}
		end
		
		local send = { exsto.PluginSettings, plugins }
		
		exsto.UMStart( "ExSendPlugs", ply, send )
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
	
	function PLUGIN.RecievePlugins( data )
		settings = data[1]
		plugins = data[2]
		Menu.EndLoad()
	end
	exsto.UMHook( "ExSendPlugs", PLUGIN.RecievePlugins )
	
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
	
	function PLUGIN.GetProperSize( text, max, font )
		surface.SetFont( font )
		
		local w, h = surface.GetTextSize( text )
		if w < max then return w, h end
		
		local spaceW, spaceH = surface.GetTextSize( " " )
		local split = string.Explode( " ", text )
		local newW = 0
		local newH = 0
		
		for _, word in ipairs( split ) do
			w, h = surface.GetTextSize( word )
			newW = newW + w + spaceW
			
			if newW >= max then
				newW = 0
				newH = newH + h + 18
			end
		end

		return max, newH
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
	
	local function sort( a, b )
		return a.Name < b.Name
	end
	
	function PLUGIN.Build( panel )
	
		surface.SetFont( "exstoTitleMenu" )
	
		-- List view of the plugins.
		PLUGIN.PluginList = exsto.CreatePanelList( 10, 10, panel:GetWide() - 20, panel:GetTall() - 70, 5, false, true, panel )
		
		-- Sort them nicely
		table.sort( plugins, sort )
		for k,v in ipairs( plugins ) do

			-- Background panel for the layout
			local w, h = PLUGIN.GetProperSize( v.Desc, PLUGIN.PluginList:GetWide() * ( 6/9 ), "exstoTitleMenu" )
			
			local panel = exsto.CreateCollapseCategory( 0, 0, PLUGIN.PluginList:GetWide(), h + 40, v.Name )
				panel.Header.Font = "exstoPlyColumn"
				panel.Header.TextColor = Color( 68, 68, 68, 255 )
				panel.Color = Color( 224, 224, 224, 255 )
				panel.Header:SetWide( PLUGIN.PluginList:GetWide() )
				
			local container = exsto.CreatePanel( 0, 0, panel:GetWide(), panel:GetTall(), Color( 0, 0, 0, 0 ) )
			local descPanel = exsto.CreatePanel( 5, 0, container:GetWide() * ( 6/9 ), container:GetTall(), Color( 0, 0, 0, 0 ), container )
			local divider = exsto.CreatePanel( descPanel:GetWide() + 5, 0, 3, descPanel:GetTall(), Color( 0, 0, 0, 70 ), container )
			local commandList = exsto.CreatePanel( descPanel:GetWide() + 8, 0, container:GetWide() - descPanel:GetWide() - 8, container:GetTall(), Color( 0, 0, 0, 0 ), container )
			
			local label = exsto.CreateLabel( 5, 0, v.Desc, "exstoTitleMenu", descPanel )
				label:SetSize( w, h )
				label:SetWrap( true )
				label:SetTextColor( Color( 68, 68, 68, 255 ) )

			label = exsto.CreateLabel( 5, descPanel:GetTall() - 15, "Created by: " .. v.Owner, "exstoDataLines", descPanel )
				label:SizeToContents()
				label:SetWrap( true )
				label:SetTextColor( Color( 68, 68, 68, 255 ) )
				
				
			local command = exsto.CreateLabel( 5, 0, "Commands:", "default", commandList )
			local col = Color( 68, 68, 68, 255 )
			command:SetTextColor( col )
			local h = 13
			local x = 5
			for k,v in ipairs( v.Commands ) do
			
				if h >= commandList:GetTall() - 10 then
					x = 70
					h = 0
				end
				
				for k,v in ipairs( v.Chat ) do
					command = exsto.CreateLabel( x, h, v, "default", commandList )
					command:SetTextColor( col )
					h = h + 13
				end
			end
			
			if LocalPlayer():IsSuperAdmin() then
				-- Create the button for enabling
				local button = exsto.CreateButton( panel.Header:GetWide() - 90, 0 / 2, 60, panel.Header:GetTall(), "Disable", panel.Header )
					PLUGIN.SetButton( button, settings[v.ID] )
					
					button.DoClick = function( self )
						if !LocalPlayer().PlugChange then LocalPlayer().PlugChange = CurTime() end
						if CurTime() < LocalPlayer().PlugChange then Menu.PushError( "Slow down, you are toggling plugins too fast!" ) return end
						
						LocalPlayer().PlugChange = CurTime() + 1
						
						if settings[v.ID] then
							-- We are trying to disable the plugin.
							
							settings[v.ID] = false
							
							Menu.CallServer( "_TogglePlugin", "false", v.ID )
							PLUGIN.SetButton( self, false )
						else
							-- Trying to enable it.
							
							settings[v.ID] = true

							Menu.CallServer( "_TogglePlugin", "true", v.ID )
							PLUGIN.SetButton( self, true )
						end
					end
			end
			
			-- Add the plugin into the list
			panel:SetContents( container )
			PLUGIN.PluginList:AddItem( panel )
			
			if v.Disabled then
				panel:SetExpanded( true )
			end
		
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