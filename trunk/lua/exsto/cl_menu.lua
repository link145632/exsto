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

--[[ -----------------------------------
	Function: exsto.Menu
	Description: Opens up the Exsto menu.
	----------------------------------- ]]
function exsto.Menu( key )

	Menu.AuthKey = key
	local flags = exsto.Levels[LocalPlayer():GetRank()].Flags
	
	-- Set up variables
	local width = 500
	local height = 640
	
	local x = ( ScrW() / 2 ) - ( width / 2 )
	local y = ( ScrH() / 2 ) - ( height / 2 )

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

--[[ -----------------------------------
	Function: Menu.CreateDialog
	Description: Creates a small notification dialog.
	----------------------------------- ]]
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
	end
		
	Menu.Dialog.AnimBG:SetVisible( false )
end

--[[ -----------------------------------
	Function: Menu.PushLoad
	Description: Shows a loading screen
	----------------------------------- ]]
function Menu.PushLoad()
	Menu.PushGeneric( "Loading...", nil, nil, true )
	
	-- Time out incase its "too" long.
	timer.Create( "exstoLoadTimeout", 10, 1, function() if Menu.Dialog.IsLoading then Menu.PushError( "Error: Loading timed out!" ) end end )
end

--[[ -----------------------------------
	Function: Menu.EndLoad
	Description: Ends the active loading screen.
	----------------------------------- ]]
function Menu.EndLoad()
	if !Menu.Frame then return end

	if !Menu.Dialog.IsLoading then return end
	
	Menu.Dialog.AnimBG:SetVisible( false )
	
	Menu.Dialog.IsLoading = false
end

--[[ -----------------------------------
	Function: Menu.PushError
	Description: Shows an error screen
	----------------------------------- ]]
function Menu.PushError( msg )
	Menu.PushGeneric( msg, "exstoErrorAnim", Color( 170, 92, 92, 255 ) )
end

--[[ -----------------------------------
	Function: Menu.PushGeneric
	Description: Shows a generic question screen
	----------------------------------- ]]
function Menu.PushGeneric( msg, imgTexture, textCol, loading )

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

--[[ -----------------------------------
	Function: Menu.CallServer
	Description: Calls a server function
	----------------------------------- ]]
function Menu.CallServer( command, ... )
	RunConsoleCommand( command, Menu.AuthKey, ... )
end
	
--[[ -----------------------------------
	Function: Menu.GetPageIndex
	Description: Gets an index of a page.
	----------------------------------- ]]
function Menu.GetPageIndex( short )
	for k,v in pairs( Menu.ListIndex ) do
		if v == short then return k end
	end
end

--[[ -----------------------------------
	Function: Menu.MoveToPage
	Description: Moves to a page
	----------------------------------- ]]
function Menu.MoveToPage( short )

	local page = Menu.List[short]
	local index = Menu.GetPageIndex( short )
	
	local oldCurrent = Menu.CurrentPage.Panel
	local oldIndex = Menu.CurrentIndex
	
	Menu.PreviousPage = Menu.List[Menu.ListIndex[index - 1]] or Menu.List[Menu.ListIndex[#Menu.ListIndex]]
	Menu.CurrentPage = page
	Menu.NextPage = Menu.List[Menu.ListIndex[index + 1]] or Menu.List[Menu.ListIndex[1]]
	
	Menu.CurrentIndex = index
	
	Menu.SetTitle( Menu.CurrentPage.Title )

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

--[[ -----------------------------------
	Function: Menu.CreateExtras
	Description: Creates the pages
	----------------------------------- ]]
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

--[[ -----------------------------------
	Function: Menu.CreatePage
	Description: Creates a menu page for the Exsto menu
	----------------------------------- ]]
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

--[[ -----------------------------------
	Function: Menu.SetTitle
	Description: Sets the title of the menu frame and bottom list.
	----------------------------------- ]]
function Menu.SetTitle( text )
	Menu.Frame.lblTitle.Title = text
	Menu.pageName:SetText( text )
	Menu.Frame.lblTitle:SetTextColor( Color( 89, 89, 89, 255 ) )
	
	surface.SetFont( "exstoBottomTitleMenu" )
	local w, h = surface.GetTextSize( text )

	Menu.pageName:SetSize( w, h )
	Menu.pageNext:SetPos( 29 + w + 9, 8 )
end

--[[ -----------------------------------
	Function: Menu.CreateTabs
	Description: Creates PropertySheet tabs
	----------------------------------- ]]
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

--[[ -----------------------------------
	Function: Menu.AddToPanelList
	Description: Adds a page to the menu list.
	----------------------------------- ]]
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