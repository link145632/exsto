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
		exsto.RankDB:DropRow( args[ 1 ] )
		
		-- Reload Exsto's access controllers.
		ACCESS_Reload()
		
		-- Resend the ranks to clients
		ACCESS_ResendRanks()
		
		-- Reload the rank editor.
		ply:QuickSend( "ExRankEditor_Reload" )
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
		//timer.Create( "reload_" .. ply:EntIndex(), 1, 1, PLUGIN.SendData, PLUGIN, "ExRankEditor_Reload", ply )
		hook.Call( "ExOnRankCreate", nil, rank[3] )
	end
	exsto.ClientHook( "ExRecRankData", PLUGIN.CommitChanges )
	
	function PLUGIN.RecieveImmunityData( ply, data )
		local tbl = exsto.RankDB:GetRow( data[1] )
			tbl.Immunity = data[2]
		exsto.RankDB:AddRow( tbl )
	end
	exsto.ClientHook( "ExRecImmuneChange", PLUGIN.RecieveImmunityData )
	
	function PLUGIN:ExClientData( hook, ply, data )
		if hook == "ExRecImmuneChange" or hook == "ExRecRankData" then
			if !ply:IsAllowed( "rankeditor" ) then return false end
		end		
	end
	
	function PLUGIN:WriteAccess( name, desc, short, derive, color, flags )
		local tbl = exsto.RankDB:GetRow( short )
		exsto.RankDB:AddRow( {
			Name = name;
			Short = short;
			Description = desc;
			Derive = derive;
			Color = FEL.NiceColor( color );
			Flags = FEL.NiceEncode( flags );
			Immunity = tbl and tbl.Immunity or 10
		} )
	end

elseif CLIENT then

	PLUGIN.Panel = nil
	PLUGIN.Recieved = false
	
	local function reload()
		PLUGIN:ReloadMenu( PLUGIN.Panel )
	end
	exsto.CreateReader( "ExRankEditor_Reload", reload )

	Menu:CreatePage( {
		Title = "Rank Editor",
		Short = "rankeditor", },
		function( panel )
			-- Request ranks.
			PLUGIN.Panel = panel
			PLUGIN.Panel:FadeOnVisible( true )
			PLUGIN.Panel:SetFadeMul( 3 )
			if !PLUGIN.Recieved then
				panel:PushLoad()
				RunConsoleCommand( "_ResendRanks" )
			else
				PLUGIN:Main( panel )
			end
		end
	)
	
	local function received( reader )
		PLUGIN.Recieved = true
		if PLUGIN.Panel then
			PLUGIN:Main( PLUGIN.Panel )
		end
	end
	exsto.CreateReader( "ExRecievedRanks", received )
	
	function PLUGIN:Main( panel )
	
		if !self.Flags then
			self.Flags = {}
			for name, desc in pairs( exsto.Flags ) do
				table.insert( self.Flags, {Name = name, Desc = desc} )
			end
			table.SortByMember( self.Flags, "Name", true )
		end
		
		panel:EndLoad()
		self:BuildMenu( panel )
	end
	
	function PLUGIN:ReloadMenu( panel )
		exsto.Ranks = {}
		panel:PushLoad()
		self.Recieved = false
		RunConsoleCommand( "_ResendRanks" )
	end
	
	function PLUGIN:FormulateUpdate( name, short, desc, derive, col, flags )

		-- Upload new rank data
		self.Panel:PushLoad()
		exsto.SendToServer( "ExRecRankData", name, desc, short, derive, col, flags )
		
		-- Send changes to immunity
		if table.Count( self.ImmunityBox.Changed ) >= 1 then
			for short, immunity in pairs( self.ImmunityBox.Changed ) do
				exsto.SendToServer( "ExRecImmuneChange", short, immunity )
			end
			self.ImmunityBox.Changed = {}
		end
		
		self:ReloadMenu( self.Panel )
		
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

		self.Tabs:SetListHeight( self.Tabs:GetListTall() - 20 )
		
		self.Tabs.AddNew = exsto.CreateImageButton( self.Tabs:GetWide() - 20, self.Tabs:GetTall() - 20, 16, 16, "gui/silkicons/add", self.Tabs )
			self.Tabs.AddNew.DoClick = function( img )
				local function build()
					self:UpdateForms( {
						Name = "",
						Short = "",
						Desc = "",
						Derive = "NONE",
						Color = Color( 255, 255, 255, 200 ),
						Flags = {},
						AllFlags = {},
					} ) 
				end
				self.Tabs:CreateButton( "New Rank", build )
				self.Tabs:SelectByName( "New Rank" )
			end
			
		-- Rank building.  
		local immunityData = {}
		local ranks = table.Copy( exsto.Ranks )
		for _, data in SortedPairsByMemberValue( ranks, "Immunity" ) do
			if data.Short != "srv_owner" then				
				self.Tabs:CreateButton( data.Name, function() self:UpdateForms( data ) end )
				
				table.insert( immunityData, { Name = data.Name, Immunity = data.Immunity, Short = data.Short } )
			end
		end

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

		local immunityRaise = exsto.CreateButton( 10, self.Secondary:GetTall() - 33, 60, 27, "Raise", self.Secondary )
			immunityRaise:SetStyle( "positive" )
			immunityRaise.OnClick = function( self )
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
			immunityLower.OnClick = function( self )
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
		if !reloading then
			self:FormPage( panel, exsto.Ranks[ "superadmin" ] )
		end
		
		self.ImmunityBox:BuildData( immunityData )
	end
	
	function PLUGIN:UpdateForms( data )
		self.Panel:SetVisible( false )
		timer.Simple( 0.1, function()
			self.nameEntry:SetText( data.Name )
			self.descEntry:SetText( data.Desc )
			self.uidEntry:SetText( data.Short )
			
			if data.Short == "" then self.uidEntry:SetEditable( true ) else self.uidEntry:SetEditable( false ) end
			
			self.deriveEntry:Clear()
			self.deriveEntry:SetText( data.Derive )
			for short, info in SortedPairsByMemberValue( exsto.Ranks, "Immunity" ) do
				if short != data.Short then
					self.deriveEntry:AddChoice( short )
				end
			end
			
			self.colorMixer:SetColor( data.Color )
			self.colorExample:SetTextColor( data.Color )
			self.redSlider:SetValue( data.Color.r )
			self.greenSlider:SetValue( data.Color.g )
			self.blueSlider:SetValue( data.Color.b )
			self.alphaSlider:SetValue( data.Color.a )
			
			self.flags = data.Flags
			self.allFlags = data.AllFlags
			self.flagList:Clear()
			self.flagList:UpdateFlagList( 1 )
			
			self.delete:SetVisible( data.CanRemove )
			if Menu.CurrentPage.Short == "rankeditor" then self.Panel:SetVisible( true ) end
		end )
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
		self.nameEntry = exsto.CreateTextEntry( 20, 0, 200, 20, mainColorPanel )
			self.nameEntry:MoveBelow( nameLabel )
			self.nameEntry:SetText( data.Name )
			self.nameEntry.OnTextChanged = ContentCheck
			
		-- Description
		local descLabel = exsto.CreateLabel( ( mainColorPanel:GetWide() / 2 ) + 20, 5, "Description", "exstoSecondaryButtons", mainColorPanel )
		self.descEntry = exsto.CreateTextEntry( ( mainColorPanel:GetWide() / 2 ) + 20, 0, 200, 20, mainColorPanel )
			self.descEntry:MoveBelow( descLabel )
			self.descEntry:SetText( data.Desc )
			self.descEntry.OnTextChanged = ContentCheck
			
		-- UniqueID
		local x, y = self.nameEntry:GetPos()
		local uidLabel = exsto.CreateLabel( 20, y + 40, "Unique ID", "exstoSecondaryButtons", mainColorPanel )
		self.uidEntry = exsto.CreateTextEntry( 20, 0, 200, 20, mainColorPanel )
			self.uidEntry:MoveBelow( uidLabel )
			self.uidEntry:SetText( data.Short )
			self.uidEntry.IsUID = true
			self.uidEntry.OnTextChanged = ContentCheck
			
			if data.Short != "" then
				self.uidEntry:SetEditable( false )
			end
			
		-- Derive
		local x, y = self.descEntry:GetPos()
		local deriveLabel = exsto.CreateLabel( ( mainColorPanel:GetWide() / 2 ) + 20, y + 40, "Derive From", "exstoSecondaryButtons", mainColorPanel )
		self.deriveEntry = exsto.CreateMultiChoice( ( mainColorPanel:GetWide() / 2 ) + 20, 0, 200, 20, mainColorPanel )
			self.deriveEntry:MoveBelow( deriveLabel )
			self.deriveEntry:SetText( data.Derive )
			self.deriveEntry:SetEditable( false )
			
			for short, info in SortedPairsByMemberValue( table.Copy( exsto.Ranks ), "Immunity" ) do
				if short != data.Short then
					self.deriveEntry:AddChoice( short )
				end
			end
			self.deriveEntry:AddChoice( "NONE" )
			
		-- Color Panel
		local colorColorPanel = Menu:CreateColorPanel( ( mainColorPanel:GetWide() / 2 ) + 70, 10, ( mainColorPanel:GetWide() / 2 ) - 60, 160, panel )
			colorColorPanel:MoveBelow( mainColorPanel, 10 )
			
		self.colorMixer = exsto.CreateColorMixer( 0, 0, 160, 100, data.Color, colorColorPanel )
			self.colorMixer:Center()
			
		self.colorExample = exsto.CreateLabel( "center", 5, "abc ABC 123", "exstoSecondaryButtons", colorColorPanel )
			self.colorExample:SetTextColor( data.Color )

		local emptyFunc = function() end

		self.redSlider = exsto.CreateNumberWang( 0, 30, 32, 20, data.Color.r, 255, 0, colorColorPanel )
			self.redSlider.Wanger.Paint = emptyFunc
			self.redSlider:SetDecimals( 0 )
			self.redSlider:MoveRightOf( self.colorMixer )
			
		self.greenSlider = exsto.CreateNumberWang( 0, 55, 32, 20, data.Color.g, 255, 0, colorColorPanel )
			self.greenSlider.Wanger.Paint = emptyFunc
			self.greenSlider:SetDecimals( 0 )
			self.greenSlider:MoveRightOf( self.colorMixer )
			
		self.blueSlider = exsto.CreateNumberWang( 0, 80, 32, 20, data.Color.b, 255, 0, colorColorPanel )
			self.blueSlider.Wanger.Paint = emptyFunc
			self.blueSlider:SetDecimals( 0 )
			self.blueSlider:MoveRightOf( self.colorMixer )
			
		self.alphaSlider = exsto.CreateNumberWang( 0, 105, 32, 20, data.Color.a, 255, 0, colorColorPanel )
			self.alphaSlider.Wanger.Paint = emptyFunc
			self.alphaSlider:SetDecimals( 0 )
			self.alphaSlider:MoveRightOf( self.colorMixer )
			
		local oldThink = self.colorMixer.Think
		self.colorMixer.Think = function( mixer )
			oldThink( mixer )
			
			if mixer.ColorCube:GetDragging() then return end
			if mixer.RGBBar:GetDragging() then return end
			if mixer.AlphaBar:GetDragging() then return end
			if !mixer.niceColor then mixer.niceColor = Color( 0, 0, 0, 200 ) end
			
			mixer.niceColor.r = self.redSlider:GetValue()
			mixer.niceColor.g = self.greenSlider:GetValue()
			mixer.niceColor.b = self.blueSlider:GetValue()
			mixer.niceColor.a = self.alphaSlider:GetValue()
			
			self.colorExample:SetTextColor( mixer.niceColor )
			mixer:SetColor( mixer.niceColor )
		end
		
		local function updateColors( obj )
			local col = obj:GetParent():GetColor()
			self.redSlider:SetValue( col.r )
			self.greenSlider:SetValue( col.g )
			self.blueSlider:SetValue( col.b )
			self.alphaSlider:SetValue( col.a )
			
			self.colorExample:SetTextColor( obj:GetParent():GetColor() )
		end
			
		local oldChange = self.colorMixer.ColorCube.OnUserChanged
		self.colorMixer.ColorCube.OnUserChanged = function( self )
			oldChange( self )
			updateColors( self )
		end
		
		local oldChange = self.colorMixer.RGBBar.OnColorChange
		self.colorMixer.RGBBar.OnColorChange = function( self, col )
			oldChange( self, col )
			updateColors( self )
		end
		
		local oldChange = self.colorMixer.AlphaBar.OnChange
		self.colorMixer.AlphaBar.OnChange = function( amix, alpha )
			self.colorMixer:SetColorAlpha( alpha )
			updateColors( amix )
		end

		-- Flag Panel
		local flagColorPanel = Menu:CreateColorPanel( 10, 0, ( mainColorPanel:GetWide() / 2 ) + 50, 195, panel )
			flagColorPanel:MoveBelow( mainColorPanel, 10 )
			
		self.flags = data.Flags or {}
		self.allFlags = data.AllFlags or {}
			
		self.flagList = exsto.CreateComboBox( 0, 0, flagColorPanel:GetWide(), flagColorPanel:GetTall(), flagColorPanel )
			self.flagList.dontDrawBackground = true

			self.flagList.UpdateFlagList = function( lst, index )
				local info = PLUGIN.Flags[ index ]
				if !info then return end
				
				local obj = lst:AddItem( info.Name )
					obj:SetToolTip( info.Desc )
					obj.FlagName = info.Name
					obj.disableSelect = true
					
					obj.OnCursorMoved = emptyFunc
					
					local oldClick = obj.DoClick
					obj.DoClick = function( obj, ... )
						oldClick( obj, ... )
						
						if obj.FlagName == "issuperadmin" or obj.FlagName == "isadmin" or obj.FlagName == "menu" then return end
						
						-- If the flag exists in his main flag table, remove it.
						if table.HasValue( self.flags, self.allFlags ) then
							for _, flag in ipairs( self.flags ) do
								if flag == obj.FlagName then
									table.remove( self.flags, _ )
									break
								end
							end
							
							for _, flag in ipairs( self.allFlags ) do
								if flag == obj.FlagName then
									table.remove( self.allFlags, _ )
									obj.Icon = "icon_off"
									obj.overrideColor = nil
									break
								end
							end
						
						-- If it doesn't exist in our flags.
						else
							-- If it doesn't exist in our flags at all.
							if !table.HasValue( self.allFlags, obj.FlagName ) then
								table.insert( self.flags, obj.FlagName )
								table.insert( self.allFlags, obj.FlagName )
								obj.Icon = "icon_on"
								obj.overrideColor = Color( 180, 241, 170 )
							end
						end
					end
					
					obj.PaintOver = function( obj )
						if obj.OldIcon != obj.Icon then
							obj.IconID = surface.GetTextureID( obj.Icon )
							obj.OldIcon = obj.Icon
						end

						surface.SetTexture( obj.IconID )
						surface.SetDrawColor( 255, 255, 255, 255 )
						surface.DrawTexturedRect( self.flagList:GetWide() - 40, ( obj:GetTall() / 2 ) - 8, 16, 16 )
					end

					obj.Icon = "icon_on"
					obj.overrideColor = Color( 180, 241, 170 )
					
					if !table.HasValue( self.flags, obj.FlagName ) then
						obj.overrideColor = nil
						if table.HasValue( self.allFlags, obj.FlagName ) then
							obj.Icon = "icon_locked"
						else
							obj.Icon = "icon_off"
						end
					end
					
				lst:UpdateFlagList( index + 1 )
			end
			self.flagList:UpdateFlagList( 1 )
		
		-- Commit Buttons
		self.save = exsto.CreateButton( panel:GetWide() - 80, panel:GetTall() - 40, 70, 27, "Save", panel )
			self.save:SetStyle( "positive" )
			self.save.OnClick = function( button )
				if self.nameEntry:GetValue() == "" then PLUGIN.Panel:PushError( "Please enter a name for the rank!" ) return end
				if self.uidEntry:GetValue() == "" then PLUGIN.Panel:PushError( "Please enter a UID for the rank!" ) return end
				if self.descEntry:GetValue() == "" then self.descEntry:SetText( "None Provided" ) end
				if self.deriveEntry.TextEntry:GetValue() == "" then PLUGIN.Panel:PushError( "Please enter a valid derive!" ) return end
				
				PLUGIN:FormulateUpdate( self.nameEntry:GetValue(), self.uidEntry:GetValue(), self.descEntry:GetValue(), self.deriveEntry.TextEntry:GetValue(), self.colorMixer:GetColor(), data.Flags )
			end
			
		self.delete = exsto.CreateButton( 0, panel:GetTall() - 40, 70, 27, "Delete", panel )
			self.delete:SetStyle( "negative" )
			self.delete:MoveLeftOf( self.save, 5 )
			self.delete:SetVisible( data.CanRemove )
			self.delete.OnClick = function( button )
				PLUGIN.Panel:PushLoad()
				Menu.CallServer( "_DeleteRank", data.Short )
			end
			
		self.refresh = exsto.CreateButton( 0, panel:GetTall() - 40, 75, 27, "Refresh", panel )
			self.refresh:SetStyle( "neutral" )
			self.refresh:MoveLeftOf( self.delete, 5 )
			self.refresh.OnClick = function( button )
				PLUGIN:ReloadMenu( PLUGIN.Panel )
			end
	end
	
end

PLUGIN:Register()
		