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


-- Clientside Menu, with adding functions

exsto.MenuTitle = exsto.Info.Version

Menu = {}
	Menu.Dialog = {}
	Menu.List = {}
	Menu.ListIndex = {}
	Menu.Create = {}
	Menu.BaseTitle = "Exsto / "
	Menu.NextPage = {}
	Menu.CurrentPage = {}
	Menu.PreviousPage = {}
	Menu.CurrentIndex = 1
	
surface.CreateFont( "arial", 17, 700, true, false, "exstoTitleMenuBold" )
surface.CreateFont( "arial", 17, 400, true, false, "exstoTitleMenu" )
surface.CreateFont( "arial", 26, 700, true, false, "exstoBottomTitleMenu" )
surface.CreateFont( "arial", 20, 700, true, false, "exstoButtons" )
surface.CreateFont( "arial", 14, 700, true, false, "exstoHelpTitle" )
surface.CreateFont( "arial", 19, 700, true, false, "exstoPlyColumn" )
surface.CreateFont( "arial", 15, 650, true, false, "exstoDataLines" )

function exsto.Menu( key )

	Menu.AuthKey = key
	local flags = exsto.Levels[LocalPlayer():GetRank()].Flags
	
	-- Set up variables
	local width = 500
	local height = 640
	
	local x = ( ScrW() / 2 ) - ( width / 2 )
	local y = ( ScrH() / 2 ) - ( height / 2 )
	
	-- Exsto redesign, 4/22/10
	-- For this, we need new info when creating menu pages.
	--	* Menu title
	--	* Flags
	--	* Size info
	
	--[[ Font Size + Color Info:
		Title, Arial 23 PX. R: 89 G: 89 B: 89
			Exsto / Formatted bold, title name not.
			
		Bottom Left Menu Title
			Arial 32 PX Bold.  R: 89 G: 89 B: 89
			
		Player List:
			Content: 238 x 3
			Text: 89 x 3
				Clicking on Text: 229 x 3
		]]
	
	-- Create main body frame.
	-- TODO: Edit layout of this frame, need to do a custom title thing.
	Menu.Frame = exsto.CreateFrame( x, y, width, height, "", true, Color( 255, 255, 255, 200 ) )
		Menu.Frame.Paint = function( frame )
			surface.SetDrawColor( 242, 242, 242, 255 )
			surface.DrawRect( 0, 0, frame:GetWide(), frame:GetTall() )
			
			surface.SetDrawColor( 4, 4, 4, 255 )
			surface.DrawOutlinedRect( 0, 0, frame:GetWide(), frame:GetTall() )
		end
		Menu.Frame.lblTitle.Paint = function( lbl )
			surface.SetFont( "exstoTitleMenu" )
			local w, h = surface.GetTextSize( lbl.TitleBase )
			
			draw.SimpleText( lbl.TitleBase, "exstoTitleMenu", 0, 0, lbl:GetTextColor() )
			draw.SimpleText( lbl.Title, "exstoTitleMenuBold", w + 1, 0, lbl:GetTextColor() )
		end
		local w, h = Menu.Frame.lblTitle:GetSize()
		Menu.Frame.lblTitle:SetSize( w + 3, h )
		Menu.Frame.lblTitle.TitleBase = Menu.BaseTitle
		Menu.Frame.lblTitle.Title = ""
		Menu.Frame:SetDeleteOnClose( false )

	-- TODO: How do we make this slide?  Display all panels at once, but set its positions back and forth?
	
	-- Create base panel to draw over.
	Menu.Background = exsto.CreatePanel( 0, 25, Menu.Frame:GetWide(), Menu.Frame:GetTall() - 40, Color( 0, 0, 0, 0 ), Menu.Frame )
	
	-- BEGIN FOOTER
	Menu.footerX = 0
	Menu.footerY = Menu.Frame:GetTall() - 40
	Menu.footerW = Menu.Frame:GetWide()
	Menu.footerH = 40
	
	Menu.Footer = exsto.CreatePanel( Menu.footerX + 1, Menu.footerY, Menu.footerW - 2, Menu.footerH - 1, Color( 0, 0, 0, 0 ), Menu.Frame )
	
	Menu.pageName = exsto.CreateLabel( 29, 10, "*UNKNOWN*", "exstoBottomTitleMenu", Menu.Footer )
	Menu.pageDMenu = exsto.CreateButton( 29, 10, Menu.pageName:GetWide(), Menu.pageName:GetTall(), "", Menu.Footer )
	
	Menu.pagePrev = exsto.CreateButton( 5, 8, 25, 25, "", Menu.Footer )
	Menu.pageNext = exsto.CreateButton( 29 + Menu.pageName:GetWide() + 9, 8, 25, 25, "", Menu.Footer )
	
	-- Logo Texture
	Menu.Footer.exstoGradient = vgui.Create( "DImage", Menu.Footer )
		Menu.Footer.exstoGradient:SetImage( "exstoGradient" )
		Menu.Footer.exstoGradient:SetSize( 210, 37 )
		Menu.Footer.exstoGradient:SetPos( Menu.Footer:GetWide() - Menu.Footer.exstoGradient:GetWide(), Menu.Footer:GetTall() - Menu.Footer.exstoGradient:GetTall())
		
	Menu.Footer.exstoLogo = vgui.Create( "DImage", Menu.Footer )
		Menu.Footer.exstoLogo:SetImage( "exstoLogo" )
		Menu.Footer.exstoLogo:SetSize( 145, 27 )
		Menu.Footer.exstoLogo:SetPos( Menu.Footer:GetWide() - Menu.Footer.exstoLogo:GetWide(), (Menu.Footer:GetTall() - Menu.Footer.exstoLogo:GetTall()) - 5 )
	
	Menu.Footer.Divider = exsto.CreatePanel( 1, 1, Menu.Footer:GetWide()-1, 1, Color( 217, 217, 217, 255 ), Menu.Footer )
	
	-- Keep the footer with the rest of the frame during position changes.
	local oldW = 0
	local oldH = 0
	local oldThink = Menu.Frame.Think
	Menu.Frame.Think = function( frame )
		local w, h = Menu.Frame:GetSize()
		
		--[[if w != oldW and h != oldH then
			oldW = w
			oldH = h
			
			-- Move footer.
			print( "MOVING!" )
			Menu.Footer:SetPos( 0, Menu.Frame:GetTall() - 40 )
			Menu.Footer.Divider:SetSize( Menu.Footer:GetWide(), 2 )
			print( Menu.Footer.exstoLogo:GetPos() )
			Menu.Footer.exstoGradient:SetPos( Menu.Footer:GetWide() - Menu.Footer.exstoGradient:GetWide(), Menu.Footer:GetTall() - Menu.Footer.exstoGradient:GetTall())
			Menu.Footer.exstoLogo:SetPos( Menu.Footer:GetWide() - Menu.Footer.exstoLogo:GetWide(), (Menu.Footer:GetTall() - Menu.Footer.exstoLogo:GetTall()) - 5 )
		end]]
		oldThink( frame )
	end
	
	Menu.pageDMenu.DoClick = function( button )
		local menu = DermaMenu()
		for k,v in pairs( Menu.List ) do
			menu:AddOption( v.Title, function() Menu.MoveToPage( v.Short ) end )
		end
		menu:Open()
	end
	
	Menu.pageDMenu.Paint = function( button )
		return
	end
	
	local textButtonPaint = function( button )
		draw.SimpleText( button.Text, "exstoBottomTitleMenu", 0, 0, button.TextColor )
		return
	end
	
	local onCursorEnter = function( button )
		button.TextColor = Color( 92, 155, 82, 200 )
	end
	
	local onCursorExit = function( button )
		button.TextColor = Color( 143, 143, 143, 255 )
	end
	
	Menu.pagePrev.OnCursorEntered = onCursorEnter
	Menu.pageNext.OnCursorEntered = onCursorEnter
	
	Menu.pagePrev.OnCursorExited = onCursorExit
	Menu.pageNext.OnCursorExited = onCursorExit
	
	Menu.pagePrev.Text = "<"
	Menu.pageNext.Text = ">"
	Menu.pagePrev.Paint = textButtonPaint
	Menu.pageNext.Paint = textButtonPaint
	
	Menu.pagePrev.TextColor = Color( 143, 143, 143, 255 )
	Menu.pageNext.TextColor = Color( 143, 143, 143, 255 )
	Menu.pageName:SetTextColor( Color( 93, 93, 93, 255 ) )
	
	Menu.CreateExtras( Menu.Background, flags )
	
	local switchPages = function( forward )
		local next = Menu.NextPage
		local prev = Menu.PreviousPage
		local current = Menu.CurrentPage
		local index = Menu.CurrentIndex
		
		if forward then
			Menu.MoveToPage( next.Short )
		else
			Menu.MoveToPage( prev.Short )
		end
	end
	
	
	Menu.pageNext.DoClick = function( button )
		switchPages( true )
	end
	
	Menu.pagePrev.DoClick = function( button )
		switchPages( false )
	end		
	
	Menu.SetTitle( Menu.CurrentPage.Title )
	
	Menu.CreateDialog()

end 
exsto.UMHook( "exsto_Menu", exsto.Menu )

function Menu.CreateDialog()
	-- Create the Anim VGUI
	Menu.Dialog.AnimBG = exsto.CreatePanel( 0, 0, Menu.Frame:GetWide(), Menu.Frame:GetTall(), Color( 255, 255, 255, 204 ), Menu.Frame )
	Menu.Dialog.Anim = vgui.Create( "DImage", Menu.Dialog.AnimBG )
		Menu.Dialog.Anim:SetImage( "exstoGenericAnim" )
		Menu.Dialog.Anim:SetKeepAspect( true )
		Menu.Dialog.Anim:SetSize( Menu.Frame:GetWide() - 100, 200 )
		Menu.Dialog.Anim:SetPos( ( Menu.Frame:GetWide() / 2 ) - ( Menu.Dialog.Anim:GetWide() / 2 ), 10 )
		
	Menu.Dialog.Msg = exsto.CreateLabel( "center", Menu.Dialog.Anim:GetTall() + 40, "", "exstoBottomTitleMenu", Menu.Dialog.AnimBG )
		Menu.Dialog.Msg:SetWrap( true )
	
	Menu.Dialog.OK = exsto.CreateButton( ( Menu.Frame:GetWide() / 2 ) - 100, Menu.Dialog.Anim:GetTall() + 70 + Menu.Dialog.Msg:GetTall(), 200, 40, "OK", Menu.Dialog.AnimBG )
	Menu.Dialog.OK.DoClick = function()
		Menu.Dialog.AnimBG:SetVisible( false )
		//Menu.Dialog.Anim:SetVisible( false )
	end
		
	Menu.Dialog.AnimBG:SetVisible( false )
	//Menu.Dialog.Anim:SetVisible( true )
end

function Menu.PushLoad()
	Menu.PushGeneric( "Loading...", nil, nil, true )
	
	-- Time out incase its "too" long.
	timer.Create( "exstoLoadTimeout", 10, 1, function() if Menu.Dialog.IsLoading then Menu.PushError( "Error: Loading timed out!" ) end end )
end

function Menu.EndLoad()
	if !Menu.Frame then return end

	if !Menu.Dialog.IsLoading then return end
	
	Menu.Dialog.AnimBG:SetVisible( false )
	
	Menu.Dialog.IsLoading = false
end

function Menu.PushError( msg )
	Menu.PushGeneric( msg, "exstoErrorAnim", Color( 170, 92, 92, 255 ) )
end

function Menu.PushGeneric( msg, imgTexture, textCol, loading )

	print( "Pushing a notification!", msg, imgTexture or "none", tostring( textCol ) or "none", tostring( loading ) or "not loading" )
	if Menu.Dialog.AnimBG and Menu.Dialog.Anim and Menu.Dialog.Msg then
		if Menu.Dialog.IsLoading and !loading then Menu.EndLoad() end
		if !Menu.Dialog.IsLoading and loading then Menu.Dialog.IsLoading = loading end
		
		Menu.Dialog.Anim:SetImage( imgTexture or "exstoGenericAnim" )
		Menu.Dialog.Msg:SetText( msg )
		
		surface.SetFont( "exstoBottomTitleMenu" )
		local w, h = surface.GetTextSize( msg )
		
		Menu.Dialog.Msg:SetSize( w, h )
		Menu.Dialog.Msg:SetPos( (Menu.Dialog.AnimBG:GetWide() / 2) - (Menu.Dialog.Msg:GetWide() / 2), Menu.Dialog.Anim:GetTall() + 40 )
		Menu.Dialog.Msg:SetTextColor( Color( 109, 170, 92, 255 ) )
		if textCol then
			Menu.Dialog.Msg:SetTextColor( textCol )
		end

		if loading then
			Menu.Dialog.OK:SetVisible( false )
		else
			Menu.Dialog.OK:SetVisible( true )
		end
		
		Menu.Dialog.AnimBG:InvalidateLayout()
		Menu.Dialog.AnimBG:SetVisible( true )
		
		return
	end

end

function Menu.CallServer( command, ... )
	RunConsoleCommand( command, Menu.AuthKey, ... )
end
	
function Menu.GetPageIndex( short )
	for k,v in pairs( Menu.ListIndex ) do
		if v == short then return k end
	end
end

function Menu.MoveToPage( short )

	local page = Menu.List[short]
	local index = Menu.GetPageIndex( short )
	
	//Menu.CurrentPage.Panel:SetVisible( false )
	local oldCurrent = Menu.CurrentPage.Panel
	local oldIndex = Menu.CurrentIndex
	
	Menu.PreviousPage = Menu.List[Menu.ListIndex[index - 1]] or Menu.List[Menu.ListIndex[#Menu.ListIndex]]
	Menu.CurrentPage = page
	Menu.NextPage = Menu.List[Menu.ListIndex[index + 1]] or Menu.List[Menu.ListIndex[1]]
	
	Menu.CurrentIndex = index
	
	Menu.SetTitle( Menu.CurrentPage.Title )
	//Menu.CurrentPage.Panel:SetVisible( true )
	
	-- Nice little effect.
	
	-- If we are moving right
	local oldW, oldH = oldCurrent:GetSize() 
		
	if oldIndex < Menu.CurrentIndex  then
		Menu.CurrentPage.Panel:SetVisible( true )
		
		Menu.CurrentPage.Panel:SetPos( oldW, 0 )
		Menu.CurrentPage.Panel:MoveTo( 0, 0, 0.5, 0, 8 )
		
		oldCurrent:MoveTo( -oldW - 1, 0, 0.5, 0, 8 )
	else
		Menu.CurrentPage.Panel:SetVisible( true )
		
		Menu.CurrentPage.Panel:SetPos( -oldW, 0 )
		Menu.CurrentPage.Panel:MoveTo( 0, 0, 0.5, 0, 8 )
		
		oldCurrent:MoveTo( oldW + 1, 0, 0.5, 0, 8 )
	end
	
end

function Menu.CreateExtras( bg, flags )

	-- Kill all old pages.
	Menu.List = {}

	for k,v in pairs( Menu.Create ) do

		if table.HasValue( flags, v.Flag ) then
	
			exsto.Print( exsto_CONSOLE_DEBUG, "MENU --> Creating menu page " .. v.Title .. "!" )
		
			if !v.Wide then v.Wide = bg:GetWide() - 1 end
			if !v.Tall then v.Tall = bg:GetTall() - 22 end
		
			local status, err = pcall( v.Function, bg, v.Wide, v.Tall )
			
			if !status then
				Menu.PushError( "Error creating page \"" .. tostring( v.Title ) .. "\"!" )
				ErrorNoHalt( tostring( err ) )
				Menu.List[v.Short] = nil
				for k,v in pairs( Menu.ListIndex ) do
					if v == v.Short then Menu.ListIndex[k] = nil end
				end
			else
			
				if v.Default then
					Menu.List[v.Short].Panel:SetVisible( true )
				end
				
			end
			
		end
		
	end
	
	-- Set current page + next ones.
	for k,v in pairs( Menu.ListIndex ) do
		if Menu.List[v].Default then
			exsto.Print( exsto_CONSOLE_DEBUG, "MENU --> Found a default page, setting it to current!" )
			Menu.CurrentPage = Menu.List[v]
			
			if k - 1 < 1 then
				Menu.PreviousPage = Menu.List[Menu.ListIndex[#Menu.ListIndex]]
			else
				Menu.PreviousPage = Menu.List[Menu.ListIndex[k - 1]]
			end
			
			if k + 1 > #Menu.ListIndex then
				Menu.NextPage = Menu.List[Menu.ListIndex[1]]
			else
				Menu.NextPage = Menu.List[Menu.ListIndex[k + 1]]
			end

			break
		end
	end
	
	-- If we still are missing a current page...
	if !Menu.CurrentPage.Panel then
		exsto.Print( exsto_CONSOLE_DEBUG, "MENU --> No default page found!  Setting current to first in index!" )
		
		Menu.CurrentPage = Menu.List[Menu.ListIndex[1]]
		Menu.PreviousPage = Menu.List[#Menu.ListIndex]
		Menu.NextPage = Menu.List[Menu.ListIndex[2]]
	end
	
end

function Menu.CreatePage( info, func )

	if type( info ) != "table" then Error( "MENU --> \"" .. tostring( info ) .. "\" is not compatible with Exsto!  Please contact the creator of the plugin!" ) end

	local title = info.Title
	local short = info.Short
	local flag = info.Flag
	local wide = info.Wide
	local tall = info.Tall
	local default = info.Default
	
	table.insert( Menu.Create, { Title = title, Flag = flag, Wide = wide, Tall = tall, Default = default, Short = short, Function = 
	
	function( bg, wide, tall )
		local page = vgui.Create( "DPanel", bg )
			page:SetSize( wide, tall )
			page:SetPos( 0, 0 )
		
			page.Paint = function()
				surface.SetDrawColor( 0, 0, 0, 0 )
				surface.DrawRect( 0, 0, page:GetWide(), page:GetTall() )
			end

			page:SetVisible( false )
			
		func( page )
		
		local data = {
			Title = title,
			Short = short,
			Default = default,
			Flag = flag,
			Wide = wide,
			Tall = tall,
			Panel = page,
		}
			
		Menu.AddToPanelList( data )
	end
	} )
	
end

function Menu.SetTitle( text )
	Menu.Frame.lblTitle.Title = text
	Menu.pageName:SetText( text )
	Menu.Frame.lblTitle:SetTextColor( Color( 89, 89, 89, 255 ) )
	
	surface.SetFont( "exstoBottomTitleMenu" )
	local w, h = surface.GetTextSize( text )

	Menu.pageName:SetSize( w, h )
	Menu.pageNext:SetPos( 29 + w + 9, 8 )
end

function Menu.SetSize( panel )
	local width = panel.Wide
	local height = panel.Tall
	
	Menu.Frame:SizeTo( width, height + 23 + Menu.footerH, 1, 0, 2 )
	Menu.Background:SizeTo( width, height, 1, 0, 2 )
end

function Menu.CreateTabs( panel, tab )

	local num = #tab
	local panels = {}
	
	local sheet = vgui.Create( "DPropertySheet", panel )
		sheet:SetPos( 3, 0 )
		sheet:SetSize( panel:GetWide() - 6, panel:GetTall()  )

	for I = 1, num do
		
		local page = vgui.Create( "DPanel" )
			page:SetPos( 0, 0 )
			page:SetSize( panel:GetWide(), panel:GetTall() - 50 )
			
			page.Paint = function()
				surface.SetDrawColor( 242, 242, 242, 255 )
				surface.DrawRect( 0, 0, page:GetWide(), page:GetTall() )
			end
		
		table.insert( panels, page )
		sheet:AddSheet( tab[I], page, false, false, false, "Editor for " .. tab[I] )
		
	end
	
	return panels, sheet
	
end

function Menu.AddToPanelList( info )
	
	Menu.List[info.Short] = {
		Title = info.Title,
		Short = info.Short,
		Default = info.Default,
		Flag = info.Flag,
		Wide = info.Wide,
		Tall = info.Tall,
		Panel = info.Panel,
	}
	
	-- Create an indexed list of the pages.
	table.insert( Menu.ListIndex, info.Short )

end

Menu.CreatePage( {
	Title = "Player List",
	Short = "playerlist",
	Default = true,
	Flag = "playerlist",
	},
	function( panel )
		local Reasons = {
			"Mingebag",
			"Requested",
			"Asshat",
			"\"We don't like you\"",
			"\"Sorry bro.\"",
			"\"No Reason\"",
		}
		
		local Times = {
			"Forever",
			"1 Hour",
			"5 Hours",
			"1 Day",
			"1 Week",
			"1 Month",
		}
		
		local plylist = exsto.CreateListView( 10, 10, panel:GetWide() - 20, panel:GetTall() - 60, panel )
			plylist.Color = Color( 224, 224, 224, 255 )
			
			plylist.HoverColor = Color( 229, 229, 229, 255 )
			plylist.SelectColor = Color( 149, 227, 134, 255 )
			
			plylist:SetHeaderHeight( 40 )
			plylist.Round = 8
			plylist.ColumnFont = "exstoPlyColumn"
			plylist.ColumnTextCol = Color( 140, 140, 140, 255 )

			plylist.LineFont = "exstoDataLines"
			plylist.LineTextCol = Color( 164, 164, 164, 255 )
			
			plylist:AddColumn( "Player" )
			plylist:AddColumn( "SteamID" ):SetFixedWidth( 145 )
			plylist:AddColumn( "Rank" )
			plylist:AddColumn( "Ping" ):SetFixedWidth( 45 )
			
			plylist.UpdatePlayers = function()
				plylist.Players = {}
				plylist:Clear()
				
				for k,v in pairs( player.GetAll() ) do
					table.insert( plylist.Players, v )
				end
				
				for k,v in pairs( plylist.Players ) do
					local line = plylist:AddLine( v:Name(), v:SteamID(), v:GetRank(), v:Ping() )
					local oldScheme = line.ApplySchemeSettings
					-- Rank Color
					local oldSettings = line.Columns[3].ApplySchemeSettings
					line.Columns[3].ApplySchemeSettings = function( self )
						oldSettings( self )
						self:SetTextColor( exsto.GetRankColor( v:GetRank() ) )
					end
					
					-- Pingggggg
					local oldSettings = line.Columns[4].ApplySchemeSettings
					line.Columns[4].ApplySchemeSettings = function( self )
						oldSettings( self )
						if v:Ping() > 150 then
							self:SetTextColor( COLOR.NAME )
						end
					end
				end
			end
			
			local lastThink = 1;
			plylist.Think = function()
				if CurTime() > lastThink then
					lastThink = CurTime() + 10
					plylist.UpdatePlayers()
				end
			end
			plylist.UpdatePlayers()
			
		local function GetSelected()
			if plylist:GetSelected()[1] then
				if plylist:GetSelected()[1]:GetValue(1) then
					return plylist:GetSelected()[1]:GetValue(1)
				else return nil end
			else return nil end
		end
			
		if LocalPlayer():IsAdmin() then
			local kickButton = exsto.CreateButton( (panel:GetWide() / 2) - 74 * 2, panel:GetTall() - 40, 74, 27, "Kick", panel )
				kickButton.DoClick = function( button )
					local ply = GetSelected()
					if ply then
						local menu = DermaMenu()
						for k,v in pairs( Reasons ) do
							menu:AddOption( v, function() LocalPlayer():ConCommand( "exsto_Kick \'" .. ply .. "\' " .. v ) plylist.UpdatePlayers() end )
						end
						menu:Open()
					end
				end
				kickButton.Color = Color( 255, 155, 155, 255 )
				kickButton.HoverCol = Color( 255, 126, 126, 255 )
				kickButton.DepressedCol = Color( 255, 106, 106, 255 )
				
			local banButton = exsto.CreateButton( (panel:GetWide() / 2) - ( 74 / 2 ), panel:GetTall() - 40, 74, 27, "Ban", panel )
				banButton.DoClick = function( button )
					local ply = GetSelected()
					if ply then
						local menu = DermaMenu()
						for k,v in pairs( Times ) do
							if v == "Forever" then v = 0 end
							if v == "1 Hour" then v = 60 end
							if v == "5 Hours" then v = 60 * 5 end
							if v == "1 Day" then v = 60 * 24 end
							if v == "1 Week" then v = (60 * 24) * 7 end
							if v == "1 Month" then v = ((60 * 24) * 7) * 4 end
							menu:AddOption( v, function() LocalPlayer():ConCommand( "exsto_Ban \'" .. ply .. "\' " .. v ) plylist.UpdatePlayers() end )
						end
						menu:Open()
					end
				end
				banButton.Color = Color( 255, 155, 155, 255 )
				banButton.HoverCol = Color( 255, 126, 126, 255 )
				banButton.DepressedCol = Color( 255, 106, 106, 255 )
				
			local rankButton = exsto.CreateButton( (panel:GetWide() / 2) + 74, panel:GetTall() - 40, 74, 27, "Rank", panel )
				rankButton.DoClick = function( button )
					local ply = GetSelected()
					if ply then
						if ply == LocalPlayer():Nick() then
							Menu.PushError( "Error: You cannot change your own rank!" )
							return
						end
						local menu = DermaMenu()
						for k,v in pairs( exsto.Levels ) do
							menu:AddOption( v.Name, function() LocalPlayer():ConCommand( "exsto_SetAccess \'" .. ply .. "\' " .. v.Short ) plylist.UpdatePlayers() end )
						end
						menu:Open()
					end
				end
				rankButton.Color = Color( 171, 255, 155, 255 )
				rankButton.HoverCol = Color( 143, 255, 126, 255 )
				rankButton.DepressedCol = Color( 123, 255, 106, 255 )
		end
	end
)

Menu.CreatePage( {
	Title = "Exsto Help",
	Short = "exstohelp",
	Flag = "helppage",
	},
	function( panel )
	
		surface.SetFont( "default" )
		
		local function RecieveHelp( contents, size )
			local verStart, verEnd, verTag, version = string.find( contents, "(%[helpver=(%d+%.%d+)%])" )
			
			if !version then
				
				return
			end
			
			-- Create table on the info we have.
			local help = {}
			
			local sub = string.sub( contents, verEnd + 1 ):Trim()
			local capture = string.gmatch( sub, "%[title=([%w%s%p]-)%]([%w%s%p]-)%[/title%]" )
			
			for k,v in capture do
				help[k] = v
			end

			local list = exsto.CreatePanelList( 5, 0, panel:GetWide() - 10, panel:GetTall() - 50, 10, false, true, panel )
				list.Color = Color( 229, 229, 229, 0 )
				
			for k,v in pairs( help ) do
				local w, h = surface.GetTextSize( k )

				local label = exsto.CreateLabel( 15, 0, v, "default" )
					label:SetWrap( true )
					label:SetTextColor( Color( 60, 60, 60, 255 ) )
					
				local category = exsto.CreateCollapseCategory( 0, 0, w + 10, label:GetTall() + 30, k )
					category.Color = Color( 229, 229, 229, 255 )
					category.Header.TextColor = Color( 60, 60, 60, 255 )
					category.Header.Font = "exstoHelpTitle" 
					
				category:SetContents( label )
				list:AddItem( category )
			end
			
		end
		http.Get( "http://94.23.154.153/Exsto/helpdb.txt", "", RecieveHelp )
	end
)

-- Small Log Viewer
local lview = {}

	lview.Lines = {}
	
	lview.X = 30
	lview.Y = 5
	lview.Font = "ChatText"
	
	lview.StayTime = 10
	
function lview.LogPrint( ... )

	local data = ""
	local numColors = 0
	
	for k,v in pairs( {...} ) do

		if type( v ) == "table" then
			
			if numColors >= 1 then
				data = data .. "[/c]"
			end
		
			data = data .. "[c=" .. v.r .. "," .. v.g .. "," .. v.b .. "," .. v.a .. "]"
			
			numColors = numColors + 1
			
		elseif type( v ) == "Player" then
		
			local rank = v:GetRank()
			local col = exsto.GetRankColor( rank )
			
			data = data .."[c=" .. col.r .. "," .. col.g .. "," .. col.b .. "," .. col.a .. "]"
			data = data .. v:Nick()
			data = data .. "[/c]"
			
		elseif type( v ) == "string" then
		
			data = data .. v
			
		end
		
	end
	
	lview.ParseLine( data )
	
end
exsto.UMHook( "exsto_LogPrint", lview.LogPrint )

function lview.ParseLine( line )

	surface.SetFont( lview.Font )

	local data = {}
		data.Type = {}
		data.Value = {}
		data.Text = {}
		data.Width = {}
		data.Length = {}
		
	local toParse = line
	local id = 1
	local total_w = 0
	
	while toParse != "" do
	
		local clStart, clEnd, clTag, clR, clG, clB, clA = string.find( toParse, "(%[c=(%d+),(%d+),(%d+),(%d+)%])" )

		if clStart then
			
			if clStart == 1 then
			
				local colEndStart, colEndEnd, colEnd = string.find( toParse, "(%[/c%])" )
				if colEndStart then colEndStart = colEndStart - 1 else colEndStart = string.len( toParse ) end
				colEndEnd = colEndEnd or string.len( toParse )
				
				local text = string.sub( toParse, clEnd + 1, colEndStart )
				local w, h = surface.GetTextSize( text )
				
				table.insert( data.Type, id, 2 )
				table.insert( data.Value, id, Color( clR, clG, clB, clA ) )
				table.insert( data.Text, id, text )
				table.insert( data.Width, id, w )
				
				total_w = total_w + w
				
				if colEndEnd then toParse = string.sub( toParse, colEndEnd + 1 ) else toParse = "" end
				
			elseif clStart > 1 then
			
				local text = string.sub( toParse, 1, clStart - 1 )
				local w, h = surface.GetTextSize( text )
				
				total_w = total_w + w
				
				table.insert( data.Width, id, w )
				table.insert( data.Type, id, 1 )
				table.insert( data.Text, id, text )
				
				toParse = string.sub( toParse, clStart, string.len( toParse ) )
				
			end
			
			id = id + 1
			
		else
		
			local w, h = surface.GetTextSize( toParse )
			
			table.insert( data.Type, id, 1 )
			table.insert( data.Text, id, toParse )
			table.insert( data.Width, id, w )
			
			total_w = total_w + w
			
			toParse = ""
			id = id + 1
			
		end
		
	end
	
	data.Length = id
	data.Time = CurTime() + lview.StayTime
	data.Alpha = 255
	data.Last_Y = 0
	data.Last_X = 0
	data.Total_W = total_w
	table.insert( lview.Lines, data )			
	
end

function lview.DrawBox( x, y, width )

	surface.SetDrawColor( 50, 50, 50, 100 )
	surface.DrawRect( x - 5, y - 2, width + 10, 22 )
	
	surface.SetDrawColor( 255, 255, 255, 100 )
	surface.DrawOutlinedRect( x - 5, y - 2, width + 10, 22 )
	--surface.DrawOutlinedRect( pchat.X, pchat.Y, pchat.G_W, 20 )
	
end

function lview.DrawLine( x, y, line )
	
	surface.SetFont( lview.Font ) 
	
	local outline = Color( 0, 0, 0, line.Alpha / 2 )

	local pw = 0

	local curX = x
	local curY = y																																						
	local num = line.Length
	local total_w = line.Total_W	
	
	lview.DrawBox( curX, curY, total_w )
	
	for I = 1, line.Length do
	
		local t = line.Type[I]
		local w = line.Width[I]
		local val = line.Value[I]
		local text = line.Text[I]		
		
		if t == 1 then
		
			draw.SimpleTextOutlined( text, lview.Font, curX, curY, Color( 255, 255, 255, line.Alpha ), 0, 0, 1, outline )
			
		elseif t == 2 then
		
			draw.SimpleTextOutlined( text, lview.Font, curX, curY, Color( val.r, val.g, val.b, line.Alpha ), 0, 0, 1, outline )
			
		end
		
		if w then curX = curX + w or curX end
		
	end

end
	
function lview.Draw()

	surface.SetFont( lview.Font )
	
	local _, lineHeight = surface.GetTextSize( "H" )
	local curX = lview.X
	local curY = lview.Y
	
	for I = 0, 5 do
	
		local line = lview.Lines[ #lview.Lines - I ]
		
		if not line then return end
		
		if line.Last_Y != curY then
		
			local dist = curY - line.Last_Y
			local speed = dist / 40
			
			line.Last_Y = math.Approach( line.Last_Y, curY, speed )
			
		end
		
		if line.Time < CurTime() then																								
		
			curX = 0 - line.Total_W - 30
			
			if line.Last_X <= curX + 10 then
			
				lview.Lines[ #lview.Lines - I ] = nil
				
			end
			
		end
		
		if line.Last_X != curX then
			
			local dist = curX - line.Last_X
			local speed = dist / 40
			
			line.Last_X = math.Approach( line.Last_X, curX, speed )
			
		end
		
		lview.DrawLine( line.Last_X, line.Last_Y, line )
		
		curY = curY + lineHeight + 2
		
	end
	
end
hook.Add( "HUDPaint", "exsto_DrawSimpleLog", lview.Draw )
