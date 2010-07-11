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

Menu = {}
	Menu.Dialog = {}
	Menu.List = {}
	Menu.ListIndex = {}
	Menu.CreatePages = {}
	Menu.BaseTitle = "Exsto / "
	Menu.NextPage = {}
	Menu.CurrentPage = {}
	Menu.DefaultPage = nil
	Menu.PreviousPage = {}
	Menu.SecondaryRequests = {}
	Menu.TabRequests = {}
	Menu.CurrentIndex = 1
	
surface.CreateFont( "arial", 17, 700, true, false, "exstoTitleMenuBold" )
surface.CreateFont( "arial", 17, 400, true, false, "exstoTitleMenu" )
surface.CreateFont( "arial", 26, 700, true, false, "exstoBottomTitleMenu" )
surface.CreateFont( "arial", 18, 700, true, false, "exstoSecondaryButtons" )
surface.CreateFont( "arial", 20, 700, true, false, "exstoButtons" )
surface.CreateFont( "arial", 14, 700, true, false, "exstoHelpTitle" )
surface.CreateFont( "arial", 19, 700, true, false, "exstoPlyColumn" )
surface.CreateFont( "arial", 15, 650, true, false, "exstoDataLines" )
surface.CreateFont( "arial", 21, 500, true, false, "exstoHeaderTitle" )
surface.CreateFont( "arial", 26, 400, true, false, "exstoArrows" )
surface.CreateFont( "arial", 46, 400, true, false, "exstoTutorialTitle" )
surface.CreateFont( "arial", 40, 400, true, false, "exstoTutorialContent" )

--[[ -----------------------------------
	Function: exsto.Menu
	Description: Opens up the Exsto menu.
	----------------------------------- ]]
function exsto.Menu( key, rank, flagCount )
	Menu:WaitForRanks( key, rank, flagCount )
end
exsto.UMHook( "exsto_Menu", exsto.Menu )

function Menu:WaitForRanks( key, rank, flagCount )
	if !exsto.Ranks or table.Count( exsto.Ranks ) == 0 then
		timer.Simple( Menu.WaitForRanks, Menu, key, rank, flagCount )
		return
	end

	self:Initialize( key, rank, flagCount )
end

function Menu:Initialize( key, rank, flagCount )
	Menu.AuthKey = key

	-- If we are valid, just open up.
	if Menu:IsValid() then	
		
		-- Wait, did we change ranks?
		if Menu.LastRank != rank then
			-- Oh god, update us.
			Menu.ListIndex = {}
			Menu.DefaultPage = {}
			Menu.PreviousPage = {}
			Menu.CurrentPage = {}
			Menu.NextPage = {}
			Menu.DefaultPage = {}
			
			Menu:BuildPages( rank, flagCount )
			Menu.LastRank = rank
		end
			
		Menu.Frame:SetVisible( true )
		Menu:BringBackSecondaries()
	else
		Menu.LastRank = LocalPlayer():GetRank()
		Menu:Create( rank, flagCount )
	end
end

function Menu:Create( rank, flagCount )

	self.Placement = {
		Main = {
			w = 600,
			h = 380,
		},
		Header = {
			h = 46,
		},
		Side = {
			w = 171,
			h = 345,
		},
		Content = {
			w = 600,
			h = 340,
		},
		Gap = 6,
	}
	
	self.Colors = {
		White = Color( 255, 255, 255, 200 ),
		Black = Color( 0, 0, 0, 0 ),
		HeaderExtendBar = Color( 226, 226, 226, 255 ),
		HeaderTitleText = Color( 103, 103, 103, 255 ),
		ArrowColor = Color( 0, 193, 32, 255 ),
		ColorPanelStandard = Color( 204, 204, 204, 51 ),
	}
	
	self:BuildMainFrame()
	self:BuildMainHeader()
	self:BuildMainContent()
	self:BuildPages( rank, flagCount )
	
	self.Frame:SetSkin( "ExstoTheme" )
end

function Menu:IsValid()
	return self.Frame and self.Frame:IsValid()
end

function Menu:BuildMainFrame()
	
	self.Frame = exsto.CreateFrame( 0, 0, self.Placement.Main.w, self.Placement.Main.h, "", true, self.Colors.White )
	self.Frame:Center()
	self.Frame:SetDeleteOnClose( false )
	self.Frame:SetDraggable( false )
	
	self.Frame.btnClose.DoClick = function( self )
		self:GetParent():Close()
		
		-- Loop through secondaries and tabs.
		for short, obj in pairs( Menu.SecondaryRequests ) do
			obj:SetVisible( false )
		end
		
		for short, obj in pairs( Menu.TabRequests ) do
			obj:SetVisible( false )
		end
	end
	
	-- Move the secondarys and tabs along with us.
	local think = self.Frame.Think
	self.Frame.Think = function( self )
		if think then think( self ) end
		
		if self.Dragging then
			self.OldX = self:GetPos()
			
			Menu:UpdateSecondariesPos()
		end
	end
	
	
end

function Menu:BuildMainHeader()

	self.Header = exsto.CreatePanel( 0, 0, self.Frame:GetWide() - 30, self.Placement.Header.h, self.Colors.Black, self.Frame )

	-- Logo
	self.Header.Logo = vgui.Create( "DImageButton", self.Header )
	self.Header.Logo:SetImage( "exstoLogo" )
	self.Header.Logo:SetSize( 86, 37 )
	self.Header.Logo:SetPos( 9, 9 )
	
	self.Header.Logo.DoClick = function()
		local list = DermaMenu()
		
		for _, data in pairs( Menu.List ) do
			list:AddOption( data.Title, function() Menu.MoveToPage( data.Short ) end )
		end
		list:Open()
	end
	
	self.Header.Title = exsto.CreateLabel( self.Header.Logo:GetWide() + 20, 17, "", "exstoHeaderTitle", self.Header )
	self.Header.Title:SetTextColor( self.Colors.HeaderTitleText )
	
	local function paint( self )
		draw.SimpleText( self.Text, "exstoArrows", self:GetWide() / 2, self:GetTall() / 2, Menu.Colors.ArrowColor, 1, 1 )
	end
	
	self.Header.MoveLeft = exsto.CreateButton( 0, 18, 20, 20, "<", self.Header )
	self.Header.MoveLeft.Paint = paint
	self.Header.MoveLeft.DoClick = function( self )
		Menu.MoveToPage( Menu.PreviousPage.Short )
	end
	
	self.Header.MoveRight = exsto.CreateButton( 0, 18, 20, 20, ">", self.Header )
	self.Header.MoveRight.Paint = paint
	self.Header.MoveRight.DoClick = function( self )
		Menu.MoveToPage( Menu.NextPage.Short )
	end
	
	self.Header.MoveLeft.Text = "<"
	self.Header.MoveRight.Text = ">"
	
	self.Header.ExtendBar = exsto.CreatePanel( 0, 20, 0, 1, self.Colors.HeaderExtendBar, self.Header )
	
	self:SetTitle( "Loading" )

end

function Menu:BuildMainContent()
	self.Content = exsto.CreatePanel( 0, 46, self.Placement.Content.w, self.Placement.Content.h, self.Colors.Black, self.Frame )
end

function Menu:BuildTabMenu()
	local tab = exsto.CreatePanel( 0, 0, 174, 348 )
		tab:Gradient( true )
		tab:Center()
		tab:SetVisible( false )
		tab:SetSkin( "ExstoTheme" )
		
		Menu:CreateAnimation( tab )
		tab:FadeOnVisible( true )
		tab:SetPosMul( 10 )
		tab:SetFadeMul( 5 )

		tab.Pages = {}
		tab.Controls = exsto.CreatePanelList( 8.5, 10, tab:GetWide() - 17, tab:GetTall() - 20, 5, false, true, tab )
		tab.Controls.m_bBackground = false
		
		tab.CreatePage = function( self, page )
			local panel = exsto.CreatePanel( 0, 0, page:GetWide(), page:GetTall(), Menu.Colors.Black, page )
			Menu:CreateAnimation( panel )
			panel:FadeOnVisible( true )
			panel:SetFadeMul( 5 )
			return panel
		end
		
		tab.AddItem = function( self, name, page )
			local button = exsto.CreateButton( 0, 0, self:GetWide() - 40, 27, name )
			button:SetStyle( "secondary" )
			button:SetSkin( "ExstoTheme" )
			button.DoClick = function( button )
			
				self.CurrentPage:SetVisible( false )
				page:SetVisible( true )
				self.ActiveButton.isEnabled = false
				
				self.CurrentPage = page
				self.ActiveButton = button
				button.isEnabled = true 
			end

			table.insert( self.Pages, page )
			self.Controls:AddItem( button )
			
			if !self.DefaultPage then
				self.CurrentPage = page
				self.DefaultPage = page
				self.ActiveButton = button
				button.isEnabled = true
				page:SetVisible( true )
				return
			end
			page:SetVisible( false )
		end
		
		tab.Clear = function( self )
			self.Controls:Clear()
			
			for _, page in ipairs( self.Pages ) do
				page:Remove()
			end
		end
	
	return tab
end

function Menu:BuildSecondaryMenu()
	local secondary = exsto.CreatePanel( 0, 0, 174, 348 )
		secondary:Gradient( true )
		secondary:Center()
		secondary:SetVisible( false )
		secondary:SetSkin( "ExstoTheme" )
		
		Menu:CreateAnimation( secondary )
		secondary:FadeOnVisible( true )
		secondary:SetPosMul( 10 )
		secondary:SetFadeMul( 5 )
		
		secondary.Hide = function( self )
			self.Hidden = true
			self:SetVisible( false )
		end
		
		secondary.Show = function( self )
			self.Hidden = false
			Menu:BringBackSecondaries()
		end

	return secondary
end

function Menu:UpdateSecondariesPos()

	local mainX, mainY = Menu.Frame:GetPos()
	local mainW, mainH = Menu.Frame:GetSize()

	if self.ActiveSecondary then
		self.ActiveSecondary:SetPos( mainX + mainW + Menu.Placement.Gap, mainY + mainH - self.ActiveSecondary:GetTall() )
	end
	
	if self.ActiveTab then		
		self.ActiveTab:SetPos( mainX - Menu.Placement.Gap - self.ActiveTab:GetWide(), mainY + mainH - self.ActiveTab:GetTall() )
	end
	
end

function Menu:HideSecondaries()

	local mainX, mainY = Menu.Frame:GetPos()
	local mainW, mainH = Menu.Frame:GetSize()

	if self.ActiveSecondary then
		self.ActiveSecondary:SetPos( ( mainX + ( mainW / 2 ) ) - ( self.ActiveSecondary:GetWide() / 2 ), mainY + mainH - self.ActiveSecondary:GetTall() )
	end
	
	if self.ActiveTab then		
		self.ActiveTab:SetPos( ( mainX + ( mainW / 2 ) ) - ( self.ActiveTab:GetWide() / 2 ), mainY + mainH - self.ActiveTab:GetTall() )
	end
	
end

function Menu:BringBackSecondaries()
	if self.ActiveSecondary then
		if !self.ActiveSecondary.Hidden then
			self.ActiveSecondary:SetVisible( true )
		end
	end
	
	if self.ActiveTab then
		self.ActiveTab:SetVisible( true )
	end
	
	self:UpdateSecondariesPos()
end

function Menu:CreateColorPanel( x, y, w, h, page )

	local panel = exsto.CreatePanel( x, y, w, h, Color( 204, 204, 204, 51 ), page )
	
	self:CreateAnimation( panel )
	panel:SetPosMul( 1 )
	
	panel.Accept = function( self )
		if self:GetStyle() == "accept" then return end
		self.Style = "accept"
		self:SetColor( Color( 0, 255, 24, 51 ) )
	end
	
	panel.Deny = function( self )
		if self:GetStyle() == "deny" then return end
		self.Style = "deny"
		self:SetColor( Color( 255, 0, 0, 51 ) )
	end
	
	panel.Neutral = function( self )
		if self:GetStyle() == "neutral" then return end
		self.Style = "neutral"
		self:SetColor( Color( 204, 204, 204, 51 ) )
	end
	
	panel.GetStyle = function( self )
		return self.Style
	end
	
	return panel
	
end

function Menu:CreateAnimation( obj )
	obj.Anims = {}
	
	obj.SetPosMul = function( self, mul )
		self.Anims[ 1 ].Mul = mul
		self.Anims[ 2 ].Mul = mul
	end
	
	obj.SetFadeMul = function( self, mul )
		self.Anims[ 3 ].Mul = mul
	end
	
	obj.SetColorMul = function( self, mul )
		for I = 4, 7 do
			self.Anims[ I ].Mul = mul
		end
	end
	
	-- Position Support
	local oldGetPos = obj.GetPos
	local oldPos = obj.SetPos
	local oldSetX = function( self, x ) oldPos( self, x, self.Anims[ 2 ].Last ) end
	local oldSetY = function( self, y ) oldPos( self, self.Anims[ 1 ].Last, y ) end
	
	obj.SetPos = function( self, x, y )
		self:SetX( x )
		self:SetY( y )
		self.Anims[ 1 ].Current = x
		self.Anims[ 2 ].Current = y
	end
	
	obj.SetX = function( self, x )
		self.Anims[ 1 ].Current = x
	end
	
	obj.SetY = function( self, y )
		self.Anims[ 2 ].Current = y
	end
	
	obj.GetPos = function( self )
		return self.Anims[ 1 ].Last, self.Anims[ 2 ].Last 
	end
	
	-- Fading Support
	local oldVisible = obj.SetVisible
	local oldSetAlpha = function( self, alpha )
		self:SetAlpha( alpha )
		oldVisible( self, alpha >= 5 )
	end
	
	obj.FadeOnVisible = function( self, bool )
		self.fadeOnVisible = bool
	end
	
	obj.SetVisible = function( self, bool )
		if self.fadeOnVisible then
			if bool == true then
				self.Anims[ 3 ].Current = 255
				oldVisible( self, bool )
			elseif bool == false then
				self.Anims[ 3 ].Current = 0
			end
		else
			oldVisible( self, bool )
		end
	end
	
	-- Color Support.
	local oldSetColor = function( self, color ) self.bgColor = color end
	local oldSetRed = function( self, red ) self.bgColor.r = red end
	local oldSetGreen = function( self, green ) self.bgColor.g = green end
	local oldSetBlue = function( self, blue ) self.bgColor.b = blue end
	local oldSetAlpha2 = function( self, alpha ) self.bgColor.a = alpha end

	obj.SetColor = function( self, color )
		print( "Setting color for" .. tostring( self ) )
		self:SetRed( color.r )
		self:SetGreen( color.g )
		self:SetBlue( color.b )
		self.Anims[ 7 ].Current = color.a
	end
	
	obj.SetRed = function( self, red )
		self.Anims[ 4 ].Current = red
	end
	
	obj.SetGreen = function( self, green )
		self.Anims[ 5 ].Current = green
	end
	
	obj.SetBlue = function( self, blue )
		self.Anims[ 6 ].Current = blue
	end
	
	local think, dist, speed = obj.Think
	obj.Think = function( self )
		for _, data in ipairs( self.Anims ) do
			//print( data.Last, data.Current )
			if math.Round( data.Last ) != math.Round( data.Current ) then
				dist = data.Current - data.Last
				speed = RealFrameTime() * ( dist / data.Mul  ) * 40

				self.Anims[ _ ].Last = math.Approach( data.Last, data.Current, speed )
				data.Call( self, self.Anims[ _ ].Last )
			end
		end
	end
	
	-- Presets.
	local x, y = oldGetPos( obj )
	obj.Anims[ 1 ] = {
		Current = x,
		Last = x,
		Mul = 40,
		Call = oldSetX,
	}
	
	obj.Anims[ 2 ] = {
		Current = y,
		Last = y,
		Mul = 40,
		Call = oldSetY,
	}

	-- Alpha.
	obj.Anims[ 3 ] = {
		Current = 255,
		Last = 255,
		Mul = 20,
		Call = oldSetAlpha
	}
	
	local col = obj.bgColor
	if col then
		-- Color Object
		obj.Anims[ 4 ] = {
			Current = col.r,
			Last = col.r,
			Mul = 20,
			Call = oldSetRed
		}
		obj.Anims[ 5 ] = {
			Current = col.g,
			Last = col.g,
			Mul = 20,
			Call = oldSetGreen
		}
		obj.Anims[ 6 ] = {
			Current = col.b,
			Last = col.b,
			Mul = 20,
			Call = oldSetBlue
		}
		obj.Anims[ 7 ] = {
			Current = col.a,
			Last = col.a,
			Mul = 20,
			Call = oldSetAlpha2
		}
	end
	
end

--[[ -----------------------------------
	Function: Menu.CreateExtras
	Description: Creates the pages
	----------------------------------- ]]
function Menu:BuildPages( rank, flagCount )

	-- Protection against clientside hacks.  Kill if the server's flagcount for the rank is not the same as the clients
	local clientFlags = exsto.Ranks[ rank ]
	if #clientFlags.Flags != flagCount then return end

	surface.SetFont( "exstoPlyColumn" )
	
	-- Clean our old
	for short, data in pairs( self.List ) do
		if data.Panel:IsValid() then
			data.Panel:Remove()
		end
		self.List[ short ] = nil
	end

	-- Loop through what we need to build.
	for _, data in ipairs( self.CreatePages ) do
		
		if table.HasValue( clientFlags.AllFlags, data.Short ) then
	
			exsto.Print( exsto_CONSOLE_DEBUG, "MENU --> Creating page for " .. data.Title .. "!" )
			
			-- Call the build function.
			local page = data.Function( self.Content )
			
			-- Insert his data into the list.
			self:AddToList( data, page )
			
			-- Are we the default?  Set us up as visible
			if data.Default then
				self.List[ data.Short ].Panel:SetVisible( true )
			end
		
		end
		
	end
	
	-- If he can't see any pages, why bother?
	if #self.ListIndex == 0 then return false end
	
	-- Set our current page and the ones near us.
	for index, short in ipairs( self.ListIndex ) do
		if self.List[ short ] then
			-- Hes a default, set him up as our first selection.
			if self.List[ short ].Default then
				Menu.MoveToPage( short )
				self.DefaultPage = self.CurrentPage
				self.DefaultPage.Panel:SetVisible( true )
			else
				self:GetPageData( index ).Panel:SetVisible( false )
			end
		end
	end
	
	-- If there still isn't any default, set the default as the first index.
	if !self.DefaultPage then
		Menu.MoveToPage( self.ListIndex[ 1 ] )
		self.DefaultPage = self.CurrentPage
		self.DefaultPage.Panel:SetVisible( true )
	end

end

--[[ -----------------------------------
	Function: Menu.AddToList
	Description: Adds a page to the menu list.
	----------------------------------- ]]
function Menu:AddToList( info, panel )
	self.List[info.Short] = {
		Title = info.Title,
		Short = info.Short,
		Default = info.Default,
		Flag = info.Flag,
		Panel = panel,
	}
	
	-- Create an indexed list of the pages.
	table.insert( self.ListIndex, info.Short )
end

function Menu:GetPageData( index )
	local short = self.ListIndex[ index ]
	if !short then return nil end
	return self.List[ short ]
end

function Menu:SetTitle( text )
	self.Header.Title:SetText( text )
	self.Header.Title:SizeToContents()
	
	self.Header.MoveLeft:MoveRightOf( self.Header.Title, 10 )
	self.Header.MoveRight:MoveRightOf( self.Header.MoveLeft, 5 )
	
	local start = self.Header.Logo:GetWide() + self.Header.Title:GetWide() + self.Header.MoveLeft:GetWide() + self.Header.MoveRight:GetWide() + 34
	self.Header.ExtendBar:SetPos( start, 27 )
	self.Header.ExtendBar:SetWide( self.Header:GetWide() - start )
end

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
	
	Menu:SetTitle( Menu.CurrentPage.Title )
	
	Menu:HideSecondaries()
	
	if Menu.ActiveSecondary then
		-- Tuck him away.
		Menu.ActiveSecondary:SetVisible( false )
		Menu.ActiveSecondary = nil
	end
	
	if Menu.ActiveTab then
		Menu.ActiveTab:SetVisible( false )
		Menu.ActiveTab = nil
	end
	
	-- Send our our requests
	local secondary = Menu.SecondaryRequests[ short ]
	if secondary then
		if !secondary.Hidden then secondary:SetVisible( true ) end
		Menu.ActiveSecondary = secondary
		Menu:UpdateSecondariesPos()
	end
	
	local tabs = Menu.TabRequests[ short ]
	if tabs then
		tabs:SetVisible( true )
		Menu.ActiveTab = tabs
		Menu:UpdateSecondariesPos()
	end
	
	if !oldCurrent then return end
	
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
	Function: Menu:CreatePage
	Description: Creates a menu page for the Exsto menu
	----------------------------------- ]]
function Menu:CreatePage( info, func )

	-- Create a build function
	local function buildPage( bg )
		-- Create the placement background.
		local page = exsto.CreatePanel( 0, 0, Menu.Placement.Content.w, Menu.Placement.Content.h - 6, Menu.Colors.Black, bg )
		page:SetVisible( false )
		
		function page:RequestSecondary( force )
			local secondary = Menu:BuildSecondaryMenu()
			Menu.SecondaryRequests[ info.Short ] = secondary
			
			if force then
				Menu.ActiveSecondary = secondary
			end
			return secondary
		end
		
		function page:RequestTabs( force )
			local tabs = Menu:BuildTabMenu()
			Menu.TabRequests[ info.Short ] = tabs
			
			if force then
				Menu.ActiveTab = tabs
			end
			return tabs
		end
		
		func( page )
		return page
	end

	-- Insert data into a *to create* list.	
	table.insert( Menu.CreatePages, {
		Title = info.Title,
		Flag = info.Flag,
		Short = info.Short,
		Default = info.Default,
		Function = buildPage,
	} )
	
end

--[[ -----------------------------------
	Category: Exsto Tutorial
	----------------------------------- 
local tutorialBackground = nil
local tutorialLogo = nil
local tutorialTitle = nil
local tutorialContent = nil
local tutorialScrollBG = nil
local tutorialScrollGrip = nil
local tutorialList = nil
local currentTutorial = nil
local Tutorials = {}

local function InitTutorial()
	-- Create the giant panel.
	tutorialBackground = exsto.CreatePanel( 0, 0, ScrW(), ScrH() )
		tutorialBackground:Gradient( true )
		tutorialBackground:SetSkin( "ExstoTheme" )
		tutorialBackground:SetVisible( false )
		
	-- Logo!
	tutorialLogo = vgui.Create( "DImage", tutorialBackground )
		tutorialLogo:SetImage( "exstoLogo" )
		tutorialLogo:SetSize( 256, 110 )
		tutorialLogo:SetPos( 30, 30 )
		
	-- Title!
	tutorialTitle = exsto.CreateLabel( 0, 50, "Exsto Tutorial: Menu", "exstoTutorialTitle", tutorialBackground )
		tutorialTitle:MoveRightOf( tutorialLogo, 40 )
		tutorialTitle:SetTextColor( Color( 103, 103, 103, 255 ) )
	
	-- Content Page
	tutorialContent = exsto.CreatePanel( 30, 150, ScrW() - 60, ScrH() - 150, Color( 0, 0, 0, 0 ), tutorialBackground )
	
	tutorialScrollBG = exsto.CreatePanel( 10, ScrH() - 50, tutorialBackground:GetWide() - 450, 40, Color( 255, 0, 0, 255 ), tutorialBackground )
		tutorialScrollBG:Gradient( true )
		tutorialScrollBG.GradientHigh = Color( 194, 194, 194, 255 )
		tutorialScrollBG.GradientLow = Color( 184, 184, 184, 255 )
		
	tutorialScrollGrip = exsto.CreatePanel( 0, 0, tutorialScrollBG:GetWide(), tutorialScrollBG:GetTall(), Color( 0, 255, 0, 255 ), tutorialScrollBG )
		tutorialScrollGrip.OnMousePressed = function( self )
			CurrentTutorial.Panel.Playing = false
			self.Locked = true
			self:MouseCapture( true )
			self.PickedAt = self:GetPos()
		end
		
		tutorialScrollGrip.OnMouseReleased = function( self )
			CurrentTutorial.Panel.Playing = true
			self.Locked = false
			self:MouseCapture( false )
			
			local closestIndex, x = self:GetClosestSlot()
			if closestIndex then
				CurrentTutorial.Panel:MoveToIndex( closestIndex )
				self.SetDrawX = x
			end
		end
		
		tutorialScrollGrip.OnCursorMoved = function( self, x, y )
			if self.Locked then
				x = self:GetParent():ScreenToLocal( gui.MouseX() )
				self.SetDrawX = x
			end
		end
		tutorialScrollGrip.PageSlots = {}
		
		tutorialScrollGrip.GetClosestSlot = function( self )
			
			local x = self.SetDrawX
			local closestDist = 500
			local closestIndex = nil
			local setX
			for _, slot in ipairs( self.PageSlots ) do
				local dist = slot - x
				
				if dist < 0 then dist = -dist end
				
				if dist <= closestDist then
					setX = x
					closestDist = dist
					closestIndex = _
				end
			end
			
			return closestIndex, setX
			
		end
		
		tutorialScrollGrip:NoClipping( true )
		
		tutorialScrollGrip.SetDrawX = 0
		tutorialScrollGrip.Paint = function( self )
			surface.SetDrawColor( 0, 0, 255, 255 )
			surface.DrawRect( self.SetDrawX, 0, 40, 40 )
			
			-- Little nice guys.
			for _, slot in ipairs( self.PageSlots ) do
				surface.DrawRect( slot - ( 75 / 2 ), -40, 75, 30 )
			end
		end
		
	local nextslide = exsto.CreateButton( ScrW() - 420, ScrH() - 40, 145, 30, "Next Slide", tutorialBackground )
		nextslide.DoClick = function( self )
			if CurrentSlide then
				CurrentSlide:NextSlide()
			end
		end
		nextslide:MoveRightOf( tutorialScrollBG, 15 )
		
	local prevslide = exsto.CreateButton( ScrW() - 260, ScrH() - 40, 145, 30, "Previous Slide", tutorialBackground )
		prevslide.DoClick = function( self )
			if CurrentSlide then
				CurrentSlide:PreviousSlide()
			end
		end
		prevslide:MoveRightOf( nextslide, 15 )
	
	local close = exsto.CreateButton( ScrW() - 100, ScrH() - 40, 75, 30, "Close", tutorialBackground )
		close:SetStyle( "negative" )
		close.DoClick = function( self )
			gui.EnableScreenClicker( false )
			tutorialBackground:SetVisible( false )
			
			-- Stop a currently playing.
			if CurrentSlide then
				CurrentSlide:Stop()
			end
		end
		close:MoveRightOf( prevslide, 15 )
		
	//Menu:CreateAnimation( tutorialScrollGrip )
		
end
InitTutorial()

local function SetScrollbar()
	
	-- Get page intervals
	local interval = tutorialScrollBG:GetWide() / #CurrentTutorial.Panel.Slides
	
	local nextSlot = 0
	tutorialScrollGrip.PageSlots = {}
	for _, slides in ipairs( CurrentTutorial.Panel.Slides ) do
		tutorialScrollGrip.PageSlots[ _ ] = nextSlot
		
		nextSlot = nextSlot + interval
	end
	
end

local function SetTutorialPage( short )
	
	if CurrentTutorial then
		CurrentTutorial.Panel:Stop()
	end
	
	CurrentTutorial = Tutorials[ short ]
	CurrentTutorial.Panel:Start()
	
end

local function BuildMainMenu()

	tutorialTitle:SetText( "Exsto Tutorial: Main Menu" )
	tutorialTitle:SizeToContents()
	
	tutorialList = exsto.CreatePanelList( 0, 0, 100, 200, 5, false, true, tutorialBackground )
		tutorialList:Center()
		
	for short, data in pairs( Tutorials ) do
		local button = exsto.CreateButton( 0, 0, tutorialList:GetWide(), 27, data.Title )
			button.DoClick = function( self )
				SetTutorialPage( short )
			end
		
		tutorialList:AddItem( button )
	end
	
end
	
local function StartTutorial() 	
	
	//LocalPlayer():EmitSound( 
	gui.EnableScreenClicker( true )
	tutorialBackground:SetVisible( true )
	
	-- Set our content to the main menu selection.
	--SetTutorialPage( "mainmenu" )
	
end

local function empty() end

local function CreateTutorial( title, short, func )
	
	local panel = exsto.CreatePanel( 0, 0, tutorialContent:GetWide(), tutorialContent:GetTall(), Color( 0, 0, 0, 0 ), tutorialContent )
		
		panel.DisplayText = exsto.CreateLabel( 10, 10, "", "exstoTutorialContent", panel )
			panel.DisplayText:SetWide( panel:GetWide() - 10 )
			panel.DisplayText:SetWrap( true )
			panel.DisplayText:SetTextColor( Color( 103, 103, 103, 255 ) )
			
			local oldSetText = panel.DisplayText.SetText
			panel.DisplayText.SetText = function( self, text )
				surface.SetFont( "exstoTutorialContent" )
				local spaceW, spaceH = surface.GetTextSize( " " )
				
				local setWidth = 0
				local setHeight = 30
				local split = string.Explode( " ", text )
				for _, splice in ipairs( split ) do
				
					if setWidth >= self:GetWide() then
						setHeight = setHeight + 50
						setWidth = 0
					end
					
					local wordW, wordH = surface.GetTextSize( splice )
					setWidth = setWidth + wordW
					
				end
				
				self:SetTall( setHeight )
				oldSetText( self, text )
			end
			
		panel.Slides = {}
		panel.TotalRunTime = 0
		panel.AddSlide = function( self, duration, text, startFunc, endFunc )
			table.insert( self.Slides, {
				Duration = duration,
				Text = text,
				StartFunction = startFunc or empty,
				EndFunction = endFunc or empty,
				Index = #self.Slides + 1,
			} )
			self.TotalRunTime = self.TotalRunTime + duration
		end
		
		panel.CurrentSlide = nil
		panel.Playing = false
		panel.NextTick = nil
		panel.NextScrollTick = 0
		panel.ScrollInterval = 0
		
		panel.Start = function( self )
			SetScrollbar()
			tutorialList:SetVisible( false )
			
			self.CurrentSlide = self.Slides[ 1 ] -- Start off with the first, always.
			self.DisplayText:SetText( self.CurrentSlide.Text )
			self.CurrentSlide.StartFunction( self )
			
			self.Playing = true
			self.NextTick = CurTime() + self.CurrentSlide.Duration
			self:SetVisible( true )
			
			self.ScrollInterval = ( tutorialScrollGrip.PageSlots[ self.CurrentSlide.Index + 1 ] - tutorialScrollGrip.SetDrawX ) / ( self.CurrentSlide.Duration * 10 )
			
		end
		
		panel.Pause = function( self )
			self.Playing = false
		end
		
		panel.Stop = function( self )
			tutorialList:SetVisible( true )
			
			self.Playing = false
			self.CurrentSlide = nil
			self.NextTick = 0
			self:SetVisible( false )
			
			tutorialScrollGrip.SetDrawX = 0
		end
		
		panel.MoveToIndex = function( self, index )
			if self.CurrentSlide.EndFunction then
				self.CurrentSlide.EndFunction( self )
			end
			
			self.CurrentSlide = self.Slides[ index ] -- Start off with the first, always.
			self.DisplayText:SetText( self.CurrentSlide.Text )
			self.CurrentSlide.StartFunction( self )
			
			self.Playing = true
			self.NextTick = CurTime() + self.CurrentSlide.Duration
		end

		panel.Think = function( self )
			if !self.Playing then return end
			if !self.CurrentSlide then return end
			
			-- Scrollbar moving tick
			if self.NextScrollTick <= CurTime() then
				self.NextScrollTick = CurTime() + .1
				
				local x = tutorialScrollGrip.SetDrawX
				tutorialScrollGrip.SetDrawX = x + self.ScrollInterval
			end
			
			-- Time to move to the next page!
			if self.NextTick <= CurTime() then
				self.CurrentSlide.EndFunction( self )
				
				self.CurrentSlide = self.Slides[ self.CurrentSlide.Index + 1 ]
				if !self.CurrentSlide then
					self:Stop()
					return
				end
				
				self.DisplayText:SetText( self.CurrentSlide.Text )
				self.CurrentSlide.StartFunction( self )
				
				self.NextTick = CurTime() + self.CurrentSlide.Duration
				
				self.ScrollInterval = ( tutorialScrollGrip.PageSlots[ self.CurrentSlide.Index + 1 or tutorialScrollGrip:GetWide() ] - tutorialScrollGrip.SetDrawX ) / ( self.CurrentSlide.Duration * 10 )
			end
		end
		
	Tutorials[ short ] = {
		Title = title,
		Short = short,
		Panel = panel,
	}
	
	func( panel )
	
end

-- Main Menu Tutuuuurial.
local function MainMenuTut( page )
	
	page:AddSlide( 3, "This slide will last for three seconds." )
	page:AddSlide( 1, "This slide will last for one second." )
	
	local testFunction = function()
		exsto.Menu()
	end
	
	page:AddSlide( 5, "This slide will open the menu and last for five seconds.", testFunction )
	
	local testFunction = function()
		Menu.Frame.btnClose:DoClick()
	end
	
	page:AddSlide( 3, "This slide will close the menu and last for three seconds.", testFunction )
	page:AddSlide( 5, "This is so freakin long I have no idea how the hell to fix this because its so long.  I hope it works on all of the things and do proper word wrapping, please; otherwise, I shall fail big time." )
	
end
CreateTutorial( "Test", "mainmenu", MainMenuTut )

local function Introduction( page )

	local anim = nil
	local startAnimLogo = function( page )
		anim = vgui.Create( "DImage", page )
			anim:SetImage( "exstoGenericAnim" )
			anim:SetKeepAspect( true )
			anim:SetSize( 350, 200 )
			anim:SetPos( ( page:GetWide() / 2 ) - ( anim:GetWide() / 2 ), page:GetTall() - 300 )
	end
	local endAnimLogo = function( page )
		anim:Remove()
	end

	page:AddSlide( 6, "Hello!  Welcome to Exsto.  This tutorial will introduce you to what Exsto is, and what it can do." )
	page:AddSlide( 10, "As you may have already noticed, the chat looks a bit different.  That is a plugin, one selection of code that is completely optional.  It is what makes up Exsto; it is a plugin based 'modular administration' system." )
	page:AddSlide( 12, "We named Exsto due to that reason.  It stood out from the rest of the competition.  The GUI; the powerful CORE behind it; the unique plugins.  Exsto has been named by the beautiful language of Latin, and it means 'To stand out'.  Exsto used to be named PAC however, but it didn't seem fit.", startAnimLogo, endAnimLogo )
	page:AddSlide( 14, "This tutorial was designed to help you as a new user, or a curious person, find out how Exsto works, and what you can do with a tool like this.  It will explain EVERYTHING, which is why it has a main menu you saw before.  That way, you don't need to view things if you do not need to see them." )
	page:AddSlide( 6, "On behalf of Prefanatic, [DI] Spart, and the rest of the minds behind the Exsto project; Thank You." )
	
end
CreateTutorial( "Introduction", "intro", Introduction )

local function CoreTutorial( page )

	local function CreateBot( page )
		
		game.ConsoleCommand( "bot\n" )
		
		local bot = nil
		for _, ply in ipairs( player.GetAll() ) do
			if ply:IsBot() then bot = ply end
		end
		
		local view = exsto.CreatePanel( 0, 0, ScrW() - 300, ScrH() - 200 )
			view:Center()
			
			local renderData = {}
			renderData.x = 0
			renderData.y = 0
			renderData.w = view:GetWide()
			renderData.h = view:GetTall()
			view.Paint = function( self )
				renderData.angles = bot:EyeAngles()
				renderData.origin = bot:GetPos() + Vector( 50, 0, 30 )
				
				render.RenderView( renderData )
			end
			
	end
	
	page:AddSlide( 6, "The CORE; the most advanced peice of Exsto that exists.  In the CORE is where the magic happens, how plugins are handeled, commands are run, code is processed." )
	page:AddSlide( 6, "Due to the advanced nature of the CORE, it tends to be unstable on new feature additions.  Because so much happens in the CORE, we created this tutorial to explain what it is actually doing." )
	page:AddSlide( 6, "When you run a command, all you see is someone exploding or being kicked out of the server.  Behind the scenes in the CORE, a lot is going on." )
	page:AddSlide( 6, "Watch the following command being run on this poor bot.", CreateBot )
	
end

local function BugReporting( page )

	local html = nil
	local function CreateCodePage( page )
		html = vgui.Create( "HTML", page )
			html:SetSize( page:GetWide() - 200, page:GetTall() - 300 )
			html:Center()
			html:OpenURL( "http://code.google.com/p/exsto" )
			html:SetVisible( false )
			
			Menu:CreateAnimation( html )
			html:FadeOnVisible( true )
	end
	
	local function VisiblePage( page )
		html:SetVisible( true )
	end
	
	local function KillPage( page )
		html:Remove()
	end

	page:AddSlide( 7, "This tutorial will teach you about how to report bugs, or request features for Exsto." )
	page:AddSlide( 10, "Reporting bugs is incredibly easy; using the power of GoogleCode.  Just simply visit http://code.google.com/p/exsto and click on the 'Issues' tab.", CreateCodePage )
	page:AddSlide( 20, "I'll give you 20 seconds to look around the page.", VisiblePage, KillPage )
	page:AddSlide( 11, "You don't just have to report bugs there.  Feature requests are always welcomed from the Exsto developers.  That is how we work - Exsto does not have a specific to-do list (Excluding CORE work); we take jobs from the community.  Just create an issue as 'enhancement' and we will start on it." )
	page:AddSlide( 5, "That concludes our tutorial on Bug Reporting.  Taking you back to the Main Menu..." )

end
CreateTutorial( "Bug Reporting", "bugs", BugReporting )


BuildMainMenu()

concommand.Add( "exstoTutorial", StartTutorial )]]
