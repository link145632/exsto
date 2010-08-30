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
	
surface.CreateFont( "arial", 14, 500, true, false, "exstoListColumn" )
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
surface.CreateFont( "arial", 16, 700, true, false, "ExLoadingText" )

for I = 14, 128 do
	surface.CreateFont( "arial", I, 700, true, false, "ExGenericText" .. I )
end

--[[ -----------------------------------
	Function: exsto.Menu
	Description: Opens up the Exsto menu.
	----------------------------------- ]]
function exsto.Menu( reader )
	Menu:WaitForRanks( reader:ReadShort(), reader:ReadString(), reader:ReadShort(), reader:ReadBool() )
end
exsto.CreateReader( "ExMenu", exsto.Menu )

local function toggleOpenMenu( ply, _, args )
	-- We need to ping the server for any new data possible.
	RunConsoleCommand( "_ExPingMenuData" )
end
concommand.Add( "+ExMenu", toggleOpenMenu )

local function toggleCloseMenu( ply, _, args )
	Menu.Frame.btnClose.DoClick( Menu.Frame.btnClose )
end
concommand.Add( "-ExMenu", toggleCloseMenu )

function Menu:WaitForRanks( key, rank, flagCount, bindOpen )
	if !exsto.Ranks or table.Count( exsto.Ranks ) == 0 then
		timer.Simple( 0.1, Menu.WaitForRanks, Menu, key, rank, flagCount, bindOpen )
		return
	end

	self:Initialize( key, rank, flagCount, bindOpen )
end

function Menu:Initialize( key, rank, flagCount, bindOpen )
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
			
		if bindOpen then Menu.Frame:ShowCloseButton( false ) end
		Menu.Frame:SetVisible( true )
		Menu:BringBackSecondaries()
	else
		Menu.LastRank = LocalPlayer():GetRank()
		Menu:Create( rank, flagCount )
		if bindOpen then Menu.Frame:ShowCloseButton( false ) end
	end
	
	if !file.Exists( "exsto_tmp/exsto_menu_opened.txt" ) then
		-- Oh lordy, move him to the help page!
		file.Write( "exsto_tmp/exsto_menu_opened.txt", "1" )
		Menu:MoveToPage( "helppage" )
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
	
	Menu:CreateAnimation( self.Frame )
	self.Frame:FadeOnVisible( true )
	self.Frame:SetFadeMul( 2 )	
	
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
			list:AddOption( data.Title, function() Menu:MoveToPage( data.Short ) end )
		end
		list:Open()
	end
	
	self.Header.Title = exsto.CreateLabel( self.Header.Logo:GetWide() + 20, 17, "", "exstoHeaderTitle", self.Header )
	self.Header.Title:SetTextColor( self.Colors.HeaderTitleText )
	
	local function paint( self )
		draw.SimpleText( self.Text, "exstoArrows", self:GetWide() / 2, self:GetTall() / 2, Menu.Colors.ArrowColor, 1, 1 )
	end
	
	self.Header.MoveLeft = exsto.CreateButton( 0, 18, 20, 20, "", self.Header )
	self.Header.MoveLeft.Paint = paint
	self.Header.MoveLeft.DoClick = function( self )
		Menu:MoveToPage( Menu.PreviousPage.Short, false )
	end
	
	self.Header.MoveRight = exsto.CreateButton( 0, 18, 20, 20, "", self.Header )
	self.Header.MoveRight.Paint = paint
	self.Header.MoveRight.DoClick = function( self )
		Menu:MoveToPage( Menu.NextPage.Short, true )
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
		tab:SetPosMul( 5 )
		tab:SetFadeMul( 4 )

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
		secondary:SetPosMul( 5 )
		secondary:SetFadeMul( 4 )
		
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
	
	obj.DisableAnims = function( self )
		self.Anims.Disabled = true
	end
	
	obj.EnableAnims = function( self )
		self.Anims.Disabled = false
	end
	
	-- Position Support
	obj.oldGetPos = obj.GetPos
	obj.oldPos = obj.SetPos
	local oldSetX = function( self, x ) obj.oldPos( self, x, self.Anims[ 2 ].Last ) end
	local oldSetY = function( self, y ) obj.oldPos( self, self.Anims[ 1 ].Last, y ) end
	
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
			if math.Round( data.Last ) != math.Round( data.Current ) then
				if self.Anims.Disabled then
					data.Last = data.Current
					data.Call( self, self.Anims[ _ ].Last )
				else
					dist = data.Current - data.Last
					speed = RealFrameTime() * ( dist / data.Mul  ) * 40

					self.Anims[ _ ].Last = math.Approach( data.Last, data.Current, speed )
					data.Call( self, self.Anims[ _ ].Last )
				end
			end
		end
	end
	
	-- Presets.
	local x, y = obj.oldGetPos( obj )
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
	local clientFlags = exsto.Ranks[ rank:lower() ]
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
	if #self.ListIndex == 0 then
		self:SetTitle( "There are no pages for you to view!" )
		return false
	end
	
	-- Set our current page and the ones near us.
	for index, short in ipairs( self.ListIndex ) do
		if self.List[ short ] then
			-- Hes a default, set him up as our first selection.
			if self.List[ short ].Default then
				self:MoveToPage( short )
				self.DefaultPage = self.CurrentPage
				self.DefaultPage.Panel:SetVisible( true )
			else
				self:GetPageData( index ).Panel:SetVisible( false )
			end
		end
	end
	
	-- If there still isn't any default, set the default as the first index.
	if !self.DefaultPage then
		self:MoveToPage( self.ListIndex[ 1 ] )
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

--[[ ----------------------------------- 
	Function: Menu:GetPageData
	Description: Grabs page data from the index.
	----------------------------------- ]]
function Menu:GetPageData( index )
	local short = self.ListIndex[ index ]
	if !short then return nil end
	return self.List[ short ]
end

--[[ ----------------------------------- 
	Function: Menu:SetTitle
	Description: Sets the menu title.
	----------------------------------- ]]
function Menu:SetTitle( text )
	self.Header.Title:SetText( text )
	self.Header.Title:SizeToContents()
	
	local start = self.Header.Logo:GetWide() + self.Header.Title:GetWide() + 34
	self.Header.ExtendBar:SetPos( start, 27 )
	self.Header.ExtendBar:SetWide( self.Header:GetWide() - start - 60 )
	
	self.Header.MoveLeft:MoveRightOf( self.Header.ExtendBar, 10 )
	self.Header.MoveRight:MoveRightOf( self.Header.MoveLeft, 5 )
	
end

--[[ ----------------------------------- 
	Function: Menu:CreateDialog
	Description: Creates a small notification dialog.
	----------------------------------- ]]
function Menu:CreateDialog()
	self.Dialog = {}
		self.Dialog.Queue = {}
		self.Dialog.Active = false
		self.Dialog.IsLoading = false
	
	self.Dialog.BG = exsto.CreatePanel( 0, 0, self.Frame:GetWide(), self.Frame:GetTall(), Color( 0, 0, 0, 190 ), self.Frame )
		self.Dialog.BG:SetVisible( false )
		local id = surface.GetTextureID( "gui/center_gradient" )
		self.Dialog.BG.Paint = function( self )
			surface.SetDrawColor( 0, 0, 0, 190 )
			surface.SetTexture( id )
			surface.DrawTexturedRect( 0, 0, self:GetWide(), self:GetTall() )
		end
		
	local w, h = surface.GetTextureSize( surface.GetTextureID( "loading" ) )
	self.Dialog.Anim = exsto.CreateImage( 0, 0, w, h, "loacing", self.Dialog.BG )
		self.Dialog.Anim:SetKeepAspect( true )
		
	self.Dialog.Msg = exsto.CreateLabel( 20, self.Dialog.Anim:GetTall() + 40, "", "exstoBottomTitleMenu", self.Dialog.BG )
		self.Dialog.Msg:DockMargin( ( self.Dialog.BG:GetWide() / 2 ) - 200, self.Dialog.Anim:GetTall() + 40, ( self.Dialog.BG:GetWide() / 2 ) - 200, 0 )
		self.Dialog.Msg:Dock( FILL )
		self.Dialog.Msg:SetContentAlignment( 7 )
		self.Dialog.Msg:SetWrap( true )
		
	self.Dialog.Yes = exsto.CreateButton( ( self.Frame:GetWide() / 2 ) - 140, self.Dialog.BG:GetTall() - 50, 100, 40, "Yes", self.Dialog.BG )
		self.Dialog.Yes:SetStyle( "positive" )
		self.Dialog.Yes.OnClick = function()
			if self.Dialog.YesFunc then
				self.Dialog.YesFunc()
			end
			sef:CleanDialog()
		end
	
	self.Dialog.No = exsto.CreateButton( ( self.Frame:GetWide() / 2 ) + 40, self.Dialog.BG:GetTall() - 50, 100, 40, "No", self.Dialog.BG )
		self.Dialog.No:SetStyle( "negative" )
		self.Dialog.No.OnClick = function()
			if self.Dialog.NoFunc then
				self.Dialog.NoFunc()
			end
			self:CleanDialog()
		end
	
	self.Dialog.OK = exsto.CreateButton( ( self.Frame:GetWide() / 2 ) - 50, self.Dialog.BG:GetTall() - 50, 100, 40, "OK", self.Dialog.BG )
		self.Dialog.OK.OnClick = function()
			self:CleanDialog()
		end
		
	self:CleanDialog()
		
end
	
function Menu:CleanDialog()
	if !self.Dialog then return end
	
	Menu:BringBackSecondaries()
	
	self.Dialog.BG:SetVisible( false )
	self.Dialog.Msg:SetText( "" )
	self.Dialog.OK:SetVisible( false )
	self.Dialog.Yes:SetVisible( false )
	self.Dialog.No:SetVisible( false )
	
	self.Dialog.IsLoading = false
	self.Dialog.Active = false
	
	if self.Dialog.Queue[1] then
		local data = self.Dialog.Queue[1]
		self:PushGeneric( data.Text, data.Texture, data.Color, data.Type )
		table.remove( self.Dialog.Queue, 1 )
	end
end
	
--[[ ----------------------------------- 
	Function: Menu:PushLoad
	Description: Shows a loading screen.
	----------------------------------- ]]
function Menu:PushLoad()
	self:PushGeneric( "Loading...", nil, nil, "loading" )
	timer.Create( "exstoLoadTimeout", 10, 1, function() if Menu.Dialog.IsLoading then Menu:EndLoad() Menu:PushError( "Loading timed out!" ) end end )
end

function Menu:EndLoad()
	if !self.Frame then return end
	if !self.Dialog then return end
	if !self.Dialog.IsLoading then return end
	
	self:CleanDialog()
end

function Menu:PushError( msg )
	self:PushGeneric( msg, "exstoErrorAnim", Color( 176, 0, 0, 255 ), "error" )
end

function Menu:PushNotify( msg )
	self:PushGeneric( msg, nil, nil, "notify" )
end

function Menu:PushQuestion( msg, yesFunc, noFunc )
	self:PushGeneric( msg, nil, nil, "question" )
	self.Dialog.YesFunc = yesFunc
	self.Dialog.NoFunc = noFunc
end

function Menu:PushGeneric( msg, imgTexture, textCol, type )
	if !self.Dialog then
		self:CreateDialog()
	end
	
	if self.Dialog.Active and type != "loading" then
		table.insert( self.Dialog.Queue, {
			Text = msg, Texture = imgTexture, Color = textCol, Type = type }
		)
		return
	elseif self.Dialog.Active and type == "loading" then
		self:EndLoad()
	end
	
	Menu:HideSecondaries()
	
	self.Dialog.Active = true
	
	self.Dialog.Anim:SetImage( imgTexture or "exstoGenericAnim" )
	self.Dialog.Msg:SetText( msg )
	self.Dialog.Msg:SetTextColor( textCol or Color( 12, 176, 0, 255 ) )
	
	if type == "notify" or type == "error" then
		self.Dialog.OK:SetVisible( true )
	elseif type == "question" then
		self.Dialog.Yes:SetVisible( true )
		self.Dialog.No:SetVisible( true )
	elseif type == "input" then
		self.Dialog.OK:SetVisible( true )
		--self.Dialog.Input:SetVisible( true )
	elseif type == "loading" then
		self.Dialog.IsLoading = true
	end
	
	self.Dialog.BG:SetVisible( true )
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
function Menu:GetPageIndex( short )
	for k,v in pairs( Menu.ListIndex ) do
		if v == short then return k end
	end
end

function Menu:TuckExtras()
	if self.ActiveSecondary then
		-- Tuck him away.
		self.ActiveSecondary:SetVisible( false )
		self.ActiveSecondary = nil
	end
	
	if self.ActiveTab then
		self.ActiveTab:SetVisible( false )
		self.ActiveTab = nil
	end
end

function Menu:CheckRequests( short )
	-- Send our our requests
	local secondary = self.SecondaryRequests[ short ]
	if secondary then
		if !secondary.Hidden then secondary:SetVisible( true ) end
		self.ActiveSecondary = secondary
		self:UpdateSecondariesPos()
	end
	
	local tabs = self.TabRequests[ short ]
	if tabs then
		tabs:SetVisible( true )
		self.ActiveTab = tabs
		self:UpdateSecondariesPos()
	end
end

--[[ -----------------------------------
	Function: Menu.MoveToPage
	Description: Moves to a page
	----------------------------------- ]]
function Menu:MoveToPage( short, right )

	local page = self.List[ short ]
	local index = self:GetPageIndex( short )
	
	if short == self.CurrentPage.Short then return end -- Why bother.
	
	local oldCurrent = self.CurrentPage.Panel
	local oldIndex = self.CurrentIndex
	
	self.PreviousPage = self.List[self.ListIndex[index - 1]] or self.List[self.ListIndex[#self.ListIndex]]
	self.CurrentPage = page
	self.NextPage = self.List[self.ListIndex[index + 1]] or self.List[self.ListIndex[1]]
	
	self.CurrentIndex = index
	
	self:SetTitle( self.CurrentPage.Title )
	
	self:HideSecondaries()
	self:TuckExtras()
	self:CheckRequests( short )

	if !oldCurrent then return end
	
	local oldW, oldH = oldCurrent:GetSize() 
	
	local startPos = oldW
	if oldIndex > self.CurrentIndex then startPos = -oldW end
	if oldIndex == #self.ListIndex and self.CurrentIndex == 1 then startPos = oldW end
	if self.CurrentIndex == #self.ListIndex and oldIndex == 1 then startPos = -oldW end

	self.CurrentPage.Panel:SetVisible( true ) -- Make him alive.
	
	self.CurrentPage.Panel:oldPos( startPos, 0 )
	self.CurrentPage.Panel.Anims[ 1 ].Last = startPos
	self.CurrentPage.Panel.Anims[ 1 ].Current = startPos
	self.CurrentPage.Panel:SetPos( 0, 0 )
	
	oldCurrent:SetPos( -startPos, 0 )

end

concommand.Add( "_Test", function( ply, _, args )
	Menu.CurrentPage.Panel:PushGeneric( args[1] )
end )

--[[ -----------------------------------
	Function: Menu:CalcFontSize
	Description: Calculates the best font to use in an area
	----------------------------------- ]]
function Menu:CalcFontSize( text, maxWidth, maxFont )
	for I = 14, maxFont do
		surface.SetFont( "ExGenericText" .. I )
		local w = surface.GetTextSize( text )
		
		if w > maxWidth then
			maxFont = math.Round( I - 3 )
			break
		end
	end
	return "ExGenericText" .. maxFont
end

--[[ -----------------------------------
	Function: Menu:CreatePage
	Description: Creates a menu page for the Exsto menu
	----------------------------------- ]]
local glow = surface.GetTextureID( "glow2" )
local loading = surface.GetTextureID( "loading" )
function Menu:CreatePage( info, func )

	-- Create a build function
	local function buildPage( bg )
		-- Create the placement background.
		local page = exsto.CreatePanel( 0, 0, Menu.Placement.Content.w, Menu.Placement.Content.h - 6, Menu.Colors.Black, bg )
		page:SetVisible( false )
		Menu:CreateAnimation( page )
		page:SetPosMul( 5 )
		
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
		
		page.ExNotify_Queue = {}
		function page:PushLoad()
			self.ExNotify_Active = true
			self.ExNotify_Loading = true
			self.ExNotify_Rotation = 0
		end
		
		function page:EndLoad()
			self.ExNotify_Active = false
			self.ExNotify_Loading = false
		end
		
		function page:PushGeneric( text, timeOnline, err )
			if self.ExNotify_Active then
				table.insert( self.ExNotify_Queue, { Text = text, TimeOnline = timeOnline, Err = err } )
				return
			end
			self.ExNotify_Active = true
			self.ExNotify_Generic = true
			self.ExNotify_Text = text or "No Text Provided"
			self.ExNotify_EndTime = CurTime() + ( timeOnline or 5 )
			self.ExNotify_Error = err or false
			self.ExNotify_Alpha = 0
		end
		
		function page:PushError( text, timeOnline )
			self:PushGeneric( text, timeOnline, true )
		end
		
		function page:DialogCleanup()
			self.ExNotify_Active = false
			self.ExNotify_Generic = false
			self.ExNotify_Loading = false
			self.ExNotify_Text = ""
			self.ExNotify_EndTime = false
			self.ExNotify_Error = false
			self.ExNotify_Alpha = 0
			
			if self.ExNotify_Queue[1] then
				self:PushGeneric( self.ExNotify_Queue[1].Text, self.ExNotify_Queue[1].TimeOnline, self.ExNotify_Queue[1].Err )
				table.remove( self.ExNotify_Queue, 1 )
			end
		end
		
		page.Text_LoadingColor = Color( 0, 192, 10, 255 )
		page.Text_ErrorColor = Color( 192, 0, 10, 255 )
		page.Text_GenericColor = Color( 30, 30, 30, 255 )
		page.Text_OutlineColor = Color( 255, 255, 255, 255 )
		page.PaintOver = function( self )
			if self.ExNotify_Active then
				if self.ExNotify_Loading then
					surface.SetDrawColor( 255, 255, 255, 255 )
					surface.SetTexture( glow )
					surface.DrawTexturedRect( ( self:GetWide() / 2 ) - ( 512 / 2 ), ( self:GetTall() / 2 ) - ( 512 / 2 ), 512, 512 )
					
					self.ExNotify_Rotation = self.ExNotify_Rotation + 1
					surface.SetTexture( loading )
					surface.DrawTexturedRectRotated( ( self:GetWide() / 2 ), ( self:GetTall() / 2 ), 128, 128, self.ExNotify_Rotation )
					
					draw.SimpleText( "Loading", "ExLoadingText", ( self:GetWide() / 2 ), ( self:GetTall() / 2 ), self.Text_LoadingColor, 1, 1 )
				elseif self.ExNotify_Generic then 
					if self.ExNotify_EndTime - .5 <= CurTime() then -- Give us a second to fade
						if self.ExNotify_Alpha > 5 then
							self.ExNotify_Alpha = self.ExNotify_Alpha - 8.5
						end
					else
						if self.ExNotify_Alpha < 250 then
							self.ExNotify_Alpha = self.ExNotify_Alpha + 8.5
						end
					end
					
					if self.ExNotify_EndTime <= CurTime() then
						self:DialogCleanup()
						return
					end
					surface.SetDrawColor( 0, 0, 0, self.ExNotify_Alpha * .9 )
					surface.DrawRect( 0, self:GetTall() - 40, self:GetWide(), 40 )
					
					local col = self.ExNotify_Error and self.Text_ErrorColor or self.Text_GenericColor
						col.a = self.ExNotify_Alpha
						
					local outlineCol = self.Text_OutlineColor
						col.a = self.ExNotify_Alpha
					
					draw.SimpleTextOutlined( self.ExNotify_Text, Menu:CalcFontSize( self.ExNotify_Text, self:GetWide() - 10, 30 ), 5, self:GetTall() - 20, col, 0, 1, 1, outlineCol )
				end
			end
		end
		
		local success, err = pcall( func, page )
		if !success then
			exsto.Print( exsto_CONSOLE, "MENU --> Error creating page '" .. info.Short .. "': " .. err )
		end
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