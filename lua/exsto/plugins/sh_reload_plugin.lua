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

	function PLUGIN:ReloadPlug( ply, plugname )
		local plug = exsto.Plugins[plugname]
		if !plug then return { ply, COLOR.NORM, "Could not find plugin ", COLOR.NAME, plugname, COLOR.NORM, ".  It doesn't exist!" } end
		
		plug.Object:Reload()
		
		return { COLOR.NORM, "Reloading plugin ", COLOR.NAME, plug.Name, COLOR.NORM, "!" }
	end
	PLUGIN:AddCommand( "reloadplug", {
		Call = PLUGIN.ReloadPlug,
		Desc = "Allows users to reload plugins.",
		Console = { "reloadplug" },
		Chat = { "!reloadplug" },
		ReturnOrder = "Plug",
		Args = { Plug = "STRING" },
		Category = "Utilities",
	})
	
	exsto.CreateFlag( "plugindisable", "Allows users to disable or enable plugins in the Plugin List page." )

	function PLUGIN.SendServerPlugins( ply )
	
		local plugins = {}
		local commands = {}
		for k,v in pairs( exsto.Plugins ) do
			if v.Object.Commands then
				for k,v in pairs( v.Object.Commands ) do
					table.insert( commands, { Chat = v.Chat, ID = v.ID } )
				end
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
	
	local function sort( a, b )
		return a.Name < b.Name
	end
	
	function PLUGIN.Build( panel )
	
		-- List view of the plugins.
		panel.pluginList = exsto.CreateComboBox( 10, 10, panel:GetWide() - 20, panel:GetTall() - 70, panel )
		
		-- Sort them nicely
		table.sort( plugins, sort )
		for k,v in ipairs( plugins ) do
		
			local obj = panel.pluginList:AddItem( " " )
				obj.PaintOver = function( self )
					draw.SimpleText( v.Name, "exstoPlyColumn", 5, self:GetTall() / 2, Color( 68, 68, 68, 255 ), 0, 1 )
					
					if self.OldIcon != self.Icon then
						self.IconID = surface.GetTextureID( self.Icon )
						self.OldIcon = self.Icon
					end

					surface.SetTexture( self.IconID )
					surface.SetDrawColor( 255, 255, 255, 255 )
					surface.DrawTexturedRect( panel.pluginList:GetWide() - 40, ( self:GetTall() / 2 ) - 8, 16, 16 )
				end
				if settings[v.ID] then
					obj.Icon = "icon_on"
				else
					obj.Icon = "icon_off"
				end
				
				if LocalPlayer():IsSuperAdmin() then
						obj.DoClick = function( self )
							if !LocalPlayer().PlugChange then LocalPlayer().PlugChange = CurTime() end
							if CurTime() < LocalPlayer().PlugChange then Menu:PushError( "Slow down, you are toggling plugins too fast!" ) return end
							
							LocalPlayer().PlugChange = CurTime() + 1
							
							if settings[v.ID] then
								-- We are trying to disable the plugin.
								
								settings[v.ID] = false
								
								Menu.CallServer( "_TogglePlugin", "false", v.ID )
								self.Icon = "icon_off"
							else
								-- Trying to enable it.
								
								settings[v.ID] = true

								Menu.CallServer( "_TogglePlugin", "true", v.ID )
								self.Icon = "icon_on"
							end
						end
				end
		end
		
	end

	Menu:CreatePage( {
		Title = "Plugin List",
		Short = "pluginlist",
		},
		function( panel )
			PLUGIN.ReloadData( panel )
		end
	)
	
end

PLUGIN:Register()