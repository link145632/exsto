local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo( {
	Name = "Quick Menu",
	ID = "quick-menu",
	Desc = "A plugin that creates a quick menu page.",
	Owner = "Prefanatic",
} )

PLUGIN.NumberJoins = 0
PLUGIN.NumberLeaves = 0
PLUGIN.NumberKicks = 0
PLUGIN.NumberBans = 0
PLUGIN.NumberErrors = 0
PLUGIN.CommandCalls = 0
PLUGIN.NumberCommands = 0
PLUGIN.NumberQueries = 0
PLUGIN.NumberDataSend = 0
PLUGIN.ServerMaxPlayers = MaxPlayers()

if SERVER then

	function PLUGIN:ExInitSpawn( ply )
		self:SendInfo( ply )
	end
	
	-- We need to send out data to the client.  Do I have to do it?
	-- Args: server time, #exsto errors, number joins, number leaves, number kicks, number bans, number commands
	function PLUGIN:SendInfo( ply )
		exsto.UMStart( "ExQuickMenuData", ply, CurTime(),
			self.NumberErrors,
			self.NumberJoins,
			self.NumberLeaves,
			self.NumberKicks,
			self.NumberBans,
			self.NumberCommands,
			self.NumberQueries,
			self.NumberDataSend,
			self.ServerMaxPlayers
		)
	end
	
	function PLUGIN:ExDataSend( name, ply )
		self.NumberDataSend = self.NumberDataSend + 1
	end
	
	function PLUGIN:ExFELQuery( running )
		self.NumberQueries = self.NumberQueries + 1
		self:SendInfo( player.GetAll() )
	end
	
	function PLUGIN:ExCommandCalled( caller, command, args )
		if command == "kick" then
			self.NumberKicks = self.NumberKicks + 1
			self.NumberCommands = self.NumberCommands + 1
		elseif command == "ban" then
			self.NumberBans = self.NumberBans + 1
			self.NumberCommands = self.NumberCommands + 1
		else
			self.NumberCommands = self.NumberCommands + 1
		end
		self:SendInfo( player.GetAll() )
	end
	
	function PLUGIN:ExPrintCalled( enum, data )
		if enum == exsto_ERROR or enum == exsto_ERRORNOHALT then
			self.NumberErrors = self.NumberErrors + 1
			self:SendInfo( player.GetAll() )
		end
	end
	
	function PLUGIN:PlayerJoin( ply )
		self.NumberJoins = self.NumberJoins + 1
		self:SendInfo( player.GetAll() )
	end
	
	function PLUGIN:PlayerDisconnected( ply )
		self.NumberLeaves = self.NumberLeaves + 1
		self:SendInfo( player.GetAll() )
	end

elseif CLIENT then

	local function waitData( serverTime, errors, joins, leaves, kicks, bans, commands, queries, data, maxplys )
		PLUGIN.ServerStartTime = serverTime + 1 -- Give us a second for data transfer.
		PLUGIN.NumberErrors = errors
		PLUGIN.NumberJoins = joins
		PLUGIN.NumberLeaves = leaves
		PLUGIN.NumberKicks = kicks
		PLUGIN.NumberBans = bans
		PLUGIN.NumberCommands = commands
		PLUGIN.NumberQueries = queries
		PLUGIN.NumberDataSend = data
		PLUGIN.ServerMaxPlayers = maxplys
	end
	exsto.UMHook( "ExQuickMenuData", waitData )

	Menu:CreatePage( {
		Title = "Quick Menu",
		Short = "quickmenu",
		Default = true },
		function( panel )
			PLUGIN:Wait( panel )
		end
	)
	
	function PLUGIN:Wait( panel )
		if !exsto.Commands or table.Count( exsto.Commands ) == 0 then
			timer.Simple( 1, self.Wait, self, panel )
			return
		end
		
		self.Categories = {}
		
		for short, data in pairs( exsto.Commands ) do
			if data.QuickMenu then
				if !self.Categories[ data.Category ] then
					self.Categories[ data.Category ] = {}
				end
				
				local index = data.ReturnOrder
				table.remove( index, 1 )
				
				table.insert( self.Categories[ data.Category ], { Name = short, CallerID = data.CallerID, OptionalInfo = data.ExtraOptionals, OptionalIndex = index } )
			end
		end
		
		for category, data in pairs( self.Categories ) do
			table.SortByMember( self.Categories[ category ], "Name", true )
		end
		
		self:Build( panel )
	end
	
	function PLUGIN:Build( panel )
		
		local secondary = panel:RequestSecondary()
			secondary:Hide()
			
		-- Player List
		local playerListClick = function( self )
			panel.categoryList:SetVisible( true )
			secondary:Show()
		end
			
		local colorPlayerPanel = Menu:CreateColorPanel( 10, 5, ( panel:GetWide() / 4 ), panel:GetTall() - 15,  panel )
		panel.playerList = exsto.CreateComboBox( 5, 5, colorPlayerPanel:GetWide() - 10, colorPlayerPanel:GetTall() - 10,  colorPlayerPanel )
			local initems = {}
			panel.playerList.Build = function( self )
				local nicks = {}
				for _, item in ipairs( self.Items ) do
					if item:IsValid() then
						if !table.HasValue( initems, item:GetValue() ) then
							table.insert( initems, item:GetValue() )
						end
					end
				end
				
				for _, ply in ipairs( player.GetAll() ) do
					table.insert( nicks, ply:Nick() )
					
					if !table.HasValue( initems, ply:Nick() ) then
						panel.playerList:AddItem( ply:Nick() ).DoClick = playerListClick
					end
				end
				
				for _, item in ipairs( self.Items ) do
					if item:IsValid() then
						if !table.HasValue( nicks, item:GetValue() ) then
							self:RemoveItem( item )
						end
					end
				end

			end
			panel.playerList:Build()
			
			panel.playerList.NextThink = 0
			panel.playerList.Think = function( self )
				if self.NextThink <= CurTime() then
					self.NextThink = CurTime() + 1
					
					self:Build()
					
					if !self.m_pSelected then return end
					if !self.m_pSelected:IsValid() then
						self:SelectByName( "" )
						return
					end
					
					local selected = self.m_pSelected:GetValue()
					self:SelectByName( selected )
				end
			end
			
		-- Category List
		panel.categoryList = exsto.CreatePanelList( 10, 10, secondary:GetWide() - 20, secondary:GetTall() - 20, 5, false, true, secondary )
			panel.categoryList.m_bBackground = false
			-- Insert our categories in there.
			for category, data in pairs( PLUGIN.Categories ) do
				local button = exsto.CreateButton( 0, 0, 70, 28, category )
					button:SetStyle( "secondary" )
					button.Category = category
					button.DoClick = function( self )
						local ply = panel.playerList.m_pSelected
						if ply then
						
							panel.categoryList:SetVisible( false )
							panel.commandList:SetVisible( true )
							panel.commandListBack:SetVisible( true )
							panel.commandList:Build( self.Category )
							
						end
					end
				panel.categoryList:AddItem( button )
			end
			panel.categoryList:SetVisible( true )
			
		-- Command List
		panel.commandList = exsto.CreateComboBox( 10, 10, secondary:GetWide() - 20, secondary:GetTall() - 50, secondary )
			panel.commandList.NextPress = CurTime()
			panel.commandList.CurrentCommand = nil
			panel.commandList:SetVisible( false )
			panel.commandList.Build = function( self, category )
				self:Clear()
				self.CurrentCategory = category
				for _, data in ipairs( PLUGIN.Categories[ category ] ) do
					local obj = self:AddItem( data.Name )
						obj.CallerID = data.CallerID
						obj.OptionalInfo = data.OptionalInfo
						obj.OptionalIndex = data.OptionalIndex
						
						obj.DoClick = function( self )
							if CurTime() <= panel.commandList.NextPress then return end
							panel.commandList.NextPress = CurTime() + 0.2
							
							panel.commandList.CallerID = self.CallerID
							panel.commandList.OptionalInfo = self.OptionalInfo
							panel.commandList.OptionalIndex = self.OptionalIndex
							panel.commandList.ReturnData = { panel.playerList.m_pSelected:GetValue() }
							
							-- If we have an awaiting optional.
							if #self.OptionalIndex >= 1 then
								panel.commandListExecute:SetVisible( true )
								
								panel.commandList.CurrentOptionalIndex = 1
								panel.commandList:OptionalFill( obj.OptionalInfo[ self.OptionalIndex[ panel.commandList.CurrentOptionalIndex ] ] )
							else
								panel.commandList:Execute()
							end
						end
				end
			end
			
			panel.commandList.OptionalFill = function( self, data )
				self:Clear()
				self.OnMainList = false
				for _, info in ipairs( data ) do
					local obj = self:AddItem( info.Display )
						obj.Data = info.Data
						obj.Display = info.Display
						
						obj.DoClick = function( self )
							if CurTime() <= panel.commandList.NextPress then return end
							panel.commandList.NextPress = CurTime() + 0.2
							
							table.insert( panel.commandList.ReturnData, tostring( self.Data or self.Display ) )
							
							panel.commandList.CurrentOptionalIndex = panel.commandList.CurrentOptionalIndex + 1
							local nextData = panel.commandList.OptionalInfo[ panel.commandList.OptionalIndex[ panel.commandList.CurrentOptionalIndex ] ]
							if nextData then
								panel.commandList:OptionalFill( nextData )
							else
								panel.commandList:Execute()
							end
						end
				end
			end
			
			panel.commandList.Clean = function( self )
				self.CallerID = nil
				self.OptionalInfo = {}
				self.OptionalIndex = {}
				self.ReturnData = {}
				
				self.OnMainList = true
				panel.commandListExecute:SetVisible( false )
				self:Build( self.CurrentCategory )
			end
			
			panel.commandList.Execute = function( self )
				RunConsoleCommand( self.CallerID, unpack( self.ReturnData ) )
				self:Clean()
			end
			
		panel.commandListBack = exsto.CreateButton( 10, secondary:GetTall() - 35, 70, 28, "Back", secondary )
			panel.commandListBack:SetStyle( "negative" )
			panel.commandListBack:SetVisible( false )
			panel.commandListBack.DoClick = function( self )
				
				if !panel.commandList.CurrentOptionalIndex or panel.commandList.OnMainList then
					panel.commandList.OnMainList = false
					
					self:SetVisible( false )
					panel.commandList:SetVisible( false )
					panel.categoryList:SetVisible( true )
					return
				end
				
				panel.commandList.CurrentOptionalIndex = panel.commandList.CurrentOptionalIndex - 1
				local prevData = panel.commandList.OptionalInfo[ panel.commandList.OptionalIndex[ panel.commandList.CurrentOptionalIndex ] ]
				if prevData then
					panel.commandList:OptionalFill( prevData )
				else
					panel.commandList:Clean()
				end
			end
			
		panel.commandListExecute = exsto.CreateButton( secondary:GetWide() - 75, secondary:GetTall() - 35, 70, 28, "OK", secondary )
			panel.commandListExecute:SetStyle( "positive" )
			panel.commandListExecute:SetVisible( false )
			panel.commandListExecute.DoClick = function( self )
				panel.commandList:Execute()
			end
			
		local exstoServerData = Menu:CreateColorPanel( 0, 5, panel:GetWide() - ( panel:GetWide() / 4 ) - 20, panel:GetTall() - 10, panel )
			exstoServerData:MoveRightOf( colorPlayerPanel, 5 )
			
		//panel.exstoNameVersion = exsto.CreateLabel( "center", 3, "Exsto running revision " .. exsto.VERSION, "exstoSecondaryButtons", exstoServerData  )
		panel.exstoDataContent = exsto.CreatePanel( 10, 5, exstoServerData:GetWide() - 20, exstoServerData:GetTall() - 25, nil, exstoServerData )
			panel.exstoDataContent.DrawColor = Color( 0, 0, 0, 255 )
			panel.exstoDataContent.Font = "default"
			panel.exstoDataContent.Paint = function( self )
				surface.SetFont( self.Font )
				
				local curY = 3
				for _, info in ipairs( self.DataDraw ) do
					
					surface.SetDrawColor( 202, 240, 168, 255 )
					surface.DrawRect( 0, curY, self:GetWide(), 26 )
					
					surface.SetDrawColor( 142, 245, 120, 255 )
					info.Max = info.Max or 1
					surface.DrawRect( 0, curY, self:GetWide() * math.Clamp( info.Value() / info.Max, 0, 1 ), 26 )
					
					surface.SetDrawColor( 16, 231, 0, 255 )
					surface.DrawOutlinedRect( 0, curY, self:GetWide(), 26 )
					
					draw.SimpleText( string.format( info.Message, info.Value(), info.Max ), self.Font, self:GetWide() / 2, curY + ( 26 / 2 ), self.DrawColor, 1, 1 )
					
					curY = curY + 30
				end
			end
			
			panel.exstoDataContent.DataDraw = {
				//{ Message = "Server Uptime: ", Value = function() return string.ToMinutesSeconds( PLUGIN.ServerStartTime + CurTime() ) end },
				{ Message = "%i Players out of %i", Value = function() return #player.GetAll() end, Max = PLUGIN.ServerMaxPlayers },
				{ Message = "%i Players joined so far", Value = function() return PLUGIN.NumberJoins end },
				{ Message = "%i Players left so far", Value = function() return PLUGIN.NumberLeaves end },
				{ Message = "%i Average ping", Value = function() return LocalPlayer():Ping() end },
				{ Message = "%i Exsto commands run", Value = function() return PLUGIN.NumberCommands end },
				{ Message = "%i Exsto kicks performed", Value = function() return PLUGIN.NumberKicks end },
				{ Message = "%i Exsto bans performed", Value = function() return PLUGIN.NumberBans end },
				{ Message = "%i Exsto Lua errors", Value = function() return PLUGIN.NumberErrors end },
				{ Message = "%i Exsto data packets sent", Value = function() return PLUGIN.NumberDataSend end },
				{ Message = "%i Exsto data queries performed", Value = function() return PLUGIN.NumberQueries end },
			}
		
		-- Animations
		Menu:CreateAnimation( panel.commandList )
		Menu:CreateAnimation( panel.categoryList )
		Menu:CreateAnimation( panel.commandListExecute )
		Menu:CreateAnimation( panel.commandListBack )
		
		panel.commandList:FadeOnVisible( true )
		panel.categoryList:FadeOnVisible( true )
		panel.commandListExecute:FadeOnVisible( true )
		panel.commandListBack:FadeOnVisible( true )
		
		panel.commandList:SetFadeMul( 4 )
		panel.categoryList:SetFadeMul( 4 )
		panel.commandListExecute:SetFadeMul( 4 )
		panel.commandListBack:SetFadeMul( 4 )
	end
end

PLUGIN:Register()