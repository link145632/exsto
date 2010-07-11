local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo( {
	Name = "Rank Editor",
	ID = "rank-editor",
	Desc = "A plugin that allows management over rank creation.",
	Owner = "Prefanatic",
} )

if SERVER then

	function PLUGIN.DeleteRank( ply, _, args )
		-- Add Flag.
		
		-- Remove exsto rank error data if we are removing the rank
		//exsto.RankErrors[ args[ 1 ] ] = nil

		-- Remove the data.
		FEL.RemoveData( "exsto_data_access", "short", args[ 1 ] )
		
		-- Reload Exsto's access controllers.
		ACCESS_Reload()
		
		-- Resend the ranks to clients
		ACCESS_ResendRanks()
		
		-- Reload the rank editor.
		PLUGIN:SendData( "ExRankEditor_Reload", ply )
	end
	exsto.MenuCall( "_DeleteRank", PLUGIN.DeleteRank )
	
	function PLUGIN.CommitChanges( ply, rank )
	
		local immunity = nil
		if !exsto.Ranks[ rank[3] ] then immunity = 10 end

		-- Write the data
		PLUGIN:WriteAccess( rank[1], rank[2], rank[3], rank[4], rank[5], rank[6], immunity )
		if immunity then
			PLUGIN.RecieveImmunityData( ply, { rank[3], immunity } )
		end
		
		-- Reload Exsto's access controllers.
		ACCESS_Reload()
		
		-- Send the new rank, thats smarter than sending the entire jazz, right?
		exsto.SendRank( player.GetAll(), rank[ 3 ] )
		
		-- Reload the rank editor.
		timer.Create( "reload_" .. ply:EntIndex(), 1, 1, PLUGIN.SendData, PLUGIN, "ExRankEditor_Reload", ply )
		
	end
	exsto.ClientHook( "ExRecRankData", PLUGIN.CommitChanges )
	
	function PLUGIN.RecieveImmunityData( ply, data )
		FEL.AddData( "exsto_data_access", {
			Look = {
				Short = data[1],
			},
			Data = {
				Immunity = data[2],
			},
			Options = {
				Update = true,
			},
		} )
	end
	exsto.ClientHook( "ExRecImmuneChange", PLUGIN.RecieveImmunityData )
	
	function PLUGIN:WriteAccess( name, desc, short, derive, color, flags )
		FEL.AddData( "exsto_data_access", {
			Look = {
				Short = short,
			},
			Data = {
				Name = name,
				Short = short,
				Description = desc,
				Derive = derive,
				Color = FEL.NiceColor( color ),
				Flags = FEL.NiceEncode( flags ),
			},
			Options = {
				Update = true,
			}
		} )
	end

elseif CLIENT then

	PLUGIN.Panel = nil
	local function reload()
		PLUGIN:ReloadMenu( PLUGIN.Panel )
	end
	exsto.UMHook( "ExRankEditor_Reload", reload )

	Menu:CreatePage( {
		Title = "Rank Editor",
		Short = "rankeditor", },
		function( panel )
			-- Request ranks.
			if table.Count( exsto.Ranks ) == 0 then
				RunConsoleCommand( "_ResendRanks" )
			end
			PLUGIN.Panel = panel
			PLUGIN:Main( panel )
		end
	)
	
	function PLUGIN:Main( panel )
		if table.Count( exsto.Ranks ) == 0 then
			timer.Simple( 1, PLUGIN.Main, self, panel )
			return
		end
		
		if table.Count( exsto.Flags ) == 0 then
			timer.Simple( 1, PLUGIN.Main, self, panel )
			return
		end
		
		if !self.Flags then
			self.Flags = {}
			for name, desc in pairs( exsto.Flags ) do
				table.insert( self.Flags, {Name = name, Desc = desc} )
			end
			table.SortByMember( self.Flags, "Name", true )
		end
		
		self:BuildMenu( panel )
	end
	
	function PLUGIN:ReloadMenu( panel )
		exsto.Ranks = {}
		RunConsoleCommand( "_ResendRanks" )
		self:Main( panel )
	end
	
	function PLUGIN:FormulateUpdate( name, short, desc, derive, col, flags )

		-- Upload new rank data
		exsto.SendToServer( "ExRecRankData", name, desc, short, derive, col, flags )
		
		-- Send changes to immunity
		if table.Count( self.ImmunityBox.Changed ) >= 1 then
			for short, immunity in pairs( self.ImmunityBox.Changed ) do
				exsto.SendToServer( "ExRecImmuneChange", short, immunity )
			end
			self.ImmunityBox.Changed = {}
		end
		
	end
	
	function PLUGIN:BuildMenu( panel )
	
		-- Clear pre-existing content.
		local reloading = false
		if self.Tabs then
			self.Tabs:Clear()
			self.Tabs:Remove()
			reloading = true
		end
		
		if self.Secondary then
			self.Secondary:Remove()
			reloading = true
		end
		
		self.Tabs = panel:RequestTabs( reloading )
		self.Secondary = panel:RequestSecondary( reloading )
		if reloading then 
			Menu:BringBackSecondaries() 
		end
		
		local immunityData = {}
		for short, data in pairs( exsto.Ranks ) do
			local page = self.Tabs:CreatePage( panel )
			self:FormPage( page, data )
			self.Tabs:AddItem( data.Name, page )
			
			table.insert( immunityData, { Name = data.Name, Immunity = data.Immunity, Short = data.Short } )
		end
		
		local page = self.Tabs:CreatePage( panel )
		self:FormPage( page, {
			Name = "",
			Short = "",
			Desc = "",
			Derive = "NONE",
			Color = Color( 255, 255, 255, 200 ),
			Flags = {},
			AllFlags = {},
		} )
		self.Tabs:AddItem( "Create New", page )

		-- Immunity Box
		local immunityLabel = exsto.CreateLabel( "center", 5, "Immunity", "exstoSecondaryButtons", self.Secondary )
		self.ImmunityBox = exsto.CreateComboBox( 10, 25, self.Secondary:GetWide() - 20, self.Secondary:GetTall() - 60, self.Secondary )
			self.ImmunityBox.Changed = {}
			
			self.ImmunityBox.BuildData = function( self, data )
				self:Clear()
				table.sort( data, function( a, b )
					if !tonumber( a.Immunity ) or !tonumber( b.Immunity ) then return false end
					return tonumber( a.Immunity ) < tonumber( b.Immunity )
				end)
				for _, info in ipairs( data ) do
					local item = PLUGIN.ImmunityBox:AddItem( info.Name )
						item.Name = info.Name
						item.Immunity = info.Immunity
						item.Short = info.Short
						item.Key = _
						
						item.PaintOver = function( self )
							draw.SimpleText( "Level: " .. self.Immunity, "default", self:GetWide() - 50, self:GetTall() / 2, Color( 0, 0, 0, 255 ), 0, 1 )
						end
				end
			end
			self.ImmunityBox:BuildData( immunityData )

		local immunityRaise = exsto.CreateButton( 10, self.Secondary:GetTall() - 33, 60, 27, "Raise", self.Secondary )
			immunityRaise:SetStyle( "positive" )
			immunityRaise.DoClick = function( self )
				local selected = PLUGIN.ImmunityBox.m_pSelected
				if selected then
					if selected.Immunity == 0 then return end
					
					PLUGIN.ImmunityBox.Changed[ selected.Short ] = selected.Immunity - 1
					immunityData[ selected.Key ].Immunity = tonumber( selected.Immunity - 1 )
					PLUGIN.ImmunityBox:BuildData( immunityData )
					PLUGIN.ImmunityBox:SelectByName( selected.Name )
				end
			end	
			
		local immunityLower = exsto.CreateButton( self.Secondary:GetWide() - 70, self.Secondary:GetTall() - 33, 60, 27, "Lower", self.Secondary )
			immunityLower:SetStyle( "negative" )
			immunityLower.DoClick = function( self )
				local selected = PLUGIN.ImmunityBox.m_pSelected
				if selected then				
					PLUGIN.ImmunityBox.Changed[ selected.Short ] = selected.Immunity + 1
					immunityData[ selected.Key ].Immunity = tonumber( selected.Immunity + 1 )
					PLUGIN.ImmunityBox:BuildData( immunityData )
					PLUGIN.ImmunityBox:SelectByName( selected.Name )
				end
			end	
			
		local immunitySlider = exsto.CreateNumberWang( ( self.Secondary:GetWide() / 2 ) - 15, self.Secondary:GetTall() - 30, 30, 20, 0, 100, 0, self.Secondary )
			immunitySlider.OnValueChanged = function( self )
				if !self.MotherObject then return false end
				if self.DontUpdateValue then return false end
				PLUGIN.ImmunityBox.Changed[ self.MotherObject.Short ] = self:GetValue()
				immunityData[ self.MotherObject.Key ].Immunity = self:GetValue()
				PLUGIN.ImmunityBox:BuildData( immunityData )
				PLUGIN.ImmunityBox:SelectByName( self.MotherObject.Name )
			end
			immunitySlider.Wanger.Paint = function() end
			immunitySlider:SetDecimals( 0 )
			
		local oldSelect = self.ImmunityBox.SelectItem
			self.ImmunityBox.SelectItem = function( self, item, onlyme )
				oldSelect( self, item, onlyme )
				immunitySlider.MotherObject = item
				immunitySlider.DontUpdateValue = true
				immunitySlider:SetValue( item.Immunity )
				immunitySlider.DontUpdateValue = false
			end
	end
	
	function PLUGIN:FormPage( panel, data )
		
		-- Main data color panel.
		local mainColorPanel = Menu:CreateColorPanel( 10, 10, panel:GetWide() - 20, 110, panel )
		
		local invalidator = nil
		local function ContentCheck( self )
			if string.find( self:GetValue(), "['\"]" ) then
				self.Invalid = true
				invalidator = self
				mainColorPanel:Deny()
				self:SetToolTip( "You cannot have ', \", or ! in the name!" )
				return
			end
			
			if self:GetValue() == "" then
				self.Invalid = true
				invalidator = self
				mainColorPanel:Deny()
				self:SetToolTip( "You cannot leave this empty!" )
				return
			end
			
			if self.IsUID then
				for short, info in pairs( exsto.Ranks ) do
					if self:GetValue() == short then
						self.Invalid = true
						invalidator = self
						mainColorPanel:Deny()
						self:SetToolTip( "You cannot have more than one rank with the same unique id!" )
						return
					end
				end
			end
			
			if self.Invalid then
				self:SetToolTip( "" )
				self.Invalid = false
			end
				
			if mainColorPanel:GetStyle() != "accept" and !self.Invalid and invalidator == self then
				mainColorPanel:Accept()
			end
		end
			
		-- Display Name
		local nameLabel = exsto.CreateLabel( 20, 5, "Display Name", "exstoSecondaryButtons", mainColorPanel )
		local nameEntry = exsto.CreateTextEntry( 20, 0, 200, 20, mainColorPanel )
			nameEntry:MoveBelow( nameLabel )
			nameEntry:SetText( data.Name )
			nameEntry.OnTextChanged = ContentCheck
			
		-- Description
		local descLabel = exsto.CreateLabel( ( mainColorPanel:GetWide() / 2 ) + 20, 5, "Description", "exstoSecondaryButtons", mainColorPanel )
		local descEntry = exsto.CreateTextEntry( ( mainColorPanel:GetWide() / 2 ) + 20, 0, 200, 20, mainColorPanel )
			descEntry:MoveBelow( descLabel )
			descEntry:SetText( data.Desc )
			descEntry.OnTextChanged = ContentCheck
			
		-- UniqueID
		local x, y = nameEntry:GetPos()
		local uidLabel = exsto.CreateLabel( 20, y + 40, "Unique ID", "exstoSecondaryButtons", mainColorPanel )
		local uidEntry = exsto.CreateTextEntry( 20, 0, 200, 20, mainColorPanel )
			uidEntry:MoveBelow( uidLabel )
			uidEntry:SetText( data.Short )
			uidEntry.IsUID = true
			uidEntry.OnTextChanged = ContentCheck
			
		-- Derive
		local x, y = descEntry:GetPos()
		local deriveLabel = exsto.CreateLabel( ( mainColorPanel:GetWide() / 2 ) + 20, y + 40, "Derive From", "exstoSecondaryButtons", mainColorPanel )
		local deriveEntry = exsto.CreateMultiChoice( ( mainColorPanel:GetWide() / 2 ) + 20, 0, 200, 20, mainColorPanel )
			deriveEntry:MoveBelow( deriveLabel )
			deriveEntry:SetText( data.Derive )
			deriveEntry:SetEditable( false )
			
			for short, info in pairs( exsto.Ranks ) do
				if short != data.Short then
					deriveEntry:AddChoice( short )
				end
			end
			deriveEntry:AddChoice( "NONE" )
			
		-- Color Panel
		local colorColorPanel = Menu:CreateColorPanel( ( mainColorPanel:GetWide() / 2 ) + 70, 10, ( mainColorPanel:GetWide() / 2 ) - 60, 160, panel )
			colorColorPanel:MoveBelow( mainColorPanel, 10 )
			
		local colorMixer = exsto.CreateColorMixer( 0, 0, 160, 100, data.Color, colorColorPanel )
			colorMixer:Center()
			
		local colorExample = exsto.CreateLabel( "center", 5, "abc ABC 123", "exstoSecondaryButtons", colorColorPanel )
			colorExample:SetTextColor( data.Color )

			local oldPress = colorMixer.ColorCube.OnMousePressed
			colorMixer.ColorCube.OnMousePressed = function( self, ... )
				oldPress( self, ... )
				self.Updating = true
			end
			
			local oldRelease = colorMixer.ColorCube.OnMouseReleased
			colorMixer.ColorCube.OnMouseReleased = function( self, ... )
				oldRelease( self, ... )
				self.Updating = false
			end
			
		local emptyFunc = function() end
		
		local valChange = function( self, tbl )
			local col = colorMixer.niceColor
			colorExample:SetTextColor( col )
			
			if !colorMixer.ColorCube.Updating then
				print( "updating color tbl .. tbl ", self:GetValue() )
				col[ tbl ] = self:GetValue()
				PrintTable( col )
				colorMixer.niceColor = Color( col.r, col.g, col.b, col.a )
				colorMixer:SetColor( colorMixer.niceColor )
			end
		end

		local redSlider = exsto.CreateNumberWang( 0, 30, 32, 20, data.Color.r, 255, 0, colorColorPanel )
			print( redSlider )
			redSlider.OnValueChanged = function( self ) valChange( self, "r" ) end
			redSlider.TextEntry.OnTextChanged = function( self ) valChange( self, "r" ) end
			
			redSlider.Wanger.Paint = emptyFunc
			redSlider:SetDecimals( 0 )
			redSlider:MoveRightOf( colorMixer )
			
		local greenSlider = exsto.CreateNumberWang( 0, 55, 32, 20, data.Color.g, 255, 0, colorColorPanel )
			print( greenSlider )
			greenSlider.OnValueChanged = function( self ) valChange( self, "g" ) end
			greenSlider.TextEntry.OnTextChanged = function( self ) valChange( self, "g" ) end
			
			greenSlider.Wanger.Paint = emptyFunc
			greenSlider:SetDecimals( 0 )
			greenSlider:MoveRightOf( colorMixer )
			
		local blueSlider = exsto.CreateNumberWang( 0, 80, 32, 20, data.Color.b, 255, 0, colorColorPanel )
			blueSlider.OnValueChanged = function( self ) valChange( self, "b" ) end
			blueSlider.TextEntry.OnTextChanged = function( self ) valChange( self, "b" ) end
			
			blueSlider.Wanger.Paint = emptyFunc
			blueSlider:SetDecimals( 0 )
			blueSlider:MoveRightOf( colorMixer )
			
		local alphaSlider = exsto.CreateNumberWang( 0, 105, 32, 20, data.Color.a, 255, 0, colorColorPanel )
			alphaSlider.OnValueChanged = function( self ) valChange( self, "a" ) end
			alphaSlider.TextEntry.OnTextChanged = function( self ) valChange( self, "a" ) end
			
			alphaSlider.Wanger.Paint = emptyFunc
			alphaSlider:SetDecimals( 0 )
			alphaSlider:MoveRightOf( colorMixer )
			
		colorMixer.ColorCube.OnUserChanged = function( self )
			local col = self:GetParent():GetColor()
			redSlider:SetValue( col.r )
			greenSlider:SetValue( col.g )
			blueSlider:SetValue( col.b )
			alphaSlider:SetValue( col.a )
			
			colorExample:SetTextColor( self:GetParent():GetColor() )
		end

		-- Flag Panel
		local flagColorPanel = Menu:CreateColorPanel( 10, 0, ( mainColorPanel:GetWide() / 2 ) + 50, 195, panel )
			flagColorPanel:MoveBelow( mainColorPanel, 10 )
			
		local flagList = exsto.CreateComboBox( 0, 0, flagColorPanel:GetWide(), flagColorPanel:GetTall(), flagColorPanel )
			flagList.dontDrawBackground = true

			flagList.UpdateFlagList = function( self, index )
				local info = PLUGIN.Flags[ index ]
				if !info then return end
				
				local obj = self:AddItem( info.Name )
					obj:SetToolTip( info.Desc )
					obj.FlagName = info.Name
					
					local oldClick = obj.DoClick
					obj.DoClick = function( self, ... )
						oldClick( self, ... )
						
						if self.FlagName == "issuperadmin" or self.FlagName == "isadmin" or self.FlagName == "menu" then return end
						
						-- If the flag exists in his main flag table, remove it.
						if table.HasValue( data.Flags, self.FlagName ) then
							for _, flag in ipairs( data.Flags ) do
								if flag == self.FlagName then
									table.remove( data.Flags, _ )
									break
								end
							end
							
							for _, flag in ipairs( data.AllFlags ) do
								if flag == self.FlagName then
									table.remove( data.AllFlags, _ )
									self.Icon = "icon_off"
									self.overrideColor = Color( 0, 0, 0, 0 )
									break
								end
							end
						
						-- If it doesn't exist in our flags.
						else
							-- If it doesn't exist in our flags at all.
							if !table.HasValue( data.AllFlags, self.FlagName ) then
								table.insert( data.Flags, self.FlagName )
								table.insert( data.AllFlags, self.FlagName )
								self.Icon = "icon_on"
								self.overrideColor = Color( 180, 241, 170 )
							end
						end
					end
					
					obj.PaintOver = function( self )
						if self.OldIcon != self.Icon then
							self.IconID = surface.GetTextureID( self.Icon )
							self.OldIcon = self.Icon
						end

						surface.SetTexture( self.IconID )
						surface.SetDrawColor( 255, 255, 255, 255 )
						surface.DrawTexturedRect( flagList:GetWide() - 40, ( self:GetTall() / 2 ) - 8, 16, 16 )
					end

					obj.Icon = "icon_on"
					obj.overrideColor = Color( 180, 241, 170 )
					
					if !table.HasValue( data.Flags, obj.FlagName ) then
						obj.overrideColor = Color( 0, 0, 0, 0 )
						if table.HasValue( data.AllFlags, obj.FlagName ) then
							obj.Icon = "icon_locked"
						else
							obj.Icon = "icon_off"
						end
					end
					
				self:UpdateFlagList( index + 1 )
			end
			flagList:UpdateFlagList( 1 )
		
		-- Commit Buttons
		local save = exsto.CreateButton( panel:GetWide() - 80, panel:GetTall() - 40, 70, 27, "Save", panel )
			save:SetStyle( "positive" )
			save.DoClick = function( self )
				PLUGIN:FormulateUpdate( nameEntry:GetValue(), uidEntry:GetValue(), descEntry:GetValue(), deriveEntry.TextEntry:GetValue(), colorMixer:GetColor(), data.Flags )
			end
			
		local delete = exsto.CreateButton( 0, panel:GetTall() - 40, 70, 27, "Delete", panel )
			delete:SetStyle( "negative" )
			delete:MoveLeftOf( save, 5 )
			delete:SetVisible( data.CanRemove )
			delete.DoClick = function( self )
				Menu.CallServer( "_DeleteRank", data.Short )
			end
			
		local refresh = exsto.CreateButton( 0, panel:GetTall() - 40, 75, 27, "Refresh", panel )
			refresh:SetStyle( "neutral" )
			refresh:MoveLeftOf( delete, 5 )
			refresh.DoClick = function( self )
				PLUGIN:ReloadMenu( PLUGIN.Panel )
			end
	end
	
end

PLUGIN:Register()
		