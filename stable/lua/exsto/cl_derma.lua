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


-- Derma Utilities

-- ################# Time saving DERMA functions @ Prefanatic
	function exsto.CreateLabel( x, y, text, font, parent )

		local label = vgui.Create("DLabel", parent)
			label:SetText( text )
			label:SetFont( font )
			label:SizeToContents()

			if x == "center" then x = (parent:GetWide() / 2) - (label:GetWide() / 2) end
			label:SetPos( x, y )
			label:SetVisible(true)
			
		-- Convinence lol.
		local oldSetText = label.SetText
		label.SetText = function( self, text )
			oldSetText( self, text )
			return self
		end

		return label

	end	
		
	function exsto.CreatePanel( x, y, w, h, color, parent )

		local panel = vgui.Create("DPanel", parent)
			panel:SetSize( w, h )
			panel:SetPos( x, y )
			panel.Paint = function()
				surface.SetDrawColor( color.r, color.g, color.b, color.a )
				surface.DrawRect( 0, 0, panel:GetWide(), panel:GetTall() )
			end
			
		return panel
	
	end
	
	function exsto.CreateTextEntry( x, y, w, h, parent )

		local tentry = vgui.Create( "DTextEntry", parent )
		
		tentry:SetSize( w, h )
		
		if x == "center" then x = (parent:GetWide() / 2) - (tentry:GetWide() / 2) end
		tentry:SetPos( x, y )
		
		return tentry
	
	end
	
	function exsto.CreateMultiChoice( x, y, w, h, parent )
	
		local panel = vgui.Create( "DMultiChoice", parent )
		
		panel:SetSize( w, h )
		panel:SetPos( x, y )
		
		return panel
		
	end

	function exsto.CreateFrame( x, y, w, h, title, showclose, borderfill )

		local frame = vgui.Create( "DFrame" )
		
			frame:SetPos( x, y )
			frame:SetSize( w, h )
			frame:SetVisible( true )
			frame:SetTitle( title )
			frame:SetDraggable( true )
			frame:SetBackgroundBlur( false )
			frame:ShowCloseButton( true )
			
			frame:MakePopup()
	
		return frame
		
	end

function exsto.CreateButton( x, y, w, h, text, parent )

	local button = vgui.Create("DButton", parent)
	
		button:SetText( "" )
		button:SetSize( w, h )
		
		if x == "center" then x = (parent:GetWide() / 2) - (button:GetWide() / 2) end
		button:SetPos( x, y )
		
		button.OnCursorEntered = function()
			surface.PlaySound( "UI/buttonrollover.wav" )
		end
		
		local buttonDraw = function( self )
			local col = self.Color
			if self.Depressed then
				col = self.DepressedCol
			elseif self.Hovered then
				col = self.HoverCol
			end
			
			draw.RoundedBox( 4, 0, 0, self:GetWide(), self:GetTall(), col )
			draw.SimpleText( self.Text, self.Font, self:GetWide() / 2, self:GetTall() / 2, Color( 255, 255, 255, 255 ), 1, 1 )
		end
		
		button.Text = text
		button.Color = Color( 155, 228, 255, 255 )
		button.HoverCol = Color( 136, 199, 255, 255 )
		button.DepressedCol = Color( 156, 179, 255, 255 )
		button.Paint = buttonDraw
		
		-- Font bug fix, wtf.
		button.Font = "exstoButtons"
		
		surface.SetFont( button.Font )
		local w, h = surface.GetTextSize( button.Text )
		
		if w > button:GetWide() then
			button:SetSize( w + 10, button:GetTall() )
			button:InvalidateLayout()
			print( "Exsto Derma --> " .. button.Text .. " -->  I recommend you fix the button width and height to match this new size... " .. button:GetWide() .. ", " .. button:GetTall() )
		end

	return button
	
end

function exsto.CreateSysButton( x, y, w, h, type, parent )

	local button = vgui.Create( "DSysButton", parent )
	
		button:SetSize( w, h )
		button:SetPos( x, y )
		button:SetType( type )
		
	return button
	
end

function exsto.CreateListView( x, y, w, h, parent )
	
	local lview = vgui.Create("DListView", parent)
	
		lview:SetSize( w, h )
		
		if posx == "center" then posx = (parent:GetWide() / 2) - (lview:GetWide() / 2) end
		lview:SetPos( x, y )
		lview:SetMultiSelect( false )
		
		lview.Color = Color( 242, 242, 242, 255 )
		lview.Round = 4
		lview.Paint = function( self )
			draw.RoundedBox( self.Round, 0, 0, self:GetWide(), self:GetTall(), self.Color )
		end
		
		lview.ScrollbarGripCol = Color( 123, 240, 101, 255 )
		lview.ScrollbarButtonCol = Color( 123, 240, 101, 255 )
		
		lview.VBar.Paint = function() end
		
		local oldPaint = lview.VBar.btnGrip.Paint
		lview.VBar.btnGrip.Paint = function( self )
			if !lview.ScrollbarGripCol then
				if oldPaint then oldPaint( self ) end
			else
				draw.RoundedBox( 4, 0, 0, self:GetWide(), self:GetTall(), lview.ScrollbarGripCol )
			end
		end
		
		local oldPaint = lview.VBar.btnUp
		local newPaint = function( self )
			if !lview.ScrollbarButtonCol then
				if oldPaint then oldPaint( self ) end
			else
				draw.RoundedBox( 0, 0, 0, self:GetWide(), self:GetTall(), lview.ScrollbarButtonCol )
			end
		end
		
		lview.VBar.btnUp.Paint = newPaint
		lview.VBar.btnDown.Paint = newPaint
		
		local oldSettings = lview.VBar.btnUp.ApplySchemeSettings
		lview.VBar.btnUp.ApplySchemeSettings = function( self )
			oldSettings( self )
			self:SetTextColor( Color( 255, 255, 255, 255 ) )
		end
		local oldSettings = lview.VBar.btnDown.ApplySchemeSettings
		lview.VBar.btnDown.ApplySchemeSettings = function( self )
			oldSettings( self )
			self:SetTextColor( Color( 255, 255, 255, 255 ) )
		end

		lview.ColumnFont = "default"
		lview.ColumnTextCol = Color( 0, 0, 0, 255 )

		local oldAdd = lview.AddColumn
		lview.AddColumn = function( self, strName, strMaterial, iPosition )
			local column = oldAdd( self, strName, strMaterial, iPosition )
			
			local texture = surface.GetTextureID( "gui/gradient_down" )
			column.Header.Paint = function( self )
				surface.SetDrawColor( lview.Color.r, lview.Color.b, lview.Color.g, lview.Color.a )
				surface.SetTexture( texture )
				surface.DrawTexturedRect( 3, 0, self:GetWide()- 6, self:GetTall() + 10 )
			end
			
			local oldSettings = column.Header.ApplySchemeSettings
			column.Header.ApplySchemeSettings = function( self )
				oldSettings( self )
				column.Header:SetFont( lview.ColumnFont )
				column.Header:SetTextColor( lview.ColumnTextCol )

				local selfW, selfH = column.Header:GetSize()
				local parW, parH = column:GetSize()
				
				column.Header:SetPos( (parW / 2 ) - (selfW / 2), (parH / 2) - (selfH / 2 ) )
			end
			
			return column
		end
		
		lview.LineFont = "default"
		lview.LineTextCol = Color( 0, 0, 0, 255 )
		
		lview.SelectColor = Color( 149, 227, 134, 255 )
		lview.HoverColor = Color( 229, 229, 229, 255 )
		
		local oldLineAdd = lview.AddLine
		lview.AddLine = function( self, ... )
			local line = oldLineAdd( self, ... )
			
			for k,v in pairs( line.Columns ) do
				local oldSettings = v.ApplySchemeSettings
				v.ApplySchemeSettings = function( self )
					oldSettings( self )
					v:SetFont( lview.LineFont )
					v:SetTextColor( lview.LineTextCol )
				end
			end
			
			line.Paint = function( self )
				local col = Color( 0, 0, 0, 0 )
				if (self:IsSelected()) then
					col = lview.SelectColor
				elseif (self.Hovered) then
					col = lview.HoverColor
				end
				
				surface.SetDrawColor( col.r, col.g, col.b, col.a )
				surface.DrawRect( 0, 0, self:GetWide(), self:GetTall() )
			end
			
			return line
		end
		
		lview:SetDrawBackground( false )
		
	return lview
	
end

function exsto.CreateCheckBox( x, y, text, convar, value, parent )

	local cbox = vgui.Create("DCheckBoxLabel", parent)
	
		cbox:SetPos( x, y )
		cbox:SetText( text )
		cbox:SetConVar( convar )
		cbox:SetValue( value )
		cbox:SizeToContents()
	
	return cbox
	
end

function exsto.CreateNumSlider( x, y, w, text, min, max, decimals, panel )

	local panel = vgui.Create( "DNumSlider", panel )
		
		panel:SetPos( x, y )
		panel:SetWide( w )
		panel:SetText( text )
		panel:SetMin( min )
		panel:SetMax( max )
		panel:SetDecimals( decimals )
		
	return panel
	
end

function exsto.CreatePanelList( x, y, w, h, space, horiz, vscroll, parent )

	local list = vgui.Create( "DPanelList", parent )
		list:SetPos( x, y )
		list:SetSize( w, h )
		list:SetSpacing( space )
		list:EnableHorizontal( horiz )
		list:EnableVerticalScrollbar( vscroll )
		
		list.Color = Color( 242, 242, 242, 255 )
		list.Paint = function( self )
			draw.RoundedBox( 4, 0, 0, self:GetWide(), self:GetTall(), self.Color )
		end
		
		if vscroll then
			list.ScrollbarGripCol = Color( 131, 255, 114, 255 )
			list.ScrollbarButtonCol = Color( 96, 216, 80, 255 )
			
			list.VBar.Paint = function() end
			
			local oldPaint = list.VBar.btnGrip.Paint
			list.VBar.btnGrip.Paint = function( self )
				if !list.ScrollbarGripCol then
					if oldPaint then oldPaint( self ) end
				else
					draw.RoundedBox( 0, 0, 0, self:GetWide(), self:GetTall(), list.ScrollbarGripCol )
				end
			end
			
			local oldPaint = list.VBar.btnUp
			local newPaint = function( self )
				if !list.ScrollbarButtonCol then
					if oldPaint then oldPaint( self ) end
				else
					draw.RoundedBox( 0, 0, 0, self:GetWide(), self:GetTall(), list.ScrollbarButtonCol )
				end
			end
			
			list.VBar.btnUp.Paint = newPaint
			list.VBar.btnDown.Paint = newPaint
			
			local oldSettings = list.VBar.btnUp.ApplySchemeSettings
			list.VBar.btnUp.ApplySchemeSettings = function( self )
				oldSettings( self )
				self:SetTextColor( Color( 255, 255, 255, 255 ) )
			end
			local oldSettings = list.VBar.btnDown.ApplySchemeSettings
			list.VBar.btnDown.ApplySchemeSettings = function( self )
				oldSettings( self )
				self:SetTextColor( Color( 255, 255, 255, 255 ) )
			end
		end
		
	return list
	
end

function exsto.CreateCollapseCategory( x, y, w, h, label, parent )
	
	local category = vgui.Create( "DCollapsibleCategory", parent )
		category:SetPos( x, y )
		category:SetSize( w, h )
		category:SetExpanded( 0 )
		category:SetLabel( "" )
		
	category.Header.Label = label
	category.Header.Font = "default"
	category.Header.TextColor = Color( 255, 255, 255, 255 )
	category.Color = Color( 255, 255, 255, 255 )
	
	category.Paint = function( self )
		draw.RoundedBox( 4, 0, 0, self:GetWide(), self:GetTall(), self.Color )
	end
	category.Header.Paint = function( self )
		draw.SimpleText( self.Label, self.Font, 4, 1, self.TextColor, 0, 0 )
	end
		
	return category
	
end

function exsto.CreateLabeledPanel( x, y, w, h, label, color, parent )
	local panel = exsto.CreatePanel( x, y, w, h, color, parent )
	panel.Label = exsto.CreateLabel( x + 5, y - 10, label, "default", parent )
	
	--[[
	local oldFont = panel.Label.SetFont
	panel.Label.SetFont = function( label, font )
	
		surface.SetFont( font )
		local w, h = surface.GetTextSize( label:GetValue() )
		//local x, y = label:GetPos()
		
		oldFont( label, font )
		
		label:SetPos( 5, ( ( h / 2 ) * -1 ) - 3 )
		label:SizeToContents()
		
	end]]
	
	local oldApplyScheme = panel.Label.ApplySchemeSettings
	panel.Label.ApplySchemeSettings = function( self )
		oldApplyScheme( self )
		
		local x, y = panel:GetPos()
		local w, h = self:GetSize()
		
		self:SizeToContents()
		self:SetPos( x + 5, y - ( h / 2 ) + .5 )
	end
	
	//panel:NoClipping( true )
	panel.Label:SetTextColor( Color( 93, 93, 93, 255  ) )
	
	panel.Paint = function( panel )
		draw.RoundedBox( 6, 0, 0, panel:GetWide(), panel:GetTall(), color )
	end
	
	return panel
end