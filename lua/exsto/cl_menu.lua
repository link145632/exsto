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
	Menu.DefaultPage = {}
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
	
	-- If this baby already exists, just set him as visible
	if Menu.Frame then
		-- If we are not the same rank as we were before, update the content we can see.
		if Menu.LastRank != LocalPlayer():GetRank() then
			Menu.LastRank = LocalPlayer():GetRank()
			
			for k,v in pairs( Menu.List ) do
				v.Panel:Remove()
			end
			
			Menu.List = {}
			Menu.ListIndex = {}
			Menu.NextPage = {}
			Menu.CurrentPage = {}
			Menu.DefaultPage = {}
			Menu.PreviousPage = {}
			Menu.CreateExtras( Menu.Background, flags )
			
			Menu.SetTitle( Menu.DefaultPage.Title )
		end

		Menu.Frame:SetVisible( true )
		return 
	end
	
	Menu.LastRank = LocalPlayer():GetRank()
	
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
		if forward then
			Menu.MoveToPage( Menu.NextPage.Short )
		else
			Menu.MoveToPage( Menu.PreviousPage.Short )
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
	RunConsoleCommand( command, Menu.AuthKey, unpack( {...} ) )
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
	
	if short == Menu.CurrentPage.Short then return end
	
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
		if Menu.List[v] and Menu.List[v].Default then
			exsto.Print( exsto_CONSOLE_DEBUG, "MENU --> Found a default page, setting it to current!" )
			Menu.CurrentPage = Menu.List[v]
			Menu.DefaultPage = Menu.List[v]
			
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

--[[ -----------------------------------
	Category: Quick Menu
	----------------------------------- ]]
QMenu = {}

function QMenu:Initialize()

	self:BuildPlayerList()
	self:BuildActionList()

	self.ActionList:AddCategory( "Administration", "hot" )
	self.ActionList:AddCategory( "Fun", "cool" )
	self.ActionList:AddCategory( "Access", "hot" )
	self.ActionList:AddCategory( "Restriction", "cool" )
	self.ActionList:AddCategory( "Misc" )
	
	self.ActionList:AddItem( "Administration", "kick" )
	self.ActionList:AddItem( "Administration", "ban" )
	
	self.ActionList:AddItem( "Fun", "rape" )
	
	self.ActionList:Build()
end

function QMenu:BuildActionList()

	local wide = ScrW() - 20
	local tall = 30
	
	local openx = 10
	local openy = ScrH() - tall - 10
	
	local closex = 10
	local closey = ScrH() + 40

	self.ActionList = exsto.CreatePanel( closex, closey, wide, tall, Color( 255, 255, 255, 255 ) )

	self.ActionList.Categories = {}
	self.ActionList.Commands = {}
	self.ActionList.CommandLists = {}
	self.ActionList.Buttons = {}
	self.ActionList.ScreenArea = ScrW() - 20

	self.ActionList.Build = function( self )
		-- Get the size of the buttons we can use.
		local size = self.ScreenArea / #self.Categories
		
		local button, combutton
		local curX = 0
		for k,v in ipairs( self.Categories ) do
			button = exsto.CreateButton( curX, 0, size, self:GetTall(), v.Name, self )
			if v.Style then button:SetStyle( v.Style ) end
			
			button.Category = v.Name
			
			button.SaveExpandData = function( self )
				local _x, _y = self:GetPos()
				local _w, _h = self:GetSize()
				
				self.ExpandData = {
					x = _x,
					y = _y,
					w = _w,
					h = _h,
				}
			end
			
			button.DoClick = function( self )
				if !self:GetParent():Locked() then
					self:GetParent():ExpandButton( self.Category )
					self:GetParent():LockCurrent( self )
					self.CommandLink:Open()
				elseif self:GetParent():Locked() then
					self:GetParent():UnlockCurrent()
					self:GetParent():ResetButtons()
					self.CommandLink:Close()
				end
			end
			
			button.OnCursorEntered = function( self )
				//self:GetParent():ExpandButton( self.Category )
			end
			
			button.OnCursorExited = function( self )
				//self:GetParent():ResetButtons()
			end

			if self.Commands[ v.Name ] then
				
				local curX = curX + 20
			
				self.CommandLists[ v.Name ] = exsto.CreatePanelList( ( curX + ( size / 2 ) ) - ( size / 4 ) + 10, 0, size / 2, 300, 5, false, true )
				local comlist = self.CommandLists[ v.Name ] 
				
				comlist.ButtonLink = button
				button.CommandLink = self.CommandLists[ v.Name ] 
				
				comlist.Open = function( self )
					local x, y = self.ButtonLink:GetPos()
					self:SetPos( ( x + ( self.ButtonLink:GetWide() / 2 ) ) - ( self:GetWide() / 2 ) + 10, openy - self:GetTall() )
					self:FadeAlpha( 255 )
				end
				
				comlist.Close = function( self )
					local x, y = self.ButtonLink:GetPos()
					self:SetPos( ( x + ( self.ButtonLink:GetWide() / 2 ) ) - ( self:GetWide() / 2 ) + 10, openy + 20  )
					self:FadeAlpha( 0 )
				end

				local think, col
				local curH = 0
				for _, command in ipairs( self.Commands[ v.Name ] ) do
					
					combutton = exsto.CreateButton( 0, 0, comlist:GetWide(), 30, command )
					
					local a = 0
					if combutton.Think then think = combutton.Think end
					combutton.Think = function( self )
						if think then think( self ) end
						
						a = comlist.AnimTable[ 8 ].Last
						
						col = self.Color
						col.a = a
						self.Color = col
						
						col = self.HoverCol
						col.a = a
						self.HoverCol = col
						
						col = self.DepressedCol
						col.a = a
						self.DepressedCol = col
					end
					
					comlist:AddItem( combutton )
					
					curH = curH + 35
					
				end
				
				comlist:SetTall( curH )
				
				QMenu:AnimateObject( comlist, 20, true )
				comlist:Close()
			end
			
			self.Buttons[ v.Name ] = button
			curX = curX + size
		end
		
	end
	
	self.ActionList.Locked = function( self )
		if self._LockedButton then return true end
		return false
	end
	
	self.ActionList.UnlockCurrent = function( self )
		if !self._LockedButton then return end
		self._LockedButton.CommandLink:Close()
		self._LockedButton = nil
	end
	
	self.ActionList.LockCurrent = function( self, button )
		self._LockedButton = button
	end
	
	self.ActionList.SetHovered = function( self, button )
		self.HoveredButton = button
	end
	
	self.ActionList.GetHovered = function( self )
		return self.HoveredButton
	end
	
	self.ActionList.ResetButtons = function( self )
		if self:Locked() then return end
		if #self.Categories <= 2 then return end
		
		local expandData, button
		for k,v in ipairs( self.Categories ) do
			button = self.Buttons[ v.Name ]
			expandData = button.ExpandData
			
			button:SetSize( expandData.w, expandData.h )
			button:SetPos( expandData.x, expandData.y )
			
			button.ExpandData = {}
		end
		
		self:SetHovered( nil )
	end
	
	self.ActionList.ExpandButton = function( self, category )
		if self:Locked() then return end
		if #self.Categories <= 2 then return end
		
		local foundIndex
		for k,v in ipairs( self.Categories ) do
			if v.Name == category then foundIndex = k break end
		end
		
		if !foundIndex then return end		
		
		self:SetHovered( self.Buttons[ foundIndex ] )
		
		local w, button
		local curX = 0
		local newSize = 0
		for I = 1, #self.Categories do
			button = self.Buttons[ self.Categories[ I ].Name ]
			w = button:GetWide() / 2

			button:SaveExpandData()
			
			if I == foundIndex then
				w = w * ( #self.Categories + 1 )
			end

			button:SetWide( w )
			button:SetPos( curX, 0 )
			
			newSize = newSize + w
			curX = curX + w
		end

	end
	
	self.ActionList.AddItem = function( self, category, command )
		local tbl = self.Commands[ category ]
		if !tbl then self.Commands[ category ] = { command } end
		
		tbl = table.Add( tbl, { command } )
		self.Commands[ category ] = tbl
	end
	
	self.ActionList.AddCategory = function( self, name, style )
		table.insert( self.Categories, { Name = name, Style = style } )
	end

	self.ActionList.Open = function( self )
		self:SetPos( openx, openy )
	end
	
	self.ActionList.Close = function( self )
		self:SetPos( closex, closey )
		
		if self:Locked() then
			self:UnlockCurrent()
			self:ResetButtons()
		end
	end
	
	self:AnimateObject( self.ActionList )
	
end

function QMenu:BuildPlayerList()

	local wide = 300
	local tall = 400
	
	local openx = ScrW() - wide - 50
	local openy = 5
	
	local closex = openx
	local closey = ( tall * -1 ) - 5
	
	self.PlayerSheet = exsto.CreatePanelList( closex, closey, wide, tall, 5, false, true )
	self.PlayerSheet:SetVisible( true )
	
	self.PlayerSheet.Update = function( self )
		self:Clear()
		local button
		
		for k,v in ipairs( player.GetAll() ) do
			button = exsto.CreateButton( 0, 0, self:GetWide(), 40, v:Nick() )
				button:SetStyle( "normal" )
			self:AddItem( button )
		end
	end
	
	self.PlayerSheet.NextUpdate = 0
	self.PlayerSheet.Think = function( self )
		if self.NextUpdate < CurTime() then
			self.NextUpdate = CurTime() + 5
			self:Update()
		end
	end
	
	self.PlayerSheet.Open = function( self )
		self:SetPos( openx, openy )
		//self:MoveTo( openx, openy, 0.5, 0, 2 )
	end
	
	self.PlayerSheet.Close = function( self )
		self:SetPos( closex, closey )
		//self:MoveTo( closex, closey, 1, 0, 2 )
	end
	
	self:AnimateObject( self.PlayerSheet, 9 )
	
end

function QMenu:AnimateObject( obj, rate, colors )

	obj.AnimTable = {}
	obj.OldFuncs = {}
	
	local x, y = obj:GetPos()
	local w, h = obj:GetSize()
	
	obj.OldFuncs.SetPos = obj.SetPos
	obj.OldFuncs.SetX = function( self, x ) obj.OldFuncs.SetPos( self, x, self.AnimTable[ 2 ].Current ) end
	obj.OldFuncs.SetY = function( self, y ) obj.OldFuncs.SetPos( self, self.AnimTable[ 1 ].Current, y ) end
	
	obj.OldFuncs.SetSize = obj.SetSize
	obj.OldFuncs.SetWide = function( self, w ) obj.OldFuncs.SetSize( self, w, self.AnimTable[ 4 ].Current ) end
	obj.OldFuncs.SetTall = function( self, h ) obj.OldFuncs.SetSize( self, self.AnimTable[ 4 ].Current, h ) end
	
	obj.OldFuncs.SetRed = function( self, r ) obj.Color.r = r end
	obj.OldFuncs.SetGreen = function( self, g ) obj.Color.g = g end
	obj.OldFuncs.SetBlue = function( self, b ) obj.Color.b = b end
	obj.OldFuncs.SetAlpha = function( self, a ) obj.Color.a = a end
	
	obj.Fade = function( self, col )
		self.AnimTable[ 5 ].Current = col.r or 255
		self.AnimTable[ 6 ].Current = col.g or 255
		self.AnimTable[ 7 ].Current = col.b or 255
		self.AnimTable[ 8 ].Current = col.a or 255
	end
	
	obj.FadeAlpha = function( self, a )
		self.AnimTable[ 8 ].Current = a
	end
	
	obj.SetX = function( self, x )
		self.AnimTable[ 1 ].Current = x
	end
	
	obj.SetY = function( self, y )
		self.AnimTable[ 2 ].Current = y
	end
	
	obj.SetPos = function( self, x, y )
		self:SetX( x )
		self:SetY( y )
	end
	
	obj.SetWide = function( self, w )
		self:SetSize( w, self:GetTall() )
	end
	
	obj.SetTall = function( self, h )
		self:SetSize( self:GetWide(), h )
	end
	
	obj.SetSize = function( self, w, h )
		self.AnimTable[ 3 ].Current = w
		self.AnimTable[ 4 ].Current = h
	end
	
	obj.GetPos = function( self )
		return self.AnimTable[1].Current, self.AnimTable[2].Current
	end
	
	obj.GetWide = function( self )
		return self.AnimTable[ 3 ].Current
	end
	
	obj.GetTall = function( self )
		return self.AnimTable[ 4 ].Current
	end
	
	obj.GetSize = function( self )
		return self:GetWide(), self:GetTall()
	end
	
	-- X
	table.insert( obj.AnimTable, 1, {
		Last = x,
		Current = x,
		Mul = rate or 20,
		Call = obj.OldFuncs.SetX,
	} )
	
	-- Y
	table.insert( obj.AnimTable, 2, {
		Last = y,
		Current = y,
		Mul = rate or 20,
		Call = obj.OldFuncs.SetY,
	} )
	
	-- W
	table.insert( obj.AnimTable, 3, {
		Last = w,
		Current = w,
		Mul = rate or 20,
		Call = obj.OldFuncs.SetWide,
	} )
			
	-- H
	table.insert( obj.AnimTable, 4, {
		Last = h,
		Current = h,
		Mul = rate or 20,
		Call = obj.OldFuncs.SetTall,
	} )
	
	if colors then
	
		-- COLORS
		table.insert( obj.AnimTable, 5, {
			Last = obj.Color.r,
			Current = obj.Color.r,
			Mul = rate or 20,
			Call = obj.OldFuncs.SetRed,
		} )
		
		table.insert( obj.AnimTable, 6, {
			Last = obj.Color.g,
			Current = obj.Color.g,
			Mul = rate or 20,
			Call = obj.OldFuncs.SetGreen,
		} )
		
		table.insert( obj.AnimTable, 7, {
			Last = obj.Color.b,
			Current = obj.Color.b,
			Mul = rate or 20,
			Call = obj.OldFuncs.SetBlue,
		} )
		
		table.insert( obj.AnimTable, 8, {
			Last = obj.Color.a,
			Current = obj.Color.a,
			Mul = rate or 20,
			Call = obj.OldFuncs.SetAlpha,
		} )
	end
	
	local dist, speed
	local last, current, mul, call
	
	local oldThink
	if obj.Think then oldThink = obj.Think end
	obj.Think = function( self )
		if oldThink then oldThink( self ) end

		for k,v in ipairs( self.AnimTable ) do
			last = v.Last
			current = v.Current
			mul = v.Mul
			call = v.Call

			if math.Round( last ) != math.Round( current ) then
				dist = current - last
				speed = dist / mul

				self.AnimTable[ k ].Last = math.Approach( last, current, speed )
				call( obj, self.AnimTable[ k ].Last )
			end
			
			last, current, mul, call = nil
		end
		
	end

end

hook.Add( "ExInitialized", "ExCreateQMenu", function() QMenu.Initialize( QMenu ) end )

function QMenu:Open()	
	gui.EnableScreenClicker( true )

	QMenu.PlayerSheet:Open()
	QMenu.ActionList:Open()
end
concommand.Add( "+exstoQMenu", QMenu.Open )

function QMenu:Close()
	gui.EnableScreenClicker( false )
	
	QMenu.PlayerSheet:Close()
	QMenu.ActionList:Close()
end
concommand.Add( "-exstoQMenu", QMenu.Close )
	