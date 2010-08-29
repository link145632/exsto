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
		local sender = exsto.CreateSender( "ExQuickMenuData", ply )
			sender:AddShort( CurTime() )
			sender:AddShort( self.NumberErrors )
			sender:AddShort( self.NumberJoins )
			sender:AddShort( self.NumberLeaves )
			sender:AddShort( self.NumberKicks )
			sender:AddShort( self.NumberBans )
			sender:AddShort( self.NumberCommands )
			sender:AddShort( self.NumberQueries )
			sender:AddShort( self.NumberDataSend )
			sender:AddShort( self.ServerMaxPlayers )
			sender:Send()
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

	local function waitData( reader )
		PLUGIN.ServerStartTime = reader:ReadShort() + 1 -- Give us a second for data transfer.
		PLUGIN.NumberErrors = reader:ReadShort()
		PLUGIN.NumberJoins = reader:ReadShort()
		PLUGIN.NumberLeaves = reader:ReadShort()
		PLUGIN.NumberKicks = reader:ReadShort()
		PLUGIN.NumberBans = reader:ReadShort()
		PLUGIN.NumberCommands = reader:ReadShort()
		PLUGIN.NumberQueries = reader:ReadShort()
		PLUGIN.NumberDataSend = reader:ReadShort()
		PLUGIN.ServerMaxPlayers = reader:ReadShort()
	end
	exsto.CreateReader( "ExQuickMenuData", waitData )
	
	local function nullFunc() end

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
				
				local index = table.Copy( data.ReturnOrder )
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
				self:Clear()
				for _, ply in ipairs( player.GetAll() ) do
					local obj = panel.playerList:AddItem( ply:Nick() )
						obj.DoClick = playerListClick
						obj.OnCursorMoved = nullFunc
				end
			end
			panel.playerList:Build()
			
			panel.playerList.NextThink = 0
			panel.playerList.Think = function( self )
				if self.NextThink <= CurTime() then
					self.NextThink = CurTime() + 1
					
					local selected = self.m_pSelected
					if selected and selected:IsValid() then
						selected = selected:GetValue()
					end
					
					self:Build()

					if type( selected ) == "string" then
						self:SelectByName( selected )
					end
				end
			end
			
		-- Category List
		panel.categoryList = exsto.CreatePanelList( 10, 10, secondary:GetWide() - 20, secondary:GetTall() - 20, 5, false, true, secondary )
			panel.categoryList.m_bBackground = false
			-- Insert our categories in there.
			for category, data in SortedPairs( PLUGIN.Categories ) do
				local button = exsto.CreateButton( 0, 0, 70, 28, category )
					button:SetStyle( "secondary" )
					button.Category = category
					button.OnClick = function( self )
						local ply = panel.playerList.m_pSelected
						if ply then
						
							panel.categoryList:SetVisible( false )
							panel.commandList:SetVisible( true )
							panel.commandListBack:SetVisible( true )
							panel.commandList:Build( self.Category )
							panel.commandList.OnMainList = true
							
						end
					end
				panel.categoryList:AddItem( button )
			end
			panel.categoryList:SetVisible( true )
			
		local function nullFunc() end
			
		-- Command List
		panel.commandList = exsto.CreateComboBox( 10, 10, secondary:GetWide() - 20, secondary:GetTall() - 50, secondary )
			panel.commandList:SetMultiple( false )
			panel.commandList.NextPress = CurTime()
			panel.commandList.CurrentCommand = nil
			panel.commandList:SetVisible( false )
			panel.commandList.UpdateStatus = function( self, obj )
				self.CallerID = obj.CallerID
				self.OptionalInfo = obj.OptionalInfo
				self.OptionalIndex = obj.OptionalIndex
				self.ReturnData = { panel.playerList.m_pSelected:GetValue() }
				self.OnMainList = false
			end
			
			panel.commandList.GetOptionalInfo = function( self )
				return self.OptionalInfo[ self.OptionalIndex[ self.CurrentIndex ] ]
			end
			
			panel.commandList.Build = function( self, category )
				self:Clear()
				self.CurrentCategory = category
				
				for _, data in ipairs( PLUGIN.Categories[ category ] ) do -- Loop through each one of our friends.
					local obj = self:AddItem( data.Name )
						obj.OnCursorMoved = nullFunc
						obj.CallerID = data.CallerID
						obj.OptionalInfo = data.OptionalInfo
						obj.OptionalIndex = data.OptionalIndex
						obj.DoClick = function( obj )
							panel.commandList:UpdateStatus( obj )

							-- Check to see if we are waiting for any optionals to display
							if #self.OptionalIndex >= 1 then
								panel.commandListExecute:SetVisible( true ) -- Allow them to execute with no optionals
								self.CurrentIndex = 1
								local info = self:GetOptionalInfo() 
								if !info then self:Execute() return end -- Developer error; he didn't provide any menu alternatives.
								self:OptionalFill( info )
							else
								self:Execute() -- He has no optionals, execute
							end
						end
				end
			end
		
			panel.commandList.OptionalFill = function( self, data )
				self:Clear()
				self.OnMainList = false
				for _, info in ipairs( data ) do
					local obj = self:AddItem( info.Display )
						obj.OnCursorMoved = nullFunc
						obj.DoClick = function( obj )

							table.insert( self.ReturnData, tostring( info.Data or info.Display ) )
							
							self.CurrentIndex = self.CurrentIndex + 1
							local nextData = self:GetOptionalInfo()
							if nextData then -- If we have more data, fill in our new optionals
								self:OptionalFill( nextData )
							else
								self:Execute()
							end
						end
				end
			end
			
			panel.commandList.Clean = function( self )
				self.CallerID = nil
				self.OptionalInfo = {}
				self.OptionalIndex = {}
				self.ReturnData = {}
				self.CurrentIndex = 1
				
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
			panel.commandListBack.OnClick = function( self )
				
				if panel.commandList.OnMainList then
					panel.commandList.OnMainList = false
					
					self:SetVisible( false )
					panel.commandList:SetVisible( false )
					panel.categoryList:SetVisible( true )
					return
				end
				
				panel.commandList.CurrentIndex = panel.commandList.CurrentIndex - 1
				local prevData = panel.commandList:GetOptionalInfo()
				if prevData then
					panel.commandList:OptionalFill( prevData )
				else
					panel.commandList:Clean()
				end
			end
			
		panel.commandListExecute = exsto.CreateButton( secondary:GetWide() - 75, secondary:GetTall() - 35, 70, 28, "OK", secondary )
			panel.commandListExecute:SetStyle( "positive" )
			panel.commandListExecute:SetVisible( false )
			panel.commandListExecute.OnClick = function( self )
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
		
		panel.commandList:SetFadeMul( 3 )
		panel.categoryList:SetFadeMul( 3 )
		panel.commandListExecute:SetFadeMul( 3 )
		panel.commandListBack:SetFadeMul( 3 )
	end
end

PLUGIN:Register()