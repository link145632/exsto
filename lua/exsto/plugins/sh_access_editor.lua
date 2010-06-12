-- Exsto
-- Rank Creator + Editor

-- TODO: Per user flags.

local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
	Name = "Rank Editor",
	ID = "rank-editor",
	Desc = "A plugin that allows management over rank creation.",
	Owner = "Prefanatic",
	Experimental = false,
} )

if SERVER then 

	PLUGIN.Editing = {}
	
	PLUGIN.DefaultTable = {
		Short = "",
		Derive = "NONE",
		Desc = "",
		Flags_NoDerive = {},
		Name = "",
		CanRemove = true,
		Color = Color( 0, 0, 0, 0 ),
		Immunity = 1,
	}

	local NextRequest = 0
	
	function PLUGIN.DeleteRank( ply, _, args )
	
		if !ply:IsAdmin() then return end
		
		-- If the ID in question is the broken one, tell Exsto.
		if exsto.RankErrors[args[1]] then
			exsto.RankErrors[args[1]] = nil
		end
		
		FEL.RemoveData( "exsto_data_access", "short", args[1] )
		
		ACCESS_PrepReload()
		ACCESS_LoadFiles()
		ACCESS_InitLevels()	
		ACCESS_ResendRanks()

		exsto.UMStart( "exsto_ReloadRankEditor", ply )
	end
	exsto.MenuCall( "_DeleteRank", PLUGIN.DeleteRank )
	
	function PLUGIN.UpdateKey( ply, _, args )
		local rank = args[1]
		local key = args[2]
		local data = args[3]
	
		if !PLUGIN.Editing[rank] then
			PLUGIN.Editing[ rank ] = PLUGIN.DefaultTable
			
			-- Check and see if we can copy the table over from the normal levels.
			if exsto.Levels[ rank ] then PLUGIN.Editing[ rank ] = exsto.Levels[ rank ] end
		end
		
		rank = PLUGIN.Editing[rank]
		
		if key == "name" then
			rank.Name = data
		elseif key == "short" then
			rank.Short = data
		elseif key == "desc" then
			rank.Desc = data
		elseif key == "derive" then
			rank.Derive = data
		elseif key == "immunity" then
			rank.Immunity = data
		elseif key == "col_red" then
			rank.Color.r = data
		elseif key == "col_green" then
			rank.Color.g = data
		elseif key == "col_blue" then
			rank.Color.b = data
		elseif key == "col_alpha" then
			rank.Color.a = data
		elseif key == "flag_add" then
			table.insert( rank.Flags_NoDerive, data )
		elseif key == "flag_remove" then
			local id = exsto.GetTableID( rank.Flags_NoDerive, data )
			table.remove( rank.Flags_NoDerive, id )
		elseif key == "flag_remall" then
			rank.Flags_NoDerive = {}
		end
	end
	exsto.MenuCall( "_UpdateRankInfo", PLUGIN.UpdateKey )
	
	concommand.Add( "_PrintEdits", function() PrintTable( PLUGIN.Editing ) end )
	
	function PLUGIN.CommitChanges( ply, _, args )
		local short = args[1]
		local realShort = args[2]
		local rank = PLUGIN.Editing[realShort]

		if !rank then return end
		PrintTable( rank )
		
		exsto.UMStart( "exsto_ReloadRankEditor", ply )
		
		PLUGIN.WriteAccess( rank.Name, rank.Desc, rank.Short, rank.Derive, rank.Immunity, rank.Color, rank.Flags_NoDerive )
		
		-- Reload the access lib
		ACCESS_PrepReload()
		ACCESS_LoadFiles()
		ACCESS_ResendRanks()
		
		-- Clean out our edit list
		PLUGIN.Editing[ "Create New" ] = PLUGIN.DefaultTable
	end
	exsto.MenuCall( "_CommitChanges", PLUGIN.CommitChanges )
	
	function PLUGIN.WriteAccess( Name, Desc, Short, Derive, Immunity, Color, Flags )				
		FEL.AddData( "exsto_data_access", {
			Look = {
				Short = Short,
			},
			Data = {
				Name = Name,
				Short = Short,
				Description = Desc,
				Derive = Derive,
				Color = FEL.NiceColor( Color ),
				Immunity = Immunity,
				Flags = FEL.NiceEncode( Flags ),
			},
			Options = {
				Update = true,
			}
		} )
		
	end
	
elseif CLIENT then

	surface.CreateFont( "arial", 15, 700, true, false, "labeledPanelFont" )
	surface.CreateFont( "arial", 17, 700, true, false, "tabFont" )

	exsto.Levels = {}
	exsto.Flags = {}
	exsto.RankErrors = {}
	local Main
	local Title
	local names = {}
	local rankPages
	local rankSheets
	
	function PLUGIN.ReloadMenuFromHook()	
		PLUGIN.ReloadMenu()
	end
	exsto.UMHook( "exsto_ReloadRankEditor", PLUGIN.ReloadMenuFromHook )
	hook.Add( "exsto_BuildRanks", PLUGIN.ReloadMenuFromHook )

	Menu.CreatePage( {
		Title = "Rank Editor",
		Short = "rankeditor",
		Flag = "rankeditor"}, function( panel )
		
		if !LocalPlayer():IsAdmin() then return end
		
		Main = panel
		
		if table.Count( exsto.Levels ) == 0 then
			RunConsoleCommand( "_ResendRanks" )
		end
		
		PLUGIN.Main()
		
	end )
	
	function PLUGIN.Main()
	
		if table.Count( exsto.Levels ) == 0 then

			//print( "Waiting..." )
			timer.Simple( 1, PLUGIN.Main )
			
			return
			
		end
		
		PLUGIN.RefreshMenu()
		Menu.EndLoad()
		
	end
	
	function PLUGIN.ReloadMenu()
	
		Menu.PushLoad()
	
		exsto.Levels = {}
		RunConsoleCommand( "_ResendRanks" )
		
		PLUGIN.Main()
		
	end
	
	function PLUGIN.RefreshMenu()
	
		if rankPages and rankSheets then
			rankSheets:Remove()
		end
	
		names = {}
		for k,v in pairs( exsto.Levels ) do table.insert( names, k ) end
		for k,v in pairs( exsto.RankErrors ) do table.insert( names, "ERROR: " .. k ) end -- For the ranks that are bugged somehow
		
		if table.Count( exsto.RankErrors ) >= 1 then
			Menu.PushError( "Exsto has found a few ranks that are bugged!" )
		end
		
		table.insert( names, "Create New" )
		
		rankPages, rankSheets = Menu.CreateTabs( Main, names )
		
		rankSheets.Paint = function() end
		
		-- Make the things paint right.
		for k,v in pairs( rankSheets.Items ) do
			v.Tab.Paint = function( self )
				draw.RoundedBox( 4, 0, 0, self:GetWide(), self:GetTall(), self.Color )
			end
			
			v.Tab.Color = Color( 171, 255, 155, 255 )
			local oldEnter = v.Tab.OnCursorEntered
			local oldExit = v.Tab.OnCursorExited
			local oldPressed = v.Tab.OnMousePressed
			v.Tab.OnCursorEntered = function( self )
				oldEnter( self )
				if self != rankSheets:GetActiveTab() then
					self.Color = Color( 139, 255, 117, 255 )
				end
			end
			
			v.Tab.OnCursorExited = function( self )
				oldExit( self )
				if self != rankSheets:GetActiveTab() then
					self.Color = Color( 171, 255, 155, 255 )
				end
			end
			
			v.Tab.OnMousePressed = function( self )
				oldPressed( self )
				self.Color = Color( 98, 219, 75, 255 )
				self.IsActive = true
			end
			
			v.Tab.Think = function( self )
				if self != rankSheets:GetActiveTab() and self.IsActive then
					self.Color = Color( 171, 255, 155, 255 )
					self.IsActive = false
				end
			end
			v.Tab:SetFont( "tabFont" )
			v.Tab:SetTextColor( Color( 255, 255, 255, 255 ) )
		end
		
		rankSheets.m_pActiveTab.Color = Color( 98, 219, 75, 255 )
		rankSheets.m_pActiveTab.IsActive = true
		
		rankSheets.tabScroller.btnRight.Paint = function( self )
			draw.RoundedBox( 4, 0, 0, self:GetWide(), self:GetTall(), self.Color )
		end
		
		rankSheets.tabScroller.btnLeft.Paint = function( self )
			draw.RoundedBox( 4, 0, 0, self:GetWide(), self:GetTall(), self.Color )
		end
		
		rankSheets.tabScroller.btnLeft.Color = Color( 155, 228, 255, 255 )
		rankSheets.tabScroller.btnRight.Color = Color( 155, 228, 255, 255 )
		
		local CreateNew = rankPages[#rankPages]
		
		local I = 1
		for k,v in pairs( exsto.Levels ) do
			local Level = v
			local page = rankPages[I]
			
			print( "Forming a page for " .. Level.Name )

			PLUGIN.FormPage( rankPages[I], Level.Name, Level.Desc, Level.Short, Level.Derive, Level.Color, Level.CanRemove )
			
			I = I + 1
		end
		
		-- Do the broken ranks.
		for k,v in pairs( exsto.RankErrors ) do
			local Level = v[1]
			PLUGIN.FormPage( rankPages[I], Level.Name, Level.Desc, Level.Short, Level.Derive, Level.Color, true, v[2] )
			
			I = I + 1
		end
		
		PLUGIN.FormPage( CreateNew, "", "", "", "", Color( 255, 255, 255, 200 ) ) -- Create New Page

		//Menu.SetTitle( "Rank Editor" )
		
	end
	
	function PLUGIN.FormPage( panel, Name, Desc, Short, Derive, Col, CanRemove, errIssue )
		local Derive = Derive or ""
		local Short = Short or ""
		local Col = Col or Color( 255, 255, 255, 255 )
		
		local FullFlags = {}
		local NoDeriveFlags = {}
		local Immunity = 100
		
		local RealShort = Short
		if RealShort == "" then RealShort = "Create New" end

		if exsto.Levels[Short] then
			Immunity = exsto.Levels[Short].Immunity
			FullFlags = exsto.Levels[Short].Flags
			NoDeriveFlags = exsto.Levels[Short].Flags_NoDerive
		end

		-- Name Entry
		local NamePanel = exsto.CreateLabeledPanel( 5, 10, (panel:GetWide() / 2) - 20, 40, "Display Name", Color( 232, 232, 232, 255 ), panel )
		local NameEntry = exsto.CreateTextEntry( 10, 10, NamePanel:GetWide() - 20, 20, NamePanel )
			NameEntry:SetText( Name )
			NamePanel.Label:SetFont( "labeledPanelFont" )
			
			NameEntry.OnTextChanged = function( self ) Menu.CallServer( "_UpdateRankInfo", RealShort, "name", self:GetValue() ) end
	
		-- Desc Entry
		local DescPanel = exsto.CreateLabeledPanel( (panel:GetWide() / 2), 10, (panel:GetWide() / 2) - 20, 40, "Description", Color( 232, 232, 232, 255 ), panel )
		local DescEntry = exsto.CreateTextEntry( 10, 10, DescPanel:GetWide() - 20, 20, DescPanel )
			DescEntry:SetText( Desc )
			DescPanel.Label:SetFont( "labeledPanelFont" )
			
			DescEntry.OnTextChanged = function( self ) Menu.CallServer( "_UpdateRankInfo", RealShort, "desc", self:GetValue() ) end
			
		-- Short Entry
		local ShortPanel = exsto.CreateLabeledPanel( 5, 60, (panel:GetWide() / 2) - 20, 40, "Unique ID", Color( 232, 232, 232, 255 ), panel )
		local ShortEntry = exsto.CreateTextEntry( 10, 10, ShortPanel:GetWide() - 20, 20, ShortPanel )
			ShortEntry:SetText( Short )
			ShortPanel.Label:SetFont( "labeledPanelFont" )
			
			if Short != ""	then ShortEntry:SetEditable( false ) end
			
			ShortEntry.OnTextChanged = function( self ) Menu.CallServer( "_UpdateRankInfo", RealShort, "short", self:GetValue() ) end
			
		-- Derive Entry
		local DerivePanel = exsto.CreateLabeledPanel( panel:GetWide() / 2, 60, (panel:GetWide() / 2) - 20, 40, "Derive From", Color( 232, 232, 232, 255 ), panel )
		local DeriveEntry = exsto.CreateMultiChoice( 10, 10, DerivePanel:GetWide() - 20, 20, DerivePanel )
			DeriveEntry:SetText( Derive )
			DerivePanel.Label:SetFont( "labeledPanelFont" )
			DeriveEntryText = Derive

			-- Options for DeriveEntry
			for k,v in pairs( names ) do
				if v == "Create New" then v = "NONE" end
				if v:sub( 1, 6 ) != "ERROR" then
					if v != Short then 
						DeriveEntry:AddChoice( v )
					end
				end
			end

			-- Make DeriveEntry uneditable
			DeriveEntry:SetEditable( false )

		-- Color Sliders
		local ColorPanel = exsto.CreateLabeledPanel( 5, 110, (panel:GetWide() / 2) + 40, 200, "Color Selection", Color( 232, 232, 232, 255 ), panel )
		local RedSlider = exsto.CreateNumSlider( 10, 10, 100, "Red", 0, 255, 0, ColorPanel )
		local GreenSlider = exsto.CreateNumSlider( 10, 60, 100, "Green", 0, 255, 0, ColorPanel )
		local BlueSlider = exsto.CreateNumSlider( 10, 110, 100, "Blue", 0, 255, 0, ColorPanel )
		local AlphaSlider = exsto.CreateNumSlider( 10, 160, 100, "Alpha", 0, 255, 0, ColorPanel )
		
		local function onValChange( value, type )
			Menu.CallServer( "_UpdateRankInfo", RealShort, type, value )
		end
		
			RedSlider.OnValueChanged = function( self, val ) onValChange( val, "col_red" ) end
			GreenSlider.OnValueChanged = function( self, val ) onValChange( val, "col_green" ) end
			BlueSlider.OnValueChanged = function( self, val ) onValChange( val, "col_blue" ) end
			AlphaSlider.OnValueChanged = function( self, val ) onValChange( val, "col_alpha" ) end
			
			RedSlider.OnEnter = function( self, val ) onValChange( val, "col_red" ) end
			GreenSlider.OnEnter = function( self, val ) onValChange( val, "col_green" ) end
			BlueSlider.OnEnter = function( self, val ) onValChange( val, "col_blue" ) end
			AlphaSlider.OnEnter = function( self, val ) onValChange( val, "col_alpha" ) end
		
		-- Setting sliders to the correct number.
			RedSlider:SetValue( Col.r )
			GreenSlider:SetValue( Col.g )
			BlueSlider:SetValue( Col.b )
			AlphaSlider:SetValue( Col.a )
			ColorPanel.Label:SetFont( "labeledPanelFont" )
			
			RedSlider.Label:SetTextColor( Color( 120, 120, 120, 255 ) )
			GreenSlider.Label:SetTextColor( Color( 120, 120, 120, 255 ) )
			BlueSlider.Label:SetTextColor( Color( 120, 120, 120, 255 ) )
			AlphaSlider.Label:SetTextColor( Color(120, 120, 120, 255 ) )
			
		-- Color Example
	
		local ExampleLabel = exsto.CreateLabel( 130, 190, LocalPlayer():Nick(), "coolvetica", panel )
			ExampleLabel.Paint = function()
				local ExampleColor = Color( RedSlider:GetValue(), GreenSlider:GetValue(), BlueSlider:GetValue(), AlphaSlider:GetValue() )
				draw.SimpleText( ExampleLabel:GetValue(), "coolvetica", 0, 0, ExampleColor )
				return true
			end
			ExampleLabel:SetSize( 200, 40 )
	
		---- Flags ( This is going to be big )
		local w = 150
		local h = 290
		
		local FlagPanelUnused = exsto.CreateLabeledPanel( 5, 330, (panel:GetWide() / 2) - 40, 220, "Unused Flags", Color( 232, 232, 232, 255 ), panel )
		FlagPanelUnused.Label:SetFont( "labeledPanelFont" )
		
		local FlagPanelUsed = exsto.CreateLabeledPanel( (panel:GetWide() / 2) + 20, 330, (panel:GetWide() / 2) - 40, 220, "Used Flags", Color( 232, 232, 232, 255 ), panel )
		FlagPanelUsed.Label:SetFont( "labeledPanelFont" )
		
		local Flag_PossibleList = exsto.CreateListView( 5, 10, FlagPanelUnused:GetWide() - 10, 200, FlagPanelUnused )
		local Flag_UsingList = exsto.CreateListView( 5, 10, FlagPanelUsed:GetWide() - 10, 200, FlagPanelUsed )
		
		DeriveEntry.OnSelect = function( index, value, data )
			DeriveEntryText = data
			
			Menu.CallServer( "_UpdateRankInfo", RealShort, "derive", data )
			
			-- Emulate his derive moving.
			if data != "NONE" and exsto.Levels[Short] then
				exsto.Levels[Short].Derive = data
			
				PLUGIN.UpdateFlagList( Flag_UsingList, Flag_PossibleList, NoDeriveFlags, FullFlags, Short )
			end
		end
		
		Flag_PossibleList:AddColumn( " " )
		Flag_UsingList:AddColumn( " " )
		
		Flag_PossibleList:SortByColumn( 1, true )
		
		Flag_PossibleList.Color = Color( 238, 238, 238, 255 )
		Flag_PossibleList.ColumnColor = Color( 229, 229, 229, 255 )
		Flag_UsingList.Color = Color( 238, 238, 238, 255 )
		Flag_UsingList.ColumnColor = Color( 229, 229, 229, 255 )

		PLUGIN.UpdateFlagList( Flag_UsingList, Flag_PossibleList, NoDeriveFlags, FullFlags, Short )
		
		-- Create buttons between lists that shuffle flags into or out of
		local MoveAllToUsing = exsto.CreateButton( ( panel:GetWide() / 2 ) - 22, panel:GetTall() - ( FlagPanelUsed:GetTall() / 2 ) - 60, 30, 20, ">>", panel )
		local MoveToUsing = exsto.CreateButton( ( panel:GetWide() / 2 ) - 22, panel:GetTall() - ( FlagPanelUsed:GetTall() / 2 ) - 20, 30, 20, ">", panel )
		local RemoveFromUsing = exsto.CreateButton( ( panel:GetWide() / 2 ) - 22, panel:GetTall() - ( FlagPanelUsed:GetTall() / 2 ) + 20, 30, 20, "<", panel )
		local RemoveAllFromUsing = exsto.CreateButton( ( panel:GetWide() / 2 ) - 22, panel:GetTall() - ( FlagPanelUsed:GetTall() / 2 ) + 60, 30, 20, "<<", panel )
		
		MoveAllToUsing.Color = Color( 255, 155, 155 )
		MoveAllToUsing.HoverCol = Color( 255, 126, 126, 255 )
		MoveAllToUsing.DepressedCol = Color( 255, 106, 106, 255 )
		
		RemoveAllFromUsing.Color = Color( 255, 155, 155 )
		RemoveAllFromUsing.HoverCol = Color( 255, 126, 126, 255 )
		RemoveAllFromUsing.DepressedCol = Color( 255, 106, 106, 255 )
		
		RemoveAllFromUsing.DoClick = function()
			Menu.CallServer( "_UpdateRankInfo", RealShort, "flag_remall", data )
			NoDeriveFlags = {}
			PLUGIN.UpdateFlagList( Flag_UsingList, Flag_PossibleList, NoDeriveFlags, FullFlags, Short )
		end
		
		MoveAllToUsing.DoClick = function()
			for k,v in pairs( Flag_PossibleList:GetLines() ) do
				Menu.CallServer( "_UpdateRankInfo", RealShort, "flag_add", v:GetValue(1) )
				table.insert( NoDeriveFlags, v:GetValue(1) )
			end
			PLUGIN.UpdateFlagList( Flag_UsingList, Flag_PossibleList, NoDeriveFlags, FullFlags, Short )
		end
		
		-- Remove from using list
		RemoveFromUsing.DoClick = function()
			local line = Flag_UsingList:GetSelectedLine()	
			if !line then return end

			Menu.CallServer( "_UpdateRankInfo", RealShort, "flag_remove", line )
			table.remove( NoDeriveFlags, line )
			
			PLUGIN.UpdateFlagList( Flag_UsingList, Flag_PossibleList, NoDeriveFlags, FullFlags, Short )
		end
		
		-- Add to using list
		MoveToUsing.DoClick = function()
			local line = Flag_PossibleList:GetSelected()[1]	
			if !line then return end
			
			Menu.CallServer( "_UpdateRankInfo", RealShort, "flag_add", line:GetValue(1) )
			table.insert( NoDeriveFlags, line:GetValue(1) )
			
			PLUGIN.UpdateFlagList( Flag_UsingList, Flag_PossibleList, NoDeriveFlags, FullFlags, Short )
		end
		
		local ImmunityPanel = exsto.CreateLabeledPanel( (panel:GetWide() / 2) + 60, 290, ( panel:GetWide() / 2 ) - 80, 30, "Immunity", Color( 232, 232, 232, 255 ), panel )
			ImmunityPanel.Label:SetFont( "labeledPanelFont" )
		local ImmunityEntry = exsto.CreateNumSlider( 50, 2, 50, "", 0, 1000, 0, ImmunityPanel )
			ImmunityEntry:SetValue( Immunity )
			
			ImmunityEntry.OnValueChanged = function( self, val )
				Menu.CallServer( "_UpdateRankInfo", RealShort, "immunity", val )
			end
			
			ImmunityEntry.OnEnter = function( self, val )
				Menu.CallServer( "_UpdateRankInfo", RealShort, "immunity", val )
			end

		local UpdatePanel = exsto.CreateLabeledPanel( (panel:GetWide() / 2) + 60, 110, (panel:GetWide() / 2) - 80, 170, "Update / Create", Color( 232, 232, 232, 255 ), panel )
			UpdatePanel.Label:SetFont( "labeledPanelFont" )
		-- Create Button
		local text = "Update Rank"
		if Short == "" then text = "Create Rank" end
		local CUButton = exsto.CreateButton( "center", 10, 74, 27, text, UpdatePanel )
			CUButton.Color = Color( 171, 255, 155 )
			CUButton.HoverCol = Color( 143, 255, 126, 255 )
			CUButton.DepressedCol = Color( 123, 255, 106, 255 )
			CUButton:SetPos( ( UpdatePanel:GetWide() / 2 ) - ( CUButton:GetWide() / 2 ), 10 )
		
		-- Finally, Formulate changes
		CUButton.DoClick = function()
			local Name = NameEntry:GetValue()
			local Desc = DescEntry:GetValue()
			local Short = ShortEntry:GetValue()
			local Immunity = ImmunityEntry:GetValue()
			local Derive_Entry = DeriveEntryText
			if Derive_Entry == "" then Derive_Entry = Derive end
			
			local FullCol = Color( RedSlider:GetValue(), GreenSlider:GetValue(), BlueSlider:GetValue(), AlphaSlider:GetValue() )
			local Flags = NoDeriveFlags
			
			if Derive_Entry == "" then Menu.PushError( "Error: Please (re)select a derive!" ) return end
			if Name == "" then Menu.PushError( "Error: Please input a name!" ) return end
			if Desc == "" then Menu.PushError( "Error: Please input a description!" ) return end
			if Short == "" then Menu.PushError( "Error: Please input a short!" ) return end
			if !Immunity then Menu.PushError( "Error: Please select an immunity level!" ) return end
			
			PLUGIN.FormulateUpdate( Short, RealShort )
		end
		
		local DeleteButton = exsto.CreateButton( "center", 50, 74, 27, "Delete Rank", UpdatePanel )
		DeleteButton.Color = Color( 255, 155, 155 )
		DeleteButton.HoverCol = Color( 255, 126, 126, 255 )
		DeleteButton.DepressedCol = Color( 255, 106, 106, 255 )
		DeleteButton.DoClick = function()
			Menu.CallServer( "_DeleteRank", Short )
			//timer.Simple( 1, PLUGIN.ReloadMenu() )
		end
		DeleteButton:SetPos( ( UpdatePanel:GetWide() / 2 ) - ( CUButton:GetWide() / 2 ), 50 )
		DeleteButton:SetVisible( false )
		
		if CanRemove then DeleteButton:SetVisible( true ) end
		if Short == "" then DeleteButton:SetVisible( false ) end
		
		local RefreshButton = exsto.CreateButton( "center", 90, 74, 27, "Refresh Ranks", UpdatePanel )
			RefreshButton.DoClick = function( self )
				PLUGIN.ReloadMenu()
			end
			RefreshButton:SetPos( ( UpdatePanel:GetWide() / 2 ) - ( CUButton:GetWide() / 2 ), 90 )
			
		local ErrorButton = exsto.CreateButton( "center", 130, 74, 27, "View Error", UpdatePanel )
		ErrorButton.DoClick = function( self )
			Menu.PushError( PLUGIN.TranslateIssue( errIssue ) )
		end
		ErrorButton:SetPos( ( UpdatePanel:GetWide() / 2 ) - ( CUButton:GetWide() / 2 ), 130 )
		ErrorButton.Color = Color( 255, 155, 155 )
		ErrorButton.HoverCol = Color( 255, 126, 126, 255 )
		ErrorButton.DepressedCol = Color( 255, 106, 106, 255 )
		ErrorButton:SetVisible( false )
		
		if errIssue then ErrorButton:SetVisible( true ) end
	end
	
	function PLUGIN.TranslateIssue( msg )
	
		if msg == "endless derive" then
			return "The rank got stuck in an endless derive!"
		elseif msg == "self derive" then
			return "The rank is trying to derive off itself!"
		elseif msg == "nonexistant derive" then
			return "The rank is deriving off of an invalid rank!"
		end
		
	end
	
	function PLUGIN.UpdateFlagList( usingList, possibleList, NoDeriveFlags, FullFlags, short )

		local info = exsto.Levels[short]
		local derivedFlags = PLUGIN.GetDeriveFlags( short )
		local newFullFlags = {}
	
		-- Clear the lists so we can add them.
		usingList:Clear()
		possibleList:Clear()
		
		-- Loop through the new flags
		for k,v in pairs( NoDeriveFlags ) do
			
			-- Insert them into our using list.
			usingList:AddLine( v )
			PLUGIN.SetFlagTooltip( v, usingList )
			
			-- Push the flag into the new full list
			table.insert( newFullFlags, v )
			
		end
		
		-- Set up his derived flags in the same list.
		for k,v in pairs( derivedFlags ) do
			
			-- Insert them.
			local line = usingList:AddLine( v )
			local oldScheme = line.Columns[1].ApplySchemeSettings
			line.Columns[1].ApplySchemeSettings = function( self )
				oldScheme( self )
				self:SetTextColor( COLOR.NAME )
			end
			PLUGIN.SetFlagTooltip( v, usingList )
			
			-- Push the flag into the new full list
			table.insert( newFullFlags, v )
		
		end
		
		-- We are done with the rank specific list, move onto the all possible list.
		for k,v in pairs( exsto.Flags ) do
		
			-- If he doesn't exist in our new full flags, add him to the possibles.
			if !table.HasValue( newFullFlags, k ) then
			
				-- Insert
				possibleList:AddLine( k )
				PLUGIN.SetFlagTooltip( k, possibleList )
				
			end
			
		end
		
		-- Reset the full using flag list.
		FullFlags = newFullFlags
		
	end

	function PLUGIN.GetDeriveFlags( short )
		local data = exsto.Levels[short]
		local derivedflags = {}
		
		if !data then return derivedflags end
		if !data.Flags_NoDerive then return derivedflags end
		
		for k,v in pairs( data.Flags ) do -- For every one of his flags
		
			if !table.HasValue( data.Flags_NoDerive, v ) then -- If they arent in his specific then
				table.insert( derivedflags, v )
			end
		
		end
		
		return derivedflags
	end
	
	function PLUGIN.SetFlagTooltip( flag, list )
		list:GetLines()[#list:GetLines()]:SetToolTip( PLUGIN.GetFlagDescription( flag ) )
	end
	
	function PLUGIN.GetFlagDescription( flag )
		for k,v in pairs( exsto.Flags ) do
			if k == flag then return v end
		end
	end				
	
	function PLUGIN.FormulateUpdate( dataShort, RealShort )
		Menu.CallServer( "_CommitChanges", dataShort, RealShort )		
	end
	
end

PLUGIN:Register()