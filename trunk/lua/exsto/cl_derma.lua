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
		label:SetTextColor( Color( 99, 99, 99, 255 ) )

	return label

end	
	
function exsto.CreatePanel( x, y, w, h, color, parent )

	local panel = vgui.Create("DPanel", parent)
		panel:SetSize( w, h )
		panel:SetPos( x, y )
		
		panel.Gradient = function( self, grad )
			if grad then
				self.GradientHigh = Color( 236, 236, 236, 255 )
				self.GradientLow = Color( 249, 249, 249, 255 )
				self.GradientBorder = Color( 124, 124, 124, 255 )
			end
			self.ShouldGradient = grad	
		end
		
		panel.bgColor = color
		
	return panel

end

function exsto.CreateColorMixer( x, y, w, h, defaultColor, parent )
	local mixer = vgui.Create( "DColorMixer", parent )
		mixer:SetSize( w, h )
		mixer:SetPos( x, y )
		
		mixer.niceColor = defaultColor
		mixer:SetColor( defaultColor )
		mixer.ColorCube:UpdateColor()
		
	return mixer
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
		
		frame.GradientHigh = Color( 236, 236, 236, 255 )
		frame.GradientLow = Color( 249, 249, 249, 255 )
		frame.GradientBorder = Color( 124, 124, 124, 255 )
		
		frame:MakePopup()

	return frame
	
end

function exsto.CreateComboBox( x, y, w, h, parent )
	local box = vgui.Create( "DComboBox", parent )
		box:SetPos( x, y )
		box:SetSize( w, h )
		box:SetMultiple( false )

		local old = box.AddItem
		box.AddItem = function( self, ... )
			local obj = old( self, ... )
				obj.OnCursorEntered = function( self ) self.Hovered = true end
				obj.OnCursorExited = function( self ) self.Hovered = false end
			return obj
		end
		
	return box
end

function exsto.CreateImage( x, y, w, h, img, parent )
	local image = vgui.Create( "DImage", parent )
		image:SetSize( w, h )
		image:SetPos( x, y )
		image:SetImage( img )
	return image
end

function exsto.CreateButton( x, y, w, h, text, parent )

	local button = vgui.Create("DButton", parent)
	
		button:SetText( "" )
		button:SetSize( w, h )
		
		if x == "center" then x = (parent:GetWide() / 2) - (button:GetWide() / 2) end
		button:SetPos( x, y )
		
		button.GetStyle = function( self )
			return self.mStyle
		end
		
		button.SetStyle = function( self, style )
			self.mStyle = style
			if style == "secondary" then
				button.GradientHigh = Color( 229, 229, 299, 255 )
				button.GradientLow = Color( 222, 222, 222, 222 )
				button.BorderColor = Color( 191, 191, 191, 255 )
				button.Rounded = 0
				
				button.HoveredGradHigh = Color( 237, 237, 237, 255 )
				button.HoveredGradLow = Color( 226, 226, 226, 255 )
				
				button.SelectedBorder = Color( 0, 194, 14, 255 )
				
				button.TextColor = Color( 64, 64, 64, 255 )
				button.Font = "exstoSecondaryButtons"
				return 
			end
			
			if style == "neutral" then
				button.TextColor = Color( 0, 153, 176, 255 )
			elseif style == "negative" then
				button.TextColor = Color( 176, 0, 0, 255 )
			elseif style == "positive" then
				button.TextColor = Color( 12, 176, 0, 255 )
			end
			
			button.BorderColor = Color( 194, 194, 194, 255 )
			button.SelectedBorder = button.BorderColor
			button.GradientHigh = Color( 255, 255, 255, 255 )
			button.GradientLow = Color( 236, 236, 236, 255 )
			button.Rounded = 4
			button.Font = "exstoButtons"
		end
		
		function button.SetText( self, text )
			self.Text = text
		end
		
		button:SetStyle( "neutral" )
		
		button.Text = text
		
		surface.SetFont( button.Font )
		local w, h = surface.GetTextSize( text )
		
		if w > button:GetWide() then
			button:SetSize( w + 10, button:GetTall() )
			button:InvalidateLayout()
			//print( "Exsto Derma --> " .. button.Text .. " -->  I recommend you fix the button width and height to match this new size... " .. button:GetWide() .. ", " .. button:GetTall() )
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

function exsto.CreateNumberWang( x, y, w, h, value, max, min, parent )
	local wang = vgui.Create( "DNumberWang", parent )
		wang:SetPos( x, y )
		wang:SetSize( w, h )
		wang:SetMinMax( min, max )
		wang:SetValue( value )
	return wang
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
		
		list.contentWidth = 0
		list.contentHeight = 0
		local oldAddItem = list.AddItem
		list.AddItem = function( self, panel, ... )
			oldAddItem( self, panel, ... )
			panel:SetSkin( "ExstoTheme" )
		end
		
	return list
end

function exsto.CreateCollapseCategory( x, y, w, h, label, parent )
	
	local category = vgui.Create( "DCollapsibleCategory", parent )
		category:SetPos( x, y )
		category:SetSize( w, h )
		category:SetExpanded( false )
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

function exsto.CreateModelPanel( x, y, w, h, model, parent )
	local panel = vgui.Create( "DModelPanel", parent )
		panel:SetPos( x, y )
		panel:SetWide( w, h )
		panel:SetModel( model )
	return panel
end

function exsto.CreateLabeledPanel( x, y, w, h, label, color, parent )
	local panel = exsto.CreatePanel( x, y, w, h, color, parent )
	panel.Label = exsto.CreateLabel( x + 5, y - 10, label, "default", parent )
	
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